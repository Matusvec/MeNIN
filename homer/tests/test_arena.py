import asyncio
import dataclasses
import json

import httpx2
import pytest
from fakes import FakeClient, reply
from fastapi.testclient import TestClient

from homer import server
from homer.arena import Arena, BattleTurn
from homer.config import settings
from homer.judge import Judge
from homer.stdb import Refused, Stdb

VERSE = "the wind was cold the waves were grey\nthe sea kept time and so did I"


class FakeDb:
    """Records reducer calls; answers 530 for reducers listed in `refuse`."""

    def __init__(self, refuse=()):
        self.calls, self.refuse = [], set(refuse)

    def handler(self, request: httpx2.Request) -> httpx2.Response:
        reducer = request.url.path.rsplit("/", 1)[-1]
        self.calls.append((reducer, json.loads(request.content), request.headers.get("authorization")))
        if reducer in self.refuse:
            return httpx2.Response(530, text="the turn is not being judged")
        return httpx2.Response(200)


def cfg():
    return dataclasses.replace(settings(), judge_model="claude-opus-5-5", judge_timeout=5.0, stdb_url="http://stdb.test",
                               stdb_db="homer", stdb_token="tok", service_key="k" * 32)


def make(data=None, refuse=(), delay=0.0):
    db = FakeDb(refuse)
    stdb = Stdb(cfg(), httpx2.AsyncClient(transport=httpx2.MockTransport(db.handler)))
    return Arena(Judge(client=FakeClient(reply() if data is None else data, delay=delay), cfg=cfg()), stdb), db


def test_post_score_sends_the_axes_in_rubric_order():
    arena, db = make()
    posted, j = asyncio.run(arena.judge_turn(BattleTurn(turn_id=42, transcript=VERSE, lines_expected=2)))
    assert posted == "post_score"
    reducer, args, auth = db.calls[0]
    assert reducer == "post_score" and auth == "Bearer tok"
    assert args == [42, [j.scores["beat"], 6, 7, 5, j.scores["range"]], j.verdict, j.best_line, ""]


def test_unfit_verse_declines_the_turn():
    arena, db = make(reply(fit=False, verdict="", best_line=""))
    posted, _ = asyncio.run(arena.judge_turn(BattleTurn(turn_id=7, transcript=VERSE)))
    assert posted == "decline_turn" and db.calls == [("decline_turn", [7], "Bearer tok")]


def test_a_refusal_is_raised_not_retried():
    arena, db = make(refuse={"post_score"})
    with pytest.raises(Refused):
        asyncio.run(arena.judge_turn(BattleTurn(turn_id=1, transcript=VERSE)))
    assert len(db.calls) == 1


def test_a_retry_while_judging_shares_one_claude_call():
    arena, db = make(delay=0.005)

    async def both():
        bt = BattleTurn(turn_id=9, transcript=VERSE)
        return await asyncio.gather(arena.judge_turn(bt), arena.judge_turn(bt))

    a, b = asyncio.run(both())
    assert a[1] is b[1]
    assert len(arena.judge.client.calls) == 1 and len(db.calls) == 1


def test_range_uses_the_turns_emotion_samples():
    arena, _ = make()
    grief = {"grief": 0.9, "anger": 0.1}
    arena.history[5] = [grief, {"anger": 0.9, "grief": 0.1}, {"awe": 0.9}, {"defiance": 0.9}]
    _, wide = asyncio.run(arena.judge_turn(BattleTurn(turn_id=5, transcript=VERSE)))
    arena.history[6] = [grief] * 4
    _, narrow = asyncio.run(arena.judge_turn(BattleTurn(turn_id=6, transcript=VERSE)))
    assert wide.scores["range"] > narrow.scores["range"]


def test_battle_judge_endpoint(monkeypatch):
    monkeypatch.setenv("HOMER_WARM", "0")
    arena, db = make(refuse={"decline_turn"})
    server._judge, server._arena = arena.judge, arena
    try:
        with TestClient(server.app) as c:
            body = c.post("/battle/judge", json={"turnId": 3, "transcript": VERSE, "previousBestLine": "took my ship"}).json()
            assert body["posted"] == "post_score" and body["scores"]["craft"] == 6
            assert "took my ship" in arena.judge.client.calls[0]["messages"][0]["content"]
            assert c.post("/battle/judge", json={"turn_id": 4, "transcript": " "}).status_code == 422
    finally:
        server._judge = server._arena = None


class SqlDb(FakeDb):
    """FakeDb that also answers the player query."""

    def handler(self, request):
        if request.url.path.endswith("/sql"):
            self.calls.append(("sql", request.content.decode(), None))
            cols = [{"name": {"some": n}} for n in ("id", "room_id", "name", "epithet", "hoard", "seat")]
            rows = [[2, 1, "Bo", "Breaker of Deadlines", ["storm-throated"], 1], [1, 1, "Ada", "", [], 0]]
            return httpx2.Response(200, json=[{"schema": {"elements": cols}, "rows": rows}])
        return super().handler(request)


def test_deal_reads_poets_from_sql_and_picks_a_theme():
    db = SqlDb()
    arena = Arena(Judge(client=FakeClient(reply()), cfg=cfg()), Stdb(cfg(), httpx2.AsyncClient(transport=httpx2.MockTransport(db.handler))))
    theme, hands = asyncio.run(arena.deal_round(1, 1, ""))
    assert theme
    reducer, args, _ = db.calls[-1]
    assert reducer == "deal_round" and args[:3] == [1, 1, theme]
    assert [pid for pid, _ in args[3]] == [1, 2]  # seat order
    ada, bo = args[3][0][1], args[3][1][1]
    assert len(ada) == len(bo) == 8 and not set(ada) & set(bo)
    assert "storm-throated" in bo
    # Round two deals fresh cards and a fresh theme.
    theme2, hands2 = asyncio.run(arena.deal_round(1, 2, ""))
    assert theme2 != theme and not set(hands2[1]) & set(ada)


def test_a_database_that_is_down_is_a_stdb_error_not_a_crash():
    from homer.stdb import StdbError

    def down(request):
        raise httpx2.ConnectError("All connection attempts failed", request=request)

    db = Stdb(cfg(), httpx2.AsyncClient(transport=httpx2.MockTransport(down)))
    for work in (db.call("set_scene", 0), db.sql("SELECT * FROM room"), db.is_service()):
        with pytest.raises(StdbError, match="can't reach"):
            asyncio.run(work)


def test_the_service_starts_when_spacetimedb_is_down(monkeypatch):
    monkeypatch.setenv("HOMER_WARM", "0")

    def down(request):
        raise httpx2.ConnectError("All connection attempts failed", request=request)

    arena = Arena(Judge(client=FakeClient(reply()), cfg=cfg()), Stdb(cfg(), httpx2.AsyncClient(transport=httpx2.MockTransport(down))))
    server._judge, server._arena = arena.judge, arena
    monkeypatch.setattr(server, "settings", lambda: cfg())
    try:
        with TestClient(server.app) as c:
            assert c.get("/health").json()["stdb"] == "unreachable"
            arena.db = Stdb(cfg(), httpx2.AsyncClient(transport=httpx2.MockTransport(lambda r: httpx2.Response(200))))
            assert c.get("/health").json()["stdb"] == "claimed"  # back without a restart
    finally:
        server._judge = server._arena = None
