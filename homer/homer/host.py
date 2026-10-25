"""Homer's lines outside the turn verdict: names, round verdicts, the song, spar verses.

Each is one strict-JSON Claude call with a cached system prompt, and the code
holds the answer to the facts: a carved line must come from a real verse, a
song line from a real turn, a spar verse must scan. When Claude fails, the
fallback is built from the poets' own words, never a canned line.
"""

from __future__ import annotations

import difflib
import random
import re
from collections.abc import Iterable
from dataclasses import dataclass
from typing import Any

import anthropic

from . import claude, debate, events, formulas
from .config import Settings, settings as load_settings
from .deal import deal
from .events import Event
from .judge import clean_verdict, sentences
from .prompts import attr, block, host_system, quote_untrusted
from .scanner import VerseScan, scan_verse, strong_hits
from .style import modern

NAME_MAX, EPITHET_MAX = 24, 32
THEME_WORDS, CALL_WORDS = 6, 6
COACH_TURNS, COACH_TEXT_MAX, COACH_WORDS = 8, 600, 45  # the conversation Homer sees, a turn's length, his reply
VERSE_MAX = 400  # characters of a poet's last verse sent to seed an epithet
SILENT_ROUND = "Silence in the hall. No verse this round."  # every turn skipped: still a call, so the round can end
# A nudge per epithet, so the same name doesn't always get the same title (Claude settles on one).
ANGLES = ("a trade or a tool", "an animal", "a place", "a time of day", "the weather", "a sound", "food or drink",
          "a game", "the sky", "a machine", "a small household thing", "a journey")
SONG_MAX, DEMO_SONG_MAX = 16, 4
SONG_MIN_HITS = 3  # a frozen fragment under this is never sung; a line a hit short, Homer completes
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


def _units(text: str, event: Event) -> list[str]:
    """What a best line can be: a line of verse, or a sentence of a debate turn."""
    return sentences(text) if event.hand == "moves" else _lines(text)


def _lines(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if line.strip()]


@dataclass(frozen=True)
class Coaching:
    """Homer's turn in Talk to Homer: his line, and the attempt's content scores when it was a verse."""

    reply: str
    attempt: bool
    scores: dict[str, int]  # craft, image, answer (1..10); ignored unless attempt


def _title_key(text: str) -> str:
    """An epithet or theme for comparing: lowercase letters and spaces, no leading "the"."""
    words = re.sub(r"[^a-z ]+", " ", text.lower()).split()
    return " ".join(words[1:] if words[:1] == ["the"] else words)


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


def _on_the_beat(lines: list[tuple[int, str]], cap: int) -> list[tuple[int, str]]:
    """The song as it will be sung over the beat: no fragments, and the four-hit lines first when it's too long.

    Order stays the battle's, and the closing line always stays: the song builds to it.
    """
    hits = {i: (scan_verse(text).lines or [None])[0] for i, (_, text) in enumerate(lines)}
    keep = [i for i, scan in hits.items() if scan is not None and scan.hits >= SONG_MIN_HITS] or list(hits)[:cap]
    if len(keep) > cap:
        last = keep[-1]
        keep = sorted(sorted(keep[:-1], key=lambda i: abs(hits[i].hits - 4))[: cap - 1] + [last])
    return [lines[i] for i in keep]


