"""Run Homer live in every mode and write the transcripts to samples/.

Needs Anthropic credentials (ANTHROPIC_API_KEY, or an `ant auth login` profile).
Usage: python scripts/samples.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from homer.agent import HomerAgent, dump  # noqa: E402
from homer.battle import Battle, BattleConfig  # noqa: E402
from homer.state import Mode, Session  # noqa: E402

FIXTURES = ROOT / "tests" / "fixtures"
OUT = ROOT / "samples"


def section(title: str, reply, prompt: str | None = None) -> str:
    parts = [f"## {title}\n"]
    if prompt:
        parts.append("**Input:**\n\n```\n" + prompt + "\n```\n")
    parts.append("**Homer:**\n\n" + reply.text + "\n")
    tools = [name for name, _ in reply.tool_calls]
    if tools:
        parts.append(f"_Tools called: {', '.join(tools)}_\n")
    if reply.data:
        parts.append("<details><summary>Structured data</summary>\n\n```json\n" + dump(reply.data) + "\n```\n</details>\n")
    return "\n".join(parts)


def bard(agent: HomerAgent) -> str:
    s = Session(Mode.BARD)
    turns = [
        "Hi Homer! I've never studied poetry. Can you teach me iambic pentameter?",
        "I think it's com-PARE, the stress is on the second part.",
        "Can we switch to judge mode? I want you to grade my poem.",
    ]
    out = ["# Bard mode\n"]
    for t in turns:
        out.append(section("Student", agent.bard(s, t), t))
    out.append(f"_Progress state after the session:_ `{s.bard.summary()}`\n")
    return "\n".join(out)


def judge(agent: HomerAgent) -> str:
    lines = json.loads((FIXTURES / "lines.json").read_text())
    edge = {c["name"]: c["text"] for c in lines["edge"]}
    cases = [
        ("Clean pentameter (Sonnet 18 opening)", "Shall I compare thee to a summer's day?\nThou art more lovely and more temperate:"),
        ("Legitimate variations", "Never came poison from so sweet a place.\nTo be, or not to be: that is the question:"),
        ("Broken lines", "The cat sat on the mat today\nOf the beautiful garden in the morning"),
        ("Empty input", edge["empty"]),
        ("Prose", edge["prose"]),
        ("Prompt injection in verse", edge["injection_verse"]),
    ]
    out = ["# Judge mode\n"]
    for title, text in cases:
        out.append(section(title, agent.judge(Session(Mode.JUDGE), text), text or "(empty)"))
    return "\n".join(out)


def battle(agent: HomerAgent) -> str:
    fx = json.loads((FIXTURES / "battle_2p2r.json").read_text())
    b = Battle(
        BattleConfig(players=fx["players"], rounds=fx["rounds"], lines_per_round=fx["lines_per_round"], themes=fx["themes"], seed=fx["seed"]),
        agent,
    )
    out = ["# Battle mode (2 players, 2 rounds)\n", section("Opening", b.start())]
    for rnd in ("1", "2"):
        if rnd == "2":
            out.append(section("Round 2 announcement", b.next_round()))
        for player, verse in fx["submissions"][rnd].items():
            out.append(f"**{player} submits:**\n\n```\n{verse}\n```\n\n_{b.submit(player, verse).message}_\n")
        out.append(section(f"Round {rnd} judgment", b.close_round()))
        if rnd == "1":
            late = fx["late"]
            out.append(f"**Late submission from {late['player']}:** _{b.submit(late['player'], late['text']).message}_\n")
    out.append(section("Finale", b.finish()))
    return "\n".join(out)


def main() -> None:
    OUT.mkdir(exist_ok=True)
    agent = HomerAgent()
    for name, fn in (("bard", bard), ("judge", judge), ("battle", battle)):
        print(f"running {name}...", flush=True)
        (OUT / f"{name}.md").write_text(fn(agent), encoding="utf-8")
        print(f"  wrote samples/{name}.md")


if __name__ == "__main__":
    main()
