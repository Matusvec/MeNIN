import json
from pathlib import Path

import pytest

from homer.scansion import (
    MAX_LINES,
    STRESSED,
    UNSTRESSED,
    format_scansion,
    heuristic_syllables,
    lookup,
    scan_line,
    scan_poem,
)

FIXTURES = json.loads((Path(__file__).parent / "fixtures" / "lines.json").read_text())


@pytest.mark.parametrize("case", FIXTURES["clean"], ids=lambda c: c["text"][:30])
def test_clean_pentameter_counts_ten_and_fits(case):
    scan = scan_line(case["text"])
    assert scan.syllable_count == case["syllables"]
    assert scan.conflicts == []
    assert scan.suggested.count("|") == 4
    assert not any("syllables: pentameter wants" in h for h in scan.hints)


@pytest.mark.parametrize("case", FIXTURES["variations"], ids=lambda c: c["text"][:30])
def test_variations_are_detected(case):
    scan = scan_line(case["text"])
    assert scan.syllable_count == case["syllables"]
    if "expect_hint" in case:
        assert any(case["expect_hint"] in h for h in scan.hints), scan.hints
    if "caesurae" in case:
        assert scan.caesurae == case["caesurae"]
    if "expect_elided_syllables" in case:
        assert scan.elided_fit is not None
        assert scan.elided_fit["syllable_count"] == case["expect_elided_syllables"]
        assert scan.elided_fit["conflicts"] == []


@pytest.mark.parametrize("case", FIXTURES["broken"], ids=lambda c: c["text"][:30])
def test_broken_lines_are_flagged(case):
    scan = scan_line(case["text"])
    assert scan.syllable_count == case["syllables"]
    flagged = scan.conflicts or any("pentameter wants" in h for h in scan.hints)
    assert flagged, scan.hints


def test_inversion_reports_fixed_stress_from_dictionary():
    scan = scan_line("Never came poison from so sweet a place.")
    assert scan.lexical.split()[:2] == [STRESSED, UNSTRESSED]
    assert scan.suggested.startswith("/ ˇ |")
    assert scan.da_dum.startswith("DUM da")


def test_monosyllables_are_never_fixed():
    # "Shall I" could be read either way; the tool must not decide.
    scan = scan_line("Shall I compare thee to a summer's day?")
    shall, i = scan.words[0], scan.words[1]
    assert shall.monosyllable and i.monosyllable
    assert scan.conflicts == []


def test_word_lookup_cmu():
    w = lookup("compare")
    assert w.in_dictionary and w.source == "cmu"
    assert w.stress_options == ["01"]
    assert w.syllable_options == [2]
    assert not w.monosyllable


def test_multiple_pronunciations_are_all_returned():
    w = lookup("every")
    assert set(w.stress_options) == {"100", "10"}
    assert w.syllable_options == [2, 3]


def test_elidable_word_offers_shorter_count():
    w = lookup("heaven")
    assert w.syllable_options == [1, 2]
    assert any("elided" in n for n in w.notes)


def test_unknown_word_flagged_with_heuristic():
    w = lookup("Zorblax")
    assert not w.in_dictionary
    assert w.source == "heuristic"
    assert w.stress_options == ["??"]
    scan = scan_line("The Zorblax glimmered over Qwertyville")
    assert {"Zorblax", "Qwertyville"} <= set(scan.unknown_words)


def test_archaic_forms():
    assert lookup("o'er").syllable_options == [1]
    assert lookup("’tis").syllable_options == [1]


def test_possessive_and_curly_apostrophe():
    assert lookup("summer’s").in_dictionary


def test_capitalised_mid_line_word_leans_stressed():
    scan = scan_line("Rough winds do shake the darling buds of May,")
    assert scan.lexical.split()[-1] == STRESSED


@pytest.mark.parametrize("word,count", [("cat", 1), ("garden", 2), ("blissfulness", 3), ("shine", 1), ("glimmered", 3)])
def test_heuristic_syllables(word, count):
    assert heuristic_syllables(word) == count


def test_empty_and_whitespace():
    assert scan_line("").syllable_count == 0
    assert scan_line("").hints == ["empty line"]
    poem = scan_poem("   \n  \n")
    assert poem["line_count"] == 0 and poem["lines"] == []


def test_prose_is_scanned_without_error():
    text = next(c["text"] for c in FIXTURES["edge"] if c["name"] == "prose")
    scan = scan_line(text)
    assert scan.syllable_count > 20
    assert any("pentameter wants 10" in h for h in scan.hints)


def test_injection_text_is_just_words():
    text = next(c["text"] for c in FIXTURES["edge"] if c["name"] == "injection_tags")
    scan = scan_line(text)
    assert all("<" not in w.text and ">" not in w.text for w in scan.words)


def test_poem_enjambment_and_rhyme():
    poem = scan_poem(
        "Shall I compare thee to a summer's day?\n"
        "Thou art more lovely and more temperate:\n"
        "Rough winds do shake the darling buds of May,\n"
        "And summer's lease hath all too short a date"
    )
    assert poem["line_count"] == 4
    assert poem["enjambed_after_lines"] == []
    assert [1, 3] in poem["rhyming_line_pairs"]


def test_enjambment_detected():
    poem = scan_poem("Of Man's first disobedience, and the fruit\nOf that forbidden tree whose mortal taste")
    assert poem["enjambed_after_lines"] == [1]


def test_poem_line_cap():
    poem = scan_poem("\n".join(["The sea is calm tonight"] * (MAX_LINES + 5)))
    assert poem["line_count"] == MAX_LINES
    assert poem["truncated"] is True


def test_to_dict_is_json_serialisable():
    json.dumps(scan_poem("To be, or not to be: that is the question:"))


def test_format_scansion():
    out = format_scansion(scan_line("When I do count the clock that tells the time,"))
    assert "ˇ / | ˇ / | ˇ / | ˇ / | ˇ /" in out
    assert "(10 syllables)" in out


def test_function_words_prefer_short_reading():
    assert lookup("our").default_stress == "1"
    assert scan_line("We set our sails beneath a silver moon,").syllable_count == 10


def test_eleven_syllables_ending_on_stress_offers_elision():
    scan = scan_line("And every star above the water grew.")
    assert scan.syllable_count == 11
    assert scan.elided_fit["syllable_count"] == 10
    assert scan.elided_fit["conflicts"] == []
