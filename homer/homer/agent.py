"""Homer's agent loop on the Claude Messages API.

The app owns the mode: `respond()` reads `session.mode` and loads only that
mode's prompt section and tools. Nothing the user types can change it.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import Any, Callable

import anthropic

from .prompts import DEFAULT_SWITCH_HINT, app_state_block, build_system_prompt, wrap_submission
from .state import Mode, Session
from .tools import MODE_TOOLS, ToolInputError, run_scan_poem, validate_judgment

MODEL = "claude-opus-5-5"
MAX_TOKENS = 16000
MAX_TOOL_ROUNDS = 12
EFFORT = {Mode.BARD: "medium", Mode.JUDGE: "high", Mode.BATTLE: "high"}
FALLBACK_BETA = "server-side-fallback-2026-07-01"

EMPTY_SUBMISSION_REPLY = (
    "The page you hand me is as empty as a windless sea, swift-fingered friend. "
    "Send me a line, a stanza, or a whole poem, and I shall weigh every foot of it."
)
REFUSAL_REPLY = "I'm sorry, I can't help with that request. Please try something else."

# A tool handler takes the tool input and returns the tool_result text.
# Raising ToolInputError sends the message back to Homer as an error to fix.
Handler = Callable[[dict[str, Any]], str]


@dataclass
class HomerReply:
    text: str
    data: dict[str, Any] = field(default_factory=dict)
    tool_calls: list[tuple[str, dict[str, Any]]] = field(default_factory=list)
    stop_reason: str | None = None
    refused: bool = False


class HomerAgent:
    def __init__(
        self,
        client: Any | None = None,
        model: str = MODEL,
        switch_hint: str = DEFAULT_SWITCH_HINT,
        use_fallbacks: bool = True,
    ) -> None:
        self.client = client if client is not None else anthropic.Anthropic()
        self.model = model
        self.switch_hint = switch_hint
        self.use_fallbacks = use_fallbacks

    # ----- Mode entry points -------------------------------------------------

    def bard(self, session: Session, student_message: str) -> HomerReply:
        self._require_mode(session, Mode.BARD)

        def update_progress(inp: dict[str, Any]) -> str:
            session.bard.update(inp["step_id"], inp["status"], inp.get("note", ""))
            return f"Recorded. Student is now on step: {session.bard.current}."

        content = f"{app_state_block(session.bard.summary())}\n\n{student_message}"
        return self.respond(session, content, handlers={"update_progress": update_progress})

    def judge(self, session: Session, submission: str) -> HomerReply:
        self._require_mode(session, Mode.JUDGE)
        expected = len([line for line in submission.splitlines() if line.strip()])
        if expected == 0:
            # No model call: there is nothing to judge.
            return HomerReply(text=EMPTY_SUBMISSION_REPLY, data={"judgment": None, "empty": True})

        data: dict[str, Any] = {}

        def record_judgment(inp: dict[str, Any]) -> str:
            validate_judgment(inp, expected)
            data["judgment"] = inp
            return "Recorded. Now write your reply to the student."

        def decline_submission(inp: dict[str, Any]) -> str:
            data["declined"] = inp
            return "Recorded. Decline gently and in character, without repeating the content."

        content = f"{app_state_block(f'non_empty_lines: {expected}')}\n\n{wrap_submission(submission)}"
        reply = self.respond(
            session,
            content,
            handlers={"record_judgment": record_judgment, "decline_submission": decline_submission},
            required_tools={"record_judgment", "decline_submission"},
        )
        reply.data.update(data)
        return reply

    # ----- Core loop ---------------------------------------------------------

    def respond(
        self,
        session: Session,
        user_content: str,
        handlers: dict[str, Handler] | None = None,
        required_tools: set[str] | None = None,
    ) -> HomerReply:
        """Send one user turn and run tools until Homer finishes.

        `required_tools`: if Homer ends the turn without calling any of these,
        he is reminded once to do so.
        """
        handlers = {"scan_poem": run_scan_poem, **(handlers or {})}
        checkpoint = len(session.messages)
        session.messages.append({"role": "user", "content": user_content})

        texts: list[str] = []
        calls: list[tuple[str, dict[str, Any]]] = []
        reminded = False
        response = None

        for _ in range(MAX_TOOL_ROUNDS):
            response = self._create(session)

            if response.stop_reason == "refusal":
                # Drop this turn so the conversation can continue cleanly.
                del session.messages[checkpoint:]
                return HomerReply(text=REFUSAL_REPLY, tool_calls=calls, stop_reason="refusal", refused=True)

            session.messages.append({"role": "assistant", "content": response.content})
            texts.extend(b.text for b in response.content if b.type == "text" and b.text.strip())
            tool_uses = [b for b in response.content if b.type == "tool_use"]

            if response.stop_reason == "tool_use" and tool_uses:
                results = []
                for block in tool_uses:
                    calls.append((block.name, block.input))
                    results.append(self._run_tool(block, handlers))
                session.messages.append({"role": "user", "content": results})
                continue

            if response.stop_reason == "end_turn" and required_tools and not reminded:
                if not any(name in required_tools for name, _ in calls):
                    reminded = True
                    names = " or ".join(sorted(required_tools))
                    session.messages.append(
                        {
                            "role": "user",
                            "content": app_state_block(
                                f"The app did not receive a {names} call for this submission. "
                                "Call the appropriate tool now. Your reply has already been shown, so do not repeat it."
                            ),
                        }
                    )
                    continue
            break

        return HomerReply(
            text="\n\n".join(texts),
            tool_calls=calls,
            stop_reason=response.stop_reason if response else None,
        )

    def _create(self, session: Session):
        kwargs: dict[str, Any] = dict(
            model=self.model,
            max_tokens=MAX_TOKENS,
            system=build_system_prompt(session.mode, self.switch_hint),
            tools=MODE_TOOLS[session.mode.value],
            messages=session.messages,
            thinking={"type": "adaptive"},
            output_config={"effort": EFFORT[session.mode]},
        )
        if self.use_fallbacks:
            kwargs.update(betas=[FALLBACK_BETA], fallbacks="default")
        return self.client.beta.messages.create(**kwargs)

    @staticmethod
    def _run_tool(block: Any, handlers: dict[str, Handler]) -> dict[str, Any]:
        result: dict[str, Any] = {"type": "tool_result", "tool_use_id": block.id}
        handler = handlers.get(block.name)
        if handler is None:
            result.update(content=f"Tool {block.name} is not available in this mode.", is_error=True)
            return result
        try:
            result["content"] = handler(block.input)
        except (ToolInputError, ValueError) as exc:
            result.update(content=str(exc), is_error=True)
        except Exception as exc:  # a real technical error; Homer may speak plainly about it
            result.update(content=f"Tool failed: {type(exc).__name__}: {exc}", is_error=True)
        return result

    @staticmethod
    def _require_mode(session: Session, mode: Mode) -> None:
        if session.mode is not mode:
            raise ValueError(f"session is in {session.mode.value} mode, not {mode.value}")


def dump(data: Any) -> str:
    return json.dumps(data, indent=2, ensure_ascii=False)
