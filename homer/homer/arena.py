"""What the arena asks of the agent during a battle.

The arena sees a phase change, calls one of the /battle endpoints, and reads
the result back through its SpacetimeDB subscription. This module does the
work and writes it with the agent's reducers (spacetime/CONTRACT.md, "Agent
service"). It also remembers what only the agent knows: the cards it dealt
(hands are private, so SQL can't read them) and each turn's emotion samples,
which Range is scored from.
"""

from __future__ import annotations

import asyncio
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import TypeVar

from . import events
from .deal import CANDIDATES, deal, pick_theme
from .judge import Judge, Judgment, Turn
from .stdb import Stdb

T = TypeVar("T")


@dataclass
class Poet:
    player_id: int
    name: str = ""
    epithet: str = ""
    hoard: list[str] = field(default_factory=list)


@dataclass
class BattleTurn:
    turn_id: int
    transcript: str
    event: str = "poetry"
    theme: str = ""
    played: list[str] = field(default_factory=list)
    rescues: int = 0
    previous: str = ""  # the previous verse in the round, or its best line
    lines_expected: int | None = None
    player_id: int = 0
    hoard: list[str] = field(default_factory=list)
    demo: bool = False


class Arena:
    def __init__(self, judge: Judge, db: Stdb) -> None:
        self.judge, self.db = judge, db
        self.history: dict[int, list[dict[str, float]]] = {}  # turn_id -> emotion samples, in order
        self.dealt: dict[int, list[str]] = {}  # player_id -> every card offered this battle
        self.themes_used: dict[int, list[str]] = {}  # room_id -> themes dealt, so a rematch gets fresh ones
        self._inflight: dict[tuple, asyncio.Task] = {}

    async def once(self, key: tuple, work: Callable[[], Awaitable[T]]) -> T:
        """Run `work` once per key at a time; a retry while it runs shares the result."""
        task = self._inflight.get(key)
        if task is None:
            task = asyncio.ensure_future(work())
            self._inflight[key] = task
            task.add_done_callback(lambda _: self._inflight.pop(key, None))
        return await asyncio.shield(task)

    async def judge_turn(self, bt: BattleTurn) -> tuple[str, Judgment]:
        """Judge a verse and post the score (or decline it). Returns the reducer called."""

        async def work() -> tuple[str, Judgment]:
            event = events.get(bt.event)
            turn = Turn(
                transcript=bt.transcript,
                mode="battle",
                event=bt.event,
                theme=bt.theme,
                hand=self.dealt.get(bt.player_id, []),
                played=bt.played,
                rescues=bt.rescues,
                previous=bt.previous,
                lines_expected=bt.lines_expected,
                emotion_history=self.history.get(bt.turn_id, []),
                hoard=bt.hoard,
                demo=bt.demo,
            )
            j = await self.judge.judge(turn)
            if j.declined:
                await self.db.call("decline_turn", bt.turn_id)
                return "decline_turn", j
            axes = [j.scores[a.key] for a in event.axes]
            await self.db.call("post_score", bt.turn_id, axes, j.verdict, j.best_line, j.coined)
            return "post_score", j

        return await self.once(("judge", bt.turn_id), work)

    async def deal_round(self, room_id: int, round_no: int, theme: str, poets: list[Poet]) -> tuple[str, dict[int, list[str]]]:
        """Pick the theme if none was chosen, deal every poet, and call deal_round."""

        async def work() -> tuple[str, dict[int, list[str]]]:
            t = theme.strip() or pick_theme(avoid=self.themes_used.get(room_id, []))
            offered: set[str] = set()  # poets in one round get different cards
            hands: list[list] = []
            for p in poets:
                cards = deal(t, p.hoard, n=CANDIDATES, exclude=[*self.dealt.get(p.player_id, []), *offered])
                texts = [c.text for c in cards]
                offered.update(texts)
                hands.append([p.player_id, texts])
            await self.db.call("deal_round", room_id, round_no, t, hands)
            for pid, texts in hands:
                self.dealt.setdefault(pid, []).extend(texts)
            self.themes_used.setdefault(room_id, []).append(t)
            return t, {pid: texts for pid, texts in hands}

        return await self.once(("deal", room_id, round_no), work)

    def forget_room(self, turn_ids: list[int], player_ids: list[int]) -> None:
        for t in turn_ids:
            self.history.pop(t, None)
        for p in player_ids:
            self.dealt.pop(p, None)
