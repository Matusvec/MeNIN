"""Terminal front end. Mode changes happen here, in the app, never in the model."""

from __future__ import annotations

import argparse
import sys

from .agent import HomerAgent, HomerReply, dump
from .battle import Battle, BattleConfig, BattleError
from .state import Mode, Session

HELP = {
    Mode.BARD: "Talk to Homer. /mode <bard|judge|battle> to switch, /json to toggle data, /quit to leave.",
    Mode.JUDGE: "Paste a line or poem; finish with an empty line. /mode, /json, /quit as usual.",
    Mode.BATTLE: (
        "/submit <player> <verse, lines separated by ' / '>  |  /close  |  /next  |  /finish  |  /standings  |  /mode  |  /quit"
    ),
}


def show(reply: HomerReply, as_json: bool) -> None:
    print(f"\nHomer: {reply.text}\n")
    if as_json and reply.data:
        print(dump(reply.data), "\n")


def read_block() -> str:
    lines = []
    while True:
        line = input("... " if lines else "> ")
        if not line.strip():
            return "\n".join(lines)
        lines.append(line)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="homer", description="Homer, the poetry-teaching bard.")
    ap.add_argument("--mode", choices=[m.value for m in Mode], default="bard")
    ap.add_argument("--players", default="Alice,Bob", help="battle: comma-separated player names")
    ap.add_argument("--rounds", type=int, default=2)
    ap.add_argument("--lines", type=int, default=4, help="battle: lines per entry")
    ap.add_argument("--themes", default="", help="battle: optional '|'-separated theme per round")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--json", action="store_true", help="print structured data after each reply")
    args = ap.parse_args(argv)

    agent = HomerAgent()
    mode = Mode(args.mode)
    as_json = args.json

    while True:
        print(f"[{mode.value} mode] {HELP[mode]}")
        try:
            switched = _run_mode(mode, agent, args, as_json)
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        if switched is None:
            return 0
        mode, as_json = switched


def _run_mode(mode: Mode, agent: HomerAgent, args, as_json: bool):
    session = Session(mode)
    battle = None
    if mode is Mode.BATTLE:
        cfg = BattleConfig(
            players=[p.strip() for p in args.players.split(",") if p.strip()],
            rounds=args.rounds,
            lines_per_round=args.lines,
            themes=[t.strip() for t in args.themes.split("|") if t.strip()],
            seed=args.seed,
        )
        battle = Battle(cfg, agent)
        show(battle.start(), as_json)

    while True:
        raw = read_block() if mode is Mode.JUDGE else input("> ")
        cmd, _, rest = raw.strip().partition(" ")
        if cmd == "/quit":
            return None
        if cmd == "/json":
            as_json = not as_json
            print(f"(structured data {'on' if as_json else 'off'})")
            continue
        if cmd == "/mode":
            try:
                return Mode(rest.strip()), as_json
            except ValueError:
                print("Modes: bard, judge, battle")
                continue
        try:
            if mode is Mode.BARD:
                show(agent.bard(session, raw), as_json)
            elif mode is Mode.JUDGE:
                show(agent.judge(session, raw), as_json)
            else:
                _battle_command(battle, cmd, rest, as_json)
        except BattleError as exc:
            print(f"(app) {exc}")


def _battle_command(battle: Battle, cmd: str, rest: str, as_json: bool) -> None:
    if cmd == "/submit":
        player, _, verse = rest.partition(" ")
        print(f"(app) {battle.submit(player, verse.replace(' / ', chr(10))).message}")
    elif cmd == "/close":
        show(battle.close_round(), as_json)
    elif cmd == "/next":
        show(battle.next_round(), as_json)
    elif cmd == "/finish":
        show(battle.finish(), as_json)
    elif cmd == "/standings":
        print(f"(app) {battle.standings()}")
    else:
        print(f"(app) {HELP[Mode.BATTLE]}")


if __name__ == "__main__":
    sys.exit(main())
