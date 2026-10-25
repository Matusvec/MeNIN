"""Homer on Fetch.ai's Agentverse: a two-step round of improvised verse, inside one ASI:One chat.

1. "Give me a theme" (or "theme: the last train out"): Homer deals a theme and
   five formulas that fit the beat, from the same dealer the game uses.
2. The user answers with a verse using them, and Homer judges it like a battle
   verse, on content: Image, Answer and Craft (x4, x4, x2 = out of 100), the
   best line and a one-line verdict. The hand is remembered per conversation,
   so Craft sees it. Where the stresses fell is shown, but it isn't scored.

(Agent Chat Protocol.)

A sidecar: the service's own image, run as a separate process by the `fetch`
profile in docker-compose.yml. It never judges by itself. It calls this
service's /judge over the compose network with the app key, so chat traffic
shares the per-IP limits and the hourly budget with everything else. It is
off unless that profile is started, and the demo never needs it (SPEC "Not
building").

Env:
    FETCH_AGENT_SEED   the agent's identity on Agentverse; secret, generate once (required)
    HOMER_URL          the service, default http://homer:8000
    HOMER_APP_KEY      sent as X-Homer-Key
    FETCH_AGENT_PORT   default 8001; only for connecting the mailbox once (DEPLOY.md)

    python -m homer.fetch_agent
"""

from __future__ import annotations

import os
import re
import time
from collections import OrderedDict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from uuid import uuid4

import httpx2

from .config import load_env

NAME = "homer-bard"
DESCRIPTION = (
    "Homer, the legendary bard, deals you a theme and five formulas from his world, then judges the verse you "
    "improvise with them like a battle verse: his verdict, Image, Answer and Craft (out of 100) and your best line."
)
README = Path(__file__).resolve().parents[1] / "AGENTVERSE.md"
MAX_LINES, MAX_CHARS = 8, 800
AXES = ("image", "answer", "craft")  # what a battle verse is scored on (content only); the total is the judge's /100

HELP = (
    "I am Homer. I improvised the Iliad out loud, from ready-made phrases that fit the beat. Let's do a round. "
    "Say \"give me a theme\" and I'll deal you five of those phrases. Then answer with two to four lines of your own, "
    "one per line, four hits a line with a breath in the middle, and I'll judge them."
)
THEME_RE = re.compile(r"^\s*theme\s*:\s*(.+)$", re.I)
GREETING_RE = re.compile(r"^\s*(hi|hello|hey|help|start|\?|what can you do\??|how does this work\??)\s*[.!]?\s*$", re.I)
DEAL_RE = re.compile(
    r"^\s*(?:(?:please\s+)?(?:give|deal|get)\s+(?:me\s+)?(?:a\s+|another\s+|new\s+)*(?:theme|hand|round)"
    r"|(?:new|another)\s+(?:theme|hand|round)|theme|deal|deal me in|play|let'?s play)\s*[.!?]*\s*$",
    re.I,
)
STATE_TTL_S, STATE_MAX = 3600, 500


def intent(text: str) -> tuple[str, dict[str, Any] | None]:
    """What a chat message asks for: ("help", None), ("deal", {"theme"}), or ("judge", a /judge request)."""
    text = (text or "").strip()[:MAX_CHARS]
    if not text or GREETING_RE.match(text):
        return "help", None
    if DEAL_RE.match(text):
        return "deal", {"theme": ""}
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    theme = ""
    if lines and (m := THEME_RE.match(lines[0])):
        theme, lines = m.group(1).strip(), lines[1:]
    if not lines:
        return "deal", {"theme": theme}  # "theme: the sea" on its own deals a hand for it
    lines = lines[:MAX_LINES]
    return "judge", {"transcript": "\n".join(lines), "theme": theme, "mode": "practice", "linesExpected": len(lines)}


def parse(text: str) -> dict[str, Any] | None:
    """A chat message as a /judge request, or None when it holds no verse."""
    kind, req = intent(text)
    return req if kind == "judge" else None


class Rounds:
    """The theme and hand dealt in each conversation, so the verse that follows is judged against them."""

    def __init__(self, ttl_s: float = STATE_TTL_S, cap: int = STATE_MAX) -> None:
        self.ttl_s, self.cap = ttl_s, cap
        self._rounds: OrderedDict[str, tuple[float, dict[str, Any]]] = OrderedDict()

    def put(self, key: str, value: dict[str, Any]) -> None:
        self._rounds[key] = (time.monotonic(), value)
        self._rounds.move_to_end(key)
        while len(self._rounds) > self.cap:
            self._rounds.popitem(last=False)

    def take(self, key: str) -> dict[str, Any] | None:
        hit = self._rounds.pop(key, None)
        if hit is None or time.monotonic() - hit[0] > self.ttl_s:
            return None
        return hit[1]


def hand_reply(dealt: dict[str, Any]) -> str:
    """The theme and the hand, read out."""
    cards = dealt.get("hand", [])
    size = {1: "one hit", 2: "two hits"}
    lines = [f"Your theme: {dealt.get('theme', '')}.", "", "Your hand. Each phrase already fits the beat:"]
    lines += [f"{i}. {c['text']} ({'half a line' if c.get('kind') == 'half_line' else size.get(c.get('beats', 2), 'two hits')})"
              for i, c in enumerate(cards, 1)]
    lines += ["", "Now give me two to four lines on the theme, one per line, using at least one of them. "
              "Four hits a line, a breath in the middle."]
    return "\n".join(lines)


