"""Four-beat line scanner. Deterministic: it never calls a model.

SPEC "The form": four hits a line, a breath in the middle. For each spoken
line this finds the four beats, counts the hits, finds the break, and, when
the app sends word timings, checks whether each hit landed on the drum. The
Beat axis comes from here, never from Claude.

Every syllable gets a weight:
    3  strong: the stressed syllable of a content word
    2  secondary: a compound's second part (WINE-dark), a secondary stress
    1  light: pronouns, auxiliaries and other small words that can take a beat
    0  weak: articles, prepositions, conjunctions, forms of "be", and the
       unstressed syllables of longer words

The four beats are placed by a small dynamic program that prefers beats on
heavy syllables, one or two syllables between beats, and the break between
beat 2 and beat 3. Each half-line may swallow one extra stress next to a beat
("the SEA kept TIME"); any other stress off the beat is an extra hit.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from functools import lru_cache

import pronouncing

from . import formulas
from .formulas import Formula

BEATS_PER_LINE = 4
PAUSE_MS = 150  # a gap this long between two words is a breath
ON_BEAT_MS = 120  # a stressed syllable this close to a pulse is on the drum
MAX_LINES = 16
MAX_LINE_CHARS = 300

STRONG, SECONDARY, LIGHT, WEAK = 3, 2, 1, 0

# Small words that carry no beat in running speech.
WEAK_WORDS = frozenset(
    """
    a an the and or nor but of to in on at by from with as than if for
    through till 'til is am are was were be been 's th' o'
    """.split()
)
# Small words that can take a beat when the line needs one ("and SO did I").
LIGHT_WORDS = frozenset(
    """
    i me my mine we us our ours you your yours he him his she her hers it its
    they them their theirs thou thee thy thine ye who whom whose which what
    when where while how why like
    that this these those there here then so yet just do does did have has had
    shall should will would can could may might must 'tis 'twas
    i'm i'll i've i'd you're you'll you've you'd we're we'll we've they're
    they'll he's she's it's that's there's what's let's
    """.split()
)
# Longer function words: their stressed syllable is light, the rest weak.
FUNCTION_POLY = frozenset(
    """
    about above across after against along among around before behind below
    beneath beside between beyond during into onto upon unto over under until
    within without toward towards because although whenever wherever myself
    yourself himself herself itself ourselves themselves
    """.split()
)
# A word starting a new phrase marks a likely break.
PHRASE_STARTS = frozenset("and but or yet so then when while till until where as because though if".split())

# Poetic forms missing from the CMU dictionary: word -> stress digits.
ARCHAIC = {
    "o'er": "1", "e'er": "1", "ne'er": "1", "'twas": "1", "'tis": "1", "th'": "0",
    "oft": "1", "ere": "1", "hath": "1", "doth": "1", "thou": "1", "thee": "1",
    "thy": "1", "thine": "1", "ye": "1", "art": "1", "wilt": "1", "shalt": "1",
    "dost": "1", "canst": "1",
}

WORD_RE = re.compile(r"[A-Za-z]+(?:['’][A-Za-z]+)*['’]?|['’][A-Za-z]+")
MARK_RE = re.compile(r"\s/\s|\|")  # an explicit break: "WINE-dark SEA / took my..."
PUNCT_RE = re.compile(r"[,;:.!?—–]|--")
VOWELS_RE = re.compile(r"[aeiouy]+")

# Costs for the beat fit. Lower is a more natural reading.
BEAT_COST = {STRONG: 0.0, SECONDARY: 1.0, LIGHT: 1.5, WEAK: 4.0}
FIXED_WEAK_COST = 6.0  # a beat inside a word, on its unstressed syllable
CLASH_COST = 1.5  # two beats side by side, with no breath between
SANDWICH_COST = 0.5  # a stress between two beats ("SEA kept TIME")
ADJACENT_COST = 1.0  # a stress next to one beat
EXTRA_COST = 3.0  # a stress with no beat beside it
HARD_BREAK_COST = 3.0  # the marked or heard break isn't between beats 2 and 3
SOFT_BREAK_COST = 1.0  # same, for a comma or a new phrase


@dataclass
class TimedWord:
    """A word from speech-to-text. Times are ms from beat 1 of the turn."""

    text: str
    start: float
    end: float


@dataclass
class _Syl:
    word: int
    weight: int
    fixed: bool  # an unstressed syllable inside a content word


@dataclass
class WordScan:
    text: str
    syllables: int
    known: bool  # in the CMU dictionary (or the archaic list)
    beat: bool = False  # one of the line's beats falls on this word
    hit: bool = False  # a stress the listener hears: a beat on it, or an extra
    weak_beat: bool = False  # a beat had to land on a small word or a weak syllable
    extra: bool = False  # a stress off the beat
    t: float | None = None  # ms from beat 1: the beat or stressed syllable, else the word start
    on_beat: bool | None = None  # None when there are no timings
    formula_id: str | None = None
    joined: bool = False  # hyphenated to the previous word


@dataclass
class LineScan:
    text: str
    words: list[WordScan]
    hits: int
    pattern: str  # "the WIND was COLD / the WAVES were GREY"
    break_after: int | None  # index of the word the break follows
    break_source: str | None  # "mark", "pause", "punctuation", "phrase", "inferred", or None if missing
    weak_beats: list[str]
    extras: list[str]
    on_beat: int | None  # beats that landed on a pulse
    offset_ms: float | None  # mean signed distance of the beats from the pulse; negative is early
    score: float  # 0 to 1


@dataclass
class VerseScan:
    lines: list[LineScan]
    beat: int  # the Beat axis, 1 to 10
    lines_expected: int
    timed: bool
    best_line: int | None  # index of the best-scanning line
    formulas: list[str] = field(default_factory=list)  # ids of the formulas spoken, in order


# ----- Words ---------------------------------------------------------------


def normalize(word: str) -> str:
    return word.lower().replace("’", "'")


def _guess_syllables(word: str) -> int:
    w = re.sub(r"[^a-z]", "", word)
    n = len(VOWELS_RE.findall(w))
    if w.endswith("e") and not w.endswith(("le", "ee", "ye")) and n > 1:
        n -= 1
    return max(1, n)


@lru_cache(maxsize=8192)
def stress(word: str) -> tuple[str, bool]:
    """CMU stress digits for a word (e.g. "10"), and whether it was found."""
    norm = normalize(word).strip("'")
    if norm in ARCHAIC:
        return ARCHAIC[norm], True
    for form in (norm, normalize(word)):
        phones = pronouncing.phones_for_word(form)
        if phones:
            options = [pronouncing.stresses(p) for p in phones]
            if form in WEAK_WORDS or form in LIGHT_WORDS or form in FUNCTION_POLY:
                options.sort(key=len)  # the short, everyday reading
            return options[0], True
    for suffix in ("'s", "s'", "'d"):
        if norm.endswith(suffix):
            base, known = stress(norm[: -len(suffix)] + ("ed" if suffix == "'d" else ""))
            if known:
                return (base[:-1] if suffix == "'d" and len(base) > 1 else base), True
    n = _guess_syllables(norm)
    return "1" + "0" * (n - 1), False


def _weights(norm: str, digits: str, compound_tail: bool) -> list[tuple[int, bool]]:
    if len(digits) == 1:
        if norm in WEAK_WORDS:
            return [(WEAK, False)]
        if norm in LIGHT_WORDS:
            return [(LIGHT, False)]
        return [(SECONDARY if compound_tail else STRONG, False)]
    if norm in FUNCTION_POLY:
        return [(LIGHT if d == "1" else WEAK, False) for d in digits]
    out = []
    for d in digits:
        if d == "1":
            out.append((SECONDARY if compound_tail else STRONG, False))
        elif d == "2":
            out.append((SECONDARY, False))
        else:
            out.append((WEAK, True))
    return out


# ----- Lines ---------------------------------------------------------------


@dataclass
class _Token:
    text: str
    norm: str
    start: int
    end: int
    joined: bool  # "-" right before it
    t0: float | None = None
    t1: float | None = None


def _tokenize(line: str) -> tuple[list[_Token], set[int], set[int]]:
    """Tokens, plus the word indices that follow a break mark or punctuation."""
    toks: list[_Token] = []
    marks: set[int] = set()
    punct: set[int] = set()
    prev_end = 0
    for m in WORD_RE.finditer(line):
        gap = line[prev_end : m.start()]
        i = len(toks)
        if i:
            if MARK_RE.search(gap):
                marks.add(i)
            elif PUNCT_RE.search(gap):
                punct.add(i)
        toks.append(_Token(m.group(), normalize(m.group()), m.start(), m.end(), joined=bool(i) and gap == "-"))
        prev_end = m.end()
    return toks, marks, punct


def _compound_tails(toks: list[_Token]) -> set[int]:
    tails = {i for i, t in enumerate(toks) if t.joined}
    words = [formulas.tokens(t.norm)[0] if formulas.tokens(t.norm) else t.norm for t in toks]
    for comp in formulas.compounds():
        k = len(comp)
        for i in range(len(words) - k + 1):
            if tuple(words[i : i + k]) == comp:
                tails.update(range(i + 1, i + k))
    return tails


def _fit(syls: list[_Syl], m: int, hard: set[int], soft: set[int]) -> list[int]:
    """Choose m beat positions (syllable indices) at the lowest cost."""
    n = len(syls)
    m = min(m, n)
    if m == 0:
        return []
    mid = m // 2 if m >= 2 else None

    def beat_cost(i: int) -> float:
        s = syls[i]
        return FIXED_WEAK_COST if s.fixed else BEAT_COST[s.weight]

    def gap_cost(a: int, b: int) -> float:
        g = b - a - 1
        if g == 0:
            c = 0.0 if b in hard or b in soft else CLASH_COST
        elif g <= 2:
            c = 0.0
        else:
            c = float(g - 2)
        for x in range(a + 1, b):
            if syls[x].weight == STRONG:
                c += SANDWICH_COST if g == 1 else ADJACENT_COST if x in (a + 1, b - 1) else EXTRA_COST
        return c

    def edge_cost(lo: int, hi: int, beat: int) -> float:
        """Offbeats in [lo, hi) before the first or after the last beat."""
        c = float(max(0, hi - lo - 3))
        for x in range(lo, hi):
            if syls[x].weight == STRONG:
                c += ADJACENT_COST if abs(x - beat) == 1 else EXTRA_COST
        return c

    def break_cost(a: int, b: int) -> float:
        if hard:
            return 0.0 if any(a < k <= b for k in hard) else HARD_BREAK_COST
        if soft:
            return 0.0 if any(a < k <= b for k in soft) else SOFT_BREAK_COST
        return 0.0

    inf = float("inf")
    cost = [[inf] * n for _ in range(m)]
    back = [[-1] * n for _ in range(m)]
    for i in range(n):
        cost[0][i] = edge_cost(0, i, i) + beat_cost(i)
    for j in range(1, m):
        for i in range(j, n):
            bc = beat_cost(i)
            for a in range(j - 1, i):
                if cost[j - 1][a] == inf:
                    continue
                c = cost[j - 1][a] + gap_cost(a, i) + bc + (break_cost(a, i) if j == mid else 0.0)
                if c < cost[j][i]:
                    cost[j][i], back[j][i] = c, a
    last = min(range(n), key=lambda i: cost[m - 1][i] + edge_cost(i + 1, n, i))
    beats = [last]
    for j in range(m - 1, 0, -1):
        beats.append(back[j][beats[-1]])
    return beats[::-1]


def _scan_line(
    text: str,
    toks: list[_Token],
    marks: set[int],
    punct: set[int],
    beats_per_line: int,
    bpm: float | None,
    timed: bool,
) -> LineScan:
    tails = _compound_tails(toks)
    words: list[WordScan] = []
    syls: list[_Syl] = []
    first_syl: list[int] = []
    for i, t in enumerate(toks):
        digits, known = stress(t.text)
        first_syl.append(len(syls))
        for weight, fixed in _weights(t.norm, digits, i in tails):
            syls.append(_Syl(i, weight, fixed))
        words.append(WordScan(t.text, len(digits), known, t=t.t0, joined=t.joined))

    # Breaks: a marked " / " or a heard pause is hard; a comma or a new phrase is soft.
    pauses = set()
    if timed:
        for i in range(1, len(toks)):
            a, b = toks[i - 1], toks[i]
            if a.t1 is not None and b.t0 is not None and b.t0 - a.t1 >= PAUSE_MS:
                pauses.add(i)
    phrase = {i for i in range(1, len(toks)) if toks[i].norm in PHRASE_STARTS}
    to_syl = lambda idxs: {first_syl[i] for i in idxs}  # noqa: E731
    hard = to_syl(marks | pauses)
    soft = to_syl(punct | phrase)

    beats = _fit(syls, beats_per_line, hard, soft)
    beat_set = set(beats)

    # Where the break fell, and what told us.
    break_after, break_source = None, None
    m = len(beats)
    if m >= 2:
        a, b = beats[m // 2 - 1], beats[m // 2]
        for source, idxs in (("mark", marks), ("pause", pauses), ("punctuation", punct), ("phrase", phrase)):
            inside = [i for i in idxs if a < first_syl[i] <= b]
            if inside:
                break_after, break_source = inside[0] - 1, source
                break
        if break_source is None and not timed and syls[a].word != syls[b].word:
            break_after, break_source = syls[a].word, "inferred"

    # Hits: beats on syllables that can carry one, plus stresses off the beat.
    # Each half-line may swallow one stress that sits next to a beat.
    split = first_syl[break_after + 1] if break_after is not None else (beats[m // 2] if m >= 2 else len(syls))
    absorbed = {0: 0, 1: 0}
    extras: list[int] = []
    for x, s in enumerate(syls):
        if x in beat_set or s.weight != STRONG:
            continue
        half = 0 if x < split else 1
        if (x - 1 in beat_set or x + 1 in beat_set) and absorbed[half] == 0:
            absorbed[half] = 1
        else:
            extras.append(x)
    weak = [x for x in beats if syls[x].weight == WEAK]
    hits = sum(1 for x in beats if syls[x].weight > WEAK) + len(extras)

    for x in beats:
        w = words[syls[x].word]
        w.beat = True
        if syls[x].weight > WEAK:
            w.hit = True
        else:
            w.weak_beat = True
    for x in extras:
        words[syls[x].word].hit = True
        words[syls[x].word].extra = True

    # Timing: the stressed syllable's moment, against the nearest pulse.
    on_beat, offset = None, None
    if timed and bpm:
        beat_ms = 60000.0 / bpm
        offsets = []
        for i, w in enumerate(words):
            tok = toks[i]
            if tok.t0 is None or tok.t1 is None:
                continue
            ws = [x for x in range(first_syl[i], first_syl[i] + w.syllables)]
            key = next((x for x in ws if x in beat_set), None)
            if key is None:
                key = max(ws, key=lambda x: syls[x].weight)
            w.t = tok.t0 + (tok.t1 - tok.t0) * (key - first_syl[i]) / max(1, w.syllables)
            off = w.t - round(w.t / beat_ms) * beat_ms
            w.on_beat = w.hit and abs(off) <= ON_BEAT_MS
            if w.beat and not w.weak_beat:
                offsets.append(off)
        if offsets:
            on_beat = sum(1 for o in offsets if abs(o) <= ON_BEAT_MS)
            offset = round(sum(offsets) / len(offsets), 1)

    # Score: four hits, no beat on a small word, a breath in the middle, on the drum.
    score = 1.0 - 0.25 * abs(hits - beats_per_line) - 0.15 * len(weak)
    if break_source is None and m >= 2:
        score -= 0.15
    score = max(0.0, score)
    if on_beat is not None:
        score = 0.6 * score + 0.4 * on_beat / beats_per_line
    if not toks:
        score = 0.0

    return LineScan(
        text=text.strip(),
        words=words,
        hits=hits,
        pattern=_pattern(text, toks, words, break_after, marks),
        break_after=break_after,
        break_source=break_source,
        weak_beats=[words[syls[x].word].text for x in weak],
        extras=[words[syls[x].word].text for x in extras],
        on_beat=on_beat,
        offset_ms=offset,
        score=round(score, 3),
    )


def _pattern(text: str, toks: list[_Token], words: list[WordScan], break_after: int | None, marks: set[int]) -> str:
    out = []
    for i, (t, w) in enumerate(zip(toks, words)):
        if i:
            out.append("-" if t.joined else " / " if i - 1 == break_after or i in marks else " ")
        out.append(t.text.upper() if w.hit or w.beat else t.text.lower())
    return "".join(out)


def stresses(text: str) -> int:
    """Strong stresses in a stretch of speech, counted plainly (no beat fitting)."""
    toks, _, _ = _tokenize(text)
    tails = _compound_tails(toks)
    return sum(
        1
        for i, t in enumerate(toks)
        for w, _ in _weights(t.norm, stress(t.text)[0], i in tails)
        if w == STRONG
    )


def strong_hits(phrase: str) -> int:
    """How many of a line's hits a phrase fills, read as a half-line.

    The count content/formulas.json uses for `beats`: "the wine-dark sea" is
    2, "storm-throated" is 1 (a compound takes one hit, on its first part),
    "when the ships set sail" is 2.
    """
    toks, marks, punct = _tokenize(phrase)
    scan = _scan_line(phrase, toks, marks, punct, 2, None, False)
    tails = _compound_tails(toks)
    return scan.hits - sum(1 for i, w in enumerate(scan.words) if i in tails and w.hit and not w.extra)


# ----- Verses --------------------------------------------------------------


def _align(lines: list[list[_Token]], words: list[TimedWord]) -> None:
    """Give tokens the times of the matching speech-to-text words, in order."""
    flat = [t for line in lines for t in line]
    timed: list[tuple[str, float, float]] = []
    for w in words:
        parts = formulas.tokens(w.text)
        if not parts:
            continue
        step = (w.end - w.start) / len(parts)
        timed.extend((p, w.start + k * step, w.start + (k + 1) * step) for k, p in enumerate(parts))
    j = 0
    for t in flat:
        want = formulas.tokens(t.norm)
        want = want[0] if want else t.norm
        for k in range(j, min(j + 4, len(timed))):
            if timed[k][0] == want:
                t.t0, t.t1 = timed[k][1], timed[k][2]
                j = k + 1
                break


def _split_by_bars(words: list[TimedWord], bpm: float, beats_per_line: int, bars_per_line: int) -> list[str]:
    line_ms = bars_per_line * beats_per_line * 60000.0 / bpm
    lines: dict[int, list[str]] = {}
    for w in words:
        lines.setdefault(max(0, int(w.start // line_ms)), []).append(w.text)
    return [" ".join(lines[k]) for k in sorted(lines)]


def scan_verse(
    transcript: str,
    *,
    words: list[TimedWord] | None = None,
    bpm: float | None = None,
    beats_per_line: int = BEATS_PER_LINE,
    lines_expected: int | None = None,
    cards: list[Formula] | tuple[Formula, ...] = (),
    bars_per_line: int = 2,
) -> VerseScan:
    """Scan a spoken verse. Lines are separated by newlines.

    `words` are speech-to-text words with times in ms from beat 1. When the
    transcript has no newlines, they also split it into lines by bar.
    `cards` are the formulas to look for (the hand, or the whole bank).
    """
    raw = [line[:MAX_LINE_CHARS] for line in (transcript or "").splitlines() if line.strip()]
    if words and bpm and len(raw) <= 1:
        raw = _split_by_bars(words, bpm, beats_per_line, bars_per_line)
    raw = raw[:MAX_LINES]
    tokenized = [_tokenize(line) for line in raw]
    timed = bool(words)
    if timed:
        _align([toks for toks, _, _ in tokenized], words)

    lines = [
        _scan_line(text, toks, marks, punct, beats_per_line, bpm, timed)
        for text, (toks, marks, punct) in zip(raw, tokenized)
    ]

    found = formulas.find([[formulas.tokens(t.norm)[0] if formulas.tokens(t.norm) else t.norm for t in toks] for toks, _, _ in tokenized], list(cards))
    for f in found:
        for w in lines[f.line].words[f.start : f.end]:
            w.formula_id = f.formula.id

    expected = max(lines_expected or 0, len(lines), 1)
    mean = sum(line.score for line in lines) / expected
    best = max(range(len(lines)), key=lambda i: lines[i].score) if lines else None
    return VerseScan(
        lines=lines,
        beat=max(1, min(10, round(1 + 9 * mean))),
        lines_expected=expected,
        timed=timed,
        best_line=best,
        formulas=[f.formula.id for f in found],
    )


def beat_lane(scan: VerseScan, bpm: float, started_at: float = 0.0, beats_per_line: int = BEATS_PER_LINE, bars_per_line: int = 2) -> dict:
    """The `BeatLane` shape in ios/Homer/Contracts.swift.

    Untimed verses (Homer's own, or typed text) are laid on the grid: each
    beat on its pulse, the other words spaced between.
    """
    beat_ms = 60000.0 / bpm
    line_ms = bars_per_line * beats_per_line * beat_ms
    out = []
    for n, line in enumerate(scan.lines):
        times = [w.t for w in line.words]
        if not scan.timed or any(t is None for t in times):
            times = _grid_times(line, n * line_ms, beat_ms)
        for w, t in zip(line.words, times):
            out.append(
                {
                    "text": w.text,
                    "t": round(t, 1),
                    "stressed": w.hit,
                    "onBeat": bool(w.on_beat) if scan.timed else (w.beat and not w.weak_beat),
                    "formulaId": w.formula_id,
                }
            )
    return {"bpm": bpm, "beatsPerLine": beats_per_line, "lines": len(scan.lines), "startedAt": started_at, "words": out}


def _grid_times(line: LineScan, start: float, beat_ms: float) -> list[float]:
    anchors = {i: start + k * beat_ms for k, i in enumerate(i for i, w in enumerate(line.words) if w.beat)}
    times: list[float] = []
    n = len(line.words)
    for i in range(n):
        if i in anchors:
            times.append(anchors[i])
            continue
        prev = max((a for a in anchors if a < i), default=None)
        nxt = min((a for a in anchors if a > i), default=None)
        if prev is not None and nxt is not None:
            times.append(anchors[prev] + (anchors[nxt] - anchors[prev]) * (i - prev) / (nxt - prev))
        elif nxt is not None:
            times.append(anchors[nxt] - (nxt - i) * beat_ms / 3)
        elif prev is not None:
            times.append(anchors[prev] + (i - prev) * beat_ms / 3)
        else:
            times.append(start + i * beat_ms / 3)
    return times
