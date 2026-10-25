"""Bard lessons: the scripts in content/lessons.md, and Homer's one line of feedback.

The wording lives in content/lessons.md (pm owns it). Each lesson's feedback
table is read in order, and each row is matched to a detector here by its
position. Homer says the first miss that applies; with no miss, the lesson
lands. tests/test_lessons.py checks the rows still line up with the detectors.

Lessons 1 to 3 run on the scanner alone (lesson 3's "generic" check asks the
judge). Lessons 4 to 6 add the emotion classifier (the turn) and one small
Claude check each (the answer, the boast), behind the `Checks` interface so
tests can fake them.
"""

from __future__ import annotations

import re
from collections.abc import Awaitable, Callable
from typing import Protocol
from dataclasses import dataclass, field
from functools import cache

from . import emotion, formulas
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
    exercise_lines: list[str] = field(default_factory=list)  # lines Homer speaks in the exercise (lessons 5 and 6)
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
        ex = re.search(r"\*\*Exercise[^\n]*\n(?:[^\n]*\n)*?```\n(.*?)```", section.split("**Feedback**")[0], re.S)
        if ex:
            lesson.exercise_lines = [line for line in ex.group(1).splitlines() if line.strip()]
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
    prompt: str = ""  # lesson 5: the line Homer threw (notation or plain)
    try_no: int = 0  # this try's number within the lesson, 1-based (P10: help after 3 and 5 misses)
    onsets_ms: list[float] | None = None  # lesson 1: the phone's stressed peaks, ms from beat 1 (no word timings)
    bars_per_line: int = 2  # a speaking bar and a rest bar per line (SPEC)
    facts: dict = field(default_factory=dict)  # filled before the detectors run (lessons 4 to 6)


@dataclass
class Feedback:
    landed: bool
    line: str  # the one line Homer says
    miss: str | None  # which row of the table applied
    scan: VerseScan | None = None
    title: str = ""  # lesson 3: the epithet, for the hoard and the battle name
    help: dict | None = None  # P10: Homer's help after the third and fifth misses


# A detector returns the placeholder values when its miss applies, else None.
Detector = Callable[[VerseScan, Attempt], dict | None]
CraftCheck = Callable[[Attempt], Awaitable[int]]


class Checks(Protocol):
    """What some lessons need beyond the scanner. The server provides it; tests fake it."""

    async def craft(self, a: Attempt) -> int: ...
    async def content(self, a: Attempt, theme: str) -> dict | None: ...  # the battle judge: {image, answer, craft, verdict}
    async def emotions(self, lines: list[str]) -> list[dict[str, float] | None]: ...
    async def answer(self, thrown: str, lines: list[str]) -> dict | None: ...  # {"stance", "answer"}
    async def boast(self, setup: list[str], closing: str) -> dict | None: ...  # {"closes_setup", "image"}


def _first(scan: VerseScan, test: Callable[[LineScan], bool]) -> LineScan | None:
    return next((line for line in scan.lines if test(line)), None)


def _rushing(s: VerseScan, a: Attempt) -> bool:
    """Ahead of the drum: from word timings when there are any, else from the phone's stressed peaks."""
    if _first(s, lambda l: l.offset_ms is not None and l.offset_ms < -RUSH_MS):
        return True
    off = a.facts.get("onset_offset_ms")
    return off is not None and off < -RUSH_MS


ONSET_TOL_MS = 170  # how near a pulse a phone peak may land: wider than word timings, for laptop mics and first-timers


# Matus (Sat 9:52 PM): "care more about content than exact timing. I'd keep the beats though." The hit count is
# the text's and lenient (a four-beat line is 3 to 5 hits; every lesson's "a hit short" means two short), and the
# timing (the drum, the break, where a hit falls) is a note at most, never a miss. Content decides (CONTENT_BAR).
FOUR = range(3, 6)  # hits that count as a four-beat line


def short_line(line: LineScan) -> bool:
    return line.hits < FOUR.start


BEAT: list[Detector] = [
    lambda s, a: {"hits": spell(x.hits)} if (x := _first(s, short_line)) else None,
    lambda s, a: {"hits": spell(x.hits)} if (x := _first(s, lambda l: l.hits >= FOUR.stop)) else None,
    lambda s, a: {} if _first(s, lambda l: l.break_source is None) else None,  # soft
    lambda s, a: {"word": x.weak_beats[0]} if (x := _first(s, lambda l: bool(l.weak_beats))) else None,  # soft
    lambda s, a: {} if _rushing(s, a) else None,  # soft
]