def reply(card: dict[str, Any]) -> str:
    """Homer's scorecard as one chat message."""
    if card.get("declined"):
        return "Not in my hall. Give me another."
    s = card.get("scores", {})
    scores = " · ".join(f"{a.capitalize()} {s.get(a, 0)}" for a in AXES)
    head = card.get("verdict") or "Homer is silent on this one."
    out = [head, "", f"{scores} ({card.get('total', 0)} of 100)"]
    if card.get("bestLine"):
        out.append(f"Best line: \"{card['bestLine']}\"")
    lines = [line.get("pattern", "") for line in ((card.get("scan") or {}).get("lines") or [])]
    if lines:
        out += ["", "Where your hits fell:", *lines]
    if card.get("coined"):
        out.append(f"A new formula for your hoard: {card['coined']}")
    return "\n".join(out)


AWAY = "Homer is away from the hall. Try again in a minute."
BUSY = "Too many verses at once. Give me a minute, then try again."


async def _post(http: httpx2.AsyncClient, url: str, body: dict[str, Any], key: str) -> tuple[int, dict[str, Any] | None]:
    headers = {"X-Homer-Key": key} if key else {}
    try:
        res = await http.post(url, json=body, headers=headers, timeout=20.0)
    except httpx2.HTTPError:
        return 0, None
    return res.status_code, (res.json() if res.status_code == 200 else None)


async def respond(text: str, http: httpx2.AsyncClient, base: str, key: str = "", rounds: Rounds | None = None,
                  conversation: str = "") -> tuple[str, bool]:
    """One chat message in, Homer's answer out, and whether the round is over (end the session)."""
    kind, req = intent(text)
    if kind == "help":
        return HELP, False
    if kind == "deal":
        status, dealt = await _post(http, f"{base}/deal", {"theme": req["theme"], "n": 5}, key)
        if dealt is None:
            return (BUSY if status == 429 else AWAY), False
        if rounds is not None:
            rounds.put(conversation, {"theme": dealt["theme"], "hand": [c["text"] for c in dealt["hand"]]})
        return hand_reply(dealt), False
    held = rounds.take(conversation) if rounds is not None else None
    if held:  # the verse answers the hand Homer dealt in this conversation
        req = {**req, "theme": req["theme"] or held["theme"], "hand": held["hand"]}
    status, card = await _post(http, f"{base}/judge", req, key)
    if card is None:
        return {429: BUSY, 422: HELP}.get(status, AWAY), False
    return reply(card) + "\n\nSay \"give me a theme\" for another round.", True


async def judge_text(text: str, http: httpx2.AsyncClient, base: str, key: str = "") -> str:
    """One message, judged on its own (no dealt hand)."""
    return (await respond(text, http, base, key))[0]


# ----- The uAgent ----------------------------------------------------------------


async def on_chat(ctx: Any, sender: str, msg: Any, http: httpx2.AsyncClient, base: str, key: str,
                  rounds: Rounds | None = None) -> None:
    """Acknowledge the message and answer it. A judged verse ends the round, and with it the session."""
    from uagents_core.contrib.protocols.chat import ChatAcknowledgement, ChatMessage, EndSessionContent, TextContent

    await ctx.send(sender, ChatAcknowledgement(timestamp=datetime.now(timezone.utc), acknowledged_msg_id=msg.msg_id))
    text = "".join(item.text for item in msg.content if isinstance(item, TextContent))
    conversation = f"{sender}:{getattr(ctx, 'session', '') or ''}"  # ASI:One relays many users from one address
    answer, over = await respond(text, http, base, key, rounds, conversation)
    content: list[Any] = [TextContent(type="text", text=answer)]
    if over:
        content.append(EndSessionContent(type="end-session"))
    await ctx.send(sender, ChatMessage(timestamp=datetime.now(timezone.utc), msg_id=uuid4(), content=content))


def build_agent(seed: str, base: str, key: str = "", port: int = 8001) -> Any:
    from uagents import Agent, Context, Protocol
    from uagents_core.contrib.protocols.chat import ChatAcknowledgement, ChatMessage, chat_protocol_spec

    agent = Agent(
        name=NAME,
        seed=seed,
        port=port,
        mailbox=True,  # Agentverse relays messages; no public endpoint needed
        publish_agent_details=True,
        description=DESCRIPTION,
        readme_path=str(README) if README.is_file() else None,
    )
    protocol = Protocol(spec=chat_protocol_spec)
    http = httpx2.AsyncClient()
    rounds = Rounds()

    @protocol.on_message(ChatMessage)
    async def handle_message(ctx: Context, sender: str, msg: ChatMessage) -> None:
        await on_chat(ctx, sender, msg, http, base, key, rounds)

    @protocol.on_message(ChatAcknowledgement)
    async def handle_ack(ctx: Context, sender: str, msg: ChatAcknowledgement) -> None:
        pass  # Homer doesn't need read receipts

    agent.include(protocol, publish_manifest=True)
    return agent


def main() -> None:
    load_env()
    seed = os.environ.get("FETCH_AGENT_SEED", "").strip()
    if not seed:
        raise SystemExit("FETCH_AGENT_SEED is not set: the agent needs a fixed identity (see .env.example)")
    base = os.environ.get("HOMER_URL", "http://homer:8000").rstrip("/")
    agent = build_agent(seed, base, os.environ.get("HOMER_APP_KEY", ""), int(os.environ.get("FETCH_AGENT_PORT", "8001")))
    agent.run()


if __name__ == "__main__":
    main()
