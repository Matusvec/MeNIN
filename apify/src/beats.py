"""How many of a line's four hits a phrase fills: the `beats` field of the bank.

The rule is content/README.md's, and this is a self-contained copy of how
homer/homer/scanner.py counts it (the Actor ships without the rest of the
repo): every content word's stressed syllable is a hit, small words are not,
and a hyphenated compound takes one hit, on its first part (WINE-dark,
AEGIS-bearing). Stress comes from the CMU Pronouncing Dictionary.

    the wine-dark sea      -> 2
    the earth-shaker       -> 1
    son of Atreus          -> 2
    the bright-eyed goddess Athene -> 3 (too long for the bank)

tests/test_beats.py checks this against the bank's own `beats` values.
"""

from __future__ import annotations

import re
from functools import lru_cache

import pronouncing

# Copied from homer/homer/scanner.py. Keep in step with it.
WEAK_WORDS = frozenset(
    """
    a an the and or nor but of to in on at by from with as than if for
    through till 'til is am are was were be been 's th' o'
    """.split()
)
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
FUNCTION_POLY = frozenset(
    """
    about above across after against along among around before behind below
    beneath beside between beyond during into onto upon unto over under until
    within without toward towards because although whenever wherever myself
    yourself himself herself itself ourselves themselves
    """.split()
)
ARCHAIC = {
    "o'er": "1", "e'er": "1", "ne'er": "1", "'twas": "1", "'tis": "1", "th'": "0",
    "oft": "1", "ere": "1", "hath": "1", "doth": "1", "thou": "1", "thee": "1",
    "thy": "1", "thine": "1", "ye": "1", "art": "1", "wilt": "1", "shalt": "1",
    "dost": "1", "canst": "1",
}

WORD_RE = re.compile(r"[A-Za-z]+(?:['’][A-Za-z]+)*['’]?|['’][A-Za-z]+")
VOWELS_RE = re.compile(r"[aeiouy]+")


def _guess_syllables(word: str) -> int:
    w = re.sub(r"[^a-z]", "", word)
    n = len(VOWELS_RE.findall(w))
    if w.endswith("e") and not w.endswith(("le", "ee", "ye")) and n > 1:
        n -= 1
    return max(1, n)


@lru_cache(maxsize=16384)
def stress(word: str) -> tuple[str, bool]:
    """CMU stress digits for a word ("10" for "aegis"), and whether it was found."""
    norm = word.lower().replace("’", "'").strip("'")
    if norm in ARCHAIC:
        return ARCHAIC[norm], True
    phones = pronouncing.phones_for_word(norm)
    if phones:
        options = [pronouncing.stresses(p) for p in phones]
        if norm in WEAK_WORDS or norm in LIGHT_WORDS or norm in FUNCTION_POLY:
            options.sort(key=len)
        return options[0], True
    for suffix in ("'s", "s'", "'d"):
        if norm.endswith(suffix):
            base, known = stress(norm[: -len(suffix)] + ("ed" if suffix == "'d" else ""))
            if known:
                return (base[:-1] if suffix == "'d" and len(base) > 1 else base), True
    n = _guess_syllables(norm)
    return "1" + "0" * (n - 1), False  # unknown names: stress the first syllable


def _strong(norm: str, digits: str, compound_tail: bool) -> int:
    """Strong syllables in one word, as the scanner weighs them."""
    if compound_tail:
        return 0  # the second part of a compound is secondary, never a hit
    if len(digits) == 1:
        return 0 if norm in WEAK_WORDS or norm in LIGHT_WORDS else 1
    if norm in FUNCTION_POLY:
        return 0
    return digits.count("1")


def count(phrase: str) -> int:
    """The phrase's hits: its strong stresses, a compound counted once."""
    total = 0
    prev_end = None
    for m in WORD_RE.finditer(phrase):
        joined = prev_end is not None and phrase[prev_end : m.start()] == "-"
        word = m.group()
        total += _strong(word.lower().replace("’", "'"), stress(word)[0], joined)
        prev_end = m.end()
    return total


def unknown_words(phrase: str) -> list[str]:
    """Words the CMU dictionary doesn't know (their stress is a guess)."""
    return [m.group() for m in WORD_RE.finditer(phrase) if not stress(m.group())[1]]
