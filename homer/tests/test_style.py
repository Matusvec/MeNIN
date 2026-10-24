"""The spoken voice, pinned: the checks themselves, and the prompts' own examples and rules.

A prompt edit that drops the quote-first rule, or adds an example that breaks
the voice (three sentences, jargon, a named feeling, a read-out score), fails here.
"""

import pytest

from homer.prompts import PROMPT_DIR
from homer.style import quoted_run, voice_problems


def examples(name: str) -> list[str]:
    text = (PROMPT_DIR / f"{name}.md").read_text(encoding="utf-8").split("## The sound of a good verdict")[1]
    return [line[2:] for line in text.splitlines() if line.startswith("- ")]


def test_the_checks():
    verse = "the hollow ships came back with no one aboard\nmy mother still sets a plate by the door"
    assert voice_problems("A plate by the door. That's the whole war in one picture.", verse) == []
    assert "doesn't quote their words" in voice_problems("Strong bones, thin blood. Heavy.", verse)
    assert any(p.startswith("talks about the rules") for p in voice_problems("Two lines, but the plate by the door hit.", verse))
    assert any(p.startswith("names a feeling") for p in voice_problems("You sound so sad. A plate by the door."))
    assert any(p.startswith("jargon") for p in voice_problems("Your meter slipped on the plate by the door."))
    assert any(p.startswith("reads a number") for p in voice_problems("Ten out of ten for the plate by the door."))
    assert "more than two sentences" in voice_problems("A plate. By the door. Knockout.")
    assert quoted_run("my mother still sets it", verse) == 4
    assert "no call: only their words" in voice_problems("My mother still sets a plate.", verse)
    assert any(p.startswith("talks about the rules") for p in voice_problems("The light box. Two cards on the table, now light a fire."))


@pytest.mark.parametrize("prompt", ["judge_poetry", "judge_debate"])
def test_every_example_verdict_has_the_voice(prompt):
    found = examples(prompt)
    assert len(found) >= 6
    for example in found:
        assert voice_problems(example) == [], example


@pytest.mark.parametrize("prompt", ["judge_poetry", "judge_debate"])
def test_the_verdict_quotes_first_and_never_talks_rules(prompt):
    text = (PROMPT_DIR / f"{prompt}.md").read_text(encoding="utf-8")
    assert "- `quote`: their own words, which you say first" in text and "copied exactly from the strongest" in text
    assert "their words first, then your call" in text and "At most sixteen words with the quote, at most two sentences" in text
    assert "The call is one sentence of your own words, at most ten, and never repeats the quote" in text
    assert "Every verdict has both" in text and "Never count anything aloud" in text


def test_a_miss_is_half_a_line_never_the_verdict():
    text = (PROMPT_DIR / "judge_poetry.md").read_text(encoding="utf-8")
    assert "at most half a line of gentle roast. The miss is never the whole verdict." in text
