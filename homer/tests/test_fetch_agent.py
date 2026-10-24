import asyncio
import json
from types import SimpleNamespace

import httpx2
import pytest

from homer.fetch_agent import HELP, Rounds, hand_reply, intent, judge_text, on_chat, parse, reply, respond

CARD = {
    "scores": {"beat": 10, "craft": 6, "image": 7, "answer": 5, "range": 6},
    "verdict": "Salt in your teeth, that's a picture.",
    "bestLine": "I stand on the shore with salt in my teeth",
    "coined": "",
    "declined": False,
    "silent": False,
    "scan": {"lines": [{"pattern": "the WINE dark SEA / took my BROTHER'S SHIP"}]},
}


def test_parse_reads_lines_and_an_optional_theme():
    assert parse("hi") is None and parse("   ") is None and parse("help") is None
    req = parse("theme: a ship that never came home\nthe wine dark sea took my brother's ship\nI stand on the shore")
    assert req == {"transcript": "the wine dark sea took my brother's ship\nI stand on the shore",
                   "theme": "a ship that never came home", "mode": "practice", "linesExpected": 2}
    assert parse("theme: the sea") is None  # a theme and no verse: that's a deal
    assert len(parse("\n".join(f"line {i}" for i in range(20)))["transcript"].splitlines()) == 8


def test_reply_reads_like_homer():
    text = reply(CARD)
    assert text.startswith("Salt in your teeth, that's a picture.\n\nBeat 10 · Craft 6 · Image 7 · Answer 5 · Range 6 (34 of 50)")
    assert "Best line: \"I stand on the shore with salt in my teeth\"" in text and "the WINE dark SEA" in text
    assert reply({**CARD, "declined": True}) == "Not in my hall. Give me another."
    assert reply({**CARD, "silent": True, "verdict": ""}).startswith("Homer is silent on this one.")


def service(status=200, body=None, seen=None):
    def handler(request):
        if seen is not None:
            seen.append(request)
        return httpx2.Response(status, json=body if body is not None else CARD)

    return httpx2.AsyncClient(transport=httpx2.MockTransport(handler))


def test_judge_text_round_trip_sends_the_app_key():
    seen = []
    out = asyncio.run(judge_text("the wine dark sea took my brother's ship", service(seen=seen), "http://homer:8000", "k3y"))
    assert out.startswith(reply(CARD)) and out.endswith('Say "give me a theme" for another round.')
    assert seen[0].url.path == "/judge" and seen[0].headers["x-homer-key"] == "k3y"
    assert json.loads(seen[0].content)["mode"] == "practice"


def test_judge_text_failures_are_said_plainly():
    base = "http://homer:8000"
    assert asyncio.run(judge_text("hello", service(), base)) == HELP
    assert asyncio.run(judge_text("a verse", service(429, {}), base)).startswith("Too many verses")
    assert asyncio.run(judge_text("a verse", service(500, {}), base)).startswith("Homer is away")

    def down(request):
        raise httpx2.ConnectError("refused", request=request)

    assert asyncio.run(judge_text("a verse", httpx2.AsyncClient(transport=httpx2.MockTransport(down)), base)).startswith("Homer is away")


def test_on_chat_acknowledges_answers_once_and_ends_the_session():
    from uagents_core.contrib.protocols.chat import ChatAcknowledgement, ChatMessage, EndSessionContent, TextContent

    sent = []

    class Ctx:
        async def send(self, to, message):
            sent.append((to, message))

    msg = ChatMessage(content=[TextContent(type="text", text="the wine dark sea took my brother's ship")])
    asyncio.run(on_chat(Ctx(), "agent1qsender", msg, service(), "http://homer:8000", ""))
    (to1, ack), (to2, answer) = sent
    assert to1 == to2 == "agent1qsender"
    assert isinstance(ack, ChatAcknowledgement) and ack.acknowledged_msg_id == msg.msg_id
    assert isinstance(answer, ChatMessage)
    assert isinstance(answer.content[0], TextContent) and answer.content[0].text.startswith(reply(CARD))
    assert isinstance(answer.content[1], EndSessionContent)  # a judged verse ends the round


@pytest.mark.filterwarnings("ignore:coroutine 'Agent.publish_manifest' was never awaited")  # never run: no network in tests
def test_the_agent_builds_with_the_chat_protocol():
    pytest.importorskip("uagents")
    from homer.fetch_agent import build_agent

    loop = asyncio.new_event_loop()  # uagents reads the current loop, as `python -m homer.fetch_agent` has one
    asyncio.set_event_loop(loop)
    try:
        agent = build_agent("homer test seed phrase not for production use", "http://homer:8000", port=8761)
        assert agent.address.startswith("agent1")
        assert [(p.name, p.version) for p in agent.protocols.values()] == [("AgentChatProtocol", "0.3.0")]
    finally:
        asyncio.set_event_loop(None)
        loop.close()


# ----- The two-step round: deal, then judge against the hand -------------------------

DEALT = {"theme": "The last train out", "hand": [
    {"id": "whale-road", "text": "the whale-road", "kind": "kenning", "beats": 1},
    {"id": "when-dawn-came-early", "text": "when Dawn came early", "kind": "half_line", "beats": 2},
]}


def test_intents():
    assert intent("hi")[0] == "help" and intent("")[0] == "help"
    for ask in ("give me a theme", "Give me another theme!", "deal me in", "new round", "theme", "let's play"):
        assert intent(ask) == ("deal", {"theme": ""}), ask
    assert intent("theme: the last train out") == ("deal", {"theme": "the last train out"})
    kind, req = intent("the train pulled out\nI missed my stop")
    assert kind == "judge" and req["linesExpected"] == 2


def router(seen):
    def handler(request):
        seen.append((request.url.path, json.loads(request.content)))
        return httpx2.Response(200, json=DEALT if request.url.path == "/deal" else CARD)

    return httpx2.AsyncClient(transport=httpx2.MockTransport(handler))


def test_a_round_deals_then_judges_against_the_hand():
    seen, rounds = [], Rounds()
    http = router(seen)
    answer, over = asyncio.run(respond("give me a theme", http, "http://homer:8000", rounds=rounds, conversation="asi:1"))
    assert not over and answer == hand_reply(DEALT)
    assert "1. the whale-road (one hit)" in answer and "2. when Dawn came early (half a line)" in answer
    answer, over = asyncio.run(respond("the train pulled out\nI missed my stop", http, "http://homer:8000",
                                       rounds=rounds, conversation="asi:1"))
    assert over and answer.startswith(reply(CARD))
    path, body = seen[-1]
    assert path == "/judge" and body["theme"] == "The last train out" and body["hand"] == ["the whale-road", "when Dawn came early"]


def test_rounds_belong_to_their_conversation_and_expire():
    seen, rounds = [], Rounds()
    http = router(seen)
    asyncio.run(respond("give me a theme", http, "http://homer:8000", rounds=rounds, conversation="asi:1"))
    asyncio.run(respond("a verse of mine\nand another line", http, "http://homer:8000", rounds=rounds, conversation="asi:2"))
    assert "hand" not in seen[-1][1]  # another user's conversation gets no hand
    old = Rounds(ttl_s=-1)
    old.put("x", {"theme": "t", "hand": []})
    assert old.take("x") is None
    capped = Rounds(cap=2)
    for k in "abc":
        capped.put(k, {"theme": k, "hand": []})
    assert capped.take("a") is None and capped.take("c")["theme"] == "c"
