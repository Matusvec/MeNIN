"""Shared plumbing for every Claude call: the request options, the stream, strict JSON out.

Every call is one streamed request with a cached system prompt and a JSON
schema. Fast mode has its own rate limit, so a 429 there drops straight to
standard speed with no backoff.
"""

from __future__ import annotations

import asyncio
import json
import logging
from collections.abc import Awaitable, Callable
from typing import Any

import anthropic

log = logging.getLogger("homer")

FALLBACK_BETA = "server-side-fallback-2026-07-01"
FAST_BETA = "fast-mode-2026-02-01"
MAX_TOKENS = 2048  # a backstop; replies are short

# Models that take server-side refusal fallbacks ("default" form) and fast mode.
FALLBACK_MODELS = ("claude-opus-5-5", "claude-opus-5", "claude-fable-5-1", "claude-sonnet-5-5")
FAST_MODELS = ("claude-opus-5-5", "claude-opus-5", "claude-opus-4-8")

OnText = Callable[[str], Awaitable[None] | None]


def thinking_for(model: str, mode: str) -> dict[str, str] | None:
    """The `thinking` setting, or None to omit it.

    Claude Opus 5.5 can't turn thinking off; low effort keeps it short.
    """
    if mode != "off":
        return {"type": "adaptive"}
    if model == "claude-sonnet-5-5":
        return {"type": "between_tools"}
    if model in ("claude-haiku-5-5", "claude-sonnet-5", "claude-opus-5"):
        return {"type": "disabled"}
    return None


def options(
    model: str,
    effort: str,
    schema: dict[str, Any],
    *,
    speed: str = "",
    thinking: str = "off",
    fallbacks: bool = True,
    max_tokens: int = MAX_TOKENS,
) -> dict[str, Any]:
    """Request kwargs for everything but `system` and `messages`."""
    kwargs: dict[str, Any] = {
        "model": model,
        "max_tokens": max_tokens,
        "output_config": {"effort": effort, "format": {"type": "json_schema", "schema": schema}},
    }
    t = thinking_for(model, thinking)
    if t:
        kwargs["thinking"] = t
    betas = []
    if fallbacks and model in FALLBACK_MODELS:
        betas.append(FALLBACK_BETA)
        kwargs["fallbacks"] = "default"
    if speed == "fast" and model in FAST_MODELS:
        betas.append(FAST_BETA)
        kwargs["speed"] = "fast"
    if betas:
        kwargs["betas"] = betas
    return kwargs


def system(text: str) -> list[dict[str, Any]]:
    """A system prompt cached for an hour. Keep `text` byte-identical across calls."""
    return [{"type": "text", "text": text, "cache_control": {"type": "ephemeral", "ttl": "1h"}}]


def obj(props: dict[str, Any]) -> dict[str, Any]:
    """A strict object schema: every property required, nothing extra."""
    return {"type": "object", "properties": props, "required": list(props), "additionalProperties": False}


async def complete(client: Any, kwargs: dict[str, Any], on_text: OnText | None = None) -> tuple[str, Any]:
    """Stream one reply. Returns the text and the final message."""
    if kwargs.get("speed") == "fast":
        fast = client.with_options(max_retries=0) if hasattr(client, "with_options") else client
        try:
            return await _stream(fast, kwargs, on_text)
        except anthropic.RateLimitError:
            log.warning("fast mode rate-limited; standard speed")
            kwargs = {k: v for k, v in kwargs.items() if k != "speed"}
            kwargs["betas"] = [b for b in kwargs["betas"] if b != FAST_BETA]
            if not kwargs["betas"]:
                del kwargs["betas"]
    return await _stream(client, kwargs, on_text)


async def _stream(client: Any, kwargs: dict[str, Any], on_text: OnText | None) -> tuple[str, Any]:
    text = ""
    async with client.beta.messages.stream(**kwargs) as stream:
        async for ev in stream:
            if ev.type == "content_block_start" and ev.content_block.type == "text":
                text = ""  # a fresh text block (after a fallback) starts over
            elif ev.type == "content_block_delta" and ev.delta.type == "text_delta":
                text += ev.delta.text
                if on_text:
                    result = on_text(text)
                    if asyncio.iscoroutine(result):
                        await result
        final = await stream.get_final_message()
    return text, final


async def ask(client: Any, kwargs: dict[str, Any], timeout: float) -> dict[str, Any] | None:
    """One strict-JSON reply, or None if Claude refused, failed, ran late or broke the JSON."""
    try:
        text, final = await asyncio.wait_for(complete(client, kwargs), timeout)
    except (asyncio.TimeoutError, anthropic.APIError) as exc:
        log.warning("claude call failed: %s", type(exc).__name__)
        return None
    if final.stop_reason == "refusal":
        return None
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        log.warning("claude returned bad JSON (stop_reason=%s)", final.stop_reason)
        return None
    return data if isinstance(data, dict) else None
