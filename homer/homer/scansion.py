"""Deterministic scansion helper built on the CMU Pronouncing Dictionary.

This module never calls a language model. It gives Homer a reliable baseline:
syllable counts, lexical stress, and the places where a line's fixed
(polysyllabic) stresses fight the iambic template. Context-dependent calls,
such as whether a monosyllable is promoted or demoted, are left to Homer and
flagged as such.

Notation used everywhere in the project:
    ˇ  unstressed syllable
    /  stressed syllable
    ?  ambiguous (secondary stress or unknown word)
    |  foot boundary
"""

from __future__ import annotations

import re
from itertools import combinations
from dataclasses import asdict, dataclass, field

import pronouncing

UNSTRESSED = "ˇ"
STRESSED = "/"
AMBIGUOUS = "?"

MAX_LINES = 40
MAX_LINE_CHARS = 300

# Words that usually take no stress in running speech. Monosyllables in this
# set lean unstressed; other monosyllables lean stressed. Either can flip.
FUNCTION_WORDS = frozenset(
    """
    a an the and but or nor for so yet if as than that though while when where
    whence whither of to in on at by from with into onto upon through till
    unto i me my we us our you your thou thee thy ye he him his she her it its
    they them their who whom whose which is am are was were been have has had
    hath doth do does did shall should will would can could may might must
    'tis 't 'twas 'twere th' i'
    """.split()
)

# The weakest function words: articles, prepositions, conjunctions. Only these
# trigger a "possible pyrrhic" hint when they land on a strong position.
CLITICS = frozenset(
    "a an the and or nor of to in on at by from with as than if but for into "
    "upon unto th' i'".split()
)

# Archaic and poetic forms missing from CMU: word -> list of stress strings.
ARCHAIC = {
    "o'er": ["1"],
    "e'er": ["1"],
    "ne'er": ["1"],
    "'twas": ["0"],
    "'twere": ["0"],
    "'tis": ["0"],
    "th'": [""],
    "i'": [""],
    "oft": ["1"],
    "ere": ["1"],
    "hath": ["1"],
    "doth": ["1"],
    "thou": ["1"],
    "thee": ["1"],
    "thy": ["1"],
    "thine": ["1"],
    "ye": ["1"],
    "art": ["1"],
    "wilt": ["1"],
    "shalt": ["1"],
    "dost": ["1"],
    "canst": ["1"],
}

# Words poets commonly squeeze by one syllable (heav'n, flow'r, ev'ry).
ELIDABLE = frozenset(
    "heaven heavens even evening flower flowers power powers hour hours fire "
    "fires tower towers being spirit spirits general several ever never "
    "over prisoner violet desire".split()
)

WORD_RE = re.compile(r"[A-Za-z]+(?:['’][A-Za-z]+)*['’]?|['’][A-Za-z]+")
CAESURA_RE = re.compile(r"[,;:.!?—–]|--")
VOWEL_GROUP_RE = re.compile(r"[aeiouy]+")


@dataclass
class WordScan:
    text: str
    in_dictionary: bool
    source: str  # "cmu", "archaic", or "heuristic"
    stress_options: list[str]  # one string of 0/1/2 per pronunciation
    syllable_options: list[int]
    monosyllable: bool
    function_word: bool
    clitic: bool = False
    notes: list[str] = field(default_factory=list)

    @property
    def default_stress(self) -> str:
        return self.stress_options[0] if self.stress_options else ""


@dataclass
class Syllable:
    word_index: int
    word: str
    mark: str  # lexical lean: ˇ, /, or ?
    fixed: bool  # True when the stress comes from a polysyllable's dictionary entry
    clitic: bool = False


@dataclass
class Conflict:
    syllable: int  # 1-based position in the line
    foot: int
    word: str
    expected: str
    lexical: str


@dataclass
class LineScan:
    text: str
    words: list[WordScan]
    syllable_count: int
    syllable_range: tuple[int, int]
    lexical: str  # one mark per syllable, lexical lean
    suggested: str  # iambic fit with foot dividers
    da_dum: str
    conflicts: list[Conflict]
    hints: list[str]
    caesurae: list[int]  # syllable positions after which a pause falls
    elision_candidates: list[str]
    unknown_words: list[str]
    end_stopped: bool
    elided_fit: dict | None = None  # best fit with elisions applied, when it helps

    def to_dict(self) -> dict:
        d = asdict(self)
        d["syllable_range"] = list(self.syllable_range)
        for w, ws in zip(d["words"], self.words):
            w["default_stress"] = ws.default_stress
        return d


