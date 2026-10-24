"""A live demo-mode battle against SpacetimeDB, with this service as the agent.

The room is hosted by the agent's own identity, so the dev stand-in agent
skips it (HOMER_DEV_SKIP_HOSTS). Two throwaway phone identities join and
speak. The agent deals with the real dealer and judges with the real judge:
two Claude calls, about two cents.

    .venv/bin/python scripts/battle_live.py
"""

from __future__ import annotations

import asyncio
import base64
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from homer.arena import Arena, BattleTurn  # noqa: E402
from homer.config import settings  # noqa: E402
from homer.judge import Judge  # noqa: E402
from homer.stdb import Stdb  # noqa: E402

VERSES = [
    "the wine dark sea took my brother's ship\nI stand on the shore with salt in my teeth",
    "you call that a storm, I call it a breeze\nmy ship comes home on the whale road tonight",
]


def identity_hex(token: str) -> str:
    part = token.split(".")[1]
    claims = json.loads(base64.urlsafe_b64decode(part + "=" * (-len(part) % 4)))
    return claims["hex_identity"]


async def main() -> None:
    cfg = settings()
    agent = Stdb(cfg)
    me = identity_hex(cfg.stdb_token)
    arena = Arena(Judge(cfg=cfg), agent)

    def phone(token: str) -> Stdb:
        return Stdb(type(cfg)(**{**cfg.__dict__, "stdb_token": token}))

    t0 = time.perf_counter()
    await agent.call("create_room", "poetry", 1, 2, 2, 80, "four_beat", True, False, True)
    rooms = [r for r in await agent.sql("SELECT * FROM room") if r["host"][0] == f"0x{me}"]
    room = max(rooms, key=lambda r: r["id"])
    print(f"room {room['code']} (id {room['id']}), demo={room['demo']}, lines={room['lines_per_turn']}")

    poets = []
    for name in ("Ada", "Bo"):
        _, token = await agent.new_identity()
        p = phone(token)
        await p.call("join_room", room["code"], name, "", [])
        poets.append(p)
    players = {r["name"]: r for r in await agent.sql(f"SELECT * FROM player WHERE room_id = {room['id']}")}
    by_id = {players[n]["id"]: poets[i] for i, n in enumerate(("Ada", "Bo"))}

    await agent.call("start_battle", room["id"])
    theme, hands = await arena.deal_round(room["id"], 1, "")
    print(f"theme: {theme}")
    for pid, cards in hands.items():
        print(f"  offered to {pid}: {cards}")

    previous = ""
    for verse in VERSES:
        room = (await agent.sql(f"SELECT * FROM room WHERE id = {room['id']}"))[0]
        turn = (await agent.sql(f"SELECT * FROM turn WHERE id = {room['current_turn_id']}"))[0]
        speaker = by_id[turn["player_id"]]
        if turn["status"] == "waiting":
            await speaker.call("start_turn", turn["id"])
        await speaker.call("update_transcript", turn["id"], verse.split("\n")[0])
        await speaker.call("end_turn", turn["id"], verse)
        tj = time.perf_counter()
        posted, j = await arena.judge_turn(
            BattleTurn(turn_id=turn["id"], transcript=verse, theme=theme, previous=previous,
                       lines_expected=room["lines_per_turn"], player_id=turn["player_id"], demo=room["demo"])
        )
        score = (await agent.sql(f"SELECT * FROM score WHERE turn_id = {turn['id']}"))[0]
        print(f"turn {turn['id']}: {posted} in {(time.perf_counter() - tj) * 1000:.0f} ms, axes {score['axes']}, "
              f"total {score['total']}\n  verdict: {score['verdict']}\n  best line: {score['best_line']}")
        previous = verse
        await agent.call("advance", room["id"])

    room = (await agent.sql(f"SELECT * FROM room WHERE id = {room['id']}"))[0]
    totals = {r["name"]: r["total"] for r in await agent.sql(f"SELECT * FROM player WHERE room_id = {room['id']}")}
    print(f"phase {room['phase']}, totals {totals}, {time.perf_counter() - t0:.1f} s end to end")


if __name__ == "__main__":
    asyncio.run(main())
