"""The turn verdict: code scores what code can, then one streamed Claude call.

SPEC "Judge axes": Beat comes from the scanner and Range from the emotion
engine, both before Claude is called. Claude scores Craft, Image and Answer,
quotes the best line, and writes the spoken verdict, all in one call:

- No tool loop. The scanner's output is inlined in the prompt.
- Strict JSON through structured outputs, with `verdict` near the front so
  text-to-speech can start the moment it closes. The stream is watched for it.
- The system prompt (persona and rubric) is the same bytes on every call and
  is cached.
- Model, effort, speed and the timeout come from settings.

When Claude fails or runs past the timeout, the turn still scores: Beat and
Range stand, and Craft, Image and Answer are 0 ("Homer is silent on this
one"). There is never a canned verdict.
"""

from __future__ import annotations

import asyncio
import difflib
import json
import re
import time
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import Any

import anthropic

from . import emotion, events, formulas
from .config import Settings, settings as load_settings
from .events import Event
from .formulas import Formula
from .prompts import block, judge_system, quote_untrusted
from .scanner import TimedWord, VerseScan, scan_verse, strong_hits

FALLBACK_BETA = "server-side-fallback-2026-07-01"
FAST_BETA = "fast-mode-2026-02-01"
MAX_TOKENS = 2048  # a backstop; the reply itself is under ~100 tokens
SCORES = list(range(1, 11))
COIN_MIN_CRAFT = 7  # SPEC "Hoard": a coined formula joins only if the judge rated the verse well

VERDICT_RE = re.compile(r'"verdict"\s*:\s*"((?:[^"\\]|\\.)*)"')
UNFIT_RE = re.compile(r'"fit"\s*:\s*false')
MARKUP_RE = re.compile(r"[*_#`~<>\[\]{}|]")

# Models that take server-side refusal fallbacks ("default" form) and fast mode.
FALLBACK_MODELS = ("claude-opus-5-5", "claude-opus-5", "claude-fable-5-1", "claude-sonnet-5-5")
FAST_MODELS = ("claude-opus-5-5", "claude-opus-5", "claude-opus-4-8")

OnVerdict = Callable[[str], Awaitable[None] | None]


@dataclass
class Turn:
    transcript: str
    mode: str = "practice"  # practice | lesson | battle
    event: str = "poetry"
    theme: str = ""
    hand: list[str] = field(default_factory=list)  # in a battle, the cards dealt (remembered by the agent)
    played: list[str] = field(default_factory=list)
    rescues: int = 0
    previous: str = ""  # the verse this one answers, or its best line
    words: list[TimedWord] | None = None
    bpm: float | None = None
    lines_expected: int | None = None
    emotion_history: list[dict[str, float]] = field(default_factory=list)
    hoard: list[str] = field(default_factory=list)
    demo: bool = False


@dataclass
class Judgment:
    scores: dict[str, int]
    verdict: str = ""
    best_line: str = ""
    coined: str = ""
    declined: bool = False  # not fit for the hall
    silent: bool = False  # Claude didn't answer in time: Craft, Image and Answer are 0
    error: str = ""
    scan: VerseScan | None = None
    timing: dict[str, float] = field(default_factory=dict)  # ms from the request
    model: str = ""
    usage: dict[str, int] = field(default_factory=dict)

    @property
    def total(self) -> int:
        return sum(self.scores.values())


class EmptyVerse(ValueError):
    pass


def output_schema(event: Event) -> dict[str, Any]:
    props: dict[str, Any] = {
        "fit": {"type": "boolean"},
        "verdict": {"type": "string"},
        "best_line": {"type": "string"},
    }
    for axis in event.claude_axes:
        props[axis.key] = {"type": "integer", "enum": SCORES}
    props["coined"] = {"type": "string"}
    return {"type": "object", "properties": props, "required": list(props), "additionalProperties": False}


def thinking_for(model: str, mode: str) -> dict[str, str] | None:
    """The `thinking` setting, or None to omit it.

    Claude Opus 5.5 can't turn thinking off; low effort keeps it short.
    """
    if mode != "off":
        return {"type": "adaptive"}
    if model == "claude-sonnet-5-5":
        return {"type": "between_tools"}
    if model in ("claude-haiku-5-5", "claude-sonnet-5", "claude-opus-5"):
        return {"type": "disabled"}
    return None