def normalize(word: str) -> str:
    return word.lower().replace("’", "'")


def heuristic_syllables(word: str) -> int:
    w = re.sub(r"[^a-z]", "", word.lower())
    if not w:
        return 0
    groups = len(VOWEL_GROUP_RE.findall(w))
    if w.endswith("e") and not w.endswith(("le", "ee", "ye")) and groups > 1:
        groups -= 1
    if w.endswith("es") and not w.endswith(("ses", "zes", "ches", "shes", "ges", "ces", "xes")) and groups > 1:
        groups -= 1
    return max(1, groups)


def lookup(word: str) -> WordScan:
    """Scan a single word. Never raises; unknown words fall back to a heuristic."""
    norm = normalize(word)
    notes: list[str] = []
    source = "cmu"
    options = [pronouncing.stresses(p) for p in pronouncing.phones_for_word(norm)]

    if norm in ARCHAIC and (not options or norm in ("'tis", "th'", "i'")):
        options, source = list(ARCHAIC[norm]), "archaic"
    if not options and norm.endswith("'s"):
        base = [pronouncing.stresses(p) for p in pronouncing.phones_for_word(norm[:-2])]
        if base:
            options = base
            notes.append("possessive: stress taken from base word")
    if not options and norm.endswith("'d"):
        base = [pronouncing.stresses(p) for p in pronouncing.phones_for_word(norm[:-2] + "ed")]
        if base:
            options = [s[:-1] if len(s) > 1 and s.endswith("0") else s for s in base]
            notes.append("'d contraction: -ed silent")
    in_dictionary = bool(options)
    if not options:
        source = "heuristic"
        n = heuristic_syllables(norm)
        options = ["?" * n]
        notes.append("not in CMU dictionary: syllable count is a guess, stress unknown")

    # Archaic voiced -ed (e.g. "belovèd"): offer one extra syllable as an option.
    if norm.endswith("ed") and len(norm) > 3 and norm[-3] not in "td" and source == "cmu":
        notes.append("archaic voiced -ed (-èd) would add a syllable")
    deduped = list(dict.fromkeys(options))
    if norm in FUNCTION_WORDS:
        # "our", "every"-style function words: the shortest reading is the usual one.
        deduped.sort(key=len)
    syllables = sorted({len(s) for s in deduped})
    if len(syllables) > 1:
        notes.append("dictionary lists more than one syllable count")
    if norm in ELIDABLE and min(syllables) > 1:
        notes.append("commonly elided in verse (one syllable fewer)")
        syllables = sorted(set(syllables) | {min(syllables) - 1})

    return WordScan(
        text=word,
        in_dictionary=in_dictionary,
        source=source,
        stress_options=deduped,
        syllable_options=syllables,
        monosyllable=len(deduped[0]) == 1,
        function_word=norm in FUNCTION_WORDS,
        clitic=norm in CLITICS,
        notes=notes,
    )


def _syllables_for(index: int, ws: WordScan, stress: str | None = None, capitalized_mid: bool = False) -> list[Syllable]:
    stress = ws.default_stress if stress is None else stress
    if len(stress) == 1:
        if stress == "?":
            mark = AMBIGUOUS
        else:
            weak = ws.function_word and not capitalized_mid
            mark = UNSTRESSED if weak else STRESSED
        return [Syllable(index, ws.text, mark, fixed=False, clitic=ws.clitic and not capitalized_mid)]
    out = []
    for digit in stress:
        if digit == "1":
            out.append(Syllable(index, ws.text, STRESSED, fixed=True))
        elif digit == "0":
            out.append(Syllable(index, ws.text, UNSTRESSED, fixed=True))
        else:
            out.append(Syllable(index, ws.text, AMBIGUOUS, fixed=False))
    return out


def _elided_stress(ws: WordScan) -> str | None:
    """Stress string with one syllable squeezed out, or None if not elidable."""
    default = ws.default_stress
    shorter = [s for s in ws.stress_options if 0 < len(s) < len(default)]
    if shorter:
        return shorter[0]
    if normalize(ws.text) in ELIDABLE and "0" in default[1:]:
        i = default.rfind("0")
        return default[:i] + default[i + 1 :]
    return None


