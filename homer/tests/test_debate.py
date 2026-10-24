import asyncio
import dataclasses
import json
import random

import httpx2
import pytest
from fakes import FakeClient
from fastapi.testclient import TestClient

from homer import debate, events, server
from homer.arena import Arena
from homer.config import settings
from homer.host import Host, Verse
from homer.judge import EmptyVerse, Judge, Turn, output_schema, sentences
from homer.scanner import TimedWord
from homer.stdb import Stdb

CFG = dataclasses.replace(settings(), judge_model="claude-opus-5-5", model="claude-opus-5-5", judge_timeout=5.0,
                          timeout=5.0, stdb_url="http://stdb.test", stdb_token="tok")
ASK = "If you could turn invisible, would you stay honest?"
ARGUMENT = ("No. Honesty is mostly fear of getting caught. Take away the witness and the fear goes with it. "
            "What about the ring of Gyges? Every man who wore it stole.")
PREVIOUS = "Yes. Honesty is who you are, not who is watching."


def run(c):
    return asyncio.run(c)


# ----- Content -----------------------------------------------------------------


def test_content_parses():
    qs = debate.questions()
    assert len(qs) == 22 and qs[0].ask == ASK and qs[0].side(0) == "Yes" and qs[0].side(1) == "No"
    assert debate.question("ship").side(1) == "New ship"
    assert debate.question(f'"{ASK}"').id == "invisible"
    ms = debate.moves()
    assert len(ms) == 40 and all(m.template for m in ms)
    assert {m.role for m in ms} == set(debate.ROLES)
    assert debate.move("counterexample").template == "What about {case}?"
    assert debate.lines()["shared"]["Go"] == "Go."
    assert debate.lines()["battle"]["Verdict, a sample 2"].startswith("Three reasons")


def test_a_hand_has_every_role():
    for seed in range(20):
        hand = debate.deal(rng=random.Random(seed))
        assert len(hand) == 5 and {m.role for m in hand} == set(debate.ROLES)
    held = [m.text for m in debate.deal(n=8, rng=random.Random(1))]
    assert not set(held) & {m.text for m in debate.deal(n=8, exclude=held, rng=random.Random(2))}


# ----- Poise ------------------------------------------------------------------


def timed(text, gap_after=None, wps=2.5):
    """Words at a steady pace; gap_after={index: ms} inserts silences."""
    out, t = [], 0.0
    for i, w in enumerate(text.split()):
        dur = 1000 / wps * 0.8
        out.append(TimedWord(w, t, t + dur))
        t += 1000 / wps + (gap_after or {}).get(i, 0)
    return out


def test_steady_clean_delivery_keeps_its_poise():
    text = " ".join([ARGUMENT] * 3)
    d = debate.poise(text, timed(text))
    assert d.fillers == [] and 120 <= d.wpm <= 180 and d.dead_air == 0 and d.poise == 10


def test_fillers_dead_air_and_rescues_cost_poise():
    text = "Um, so, like, honesty is, uh, you know, hard. " * 4
    d = debate.poise(text, timed(text, {5: 2500, 12: 3000}), rescues=1)
    assert len(d.fillers) >= 8 and d.dead_air == 3 and d.longest_silence_ms >= 3000
    assert d.poise <= 4


def test_poise_without_timings_uses_the_turn_length():
    short = debate.poise("Yes. Because.", turn_seconds=45)
    full = debate.poise(" ".join([ARGUMENT] * 4), turn_seconds=45)
    assert short.poise < full.poise and full.wpm is not None


# ----- The rescue -----------------------------------------------------------------


def test_template_whispers_fill_from_the_last_speaker():
    q = debate.question("invisible")
    assert debate.template_whisper(debate.move("ask-for-a-definition"), q, PREVIOUS) == "What do you mean by honesty?"
    first = debate.template_whisper(debate.move("counterexample"), q)
    assert first.startswith("What about ") and "would you" not in first


def test_rescue_raises_the_right_role():
    hand = [m.text for m in debate.deal(rng=random.Random(4))]
    assert debate.rescue_move(hand, elapsed_s=3).role == "open"
    assert debate.rescue_move(hand, elapsed_s=10, previous=PREVIOUS).role == "attack"
    assert debate.rescue_move(hand, elapsed_s=40).role == "close"
    assert debate.rescue_move(hand, played=hand) is None


# ----- The judge ------------------------------------------------------------------


REPLY = {"fit": True, "verdict": "You tapped counterexample and gave me Gyges. Fair.",
         "best_line": "Take away the witness and the fear goes with it.", "claim": 7, "reason": 6, "answer": 5,
         "craft": 6, "made": ["counterexample", "stake-your-claim", "not-a-move", "counterexample"]}
HAND = ["stake your claim", "counterexample", "ask for proof", "concede and pivot", "sum it up"]


def judge(reply=REPLY, **kw):
    return Judge(client=FakeClient(reply, **kw), cfg=CFG)


