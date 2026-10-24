"""Homer's lines outside the turn verdict: names, round verdicts, the song, spar verses.

Each is one strict-JSON Claude call with a cached system prompt, and the code
holds the answer to the facts: a carved line must come from a real verse, a
song line from a real turn, a spar verse must scan. When Claude fails, the
fallback is built from the poets' own words, never a canned line.
"""

from __future__ import annotations

import difflib
import re
from dataclasses import dataclass
from typing import Any

import anthropic

from . import claude, events, formulas
from .config import Settings, settings as load_settings
from .deal import deal
from .judge import clean_verdict
from .prompts import attr, block, host_system, quote_untrusted
from .scanner import VerseScan, scan_verse

NAME_MAX, EPITHET_MAX = 24, 32
SONG_MAX, DEMO_SONG_MAX = 16, 4
CALL_MAX_WORDS = 12  # the round call, before the carved line: ~7 s together (docs/gtm/demo-script.md)

STR = {"type": "string"}
INT = {"type": "integer"}


@dataclass
class Verse:
    turn_id: int
    poet: str
    transcript: str
    total: int = 0
    best_line: str = ""


def _lines(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if line.strip()]


def _lead_in(text: str) -> str:
    """Homer's round call as one short lead-in that ends in a colon, ready for the carved line."""
    first = re.split(r"(?<=[.!?:])\s", clean_verdict(text), maxsplit=1)[0]
    words = first.rstrip(" .!?:;,").split()[:CALL_MAX_WORDS]
    return " ".join(words) + ":" if words else ""


def _match_line(quoted: str, candidates: list[str]) -> str | None:
    """The candidate a quote refers to, or None if it was invented."""
    q = " ".join(quoted.split()).strip(" \"'“”").lower()
    if not q:
        return None
    for line in candidates:
        if q == line.lower() or (len(q) > 8 and q in line.lower()):
            return line
    close = difflib.get_close_matches(q, [line.lower() for line in candidates], n=1, cutoff=0.7)
    return next((line for line in candidates if line.lower() == close[0]), None) if close else None