# Rows that are notes, not misses: when the try lands, the first one that applies follows the success line.
SOFT: dict[str, set[int]] = {"beat": {2, 3, 4}}


def onset_offset(onsets_ms: list[float], bpm: float) -> float | None:
    """The mean signed distance (ms) of stressed peaks from their nearest pulse; negative is early.

    Peaks more than a third of a beat from any pulse are offbeat syllables, not hits, and are left out.
    """
    beat = 60000.0 / bpm
    offs = [o - round(o / beat) * beat for o in onsets_ms if o >= -beat / 2]
    near = [x for x in offs if abs(x) <= beat / 3]
    return round(sum(near) / len(near), 1) if near else None


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
    lambda s, a: {} if all(short_line(line) for _, line in _card_lines(a, s)) else None,
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
    lambda s, a: {} if strong_hits(title_of(a, s)) >= 4 else None,  # a two-hit title, ±1
    lambda s, a: {} if strong_hits(title_of(a, s)) == 0 else None,
    None,  # "Generic, judged weak": the judge's Craft score, checked in feedback()
    lambda s, a: {} if _title_line(a, s) is None else None,
    lambda s, a: {} if (x := _title_line(a, s)) is not None and short_line(x) else None,
]

# Lesson 4: the feeling named instead of shown. Homer's rule: show it, never say it.
FEELING_RE = re.compile(
    r"\b(?:sad|sadness|happy|happiness|angry|anger|mad|furious|scared|afraid|fearful|frightened|terrified|"
    r"joyful|glad|grieving|lonely|depressed|upset|heartbroken|miserable|ashamed|excited|nervous|anxious|"
    r"hopeless|jealous|feel|feels|felt|feeling|feelings|emotion|emotions)\b",
    re.I,
)

TURN: list[Detector | None] = [
    lambda s, a: {} if a.facts["turn_at"] is None else None,  # no turn
    lambda s, a: {} if a.facts["turn_at"] == 1 else None,  # turned at line 2: too soon
    lambda s, a: {} if a.facts["turn_at"] == 3 else None,  # turned on the last line
    lambda s, a: {} if FEELING_RE.search(" ".join(line.text for line in s.lines)) else None,
    lambda s, a: {} if len(s.lines) >= 3 and short_line(s.lines[2]) else None,  # the bend cost line 3 hits
]

ANSWER: list[Detector | None] = [
    lambda s, a: {} if a.facts["stance"] == "ignored" else None,
    lambda s, a: {} if a.facts["stance"] == "agreed" else None,
    lambda s, a: {} if a.facts["stance"] == "denied" else None,
    lambda s, a: {} if len(s.lines) < 2 else None,  # only one line
    lambda s, a: {} if any(short_line(line) for line in s.lines[:2]) else None,
    lambda s, a: {} if a.facts["answer"] < GOOD_ANSWER else None,  # clean, but under the bar
]

# Lesson 6: a boast that hedges isn't one.
HEDGE_RE = re.compile(
    r"\b(?:maybe|might|perhaps|probably|possibly|hopefully|almost|i think|i guess|i hope|i suppose|"
    r"kind of|sort of|could be|try to|trying to)\b",
    re.I,
)


def _last_word(line: LineScan) -> str:
    return line.words[-1].text if line.words else ""


BOAST: list[Detector | None] = [
    lambda s, a: {"last_word": _last_word(s.lines[0])} if s.lines[0].words and not s.lines[0].words[-1].hit else None,
    lambda s, a: {} if len(s.lines) > 1 else None,  # landed it, then kept talking
    lambda s, a: {} if HEDGE_RE.search(s.lines[0].text) else None,
    lambda s, a: {} if not a.facts["closes_setup"] else None,
    lambda s, a: {} if short_line(s.lines[0]) else None,
    lambda s, a: {} if a.facts["image"] < GOOD_IMAGE else None,  # clean, but nothing to see
]

