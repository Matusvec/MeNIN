"""Battle engine: the app-side referee bookkeeping around Homer.

Fairness is enforced here in code, not left to the model:
- entries are shuffled with a seeded RNG and shown to Homer under neutral labels;
- totals and round winners are computed from Homer's recorded scores, and a
  declared winner that disagrees with the scores is sent back for correction;
- late, missing, and ineligible submissions are handled before Homer sees them.
"""

from __future__ import annotations

import random
import string
from dataclasses import dataclass, field
from typing import Any

from .agent import HomerAgent, HomerReply
from .prompts import app_state_block, wrap_entry
from .state import Mode, Session
from .tools import ROUND_PENALTY_OFF_THEME, ToolInputError, entry_total, validate_round


class BattleError(RuntimeError):
    """An app-level misuse, such as closing a round that is not open."""


@dataclass
class BattleConfig:
    players: list[str]
    rounds: int = 2
    lines_per_round: int = 4
    meter: str = "iambic pentameter"
    themes: list[str] = field(default_factory=list)  # optional required theme per round
    seed: int | None = None

    def validate(self) -> None:
        if len(self.players) < 2:
            raise BattleError("a battle needs at least 2 players")
        if len({p.casefold() for p in self.players}) != len(self.players):
            raise BattleError("player names must be unique")
        if self.rounds < 1 or self.lines_per_round < 1:
            raise BattleError("rounds and lines_per_round must be at least 1")


@dataclass
class Round:
    number: int
    players: list[str]
    tiebreak: bool = False
    theme: str | None = None
    constraint: str | None = None
    submissions: dict[str, str] = field(default_factory=dict)
    open: bool = False
    labels: dict[str, str] = field(default_factory=dict)  # label -> player
    record: dict[str, Any] | None = None
    points: dict[str, int] = field(default_factory=dict)
    winners: list[str] = field(default_factory=list)


@dataclass
class SubmitResult:
    accepted: bool
    message: str