def clean_verdict(text: str) -> str:
    """Plain, speakable text: no markup, at most two sentences."""
    text = MARKUP_RE.sub("", text)
    text = " ".join(text.split()).strip().strip("\"'“”")
    sentences = re.findall(r"[^.!?]+[.!?]*", text)
    return "".join(sentences[:2]).strip() if len(sentences) > 2 else text


def _ms(t0: float) -> float:
    return round((time.perf_counter() - t0) * 1000, 1)


class Judge:
    def __init__(self, client: Any | None = None, cfg: Settings | None = None) -> None:
        self.cfg = cfg or load_settings()
        self.client = client if client is not None else anthropic.AsyncAnthropic(timeout=self.cfg.judge_timeout)

    # ----- Building the call -----------------------------------------------

    def cards(self, turn: Turn) -> list[Formula]:
        """The poet's cards first, then the whole bank, without repeats."""
        seen: set[tuple[str, ...]] = set()
        out = []
        for f in [formulas.card(t) for t in turn.hand + turn.played + turn.hoard] + list(formulas.bank()):
            k = formulas.key(f.text)
            if k and k not in seen:
                seen.add(k)
                out.append(f)
        return out

    def scan(self, turn: Turn, event: Event) -> VerseScan:
        return scan_verse(
            turn.transcript,
            words=turn.words,
            bpm=turn.bpm,
            beats_per_line=event.beats_per_line,
            lines_expected=turn.lines_expected,
            cards=self.cards(turn),
        )

    def user_content(self, turn: Turn, scan: VerseScan) -> str:
        texts = {f.id: f.text for f in self.cards(turn)}
        hand = turn.played if turn.mode == "battle" else turn.hand or turn.played
        spoken = list(dict.fromkeys(texts.get(i, i) for i in scan.formulas))
        info = [
            f"mode: {turn.mode}",
            f"theme: {quote_untrusted(turn.theme.strip()) or 'open'}",
            f"hand: {'; '.join(quote_untrusted(c) for c in hand) or 'none'}",
            f"formulas spoken: {'; '.join(quote_untrusted(s) for s in spoken) or 'none'}",
            f"rescues: {turn.rescues}",
        ]
        lines = [f"line {i + 1}, {line.hits} hits: {line.pattern}" for i, line in enumerate(scan.lines)]
        lines.append(f"{len(scan.lines)} of {scan.lines_expected} lines spoken")
        previous = (
            block("previous_verse", turn.previous)
            if turn.previous.strip()
            else "<previous_verse>\nnone: this verse answers the theme\n</previous_verse>"
        )
        return "\n\n".join(
            [
                "<turn>\n" + "\n".join(info) + "\n</turn>",
                previous,
                block("beat_scan", "\n".join(lines)),
                block("verse", "\n".join(line.text for line in scan.lines)),
            ]
        )

    def request(self, turn: Turn, event: Event, scan: VerseScan) -> dict[str, Any]:
        cfg, model = self.cfg, self.cfg.judge_model
        kwargs: dict[str, Any] = {
            "model": model,
            "max_tokens": MAX_TOKENS,
            "system": [
                {"type": "text", "text": judge_system(event), "cache_control": {"type": "ephemeral", "ttl": "1h"}}
            ],
            "messages": [{"role": "user", "content": self.user_content(turn, scan)}],
            "output_config": {
                "effort": cfg.judge_effort,
                "format": {"type": "json_schema", "schema": output_schema(event)},
            },
        }
        thinking = thinking_for(model, cfg.judge_thinking)
        if thinking:
            kwargs["thinking"] = thinking
        betas = []
        if cfg.fallbacks and model in FALLBACK_MODELS:
            betas.append(FALLBACK_BETA)
            kwargs["fallbacks"] = "default"
        if cfg.judge_speed == "fast" and model in FAST_MODELS:
            betas.append(FAST_BETA)
            kwargs["speed"] = "fast"
        if betas:
            kwargs["betas"] = betas
        return kwargs

    # ----- Judging ---------------------------------------------------------

    async def judge(self, turn: Turn, on_verdict: OnVerdict | None = None) -> Judgment:
        t0 = time.perf_counter()
        event = events.get(turn.event)
        scan = self.scan(turn, event)
        if not any(line.words for line in scan.lines):
            raise EmptyVerse("nothing to judge")
        lines = [line.text for line in scan.lines]
        scores = {a.key: 0 for a in event.axes}
        scores["beat"] = scan.beat
        scores["range"] = emotion.range_score(turn.emotion_history, lines)
        j = Judgment(scores=scores, scan=scan, model=self.cfg.judge_model)
        j.timing["scan"] = _ms(t0)

        try:
            text, final = await asyncio.wait_for(
                self._stream(self.request(turn, event, scan), j, t0, on_verdict), self.cfg.judge_timeout
            )
        except (asyncio.TimeoutError, anthropic.APIError) as exc:
            j.silent, j.error = True, type(exc).__name__
            j.best_line = lines[scan.best_line] if scan.best_line is not None else ""
            j.timing["done"] = _ms(t0)
            return j
        j.timing["done"] = _ms(t0)
        j.model = getattr(final, "model", j.model) or j.model
        usage = getattr(final, "usage", None)
        if usage is not None:
            for k in ("input_tokens", "output_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"):
                j.usage[k] = getattr(usage, k, 0) or 0

        if final.stop_reason == "refusal":
            j.declined = True
            return j
        try:
            data = json.loads(text)
        except json.JSONDecodeError:
            j.silent, j.error = True, f"bad JSON (stop_reason={final.stop_reason})"
            j.best_line = lines[scan.best_line] if scan.best_line is not None else ""
            return j
        if not data.get("fit", True):
            j.declined = True
            return j

        for axis in event.claude_axes:
            j.scores[axis.key] = max(1, min(10, int(data.get(axis.key, 1))))
        j.verdict = clean_verdict(str(data.get("verdict", "")))
        j.best_line = self._best_line(str(data.get("best_line", "")), lines, scan)
        j.coined = self._coined(str(data.get("coined", "")), turn, lines, j.scores.get("craft", 0))
        return j

    async def _stream(self, kwargs: dict[str, Any], j: Judgment, t0: float, on_verdict: OnVerdict | None):
        text, sent = "", False
        async with self.client.beta.messages.stream(**kwargs) as stream:
            async for ev in stream:
                if ev.type == "content_block_start" and ev.content_block.type == "text":
                    text = ""  # a fresh text block (after a fallback) starts over
                elif ev.type == "content_block_delta" and ev.delta.type == "text_delta":
                    j.timing.setdefault("first_token", _ms(t0))
                    text += ev.delta.text
                    if not sent and (m := VERDICT_RE.search(text)):
                        sent = True
                        j.timing["verdict"] = _ms(t0)
                        verdict = clean_verdict(json.loads(f'"{m.group(1)}"'))
                        if on_verdict and verdict and not UNFIT_RE.search(text):
                            result = on_verdict(verdict)
                            if asyncio.iscoroutine(result):
                                await result
            final = await stream.get_final_message()
        return text, final

    @staticmethod
    def _best_line(quoted: str, lines: list[str], scan: VerseScan) -> str:
        """The quoted line, held to the verse: a line, or a span of one, never invented."""
        q = " ".join(quoted.split()).strip(" \"'“”")
        if q:
            for line in lines:
                if q.lower() == line.lower() or (len(q) > 8 and q.lower() in line.lower()):
                    return q if q.lower() != line.lower() else line
            close = difflib.get_close_matches(q.lower(), [line.lower() for line in lines], n=1, cutoff=0.6)
            if close:
                return lines[[line.lower() for line in lines].index(close[0])]
        return lines[scan.best_line] if scan.best_line is not None else ""

    def _coined(self, coined: str, turn: Turn, lines: list[str], craft: int) -> str:
        """Keep a coined formula only if it is new, really in the verse, scans, and the verse rated well."""
        if turn.demo or not coined.strip() or craft < COIN_MIN_CRAFT:
            return ""
        k = formulas.key(coined)
        if not 1 <= len(k) <= 5 or k in {formulas.key(f.text) for f in self.cards(turn)}:
            return ""
        spoken = [tuple(formulas.tokens(line)) for line in lines]
        if not any(k == words[i : i + len(k)] for words in spoken for i in range(len(words))):
            return ""
        if not 1 <= strong_hits(coined) <= 2:
            return ""
        return " ".join(coined.split()).strip(" \"'“”.,;:!?")

    async def warm(self) -> None:
        """One real judge call so the system prompt is cached before the first turn."""
        turn = Turn(transcript="the wind was cold, the waves were grey\nthe sea kept time and so did I", theme="the sea")
        try:
            await self.judge(turn)
        except Exception:
            pass
