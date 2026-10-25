"""Socratic debate: the content in content/debate.md and content/moves.json, Poise, and the rescue.

SPEC "The games": debate runs on the poetry battle's engine. Each round is a
question with two sides, the hand holds rhetorical moves, the freeze rescue is
a question Socrates whispers, and Poise is measured from the delivery the way
Beat is scanned from the verse. Claude never scores Poise.

The wording lives in content/debate.md (pm owns it) and is read at runtime.
"""

from __future__ import annotations

import json
import random
import re
from collections.abc import Iterable
from dataclasses import dataclass, field
from functools import cache

from .formulas import CONTENT_DIR
from .scanner import TimedWord

HAND_SIZE = 5
CANDIDATES = 8  # deal_round tops each hand up to 5 from this list
ROLES = ("open", "attack", "defend", "close")


@dataclass(frozen=True)
class Move:
    id: str
    text: str
    role: str
    template: str  # how the move sounds as a question: the rescue, and how the judge recognizes it
    emotions: tuple[str, ...] = ()
    kind: str = "move"


@dataclass(frozen=True)
class Question:
    id: str
    ask: str  # exactly as Socrates asks it
    side_a: str
    side_b: str
    kind: str  # classic | everyday | wild

    def side(self, turn_no: int) -> str:
        """Sides are dealt by turn order, alternating (ux-flow P18)."""
        return self.side_a if turn_no % 2 == 0 else self.side_b


# ----- Content ---------------------------------------------------------------

QUOTE_RE = re.compile(r"“([^”]*)”|\"([^\"]*)\"")


def _quoted(text: str) -> str:
    m = QUOTE_RE.search(text)
    return next(g for g in m.groups() if g is not None) if m else text.strip()


def _rows(section: str) -> list[list[str]]:
    """Body rows of the first markdown table in a section."""
    rows = []
    for line in section.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            if rows:
                break
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if all(set(c) <= set("-: ") for c in cells):
            continue
        rows.append(cells)
    return rows[1:]  # drop the header


@cache
def _text() -> str:
    return (CONTENT_DIR / "debate.md").read_text(encoding="utf-8")


def _section(title: str) -> str:
    parts = re.split(r"\n#{2,3} ", "\n" + _text())
    return next((p for p in parts if p.startswith(title)), "")


@cache
def questions() -> tuple[Question, ...]:
    out = []
    for row in _rows(_section("The questions")):
        if len(row) >= 5:
            out.append(Question(row[0].strip("`"), _quoted(row[1]), row[2], row[3], row[4]))
    return tuple(out)


def question(text_or_id: str) -> Question | None:
    """A question by id, or by the words Socrates asks (a round's theme)."""
    key = text_or_id.strip().strip("\"“”").lower()
    for q in questions():
        if key in (q.id, q.ask.lower()):
            return q
    return None


@cache
def moves() -> tuple[Move, ...]:
    templates = {row[0].strip("`"): _quoted(row[2]) for row in _rows(_section("The moves")) if len(row) >= 3}
    raw = json.loads((CONTENT_DIR / "moves.json").read_text(encoding="utf-8"))
    return tuple(
        Move(m["id"], m["text"], m["role"], templates.get(m["id"], ""), tuple(m.get("emotions", ()))) for m in raw
    )


def move(text_or_id: str) -> Move | None:
    key = text_or_id.strip().lower()
    return next((m for m in moves() if key in (m.id, m.text.lower())), None)


@cache
def lines() -> dict[str, dict[str, str]]:
    """Socrates' lines by register: {"shared": {when: line}, "training": {...}, "battle": {...}}.

    Repeated rows (the verdict samples) keep their first line under the plain
    key and the rest as "<when> 2", "<when> 3".
    """
    out: dict[str, dict[str, str]] = {}
    for key, title in (("shared", "Shared"), ("training", "Training"), ("battle", "Battle")):
        rows: dict[str, str] = {}
        for row in _rows(_section(title)):
            if len(row) >= 2:
                when, n = row[0], 2
                while when in rows:
                    when = f"{row[0]} {n}"
                    n += 1
                rows[when] = _quoted(row[1])
        out[key] = rows
    return out


# ----- Dealing ---------------------------------------------------------------


DEMO_QUESTION = "achilles-choice"  # the demo's one debate question: Achilles' choice (/themes?event=debate&demo=true)


def pick_question(rng: random.Random | None = None, avoid: Iterable[str] = ()) -> Question:
    rng = rng or random.Random()
    skip = {a.strip().lower() for a in avoid}
    pool = [q for q in questions() if q.ask.lower() not in skip and q.id not in skip] or list(questions())
    return rng.choice(pool)


def deal(n: int = HAND_SIZE, exclude: Iterable[str] = (), rng: random.Random | None = None) -> list[Move]:
    """n moves: at least one of each role first (content/debate.md), then any role."""
    rng = rng or random.Random()
    skip = {e.strip().lower() for e in exclude}
    pool = [m for m in moves() if m.text.lower() not in skip and m.id not in skip]
    rng.shuffle(pool)
    hand: list[Move] = []
    for role in ROLES:
        m = next((m for m in pool if m.role == role), None)
        if m and len(hand) < n:
            hand.append(m)
            pool.remove(m)
    hand.extend(pool[: max(0, n - len(hand))])
    return hand


# ----- Poise -----------------------------------------------------------------

FILLER_RE = re.compile(
    r"\b(?:um+|uh+|uhm|erm|er|ah+|hmm+|mm+|you know|i mean)\b|(?<=,)\s*like\s*(?=,)",
    re.I,
)
WORD_RE = re.compile(r"[A-Za-z']+")
PACE_BAND = (120.0, 180.0)  # words a minute that sound steady, not rushed or dragging
DEAD_AIR_MS = 2000  # a silence this long is dead air; it's when the freeze rescue fires


