"""Mining noun-epithet formulas out of a translation's plain text.

Homer's formulas recur: "rosy-fingered Dawn", "the wine-dark sea",
"aegis-bearing Zeus" come back dozens of times, and the translators keep
them. So the miner looks for a few fixed shapes, counts every occurrence
across all sources, and keeps the shapes that recur.

Shapes (each needs a head the lexicon knows: a name or a Homeric noun):

    compound     HYPHENATED-ADJ HEAD      aegis-bearing Zeus, the well-greaved Achaeans
    appositive   NAME ..., the HYPH-ADJ   "early Dawn shone forth, the rosy-fingered"
    simple       ADJ HEAD / TITLE NAME    goodly Odysseus, the barren sea, father Zeus
    agentive     the HYPH-NOUN            the cloud-gatherer
    genitive     TITLE of (the) HEAD      son of Atreus, king of men, the gates of Hades
    half_line    PREP the ADJ HEAD        over the wine-dark sea   (kind "half_line")

Then: names folded to the bank's spelling (Jove -> Zeus, Athene -> Athena),
variants merged, beats counted, tags assigned from the lexicon, bank
duplicates dropped, and the rest ranked by how often and how widely they recur.
"""

from __future__ import annotations

import math
import re
from collections import Counter
from dataclasses import dataclass, field
from typing import Any

from . import beats as beatcount
from . import lexicon as lx
from .bank import Bank, loose_key, slug, validate
from .gutenberg import Book

TOKEN_RE = re.compile(r"[A-Za-z]+(?:[-'][A-Za-z]+)*|--|[.,;:!?()\[\]\"—–]")
COMPOUND_RE = re.compile(r"[a-z]+(?:-[a-z]+){1,2}")
BOUNDARY = lx.SENTENCE_END | {"--", "—", "–"}
TIER_WEIGHT = {1: 1.5, 2: 1.0, 3: 0.6}
# The compound epithet is the Homeric formula par excellence; plain shapes rank lower.
PATTERN_WEIGHT = {"compound": 3.0, "appositive": 3.0, "agentive": 2.0, "genitive": 1.0, "simple": 1.0, "half_line": 0.8}

ADJECTIVAL_TAILS = ("ed", "ing", "en")
ADJECTIVAL_PARTS = frozenset("dark sweet bright like born white red black deep wide".split())


@dataclass
class Settings:
    min_count: int = 2
    max_formulas: int = 150
    max_per_head: int = 4
    max_patronymics: int = 6
    max_half_lines: int = 15
    include_half_lines: bool = True
    modernize_names: bool = True


@dataclass
class Candidate:
    key: tuple[str, ...]
    kind: str
    head: lx.Head
    group: str  # "", "patronymic", "half_line"
    article: str  # "never", "always", "majority"
    modifiers: list[str]
    np_key: tuple[str, ...]  # the noun phrase without a preposition (one half-line per phrase)
    surfaces: Counter = field(default_factory=Counter)
    with_article: int = 0
    per_source: Counter = field(default_factory=Counter)
    patterns: Counter = field(default_factory=Counter)
    generic: bool = True  # every occurrence came from a generic adjective ("the great hall")
    example: str = ""

    @property
    def count(self) -> int:
        return sum(self.surfaces.values())

    def text(self) -> str:
        core = self.surfaces.most_common(1)[0][0]
        if self.article == "always" or (self.article == "majority" and self.with_article * 2 > self.count):
            return "the " + core
        return core

    def score(self) -> float:
        """Recurrence (log count), spread across translations, fame of the head, and shape."""
        spread = 1 + 0.5 * (len(self.per_source) - 1)
        shape = max(PATTERN_WEIGHT.get(p, 1.0) for p in self.patterns)
        if self.patterns.most_common(1)[0][0] == "simple" and self.head.kind == "thing":
            shape = 1.2  # already gated to Homer's fixed adjectives (lexicon.NOUN_ADJ)
        return math.log2(self.count) * spread * TIER_WEIGHT.get(self.head.tier, 1.0) * shape


# ----- Tokens ----------------------------------------------------------------


def clean(text: str) -> str:
    text = text.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"').replace("_", "")
    text = re.sub(r"\[(?:Illustration|Footnote|Note)[^\]]*\]", " ", text, flags=re.S | re.I)
    return text


def tokenize(text: str) -> list[str]:
    return TOKEN_RE.findall(clean(text))


def _starts_sentence(toks: list[str], i: int) -> bool:
    return i == 0 or toks[i - 1] in BOUNDARY or toks[i - 1] == ","


