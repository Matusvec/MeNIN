"""The turn verdict: code scores what code can, then one streamed Claude call.

SPEC "Judge axes": Flow (key `beat`) comes from the scanner and Range from the
emotion engine, both before Claude is called. Claude scores Craft, Image and
Answer, quotes the best line, and writes the spoken verdict, all in one call.
A battle verse counts content only: Image x4, Answer x4, Craft x2, out of 100;
Flow and Range are computed but weigh 0 (events.py, the module's post_score):

- No tool loop. The scanner's output is inlined in the prompt.
- Strict JSON through structured outputs, with `verdict` near the front so
  text-to-speech can start the moment it closes. The stream is watched for it.
- The system prompt (persona and rubric) is the same bytes on every call and
  is cached.
- Model, effort, speed and the timeout come from settings.

When Claude fails or runs past the timeout, the turn still scores: Flow and
Range stand, Craft, Image and Answer take the neutral SILENT_SCORE (4, so 40/100),
and the verdict is SILENT_VERDICT, "Homer is silent on this one.", which every
client shows as a neutral fallback. There is never an invented verdict.
"""

from __future__ import annotations

import asyncio
import difflib
import json
import logging
import re
import time
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import Any

import anthropic

from . import claude, debate, emotion, events, formulas
from .config import Settings, settings as load_settings
from .events import Event
from .formulas import Formula
from .prompts import block, judge_system, quote_untrusted
from .debate import Delivery
from .guard import BudgetExceeded
from .scanner import TimedWord, VerseScan, scan_verse, strong_hits

log = logging.getLogger("homer")

SCORES = list(range(1, 11))
COIN_MIN_CRAFT = 7  # SPEC "Hoard": a coined formula joins only if the judge rated the verse well

VERDICT_RE = re.compile(r'"verdict"\s*:\s*"((?:[^"\\]|\\.)*)"')
QUOTE_RE = re.compile(r'"quote"\s*:\s*"((?:[^"\\]|\\.)*)"')
UNFIT_RE = re.compile(r'"fit"\s*:\s*false')
MARKUP_RE = re.compile(r"[*_#`~<>\[\]{}|]")

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
    previous: str = ""  # the verse (or debate turn) this one answers, or its best line
    words: list[TimedWord] | None = None
    bpm: float | None = None
    lines_expected: int | None = None
    emotion_history: list[dict[str, float]] = field(default_factory=list)
    hoard: list[str] = field(default_factory=list)
    demo: bool = False
    side: str = ""  # debate: the side this debater was dealt
    turn_seconds: float | None = None  # debate: the turn's length, for keeping the floor
    spoken_seconds: float | None = None  # debate: Go to the end of the turn, for pace when there are no word timings


@dataclass
class Judgment:
    scores: dict[str, int]
    verdict: str = ""
    best_line: str = ""
    coined: str = ""
    declined: bool = False  # not fit for the hall
    silent: bool = False  # Claude didn't answer in time: Craft, Image and Answer are SILENT_SCORE
    error: str = ""
    scan: VerseScan | None = None
    delivery: Delivery | None = None  # debate: what Poise was measured from
    made: list[str] = field(default_factory=list)  # debate: move ids the judge heard made, tapped or not
    tapped_unmade: list[str] = field(default_factory=list)  # debate: tapped but not made (P17: no Craft)
    timing: dict[str, float] = field(default_factory=dict)  # ms from the request
    model: str = ""
    usage: dict[str, int] = field(default_factory=dict)

    weights: dict[str, int] = field(default_factory=dict)  # by axis key; 1 when missing

    @property
    def total(self) -> int:
        """Weighted like the module's post_score: a poetry verse is out of 100 (Image, Answer x4, Craft x2; Flow, Range 0)."""
        return sum(v * self.weights.get(k, 1) for k, v in self.scores.items())


# Claude's axes when the judge never answered (timeout, outage, unreadable reply). The battle score is
# content only, so a 0 would sink a poet for our failure; 4 is the low end of "a real attempt" (40/100),
# about where the day's real verses landed (22-40), so a timeout neither punishes nor rewards much.
SILENT_SCORE = 4
# ...and the verdict posted with it, so every client can tell a neutral fallback from a judgment and say so
# (the website's lib/arena.ts SILENT_VERDICT and the phone match it exactly).
SILENT_VERDICT = "Homer is silent on this one."


class EmptyVerse(ValueError):
    pass


def output_schema(event: Event) -> dict[str, Any]:
    props: dict[str, Any] = {
        "fit": {"type": "boolean"},
        "quote": {"type": "string"},  # their words, said first; code joins it to the call (see spoken)
        "verdict": {"type": "string"},
        "best_line": {"type": "string"},
    }
    for axis in event.claude_axes:
        props[axis.key] = {"type": "integer", "enum": SCORES}
    if event.hoard:
        props["coined"] = {"type": "string"}
    if event.hand == "moves":
        props["made"] = {"type": "array", "items": {"type": "string"}}
    return claude.obj(props)


