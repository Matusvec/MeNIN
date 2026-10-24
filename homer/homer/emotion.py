"""The eight emotions the scene paints, and the Range axis built from them.

Range comes from the turn's emotion history: the weight vectors the
classifier returned every ~1.5 s while the poet spoke. When there is no
history (a typed verse, or a turn too short to sample), a small word list
stands in, one sample per line.
"""

from __future__ import annotations

import re

EMOTIONS = ("anger", "grief", "joy", "awe", "tenderness", "fear", "defiance", "longing")

# A starter lexicon for the no-history fallback. Stems match word starts.
LEXICON = {
    "anger": "rage wrath fury burn blood fist hate curse spite scorn storm break smash roar seeth bitter".split(),
    "grief": "grief mourn weep tear grave dead death lost loss gone ash bury cold empty sorrow widow funeral".split(),
    "joy": "joy laugh danc sing feast gold bright sun shin glad bless wine sweet warm cheer song".split(),
    "awe": "god gods vast sky star heaven mountain thunder dawn eternal infinite holy wonder giant ocean".split(),
    "tenderness": "gentle soft hold hand kiss child mother home rest care quiet tender dear embrace hush".split(),
    "fear": "fear dread dark shadow tremb shiver hide ghost night wolf haunt terror creep whisper fog".split(),
    "defiance": "never stand rise fight defy refuse unbow unbroken iron steel spit challenge dare win".split(),
    "longing": "long miss far away return wait shore distant remember yearn wander sail ago someday".split(),
}
WORD_RE = re.compile(r"[a-z']+")


def normalize(weights: dict[str, float]) -> dict[str, float]:
    clean = {e: max(0.0, float(weights.get(e, 0.0))) for e in EMOTIONS}
    total = sum(clean.values())
    if total <= 0:
        return {e: 1.0 / len(EMOTIONS) for e in EMOTIONS}
    return {e: v / total for e, v in clean.items()}


def lexicon_weights(text: str) -> dict[str, float] | None:
    """Rough weights from word matches, or None when nothing matched."""
    counts = dict.fromkeys(EMOTIONS, 0.0)
    for word in WORD_RE.findall(text.lower()):
        for emotion, stems in LEXICON.items():
            if any(word.startswith(s) for s in stems):
                counts[emotion] += 1
    if not any(counts.values()):
        return None
    return normalize(counts)


def range_score(history: list[dict[str, float]], lines: list[str] | None = None) -> int:
    """The Range axis, 1 to 10.

    Two parts, equally weighted:
    - breadth: how many emotions led a sample or reached 0.35 of one (1 to 4+)
    - travel: how far the mix moved from sample to sample (half the L1 distance, summed)
    """
    samples = [normalize(h) for h in history if h]
    if not samples and lines:
        samples = [w for w in (lexicon_weights(line) for line in lines) if w]
    if not samples:
        return 1
    present = set()
    for s in samples:
        present.add(max(s, key=s.get))
        present.update(e for e, v in s.items() if v >= 0.35)
    travel = sum(0.5 * sum(abs(b[e] - a[e]) for e in EMOTIONS) for a, b in zip(samples, samples[1:]))
    breadth = min(len(present) - 1, 3) / 3
    moved = min(travel, 1.5) / 1.5
    return max(1, min(10, round(1 + 9 * (0.5 * breadth + 0.5 * moved))))
