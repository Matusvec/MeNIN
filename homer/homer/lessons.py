"""Bard lessons: the scripts in content/lessons.md, and Homer's one line of feedback.

The wording lives in content/lessons.md (pm owns it). Each lesson's feedback
table is read in order, and each row is matched to a detector here by its
position. Homer says the first miss that applies; with no miss, the lesson
lands. tests/test_lessons.py checks the rows still line up with the detectors.

Lessons 1 to 3 are built. TODO(spec): lessons 4 to 6 (the turn, the answer,
the boast) are in the cut order and come after the battle works.
"""

from __future__ import annotations

import re
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from functools import cache

from . import formulas
from .formulas import CONTENT_DIR, Formula
from .scanner import LineScan, TimedWord, VerseScan, scan_verse, strong_hits

RUSH_MS = 60  # beats this early on average are "rushing the drum"
NUMBERS = "zero one two three four five six seven eight nine ten".split()


@dataclass
class Lesson:
    id: str
    n: int
    title: str
    move: str = ""  # "Name the move", spoken
    exercise: str = ""  # spoken
    demo: list[str] = field(default_factory=list)  # notation: CAPS are hits, " / " the break
    misses: list[tuple[str, str]] = field(default_factory=list)  # (miss, Homer's line)
    success: str = ""


QUOTE_RE = re.compile(r"“([^”]*)”|\"([^\"]*)\"")


def _quoted(text: str) -> str:
    m = QUOTE_RE.search(text)
    return next(g for g in m.groups() if g is not None) if m else ""


@cache
def lessons() -> dict[str, Lesson]:
    text = (CONTENT_DIR / "lessons.md").read_text(encoding="utf-8")
    out: dict[str, Lesson] = {}
    for section in re.split(r"\n## ", text)[1:]:
        head = re.match(r"(\d+)\. (.+)", section)
        lid = re.search(r"\*\*id:\*\* `([^`]+)`", section)
        if not head or not lid:
            continue
        lesson = Lesson(id=lid.group(1), n=int(head.group(1)), title=head.group(2).strip())
        for line in section.splitlines():
            if line.startswith("**Name the move:**"):
                lesson.move = _quoted(line)
            elif line.startswith("**Exercise"):
                lesson.exercise = _quoted(line)
            elif line.startswith("**Success:**"):
                lesson.success = _quoted(line)
        demo = re.search(r"\*\*Demo verse[^\n]*\n(?:[^\n]*\n)*?```\n(.*?)```", section, re.S)
        if demo:
            lesson.demo = [line for line in demo.group(1).splitlines() if line.strip()]
        table = section.split("**Feedback**", 1)[1] if "**Feedback**" in section else ""
        for row in table.splitlines():
            cells = [c.strip() for c in row.strip().strip("|").split("|")]
            if len(cells) == 2 and cells[0] not in ("Miss", "---") and not cells[0].startswith("-"):
                lesson.misses.append((cells[0], _quoted(cells[1])))
        out[lesson.id] = lesson
    return out


@cache
def common() -> dict[str, str]:
    """The lines every lesson uses ("No speech heard" -> "I heard nothing. Again, and louder.")."""
    text = (CONTENT_DIR / "lessons.md").read_text(encoding="utf-8")
    part = text.split("## Lines every lesson uses", 1)[1].split("\n---", 1)[0]
    rows = {}
    for row in part.splitlines():
        cells = [c.strip() for c in row.strip().strip("|").split("|")]
        if len(cells) == 2 and cells[0] not in ("When", "---") and not cells[0].startswith("-"):
            rows[cells[0]] = _quoted(cells[1])
    return rows


def spoken_demo(lesson: Lesson) -> str:
    """The demo verse as TTS text: CAPS lowered, the break marks dropped."""
    return "\n".join(" ".join(line.replace(" / ", " ").split()).lower() for line in lesson.demo)


PRONOUN_I = {"I", "I'll", "I'm", "I'd", "I've"}  # capitalized by grammar, not as a hit