def turn(**kw):
    base = dict(transcript=ARGUMENT, event="debate", mode="battle", theme=ASK, side="No", hand=HAND,
                played=["counterexample", "ask for proof"], previous=PREVIOUS, turn_seconds=45)
    return Turn(**{**base, **kw})


def test_schema_has_the_debate_axes_and_moves_and_no_hoard():
    props = list(output_schema(events.DEBATE)["properties"])
    assert props == ["fit", "verdict", "best_line", "claim", "reason", "answer", "craft", "made"]


def test_debate_judgment():
    j = judge()
    out = run(j.judge(turn()))
    assert list(out.scores) == ["claim", "reason", "answer", "craft", "poise"]
    assert out.scores["claim"] == 7 and 1 <= out.scores["poise"] <= 10 and out.delivery.poise == out.scores["poise"]
    assert out.made == ["counterexample", "stake-your-claim"]  # unknown ids dropped, repeats folded
    assert out.tapped_unmade == ["ask-for-proof"]  # tapped, never made: no Craft for it
    assert out.best_line == "Take away the witness and the fear goes with it."
    assert out.coined == "" and out.scan is None
    sent = j.client.calls[0]
    assert sent["system"][0]["text"].startswith("# Who you are\n\nYou are Socrates")
    content = sent["messages"][0]["content"]
    for part in (f"question: {ASK}", "side: No", "- counterexample (attack): What about {case}?",
                 "tapped: counterexample, ask-for-proof", "<previous_turn>\n" + PREVIOUS, "<delivery>", "<argument>"):
        assert part in content


def test_debate_judge_silent_and_empty():
    out = run(judge(delay=0.05, chunk=2).__class__(client=FakeClient(REPLY, delay=0.05, chunk=2),
                                                    cfg=dataclasses.replace(CFG, judge_timeout=0.2)).judge(turn()))
    assert out.silent and out.scores["claim"] == 0 and out.scores["poise"] >= 1
    assert out.best_line in sentences(ARGUMENT)
    with pytest.raises(EmptyVerse):
        run(judge().judge(turn(transcript="  ")))


# ----- Socrates' other jobs ---------------------------------------------------------


def host(*replies):
    return Host(client=FakeClient(list(replies)), cfg=CFG)


def test_whispers_keep_templates_unless_claude_does_better():
    h = host({"whispers": [{"id": "ask-for-proof", "text": "How do you know honesty is fear?"},
                           {"id": "counterexample", "text": "What about the saint who lies to save a life, and then confesses?"},
                           {"id": "sum-it-up", "text": "Say it plainly."}]})
    out = run(h.whispers(ASK, "No", HAND, PREVIOUS))
    assert set(out) == {"stake-your-claim", "counterexample", "ask-for-proof", "concede-and-pivot", "sum-it-up"}
    assert out["ask-for-proof"] == "How do you know honesty is fear?"
    assert out["counterexample"].startswith("What about ") and len(out["counterexample"].split()) <= 10  # too long: template
    assert out["sum-it-up"] == debate.move("sum-it-up").template  # not a question: template
    assert h.client.calls[0]["system"][0]["text"].count("You are Socrates") == 1


A = Verse(1, "Ada", ARGUMENT, 31, "Take away the witness and the fear goes with it.")
B = Verse(2, "Bo", PREVIOUS, 25, "Honesty is who you are, not who is watching.")


def test_last_question_quotes_a_real_point_then_asks():
    h = host({"quote_turn": 1, "quote": "Take away the witness and the fear goes with it.",
              "question": "Then who is honest when nobody is watching?"})
    assert run(h.last_question([A, B], [ASK])) == [
        (1, "Take away the witness and the fear goes with it."), (1, "Then who is honest when nobody is watching?")]
    assert run(host({"quote_turn": 1, "quote": "something nobody said", "question": "Why?"}).last_question([A, B], [ASK])) == [
        (1, A.best_line)]


def test_debate_round_verdict_uses_socrates():
    h = host({"verdict": "The round goes to the line that left this room with nothing to say:", "best_turn": 2,
              "best_line": "Honesty is who you are, not who is watching."})
    verdict, turn_id, line = run(h.round_verdict(ASK, [A, B], events.DEBATE))
    assert turn_id == 2 and verdict.endswith(": Honesty is who you are, not who is watching.")
    sent = h.client.calls[0]
    assert "Socrates" in sent["system"][0]["text"] and sent["messages"][0]["content"].startswith(f"question: {ASK}")


def test_spar_debate():
    h = host({"lines": ["Is it fear?", "Or is it habit?", "What would you do with the ring?", "extra"]})
    assert run(h.spar_debate(ASK, "Yes", 3, PREVIOUS)) == ["Is it fear?", "Or is it habit?", "What would you do with the ring?"]


# ----- The arena -------------------------------------------------------------------