class Host:
    def __init__(self, client: Any | None = None, cfg: Settings | None = None, event: str = "poetry") -> None:
        self.cfg = cfg or load_settings()
        self.client = client if client is not None else anthropic.AsyncAnthropic(timeout=self.cfg.timeout)
        self.event = events.get(event)

    def _kwargs(self, task: str, schema: dict[str, Any], user: str) -> dict[str, Any]:
        kw = claude.options(self.cfg.model, self.cfg.effort, schema, speed=self.cfg.speed, fallbacks=self.cfg.fallbacks)
        kw["system"] = claude.system(host_system(self.event, task))
        kw["messages"] = [{"role": "user", "content": user}]
        return kw

    async def _ask(self, task: str, schema: dict[str, Any], user: str) -> dict[str, Any] | None:
        return await claude.ask(self.client, self._kwargs(task, schema, user), self.cfg.timeout)

    # ----- The entrance ------------------------------------------------------

    async def name_poet(self, name: str, epithet: str = "") -> tuple[str, str, bool]:
        """A PG name and an epithet (coined if they brought none). Returns (name, epithet, coined)."""
        schema = claude.obj({"name": STR, "epithet": STR, "coined": {"type": "boolean"}})
        data = await self._ask("poet", schema, block("name", name) + "\n\n" + block("epithet", epithet))
        if data is None:  # keep what they typed; the arena announces the bare name
            return name.strip()[:NAME_MAX] or "Nameless", epithet.strip()[:EPITHET_MAX], False
        new_name = clean_verdict(str(data.get("name", ""))).strip(".!?")[:NAME_MAX] or name.strip()[:NAME_MAX]
        new_epithet = clean_verdict(str(data.get("epithet", ""))).strip(".!?")[:EPITHET_MAX]
        return new_name or "Nameless", new_epithet, bool(data.get("coined")) and new_epithet != epithet.strip()

    # ----- The round verdict and the carved line ---------------------------

    async def round_verdict(self, theme: str, verses: list[Verse]) -> tuple[str, int, str]:
        """Returns (verdict, best_turn_id, best_line).

        The verdict is what Homer speaks: a lead-in of at most twelve words,
        then the carved line itself, verbatim. The arena reads it once.
        """
        scored = [v for v in verses if _lines(v.transcript)]
        if not scored:
            return "", 0, ""
        top = max(scored, key=lambda v: v.total)
        fallback = (top.turn_id, top.best_line or _lines(top.transcript)[0])
        schema = claude.obj({"verdict": STR, "best_turn": INT, "best_line": STR})
        body = "\n\n".join(
            f'<verse turn="{v.turn_id}" poet="{attr(v.poet)}" total="{v.total}">\n'
            f"{quote_untrusted(v.transcript.strip())}\nbest_line: {quote_untrusted(v.best_line)}\n</verse>"
            for v in scored
        )
        data = await self._ask("verdict", schema, f"theme: {quote_untrusted(theme) or 'open'}\n\n{body}")
        if data is None:
            return "", *fallback
        by_id = {v.turn_id: v for v in scored}
        v = by_id.get(int(data.get("best_turn", 0)))
        line = _match_line(str(data.get("best_line", "")), _lines(v.transcript)) if v else None
        if v is None or line is None:  # an invented line is never carved
            best_turn, line = fallback
        else:
            best_turn = v.turn_id
        call = _lead_in(str(data.get("verdict", "")))
        return (f"{call} {line}" if call else ""), best_turn, line

    # ----- The stitched song -------------------------------------------------

    async def song(self, verses: list[Verse], demo: bool = False) -> list[tuple[int, str]]:
        """The battle's verses stitched into one poem: [(turn_id, line)]. Capped at 4 lines in demo mode."""
        cap = DEMO_SONG_MAX if demo else SONG_MAX
        spoken = [v for v in verses if _lines(v.transcript)]
        if not spoken:
            return []
        schema = claude.obj({"lines": {"type": "array", "items": claude.obj({"turn": INT, "text": STR})}})
        body = "\n\n".join(
            f'<verse turn="{v.turn_id}" poet="{attr(v.poet)}">\n{quote_untrusted(v.transcript.strip())}\n</verse>'
            for v in spoken
        )
        data = await self._ask("song", schema, f"max_lines: {cap}\n\n{body}")
        ids = {v.turn_id for v in spoken}
        out: list[tuple[int, str]] = []
        for item in (data or {}).get("lines", []):
            text = clean_verdict(str(item.get("text", ""))) if isinstance(item, dict) else ""
            if text and item.get("turn") in ids:
                out.append((int(item["turn"]), text))
        if not out:  # Claude failed: the poets' own best lines, in battle order
            out = [(v.turn_id, v.best_line or _lines(v.transcript)[0]) for v in spoken]
        return out[:cap]

    # ----- Homer's own verse (spar, lessons) ---------------------------------

    async def spar(self, theme: str, lines: int = 4, answer_to: str = "", hand: list[str] | None = None) -> tuple[list[str], VerseScan]:
        """Homer's verse from the formula engine: a hand of formulas, Claude, then the scanner.

        Lines that miss four hits get one fix-up call. That's a fresh request
        with the draft quoted, not an edited conversation.
        """
        lines = max(1, min(lines, 8))
        hand = hand or [c.text for c in deal(theme, n=6)]
        schema = claude.obj({"lines": {"type": "array", "items": STR}})
        ask = (
            f"theme: {quote_untrusted(theme) or 'open'}\nlines: {lines}\n"
            f"formulas: {'; '.join(quote_untrusted(h) for h in hand)}"
        )
        if answer_to.strip():
            ask += "\n\n" + block("answer_to", answer_to)
        verse = self._verse(await self._ask("spar", schema, ask), lines)
        scan = scan_verse("\n".join(verse), cards=[formulas.card(h) for h in hand] + list(formulas.bank()))
        misses = [(i, line) for i, line in enumerate(scan.lines) if line.hits != self.event.beats_per_line]
        if verse and misses:
            notes = "\n".join(f"line {i + 1} has {line.hits} hits: {line.pattern}" for i, line in misses)
            fix = f"{ask}\n\n{block('draft', chr(10).join(verse))}\n\nThe beat check:\n{notes}\nRewrite only those lines so each has four hits. Return all {lines} lines."
            fixed = self._verse(await self._ask("spar", schema, fix), lines)
            if fixed:
                rescanned = scan_verse("\n".join(fixed), cards=[formulas.card(h) for h in hand] + list(formulas.bank()))
                if rescanned.beat >= scan.beat:
                    verse, scan = fixed, rescanned
        return verse, scan

    @staticmethod
    def _verse(data: dict[str, Any] | None, n: int) -> list[str]:
        raw = (data or {}).get("lines", [])
        out = [" ".join(str(line).replace("/", " ").split()).lower() for line in raw if str(line).strip()]
        return out[:n]
