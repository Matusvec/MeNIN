"""The eight emotions the scene paints, and the Range axis built from them.

Range comes from the turn's emotion history: the weight vectors the
classifier returned every ~1.5 s while the poet spoke. When there is no
history (a typed verse, or a turn too short to sample), a small word list
stands in, one sample per line.
"""

from __future__ import annotations

import re
from collections import Counter
from functools import cache
from pathlib import Path
from typing import Any

import anthropic

from . import claude
from .config import Settings, settings as load_settings
from .prompts import block

EMOTIONS = ("anger", "grief", "joy", "awe", "tenderness", "fear", "defiance", "longing")
NEUTRAL = 5  # Range with nothing to measure: no samples and no feeling words
FELT = 0.3  # a sample whose strongest feeling is weaker heard nothing yet (silence, "okay, I'll try")
LEAD = 0.6  # one sample this strong is enough to count a feeling as present

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
    """The Range axis, 1 to 10. One feeling held is about 2; two feelings about 5; a real turn 9 or 10.

    Two parts:
    - breadth (55%): emotions that led two samples or reached LEAD in one (one to four or more)
    - travel (45%): how far the mix moved from the verse's beginning to its middle to its end

    Samples come every ~1.5 s from a classifier that wobbles between neighbours (longing, fear);
    counting every wobble gave any 20 s verse a 10. Samples that heard nothing are dropped, and
    with nothing at all to measure the score is a neutral 5, never a gift or a penalty.
    """
    raw = [h for h in history if h and max(float(v or 0.0) for v in h.values()) >= FELT]
    if not raw and lines:
        raw = [w for w in (lexicon_weights(line) for line in lines) if w]
    if not raw:
        return NEUTRAL
    samples = [normalize(h) for h in raw]
    leads = Counter(max(s, key=s.get) for s in samples)
    present = {e for e, n in leads.items() if n >= 2 or len(samples) == 1}
    present.update(e for h in raw for e in EMOTIONS if float(h.get(e, 0.0) or 0.0) >= LEAD)
    present = present or {leads.most_common(1)[0][0]}
    k = min(3, len(samples))  # beginning, middle, end
    parts = [samples[i * len(samples) // k : (i + 1) * len(samples) // k] for i in range(k)]
    means = [{e: sum(s[e] for s in part) / len(part) for e in EMOTIONS} for part in parts]
    travel = sum(0.5 * sum(abs(b[e] - a[e]) for e in EMOTIONS) for a, b in zip(means, means[1:]))
    breadth = min(len(present) - 1, 3) / 3
    moved = min(travel, 1.0)
    return max(1, min(10, round(2 + 8 * (0.55 * breadth + 0.45 * moved))))


# ----- The live classifier -----------------------------------------------

CLASSIFY_TIMEOUT = 2.5  # seconds; a sample that arrives later than the next one is useless
WINDOW_WORDS = 40  # the latest words are what the scene should show


@cache
def _system() -> str:
    return (Path(__file__).parent / "prompts" / "emotion.md").read_text(encoding="utf-8").strip() + "\n"


def schema() -> dict[str, Any]:
    return claude.obj({e: {"type": "number"} for e in EMOTIONS})


class Classifier:
    """Weights over the eight emotions for the latest stretch of speech (SPEC "The scene")."""

    def __init__(self, client: Any | None = None, cfg: Settings | None = None) -> None:
        self.cfg = cfg or load_settings()
        self.client = client if client is not None else anthropic.AsyncAnthropic(timeout=CLASSIFY_TIMEOUT)

    def request(self, text: str, loudness: float | None, pitch: float | None) -> dict[str, Any]:
        kw = claude.options(self.cfg.emotion_model, "low", schema(), thinking="off", fallbacks=self.cfg.fallbacks, max_tokens=512)
        kw["system"] = claude.system(_system())
        window = " ".join(text.split()[-WINDOW_WORDS:])
        prosody = []
        if loudness is not None:
            prosody.append(f"loudness: {max(0.0, min(1.0, loudness)):.2f}")
        if pitch is not None:
            prosody.append(f"pitch: {max(0.0, pitch):.0f}")
        kw["messages"] = [{"role": "user", "content": "\n".join([*prosody, block("window", window)])}]
        return kw

    async def classify(self, text: str, loudness: float | None = None, pitch: float | None = None) -> dict[str, float] | None:
        """Weights 0 to 1 per emotion, or None when there's nothing to read or Claude didn't answer in time."""
        if not text.strip():
            return None
        data = await claude.ask(self.client, self.request(text, loudness, pitch), CLASSIFY_TIMEOUT)
        if data is None:
            return None
        return {e: round(max(0.0, min(1.0, float(data.get(e, 0.0) or 0.0))), 3) for e in EMOTIONS}