@dataclass
class Delivery:
    """How the debater kept the floor. Poise comes from this, never from Claude."""

    words: int
    fillers: list[str] = field(default_factory=list)
    wpm: float | None = None  # None when there are no timings and no turn length
    longest_silence_ms: float | None = None
    dead_air: int = 0  # silences of 2 s or more, plus each freeze rescue
    poise: int = 1


def poise(
    transcript: str,
    words: list[TimedWord] | None = None,
    turn_seconds: float | None = None,
    rescues: int = 0,
    spoken_seconds: float | None = None,
) -> Delivery:
    """Poise, 1 to 10: few fillers, a steady pace, no dead air, and the floor kept.

    Pace comes from the word timings when there are any, else from
    `spoken_seconds` (Go to the end of the turn, which can be early with Done),
    else from the full `turn_seconds`.
    """
    count = len(WORD_RE.findall(transcript)) if transcript.strip() else len(words or [])
    d = Delivery(words=count, fillers=[m.group().strip().lower() for m in FILLER_RE.finditer(transcript)])
    if count == 0:
        return d

    spoken_s = None
    if words:
        timed = sorted(words, key=lambda w: w.start)
        spoken_s = max(0.001, (timed[-1].end - timed[0].start) / 1000)
        gaps = [b.start - a.end for a, b in zip(timed, timed[1:])]
        d.longest_silence_ms = max([0.0, *gaps])
        d.dead_air = sum(1 for g in gaps if g >= DEAD_AIR_MS)
    elif spoken_seconds or turn_seconds:
        spoken_s = spoken_seconds or turn_seconds
    if spoken_s:
        d.wpm = round(count / spoken_s * 60, 1)
    d.dead_air += rescues

    minutes = (spoken_s or count / 150 * 60) / 60  # without timings, assume a steady 150 a minute
    penalty = min(4.0, len(d.fillers) / max(minutes, 0.25) / 2)  # 2 fillers a minute costs a point
    if d.wpm is not None:
        lo, hi = PACE_BAND
        penalty += min(2.0, max(lo - d.wpm, d.wpm - hi, 0) / 20)
    penalty += min(3.0, float(d.dead_air))
    if turn_seconds and count < turn_seconds * 1.0:  # under a word a second of the turn: the floor wasn't kept
        penalty += min(2.0, (turn_seconds - count) / turn_seconds * 3)
    d.poise = max(1, min(10, round(10 - penalty)))
    return d


# ----- The rescue ------------------------------------------------------------

STOP = frozenset(
    """the a an and or but of to in on at by for with from is are was were be been being it its this that these
    those i you he she we they me him her us them my your his our their not no so if then than as just very
    really what which who whom whose when where why how do does did have has had will would can could should
    about there here all any some more most such only own same too also into out up down over again""".split()
)


def key_terms(text: str, n: int = 3) -> list[str]:
    """The words a turn leans on, what {term} and {thing} point at: most repeated, then earliest (the subject)."""
    counts: dict[str, int] = {}
    for w in WORD_RE.findall(text.lower()):
        if w not in STOP and len(w) > 3:
            counts[w] = counts.get(w, 0) + 1
    order = list(counts)
    return sorted(order, key=lambda w: (-counts[w], order.index(w)))[:n]


def template_whisper(m: Move, q: Question | None, previous: str = "") -> str:
    """The move's template with its blanks filled from the previous turn (or the question)."""
    source = previous or (q.ask if q else "")
    terms = key_terms(source) or ["that"]
    # A case or claim is a few words from the last speaker; with no last speaker, the question's key word.
    last = re.split(r"[.!?]\s+", previous.strip())[-1] if previous.strip() else ""
    phrase = " ".join(last.split()[-5:]).strip(" .?!,").lower() if last else terms[0]
    fills = {"term": terms[0], "thing": terms[-1], "case": phrase, "claim": phrase}
    return re.sub(r"\{(\w+)\}", lambda mo: fills.get(mo.group(1), "that"), m.template)


def rescue_move(hand: Iterable[str], played: Iterable[str] = (), elapsed_s: float = 0.0, turn_seconds: float = 45.0, previous: str = "") -> Move | None:
    """The move to raise when the debater freezes: open early, attack an answerable point, close late."""
    spent = {p.strip().lower() for p in played}
    cards = [m for m in (move(h) for h in hand) if m and m.text.lower() not in spent and m.id not in spent]
    if not cards:
        return None
    left = turn_seconds - elapsed_s
    order = ["close", "defend", "attack", "open"] if left <= 12 else (
        ["attack", "open", "defend", "close"] if previous.strip() else ["open", "defend", "attack", "close"]
    )
    return min(cards, key=lambda m: order.index(m.role) if m.role in order else 9)


# ----- Speakable text ----------------------------------------------------------

SPOKEN_FILLER_RE = re.compile(r"\b(?:um+|uh+|uhm|erm|er|hmm+)\b[,.]?\s*", re.I)


def clean_line(text: str) -> str:
    """A debater's sentence fit to carve and read aloud: the ums and uhs dropped."""
    out = " ".join(SPOKEN_FILLER_RE.sub("", text).split()).strip(" ,")
    return out[:1].upper() + out[1:] if out else text.strip()


def plain_moves(text: str) -> str:
    """Move ids written as words ("ask-for-proof" -> "ask for proof"), so text-to-speech reads them."""
    for m in moves():
        text = text.replace(m.id, m.text.rstrip("?"))
    return text