def _group_feet(marks: list[str]) -> str:
    feet = [" ".join(marks[i : i + 2]) for i in range(0, len(marks), 2)]
    return " | ".join(feet)


def _da_dum(marks: list[str]) -> str:
    words = ["DUM" if m == STRESSED else "da" for m in marks]
    return " | ".join(" ".join(words[i : i + 2]) for i in range(0, len(words), 2))


def _fit(syllables: list[Syllable]) -> tuple[list[str], list[Conflict]]:
    """Fit syllables to the iambic template; return suggested marks and conflicts."""
    template = [UNSTRESSED if i % 2 == 0 else STRESSED for i in range(len(syllables))]
    conflicts = [
        Conflict(i + 1, i // 2 + 1, s.word, exp, s.mark)
        for i, (s, exp) in enumerate(zip(syllables, template))
        if s.fixed and s.mark != exp
    ]
    # Dictionary stress where it is fixed, the metre elsewhere.
    suggested = [s.mark if s.fixed else template[i] for i, s in enumerate(syllables)]
    return suggested, conflicts


def _build(words: list[WordScan], caps: list[bool], overrides: dict[int, str], dropped: set[int]) -> list[Syllable]:
    out: list[Syllable] = []
    for i, ws in enumerate(words):
        if i in dropped:
            continue
        out.extend(_syllables_for(i, ws, overrides.get(i), caps[i]))
    return out


def scan_line(text: str) -> LineScan:
    """Scan one line against iambic pentameter."""
    text = (text or "")[:MAX_LINE_CHARS]
    tokens = list(WORD_RE.finditer(text))
    words = [lookup(m.group()) for m in tokens]
    # A capitalised word mid-line (e.g. "May") is probably a name, so content.
    caps = [i > 0 and m.group()[:1].isupper() and normalize(m.group()) != "i" for i, m in enumerate(tokens)]

    syllables = _build(words, caps, {}, set())
    caesurae: list[int] = []
    count = 0
    for i, m in enumerate(tokens):
        count += len(words[i].default_stress)
        nxt = tokens[i + 1].start() if i + 1 < len(tokens) else None
        if nxt is not None and CAESURA_RE.search(text[m.end() : nxt]):
            caesurae.append(count)

    n = len(syllables)
    lexical = [s.mark for s in syllables]
    suggested, conflicts = _fit(syllables)

    # Elision options: squeezable words and "the"/"to" before a vowel.
    options: list[tuple[str, dict[int, str], set[int]]] = []
    for i, ws in enumerate(words):
        short = _elided_stress(ws)
        if short is not None:
            options.append((ws.text, {i: short}, set()))
    for i in range(len(words) - 1):
        a, b = normalize(words[i].text), normalize(words[i + 1].text)
        if a in ("the", "to") and b[:1] in "aeiou":
            options.append((f"{words[i].text} {words[i + 1].text} -> {a[:-1]}'{words[i + 1].text}", {}, {i}))
    elisions = [label for label, _, _ in options]

    lo = sum(min(w.syllable_options) for w in words) - sum(1 for _, _, d in options if d)
    hi = sum(max(w.syllable_options) for w in words)

    hints: list[str] = []
    elided_fit = None
    if not words:
        hints.append("empty line")
    else:
        hints.extend(_variation_hints(syllables, lexical, conflicts))
        stressed_eleventh = n == 11 and lexical[-1] == STRESSED  # 11 syllables but no feminine ending
        if n not in (10, 11) or conflicts or stressed_eleventh:
            elided_fit = _best_elision(words, caps, options, n, conflicts)
        if elided_fit:
            hints.append(
                f"with elision ({', '.join(elided_fit['elided'])}) the line has "
                f"{elided_fit['syllable_count']} syllables and {len(elided_fit['conflicts'])} stress clashes"
            )
        if n not in (10, 11) and not elided_fit:
            hints.append(f"{n} syllables: pentameter wants 10 (11 with a feminine ending)")

    unknown = [w.text for w in words if not w.in_dictionary]
    stripped = text.rstrip()
    return LineScan(
        text=text,
        words=words,
        syllable_count=n,
        syllable_range=(lo, hi),
        lexical=" ".join(lexical),
        suggested=_group_feet(suggested),
        da_dum=_da_dum(suggested),
        conflicts=conflicts,
        hints=hints,
        caesurae=caesurae,
        elision_candidates=elisions,
        unknown_words=unknown,
        end_stopped=bool(stripped) and bool(CAESURA_RE.search(stripped[-1])),
        elided_fit=elided_fit,
    )


def _best_elision(words, caps, options, n, conflicts) -> dict | None:
    """Try up to 3 elisions; return the fit only if it beats the line as spoken."""
    def badness(count, clashes):
        return (0 if count in (10, 11) else abs(count - 10)) * 10 + clashes + (count == 11)

    best = None
    base = badness(n, len(conflicts))
    opts = options[:6]
    for size in (1, 2, 3):
        for combo in combinations(opts, size):
            overrides: dict[int, str] = {}
            dropped: set[int] = set()
            for _, o, d in combo:
                overrides.update(o)
                dropped |= d
            syl = _build(words, caps, overrides, dropped)
            sugg, confl = _fit(syl)
            score = badness(len(syl), len(confl))
            if score < base and (best is None or score < best[0]):
                best = (score, combo, syl, sugg, confl)
    if best is None:
        return None
    _, combo, syl, sugg, confl = best
    return {
        "elided": [label for label, _, _ in combo],
        "syllable_count": len(syl),
        "suggested": _group_feet(sugg),
        "da_dum": _da_dum(sugg),
        "conflicts": [asdict(c) for c in confl],
    }


def _variation_hints(syllables, lexical, conflicts) -> list[str]:
    hints = []
    n = len(syllables)
    conflict_pos = {c.syllable for c in conflicts}
    explained: set[int] = set()

    # Trochaic inversion: a foot reading / ˇ where at least one stress is fixed.
    for start in range(0, min(n, 10) - 1, 2):
        a, b = syllables[start], syllables[start + 1]
        if lexical[start] == STRESSED and lexical[start + 1] == UNSTRESSED and (
            start + 1 in conflict_pos or start + 2 in conflict_pos
        ):
            where = "first foot" if start == 0 else f"foot {start // 2 + 1}"
            pair = a.word if a.word == b.word else f"{a.word} {b.word}"
            hints.append(f"trochaic inversion likely in {where} ({pair})")
            explained |= {start + 1, start + 2}

    if n == 11 and lexical[-1] in (UNSTRESSED, AMBIGUOUS) and lexical[-2] != UNSTRESSED:
        hints.append("feminine ending: unstressed 11th syllable")
        explained.add(11)

    # Spondee / pyrrhic candidates come from monosyllables only, so flag, never assert.
    for start in range(0, min(n, 10) - 1, 2):
        a, b = syllables[start], syllables[start + 1]
        if not a.fixed and lexical[start] == STRESSED and lexical[start + 1] == STRESSED:
            hints.append(f"possible spondee in foot {start // 2 + 1} ({a.word} {b.word})")
        if lexical[start] == UNSTRESSED and b.clitic:
            hints.append(f"possible pyrrhic in foot {start // 2 + 1} ({a.word} {b.word}): '{b.word}' sits on a strong position")

    for c in conflicts:
        if c.syllable not in explained:
            hints.append(f"stress clash at syllable {c.syllable} ('{c.word}' is {c.lexical} where the metre wants {c.expected})")
    return hints


def scan_poem(text: str) -> dict:
    """Scan every non-empty line and add poem-level observations."""
    raw = [line for line in (text or "").splitlines() if line.strip()][:MAX_LINES]
    scans = [scan_line(line) for line in raw]
    enjambed = [i + 1 for i, s in enumerate(scans[:-1]) if not s.end_stopped]
    rhyme_pairs = []
    for i in range(len(scans) - 1):
        for j in range(i + 1, min(i + 4, len(scans))):
            if _rhymes(scans[i], scans[j]):
                rhyme_pairs.append([i + 1, j + 1])
    return {
        "line_count": len(scans),
        "lines": [s.to_dict() for s in scans],
        "enjambed_after_lines": enjambed,
        "rhyming_line_pairs": rhyme_pairs,
        "truncated": len([l for l in (text or "").splitlines() if l.strip()]) > MAX_LINES,
    }


def _rhymes(a: LineScan, b: LineScan) -> bool:
    if not a.words or not b.words:
        return False
    wa, wb = normalize(a.words[-1].text), normalize(b.words[-1].text)
    return wa != wb and wb in pronouncing.rhymes(wa)


def format_scansion(scan: LineScan) -> str:
    """Human-readable block for a single line."""
    return f"{scan.text}\n{scan.suggested}   ({scan.syllable_count} syllables)\n{scan.da_dum}"
