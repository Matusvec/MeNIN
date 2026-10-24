"""App-owned session state. The mode lives here and is set only by the app."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class Mode(str, Enum):
    BARD = "bard"
    JUDGE = "judge"
    BATTLE = "battle"


# (step id, title). Order is the teaching order.
CURRICULUM: list[tuple[str, str]] = [
    ("syllables_stress", "Syllables and stress"),
    ("iamb", "The iamb (da-DUM)"),
    ("feet", "Feet"),
    ("pentameter", "Counting to five: the pentameter line"),
    ("notation", "Scansion notation"),
    ("trochaic_inversion", "Trochaic inversion, especially in the first foot"),
    ("feminine_ending", "Feminine endings"),
    ("spondee_pyrrhic", "Spondees and pyrrhics"),
    ("caesura", "Caesura"),
    ("enjambment", "Enjambment"),
    ("elision", "Elision"),
    ("blank_vs_rhymed", "Blank verse vs. rhymed verse (heroic couplets, sonnets)"),
]
STEP_IDS = [step_id for step_id, _ in CURRICULUM]
STEP_STATUSES = ("introduced", "practicing", "mastered")


@dataclass
class BardProgress:
    current: str = STEP_IDS[0]
    status: dict[str, str] = field(default_factory=dict)
    notes: dict[str, str] = field(default_factory=dict)

    def update(self, step_id: str, status: str, note: str = "") -> None:
        if step_id not in STEP_IDS:
            raise ValueError(f"unknown curriculum step: {step_id}")
        if status not in STEP_STATUSES:
            raise ValueError(f"unknown status: {status}")
        self.status[step_id] = status
        if note:
            self.notes[step_id] = note
        if status == "mastered":
            # Advance to the first step not yet mastered.
            for sid in STEP_IDS:
                if self.status.get(sid) != "mastered":
                    self.current = sid
                    break
            else:
                self.current = STEP_IDS[-1]
        elif STEP_IDS.index(step_id) > STEP_IDS.index(self.current):
            self.current = step_id

    def summary(self) -> str:
        title = dict(CURRICULUM)[self.current]
        mastered = [sid for sid in STEP_IDS if self.status.get(sid) == "mastered"]
        lines = [f"current_step: {self.current} ({title}), status: {self.status.get(self.current, 'not started')}"]
        lines.append(f"mastered: {', '.join(mastered) if mastered else 'none yet'}")
        if self.current in self.notes:
            lines.append(f"note on current step: {self.notes[self.current]}")
        return "\n".join(lines)


@dataclass
class Session:
    """One conversation with Homer in one mode. Switching mode starts a new Session."""

    mode: Mode
    messages: list[dict[str, Any]] = field(default_factory=list)
    bard: BardProgress = field(default_factory=BardProgress)

    def __post_init__(self) -> None:
        self.mode = Mode(self.mode)
