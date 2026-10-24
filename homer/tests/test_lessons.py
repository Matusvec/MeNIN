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
    "turn": ["No turn", "Turned at line 1 or 2", "Turned at line 4", "Said the feeling instead of showing it",
             "The turn cost a hit"],
    "answer": ["Ignored the line", "Agreed with it", "Denied it", "Only one line", "Good answer, but a hit short",
               "Answer below 7"],
    "boast": ["Ended on a weak word", "Kept going after the hit", "Hedged", "Didn't close the setup", "A hit short",
              "Image below 7"],
}


def test_the_six_lessons_parse():
    ls = lessons()
    assert [l.id for l in ls.values()] == ["beat", "formula", "epithet", "turn", "answer", "boast"]
    for l in ls.values():
        assert l.move and l.success and len(l.demo) == 4 and len(l.misses) == len(ROWS[l.id])
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


def test_a_short_try_is_told_how_many_lines():
    f = say("beat", "the road was long, the night was cold")
    assert (f.landed, f.miss) == (False, "Fewer lines than the exercise asks for")
    assert f.line == "You stopped short. I asked for two lines. Finish it."


# ----- Lessons 4 to 6 ---------------------------------------------------------


class FakeChecks:
    """Stands in for the classifier and Homer's readings."""

    def __init__(self, leads=None, answer=None, boast=None):
        self.leads, self._answer, self._boast = leads or [], answer, boast
        self.seen = []

    async def craft(self, a):
        return 8

    async def emotions(self, lines):
        return [{e: 0.9} if e else None for e in self.leads[: len(lines)]]

    async def answer(self, thrown, lines):
        self.seen.append(thrown)
        return self._answer

    async def boast(self, setup, closing):
        self.seen.append(setup)
        return self._boast


def check(lesson, transcript, **kw):
    checks = FakeChecks(**{k: kw.pop(k) for k in ("leads", "answer", "boast") if k in kw})
    return asyncio.run(feedback(Attempt(lesson, transcript, **kw), checks=checks)), checks


TURN_VERSE = ("we broke their gates, we burned their towers\nwe drank their wine till the dawn came up\n"
              "then I saw my brother lying in the sand\nand the wine turned to ash in the back of my throat")


@pytest.mark.parametrize(
    "leads, verse, miss",
    [
        (["joy", "joy", "grief", "grief"], TURN_VERSE, None),
        (["joy", "joy", "joy", "joy"], TURN_VERSE, "No turn"),
        (["joy", "grief", "grief", "grief"], TURN_VERSE, "Turned at line 1 or 2"),
        (["joy", "joy", "joy", "grief"], TURN_VERSE, "Turned at line 4"),
        (["joy", "joy", "grief", "grief"], TURN_VERSE.replace("then I saw my brother", "then I felt so sad, my brother"),
         "Said the feeling instead of showing it"),
        (["joy", "joy", "grief", "grief"], TURN_VERSE.replace("then I saw my brother lying in the sand", "then I saw him"),
         "The turn cost a hit"),
    ],
)
def test_lesson_four_the_turn(leads, verse, miss):
    f, _ = check("turn", verse, leads=leads)
    assert f.miss == miss and f.landed == (miss is None)
    if miss is None:
        assert f.line == "You moved the room. That's the turn."


def test_lesson_four_needs_all_four_lines():
    f, _ = check("turn", "we broke their gates\nwe drank their wine", leads=["joy", "grief"])
    assert f.miss == "Fewer lines than the exercise asks for" and "four lines" in f.line


THROWN = "you SPEAK like a SPARrow / LOST in a STORM"
ANSWERED = "a sparrow in a storm still flies to the shore\nwhile your thunder dies in the clouds that you bore"


