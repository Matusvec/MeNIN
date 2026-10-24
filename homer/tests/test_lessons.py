import asyncio

import pytest

from homer.lessons import Attempt, DETECTORS, common, demo_lane, demo_words, feedback, lessons, spoken_demo

# The rows each detector list was written against, in order. If content/lessons.md
# reorders or renames a row, this fails before Homer says the wrong line.
ROWS = {
    "beat": ["Three hits or fewer", "Five hits or more", "No break", "A hit on a small word", "Ahead of the drum"],
    "formula": ["Froze, and didn't use the whispered card", "No card from the hand", "Changed the card's words",
                "The card alone, nothing of their own", "Their own half is off"],
    "epithet": ["Three or more hits in the title", "One hit in the title", "Generic, judged weak",
                "Title not used in the line", "The line around it is off"],
}


def test_the_six_lessons_parse():
    ls = lessons()
    assert [l.id for l in ls.values()] == ["beat", "formula", "epithet", "turn", "answer", "boast"]
    for l in ls.values():
        assert l.move and l.success and len(l.demo) == 4 and len(l.misses) == 5
        assert all(sum(hit for _, hit in line) == 4 for line in demo_words(l))
    assert common()["No speech heard"] == "I heard nothing. Again, and louder."


@pytest.mark.parametrize("lesson", ROWS)
def test_detectors_line_up_with_the_tables(lesson):
    assert [m for m, _ in lessons()[lesson].misses] == ROWS[lesson]
    assert len(DETECTORS[lesson]) == len(ROWS[lesson])


def test_demo_is_speakable_and_on_the_beat():
    l = lessons()["beat"]
    assert spoken_demo(l).splitlines()[0] == "the wind was cold the waves were grey"
    lane = demo_lane(l, 80)
    hits = [w["t"] for w in lane["words"] if w["stressed"]][:4]
    assert hits == [0, 750, 1500, 2250] and lane["lines"] == 4


def say(lesson, transcript, craft=8, **kw):
    async def judge(_):
        return craft

    return asyncio.run(feedback(Attempt(lesson, transcript, **kw), judge))


@pytest.mark.parametrize(
    "transcript, miss, line",
    [
        ("the road was long, the night was cold\nI walked alone, I walked in the rain", None, "Four and four. That's the beat. It's yours now."),
        ("the cat sat on the mat\nthe road was long, the night was cold", "Three hits or fewer", "Three hits. I need four. Add a word with weight."),
        ("big black dogs ran fast through cold dark woods\nthe road was long, the night was cold", "Five hits or more", "Six hits. Too many. Cut a word."),
        ("", "No speech heard", "I heard nothing. Again, and louder."),
    ],
)
def test_lesson_one(transcript, miss, line):
    f = say("beat", transcript)
    assert (f.miss, f.line) == (miss, line) and f.landed == (miss is None)


@pytest.mark.parametrize(
    "transcript, kw, miss",
    [
        ("I burn alone tonight on the whale road", {}, None),
        ("the whale road", {}, "The card alone, nothing of their own"),
        ("I sailed the wine sea till dawn", {}, "Changed the card's words"),
        ("I burn alone tonight with no one left", {}, "No card from the hand"),
        ("I burn alone tonight", {"rescue": "the whale-road"}, "Froze, and didn't use the whispered card"),
        ("my ship on the whale road", {}, "Their own half is off"),
    ],
)
def test_lesson_two(transcript, kw, miss):
    f = say("formula", transcript, hand=["the whale-road", "the wine-dark sea"], **kw)
    assert f.miss == miss


def test_lesson_two_fills_the_whispered_card():
    f = say("formula", "I burn alone tonight", hand=["the whale-road"], rescue="the whale-road")
    assert f.line == "I handed you the whale-road. Say it. Half your line is done."


@pytest.mark.parametrize(
    "transcript, craft, miss",
    [
        ("Matus, Breaker of Deadlines\nhere comes Matus, breaker of deadlines, home", 8, None),
        ("Matus, Breaker\nI walk the long road home tonight", 8, "One hit in the title"),
        ("Matus, Breaker of the Old Gods' Iron Chains\nthe road", 8, "Three or more hits in the title"),
        ("Matus, Breaker of Deadlines\nhere comes Matus, breaker of deadlines, home", 4, "Generic, judged weak"),
        ("Matus, Breaker of Deadlines\nI walk the long road home tonight", 8, "Title not used in the line"),
        ("Matus, Breaker of Deadlines\nbreaker of deadlines", 8, "The line around it is off"),
    ],
)
def test_lesson_three(transcript, craft, miss):
    f = say("epithet", transcript, craft=craft, name="Matus")
    assert f.miss == miss
    if miss is None:
        assert f.title == "Breaker of Deadlines" and f.line.startswith("Breaker of Deadlines. Good.")


def test_later_lessons_are_not_built_yet():
    with pytest.raises(NotImplementedError):
        say("turn", "we broke their gates")
