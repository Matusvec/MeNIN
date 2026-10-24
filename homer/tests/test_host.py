import asyncio
import dataclasses
import json

import httpx2
from fakes import FakeClient

from homer.arena import Arena
from homer.config import settings
from homer.host import Host, Verse
from homer.judge import Judge
from homer.stdb import Stdb

CFG = dataclasses.replace(settings(), model="claude-opus-5-5", timeout=5.0, stdb_url="http://stdb.test", stdb_token="tok")

ADA = Verse(1, "Ada, Iron-Hearted", "the wine dark sea took my brother's ship\nI stand on the shore with salt in my teeth", 30,
            "I stand on the shore with salt in my teeth")
BO = Verse(2, "Bo", "you call that a storm, I call it a breeze\nmy ship comes home on the whale road tonight", 33,
           "my ship comes home on the whale road tonight")


def host(*replies):
    return Host(client=FakeClient(list(replies)), cfg=CFG)


def run(c):
    return asyncio.run(c)


# ----- Names -----------------------------------------------------------------


def test_name_poet_keeps_a_fine_name_and_coins_an_epithet():
    h = host({"name": "Matus", "epithet": "Breaker of Deadlines", "coined": True})
    assert run(h.name_poet("Matus", "")) == ("Matus", "Breaker of Deadlines", True)
    sent = h.client.calls[0]
    assert "<name>\nMatus\n</name>" in sent["messages"][0]["content"]
    assert sent["system"][0]["cache_control"]["ttl"] == "1h"


def test_a_coined_epithet_that_misses_the_half_line_gives_way_to_one_that_fills_it():
    h = host({"name": "Ana", "epithet": "Lord of the Endless Respawn", "coined": True,
              "alternatives": ["Breaker of Controllers", "Respawn-Queen"]})
    assert run(h.name_poet("Ana", "")) == ("Ana", "Breaker of Controllers", True)
    kept = host({"name": "Priya", "epithet": "Salt-Tongued", "coined": False, "alternatives": ["Breaker of Waves"]})
    assert run(kept.name_poet("Priya", "Salt-Tongued")) == ("Priya", "Salt-Tongued", False)  # theirs stays, hits or not


def test_name_poet_without_claude_keeps_what_was_typed():
    h = host("not json")
    assert run(h.name_poet("Ada", "Iron-Hearted")) == ("Ada", "Iron-Hearted", False)


# ----- Round verdict ---------------------------------------------------------


def test_round_verdict_carves_a_real_line_and_reads_it():
    h = host({"verdict": "The round goes to Ada, and the line that stung:", "best_turn": 1,
              "best_line": "I stand on the shore with salt in my teeth"})
    assert run(h.round_verdict("the sea", [ADA, BO])) == (
        "The round goes to Ada, and the line that stung: I stand on the shore with salt in my teeth",
        1, "I stand on the shore with salt in my teeth")


def test_a_long_round_call_is_cut_to_one_short_lead_in():
    long = "Bo takes the round with a storm that turned into a breeze and sailed home. Ada fought well."
    h = host({"verdict": long, "best_turn": 2, "best_line": BO.best_line})
    verdict, _, line = run(h.round_verdict("the sea", [ADA, BO]))
    call = verdict[: -len(line) - 1]
    assert call.endswith(":") and len(call.split()) == 12 and verdict.endswith(BO.best_line)


def test_an_invented_line_is_never_carved():
    h = host({"verdict": "Bo.", "best_turn": 1, "best_line": "a line nobody said"})
    _, turn, line = run(h.round_verdict("the sea", [ADA, BO]))
    assert (turn, line) == (2, BO.best_line)  # the top total's own best line


def test_round_verdict_without_claude_falls_back_to_the_top_verse():
    assert run(host("{").round_verdict("the sea", [ADA, BO])) == ("", 2, BO.best_line)


# ----- Song ------------------------------------------------------------------


SONG = {"lines": [
    {"turn": 1, "text": "the wine dark sea took my brother's ship"},
    {"turn": 2, "text": "you call that a storm, I call it a breeze"},
    {"turn": 9, "text": "a line from a turn that never happened"},
    {"turn": 1, "text": "I stand on the shore with salt in my teeth"},
    {"turn": 2, "text": "my ship comes home on the whale road tonight"},
    {"turn": 1, "text": "and the sea kept time"},
]}


def test_song_drops_unknown_turns_and_caps_demo_at_four():
    lines = run(host(SONG).song([ADA, BO], demo=True))
    assert len(lines) == 4 and all(t in (1, 2) for t, _ in lines)
    assert len(run(host(SONG).song([ADA, BO]))) == 5


def test_the_song_request_shows_each_lines_hits():
    h = host(SONG)
    run(h.song([ADA, BO], demo=True))
    sent = h.client.calls[0]["messages"][0]["content"]
    assert '<verse turn="1" poet="Ada, Iron-Hearted" hits="4 4">' in sent and 'hits="' in sent.split("<verse turn=\"2\"")[1]


