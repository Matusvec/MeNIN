"""Per-event config: the host, the hand, the rubric, the beat.

SPEC "The games": each event is a config on one engine. Poetry and Socratic
debate share the turn, the judge and the verdict; this config is where they
differ. SpacetimeDB stores a score as an axes array in rubric order, so the
order of `axes` here is the wire order. Discus has no voice and no Claude, so
it isn't an event here.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Axis:
    key: str
    name: str
    measures: str
    source: str  # "scanner", "claude", or "emotion"
    weight: int = 1  # in the verse total; the module's post_score uses the same (spacetime EVENTS)


@dataclass(frozen=True)
class Event:
    id: str
    host: str
    persona: str  # prompt file in homer/prompts/
    judge_prompt: str  # prompt file in homer/prompts/
    axes: tuple[Axis, ...]
    hand: str  # where hands are dealt from: "formulas" (content/formulas.json) or "moves" (content/moves.json)
    beat: bool
    beats_per_line: int = 4
    hoard: bool = True  # coined cards join the poet's hoard
    tasks: tuple[tuple[str, str], ...] = ()  # the host's other jobs: (task, prompt file in homer/prompts/)

    @property
    def claude_axes(self) -> tuple[Axis, ...]:
        return tuple(a for a in self.axes if a.source == "claude")

    def task(self, name: str) -> str:
        """The prompt file for one of the host's jobs (verdict, song, spar, whispers)."""
        try:
            return dict(self.tasks)[name]
        except KeyError:
            raise ValueError(f"{self.id} has no {name}") from None


POETRY = Event(
    id="poetry",
    host="Homer",
    persona="homer",
    judge_prompt="judge_poetry",
    axes=(
        Axis("beat", "Flow", "A steady rhythm, about three to five stresses a line", "scanner"),
        Axis(
            "craft",
            "Craft",
            "Used formulas from the hand, varied them so they fit the line, and coined new ones. "
            "A formula dropped in whole with nothing around it is weak craft; one bent to the theme is strong. "
            "Lines that sound worked out in advance, or copied from a famous song or poem, are weak craft.",
            "claude",
            2,
        ),
        Axis(
            "image",
            "Image",
            "Strength of the imagery: concrete, surprising, seen and heard. Abstract words "
            "(love, pain, life) with nothing to see are weak; a single sharp picture is strong.",
            "claude",
            3,
        ),
        Axis(
            "answer",
            "Answer",
            "How well the verse responds to the previous verse: takes up its image, turns it, tops it, "
            "or hits back at it. With no previous verse, how well it answers the theme.",
            "claude",
            3,
        ),
        Axis("range", "Range", "How much emotional ground the verse covered", "emotion"),
    ),
    hand="formulas",
    beat=True,
    tasks=(
        ("poet", "poet"),
        ("theme", "theme"),
        ("verdict", "verdict"),
        ("song", "song"),
        ("spar", "spar"),
        ("lesson_answer", "lesson_answer"),
        ("lesson_boast", "lesson_boast"),
    ),
)

# content/debate.md, "The rubric". Poise is measured from the delivery, never scored by Claude.
DEBATE = Event(
    id="debate",
    host="Socrates",
    persona="socrates",
    judge_prompt="judge_debate",
    axes=(
        Axis("claim", "Claim", "They took their side, said it plainly, and held it to the end.", "claude"),
        Axis("reason", "Reason", "Their reasons and examples actually support their claim.", "claude"),
        Axis(
            "answer",
            "Answer",
            "They took on the last speaker's strongest point, not their weakest. "
            "If they went first, they took on the question itself.",
            "claude",
        ),
        Axis(
            "craft",
            "Craft",
            "They made the moves in their hand, at the right moment, and varied them. Doing a move counts; "
            "naming it doesn't. A move they tapped but didn't make earns nothing.",
            "claude",
        ),
        Axis("poise", "Poise", "They kept the floor: steady pace, few fillers, no dead air.", "delivery"),
    ),
    hand="moves",
    beat=False,
    beats_per_line=0,
    hoard=False,
    tasks=(
        ("poet", "poet"),
        ("verdict", "verdict_debate"),
        ("song", "last_question"),
        ("spar", "spar_debate"),
        ("whispers", "whispers"),
    ),
)

EVENTS = {POETRY.id: POETRY, DEBATE.id: DEBATE}


def get(event_id: str) -> Event:
    try:
        return EVENTS[event_id]
    except KeyError:
        raise ValueError(f"unknown event: {event_id}") from None
