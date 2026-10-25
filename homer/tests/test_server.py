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
    server._judge = server._arena = None


def test_health(client):
    body = client.get("/health").json()
    assert body["ok"] and body["events"] == ["poetry", "debate", "coach"]


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
    w = {"beat": 0, "craft": 2, "image": 4, "answer": 4, "range": 0}  # content only (out of 100): Flow and Range unscored
    assert body["total"] == sum(v * w[k] for k, v in body["scores"].items())
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
    assert [l["id"] for l in ls] == ["beat", "formula", "epithet", "turn", "answer", "boast"]
    assert all(l["feedback"] for l in ls) and len(ls[4]["exercise"]) == 3
    assert ls[0]["demoLane"]["words"][0] == {"text": "sing", "t": 0.0, "stressed": True, "onBeat": True, "formulaId": None}
    body = client.post("/lesson/feedback", json={"lesson": "beat", "transcript": "the cat on the mat\nthe road was long, the night was cold"}).json()
    assert body["landed"] is False and body["line"].startswith("Two hits.")
    short = client.post("/lesson/feedback", json={"lesson": "turn", "transcript": "we broke their gates"}).json()
    assert short["miss"] == "Fewer lines than the exercise asks for"
    assert client.post("/lesson/feedback", json={"lesson": "nope"}).status_code == 404


def test_emotion_takes_text_or_transcript(client, monkeypatch):
    seen = []

    async def classify(text, loudness=None, pitch=None):
        seen.append((text, loudness))
        return {"grief": 0.8}

    monkeypatch.setattr(server.arena().classifier, "classify", classify)
    assert client.post("/emotion", json={"transcript": "the grave is cold", "loudness": 0.4}).json() == {"weights": {"grief": 0.8}}
    assert client.post("/emotion", json={"text": "the grave"}).status_code == 200
    assert client.post("/emotion", json={"transcript": "  "}).status_code == 422
    assert seen == [("the grave is cold", 0.4), ("the grave", None)]


def test_themes_carry_homers_call_and_debate_has_a_demo_question():
    from homer import server
    from fastapi.testclient import TestClient
    with TestClient(server.app) as c:
        demo = c.get("/themes?demo=true").json()
        assert demo["themes"][:3] == ["A ship that never came home", "The night before the battle", "The war between two brothers"]
        assert demo["calls"] == ["The sea is yours.", "The watch is yours.", "Pick a brother."]
        some = c.get("/themes?n=5").json()
        assert len(some["calls"]) == len(some["themes"]) == 5 and all(some["calls"])
        debate = c.get("/themes?event=debate&demo=true").json()
        assert debate == {"themes": ["Is it cheating to let an AI write your love letter?"], "calls": [""]}
        assert len(c.get("/themes?event=debate").json()["themes"]) == 3


def test_call_for_any_theme():
    from homer.deal import FLOOR, THEME_CALLS, call_for, themes
    assert all(call_for(t) == THEME_CALLS[t] for t in themes()) and len(THEME_CALLS) == 16
    assert call_for("  a SHIP that never came home ") == "The sea is yours." and call_for("My own theme") == FLOOR