class Miner:
    def __init__(self, settings: Settings) -> None:
        self.s = settings
        self.cands: dict[tuple[str, ...], Candidate] = {}

    # --- lookups ---

    def _name(self, tok: str) -> tuple[lx.Head, str] | None:
        canon = lx.NAME_FORMS.get(tok)
        if canon is None:
            return None
        return lx.NAMES[canon], canon if self.s.modernize_names else tok

    def _head(self, toks: list[str], j: int, lower_names: bool) -> tuple[lx.Head, str] | None:
        """The head at j: a name (capitalized) or a lexicon noun (lowercase)."""
        if j >= len(toks):
            return None
        tok = toks[j]
        if found := self._name(tok):
            return found
        if not tok.islower():
            return None
        if lower_names and tok in lx.LOWER_NAME_FORMS:
            canon = lx.LOWER_NAME_FORMS[tok]
            return lx.NAMES[canon], canon
        word = lx.SPELLING.get(tok, tok)
        if word in lx.NOUNS:
            return lx.NOUNS[word], word
        return None

    def _compound(self, toks: list[str], i: int) -> str | None:
        """The hyphenated epithet at i, normalized ("well-builded" -> "well-built"), or None."""
        if i >= len(toks):
            return None
        tok = toks[i]
        if not tok.islower():
            if not (_starts_sentence(toks, i) and tok[:1].isupper() and tok[1:].islower()):
                return None
            if tok.split("-")[0] in lx.NAME_FORMS:
                return None
            tok = tok.lower()
        if not COMPOUND_RE.fullmatch(tok) or tok in lx.HYPHEN_STOP:
            return None
        parts = tok.split("-")
        if any(len(p) < 2 or p in lx.HYPHEN_STOP_PARTS for p in parts):
            return None
        return "-".join(lx.SPELLING.get(p, p) for p in parts)

    def _simple(self, toks: list[str], i: int) -> str | None:
        tok = toks[i]
        if not tok.islower():
            if not (_starts_sentence(toks, i) and tok[:1].isupper() and tok[1:].islower()):
                return None
            tok = tok.lower()
        return tok if tok in lx.SIMPLE_ADJ or tok in lx.TITLES else None

    def _name_back(self, toks: list[str], i: int, window: int = 6) -> tuple[lx.Head, str] | None:
        """The nearest name before i in the same clause ("Dawn shone forth, the ...")."""
        for j in range(i - 1, max(-1, i - 1 - window), -1):
            if toks[j] in BOUNDARY:
                return None
            if found := self._name(toks[j]):
                return found
        return None

    # --- recording ---

    def _add(
        self,
        *,
        core: str,
        kind: str,
        head: lx.Head,
        modifiers: list[str],
        article: str,
        had_article: bool,
        pattern: str,
        source: str,
        toks: list[str],
        i: int,
        group: str = "",
        generic: bool = False,
        np_core: str | None = None,
    ) -> None:
        key = loose_key(core)
        c = self.cands.get(key)
        if c is None:
            c = Candidate(
                key=key, kind=kind, head=head, group=group, article=article, modifiers=modifiers,
                np_key=loose_key(np_core or core),
            )
            c.example = _snippet(toks, i)
            self.cands[key] = c
        c.surfaces[core] += 1
        c.with_article += int(had_article)
        c.per_source[source] += 1
        c.patterns[pattern] += 1
        c.generic = c.generic and generic

    # --- patterns ---

    def scan(self, book: Book) -> None:
        toks = tokenize(book.text)
        src = book.source
        n = len(toks)
        for i in range(n):
            tok = toks[i]
            prev_the = i > 0 and toks[i - 1].lower() == "the"

            # compound: HYPH HEAD
            mod = self._compound(toks, i)
            if mod:
                h = self._head(toks, i + 1, lower_names=True)
                if h and h[0].key in lx.PLAIN_HEADS and i + 2 < n and toks[i + 2] == "of":
                    pass  # "the swift-footed son of Peleus": the formula is longer than two beats
                elif h:
                    head, word = h
                    self._add(
                        core=f"{mod} {word}", kind="epithet", head=head, modifiers=mod.split("-"),
                        article=_article_policy(head), had_article=prev_the, pattern="compound",
                        source=src, toks=toks, i=i,
                    )
                elif prev_the and (i + 1 >= n or toks[i + 1] in BOUNDARY or toks[i + 1] == ","
                                   or toks[i + 1].lower() in lx.FUNCTION_WORDS):
                    self._substantive(toks, i, mod, src)

            # simple: ADJ HEAD, TITLE NAME, Pallas Athene
            adj = self._simple(toks, i) if tok[:1].isalpha() else None
            if adj and i + 1 < n:
                h = self._head(toks, i + 1, lower_names=False)
                if h:
                    head, word = h
                    is_name = head.kind != "thing"
                    if is_name or (adj in lx.NOUN_ADJ and head.key not in lx.PLAIN_HEADS):
                        self._add(
                            core=f"{adj} {word}", kind="epithet", head=head, modifiers=[adj],
                            article=_article_policy(head), had_article=prev_the, pattern="simple",
                            source=src, toks=toks, i=i, generic=adj in lx.GENERIC_ADJ,
                        )
            if tok in lx.NAME_EPITHETS and i + 1 < n and (h := self._name(toks[i + 1])):
                head, word = h
                pair = lx.NAME_PAIRS.get((tok, head.key))
                if pair:
                    self._add(
                        core=pair if self.s.modernize_names else f"{tok} {word}", kind="epithet", head=head,
                        modifiers=[tok.lower()], article="never", had_article=False, pattern="simple",
                        source=src, toks=toks, i=i,
                    )

            # genitive: TITLE of (the) HEAD
            low = tok.lower() if tok.islower() or _starts_sentence(toks, i) else ""
            if low and (low in lx.GENITIVE_TITLES or low in lx.GENITIVE_THINGS) and i + 2 < n and toks[i + 1] == "of":
                j = i + 2
                the = toks[j] == "the"
                j += int(the)
                h = self._head(toks, j, lower_names=False)
                title = low in lx.GENITIVE_TITLES
                coordinated = j + 2 < n and toks[j + 1] == "and" and self._head(toks, j + 2, False)
                if h and not coordinated and not (title and h[0].key in lx.GENITIVE_X_STOP):
                    head, word = h
                    core = f"{low} of {'the ' if the else ''}{word}"
                    if core in lx.FIXED:
                        core, name = lx.FIXED[core]
                        head = lx.NAMES[name]
                    self._add(
                        core=core, kind="epithet", head=head,
                        modifiers=[low], article="never" if title else "majority", had_article=prev_the,
                        pattern="genitive", source=src, toks=toks, i=i,
                        group="patronymic" if low in lx.PATRONYMIC else "",
                    )

            # half_line: PREP the (HYPH|ADJ) HEAD
            if self.s.include_half_lines and tok in lx.HALF_LINE_PREPS and i + 3 < n and toks[i + 1] == "the":
                mod = self._compound(toks, i + 2) or (
                    toks[i + 2] if toks[i + 2] in lx.SIMPLE_ADJ and toks[i + 2] not in lx.GENERIC_ADJ else None
                )
                h = self._head(toks, i + 3, lower_names=False) if mod else None
                if mod and h and h[0].key in lx.HALF_LINE_HEADS:
                    head, word = h
                    self._add(
                        core=f"{tok} the {mod} {word}", kind="half_line", head=head, modifiers=mod.split("-"),
                        article="never", had_article=False, pattern="half_line", source=src, toks=toks, i=i,
                        group="half_line", np_core=f"{mod} {word}",
                    )

    def _substantive(self, toks: list[str], i: int, mod: str, src: str) -> None:
        """ "the HYPH" with no noun after it: an appositive epithet or an agent noun."""
        parts = mod.split("-")
        last = parts[-1]
        if last.endswith(ADJECTIVAL_TAILS) or last in ADJECTIVAL_PARTS:
            # "early Dawn shone forth, the rosy-fingered": count it for "rosy-fingered Dawn"
            h = self._name_back(toks, i - 1)
            if h:
                head, word = h
                self._add(
                    core=f"{mod} {word}", kind="epithet", head=head, modifiers=parts,
                    article=_article_policy(head), had_article=head.kind == "people", pattern="appositive",
                    source=src, toks=toks, i=i,
                )
        elif last.endswith("er") and len(last) > 3:
            # "Zeus the cloud-gatherer": a one-beat title, like the bank's "the earth-shaker"
            first = parts[0]
            head = lx.NOUNS.get(first) or lx.NOUNS.get(first + "s")
            if head is None and (h := self._name_back(toks, i - 1, window=3)):
                head = h[0]
            if head is not None:
                self._add(
                    core=mod, kind="epithet", head=head, modifiers=parts, article="always",
                    had_article=True, pattern="agentive", source=src, toks=toks, i=i,
                )

    # --- output ---

    def entries(self, bank: Bank) -> tuple[list[dict[str, Any]], dict[str, Any]]:
        """The ranked candidate entries, and a report of what was dropped and why."""
        dropped: dict[str, list[str]] = {}

        def drop(reason: str, what: str) -> None:
            dropped.setdefault(reason, []).append(what)

        ranked: list[tuple[Candidate, dict[str, Any]]] = []
        ids: set[str] = set()
        for c in sorted(self.cands.values(), key=lambda c: -c.count):
            text = c.text()
            need = self.s.min_count * (2 if c.generic else 1)
            if c.count < need:
                drop("rare", text)
                continue
            n_beats = beatcount.count(text)
            if n_beats not in (1, 2) or (c.kind == "half_line" and n_beats != 2):
                drop(f"{n_beats} beats", text)
                continue
            entry_id = slug(text)
            dup = bank.duplicate_of(entry_id, text)
            if dup:
                drop(f"bank duplicate ({dup[0]})", f"{text} = {dup[1]}")
                continue
            if entry_id in ids:
                drop("duplicate id", text)
                continue
            ids.add(entry_id)
            entry = {
                "id": entry_id,
                "text": text,
                "kind": c.kind,
                "beats": n_beats,
                "themes": _themes(c),
                "emotions": _emotions(c),
                "source": "; ".join(s for s, _ in c.per_source.most_common()),
                "count": c.count,
            }
            problems = validate(entry)
            if problems:
                drop("invalid", f"{text}: {', '.join(problems)}")
                continue
            ranked.append((c, entry))

        ranked.sort(key=lambda ce: (-ce[0].score(), -ce[0].count, ce[1]["text"]))

        # Half-lines rank below epithets on recurrence alone, so they get their own
        # share of max_formulas (a fifth at most) and go last, as in content/formulas.json.
        half_lines: list[tuple[Candidate, dict[str, Any]]] = []
        phrases: set[tuple[str, ...]] = set()
        quota = min(self.s.max_half_lines, self.s.max_formulas // 5)
        for c, e in (ce for ce in ranked if ce[0].group == "half_line"):
            if len(half_lines) >= quota or c.np_key in phrases:
                drop("half-line cap", e["text"])
                continue
            half_lines.append((c, e))
            phrases.add(c.np_key)

        epithets: list[tuple[Candidate, dict[str, Any]]] = []
        per_head: Counter = Counter()
        patronymics = 0
        for c, e in (ce for ce in ranked if ce[0].group != "half_line"):
            if len(epithets) >= self.s.max_formulas - len(half_lines):
                drop("over max formulas", e["text"])
            elif per_head[c.head.key] >= self.s.max_per_head:
                drop("per-head cap", e["text"])
            elif c.group == "patronymic" and patronymics >= self.s.max_patronymics:
                drop("patronymic cap", e["text"])
            else:
                epithets.append((c, e))
                per_head[c.head.key] += 1
                patronymics += c.group == "patronymic"

        out = epithets + half_lines
        report = {
            "candidates_seen": len(self.cands),
            "kept": len(out),
            "dropped": {k: {"count": len(v), "examples": v[:15]} for k, v in sorted(dropped.items())},
        }
        self._kept = out
        return [e for _, e in out], report

    def dataset_items(self) -> list[dict[str, Any]]:
        """The kept entries plus review aids for the Apify dataset view."""
        return [
            {**e, "pattern": c.patterns.most_common(1)[0][0], "example": c.example}
            for c, e in getattr(self, "_kept", [])
        ]


# ----- Tags ------------------------------------------------------------------


def _article_policy(head: lx.Head) -> str:
    if head.kind in ("person", "place"):
        return "never"
    return "majority"


def _themes(c: Candidate) -> list[str]:
    themes = list(c.head.themes)
    for m in c.modifiers:
        themes.extend(lx.THEME_CUES.get(m.lower(), ()))
    if c.group == "patronymic" or c.modifiers and c.modifiers[0] in lx.GENITIVE_TITLES:
        title = lx.NOUNS.get(c.modifiers[0])
        if title and len(c.head.themes) < 2:
            themes.extend(title.themes)
    return list(dict.fromkeys(themes))[:3]


def _emotions(c: Candidate) -> list[str]:
    emotions: list[str] = list(lx.EMOTION_CUES.get("-".join(c.modifiers).lower(), ()))
    for m in c.modifiers:
        emotions.extend(lx.EMOTION_CUES.get(m.lower(), ()))
    emotions.extend(c.head.emotions)
    return list(dict.fromkeys(emotions))[:2]


def _snippet(toks: list[str], i: int, before: int = 6, after: int = 8) -> str:
    words = toks[max(0, i - before) : i + after]
    s = " ".join(words)
    s = re.sub(r"\s+([.,;:!?)\]])", r"\1", s)
    s = re.sub(r"([(\[])\s+", r"\1", s)
    return ("… " if i > before else "") + s + " …"