DETECTORS: dict[str, list[Detector | None]] = {
    "beat": BEAT, "formula": FORMULA, "epithet": EPITHET, "turn": TURN, "answer": ANSWER, "boast": BOAST,
}
LINES = {"beat": 2, "formula": 1, "epithet": 2, "turn": 4, "answer": 2, "boast": 1}  # what each exercise asks for
GOOD_CRAFT = 6
GOOD_ANSWER = 7  # lesson 5 lands at Answer 7 or more
GOOD_IMAGE = 7  # lesson 6 lands at Image 7 or more
# Lessons 1 and 2 have no content check of their own: the battle judge weighs the verse the way battles do
# (Image x4, Answer x4, Craft x2, out of 100) against the exercise, and a thin one doesn't land.
CONTENT_LESSONS = {"beat", "formula"}
CONTENT_WEIGHTS = {"image": 4, "answer": 4, "craft": 2}
CONTENT_BAR = 40  # the low end of a real attempt (the judge's neutral 4s make 40): only filler and off-topic fall short
THIN = "Content is thin"  # content/lessons.md may give it its own row; else Homer's own verdict on the verse
SILENT = "Homer is silent"  # a Claude check didn't answer: no line, never a canned one


def lead(weights: dict[str, float] | None) -> str | None:
    return max(weights, key=weights.get) if weights and any(weights.values()) else None


# How each emotion leans, from triumph (+1) to loss (-1). A turn is a swing along this line.
VALENCE = {"joy": 1.0, "awe": 0.6, "tenderness": 0.6, "defiance": 0.5, "longing": -0.4, "anger": -0.4, "fear": -0.9, "grief": -1.0}
TURN_SWING = 0.6  # the smallest valence swing between before and after that counts as a turn


def valence(weights: dict[str, float] | None) -> float | None:
    if not weights or not any(weights.values()):
        return None
    total = sum(max(0.0, float(v)) for v in weights.values())
    return sum(VALENCE.get(e, 0.0) * max(0.0, float(v)) for e, v in weights.items()) / total if total else None


def turn_at(weights: list[dict[str, float] | None]) -> int | None:
    """The 0-based line where the verse turns, or None.

    Each line gets a valence (triumph to loss). The turn is where the mean
    before and the mean after differ most; ties go to line 3, where the
    lesson wants it. A swing smaller than TURN_SWING is no turn at all.
    """
    v = [valence(w) for w in weights]
    known = [x for x in v if x is not None]
    if len(known) < 2:
        return None
    v = [x if x is not None else sum(known) / len(known) for x in v]
    best, best_swing = None, 0.0
    for k in sorted(range(1, len(v)), key=lambda k: abs(k - 2)):  # line 3 first, so it wins ties
        swing = abs(sum(v[:k]) / k - sum(v[k:]) / (len(v) - k))
        if swing > best_swing + 1e-9:
            best, best_swing = k, swing
    return best if best_swing >= TURN_SWING else None


async def _facts(a: Attempt, scan: VerseScan, checks: Checks | None) -> bool:
    """Work out what lessons 4 to 6 need before the detectors run. False if a Claude check went silent."""
    lines = [line.text for line in scan.lines]
    if a.lesson == "beat" and a.onsets_ms and a.bpm and not a.words:
        a.facts["onset_offset_ms"] = onset_offset(a.onsets_ms, a.bpm)
    if a.lesson == "turn":
        weights = await checks.emotions(lines[:4]) if checks else [None] * len(lines[:4])
        weights = [w or emotion.lexicon_weights(text) for w, text in zip(weights, lines[:4])]
        a.facts["leads"] = [lead(w) for w in weights]
        a.facts["valence"] = [None if (x := valence(w)) is None else round(x, 2) for w in weights]
        a.facts["turn_at"] = turn_at(weights)
    elif a.lesson == "answer":
        thrown = " ".join(a.prompt.replace(" / ", " ").split()).lower()
        r = await checks.answer(thrown, lines[:2]) if checks else None
        if r is None:
            return False
        a.facts["stance"] = str(r.get("stance", ""))
        a.facts["answer"] = int(r.get("answer", 0) or 0)
    elif a.lesson == "boast":
        setup = [" ".join(x.replace(" / ", " ").split()).lower() for x in lessons()["boast"].exercise_lines]
        r = await checks.boast(setup, lines[0]) if checks else None
        if r is None:
            return False
        a.facts["closes_setup"] = bool(r.get("closes_setup"))
        a.facts["image"] = int(r.get("image", 0) or 0)
    return True


async def feedback(a: Attempt, craft: CraftCheck | None = None, checks: Checks | None = None) -> Feedback:
    """Homer's one line for this try: the first miss that applies, or the lesson's success line.

    With `try_no`, a miss also carries P10's help (after the third and fifth misses).
    """
    return _helped(await _feedback(a, craft, checks), a, lessons()[a.lesson])


