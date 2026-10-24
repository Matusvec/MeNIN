"""The formula bank's contract, so a merge into content/formulas.json can't quietly break dealing.

Extra fields on an entry (e.g. "source", "count" from the Apify miner) are fine:
the service reads only the six below. Run before merging:

    cd homer && .venv/bin/python -m pytest tests/test_content.py -q
"""

import json

import pytest

from homer import formulas
from homer.deal import TAG_WORDS
from homer.emotion import EMOTIONS
from homer.scanner import strong_hits

KINDS = {"epithet", "kenning", "half_line"}  # FormulaCard.Kind in ios/Homer/Contracts.swift (plus "move" for debate)
RAW = json.loads((formulas.CONTENT_DIR / "formulas.json").read_text(encoding="utf-8"))


def test_every_entry_has_the_six_fields():
    for e in RAW:
        assert {"id", "text", "kind", "beats", "themes", "emotions"} <= set(e), e.get("id")


def test_ids_and_phrases_are_unique():
    ids = [e["id"] for e in RAW]
    assert len(ids) == len(set(ids)), "duplicate ids"
    keys = [formulas.key(e["text"]) for e in RAW]
    assert len(keys) == len(set(keys)), "two entries say the same words (ignoring case, hyphens and a leading 'the')"


@pytest.mark.parametrize("e", RAW, ids=[e["id"] for e in RAW])
def test_an_entry_fits_the_game(e):
    assert e["text"].strip() and e["kind"] in KINDS
    assert e["beats"] in (1, 2) and (e["kind"] != "half_line" or e["beats"] == 2)
    assert e["themes"] and set(e["themes"]) <= set(TAG_WORDS), f"unknown theme tag in {e['themes']}"
    assert e["emotions"] and set(e["emotions"]) <= set(EMOTIONS), f"unknown emotion in {e['emotions']}"
    assert strong_hits(e["text"]) == e["beats"], f"the scanner hears {strong_hits(e['text'])} hits in {e['text']!r}"
