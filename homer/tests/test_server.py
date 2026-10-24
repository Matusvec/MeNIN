import dataclasses
import json

import pytest
from fakes import FakeClient, reply
from fastapi.testclient import TestClient

from homer import server
from homer.config import settings
from homer.judge import Judge

VERSE = "the wind was cold the waves were grey\nthe sea kept time and so did I"


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("HOMER_WARM", "0")
    cfg = dataclasses.replace(settings(), judge_model="claude-opus-5-5", judge_timeout=5.0)
    server._judge = Judge(client=FakeClient(reply(), delay=0.005), cfg=cfg)
    with TestClient(server.app) as c:
        yield c
    server._judge = None


def test_health(client):
    body = client.get("/health").json()
    assert body["ok"] and body["events"] == ["poetry"]


def test_scan_returns_lines_and_a_beat_lane(client):
    body = client.post("/scan", json={"transcript": VERSE, "bpm": 80, "linesExpected": 2}).json()
    assert body["beat"] == 10
    assert body["lines"][0]["pattern"] == "the WIND was COLD / the WAVES were GREY"
    assert body["lines"][0]["breakSource"] == "inferred"
    assert body["beatLane"]["lines"] == 2
    assert set(body["beatLane"]["words"][0]) == {"text", "t", "stressed", "onBeat", "formulaId"}


def test_scan_takes_timed_words_in_snake_or_camel_case(client):
    words = [{"text": w, "start": i * 375.0, "end": i * 375.0 + 300} for i, w in enumerate("wind was cold now".split())]
    body = client.post("/scan", json={"words": words, "bpm": 80, "lines_expected": 1}).json()
    assert body["timed"] and body["lines"][0]["words"][0]["onBeat"] is True


def test_judge_returns_a_scorecard(client):
    body = client.post("/judge", json={"transcript": VERSE, "theme": "the sea", "linesExpected": 2}).json()
    assert set(body["scores"]) == {"beat", "craft", "image", "answer", "range"}
    assert body["total"] == sum(body["scores"].values())
    assert body["verdict"] and body["bestLine"] == "the sea kept time and so did I"
    assert body["silent"] is False and body["declined"] is False


def test_judge_streams_the_verdict_first(client):
    with client.stream("POST", "/judge", json={"transcript": VERSE}, headers={"Accept": "text/event-stream"}) as r:
        raw = "".join(r.iter_text())
    events = [chunk.split("\n", 1) for chunk in raw.strip().split("\n\n")]
    names = [e[0].removeprefix("event: ") for e in events]
    assert names == ["verdict", "scorecard"]
    assert json.loads(events[0][1].removeprefix("data: "))["verdict"].startswith("Strong bones")


def test_judge_rejects_an_empty_verse_and_unknown_events(client):
    assert client.post("/judge", json={"transcript": "  "}).status_code == 422
    assert client.post("/judge", json={"transcript": VERSE, "event": "discus"}).status_code == 400
    assert client.post("/scan", json={"transcript": VERSE, "event": "discus"}).status_code == 400


def test_lessons_and_feedback(client):
    ls = client.get("/lessons?bpm=80").json()["lessons"]
    assert [l["id"] for l in ls][:3] == ["beat", "formula", "epithet"] and ls[0]["feedback"] and not ls[3]["feedback"]
    assert ls[0]["demoLane"]["words"][1] == {"text": "wind", "t": 0.0, "stressed": True, "onBeat": True, "formulaId": None}
    body = client.post("/lesson/feedback", json={"lesson": "beat", "transcript": "the cat sat on the mat\nthe road was long, the night was cold"}).json()
    assert body["landed"] is False and body["line"].startswith("Three hits.")
    assert client.post("/lesson/feedback", json={"lesson": "turn", "transcript": "we broke their gates"}).status_code == 501
    assert client.post("/lesson/feedback", json={"lesson": "nope"}).status_code == 404
