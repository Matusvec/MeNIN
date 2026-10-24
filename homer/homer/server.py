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
import random
import re
import time
from contextlib import asynccontextmanager
from dataclasses import asdict, is_dataclass
from typing import Any, Literal

import httpx2
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

from . import debate, events, formulas, moss_dealer
from .arena import Arena, BattleTurn, NotFound, Poet
from .config import settings
from .deal import Card, deal, pick_theme, rescue, themes
from .host import Host
from .lessons import Attempt, demo_lane, feedback as lesson_feedback, lessons, spoken_demo
from .judge import EmptyVerse, Judge, Judgment, Turn
from .scanner import TimedWord, VerseScan, beat_lane, scan_verse
from .stdb import Refused, Stdb, StdbError
from .claude import budget
from .guard import APP_KEY_HEADER, KEYED, AppKey, Guard, client_ip
from .voice import VoiceConfig, VoiceError, mint

log = logging.getLogger("homer")
if not log.handlers:  # one compact line per timed call, next to uvicorn's own log
    _handler = logging.StreamHandler()
    _handler.setFormatter(logging.Formatter("%(levelname)s homer: %(message)s"))
    log.addHandler(_handler)
    log.setLevel(logging.INFO)
    log.propagate = False

# Calls the demo waits on, and how long each may take before the log flags it SLOW (ms).
TIMED = {
    "/battle/judge": 2500, "/judge": 2500, "/battle/emotion": 2500, "/emotion": 2500, "/rescue": 300,
    "/battle/deal": 3000, "/battle/poet": 5000, "/battle/verdict": 5000, "/battle/song": 8000,
    "/debate/whispers": 5000, "/lesson/feedback": 6000, "/spar": 8000, "/voice/token": 1500,
}

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


def host() -> Host:
    return arena().host


async def written(work):
    """Run battle work that ends in a reducer call; map its failures to HTTP."""
    try:
        return await work
    except NotFound as exc:
        raise HTTPException(404, str(exc)) from None
    except Refused as exc:
        raise HTTPException(409, str(exc)) from None
    except StdbError as exc:
        raise HTTPException(502, str(exc)) from None


# What /health reports: the judge's prompt cache and the SpacetimeDB claim.
status: dict[str, str] = {"judge": "off", "stdb": "off"}


async def _warm_judge() -> None:
    status["judge"] = "warming"
    status["judge"] = "warm" if await judge().warm() else "failed"


@asynccontextmanager
async def lifespan(_: FastAPI):
    scan_verse("warm the dictionary")  # loads CMU once, before the first turn
    formulas.bank()
    cfg = settings()
    if os.environ.get("HOMER_WARM", "1") not in ("0", "false") and os.environ.get("ANTHROPIC_API_KEY"):
        asyncio.get_running_loop().create_task(_warm_judge())
    if (moss := moss_dealer.dealer()) is not None:  # HOMER_DEALER=moss: load the index in the background
        asyncio.get_running_loop().create_task(moss.start())
    if cfg.stdb_token:
        db = arena().db
        try:
            if cfg.service_key:
                try:
                    await db.claim_service()
                except Refused as exc:  # a rotated key; we may well be registered already
                    log.warning("%s", exc)
            status["stdb"] = "claimed" if await db.is_service() else "failed"
        except StdbError as exc:
            status["stdb"] = "unreachable"
            log.warning("spacetimedb: %s", exc)
    yield


app = FastAPI(title="Homer agent service", lifespan=lifespan)


_guard = Guard()


@app.middleware("http")
async def protect(request: Request, call_next):
    """The app key on the endpoints that spend credits, then a per-IP rate limit on every path."""
    path = request.url.path
    if path in KEYED and not AppKey.from_env().ok(request.headers.get(APP_KEY_HEADER)):
        return JSONResponse({"detail": "missing or wrong app key"}, status_code=401)
    ip = client_ip(request.headers, request.client.host if request.client else "?")
    if not _guard.allow(path, ip):
        log.warning("rate limited %s %s", path, ip)
        return JSONResponse({"detail": "too many requests; slow down"}, status_code=429)
    return await call_next(request)