def demo_words(lesson: Lesson) -> list[list[tuple[str, bool]]]:
    """Each demo line as (word, is a hit), read from the CAPS.

    A capital "I" (or "I'm", "I'll") counts as a hit only when the line needs it to make four.
    """
    out = []
    for line in lesson.demo:
        words = [w for w in line.replace(" / ", " ").split() if w != "/"]
        caps = [any(c.isupper() for c in w) for w in words]
        if sum(caps) > 4:
            caps = [c and w.strip(",.!?") not in PRONOUN_I for w, c in zip(words, caps)]
        out.append([(w.lower(), c) for w, c in zip(words, caps)])
    return out


def demo_lane(lesson: Lesson, bpm: float, bars_per_line: int = 2) -> dict:
    """The demo verse on the beat lane (`BeatLane` in Contracts.swift): each hit on its pulse."""
    beat_ms = 60000.0 / bpm
    line_ms = bars_per_line * 4 * beat_ms
    words = []
    for n, line in enumerate(demo_words(lesson)):
        hits = [i for i, (_, hit) in enumerate(line) if hit]
        anchors = {i: n * line_ms + k * beat_ms for k, i in enumerate(hits)}
        for i, (text, hit) in enumerate(line):
            prev = max((a for a in anchors if a <= i), default=None)
            nxt = min((a for a in anchors if a > i), default=None)
            if prev is not None and nxt is not None:
                t = anchors[prev] + (anchors[nxt] - anchors[prev]) * (i - prev) / (nxt - prev)
            elif nxt is not None:
                t = anchors[nxt] - (nxt - i) * beat_ms / 3
            elif prev is not None:
                t = anchors[prev] + (i - prev) * beat_ms / 3
            else:
                t = n * line_ms + i * beat_ms / 3
            words.append({"text": text.strip(",.!?"), "t": round(t, 1), "stressed": hit, "onBeat": hit, "formulaId": None})
    return {"bpm": bpm, "beatsPerLine": 4, "lines": len(lesson.demo), "startedAt": 0, "words": words}


def spell(n: int) -> str:
    return NUMBERS[n].capitalize() if 0 <= n < len(NUMBERS) else str(n)


# ----- Feedback --------------------------------------------------------------


@dataclass
class Attempt:
    lesson: str
    transcript: str
    words: list[TimedWord] | None = None
    bpm: float | None = None
    hand: list[str] = field(default_factory=list)  # lesson 2
    rescue: str = ""  # lesson 2: the card Homer whispered, if he did
    name: str = ""  # lesson 3: the poet's name, to find the title after it
    lines_expected: int | None = None  # the exercise's count when None


@dataclass
class Feedback:
    landed: bool
    line: str  # the one line Homer says
    miss: str | None  # which row of the table applied
    scan: VerseScan | None = None
    title: str = ""  # lesson 3: the epithet, for the hoard and the battle name


# A detector returns the placeholder values when its miss applies, else None.
Detector = Callable[[VerseScan, Attempt], dict | None]
CraftCheck = Callable[[Attempt], Awaitable[int]]


def _first(scan: VerseScan, test: Callable[[LineScan], bool]) -> LineScan | None:
    return next((line for line in scan.lines if test(line)), None)


BEAT: list[Detector] = [
    lambda s, a: {"hits": spell(x.hits)} if (x := _first(s, lambda l: l.hits <= 3)) else None,
    lambda s, a: {"hits": spell(x.hits)} if (x := _first(s, lambda l: l.hits >= 5)) else None,
    lambda s, a: {} if _first(s, lambda l: l.break_source is None) else None,
    lambda s, a: {"word": x.weak_beats[0]} if (x := _first(s, lambda l: bool(l.weak_beats))) else None,
    lambda s, a: {} if _first(s, lambda l: l.offset_ms is not None and l.offset_ms < -RUSH_MS) else None,
]


def _tokens(line: LineScan) -> list[str]:
    return formulas.tokens(line.text)


def _find(card: str, line: LineScan) -> bool:
    k, words = formulas.key(card), _tokens(line)
    return any(tuple(words[i : i + len(k)]) == k for i in range(len(words)))


