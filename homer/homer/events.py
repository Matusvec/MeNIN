"""Per-event config: the host, the hand, the rubric, the beat.

SPEC "The games": each event is a config on one engine. Poetry is the only
event so far. TODO(spec): Socratic debate adds a second Event here (host
Socrates, a hand of rhetorical moves, its own five axes, no beat) once the
poetry demo passes the Sat 2 PM checkpoint. The score table in SpacetimeDB
has fixed columns (beat, craft, image, answer, range), so debate's axes will
need a mapping onto them or a contract change.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Axis:
    key: str
    name: str
    measures: str
    source: str  # "scanner", "claude", or "emotion"


@dataclass(frozen=True)
class Event:
    id: str
    host: str
    persona: str  # prompt file in homer/prompts/
    judge_prompt: str  # prompt file in homer/prompts/
    axes: tuple[Axis, ...]
    hand: str  # where hands are dealt from: "formulas" is content/formulas.json
    beat: bool
    beats_per_line: int = 4

    @property
    def claude_axes(self) -> tuple[Axis, ...]:
        return tuple(a for a in self.axes if a.source == "claude")


POETRY = Event(
    id="poetry",
    host="Homer",
    persona="homer",
    judge_prompt="judge_poetry",
    axes=(
        Axis("beat", "Beat", "Did the stresses land on the beat", "scanner"),
        Axis(
            "craft",
            "Craft",
            "Used formulas from the hand, varied them so they fit the line, and coined new ones. "
            "A formula dropped in whole with nothing around it is weak craft; one bent to the theme is strong. "
            "Lines that sound worked out in advance, or copied from a famous song or poem, are weak craft.",
            "claude",
        ),
        Axis(
            "image",
            "Image",
            "Strength of the imagery: concrete, surprising, seen and heard. Abstract words "
            "(love, pain, life) with nothing to see are weak; a single sharp picture is strong.",
            "claude",
        ),
        Axis(
            "answer",
            "Answer",
            "How well the verse responds to the previous verse: takes up its image, turns it, tops it, "
            "or hits back at it. With no previous verse, how well it answers the theme.",
            "claude",
        ),
        Axis("range", "Range", "How much emotional ground the verse covered", "emotion"),
    ),
    hand="formulas",
    beat=True,
)

EVENTS = {POETRY.id: POETRY}


def get(event_id: str) -> Event:
    try:
        return EVENTS[event_id]
    except KeyError:
        raise ValueError(f"unknown event: {event_id}") from None