@app.middleware("http")
async def timing(request: Request, call_next):
    """Log how long each demo-path call took, and flag the slow ones (streams: time to the first byte)."""
    t0 = time.perf_counter()
    response = await call_next(request)
    limit = TIMED.get(request.url.path)
    if limit is not None:
        ms = (time.perf_counter() - t0) * 1000
        slow = ms > limit
        log.log(logging.WARNING if slow else logging.INFO, "%s %s %d %.0fms%s",
                request.method, request.url.path, response.status_code, ms, " SLOW" if slow else "")
    return response


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
    side: str = ""  # debate: the side dealt to this debater
    turn_seconds: float | None = None  # debate: the turn's length, for keeping the floor
    spoken_seconds: float | None = None  # debate: Go to the end of the turn, for pace without word timings


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
        "delivery": camel(j.delivery) if j.delivery else None,  # debate: what Poise was measured from
        "made": j.made,  # debate: move ids the judge heard made
        "tappedUnmade": j.tapped_unmade,  # debate: tapped but not made, so no Craft for them (P17)
        "timing": j.timing,
        "model": j.model,
    }


# ----- Endpoints -------------------------------------------------------------


@app.get("/health")
async def health() -> dict[str, Any]:
    cfg = settings()
    if cfg.stdb_token and status["stdb"] in ("failed", "unreachable"):
        # The database may be back (a reboot, a key set late): look again rather than wait for a restart.
        try:
            status["stdb"] = "claimed" if await arena().db.is_service() else "failed"
        except StdbError:
            status["stdb"] = "unreachable"
    return {
        "ok": True,
        "judgeModel": cfg.judge_model,
        "judgeEffort": cfg.judge_effort,
        "judgeSpeed": cfg.judge_speed or "standard",
        "judge": status["judge"],  # off | warming | warm | failed: the prompt cache before the first turn
        "stdb": status["stdb"],  # off | claimed | failed | unreachable
        "stdbDb": cfg.stdb_db,
        "events": list(events.EVENTS),
        "budget": {k: f"{n}/{budget().caps[k]}" for k, n in budget().used().items()},  # calls in the last hour / cap
        "dealer": "moss" if (m := moss_dealer.dealer()) and m.ready else "tags",
    }


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
        side=req.side,
        turn_seconds=req.turn_seconds,
        spoken_seconds=req.spoken_seconds,
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


def card_json(c: Card) -> dict[str, Any]:
    """`FormulaCard` in Contracts.swift, plus beats and hoard."""
    return {"id": c.id, "text": c.text, "kind": c.kind, "used": False, "beats": c.beats, "hoard": c.hoard}


def move_json(m: debate.Move) -> dict[str, Any]:
    """A debate move card: `FormulaCard` with kind "move", plus its role and how it sounds as a question."""
    return {"id": m.id, "text": m.text, "kind": "move", "used": False, "beats": 0, "hoard": False, "role": m.role, "template": m.template}


def question_json(q: debate.Question) -> dict[str, Any]:
    return {"id": q.id, "ask": q.ask, "sides": [q.side_a, q.side_b], "kind": q.kind}


@app.get("/themes")
async def get_themes(n: int = 3, demo: bool = False) -> dict[str, Any]:
    """Theme cards for the arena or Practice. Demo mode gets the three rehearsed themes."""
    pool = list(themes())
    if demo:
        return {"themes": pool[:n]}
    return {"themes": random.sample(pool, min(n, len(pool)))}


class DealRequest(Model):
    theme: str = ""  # debate: a question's id or words
    hoard: list[str] = Field(default_factory=list)
    exclude: list[str] = Field(default_factory=list)  # cards already held or spent
    n: int = 5
    event: str = "poetry"


@app.post("/deal")
async def deal_hand(req: DealRequest) -> dict[str, Any]:
    """A hand for Practice (battle hands come from /battle/deal). An empty theme gets a random one."""
    n = max(1, min(req.n, 8))
    if events.get(req.event).hand == "moves":
        q = debate.question(req.theme) if req.theme.strip() else debate.pick_question()
        if q is None:
            raise HTTPException(404, f"no question {req.theme}")
        return {"theme": q.ask, "question": question_json(q), "hand": [move_json(m) for m in debate.deal(n, exclude=req.exclude)]}
    theme = req.theme.strip() or pick_theme()
    ranked = await moss_dealer.ranked_formulas(theme)  # None unless HOMER_DEALER=moss and Moss answers in time
    return {"theme": theme, "hand": [card_json(c) for c in deal(theme, req.hoard, n=n, exclude=req.exclude, ranked=ranked)]}