class Host:
    def __init__(self, client: Any | None = None, cfg: Settings | None = None, event: str = "poetry") -> None:
        self.cfg = cfg or load_settings()
        self.client = client if client is not None else anthropic.AsyncAnthropic(timeout=self.cfg.timeout)
        self.event = events.get(event)

    def _kwargs(self, task: str, schema: dict[str, Any], user: str, event: Event | None = None) -> dict[str, Any]:
        ev = event or self.event
        kw = claude.options(self.cfg.model, self.cfg.effort, schema, speed=self.cfg.speed, fallbacks=self.cfg.fallbacks)
        kw["system"] = claude.system(host_system(ev, ev.task(task)))
        kw["messages"] = [{"role": "user", "content": user}]
        return kw

    async def _ask(self, task: str, schema: dict[str, Any], user: str, event: Event | None = None) -> dict[str, Any] | None:
        return await claude.ask(self.client, self._kwargs(task, schema, user, event), self.cfg.timeout)

    # ----- The entrance ------------------------------------------------------

    async def name_poet(
        self, name: str, brought: str = "", event: Event | None = None, worn: Iterable[str] = (), last_verse: str = ""
    ) -> tuple[str, str, bool]:
        """A PG name and a freshly coined epithet, never one in `worn` (the poet's recent ones).

        Matus: the same epithet every battle is boring. Seeded with their last verse
        when there is one. Without Claude, the poet keeps the epithet they `brought`.
        Returns (name, epithet, coined).
        """
        ev = event or self.event
        worn = [w for w in dict.fromkeys(x.strip() for x in worn) if w]
        schema = claude.obj({"name": STR, "epithet": STR, "alternatives": {"type": "array", "items": STR}})
        user = "\n\n".join([block("name", name), block("worn", "\n".join(worn)), block("last_verse", last_verse[:VERSE_MAX]),
                            block("angle", random.choice(ANGLES))])
        data = await self._ask("poet", schema, user, event)
        kept = name.strip()[:NAME_MAX] or "Nameless", brought.strip()[:EPITHET_MAX], False
        if data is None:  # the arena announces them with what they brought
            return kept
        new_name = clean_verdict(str(data.get("name", ""))).strip(".!?")[:NAME_MAX] or kept[0]
        seen = {_title_key(w) for w in worn}
        options = [clean_verdict(str(e)).strip(".!?")[:EPITHET_MAX] for e in [data.get("epithet", ""), *data.get("alternatives", [])]]
        options = [e for e in options if e and _title_key(e) not in seen and not modern(e)]  # Homer's world only
        if not options:
            return new_name, kept[1], False
        # It must fill half a line: the first the scanner hears as two hits.
        pick = next((e for e in options if strong_hits(e) == 2), options[0]) if ev.beat else options[0]
        return new_name, pick, True

    # ----- Talk to Homer (the coach event) -----------------------------------

    async def coach(self, history: list[tuple[str, str, str]], theme: str) -> Coaching:
        """Homer's next line in a coach conversation ([(who, name, text)] oldest first, "homer" or "poet"),
        and, when the poet's last turn was a verse attempt, its scores on the battle's content axes.

        Two sentences at most, about forty words; reply "" if Claude failed.
        """
        convo = "\n".join(
            f'<turn who="{who}"' + (f' name="{attr(name)}"' if name else "") + f">\n{quote_untrusted(text[:COACH_TEXT_MAX])}\n</turn>"
            for who, name, text in history[-COACH_TURNS:]
        )
        schema = claude.obj({"attempt": {"type": "boolean"}, "image": INT, "answer": INT, "craft": INT, "reply": STR})
        data = await self._ask("coach", schema, f"theme: {quote_untrusted(theme) or 'open'}\n\n{convo}", events.COACH) or {}
        reply = clean_verdict(str(data.get("reply", "")))
        if len(reply.split()) > COACH_WORDS:  # the second sentence ran long: keep the first
            reply = re.findall(r"[^.!?]+[.!?]*", reply)[0].strip()
        score = {k: max(1, min(10, int(data.get(k, 1) or 1))) for k in ("craft", "image", "answer")}
        return Coaching(reply, bool(data.get("attempt")) and bool(reply), score)

    # ----- The theme ---------------------------------------------------------

    async def coin_theme(self, recent: Iterable[str] = ()) -> tuple[str, str] | None:
        """A fresh round theme and the call that hands the floor over: ("The text you never sent", "Say it now.").

        Never one of `recent`. None when Claude fails or breaks the rules; the
        written themes are the fallback.
        """
        recent = [t for t in dict.fromkeys(x.strip() for x in recent) if t]
        schema = claude.obj({"theme": STR, "call": STR})
        data = await self._ask("theme", schema, block("recent", "\n".join(recent)))
        if data is None:
            return None
        theme = " ".join(clean_verdict(str(data.get("theme", ""))).strip(" .!?;:\"'").split())
        call = " ".join(clean_verdict(str(data.get("call", ""))).split())
        if not theme or len(theme.split()) > THEME_WORDS or _title_key(theme) in {_title_key(t) for t in recent}:
            return None
        if modern(theme):  # nothing invented after the Bronze Age
            return None
        if modern(call):
            call = ""
        if not call or len(call.split()) > CALL_WORDS:
            call = ""
        elif call[-1] not in ".!":
            call += "."
        return theme[0].upper() + theme[1:], call

    # ----- The round verdict and the carved line ---------------------------

    async def round_verdict(self, theme: str, verses: list[Verse], event: Event | None = None) -> tuple[str, int, str]:
        """Returns (verdict, best_turn_id, best_line).

        The verdict is what Homer speaks: a lead-in of at most twelve words,
        then the carved line itself, verbatim. The arena reads it once.
        """
        ev = event or self.event
        scored = [v for v in verses if _units(v.transcript, ev)]
        if not scored:  # the module wants a verdict to close the round (best turn 0 is allowed)
            return SILENT_ROUND, 0, ""
        top = max(scored, key=lambda v: v.total)
        fallback = (top.turn_id, top.best_line or _units(top.transcript, ev)[0])
        schema = claude.obj({"verdict": STR, "best_turn": INT, "best_line": STR})
        body = "\n\n".join(
            f'<verse turn="{v.turn_id}" poet="{attr(v.poet)}" total="{v.total}">\n'
            f"{quote_untrusted(v.transcript.strip())}\nbest_line: {quote_untrusted(v.best_line)}\n</verse>"
            for v in scored
        )
        label = "question" if ev.hand == "moves" else "theme"
        data = await self._ask("verdict", schema, f"{label}: {quote_untrusted(theme) or 'open'}\n\n{body}", ev)
        if data is None:
            return "", *fallback
        by_id = {v.turn_id: v for v in scored}
        v = by_id.get(int(data.get("best_turn", 0)))
        line = _match_line(str(data.get("best_line", "")), _units(v.transcript, ev)) if v else None
        if v is None or line is None:  # an invented line is never carved
            best_turn, line = fallback
        else:
            best_turn = v.turn_id
        if ev.hand == "moves":
            line = debate.clean_line(line)
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
            f'<verse turn="{v.turn_id}" poet="{attr(v.poet)}" hits="{" ".join(str(line.hits) for line in scan_verse(v.transcript).lines)}">\n'
            f"{quote_untrusted(v.transcript.strip())}\n</verse>"
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
        return _on_the_beat(out, cap)

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

    # ----- Socrates: whispers, the last question, sparring ------------------

    async def whispers(self, question: str, side: str, hand: list[str], previous: str = "") -> dict[str, str]:
        """One rescue question per move in the hand, prepared at step-up: {move id: question}.

        Every move gets its filled template first, so a rescue always has
        something to play; Claude's version replaces it only if it's a single
        short question.
        """
        moves = [m for m in (debate.move(h) for h in hand) if m]
        q = debate.question(question)
        out = {m.id: debate.template_whisper(m, q, previous) for m in moves}
        if not moves:
            return out
        schema = claude.obj({"whispers": {"type": "array", "items": claude.obj({"id": STR, "text": STR})}})
        user = (
            f"question: {quote_untrusted(question) or 'open'}\nside: {quote_untrusted(side) or 'not given'}\nhand:"
            + "".join(f"\n- {m.id} ({m.role}): {m.template}" for m in moves)
        )
        if previous.strip():
            user += "\n\n" + block("previous_turn", previous)
        data = await self._ask("whispers", schema, user, events.DEBATE)
        for item in (data or {}).get("whispers", []):
            if not isinstance(item, dict) or item.get("id") not in out:
                continue
            text = clean_verdict(str(item.get("text", ""))).strip("\"'“”")
            if text.endswith("?") and text.count("?") == 1 and len(text.split()) <= 10:
                out[item["id"]] = text
        return out

    async def last_question(self, verses: list[Verse], questions: list[str]) -> list[tuple[int, str]]:
        """The debate finale: the night's strongest point quoted, then the question nobody answered.

        Returns [(turn, quote), (turn, question)]. If Claude fails, the top
        turn's best line stands alone; no question is invented.
        """
        spoken = [v for v in verses if sentences(v.transcript)]
        if not spoken:
            return []
        top = max(spoken, key=lambda v: v.total)
        fallback = [(top.turn_id, top.best_line or sentences(top.transcript)[0])]
        schema = claude.obj({"quote_turn": INT, "quote": STR, "question": STR})
        asked = "\n".join(f"- {quote_untrusted(q)}" for q in questions if q.strip()) or "- open"
        body = "\n\n".join(
            f'<verse turn="{v.turn_id}" poet="{attr(v.poet)}">\n{quote_untrusted(v.transcript.strip())}\n</verse>' for v in spoken
        )
        data = await self._ask("song", schema, f"questions tonight:\n{asked}\n\n{body}", events.DEBATE)
        if data is None:
            return fallback
        v = {x.turn_id: x for x in spoken}.get(int(data.get("quote_turn", 0) or 0))
        quote = _match_line(str(data.get("quote", "")), sentences(v.transcript)) if v else None
        question = clean_verdict(str(data.get("question", ""))).strip("\"'“”")
        if v is None or quote is None:
            return [(t, debate.clean_line(line)) for t, line in fallback]
        out = [(v.turn_id, debate.clean_line(quote))]
        if question.endswith("?") and len(question.split()) <= 20:
            out.append((v.turn_id, question))
        return out

    async def spar_debate(self, question: str, side: str, n: int = 3, answer_to: str = "") -> list[str]:
        """Socrates' own turn in a spar: the other side, argued mostly in questions."""
        n = max(1, min(n, 6))
        schema = claude.obj({"lines": {"type": "array", "items": STR}})
        user = f"question: {quote_untrusted(question) or 'open'}\nyour side: {quote_untrusted(side) or 'the other one'}\nsentences: {n}"
        if answer_to.strip():
            user += "\n\n" + block("answer_to", answer_to)
        data = await self._ask("spar", schema, user, events.DEBATE)
        return [clean_verdict(str(x)) for x in (data or {}).get("lines", []) if str(x).strip()][:n]

    # ----- Bard lessons 5 and 6: Homer's reading, not his voice ---------------

    async def lesson_answer(self, thrown: str, lines: list[str]) -> dict | None:
        """Lesson 5: did the answer turn Homer's line, ignore it, agree with it, or deny it?"""
        schema = claude.obj({"stance": {"type": "string", "enum": ["turned", "ignored", "agreed", "denied"]},
                             "answer": {"type": "integer", "enum": list(range(1, 11))}})
        user = block("thrown", thrown) + "\n\n" + block("answer", "\n".join(lines))
        data = await self._ask("lesson_answer", schema, user, events.POETRY)
        if data is None or data.get("stance") not in ("turned", "ignored", "agreed", "denied"):
            return None
        return {"stance": data["stance"], "answer": max(1, min(10, int(data.get("answer", 1))))}

    async def lesson_boast(self, setup: list[str], closing: str) -> dict | None:
        """Lesson 6: does the closing line pay off Homer's setup, and how strong is its picture?"""
        schema = claude.obj({"closes_setup": {"type": "boolean"}, "image": {"type": "integer", "enum": list(range(1, 11))}})
        user = block("setup", "\n".join(setup)) + "\n\n" + block("closing", closing)
        data = await self._ask("lesson_boast", schema, user, events.POETRY)
        if data is None:
            return None
        return {"closes_setup": bool(data.get("closes_setup")), "image": max(1, min(10, int(data.get("image", 1))))}
