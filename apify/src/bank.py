"""The existing bank (content/formulas.json): loading it, deduping against it, and the entry schema.

An entry keeps exactly the bank's fields (content/README.md) plus two the
miner adds for review: `source` (book and translator) and `count`
(occurrences across the sources). The agent service's loader reads only the
bank fields, so the two extras are harmless if an entry is merged as is.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from . import lexicon

BANK_FIELDS = ("id", "text", "kind", "beats", "themes", "emotions")
ENTRY_FIELDS = (*BANK_FIELDS, "source", "count")
KINDS = ("epithet", "kenning", "half_line")

_TOKEN_RE = re.compile(r"[a-z]+(?:'[a-z]+)*")
_SLUG_RE = re.compile(r"[^a-z0-9]+")


def slug(text: str) -> str:
    """The bank's id rule: lowercase, hyphens, no leading "the" ("the gannet's bath" -> "gannet-s-bath")."""
    s = text.lower().replace("’", "'")
    if s.startswith("the "):
        s = s[4:]
    return _SLUG_RE.sub("-", s).strip("-")


def strict_key(text: str) -> tuple[str, ...]:
    """homer/homer/formulas.py's match key: words only, a leading "the" dropped."""
    words = _TOKEN_RE.findall(text.lower().replace("’", "'").replace("-", " "))
    if len(words) > 1 and words[0] == "the":
        words = words[1:]
    return tuple(words)


def _stem(w: str) -> str:
    w = lexicon.WORD_SYNONYMS.get(w, w)
    if w.endswith("'s"):
        w = w[:-2]
    if len(w) > 4 and w.endswith("ies"):
        w = w[:-3] + "y"
    elif len(w) > 3 and w.endswith("s") and not w.endswith("ss"):
        w = w[:-1]
    return w


def loose_key(text: str) -> tuple[str, ...]:
    """A key that also folds spelling, names, plurals and synonym compounds.

    "fleet-footed Achilleus", "swift-footed Achilles" and "the swift-footed
    Achilles" share one key, so a variant of a bank formula counts as a duplicate.
    """
    out: list[str] = []
    for raw in text.replace("’", "'").split():
        word = raw.strip(",.;:!?\"()")
        name = lexicon.NAME_FORMS.get(word)
        word = (name or word).lower()
        word = lexicon.SPELLING.get(word, word)
        word = lexicon.COMPOUND_SYNONYMS.get(word, word)
        out.extend(_stem(p) for p in word.split("-") if p)
    if len(out) > 1 and out[0] == "the":
        out = out[1:]
    return tuple(out)


class Bank:
    """The formulas already in content/formulas.json, indexed for dedupe."""

    def __init__(self, entries: list[dict[str, Any]], origin: str) -> None:
        self.entries = entries
        self.origin = origin
        self.ids = {e["id"] for e in entries if "id" in e}
        self.texts = {e["text"].lower() for e in entries if "text" in e}
        self.strict = {strict_key(e["text"]): e["id"] for e in entries if "text" in e}
        self.loose = {loose_key(e["text"]): e["id"] for e in entries if "text" in e}

    def duplicate_of(self, entry_id: str, text: str) -> tuple[str, str] | None:
        """(reason, bank id) if the bank already has this formula, else None."""
        if entry_id in self.ids:
            return "same id", entry_id
        if text.lower() in self.texts or strict_key(text) in self.strict:
            return "same text", self.strict.get(strict_key(text), entry_id)
        hit = self.loose.get(loose_key(text))
        if hit:
            return "variant", hit
        return None

    @classmethod
    def empty(cls) -> "Bank":
        return cls([], "none")

    @classmethod
    def from_path(cls, path: Path) -> "Bank":
        return cls(_entries(json.loads(path.read_text(encoding="utf-8"))), str(path))

    @classmethod
    def from_json(cls, data: Any, origin: str) -> "Bank":
        return cls(_entries(data), origin)


def _entries(data: Any) -> list[dict[str, Any]]:
    if not isinstance(data, list):
        raise ValueError("the bank must be a JSON array of formula entries")
    return [e for e in data if isinstance(e, dict) and isinstance(e.get("text"), str)]


def validate(entry: dict[str, Any]) -> list[str]:
    """Problems with an entry against content/README.md's schema (empty if none)."""
    problems = []
    if tuple(entry) != ENTRY_FIELDS:
        problems.append(f"fields are {list(entry)}, want {list(ENTRY_FIELDS)}")
    if entry.get("id") != slug(entry.get("text", "")):
        problems.append("id is not the slug of text")
    if entry.get("kind") not in KINDS:
        problems.append(f"kind {entry.get('kind')!r}")
    if entry.get("beats") not in (1, 2):
        problems.append(f"beats {entry.get('beats')!r}")
    if entry.get("kind") == "half_line" and entry.get("beats") != 2:
        problems.append("a half_line must be 2 beats")
    themes, emotions = entry.get("themes") or [], entry.get("emotions") or []
    if not themes or any(t not in lexicon.THEMES for t in themes):
        problems.append(f"themes {themes}")
    if not emotions or any(e not in lexicon.EMOTIONS for e in emotions):
        problems.append(f"emotions {emotions}")
    if not isinstance(entry.get("count"), int) or entry["count"] < 1:
        problems.append("count")
    if not str(entry.get("source", "")).strip():
        problems.append("source")
    return problems
