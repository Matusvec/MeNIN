"""Offline stand-ins for the Anthropic client, shaped like `client.beta.messages.create`."""

from __future__ import annotations

import itertools
import json
import re
from types import SimpleNamespace
from typing import Any, Callable

from homer.scansion import scan_poem

_ids = itertools.count(1)


def text(t: str) -> SimpleNamespace:
    return SimpleNamespace(type="text", text=t)


def tool(name: str, inp: dict[str, Any]) -> SimpleNamespace:
    return SimpleNamespace(type="tool_use", id=f"toolu_{next(_ids)}", name=name, input=inp)


def response(*blocks: SimpleNamespace, stop_reason: str | None = None) -> SimpleNamespace:
    if stop_reason is None:
        stop_reason = "tool_use" if any(b.type == "tool_use" for b in blocks) else "end_turn"
    return SimpleNamespace(content=list(blocks), stop_reason=stop_reason)


class FakeClient:
    """Replays a script. Each item is a response, or a callable(kwargs) -> response."""

    def __init__(self, script: list[Any] | Callable[[dict], SimpleNamespace]):
        self.script = script
        self.calls: list[dict[str, Any]] = []
        self.beta = SimpleNamespace(messages=SimpleNamespace(create=self._create))

    def _create(self, **kwargs: Any) -> SimpleNamespace:
        # Snapshot messages: the agent keeps appending to the same list.
        self.calls.append({**kwargs, "messages": list(kwargs["messages"])})
        if callable(self.script):
            return self.script(kwargs)
        item = self.script.pop(0)
        return item(kwargs) if callable(item) else item


def last_tool_results(kwargs: dict) -> list[dict]:
    content = kwargs["messages"][-1]["content"]
    return content if isinstance(content, list) else []


ENTRY_RE = re.compile(r'<entry label="([A-Z])">\n(.*?)\n</entry>', re.S)


class ScriptedHomer:
    """A deterministic fake Homer for battle simulations.

    It really calls scan_poem through the agent, scores each entry from the
    scansion (so better meter wins), and responds to the app's phase prompts.
    """

    def __init__(self, themes: list[str]):
        self.themes = themes
        self.pending_text = ""
        self.seen_entries: list[str] = []

    def __call__(self, kwargs: dict) -> SimpleNamespace:
        last = kwargs["messages"][-1]["content"]
        if isinstance(last, list):  # tool results came back
            if any(r.get("is_error") for r in last):
                raise AssertionError(f"unexpected tool error: {last}")
            if any(json.loads(r["content"]).get("line_count") is not None for r in last if r["content"].startswith("{")):
                return self._record()
            return response(text(self.pending_text))
        if "<entry" in last:
            self.entries = ENTRY_RE.findall(last)
            self.seen_entries.append(last)
            return response(*(tool("scan_poem", {"text": t}) for _, t in self.entries))
        match = re.search(r"announce_round(?: \(round_number (\d+)\))?", last)
        if "Crown the champion" in last:
            return response(text("Sing, Muse, of the champion! " + re.search(r"Champion: (\w+)", last).group(1) + " takes the laurel."))
        if match:
            number = int(match.group(1) or re.search(r"round: (\d+)", last).group(1))
            required = re.search(r"required theme for round \d+: (.+)", last)
            theme = required.group(1).strip() if required else "a tiebreaker: the dawn"
            self.pending_text = f"Round {number}! Sing of {theme}."
            return response(tool("announce_round", {"round_number": number, "theme": theme, "constraint": "include one trochaic inversion"}))
        return response(text("The bard nods."))

    def _record(self) -> SimpleNamespace:
        entries = []
        for label, verse in self.entries:
            scan = scan_poem(verse)
            fits = [l["elided_fit"] or l for l in scan["lines"]]
            off = sum(abs(f["syllable_count"] - 10) + len(f["conflicts"]) for f in fits) / max(scan["line_count"], 1)
            metrical = max(1, min(10, round(10 - 2 * off)))
            entries.append(
                {
                    "label": label,
                    "syllable_counts": [l["syllable_count"] for l in scan["lines"]],
                    "scores": {"metrical_accuracy": metrical, "naturalness": metrical, "imagery_diction": 7, "overall_craft": metrical},
                    "on_theme": True,
                    "meets_constraint": True,
                    "disqualified": False,
                    "disqualification_reason": "",
                    "summary": f"Entry {label} scored on meter.",
                }
            )
        totals = {e["label"]: sum(e["scores"].values()) for e in entries}
        best = max(totals.values())
        winners = sorted(l for l, t in totals.items() if t == best)
        self.pending_text = "Entry " + " and ".join(winners) + " takes the round."
        return response(tool("record_round", {"entries": entries, "winner_labels": winners, "close_call_note": ""}))