class Db:
    def __init__(self, event="debate"):
        self.calls, self.event = [], event

    def handler(self, request):
        if request.url.path.endswith("/sql"):
            q = request.content.decode()
            table = q.split("FROM ")[1].split()[0]
            rows = {
                "room": (["id", "event", "demo"], [[1, self.event, True]]),
                "player": (["id", "room_id", "name", "epithet", "hoard", "seat"], [[10, 1, "Ada", "", [], 0], [20, 1, "Bo", "", [], 1]]),
                "round": (["id", "room_id", "round_no", "theme"], [[5, 1, 1, ASK]]),
                "turn": (["id", "room_id", "round_id", "player_id", "turn_no", "transcript"], [[1, 1, 5, 10, 0, ARGUMENT], [2, 1, 5, 20, 1, PREVIOUS]]),
                "score": (["turn_id", "room_id", "round_id", "total", "best_line"], [[1, 1, 5, 31, A.best_line], [2, 1, 5, 25, B.best_line]]),
            }[table]
            return httpx2.Response(200, json=[{"schema": {"elements": [{"name": {"some": c}} for c in rows[0]]}, "rows": rows[1]}])
        self.calls.append((request.url.path.rsplit("/", 1)[-1], json.loads(request.content)))
        return httpx2.Response(200)


def arena(*replies, event="debate"):
    db = Db(event)
    client = FakeClient(list(replies) or [{}])
    stdb = Stdb(CFG, httpx2.AsyncClient(transport=httpx2.MockTransport(db.handler)))
    return Arena(Judge(client=client, cfg=CFG), stdb, Host(client=client, cfg=CFG)), db


def test_debate_deal_is_a_question_and_moves_with_every_role():
    a, db = arena()
    theme, hands = run(a.deal_round(1, 1, ""))
    assert debate.question(theme) is not None
    reducer, (room, round_no, posted_theme, posted_hands) = db.calls[0]
    assert reducer == "deal_round" and posted_theme == theme
    for _, cards in posted_hands:
        assert len(cards) == 8 and {debate.move(c).role for c in cards[:4]} == set(debate.ROLES)
    theme2, _ = run(a.deal_round(1, 2, "ship"))
    assert theme2 == debate.question("ship").ask


def test_debate_battle_judge_posts_five_axes_in_rubric_order():
    a, db = arena(REPLY)
    a.dealt[10] = HAND
    from homer.arena import BattleTurn

    posted, j = run(a.judge_turn(BattleTurn(turn_id=1, transcript=ARGUMENT, event="debate", theme=ASK, side="No",
                                            played=["counterexample"], previous=PREVIOUS, player_id=10, turn_seconds=45)))
    reducer, args = db.calls[0]
    assert posted == "post_score" and args[1] == [7, 6, 5, 6, j.scores["poise"]] and args[4] == ""


def test_debate_finale_is_the_last_question():
    a, db = arena({"quote_turn": 1, "quote": A.best_line, "question": "Then who is honest when nobody watches?"})
    lines = run(a.song(1))
    assert db.calls == [("post_song", [1, [1, 1], [A.best_line, "Then who is honest when nobody watches?"]])]
    assert len(lines) == 2


# ----- The endpoints ------------------------------------------------------------------


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("HOMER_WARM", "0")
    a, _ = arena({"whispers": [{"id": "counterexample", "text": "What about the ring of Gyges?"}]})
    server._judge, server._arena = a.judge, a
    with TestClient(server.app) as c:
        yield c
    server._judge = server._arena = None


def test_debate_endpoints(client):
    content = client.get("/debate").json()
    assert len(content["questions"]) == 22 and content["questions"][0]["sides"] == ["Yes", "No"]
    assert content["moves"][0]["kind"] == "move" and content["moves"][0]["role"] == "open"
    dealt = client.post("/deal", json={"event": "debate", "theme": "invisible"}).json()
    assert dealt["theme"] == ASK and {c["role"] for c in dealt["hand"]} == set(debate.ROLES)
    w = client.post("/debate/whispers", json={"question": ASK, "side": "No", "hand": HAND, "previous": PREVIOUS}).json()
    assert w["whispers"]["counterexample"] == "What about the ring of Gyges?"
    r = client.post("/rescue", json={"event": "debate", "hand": HAND, "previous": PREVIOUS, "elapsedS": 10,
                                     "whispers": w["whispers"]}).json()
    assert r["card"]["role"] == "attack" and r["whisper"] == w["whispers"][r["card"]["id"]]
    assert client.post("/rescue", json={"event": "debate", "hand": HAND, "played": HAND}).status_code == 409


def test_carved_lines_and_verdicts_are_speakable():
    assert debate.clean_line("Um, if the only thing keeping you honest is a witness, uh, you were careful.") == \
        "If the only thing keeping you honest is a witness, you were careful."
    assert debate.plain_moves("You tapped ask-for-proof and never asked.") == "You tapped ask for proof and never asked."


def test_pace_uses_the_spoken_time_when_the_turn_ended_early():
    text = " ".join([ARGUMENT] * 2)  # ~55 words
    full = debate.poise(text, turn_seconds=45)
    early = debate.poise(text, turn_seconds=45, spoken_seconds=22)
    assert early.wpm > full.wpm and early.wpm == pytest.approx(len(text.split()) / 22 * 60, rel=0.05)
