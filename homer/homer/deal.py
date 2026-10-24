"""Themes, hands and the freeze rescue. No model calls: these must be instant.

SPEC "The turn": you are dealt five formulas that fit the beat, drawn from
the theme and your hoard. If you go silent mid-turn, Homer whispers one
formula that fits.
"""

from __future__ import annotations

import json
import random
import re
from collections.abc import Iterable
from dataclasses import dataclass
from functools import cache

from . import formulas
from .formulas import CONTENT_DIR, Formula
from .scanner import stresses, strong_hits

HAND_SIZE = 5
CANDIDATES = 8  # deal_round tops each hand up to 5 from this list, skipping cards already held

# Used until content/ has a themes.json (a JSON array of strings). The first
# three are the judging theme cards (/themes?demo=true; hands in docs/gtm/demo-hands.md).
DEFAULT_THEMES = (
    "A ship that never came home",
    "The night before the deadline",
    "The war between two brothers",
    "A city that never sleeps",
    "The last train out",
    "A feast for a returning hero",
    "The forge at midnight",
    "A storm on the open sea",
    "The road that brought you here",
    "A letter never sent",
    "Dawn after the long battle",
    "The wolf at the edge of the wood",
    "A crown nobody wanted",
    "The fire that took the hall",
    "The gods are watching",
    "The house you grew up in",
)

# Homer's call to the round's first poet, after "{name}, {title}." (docs/ux-flow.md, T1 / P21).
THEME_CALLS = {
    "A ship that never came home": "The sea is yours.",
    "The night before the deadline": "The clock is yours.",
    "The war between two brothers": "Pick a brother.",
    "A city that never sleeps": "The streets are yours.",
    "The last train out": "The platform is yours.",
    "A feast for a returning hero": "Raise the cup.",
    "The forge at midnight": "Strike while it's hot.",
    "A storm on the open sea": "The storm is yours.",
    "The road that brought you here": "The road is yours.",
    "A letter never sent": "Send it now.",
    "Dawn after the long battle": "The dawn is yours.",
    "The wolf at the edge of the wood": "Mind the wolf.",
    "A crown nobody wanted": "The crown is yours.",
    "The fire that took the hall": "The fire is yours.",
    "The gods are watching": "Give them a show.",
    "The house you grew up in": "Take us home.",
}
FLOOR = "The floor is yours."  # any other theme, a typed one included


def call_for(theme: str) -> str:
    key = " ".join(theme.split()).lower()
    return next((call for t, call in THEME_CALLS.items() if t.lower() == key), FLOOR)


# Words in a theme that point at the bank's theme tags (content/README.md).
TAG_WORDS = {
    "sea": "sea ocean ship ships sail sailor wave waves harbor harbour shore boat tide island",
    "war": "war battle fight sword spear army enemy brothers siege soldier",
    "home": "home house mother father family hearth return returning grew",
    "love": "love heart kiss lover wedding beloved letter",
    "loss": "never lost gone death dead grief goodbye last sent",
    "journey": "road journey train travel leave came brought wander path out",
    "night": "night midnight dark sleep sleeps sleepless moon",
    "dawn": "dawn morning sunrise after",
    "storm": "storm thunder rain lightning wind",
    "fire": "fire forge burn flame flames took",
    "gods": "god gods heaven fate watching olympus",
    "feast": "feast party wine dinner hall drink",
    "city": "city street streets town subway tower",
    "wild": "wolf wood woods forest mountain wild beast",
    "time": "time clock deadline years age before last",
    "glory": "glory win hero champion crown victory king",
}
WORD_RE = re.compile(r"[a-z']+")


@cache
def themes() -> tuple[str, ...]:
    path = CONTENT_DIR / "themes.json"
    if path.is_file():
        return tuple(json.loads(path.read_text(encoding="utf-8")))
    return DEFAULT_THEMES


def tags(theme: str) -> set[str]:
    words = set(WORD_RE.findall(theme.lower()))
    return {tag for tag, keys in TAG_WORDS.items() if words & set(keys.split())}


def pick_theme(rng: random.Random | None = None, avoid: Iterable[str] = ()) -> str:
    rng = rng or random.Random()
    pool = [t for t in themes() if t not in set(avoid)] or list(themes())
    return rng.choice(pool)


@dataclass(frozen=True)
class Card:
    """A dealt card: `FormulaCard` in Contracts.swift, minus game state."""

    id: str
    text: str
    kind: str
    beats: int
    hoard: bool = False  # the poet's own coined formula


def _card(f: Formula, hoard: bool = False) -> Card:
    beats = f.beats if formulas.in_bank(f.text) else max(1, min(2, strong_hits(f.text)))
    return Card(f.id, f.text, f.kind, beats, hoard)


def deal(
    theme: str,
    hoard: Iterable[str] = (),
    *,
    n: int = HAND_SIZE,
    exclude: Iterable[str] = (),
    rng: random.Random | None = None,
    ranked: list[Formula] | None = None,
) -> list[Card]:
    """n cards for a theme: up to two from the poet's hoard, the rest from the bank.

    Cards fitting more of the theme's tags come first, with a mix of kinds so
    a hand can fill a half-line, name a hero and name a thing. `exclude` holds
    card texts already dealt or held. `ranked` is the bank in order of fit from
    Moss (homer/moss_dealer.py); when given, it replaces the tag order, with a
    light shuffle among the best so hands vary.
    """
    rng = rng or random.Random()
    want = tags(theme)
    skip = {formulas.key(t) for t in exclude}
    hand: list[Card] = []

    own = [formulas.card(t) for t in hoard if formulas.key(t) and formulas.key(t) not in skip]
    rng.shuffle(own)
    for f in own[: min(2, n)]:
        hand.append(_card(f, hoard=True))
        skip.add(formulas.key(f.text))

    pool = [f for f in formulas.bank() if formulas.key(f.text) not in skip]
    rng.shuffle(pool)
    pool.sort(key=lambda f: -len(want & set(f.themes)))
    if ranked:
        best = [f for f in ranked if formulas.key(f.text) not in skip]
        head = best[: 3 * n]
        rng.shuffle(head)
        seen = {f.id for f in best}
        pool = head + best[3 * n :] + [f for f in pool if f.id not in seen]
    kinds_needed = ["half_line", "epithet", "kenning"]
    for kind in kinds_needed:
        if len(hand) >= n:
            break
        f = next((f for f in pool if f.kind == kind), None)
        if f:
            hand.append(_card(f))
            pool.remove(f)
    for f in pool:
        if len(hand) >= n:
            break
        hand.append(_card(f))
    return hand


def rescue(transcript: str, hand: Iterable[str], *, played: Iterable[str] = (), theme: str = "") -> Card | None:
    """The one card Homer whispers when the poet freezes.

    It fills what the current line still needs: a half-line at the start of a
    line, a two-hit card with two or more hits to go, else a one-hit card.
    Cards already spoken are skipped; the theme breaks ties.
    """
    spent = {formulas.key(t) for t in played}
    cards = [_card(formulas.card(t)) for t in hand if formulas.key(t) and formulas.key(t) not in spent]
    if not cards:
        return None
    lines = (transcript or "").split("\n")
    current = lines[-1] if lines else ""
    hits = min(4, stresses(current))
    left = max(1, 4 - hits)
    want = tags(theme)

    def fit(c: Card) -> tuple[int, int, int]:
        f = formulas.card(c.text)
        shape = 2 if (hits == 0 and c.kind == "half_line") else 1 if c.beats == min(left, 2) else 0
        return (shape, len(want & set(f.themes)), -c.beats if left == 1 else c.beats)

    return max(cards, key=fit)