async def _feedback(a: Attempt, craft: CraftCheck | None, checks: Checks | None) -> Feedback:
    if craft is None and checks is not None:
        craft = checks.craft
    lesson = lessons()[a.lesson]
    detectors = DETECTORS.get(a.lesson)
    if detectors is None:
        raise NotImplementedError(f"feedback for lesson {a.lesson} isn't built yet")
    expected = a.lines_expected or LINES[a.lesson]
    cards: list[Formula] = [formulas.card(c) for c in a.hand] + list(formulas.bank())
    scan = scan_verse(a.transcript, words=a.words, bpm=a.bpm, lines_expected=expected, cards=cards)
    if not any(line.words for line in scan.lines):
        return Feedback(False, common().get("No speech heard", ""), "No speech heard", scan)
    short = "Fewer lines than the exercise asks for"
    if a.lesson == "turn" and len(scan.lines) < expected:  # a turn needs all four lines to be found
        return Feedback(False, _fill(common()[short], {"lines": spell(expected).lower()}), short, scan)
    if not await _facts(a, scan, checks):
        return Feedback(False, "", SILENT, scan)

    note = ""  # the first soft row that applies: said after the success line, never a miss
    for k, ((miss, line), detect) in enumerate(zip(lesson.misses, detectors)):
        if detect is None:
            if craft is not None and await craft(a) < GOOD_CRAFT:
                return Feedback(False, line, miss, scan)
            continue
        fills = detect(scan, a)
        if fills is None:
            continue
        if k in SOFT.get(a.lesson, set()):
            note = note or _fill(line, fills)
            continue
        return Feedback(False, _fill(line, fills), miss, scan)

    if len(scan.lines) < expected:
        return Feedback(False, _fill(common()[short], {"lines": spell(expected).lower()}), short, scan)
    if a.lesson in CONTENT_LESSONS and checks is not None:
        scores = await checks.content(a, lesson.exercise)
        if scores is not None and sum(int(scores.get(k, 0) or 0) * w for k, w in CONTENT_WEIGHTS.items()) < CONTENT_BAR:
            thin = dict(lesson.misses).get(THIN) or str(scores.get("verdict") or "")
            if thin:  # no line to say is no verdict: let the try stand
                return Feedback(False, thin, THIN, scan)
    title = title_of(a, scan) if a.lesson == "epithet" else ""
    success = _fill(lesson.success, {"title": title})
    return Feedback(True, f"{success} {note}" if note else success, None, scan, title=title)


# P10: the demo verse line that shows each lesson's move, 0-based.
HELP_LINE = {"beat": 0, "formula": 0, "epithet": 0, "turn": 2, "answer": 1, "boast": 3}


def _plain(notation: str) -> str:
    return " ".join(notation.replace(" / ", " ").replace("/", " ").split()).lower()


def help_for(lesson: Lesson, try_no: int) -> dict | None:
    """P10, help after misses: after the third, the first half of a model line to finish; after the fifth, a walkthrough.

    The model line is the lesson's demo verse line that shows the move. The
    framing is pm's ("Help after three misses", "Walkthrough after five
    misses" in lessons.md); until it exists, Homer says the words alone.
    """
    if try_no < 3 or try_no == 4 or not lesson.demo:
        return None
    line = lesson.demo[min(HELP_LINE.get(lesson.id, 0), len(lesson.demo) - 1)]
    if try_no == 3:
        half = line.split(" / ")[0].strip() + " /"
        say = common().get("Help after three misses", "{half}")
        return {"kind": "half", "say": _fill(say, {"half": _plain(half)}), "half": half, "line": line}
    say = common().get("Walkthrough after five misses", "{line}")
    return {"kind": "walkthrough", "say": _fill(say, {"line": _plain(line)}), "line": line}


def _helped(f: Feedback, a: Attempt, lesson: Lesson) -> Feedback:
    """Add P10's help to a miss. After the fifth, the walkthrough lands the lesson."""
    if f.landed or f.miss == SILENT:
        return f
    f.help = help_for(lesson, a.try_no)
    if f.help and f.help["kind"] == "walkthrough":
        f.landed = True
    return f


def _fill(line: str, values: dict) -> str:
    for k, v in values.items():
        line = line.replace("{" + k + "}", str(v))
    # content/lessons.md writes "{hits} hits." for any count: one hit is singular.
    return re.sub(r"\bOne (hit|line|beat)s\b", r"One \1", line)