class Battle:
    def __init__(self, config: BattleConfig, agent: HomerAgent) -> None:
        config.validate()
        self.config = config
        self.agent = agent
        self.session = Session(Mode.BATTLE)
        self.rng = random.Random(config.seed)
        self.rounds: list[Round] = []
        self.phase = "setup"  # setup -> collecting -> judged -> ... -> finished
        self.champion: str | None = None

    # ----- Public API --------------------------------------------------------

    @property
    def current(self) -> Round | None:
        return self.rounds[-1] if self.rounds else None

    def standings(self) -> dict[str, int]:
        totals = {p: 0 for p in self.config.players}
        for rnd in self.rounds:
            if not rnd.tiebreak:
                for player, pts in rnd.points.items():
                    totals[player] += pts
        return totals

    def start(self) -> HomerReply:
        if self.phase != "setup":
            raise BattleError("battle already started")
        pending = Round(number=1, players=list(self.config.players))
        msg = "The battle begins. Announce the players, rounds and rules, then set round 1 with announce_round."
        return self._announce(pending, msg)

    def submit(self, player: str, verse: str) -> SubmitResult:
        rnd = self.current
        name = self._canonical(player)
        if name is None:
            return SubmitResult(False, f"{player} is not a player in this battle.")
        if rnd is None or not rnd.open:
            return SubmitResult(False, f"Too late, {name}: no round is open for submissions.")
        if name not in rnd.players:
            return SubmitResult(False, f"{name} is not part of this tiebreaker.")
        if not verse.strip():
            return SubmitResult(False, "An empty verse cannot be entered.")
        replaced = name in rnd.submissions
        rnd.submissions[name] = verse.strip()
        return SubmitResult(True, f"{name}'s verse {'replaced' if replaced else 'received'} for round {rnd.number}.")

    def close_round(self) -> HomerReply:
        rnd = self.current
        if rnd is None or not rnd.open:
            raise BattleError("no round is open")
        rnd.open = False
        missing = [p for p in rnd.players if p not in rnd.submissions]

        if not rnd.submissions:
            rnd.points = {p: 0 for p in rnd.players}
            self.phase = "judged"
            return HomerReply(text=f"Round {rnd.number} is void: no verses were submitted.", data={"round": self._round_data(rnd)})

        entrants = sorted(rnd.submissions)
        self.rng.shuffle(entrants)
        rnd.labels = {string.ascii_uppercase[i]: p for i, p in enumerate(entrants)}
        labels = list(rnd.labels)

        def record_round(inp: dict[str, Any]) -> str:
            validate_round(inp, labels)
            rnd.record = inp
            return "Recorded. Now write the round report, referring to entries by label only."

        def announce_round(_: dict[str, Any]) -> str:
            raise ToolInputError("Judge this round first; the next round is announced later.")

        line_counts = ", ".join(
            f"{label}: {len([l for l in rnd.submissions[p].splitlines() if l.strip()])} line(s)" for label, p in rnd.labels.items()
        )
        state = self._state(rnd) + [
            f"entries: {len(labels)} ({line_counts}); required lines per entry: {self.config.lines_per_round}",
            f"players without an entry: {len(missing)} (the app scores them 0)",
            "Judge the entries below blind. Call record_round, then write the round report.",
        ]
        entries = "\n\n".join(wrap_entry(label, rnd.submissions[p]) for label, p in rnd.labels.items())
        reply = self.agent.respond(
            self.session,
            f"{app_state_block(state)}\n\n{entries}",
            handlers={"record_round": record_round, "announce_round": announce_round},
            required_tools={"record_round"},
        )
        if rnd.record is None:
            raise BattleError("Homer did not record scores for this round; call close_round again to retry")

        by_label = {e["label"]: e for e in rnd.record["entries"]}
        rnd.points = {p: entry_total(by_label[label]) for label, p in rnd.labels.items()}
        rnd.points.update({p: 0 for p in missing})
        rnd.winners = sorted(rnd.labels[label] for label in rnd.record["winner_labels"])
        self.phase = "judged"

        reply.text = f"{reply.text}\n\n{self._reveal(rnd, missing)}".strip()
        reply.data["round"] = self._round_data(rnd)
        return reply

    def next_round(self) -> HomerReply:
        rnd = self.current
        if self.phase != "judged" or rnd is None or rnd.tiebreak:
            raise BattleError("the current round has not been judged")
        if rnd.number >= self.config.rounds:
            raise BattleError("all rounds are done; call finish()")
        pending = Round(number=rnd.number + 1, players=list(self.config.players))
        msg = f"Comment briefly on the standings by name, then set round {pending.number} with announce_round."
        return self._announce(pending, msg)

    def finish(self) -> HomerReply:
        rnd = self.current
        if self.phase != "judged" or rnd is None:
            raise BattleError("the current round has not been judged")
        main_rounds = [r for r in self.rounds if not r.tiebreak]
        if len(main_rounds) < self.config.rounds:
            raise BattleError("not all rounds have been played")

        totals = self.standings()
        best = max(totals.values())
        leaders = sorted(p for p, t in totals.items() if t == best)
        if rnd.tiebreak and rnd.winners:
            leaders = [p for p in leaders if p in rnd.winners]

        if len(leaders) > 1:
            pending = Round(number=rnd.number + 1, players=leaders, tiebreak=True)
            msg = (
                f"The championship is tied between {' and '.join(leaders)} on {best} points. "
                f"Set a tiebreaker challenge for them alone with announce_round (round_number {pending.number})."
            )
            reply = self._announce(pending, msg)
            reply.data["tie"] = leaders
            return reply

        self.champion = leaders[0]
        self.phase = "finished"
        table = "; ".join(f"{p}: {t}" for p, t in sorted(totals.items(), key=lambda kv: -kv[1]))
        msg = (
            f"The battle is over. Final standings: {table}. Champion: {self.champion}. "
            "Crown the champion with a short epic proclamation and give every player one sincere compliment."
        )
        reply = self.agent.respond(self.session, f"{app_state_block(self._state(None) + [msg])}")
        reply.data.update(champion=self.champion, standings=totals)
        return reply

    # ----- Internals ---------------------------------------------------------

    def _announce(self, pending: Round, instruction: str) -> HomerReply:
        required_theme = self._required_theme(pending)

        def announce_round(inp: dict[str, Any]) -> str:
            if inp["round_number"] != pending.number:
                raise ToolInputError(f"This is round {pending.number}, not {inp['round_number']}.")
            if required_theme and inp["theme"].strip().casefold() != required_theme.casefold():
                raise ToolInputError(f"Round {pending.number} has a required theme: {required_theme!r}. Use it exactly.")
            pending.theme, pending.constraint = inp["theme"], inp["constraint"]
            return f"Round {pending.number} is open for submissions."

        state = self._state(pending) + [instruction]
        if required_theme:
            state.append(f"required theme for round {pending.number}: {required_theme}")
        reply = self.agent.respond(
            self.session,
            app_state_block(state),
            handlers={"announce_round": announce_round},
            required_tools={"announce_round"},
        )
        if pending.theme is None:
            raise BattleError("Homer did not announce the round; try again")
        pending.open = True
        self.rounds.append(pending)
        self.phase = "collecting"
        reply.data["round"] = {"number": pending.number, "theme": pending.theme, "constraint": pending.constraint, "players": pending.players, "tiebreak": pending.tiebreak}
        return reply

    def _required_theme(self, rnd: Round) -> str | None:
        if rnd.tiebreak or rnd.number > len(self.config.themes):
            return None
        return self.config.themes[rnd.number - 1]

    def _state(self, rnd: Round | None) -> list[str]:
        cfg = self.config
        lines = [
            f"players: {', '.join(cfg.players)}",
            f"rules: {cfg.rounds} round(s); {cfg.lines_per_round} line(s) of {cfg.meter} per entry; "
            f"scores are the four rubric scores summed (4-40), off-theme entries lose {ROUND_PENALTY_OFF_THEME}, "
            "disqualified or missing entries score 0; highest total over all rounds wins",
            f"standings: {', '.join(f'{p} {t}' for p, t in self.standings().items())}",
        ]
        if rnd is not None:
            kind = "tiebreaker" if rnd.tiebreak else f"of {cfg.rounds}"
            lines.append(f"round: {rnd.number} {kind}")
            if rnd.theme:
                lines.append(f"theme: {rnd.theme}; constraint: {rnd.constraint}")
        return lines

    def _reveal(self, rnd: Round, missing: list[str]) -> str:
        parts = [f"Entry {label}: {p} ({rnd.points[p]} pts)" for label, p in rnd.labels.items()]
        text = f"**Revealed.** {' · '.join(parts)}. Round {rnd.number} to {' and '.join(rnd.winners)}."
        if missing:
            text += f" No entry from {', '.join(missing)} (0 pts)."
        return text

    def _round_data(self, rnd: Round) -> dict[str, Any]:
        return {
            "number": rnd.number,
            "tiebreak": rnd.tiebreak,
            "theme": rnd.theme,
            "constraint": rnd.constraint,
            "labels": rnd.labels,
            "record": rnd.record,
            "points": rnd.points,
            "winners": rnd.winners,
            "standings": self.standings(),
        }

    def _canonical(self, player: str) -> str | None:
        for p in self.config.players:
            if p.casefold() == player.strip().casefold():
                return p
        return None