def _near(card: str, line: LineScan) -> bool:
    """Most of a card's words, in a stretch of the line about its length, but not the card itself."""
    k, words = formulas.key(card), _tokens(line)
    if len(k) < 2:
        return False
    for i in range(len(words)):
        window = words[i : i + len(k) + 1]
        if sum(1 for w in k if w in window) >= max(2, len(k) - 1):
            return True
    return False


def _card_lines(a: Attempt, s: VerseScan) -> list[tuple[str, LineScan]]:
    return [(c, line) for line in s.lines for c in a.hand if _find(c, line)]


FORMULA: list[Detector] = [
    lambda s, a: {"formula": a.rescue} if a.rescue and not any(_find(a.rescue, line) for line in s.lines) else None,
    lambda s, a: {} if not _card_lines(a, s) and not any(_near(c, line) for c in a.hand for line in s.lines) else None,
    lambda s, a: {} if not _card_lines(a, s) else None,  # near, but not word for word
    lambda s, a: {} if any(len(_tokens(line)) - len(formulas.key(c)) <= 1 for c, line in _card_lines(a, s)) else None,
    lambda s, a: {} if all(line.hits < 4 for _, line in _card_lines(a, s)) else None,
]


def title_of(a: Attempt, s: VerseScan) -> str:
    """The title the poet named themself with: the first line, minus their name."""
    if not s.lines:
        return ""
    first = s.lines[0].text
    if a.name and first.lower().startswith(a.name.lower()):
        first = first[len(a.name) :]
    first = re.sub(r"^(?:\W*(?:i am|i'm|my name is|call me)\b)?[\s,;:.!-]*", "", first, flags=re.I)
    return first.strip(" ,;:.!?-")


def _title_line(a: Attempt, s: VerseScan) -> LineScan | None:
    t = title_of(a, s)
    return next((line for line in s.lines[1:] if t and _find(t, line)), None)


EPITHET: list[Detector] = [
    lambda s, a: {} if strong_hits(title_of(a, s)) >= 3 else None,
    lambda s, a: {} if strong_hits(title_of(a, s)) <= 1 else None,
    None,  # "Generic, judged weak": the judge's Craft score, checked in feedback()
    lambda s, a: {} if _title_line(a, s) is None else None,
    lambda s, a: {} if (x := _title_line(a, s)) is not None and x.hits < 4 else None,
]

DETECTORS: dict[str, list[Detector | None]] = {"beat": BEAT, "formula": FORMULA, "epithet": EPITHET}
LINES = {"beat": 2, "formula": 1, "epithet": 2}  # what each exercise asks for (content/lessons.md)
GOOD_CRAFT = 6


async def feedback(a: Attempt, craft: CraftCheck | None = None) -> Feedback:
    """Homer's one line for this try: the first miss that applies, or the lesson's success line."""
    lesson = lessons()[a.lesson]
    detectors = DETECTORS.get(a.lesson)
    if detectors is None:
        raise NotImplementedError(f"feedback for lesson {a.lesson} isn't built yet")
    expected = a.lines_expected or LINES[a.lesson]
    cards: list[Formula] = [formulas.card(c) for c in a.hand] + list(formulas.bank())
    scan = scan_verse(a.transcript, words=a.words, bpm=a.bpm, lines_expected=expected, cards=cards)
    if not any(line.words for line in scan.lines):
        return Feedback(False, common().get("No speech heard", ""), "No speech heard", scan)

    for (miss, line), detect in zip(lesson.misses, detectors):
        if detect is None:
            if craft is not None and await craft(a) < GOOD_CRAFT:
                return Feedback(False, line, miss, scan)
            continue
        fills = detect(scan, a)
        if fills is not None:
            return Feedback(False, _fill(line, fills), miss, scan)

    if len(scan.lines) < expected:
        short = "Fewer lines than the exercise asks for"
        return Feedback(False, _fill(common()[short], {"lines": spell(expected).lower()}), short, scan)
    title = title_of(a, scan) if a.lesson == "epithet" else ""
    return Feedback(True, _fill(lesson.success, {"title": title}), None, scan, title=title)


def _fill(line: str, values: dict) -> str:
    for k, v in values.items():
        line = line.replace("{" + k + "}", str(v))
    return line
