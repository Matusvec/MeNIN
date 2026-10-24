import asyncio
import dataclasses

import pytest
from fakes import FakeClient, reply
from fastapi.testclient import TestClient

from homer import claude, server
from homer.config import settings
from homer.guard import AppKey, Budget, BudgetExceeded, Guard, client_ip, kind_of
from homer.judge import Judge, Turn


def test_per_path_limits_per_ip():
    g = Guard({"/judge": (2, 60)}, cheap=(3, 60))
    assert g.allow("/judge", "a", 0) and g.allow("/judge", "a", 1) and not g.allow("/judge", "a", 2)
    assert g.allow("/judge", "b", 2)  # another device
    assert g.allow("/judge", "a", 61)  # the window slid
    assert all(g.allow("/scan", "a", 0) for _ in range(3)) and not g.allow("/scan", "a", 0)  # the cheap cap
    assert g.allow("/rescue", "a", 0)  # a scan burst never starves the rescue
    assert all(g.allow("/health", "a", 0) for _ in range(100))  # the demo gate is never limited


def test_app_key_rules():
    assert AppKey("", True).ok(None)  # no key configured: open
    assert AppKey("k", False).ok(None) and AppKey("k", False).ok("k") and not AppKey("k", False).ok("x")
    assert not AppKey("k", True).ok(None) and AppKey("k", True).ok("k")


def test_budget_caps_calls_per_hour():
    b = Budget({"claude": 2})
    b.spend("claude", 0)
    b.spend("claude", 1)
    with pytest.raises(BudgetExceeded):
        b.spend("claude", 2)
    b.spend("claude", 3601)  # an hour on
    b.spend("unknown", 0)  # no cap, no limit
    assert kind_of("claude-haiku-5-5") == "claude_cheap" and kind_of("claude-opus-5-5") == "claude"


def test_client_ip_reads_caddys_forwarded_for():
    assert client_ip({"x-forwarded-for": "203.0.113.7"}) == "203.0.113.7"
    assert client_ip({}, "10.0.0.1") == "10.0.0.1"


def test_a_spent_budget_leaves_homer_silent_not_canned(monkeypatch):
    monkeypatch.setattr(claude, "_budget", Budget({"claude": 0}))
    cfg = dataclasses.replace(settings(), judge_model="claude-opus-5-5", judge_timeout=5.0)
    client = FakeClient(reply())
    j = asyncio.run(Judge(client=client, cfg=cfg).judge(Turn("the wind was cold the waves were grey")))
    assert j.silent and j.error == "BudgetExceeded" and j.verdict == "" and j.scores["craft"] == 0
    assert client.calls == []  # nothing was sent


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("HOMER_WARM", "0")
    cfg = dataclasses.replace(settings(), judge_model="claude-opus-5-5", judge_timeout=5.0)
    server._judge = Judge(client=FakeClient(reply()), cfg=cfg)
    monkeypatch.setattr(server, "_guard", Guard({"/judge": (2, 60)}))
    with TestClient(server.app) as c:
        yield c
    server._judge = server._arena = None


VERSE = {"transcript": "the wind was cold the waves were grey"}


def test_rate_limit_answers_429(client):
    assert client.post("/judge", json=VERSE).status_code == 200
    assert client.post("/judge", json=VERSE).status_code == 200
    r = client.post("/judge", json=VERSE)
    assert r.status_code == 429 and "slow down" in r.json()["detail"]
    assert client.post("/judge", json=VERSE, headers={"X-Forwarded-For": "198.51.100.9"}).status_code == 200


def test_app_key_when_required(client, monkeypatch):
    monkeypatch.setenv("HOMER_APP_KEY", "s3cret")
    monkeypatch.setenv("HOMER_APP_KEY_REQUIRED", "1")
    assert client.post("/judge", json=VERSE).status_code == 401
    assert client.post("/judge", json=VERSE, headers={"X-Homer-Key": "nope"}).status_code == 401
    assert client.post("/judge", json=VERSE, headers={"X-Homer-Key": "s3cret"}).status_code == 200
    assert client.get("/health").status_code == 200 and client.post("/scan", json=VERSE).status_code == 200  # not keyed


WEB = "https://play.example.test"


def test_the_website_gets_cors_and_needs_no_key(client, monkeypatch):
    monkeypatch.setenv("HOMER_WEB_ORIGINS", f"{WEB}, https://playmenin.tech/")
    monkeypatch.setenv("HOMER_APP_KEY", "s3cret")
    monkeypatch.setenv("HOMER_APP_KEY_REQUIRED", "1")
    pre = client.options("/judge", headers={"Origin": WEB, "Access-Control-Request-Method": "POST",
                                            "Access-Control-Request-Headers": "content-type"})
    assert pre.status_code == 204 and pre.headers["access-control-allow-origin"] == WEB
    assert "content-type" in pre.headers["access-control-allow-headers"]
    r = client.post("/judge", json=VERSE, headers={"Origin": WEB})
    assert r.status_code == 200 and r.headers["access-control-allow-origin"] == WEB  # keyless from the website
    assert client.post("/judge", json=VERSE, headers={"Origin": WEB, "X-Homer-Key": "nope"}).status_code == 401
    assert client.get("/health", headers={"Origin": "https://playmenin.tech"}).headers["access-control-allow-origin"] == "https://playmenin.tech"
    other = client.post("/judge", json=VERSE, headers={"Origin": "https://evil.test"})
    assert other.status_code == 401 and "access-control-allow-origin" not in other.headers
    assert client.options("/judge", headers={"Origin": "https://evil.test"}).status_code != 204


def test_the_website_is_rate_limited_like_anyone(client, monkeypatch):
    monkeypatch.setenv("HOMER_WEB_ORIGINS", WEB)
    statuses = [client.post("/judge", json=VERSE, headers={"Origin": WEB}).status_code for _ in range(3)]
    assert statuses == [200, 200, 429]


def test_no_origins_no_cors(client, monkeypatch):
    monkeypatch.delenv("HOMER_WEB_ORIGINS", raising=False)
    assert "access-control-allow-origin" not in client.get("/health", headers={"Origin": WEB}).headers
