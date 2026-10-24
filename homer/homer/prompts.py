"""Assemble Homer's system prompt: shared persona plus exactly one mode section."""

from __future__ import annotations

from functools import cache
from pathlib import Path

from .state import CURRICULUM, Mode

PROMPT_DIR = Path(__file__).parent / "prompts"
DEFAULT_SWITCH_HINT = "choose another mode from the mode selector, or type `/mode bard`, `/mode judge`, or `/mode battle`."


@cache
def _read(name: str) -> str:
    return (PROMPT_DIR / f"{name}.md").read_text(encoding="utf-8")


def build_system_prompt(mode: Mode | str, switch_hint: str = DEFAULT_SWITCH_HINT) -> str:
    mode = Mode(mode)
    persona = _read("persona").replace("{{SWITCH_HINT}}", switch_hint)
    section = _read(mode.value)
    if mode is Mode.BARD:
        steps = "\n".join(f"{i}. `{sid}`: {title}" for i, (sid, title) in enumerate(CURRICULUM, 1))
        section = section.replace("{{CURRICULUM}}", steps)
    footer = f"# Current mode\n\nThe app has set this session to **{mode.value}** mode."
    return f"{persona.strip()}\n\n{section.strip()}\n\n{footer}\n"


def quote_untrusted(text: str) -> str:
    """Neutralise anything in user text that could pose as our own markup.

    Only angle brackets are touched, so apostrophes and quotes in verse survive
    intact for scansion.
    """
    return text.replace("<", "&lt;").replace(">", "&gt;")


def wrap_submission(text: str) -> str:
    return f"<submission>\n{quote_untrusted(text)}\n</submission>"


def wrap_entry(label: str, text: str) -> str:
    return f'<entry label="{label}">\n{quote_untrusted(text)}\n</entry>'


def app_state_block(lines: list[str] | str) -> str:
    body = lines if isinstance(lines, str) else "\n".join(lines)
    return f"<app_state>\n{body}\n</app_state>"