SENTENCE_RE = re.compile(r"(?<=[.!?])\s+|\n+")


def sentences(text: str, chunk: int = 24) -> list[str]:
    """A spoken turn as sentences; unpunctuated speech is cut into chunks of about `chunk` words."""
    out = []
    for part in SENTENCE_RE.split(text.strip()):
        words = part.split()
        out.extend(" ".join(words[i : i + chunk]) for i in range(0, len(words), chunk))
    return [s for s in out if s]


def spoken(quote: str, call: str) -> str:
    """Their words, then Homer's call: "A plate by the door. That empty chair sank the fleet."

    Claude writes the two apart (a copy, then a one-sentence call), which keeps
    its thinking as short as the call alone; joining them here is free.
    """
    q = " ".join(MARKUP_RE.sub("", quote).split()).strip(" \"'“”.,;:!?—-")
    c = clean_verdict(call)
    if not q or q.lower() in c.lower():
        return c
    return clean_verdict(f"{q[:1].upper()}{q[1:]}. {c}" if c else f"{q[:1].upper()}{q[1:]}.")


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

    def debate_content(self, turn: Turn, d: Delivery) -> str:
        hand = [m for m in (debate.move(c) for c in dict.fromkeys(turn.hand + turn.played)) if m]
        tapped = [m.id for m in (debate.move(p) for p in turn.played) if m]
        info = [
            f"mode: {turn.mode}",
            f"question: {quote_untrusted(turn.theme.strip()) or 'open'}",
            f"side: {quote_untrusted(turn.side.strip()) or 'not given'}",
            "hand:" + ("".join(f"\n- {m.id} ({m.role}): {quote_untrusted(m.template)}" for m in hand) or " none"),
            f"tapped: {', '.join(tapped) or 'none'}",
            f"rescues: {turn.rescues}",
        ]
        facts = [f"{d.words} words", f"fillers: {len(d.fillers)}" + (f" ({', '.join(sorted(set(d.fillers)))})" if d.fillers else "")]
        if d.wpm is not None:
            facts.append(f"pace: {d.wpm:.0f} words a minute")
        if d.longest_silence_ms is not None:
            facts.append(f"longest silence: {d.longest_silence_ms / 1000:.1f} s")
        facts.append(f"dead air (2 s or more, including rescues): {d.dead_air}")
        previous = (
            block("previous_turn", turn.previous)
            if turn.previous.strip()
            else "<previous_turn>\nnone: this turn answers the question\n</previous_turn>"
        )
        return "\n\n".join(
            [
                "<turn>\n" + "\n".join(info) + "\n</turn>",
                previous,
                block("delivery", "\n".join(facts)),
                block("argument", turn.transcript),
            ]
        )

    def request(self, turn: Turn, event: Event, content: VerseScan | str) -> dict[str, Any]:
        """The Claude call. `content` is the poetry scan, or a user message already built."""
        if not isinstance(content, str):
            content = self.user_content(turn, content)
        cfg = self.cfg
        kwargs = claude.options(
            cfg.judge_model,
            cfg.judge_effort,
            output_schema(event),
            speed=cfg.judge_speed,
            thinking=cfg.judge_thinking,
            fallbacks=cfg.fallbacks,
        )
        kwargs["system"] = claude.system(judge_system(event))
        kwargs["messages"] = [{"role": "user", "content": content}]
        return kwargs

    # ----- Judging ---------------------------------------------------------

    async def judge(self, turn: Turn, on_verdict: OnVerdict | None = None) -> Judgment:
        t0 = time.perf_counter()
        event = events.get(turn.event)
        j = Judgment(scores={a.key: 0 for a in event.axes}, weights={a.key: a.weight for a in event.axes}, model=self.cfg.judge_model)
        if event.hand == "moves":  # debate: Poise from the delivery
            text = turn.transcript or " ".join(w.text for w in turn.words or [])
            if not text.strip():
                raise EmptyVerse("nothing to judge")
            turn.transcript = text
            j.delivery = debate.poise(text, turn.words, turn.turn_seconds, turn.rescues, turn.spoken_seconds)
            j.scores["poise"] = j.delivery.poise
            lines = sentences(text)
            fallback = max(range(len(lines)), key=lambda i: len(lines[i].split())) if lines else None
            content = self.debate_content(turn, j.delivery)
        else:  # poetry: Beat from the scanner, Range from the emotion samples
            j.scan = scan = self.scan(turn, event)
            if not any(line.words for line in scan.lines):
                raise EmptyVerse("nothing to judge")
            lines = [line.text for line in scan.lines]
            j.scores["beat"] = scan.flow  # "Flow" on screen; the key stays beat
            j.scores["range"] = emotion.range_score(turn.emotion_history, lines)
            fallback = scan.best_line
            content = self.user_content(turn, scan)
        j.timing["scan"] = _ms(t0)

        try:
            text, final = await asyncio.wait_for(
                self._call(self.request(turn, event, content), j, t0, on_verdict), self.cfg.judge_timeout
            )
        except anthropic.APIError as exc:
            # An error back in a blink (a connection reset, an overload) gets one more try in what's left of
            # the time; a slow failure doesn't (it already spent the budget).
            left = self.cfg.judge_timeout - (time.perf_counter() - t0)
            if left < 2.0:
                return self._silent(j, event, lines, fallback, t0, exc)
            log.warning("judge call failed fast (%s); trying once more", type(exc).__name__)
            await asyncio.sleep(0.3)
            try:
                text, final = await asyncio.wait_for(
                    self._call(self.request(turn, event, content), j, t0, on_verdict), left - 0.3
                )
            except (asyncio.TimeoutError, anthropic.APIError, BudgetExceeded) as again:
                return self._silent(j, event, lines, fallback, t0, again)
        except (asyncio.TimeoutError, BudgetExceeded) as exc:
            return self._silent(j, event, lines, fallback, t0, exc)
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
            j.scores.update({a.key: SILENT_SCORE for a in event.claude_axes})
            j.verdict = SILENT_VERDICT
            j.best_line = lines[fallback] if fallback is not None else ""
            return j
        if not data.get("fit", True):
            j.declined = True
            return j

        for axis in event.claude_axes:
            j.scores[axis.key] = max(1, min(10, int(data.get(axis.key, 1))))
        j.verdict = spoken(str(data.get("quote", "")), str(data.get("verdict", "")))
        j.best_line = self._best_line(str(data.get("best_line", "")), lines, fallback)
        if event.hoard:
            j.coined = self._coined(str(data.get("coined", "")), turn, lines, j.scores.get("craft", 0))
        if event.hand == "moves":
            j.verdict = debate.plain_moves(j.verdict)
            j.best_line = debate.clean_line(j.best_line)
            dealt = {m.id for m in (debate.move(c) for c in turn.hand + turn.played) if m}
            j.made = [i for i in dict.fromkeys(str(x) for x in data.get("made", []) or []) if i in dealt]
            tapped = [m.id for m in (debate.move(p) for p in turn.played) if m]
            j.tapped_unmade = [t for t in tapped if t not in j.made]
        return j

    async def _call(self, kwargs: dict[str, Any], j: Judgment, t0: float, on_verdict: OnVerdict | None):
        sent = False

        async def watch(text: str) -> None:
            """Send the verdict on as soon as its string closes in the stream."""
            nonlocal sent
            j.timing.setdefault("first_token", _ms(t0))
            if sent or not (m := VERDICT_RE.search(text)):
                return
            sent = True
            j.timing["verdict"] = _ms(t0)
            q = QUOTE_RE.search(text)
            verdict = spoken(json.loads(f'"{q.group(1)}"') if q else "", json.loads(f'"{m.group(1)}"'))
            if on_verdict and verdict and not UNFIT_RE.search(text):
                result = on_verdict(verdict)
                if asyncio.iscoroutine(result):
                    await result

        return await claude.complete(self.client, kwargs, watch)

    @staticmethod
    def _best_line(quoted: str, lines: list[str], fallback: int | None) -> str:
        """The quoted line, held to the verse (or turn): a line, or a span of one, never invented."""
        q = " ".join(quoted.split()).strip(" \"'“”")
        if q:
            for line in lines:
                if q.lower() == line.lower() or (len(q) > 8 and q.lower() in line.lower()):
                    return q if q.lower() != line.lower() else line
            close = difflib.get_close_matches(q.lower(), [line.lower() for line in lines], n=1, cutoff=0.6)
            if close:
                return lines[[line.lower() for line in lines].index(close[0])]
        return lines[fallback] if fallback is not None else ""

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

    def _silent(self, j: Judgment, event, lines: list[str], fallback: int | None, t0: float, exc: BaseException) -> Judgment:
        """Claude didn't answer: the neutral score and SILENT_VERDICT, and the cause in the log."""
        j.silent, j.error = True, type(exc).__name__
        log.warning("judge silent after %d ms: %s %s", _ms(t0), j.error, str(exc)[:160])
        j.scores.update({a.key: SILENT_SCORE for a in event.claude_axes})
        j.verdict = SILENT_VERDICT
        j.best_line = lines[fallback] if fallback is not None else ""
        if event.hand == "moves":
            j.best_line = debate.clean_line(j.best_line)
        j.timing["done"] = _ms(t0)
        return j

    async def warm(self) -> bool:
        """One real judge call so the system prompt is cached before the first turn."""
        turn = Turn(transcript="the wind was cold, the waves were grey\nthe sea kept time and so did I", theme="the sea")
        try:
            j = await self.judge(turn)
        except Exception:
            log.exception("warm-up judge call failed")
            return False
        return not j.silent
