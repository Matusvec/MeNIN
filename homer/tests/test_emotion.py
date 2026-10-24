import asyncio
import dataclasses
import json

import httpx2
from fakes import FakeClient

from homer.arena import Arena
from homer.config import settings
from homer.emotion import EMOTIONS, Classifier, lexicon_weights, range_score
from homer.judge import Judge
from homer.stdb import Stdb


def one_hot(emotion, strength=0.9):
    rest = (1 - strength) / (len(EMOTIONS) - 1)
    return {e: strength if e == emotion else rest for e in EMOTIONS}


def test_one_feeling_held_is_narrow():
    assert range_score([one_hot("grief")] * 5) <= 2


def test_a_verse_that_travels_scores_high():
    history = [one_hot("grief"), one_hot("anger"), one_hot("defiance"), one_hot("awe")]
    assert range_score(history) >= 8


def test_range_is_always_one_to_ten():
    assert range_score([]) == 5  # nothing to measure: neutral, never a gift or a penalty
    assert 1 <= range_score([{}]) <= 10
    assert 1 <= range_score([one_hot(e) for e in EMOTIONS] * 3) <= 10


def test_a_classifier_wobbling_between_two_feelings_is_not_range():
    wobble = [one_hot("longing"), one_hot("fear")] * 5  # JZRE: ten samples, longing and fear in turn
    quiet = {e: 0.1 for e in EMOTIONS}  # the samples before any words
    assert range_score([quiet, quiet] + wobble) <= 6


def test_a_verse_that_moves_from_grief_to_anger_to_awe_scores_high():
    arc = [one_hot("grief")] * 4 + [one_hot("anger")] * 4 + [one_hot("awe")] * 4
    assert range_score(arc) >= 8


def test_lexicon_stands_in_without_history():
    assert lexicon_weights("the cat is fine") is None
    w = lexicon_weights("I weep at the grave")
    assert max(w, key=w.get) == "grief"
    assert range_score([], ["I weep at the grave", "but I rise and fight with iron"]) > range_score([], ["I weep at the grave"])


# ----- The live classifier -----------------------------------------------

CFG = dataclasses.replace(settings(), emotion_model="claude-haiku-5-5", stdb_url="http://stdb.test", stdb_token="tok")
GRIEF = {"anger": 0.1, "grief": 0.8, "joy": 0, "awe": 0.1, "tenderness": 0.2, "fear": 0.1, "defiance": 0, "longing": 1.4}


def test_classifier_request_is_haiku_without_thinking_and_reads_the_latest_words():
    c = Classifier(client=FakeClient(GRIEF), cfg=CFG)
    kw = c.request(" ".join(f"w{i}" for i in range(100)), loudness=1.7, pitch=180)
    assert kw["model"] == "claude-haiku-5-5" and kw["thinking"] == {"type": "disabled"}
    assert "fallbacks" not in kw and "speed" not in kw
    content = kw["messages"][0]["content"]
    assert content.startswith("loudness: 1.00\npitch: 180") and "w59" not in content and "w99" in content


def test_classify_clamps_weights_and_skips_silence():
    c = Classifier(client=FakeClient(GRIEF), cfg=CFG)
    w = asyncio.run(c.classify("the grave is cold"))
    assert w["longing"] == 1.0 and w["grief"] == 0.8 and set(w) == set(EMOTIONS)
    assert asyncio.run(c.classify("   ")) is None and len(c.client.calls) == 1


def test_scene_posts_the_eight_weights_in_order_and_keeps_the_sample():
    calls = []

    def handler(request):
        if request.url.path.endswith("/sql"):  # the turn is live
            return httpx2.Response(200, json=[{"schema": {"elements": [{"name": {"some": "id"}}, {"name": {"some": "status"}}]},
                                               "rows": [[7, "speaking"]]}])
        calls.append((request.url.path.rsplit("/", 1)[-1], json.loads(request.content)))
        return httpx2.Response(200)

    client = FakeClient(GRIEF)
    arena = Arena(Judge(client=client, cfg=CFG), Stdb(CFG, httpx2.AsyncClient(transport=httpx2.MockTransport(handler))))
    asyncio.run(arena.scene(7, "the grave is cold", 0.4, 120))
    asyncio.run(arena.scene(7, "the grave is cold and so am I", 0.3, 110))
    assert calls[0] == ("set_scene", [7, 0.1, 0.8, 0, 0.1, 0.2, 0.1, 0, 1.0])
    assert len(arena.history[7]) == 2
