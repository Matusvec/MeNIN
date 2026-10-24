"""What the arena asks of the agent during a battle.

The arena sees a phase change, calls one of the /battle endpoints, and reads
the result back through its SpacetimeDB subscription. This module does the
work and writes it with the agent's reducers (spacetime/CONTRACT.md, "Agent
service"). It also remembers what only the agent knows: the cards it dealt
(hands are private, so SQL can't read them) and each turn's emotion samples,
which Range is scored from.

The room's event (room.event) decides the rest: a poetry round gets a theme
and formulas, a debate round a question and moves; the host's persona, the
round call and the finale (the stitched song, or Socrates' last question)
follow the event.
"""

from __future__ import annotations

import asyncio
import logging
import string
import time
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import TypeVar

from . import debate, events, moss_dealer
from .emotion import EMOTIONS, Classifier
from .deal import CANDIDATES, call_for, deal, pick_theme
from .host import Host, Verse
from .lines import break_lines
from .judge import SILENT_VERDICT, EmptyVerse, Judge, Judgment, Turn
from .stdb import Refused, Stdb, StdbError

T = TypeVar("T")
log = logging.getLogger("homer")

WORN = 5  # a poet's last epithets that a fresh one may not repeat
FLOW_NEUTRAL = 5  # Flow for a verse with no breath breaks from the phone: no lines of its own to judge
HOSTS = frozenset({"homer", "socrates"})  # the hosts' names; a poet who types one becomes "Poet {seat}"
RECENT_THEMES = 20  # themes a generated one may not repeat
THEME_WAIT = 4.0  # seconds a deal waits for a theme still being coined, then takes a written one


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
    side: str = ""  # debate: the side dealt to this debater
    turn_seconds: float | None = None  # debate: for keeping the floor
    spoken_seconds: float | None = None  # debate: for pace


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
        self._live: dict[int, tuple[float, bool]] = {}  # turn_id -> (checked at, speaking or judging)
        self._verdicts: dict[int, tuple[str, int, str]] = {}  # round_id -> the call, worked out ahead of round_end
        self._next_theme: dict[int, asyncio.Task] = {}  # room_id -> the next round's theme, being coined
        self._calls: dict[str, str] = {}  # a coined theme (lowercase) -> the call that hands the floor over

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
            # The live turn, not the request, says what's judged: only a turn in `judging`
            # costs a Claude call, and its words, cards and rescues come from the database.
            rows = await self.db.sql(f"SELECT * FROM turn WHERE id = {int(bt.turn_id)}")
            if not rows:
                raise NotFound(f"no turn {bt.turn_id}")
            live = rows[0]
            if live.get("status") != "judging":
                raise Refused(f"turn {bt.turn_id} is {live.get('status')}, not judging")
            if bt.event == "coach":  # a wrong event can't slip through: the module refuses axes that don't fit the room
                return await self._coach_turn(bt.turn_id, live)
            event = events.get(bt.event)
            said = live.get("transcript") or ""
            turn = Turn(
                transcript=break_lines(said) if event.hand == "formulas" else said,  # free verse: a line per breath
                mode="battle",
                event=bt.event,
                theme=bt.theme,
                hand=self.dealt.get(bt.player_id, []),
                played=list(live.get("played") or []),
                rescues=int(live.get("rescues") or 0),
                previous=bt.previous,
                lines_expected=None if event.hand == "formulas" else bt.lines_expected,  # free verse: as many lines as breaths
                emotion_history=self.history.get(bt.turn_id, []),
                hoard=bt.hoard,
                demo=bt.demo,
                side=bt.side,
                turn_seconds=bt.turn_seconds,
                spoken_seconds=bt.spoken_seconds,
            )
            j = await self.judge.judge(turn)
            if event.hand == "formulas" and "\n" not in said.strip():
                # The splitter cuts lines to about four stresses, so Flow on its lines is a free 10.
                j.scores["beat"] = FLOW_NEUTRAL
            if j.declined:
                await self.db.call("decline_turn", bt.turn_id)
                return "decline_turn", j
            axes = [j.scores[a.key] for a in event.axes]
            await self.db.call("post_score", bt.turn_id, axes, j.verdict, j.best_line, j.coined)
            return "post_score", j

        return await self.once(("judge", bt.turn_id), work)

    async def _coach_turn(self, turn_id: int, live: dict) -> tuple[str, Judgment]:
        """Talk to Homer: his spoken reply to this turn, from the room's conversation so far, posted as the verdict."""
        room_id = int(live["room_id"])
        said = break_lines(live.get("transcript") or "")
        if not said.strip():
            raise EmptyVerse("nothing to answer")
        turns = sorted(await self.db.sql(f"SELECT * FROM turn WHERE room_id = {room_id}"), key=lambda t: t["id"])
        replies = {s["turn_id"]: s.get("verdict", "") for s in await self.db.sql(f"SELECT * FROM score WHERE room_id = {room_id}")}
        names = {p["id"]: p.get("name", "") for p in await self.db.sql(f"SELECT * FROM player WHERE room_id = {room_id}")}
        rounds = sorted(await self.db.sql(f"SELECT * FROM round WHERE room_id = {room_id}"), key=lambda r: r["id"])
        theme = (rounds[-1].get("theme") if rounds else "") or ""
        history: list[tuple[str, str, str]] = [("homer", "", opening_line(theme))] if theme else []
        for t in turns:
            if t["id"] == turn_id:
                break
            text = (t.get("transcript") or "").strip()
            if text and replies.get(t["id"]):
                history += [("poet", names.get(t["player_id"], ""), text), ("homer", "", replies[t["id"]])]
        history.append(("poet", names.get(live.get("player_id"), ""), said))
        reply = await self.host.coach(history, theme) or SILENT_VERDICT  # honest, never invented
        await self.db.call("post_score", turn_id, [], reply, "", "")
        j = Judgment(scores={}, verdict=reply, silent=reply == SILENT_VERDICT)
        return "post_score", j

    async def room(self, room_id: int) -> dict:
        rows = await self.db.sql(f"SELECT * FROM room WHERE id = {int(room_id)}")
        if not rows:
            raise NotFound(f"no room {room_id}")
        return rows[0]

    async def event_of(self, room_id: int) -> events.Event:
        return events.get((await self.room(room_id)).get("event") or "poetry")

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
            event = await self.event_of(room_id)
            used = self.themes_used.get(room_id, [])
            hands: list[list] = []
            if event.hand == "moves":  # debate: a question, and moves with every role (one deck per poet)
                q = debate.question(theme) if theme.strip() else debate.pick_question(avoid=used)
                t = q.ask if q else theme.strip()
                for p in poets:
                    moves = debate.deal(n=debate.CANDIDATES, exclude=self.dealt.get(p.player_id, []))
                    hands.append([p.player_id, [m.text for m in moves]])
            elif event.id == "coach":  # Talk to Homer: a theme to open the conversation, no cards
                t = theme.strip() or await self._theme_for(room_id, used)
                hands = [[p.player_id, []] for p in poets]
            else:
                t = theme.strip() or await self._theme_for(room_id, used)
                ranked = await moss_dealer.ranked_formulas(t)  # None unless HOMER_DEALER=moss and Moss answers in time
                offered: set[str] = set()  # poets in one round get different cards
                for p in poets:
                    cards = deal(t, p.hoard, n=CANDIDATES, exclude=[*self.dealt.get(p.player_id, []), *offered], ranked=ranked)
                    texts = [c.text for c in cards]
                    offered.update(texts)
                    hands.append([p.player_id, texts])
            await self.db.call("deal_round", room_id, round_no, t, hands)
            for pid, texts in hands:
                self.dealt.setdefault(pid, []).extend(texts)
            self.themes_used.setdefault(room_id, []).append(t)
            if event.hand == "formulas":  # the next round's (or a rematch's) theme, coined while this one plays
                self.prefetch_theme(room_id)
            return t, {pid: texts for pid, texts in hands}

        return await self.once(("deal", room_id, round_no), work)

    async def scene(self, turn_id: int, text: str, loudness: float | None = None, pitch: float | None = None) -> dict[str, float] | None:
        """Classify the latest speech, keep the sample for Range, and call set_scene.

        A call that arrives while one for the same turn is running shares its
        result, so a slow reply never stacks up behind the 1.5 s cadence.
        """

        async def work() -> dict[str, float] | None:
            if not await self._turn_is_live(turn_id):
                raise Refused(f"turn {turn_id} isn't speaking or judging")
            weights = await self.classifier.classify(text, loudness, pitch)
            if weights is None:
                return None
            self.history.setdefault(turn_id, []).append(weights)
            await self.db.call("set_scene", turn_id, *[weights[e] for e in EMOTIONS])
            return weights

        return await self.once(("scene", turn_id), work)

    async def _turn_is_live(self, turn_id: int, ttl: float = 5.0) -> bool:
        """Whether a turn is speaking or judging, from SQL at most every `ttl` seconds (emotion runs every 1.5 s)."""
        hit = self._live.get(turn_id)
        if hit and time.monotonic() - hit[0] < ttl:
            return hit[1]
        rows = await self.db.sql(f"SELECT * FROM turn WHERE id = {int(turn_id)}")
        live = bool(rows) and rows[0].get("status") in ("speaking", "judging")
        self._live[turn_id] = (time.monotonic(), live)
        return live

    async def name_poet(self, player_id: int, name: str | None = None, epithet: str | None = None) -> tuple[str, str]:
        """PG-check the poet's name, coin an epithet if there is none, and call name_poet.

        The player row is the truth: a poet already named costs nothing, and the
        request's name and epithet are ignored (they'd be free text into Claude).
        """

        async def work() -> tuple[str, str]:
            rows = await self.db.sql(f"SELECT * FROM player WHERE id = {int(player_id)}")
            if not rows:
                raise NotFound(f"no player {player_id}")
            row = rows[0]
            n, e = row["name"], row["epithet"]
            if row.get("named"):
                return n, e
            event = await self.event_of(row["room_id"])
            worn, last = await self._past(row)
            stand_in = f"Poet {int(row.get('seat') or 0) + 1}"  # seats count from 0
            n = stand_in if n.strip().lower() in HOSTS else n  # old builds prefill the host's name
            n, e, _ = await self.host.name_poet(n, e or "", event, worn=worn, last_verse=last)
            n = stand_in if n.strip().lower() in HOSTS else n
            await self.db.call("name_poet", player_id, n, e)
            if event.hand == "formulas":  # the lobby: get the first round's theme coming
                self.prefetch_theme(row["room_id"])
            return n, e

        return await self.once(("poet", player_id), work)

    async def _past(self, row: dict) -> tuple[list[str], str]:
        """This poet's last epithets (newest first, the one they brought too) and their last verse.

        Earlier battles are earlier player rows with the same identity (the phone's), then
        the same name. The verse comes only from their own identity.
        """
        worn = [row.get("epithet") or ""]
        ident = row.get("identity")
        ident = ident[0] if isinstance(ident, list) and ident else ident
        if not (isinstance(ident, str) and ident.startswith("0x") and all(c in string.hexdigits for c in ident[2:])):
            return [w for w in worn if w], ""
        try:
            mine = await self.db.sql(f"SELECT * FROM player WHERE identity = {ident}")
            before = sorted((p for p in mine if p["id"] != row["id"]), key=lambda p: p["id"], reverse=True)
            worn += [p.get("epithet") or "" for p in before]
            name = (row.get("name") or "").replace("'", "''")
            if name:  # the same name on a new identity (a reinstall) still gets a fresh title
                namesakes = await self.db.sql(f"SELECT * FROM player WHERE name = '{name}'")
                worn += [p.get("epithet") or "" for p in sorted(namesakes, key=lambda p: p["id"], reverse=True) if p["id"] != row["id"]]
            last = ""
            for p in before[:3]:
                said = [t for t in await self.db.sql(f"SELECT * FROM turn WHERE player_id = {int(p['id'])}") if (t.get("transcript") or "").strip()]
                if said:
                    last = max(said, key=lambda t: t["id"])["transcript"]
                    break
        except StdbError as exc:  # a fresh epithet still comes; it just can't see their past
            log.warning("poet history: %s", exc)
            last = ""
        return [w for w in dict.fromkeys(worn) if w][:WORN], last

    # ----- Themes ------------------------------------------------------------

    def prefetch_theme(self, room_id: int) -> None:
        """Coin the room's next theme in the background: from the lobby, then after every deal."""
        task = self._next_theme.get(room_id)
        if task is None or _failed(task) or (task.done() and task.result() is None):
            self._next_theme[room_id] = asyncio.ensure_future(self._coin_theme(room_id))

    async def _coin_theme(self, room_id: int) -> str | None:
        try:
            rounds = sorted(await self.db.sql("SELECT * FROM round"), key=lambda r: r["id"])
            recent = [r.get("theme", "") for r in rounds[-RECENT_THEMES:]] + self.themes_used.get(room_id, [])
            coined = await self.host.coin_theme(recent) or await self.host.coin_theme(recent)  # one retry: it's off the clock
        except Exception as exc:  # the written themes still deal
            log.warning("theme: %s", exc)
            return None
        if coined is None:
            return None
        theme, call = coined
        if call:
            self._calls[theme.lower()] = call
        return theme

    async def _theme_for(self, room_id: int, used: list[str]) -> str:
        """The coined theme waiting for this room (or one coined now), else a written one."""
        task = self._next_theme.pop(room_id, None)
        if task is None or _failed(task):
            task = asyncio.ensure_future(self._coin_theme(room_id))
        try:
            theme = await asyncio.wait_for(asyncio.shield(task), THEME_WAIT)
        except asyncio.TimeoutError:
            theme = None
        return theme if theme and theme not in used else pick_theme(avoid=used)

    def call_for(self, theme: str) -> str:
        """The line that hands the floor over after the theme: a coined theme's own, else the written one."""
        return self._calls.get(" ".join(theme.split()).lower()) or call_for(theme)

    async def _verses(self, room_id: int, where: str, event: events.Event | None = None) -> list[Verse]:
        """Scored verses matching a SQL condition on `turn`, in battle order (poetry: a line per breath)."""
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
            said = break_lines(t["transcript"]) if event is not None and event.hand == "formulas" else t["transcript"]
            out.append(Verse(t["id"], poet, said, int(s.get("total", 0)), s.get("best_line", "")))
        return out

    async def round_verdict(self, round_id: int) -> tuple[str, int, str]:
        """Call the round and carve its best line: post_verdict.

        Also ahead of time: once the round's last turn is scored, the arena asks
        during that verdict's reveal, and the call is worked out and kept. The
        module takes post_verdict only in round_end, so it's posted when the arena
        asks again there, with no wait on Claude.
        """
        rows = await self.db.sql(f"SELECT * FROM round WHERE id = {int(round_id)}")
        if not rows:
            raise NotFound(f"no round {round_id}")
        rnd = rows[0]
        if rnd.get("verdict"):  # called already: say it again, don't pay for it again
            return rnd["verdict"], int(rnd.get("best_turn_id") or 0), rnd.get("best_line", "")
        room = await self.room(rnd["room_id"])
        phase = room.get("phase")
        if phase != "round_end" and not (phase == "scored" and await self._round_done(round_id)):
            raise Refused(f"round {round_id}'s room is in {phase}, not round_end")

        async def work() -> tuple[str, int, str]:
            event = events.get(room.get("event") or "poetry")
            verses = await self._verses(rnd["room_id"], f"round_id = {int(round_id)}", event)
            call = await self.host.round_verdict(rnd.get("theme", ""), verses, event)
            self._verdicts[round_id] = call
            return call

        call = self._verdicts.get(round_id) or await self.once(("verdict", round_id), work)
        if phase == "round_end":
            await self.db.call("post_verdict", round_id, *call)
        return call

    async def _round_done(self, round_id: int) -> bool:
        """Every turn of the round is over (scored, skipped or declined)."""
        turns = await self.db.sql(f"SELECT * FROM turn WHERE round_id = {int(round_id)}")
        return bool(turns) and all(t.get("status") in ("scored", "skipped", "declined") for t in turns)

    async def song(self, room_id: int) -> list[tuple[int, str]]:
        """The finale, written with post_song.

        Poetry: every scored verse so far stitched into the song (4 lines in demo
        rooms). Debate: Socrates' last question, the night's strongest point
        quoted and then the question nobody answered.
        """

        async def work() -> list[tuple[int, str]]:
            room = await self.room(room_id)
            if room.get("phase") not in ("round_end", "finale"):
                raise Refused(f"room {room_id} is in {room.get('phase')}: the song is stitched at a round's end")
            event = events.get(room.get("event") or "poetry")
            verses = await self._verses(room_id, f"room_id = {int(room_id)}", event)
            if event.hand == "moves":
                rounds = await self.db.sql(f"SELECT * FROM round WHERE room_id = {int(room_id)}")
                asked = [r.get("theme", "") for r in sorted(rounds, key=lambda r: r.get("round_no", 0))]
                lines = await self.host.last_question(verses, asked)
            else:
                lines = await self.host.song(verses, demo=bool(room.get("demo")))
            await self.db.call("post_song", room_id, [t for t, _ in lines], [text for _, text in lines])
            return lines

        return await self.once(("song", room_id), work)

    def forget_room(self, turn_ids: list[int], player_ids: list[int]) -> None:
        for t in turn_ids:
            self.history.pop(t, None)
        for p in player_ids:
            self.dealt.pop(p, None)


def opening_line(theme: str) -> str:
    """Homer's opening in Talk to Homer: "Give me a verse about the ship that left without you." """
    t = theme.strip().rstrip(".")
    return f"Give me a verse about {t[:1].lower() + t[1:]}." if t else "Give me a verse."


def _failed(task: asyncio.Task) -> bool:
    """A finished task with nothing to give: cancelled (say, at shutdown) or raised."""
    return task.done() and (task.cancelled() or task.exception() is not None)
