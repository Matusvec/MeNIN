"""The formula bank (content/formulas.json) and spotting formulas in a verse.

A formula is matched on its words alone: case, hyphens, punctuation and a
leading "the" are ignored, so "the wine-dark sea" matches a transcript's
"wine dark sea".
"""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from functools import cache
from pathlib import Path

CONTENT_DIR = Path(os.environ.get("HOMER_CONTENT_DIR", Path(__file__).resolve().parents[2] / "content"))

TOKEN_RE = re.compile(r"[a-z]+(?:'[a-z]+)*")


@dataclass(frozen=True)
class Formula:
    id: str
    text: str
    kind: str = "epithet"
    beats: int = 2
    themes: tuple[str, ...] = ()
    emotions: tuple[str, ...] = ()


@dataclass(frozen=True)
class Match:
    line: int  # 0-based line of the verse
    start: int  # first token, 0-based within the line
    end: int  # one past the last token
    formula: Formula


def tokens(text: str) -> list[str]:
    """Lowercase words, hyphenated compounds split, curly apostrophes folded."""
    return TOKEN_RE.findall(text.lower().replace("’", "'").replace("-", " "))


def key(text: str) -> tuple[str, ...]:
    words = tokens(text)
    if len(words) > 1 and words[0] == "the":
        words = words[1:]
    return tuple(words)


def slug(text: str) -> str:
    return "-".join(key(text))


@cache
def bank() -> tuple[Formula, ...]:
    raw = json.loads((CONTENT_DIR / "formulas.json").read_text(encoding="utf-8"))
    return tuple(
        Formula(
            id=e["id"],
            text=e["text"],
            kind=e.get("kind", "epithet"),
            beats=int(e.get("beats", 2)),
            themes=tuple(e.get("themes", ())),
            emotions=tuple(e.get("emotions", ())),
        )
        for e in raw
    )


@cache
def _by_key() -> dict[tuple[str, ...], Formula]:
    return {key(f.text): f for f in bank()}


def card(text: str) -> Formula:
    """The bank entry for a card's text, or an ad-hoc one (a coined hoard card)."""
    return _by_key().get(key(text)) or Formula(id=slug(text), text=text.strip())


@cache
def compounds() -> frozenset[tuple[str, ...]]:
    """Hyphenated compounds in the bank ("wine-dark" -> ("wine", "dark")).

    Speech-to-text drops the hyphen, so the scanner uses these to give a
    compound one hit, on its first part.
    """
    out = set()
    for f in bank():
        for part in f.text.lower().split():
            if "-" in part:
                words = tuple(tokens(part))
                if len(words) > 1:
                    out.add(words)
    return frozenset(out)


def find(lines: list[list[str]], cards: list[Formula]) -> list[Match]:
    """Every place a card's words appear, longest card first, no overlaps."""
    keyed = sorted(((key(c.text), c) for c in cards), key=lambda kc: -len(kc[0]))
    taken: set[tuple[int, int]] = set()
    found: list[Match] = []
    for n, words in enumerate(lines):
        for k, c in keyed:
            if not k:
                continue
            for i in range(len(words) - len(k) + 1):
                span = {(n, j) for j in range(i, i + len(k))}
                if tuple(words[i : i + len(k)]) == k and not span & taken:
                    taken |= span
                    found.append(Match(n, i, i + len(k), c))
    found.sort(key=lambda m: (m.line, m.start))
    return found
