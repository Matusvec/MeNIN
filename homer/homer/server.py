"""The agent service's HTTP API. See homer/API.md.

Run: .venv/bin/uvicorn homer.server:app --host 0.0.0.0 --port 8000

JSON on the wire is camelCase, matching ios/Homer/Contracts.swift. Request
fields also accept snake_case.
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
from contextlib import asynccontextmanager
from dataclasses import asdict, is_dataclass
from typing import Any, Literal

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

from . import events, formulas
from .arena import Arena, BattleTurn
from .config import settings
from .judge import EmptyVerse, Judge, Judgment, Turn
from .scanner import TimedWord, VerseScan, beat_lane, scan_verse
from .stdb import Refused, Stdb, StdbError

log = logging.getLogger("homer")

_judge: Judge | None = None
_arena: Arena | None = None


def judge() -> Judge:
    global _judge
    if _judge is None:
        _judge = Judge()
    return _judge


def arena() -> Arena:
    global _arena
    if _arena is None:
        _arena = Arena(judge(), Stdb())
    return _arena


@asynccontextmanager
async def lifespan(_: FastAPI):
    scan_verse("warm the dictionary")  # loads CMU once, before the first turn
    formulas.bank()
    cfg = settings()
    if os.environ.get("HOMER_WARM", "1") not in ("0", "false") and os.environ.get("ANTHROPIC_API_KEY"):
        asyncio.get_running_loop().create_task(judge().warm())
    if cfg.stdb_token and cfg.service_key:
        try:
            await arena().db.claim_service()
        except StdbError as exc:
            log.warning("claim_service failed: %s", exc)
    yield


app = FastAPI(title="Homer agent service", lifespan=lifespan)


# ----- Wire shapes -----------------------------------------------------------


class Model(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class Word(Model):
    text: str
    start: float  # ms from beat 1 of the turn
    end: float


class ScanRequest(Model):
    transcript: str = ""
    words: list[Word] | None = None
    bpm: float | None = None
    lines_expected: int | None = None
    hand: list[str] = Field(default_factory=list)
    started_at: float = 0.0
    event: str = "poetry"


class JudgeRequest(ScanRequest):
    mode: Literal["practice", "lesson", "battle"] = "practice"
    theme: str = ""
    played: list[str] = Field(default_factory=list)
    rescues: int = 0
    previous: str = ""
    emotion_history: list[dict[str, float]] = Field(default_factory=list)
    hoard: list[str] = Field(default_factory=list)
    demo: bool = False


def camel(obj: Any) -> Any:
    """Dataclasses and dicts to JSON-ready values with camelCase keys."""
    if is_dataclass(obj) and not isinstance(obj, type):
        obj = asdict(obj)
    if isinstance(obj, dict):
        return {to_camel(k) if isinstance(k, str) else k: camel(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [camel(v) for v in obj]
    return obj


def _words(req: ScanRequest) -> list[TimedWord] | None:
    return [TimedWord(w.text, w.start, w.end) for w in req.words] if req.words else None


def scan_json(scan: VerseScan, bpm: float | None = None, started_at: float = 0.0, event: str = "poetry") -> dict[str, Any]:
    out = camel(scan)
    if bpm:
        out["beatLane"] = beat_lane(scan, bpm, started_at, events.get(event).beats_per_line)
    return out


def scorecard(j: Judgment, bpm: float | None = None, started_at: float = 0.0, event: str = "poetry") -> dict[str, Any]:
    return {
        "scores": j.scores,
        "total": j.total,
        "verdict": j.verdict,
        "bestLine": j.best_line,
        "coined": j.coined,
        "declined": j.declined,
        "silent": j.silent,
        "scan": scan_json(j.scan, bpm, started_at, event) if j.scan else None,
        "timing": j.timing,
        "model": j.model,
    }


# ----- Endpoints -------------------------------------------------------------


@app.get("/health")
async def health() -> dict[str, Any]:
    cfg = settings()
    return {"ok": True, "judgeModel": cfg.judge_model, "judgeEffort": cfg.judge_effort, "events": list(events.EVENTS)}


@app.post("/scan")
async def scan(req: ScanRequest) -> dict[str, Any]:
    try:
        event = events.get(req.event)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from None
    cards = [formulas.card(t) for t in req.hand] + list(formulas.bank())
    result = scan_verse(
        req.transcript,
        words=_words(req),
        bpm=req.bpm,
        beats_per_line=event.beats_per_line,
        lines_expected=req.lines_expected,
        cards=cards,
    )
    return scan_json(result, req.bpm, req.started_at, req.event)


@app.post("/judge")
async def judge_turn(req: JudgeRequest, request: Request):
    """Judge one verse (practice, lesson). JSON, or SSE when the client asks for text/event-stream."""
    if req.event not in events.EVENTS:
        raise HTTPException(400, f"unknown event: {req.event}")
    if not req.transcript.strip() and not req.words:
        raise HTTPException(422, "nothing to judge")
    turn = Turn(
        transcript=req.transcript,
        mode=req.mode,
        event=req.event,
        theme=req.theme,
        hand=req.hand,
        played=req.played,
        rescues=req.rescues,
        previous=req.previous,
        words=_words(req),
        bpm=req.bpm,
        lines_expected=req.lines_expected,
        emotion_history=req.emotion_history,
        hoard=req.hoard,
        demo=req.demo,
    )
    if "text/event-stream" not in request.headers.get("accept", ""):
        try:
            return scorecard(await judge().judge(turn), req.bpm, req.started_at, req.event)
        except EmptyVerse as exc:
            raise HTTPException(422, str(exc)) from None

    queue: asyncio.Queue[tuple[str, Any]] = asyncio.Queue()

    async def run() -> None:
        try:
            j = await judge().judge(turn, on_verdict=lambda v: queue.put_nowait(("verdict", {"verdict": v})))
            queue.put_nowait(("scorecard", scorecard(j, req.bpm, req.started_at, req.event)))
        except EmptyVerse as exc:
            queue.put_nowait(("error", {"detail": str(exc)}))
        except Exception as exc:  # report, don't hang the stream
            log.exception("judge failed")
            queue.put_nowait(("error", {"detail": type(exc).__name__}))

    async def stream():
        task = asyncio.create_task(run())
        try:
            while True:
                name, data = await queue.get()
                yield f"event: {name}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"
                if name in ("scorecard", "error"):
                    break
        finally:
            task.cancel()

    return StreamingResponse(stream(), media_type="text/event-stream", headers={"Cache-Control": "no-cache"})


class BattleJudgeRequest(Model):
    turn_id: int
    transcript: str
    event: str = "poetry"
    form: str = "four_beat"
    theme: str = ""
    played: list[str] = Field(default_factory=list)
    rescues: int = 0
    previous: str = ""  # the previous verse in the round
    previous_best_line: str = ""  # or just its best line
    lines_expected: int | None = None  # room.lines_per_turn
    player_id: int = 0
    hoard: list[str] = Field(default_factory=list)
    demo: bool = False


@app.post("/battle/judge")
async def battle_judge(req: BattleJudgeRequest) -> dict[str, Any]:
    """Judge a battle verse and write it: post_score, or decline_turn. Safe to retry."""
    if req.event not in events.EVENTS:
        raise HTTPException(400, f"unknown event: {req.event}")
    bt = BattleTurn(
        turn_id=req.turn_id,
        transcript=req.transcript,
        event=req.event,
        theme=req.theme,
        played=req.played,
        rescues=req.rescues,
        previous=req.previous or req.previous_best_line,
        lines_expected=req.lines_expected,
        player_id=req.player_id,
        hoard=req.hoard,
        demo=req.demo,
    )
    try:
        posted, j = await arena().judge_turn(bt)
    except EmptyVerse as exc:
        raise HTTPException(422, str(exc)) from None
    except Refused as exc:
        raise HTTPException(409, str(exc)) from None
    except StdbError as exc:
        raise HTTPException(502, str(exc)) from None
    return {"posted": posted, **scorecard(j, event=req.event)}


@app.exception_handler(ValueError)
async def bad_value(_: Request, exc: ValueError) -> JSONResponse:
    return JSONResponse({"detail": str(exc)}, status_code=400)