@pytest.mark.parametrize(
    "answer, verse, miss",
    [
        ({"stance": "turned", "answer": 8}, ANSWERED, None),
        ({"stance": "ignored", "answer": 3}, ANSWERED, "Ignored the line"),
        ({"stance": "agreed", "answer": 4}, ANSWERED, "Agreed with it"),
        ({"stance": "denied", "answer": 4}, ANSWERED, "Denied it"),
        ({"stance": "turned", "answer": 8}, ANSWERED.split("\n")[0], "Only one line"),
        ({"stance": "turned", "answer": 8}, ANSWERED.split("\n")[0] + "\nyou lose", "Good answer, but a hit short"),
        ({"stance": "turned", "answer": 5}, ANSWERED, "Answer below 7"),
        (None, ANSWERED, "Homer is silent"),
    ],
)
def test_lesson_five_the_answer(answer, verse, miss):
    f, checks = check("answer", verse, answer=answer, prompt=THROWN)
    assert f.miss == miss and f.landed == (miss is None)
    assert checks.seen == ["you speak like a sparrow lost in a storm"]  # notation stripped for Homer's reading
    if miss == "Homer is silent":
        assert f.line == ""
    if miss == "Answer below 7":
        assert f.line == "Clean lines, but it barely stung. Take my sharpest word and turn it on me."


CLOSING = "and I walk through the gate as the hall goes still"


@pytest.mark.parametrize(
    "boast, verse, miss, fill",
    [
        ({"closes_setup": True, "image": 8}, CLOSING, None, None),
        ({"closes_setup": True, "image": 8}, "and I walk through the gate of the hall like a", "Ended on a weak word", "a"),
        ({"closes_setup": True, "image": 8}, CLOSING + "\nand then I sit down", "Kept going after the hit", None),
        ({"closes_setup": True, "image": 8}, "and maybe I walk through the gate as the hall goes still", "Hedged", None),
        ({"closes_setup": False, "image": 8}, CLOSING, "Didn't close the setup", None),
        ({"closes_setup": True, "image": 8}, "I won the hall", "A hit short", None),
        ({"closes_setup": True, "image": 5}, CLOSING, "Image below 7", None),
    ],
)
def test_lesson_six_the_boast(boast, verse, miss, fill):
    f, checks = check("boast", verse, boast=boast)
    assert f.miss == miss and f.landed == (miss is None)
    assert checks.seen[0][2] == "and now you stand at the gate of the hall"  # Homer's setup, from lessons.md
    if fill:
        assert f.line == f"You ended on {fill}. End on the word that hits hardest."
    if miss == "Image below 7":
        assert f.line == "Clean, but I can't see it. Put one thing in that line I could paint."


# ----- P10: help after misses, and onsets ----------------------------------------


def test_help_after_the_third_and_fifth_misses():
    miss = "the cat sat on the mat\nthe road was long, the night was cold"
    assert say("beat", miss, try_no=2).help is None
    third = say("beat", miss, try_no=3)
    assert not third.landed and third.help["kind"] == "half"
    assert third.help["half"] == "the WIND was COLD /"
    assert third.help["say"] == common()["Help after three misses"].replace("{half}", "the wind was cold")
    assert say("beat", miss, try_no=4).help is None
    fifth = say("beat", miss, try_no=5)
    assert fifth.landed and fifth.help["kind"] == "walkthrough" and fifth.help["line"] == "the WIND was COLD / the WAVES were GREY"
    assert fifth.help["say"] == common()["Walkthrough after five misses"].replace("{line}", "the wind was cold the waves were grey")
    assert fifth.line == third.line  # Homer still names the miss; the walkthrough follows it


def test_help_line_shows_each_lessons_move():
    from homer.lessons import help_for

    assert help_for(lessons()["turn"], 5)["line"].startswith("then I SAW my BROTHer")
    assert help_for(lessons()["boast"], 5)["line"] == "the KINGS are DUST / and I'm STILL HERE"
    assert help_for(lessons()["answer"], 3)["half"] == "but a CANdle in the RAIN /"


def test_a_landed_try_needs_no_help():
    f = say("beat", "the road was long, the night was cold\nI walked alone, I walked in the rain", try_no=5)
    assert f.landed and f.help is None


def test_onsets_hear_rushing_without_word_timings():
    lines = "the road was long, the night was cold\nI walked alone, I walked in the rain"
    early = [k * 750 - 150 for k in range(8)]
    on = [k * 750 + 10 for k in range(8)]
    assert say("beat", lines, bpm=80, onsets_ms=early).miss == "Ahead of the drum"
    assert say("beat", lines, bpm=80, onsets_ms=on).landed