class RescueRequest(Model):
    transcript: str = ""
    hand: list[str]
    played: list[str] = Field(default_factory=list)
    theme: str = ""
    event: str = "poetry"
    previous: str = ""  # debate: the turn being answered
    elapsed_s: float = 0.0  # debate: seconds into the turn
    turn_seconds: float = 45.0  # debate
    whispers: dict[str, str] = Field(default_factory=dict)  # debate: from /debate/whispers at step-up


@app.post("/rescue")
async def rescue_card(req: RescueRequest) -> dict[str, Any]:
    """What the host whispers when the player freezes. No model call.

    Poetry: Homer whispers a formula that fits the line. Debate: one move is
    raised and Socrates whispers a question that performs it, the one prepared
    at step-up when there is one, else the move's template.
    """
    if events.get(req.event).hand == "moves":
        m = debate.rescue_move(req.hand, req.played, req.elapsed_s, req.turn_seconds, req.previous)
        if m is None:
            raise HTTPException(409, "no unplayed move in the hand")
        whisper = req.whispers.get(m.id) or debate.template_whisper(m, debate.question(req.theme), req.previous)
        return {"whisper": whisper, "card": move_json(m)}
    c = rescue(req.transcript, req.hand, played=req.played, theme=req.theme)
    if c is None:
        raise HTTPException(409, "no unplayed card in the hand")
    return {"formula": c.text, "card": card_json(c)}


@app.get("/debate")
async def debate_content() -> dict[str, Any]:
    """The debate content from content/debate.md and content/moves.json, for the app."""
    return {
        "questions": [question_json(q) for q in debate.questions()],
        "moves": [move_json(m) for m in debate.moves()],
        "lines": debate.lines(),
    }


class WhispersRequest(Model):
    question: str = ""  # a question's id or words (the round's theme)
    side: str = ""
    hand: list[str]
    previous: str = ""  # the turn this debater will answer, if any


@app.post("/debate/whispers")
async def debate_whispers(req: WhispersRequest) -> dict[str, Any]:
    """At step-up: one rescue question per move in the hand, so the freeze rescue plays instantly."""
    return {"whispers": await host().whispers(req.question, req.side, req.hand, req.previous)}


class PoetIn(Model):
    player_id: int
    name: str = ""
    epithet: str = ""
    hoard: list[str] = Field(default_factory=list)


class BattleDealRequest(Model):
    room_id: int
    round_no: int
    theme: str = ""  # room.next_theme when the judges picked one; empty and the agent picks
    poets: list[PoetIn] | None = None  # normally read from SQL


@app.post("/battle/deal")
async def battle_deal(req: BattleDealRequest) -> dict[str, Any]:
    """Pick the theme if it's empty, deal every poet, and call deal_round. Safe to retry."""
    poets = [Poet(p.player_id, p.name, p.epithet, p.hoard) for p in req.poets] if req.poets else None
    try:
        theme, hands = await arena().deal_round(req.room_id, req.round_no, req.theme, poets)
    except Refused as exc:
        raise HTTPException(409, str(exc)) from None
    except StdbError as exc:
        raise HTTPException(502, str(exc)) from None
    return {"theme": theme, "hands": {str(k): v for k, v in hands.items()}}


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
    side: str = ""  # debate: the side dealt to this debater (sides alternate by turn order)
    turn_seconds: float | None = None  # debate: room.turn_seconds, for keeping the floor
    spoken_seconds: float | None = None  # debate: Go (turn.beat_at) to end_turn, for pace


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
        side=req.side,
        turn_seconds=req.turn_seconds,
        spoken_seconds=req.spoken_seconds,
    )
    try:
        posted, j = await arena().judge_turn(bt)
        log.info("judge turn=%s %s verdict=%sms done=%sms%s", req.turn_id, req.event, j.timing.get("verdict", "-"),
                 j.timing.get("done", "-"), " SILENT " + j.error if j.silent else "")
    except EmptyVerse as exc:
        raise HTTPException(422, str(exc)) from None
    except Refused as exc:
        raise HTTPException(409, str(exc)) from None
    except StdbError as exc:
        raise HTTPException(502, str(exc)) from None
    return {"posted": posted, **scorecard(j, event=req.event)}


