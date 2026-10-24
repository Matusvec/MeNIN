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
from .emotion import EMOTIONS, Classifier
from .deal import CANDIDATES, deal, pick_theme
from .host import Host, Verse
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


class NotFound(LookupError):
    pass


class Arena:
    def __init__(self, judge: Judge, db: Stdb, host: Host | None = None, classifier: Classifier | None = None) -> None:
        self.judge, self.db = judge, db
        self.host = host or Host(client=judge.client, cfg=judge.cfg)
        self.classifier = classifier or Classifier(client=judge.client, cfg=judge.cfg)
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

    async def poets(self, room_id: int) -> list[Poet]:
        """The room's poets in seat order, from SQL (the source of truth for hoards)."""
        rows = await self.db.sql(f"SELECT * FROM player WHERE room_id = {int(room_id)}")
        rows.sort(key=lambda r: r.get("seat", 0))
        return [Poet(r["id"], r.get("name", ""), r.get("epithet", ""), list(r.get("hoard") or [])) for r in rows]

    async def deal_round(
        self, room_id: int, round_no: int, theme: str, poets: list[Poet] | None = None
    ) -> tuple[str, dict[int, list[str]]]:
        """Pick the theme if none was chosen, deal every poet, and call deal_round."""

        async def work() -> tuple[str, dict[int, list[str]]]:
            nonlocal poets
            if poets is None:
                poets = await self.poets(room_id)
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

    async def scene(self, turn_id: int, text: str, loudness: float | None = None, pitch: float | None = None) -> dict[str, float] | None:
        """Classify the latest speech, keep the sample for Range, and call set_scene.

        A call that arrives while one for the same turn is running shares its
        result, so a slow reply never stacks up behind the 1.5 s cadence.
        """

        async def work() -> dict[str, float] | None:
            weights = await self.classifier.classify(text, loudness, pitch)
            if weights is None:
                return None
            self.history.setdefault(turn_id, []).append(weights)
            await self.db.call("set_scene", turn_id, *[weights[e] for e in EMOTIONS])
            return weights

        return await self.once(("scene", turn_id), work)

    async def name_poet(self, player_id: int, name: str | None = None, epithet: str | None = None) -> tuple[str, str]:
        """PG-check the name, coin an epithet if there is none, and call name_poet."""

        async def work() -> tuple[str, str]:
            n, e = name, epithet
            if n is None:
                rows = await self.db.sql(f"SELECT * FROM player WHERE id = {int(player_id)}")
                if not rows:
                    raise NotFound(f"no player {player_id}")
                n, e = rows[0]["name"], rows[0]["epithet"]
            n, e, _ = await self.host.name_poet(n, e or "")
            await self.db.call("name_poet", player_id, n, e)
            return n, e

        return await self.once(("poet", player_id), work)

    async def _verses(self, room_id: int, where: str) -> list[Verse]:
        """Scored verses matching a SQL condition on `turn`, in battle order."""
        turns = await self.db.sql(f"SELECT * FROM turn WHERE {where}")
        scores = {s["turn_id"]: s for s in await self.db.sql(f"SELECT * FROM score WHERE room_id = {int(room_id)}")}
        players = {p["id"]: p for p in await self.db.sql(f"SELECT * FROM player WHERE room_id = {int(room_id)}")}
        out = []
        for t in sorted(turns, key=lambda t: (t["round_id"], t["turn_no"])):
            s = scores.get(t["id"])
            if s is None or not t.get("transcript", "").strip():
                continue
            p = players.get(t["player_id"], {})
            poet = ", ".join(x for x in (p.get("name", ""), p.get("epithet", "")) if x)
            out.append(Verse(t["id"], poet, t["transcript"], int(s.get("total", 0)), s.get("best_line", "")))
        return out

    async def round_verdict(self, round_id: int) -> tuple[str, int, str]:
        """Call the round and carve its best line: post_verdict."""

        async def work() -> tuple[str, int, str]:
            rows = await self.db.sql(f"SELECT * FROM round WHERE id = {int(round_id)}")
            if not rows:
                raise NotFound(f"no round {round_id}")
            rnd = rows[0]
            verses = await self._verses(rnd["room_id"], f"round_id = {int(round_id)}")
            verdict, best_turn, line = await self.host.round_verdict(rnd.get("theme", ""), verses)
            await self.db.call("post_verdict", round_id, verdict, best_turn, line)
            return verdict, best_turn, line

        return await self.once(("verdict", round_id), work)

    async def song(self, room_id: int) -> list[tuple[int, str]]:
        """Stitch every scored verse so far into the song: post_song. Demo rooms get 4 lines."""

        async def work() -> list[tuple[int, str]]:
            rows = await self.db.sql(f"SELECT * FROM room WHERE id = {int(room_id)}")
            if not rows:
                raise NotFound(f"no room {room_id}")
            verses = await self._verses(room_id, f"room_id = {int(room_id)}")
            lines = await self.host.song(verses, demo=bool(rows[0].get("demo")))
            await self.db.call("post_song", room_id, [t for t, _ in lines], [text for _, text in lines])
            return lines

        return await self.once(("song", room_id), work)

    def forget_room(self, turn_ids: list[int], player_ids: list[int]) -> None:
        for t in turn_ids:
            self.history.pop(t, None)
        for p in player_ids:
            self.dealt.pop(p, None)
