import pytest

from homer import formulas
from homer.scanner import TimedWord, beat_lane, scan_verse, strong_hits

BANK = formulas.bank()

# Lesson 1's demo verse (content/lessons.md) and SPEC's example, with their marks.
MARKED = [
    "the WIND was COLD / the WAVES were GREY",
    "we ROWED through the NIGHT / and SANG through the DAY",
    "my HANDS were RAW / my VOICE was STRONG",
    "the SEA kept TIME / and SO did I",
    "WINE-dark SEA / took my BROTH-er's SHIP",
]


def line(text, **kw):
    return scan_verse(text, cards=BANK, **kw).lines[0]


def hit_words(scan_line):
    return [w.text.lower() for w in scan_line.words if w.hit]


@pytest.mark.parametrize("marked", MARKED)
def test_marked_lines_scan_as_marked(marked):
    s = line(marked.lower())
    expected = [w.strip("/").lower() for w in marked.replace("-", " ").split() if w.isupper() and w != "/"]
    assert s.hits == 4
    assert hit_words(s) == [w.split("-")[0] for w in expected]
    assert s.break_source == "mark"
    assert s.score == 1.0


@pytest.mark.parametrize("marked", MARKED)
def test_unmarked_lines_find_four_hits_and_a_break(marked):
    plain = marked.replace(" / ", " ").lower()
    s = line(plain)
    assert s.hits == 4
    assert s.break_source is not None
    assert " / " in s.pattern


def test_compound_from_the_bank_takes_one_hit_without_its_hyphen():
    s = line("the wine dark sea took my brother's ship")
    assert hit_words(s) == ["wine", "sea", "brother's", "ship"]


def test_three_hits_and_a_beat_on_a_small_word():
    s = line("the cat sat on the mat")
    assert s.hits == 3
    assert s.weak_beats
    assert s.score < 1


def test_too_many_hits_counts_extras():
    s = line("cold wind black ships the grey sea dead men")
    assert s.hits >= 5
    assert s.extras


def test_short_line():
    assert line("go home").hits == 2


def test_light_words_take_the_beat_when_the_half_line_needs_them():
    s = line("the sea kept time / and so did i")
    assert hit_words(s) == ["sea", "time", "so", "i"]


def test_formulas_are_found_without_hyphens_or_the():
    s = scan_verse("rose fingered dawn came early to the whale road", cards=BANK)
    assert s.formulas == ["rose-fingered-dawn", "whale-road"]
    ids = [w.formula_id for w in s.lines[0].words]
    assert ids[:3] == ["rose-fingered-dawn"] * 3
    assert ids[-2:] == ["whale-road", "whale-road"]


def test_strong_hits_matches_the_bank_rule():
    assert strong_hits("the wine-dark sea") == 2
    assert strong_hits("storm-throated") == 1
    assert strong_hits("Breaker of Deadlines") == 2
    assert strong_hits("the whale-road") == 1


def test_missing_lines_lower_the_beat_score():
    two = "the wind was cold the waves were grey\nthe sea kept time and so did I"
    assert scan_verse(two, lines_expected=2).beat == 10
    assert scan_verse(two, lines_expected=4).beat < 7


def test_empty_verse():
    s = scan_verse("")
    assert s.lines == [] and s.beat == 1 and s.best_line is None


# ----- Timing ----------------------------------------------------------------

BPM = 80
BEAT = 750.0


def timed(spec):
    """spec: (word, start_ms, end_ms)."""
    return [TimedWord(w, a, b) for w, a, b in spec]


ON_BEAT = timed(
    [
        ("the", -200, -80), ("wind", 0, 300), ("was", 320, 470), ("cold", 750, 1100),
        ("the", 1250, 1350), ("waves", 1500, 1800), ("were", 1820, 1970), ("grey", 2250, 2650),
    ]
)


def test_on_the_drum_with_a_breath():
    s = scan_verse("", words=ON_BEAT, bpm=BPM)
    ln = s.lines[0]
    assert ln.hits == 4 and ln.on_beat == 4 and ln.offset_ms == 0
    assert ln.break_source == "pause" and ln.break_after == 3
    assert s.timed and s.beat == 10


def test_rushing_shows_as_a_negative_offset():
    early = [TimedWord(w.text, w.start - 200, w.end - 200) for w in ON_BEAT]
    ln = scan_verse("", words=early, bpm=BPM).lines[0]
    assert ln.on_beat == 0 and ln.offset_ms == -200
    assert ln.score < 1


def test_no_pause_means_no_break_when_timed():
    rushed_through = timed(
        [("the", -200, -80), ("wind", 0, 300), ("was", 320, 470), ("cold", 490, 800),
         ("the", 820, 900), ("waves", 920, 1200), ("were", 1220, 1300), ("grey", 1320, 1600)]
    )
    ln = scan_verse("the wind was cold the waves were grey", words=rushed_through, bpm=BPM).lines[0]
    assert ln.break_source is None


def test_untimed_transcript_split_into_lines_by_bar():
    line_ms = 2 * 4 * BEAT
    second = [TimedWord(w.text, w.start + line_ms, w.end + line_ms) for w in ON_BEAT]
    s = scan_verse("", words=ON_BEAT + second, bpm=BPM)
    assert len(s.lines) == 2


def test_beat_lane_has_the_contract_shape():
    s = scan_verse("the wind was cold the waves were grey", cards=BANK)
    lane = beat_lane(s, BPM, started_at=1700000000000)
    assert set(lane) == {"bpm", "beatsPerLine", "lines", "startedAt", "words"}
    assert set(lane["words"][0]) == {"text", "t", "stressed", "onBeat", "formulaId"}
    beats = [w["t"] for w in lane["words"] if w["onBeat"]]
    assert beats == [0, 750, 1500, 2250]
