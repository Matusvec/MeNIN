"""Free verse into lines (SPEC "The turn", step 3: lines are whatever you say between breaths).

A battle verse arrives with the phone's pause breaks as newlines. A line that runs
long (a poet who never drew breath, or a transcript with no breaks at all) is
split at its best stress boundary, so the scanner, the judge and the song always
get lines. Battle only: lessons scan exactly what they are given.
"""

from __future__ import annotations

from .scanner import stresses

LONG = 12  # words: a longer line is split
STRESSES = 4  # what a line naturally carries (SPEC, Flow)
SMALL = frozenset(
    "a an the of to in on at by for from with and or but nor so my your his her its our their is was are were be as that than".split()
)
OPENERS = frozenset("and but so then or when while till until because".split())
PUNCT = ",.;:!?—–-"


def break_lines(text: str, long: int = LONG) -> str:
    """The verse with one line per breath, and no line over `long` words."""
    out: list[str] = []
    for raw in (text or "").splitlines():
        words = raw.split()
        if words:
            out.extend(_split(words, long))
    return "\n".join(out)


def _split(words: list[str], long: int) -> list[str]:
    if len(words) <= long:
        return [" ".join(words)]
    best, best_cost = 3, float("inf")
    for k in range(3, min(len(words) - 2, long + 2)):  # both halves keep three words; the first fits (one over, at a cost)
        left, right = " ".join(words[:k]), " ".join(words[k:])
        cost = abs(stresses(left) - STRESSES) + max(0, k - long)
        if len(words) - k <= long:
            cost += abs(stresses(right) - STRESSES)
        if words[k - 1][-1] in PUNCT:  # a comma or a full stop is a breath already
            cost -= 2
        if words[k - 1].lower().strip(PUNCT) in SMALL:  # never end a line on "the"
            cost += 3
        if words[k].lower().strip(PUNCT) in OPENERS:
            cost -= 0.5
        if cost < best_cost:
            best, best_cost = k, cost
    return _split(words[:best], long) + _split(words[best:], long)
