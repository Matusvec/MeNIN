"""What code can check about the spoken voice (SPEC "Homer, the character").

Used by the tests, to pin the prompts' example verdicts, and by
scripts/voice_eval.py on live output. Whether a verdict lands like a knockout
is still for a human to hear.
"""

from __future__ import annotations

import re

JARGON = ("iamb", "trochee", "dactyl", "scansion", "meter", "metre", "stanza", "syllable", "foot", "feet",
          "fallacy", "premise", "syllogism", "rhetoric", "straw man", "argument from authority", "tapped")
FEELINGS = re.compile(r"\byou (?:sound|seem|feel|felt|are so)\b|\b(?:sad|sadness|angry|anger|anxious|happy|joyful|"
                      r"emotional|heartbroken|depressed|furious|scared)\b", re.I)
NUMBER = re.compile(r"\b\d+\b|\b(?:out of ten|points?|score[sd]?)\b", re.I)
META = re.compile(r"\b(?:(?:one|two|three|four|five|\d+) (?:lines?|cards?|rescues?|words|seconds|hits)|short turn|rescues?|"
                  r"the clock|your cards?|your hand)\b", re.I)
WORD = re.compile(r"[a-z0-9']+")
VERDICT_WORDS = 16  # judge_poetry.md and judge_debate.md: "At most sixteen words"


# Nothing invented after the Bronze Age in a theme, its call or an epithet (Matus: "Umbrellas did not exist").
MODERN = frozenset("""
    umbrella umbrellas phone phones telephone smartphone text texts texting email emails inbox mail mailbox envelope
    car cars truck trucks taxi bus buses train trains subway metro station platform plane planes airport rocket
    bike bicycle engine engines motor motors gear gears machine machines robot robots computer computers laptop
    keyboard screen screens internet wifi app apps online clock clocks deadline deadlines office offices desk boss
    meeting meetings coffee pizza burger radio television tv camera photo photos photograph movie movies cinema
    electric electricity battery batteries neon streetlight streetlights porch plastic controller controllers
    respawn console headphones guitar piano ticket tickets highway parking elevator
    code compiled server servers alarm alarms rent curfew skyline wire wires steel glass gloves
""".split())


def modern(text: str) -> list[str]:
    """The words in `text` from after Homer's world ("umbrella", "engines"); empty when it's all Bronze Age."""
    return [w for w in re.findall(r"[a-z]+", text.lower()) if w in MODERN]


def words(text: str) -> list[str]:
    return WORD.findall(text.lower().replace("’", "'"))


def quoted_run(said: str, source: str) -> int:
    """The longest run of consecutive words `said` shares with `source`."""
    a, b = words(said), words(source)
    best = 0
    for i in range(len(a)):
        for j in range(len(b)):
            k = 0
            while i + k < len(a) and j + k < len(b) and a[i + k] == b[j + k]:
                k += 1
            best = max(best, k)
    return best


def voice_problems(verdict: str, source: str = "", *, max_words: int = VERDICT_WORDS, must_quote: int = 2) -> list[str]:
    """What breaks the spoken voice rules in one verdict ([] when it's clean).

    With `source` (the verse or argument), the verdict must quote at least
    `must_quote` consecutive words of it.
    """
    w = words(verdict)
    if not w:
        return ["empty"]
    out = []
    if len(w) > max_words:
        out.append(f"{len(w)} words")
    if len(re.findall(r"[.!?](?:\s|$)", verdict.strip() + " ")) > 2:
        out.append("more than two sentences")
    padded = f" {' '.join(w)} "
    out += [f"jargon: {j}" for j in JARGON if f" {j} " in padded]
    for name, rule in (("names a feeling", FEELINGS), ("reads a number", NUMBER), ("talks about the rules", META)):
        if m := rule.search(verdict):
            out.append(f"{name}: {m.group(0)}")
    if source and must_quote and quoted_run(verdict, source) < must_quote:
        out.append("doesn't quote their words")
    if source and quoted_run(verdict, source) >= len(w) - 1:
        out.append("no call: only their words")
    return out