class VoiceTokenRequest(Model):
    role: Literal["phone", "arena", "solo"]
    room_code: str = ""
    player_id: int = 0


_voice_http: httpx2.AsyncClient | None = None
ROOM_CODE_RE = re.compile(r"^[A-Za-z]{4}$")


@app.post("/voice/token")
async def voice_token(req: VoiceTokenRequest, request: Request) -> dict[str, Any]:
    """A short-lived Cartesia token: phone gets stt, arena gets tts, solo gets both."""
    global _voice_http
    cfg = settings()
    if req.room_code and cfg.stdb_token:
        if not ROOM_CODE_RE.match(req.room_code):
            raise HTTPException(400, "bad room code")
        try:
            rooms = await arena().db.sql(f"SELECT id FROM room WHERE code = '{req.room_code.upper()}'")
        except StdbError as exc:  # never let the database take the voice down
            log.warning("room check skipped: %s", exc)
            rooms = [{}]
        if not rooms:
            raise HTTPException(403, "no such room")
    if _voice_http is None:
        _voice_http = httpx2.AsyncClient(timeout=5.0)
    try:
        return await mint(VoiceConfig.from_env(), req.role, _voice_http)
    except VoiceError as exc:
        raise HTTPException(503, str(exc)) from None


class BattlePoetRequest(Model):
    player_id: int
    name: str | None = None  # read from SQL when absent
    epithet: str | None = None


@app.post("/battle/poet")
async def battle_poet(req: BattlePoetRequest) -> dict[str, Any]:
    """A player row has named = false: PG-check the name, coin an epithet if empty, call name_poet."""
    name, epithet = await written(arena().name_poet(req.player_id, req.name, req.epithet))
    return {"name": name, "epithet": epithet}


class BattleVerdictRequest(Model):
    round_id: int


@app.post("/battle/verdict")
async def battle_verdict(req: BattleVerdictRequest) -> dict[str, Any]:
    """In round_end: Homer calls the round and the best line is carved (post_verdict)."""
    verdict, best_turn, line = await written(arena().round_verdict(req.round_id))
    return {"verdict": verdict, "bestTurnId": best_turn, "bestLine": line}


class BattleSongRequest(Model):
    room_id: int


@app.post("/battle/song")
async def battle_song(req: BattleSongRequest) -> dict[str, Any]:
    """Stitch every scored verse so far into the song (post_song). Call after round 1 to pre-stitch, then at the end."""
    lines = await written(arena().song(req.room_id))
    return {"lines": [{"turnId": t, "text": text} for t, text in lines]}


class EmotionRequest(Model):
    text: str = ""  # the transcript so far; the latest ~40 words are read
    transcript: str = ""  # the same, under the name turn.transcript uses
    loudness: float | None = None  # 0 to 1, from the prosody row
    pitch: float | None = None  # Hz, 0 = unvoiced
    turn_id: int = 0  # battle only

    @property
    def words(self) -> str:
        return self.text or self.transcript


@app.post("/emotion")
async def emotion_now(req: EmotionRequest) -> dict[str, Any]:
    """Weights over the eight emotions, for Practice and Bard. Keep them and send them to /judge as emotionHistory."""
    if not req.words.strip():
        raise HTTPException(422, "nothing to read")
    weights = await arena().classifier.classify(req.words, req.loudness, req.pitch)
    if weights is None:
        raise HTTPException(503, "no reading in time")
    return {"weights": weights}


@app.post("/battle/emotion")
async def battle_emotion(req: EmotionRequest) -> dict[str, Any]:
    """Every ~1.5 s while a battle turn is speaking: classify, keep the sample for Range, call set_scene."""
    if not req.turn_id:
        raise HTTPException(400, "turnId is required")
    weights = await written(arena().scene(req.turn_id, req.words, req.loudness, req.pitch))
    return {"weights": weights}


@app.get("/lessons")
async def get_lessons(bpm: float = 80) -> dict[str, Any]:
    """The Bard path from content/lessons.md: what Homer says, the demo verse and its beat lane."""
    return {
        "lessons": [
            {
                "id": l.id,
                "n": l.n,
                "title": l.title,
                "move": l.move,
                "exercise": l.exercise,
                "demo": l.demo,
                "demoSpoken": spoken_demo(l),
                "demoLane": demo_lane(l, bpm),
                "success": l.success,
                "exerciseSpoken": l.exercise,  # what Homer says to set up the try
                "exercise": l.exercise_lines,  # lines Homer speaks in the exercise (lessons 5 and 6), as notation
                "feedback": True,
            }
            for l in lessons().values()
        ]
    }


