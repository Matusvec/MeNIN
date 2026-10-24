"""Assemble system prompts: the event's host persona plus one task section.

System prompts are built only from files and the event config, never from
request data, so they are byte-identical across calls and stay cached.
"""

from __future__ import annotations

from functools import cache
from pathlib import Path

from .events import Event

PROMPT_DIR = Path(__file__).parent / "prompts"


@cache
def _read(name: str) -> str:
    return (PROMPT_DIR / f"{name}.md").read_text(encoding="utf-8").strip()


@cache
def judge_system(event: Event) -> str:
    axes = "\n".join(f"- `{a.key}` ({a.name}): {a.measures}" for a in event.claude_axes)
    task = _read(event.judge_prompt).replace("{{AXES}}", axes)
    return f"{_read(event.persona)}\n\n{task}\n"


def quote_untrusted(text: str) -> str:
    """Neutralise anything in user text that could pose as our own markup.

    Only angle brackets are touched, so apostrophes and quotes in verse survive.
    """
    return text.replace("<", "&lt;").replace(">", "&gt;")


def block(tag: str, text: str) -> str:
    return f"<{tag}>\n{quote_untrusted(text.strip())}\n</{tag}>"