def test_the_song_drops_fragments_and_prefers_four_hit_lines():
    from homer.host import _on_the_beat
    lines = [(1, "the wine dark sea took my brother's ship"), (2, "the war was long"),
             (1, "the hollow ships came back with no one aboard"), (2, "and the sea kept time"),
             (1, "I stand on the shore with salt in my teeth")]
    assert _on_the_beat(lines, 16) == [lines[0], lines[2], lines[3], lines[4]]  # "the war was long" has two hits
    assert _on_the_beat(lines, 3) == [lines[0], lines[2], lines[4]]  # nearest four wins (ties keep battle order); the close stays
    assert _on_the_beat([(1, "the war was long")], 4) == [(1, "the war was long")]  # nothing else: sing what there is


def test_song_without_claude_uses_the_poets_best_lines():
    assert run(host("x").song([ADA, BO])) == [(1, ADA.best_line), (2, BO.best_line)]


# ----- Spar ------------------------------------------------------------------


GOOD = ["on the wine dark sea our sails were torn", "the storm came down like the wrath of gods"]
WEAK = ["on the wine dark sea our sails were torn", "the cat sat on the mat"]


def test_spar_verse_that_scans_takes_one_call():
    h = host({"lines": GOOD})
    verse, scan = run(h.spar("A storm on the open sea", lines=2))
    assert verse == GOOD and scan.beat == 10 and len(h.client.calls) == 1
    assert "formulas:" in h.client.calls[0]["messages"][0]["content"]


def test_spar_fixes_lines_that_miss_the_beat():
    h = host({"lines": WEAK}, {"lines": GOOD})
    verse, scan = run(h.spar("A storm on the open sea", lines=2, answer_to="you speak like a sparrow"))
    assert verse == GOOD and len(h.client.calls) == 2
    fix = h.client.calls[1]["messages"][0]["content"]
    assert "line 2 has 3 hits" in fix and "<draft>" in fix and "<answer_to>" in fix


def test_spar_strips_notation_and_caps_lines():
    h = host({"lines": ["the WIND was COLD / the WAVES were GREY", "the SEA kept TIME / and SO did I", "extra"]})
    verse, _ = run(h.spar("the sea", lines=2))
    assert verse == ["the wind was cold the waves were grey", "the sea kept time and so did i"]


# ----- Battle flows over SQL -------------------------------------------------


TABLES = {
    "round": (["id", "room_id", "round_no", "theme"], [[5, 1, 1, "A ship that never came home"]]),
    "room": (["id", "demo", "phase"], [[1, True, "round_end"]]),
    "turn": (["id", "room_id", "round_id", "player_id", "turn_no", "transcript", "status"],
             [[2, 1, 5, 20, 1, BO.transcript, "scored"], [1, 1, 5, 10, 0, ADA.transcript, "scored"],
              [3, 1, 5, 30, 2, "", "skipped"]]),
    "score": (["turn_id", "room_id", "round_id", "total", "best_line"],
              [[1, 1, 5, 30, ADA.best_line], [2, 1, 5, 33, BO.best_line]]),
    "player": (["id", "room_id", "name", "epithet", "seat"],
               [[10, 1, "Ada", "Iron-Hearted", 0], [20, 1, "Bo", "", 1], [30, 1, "Cy", "", 2]]),
}


class Db:
    def __init__(self):
        self.calls = []

    def handler(self, request):
        if request.url.path.endswith("/sql"):
            q = request.content.decode()
            table = q.split("FROM ")[1].split()[0]
            cols, rows = TABLES[table]
            if "WHERE id = " in q:
                want = int(q.rsplit("= ", 1)[1])
                rows = [r for r in rows if r[0] == want]
            return httpx2.Response(200, json=[{"schema": {"elements": [{"name": {"some": c}} for c in cols]}, "rows": rows}])
        self.calls.append((request.url.path.rsplit("/", 1)[-1], json.loads(request.content)))
        return httpx2.Response(200)


def arena(*replies):
    db = Db()
    stdb = Stdb(CFG, httpx2.AsyncClient(transport=httpx2.MockTransport(db.handler)))
    client = FakeClient(list(replies))
    return Arena(Judge(client=client, cfg=CFG), stdb, Host(client=client, cfg=CFG)), db


def test_round_verdict_reads_the_round_and_posts_the_carved_line():
    a, db = arena({"verdict": "Bo takes it.", "best_turn": 2, "best_line": BO.best_line})
    spoken = f"Bo takes it: {BO.best_line}"
    assert run(a.round_verdict(5)) == (spoken, 2, BO.best_line)
    assert db.calls == [("post_verdict", [5, spoken, 2, BO.best_line])]
    sent = a.host.client.calls[0]["messages"][0]["content"]
    assert sent.index('turn="1" poet="Ada, Iron-Hearted"') < sent.index('turn="2" poet="Bo"')  # turn order
    assert 'turn="3"' not in sent  # skipped turns aren't verses


def test_song_posts_turn_ids_and_lines_capped_for_demo():
    a, db = arena(SONG)
    lines = run(a.song(1))
    reducer, (room, turn_ids, texts) = db.calls[0]
    assert reducer == "post_song" and room == 1 and len(texts) == 4 == len(turn_ids) == len(lines)


def test_name_poet_reads_the_player_row():
    a, db = arena({"name": "Bo", "epithet": "Storm-Throated", "coined": True})
    assert run(a.name_poet(20)) == ("Bo", "Storm-Throated")
    assert db.calls == [("name_poet", [20, "Bo", "Storm-Throated"])]