class LessonChecks:
    """What lessons need beyond the scanner: the judge (lesson 3), the classifier (4), Homer's reading (5, 6)."""

    async def craft(self, a: Attempt) -> int:
        j = await judge().judge(Turn(a.transcript, mode="lesson", theme="the poet's own battle title"))
        return j.scores["craft"] if not j.silent else 10  # a silent judge doesn't fail the poet

    async def emotions(self, lines: list[str]) -> list[dict[str, float] | None]:
        return list(await asyncio.gather(*(arena().classifier.classify(line) for line in lines)))

    async def answer(self, thrown: str, lines: list[str]) -> dict | None:
        return await host().lesson_answer(thrown, lines)

    async def boast(self, setup: list[str], closing: str) -> dict | None:
        return await host().lesson_boast(setup, closing)


class LessonFeedbackRequest(Model):
    lesson: str
    transcript: str = ""
    words: list[Word] | None = None
    bpm: float | None = None
    hand: list[str] = Field(default_factory=list)
    rescue: str = ""  # the card Homer whispered on this try, if he did
    name: str = ""  # the poet's name (lesson 3 finds the title after it)
    lines_expected: int | None = None
    prompt: str = ""  # lesson 5: the line Homer threw (one of the exercise's lines)
    try_no: int = 0  # this try's number in the lesson, 1-based: P10's help comes after the 3rd and 5th
    onsets_ms: list[float] | None = None  # lesson 1, with no word timings: the phone's stressed peaks, ms from beat 1


@app.post("/lesson/feedback")
async def lesson_feedback_endpoint(req: LessonFeedbackRequest) -> dict[str, Any]:
    """Homer's one line for a try: the first miss in the lesson's table, or its success line."""
    if req.lesson not in lessons():
        raise HTTPException(404, f"no lesson {req.lesson}")
    attempt = Attempt(
        req.lesson, req.transcript, _words(req), req.bpm, req.hand, req.rescue, req.name, req.lines_expected, req.prompt,
        try_no=req.try_no, onsets_ms=req.onsets_ms,
    )
    try:
        f = await lesson_feedback(attempt, checks=LessonChecks())
    except NotImplementedError as exc:
        raise HTTPException(501, str(exc)) from None
    return {
        "landed": f.landed,
        "line": f.line,
        "miss": f.miss,
        "title": f.title,
        "help": f.help,
        "scan": scan_json(f.scan, req.bpm) if f.scan else None,
    }


class SparRequest(Model):
    theme: str = ""  # debate: a question's id or words
    lines: int = 4  # debate: sentences
    answer_to: str = ""  # the player's turn the host answers
    hand: list[str] | None = None  # formulas to build from; dealt from the theme when absent
    bpm: float | None = None
    started_at: float = 0.0
    event: str = "poetry"
    side: str = ""  # debate: the side Socrates argues (the one the student wasn't dealt)


@app.post("/spar")
async def spar(req: SparRequest) -> dict[str, Any]:
    """The host's own turn in a spar. Homer: a verse from formulas, checked by the scanner. Socrates: the other side, in questions."""
    if events.get(req.event).hand == "moves":
        q = debate.question(req.theme) if req.theme.strip() else debate.pick_question()
        ask = q.ask if q else req.theme.strip()
        side = req.side or (q.side_b if q else "")
        lines = await host().spar_debate(ask, side, req.lines, req.answer_to)
        if not lines:
            raise HTTPException(503, "Socrates is silent on this one")
        return {"theme": ask, "side": side, "lines": lines}
    theme = req.theme.strip() or pick_theme()
    verse, scan = await host().spar(theme, req.lines, req.answer_to, req.hand)
    if not verse:
        raise HTTPException(503, "Homer is silent on this one")
    return {"theme": theme, "lines": verse, "scan": scan_json(scan, req.bpm, req.started_at)}


@app.exception_handler(ValueError)
async def bad_value(_: Request, exc: ValueError) -> JSONResponse:
    return JSONResponse({"detail": str(exc)}, status_code=400)
