"""An offline stand-in for `AsyncAnthropic().beta.messages.stream`."""

from __future__ import annotations

import asyncio
import json
from types import SimpleNamespace
from typing import Any


def reply(**overrides: Any) -> dict[str, Any]:
    """A judge reply in schema order, with sensible defaults."""
    out = {
        "fit": True,
        "verdict": "Strong bones, thin blood. Your third line carried you.",
        "best_line": "the sea kept time and so did I",
        "craft": 6,
        "image": 7,
        "answer": 5,
        "coined": "",
    }
    out.update(overrides)
    return out


class FakeStream:
    def __init__(self, text: str, stop_reason: str, chunk: int, delay: float, model: str):
        self.text, self.stop_reason, self.chunk, self.delay, self.model = text, stop_reason, chunk, delay, model

    async def __aenter__(self) -> FakeStream:
        return self

    async def __aexit__(self, *exc: Any) -> bool:
        return False

    def __aiter__(self):
        return self._events()

    async def _events(self):
        yield SimpleNamespace(type="content_block_start", content_block=SimpleNamespace(type="text"))
        for i in range(0, len(self.text), self.chunk):
            if self.delay:
                await asyncio.sleep(self.delay)
            yield SimpleNamespace(
                type="content_block_delta", delta=SimpleNamespace(type="text_delta", text=self.text[i : i + self.chunk])
            )

    async def get_final_message(self) -> SimpleNamespace:
        return SimpleNamespace(
            stop_reason=self.stop_reason,
            model=self.model,
            content=[SimpleNamespace(type="text", text=self.text)],
            usage=SimpleNamespace(input_tokens=200, output_tokens=60, cache_read_input_tokens=1400, cache_creation_input_tokens=0),
        )


class FakeClient:
    """Streams a fixed reply (a dict is sent as JSON, in key order).

    Pass a list to script one reply per call; the last one repeats.
    """

    def __init__(self, data: dict | str | list, stop_reason: str = "end_turn", chunk: int = 9, delay: float = 0.0):
        replies = data if isinstance(data, list) else [data]
        self.texts = [r if isinstance(r, str) else json.dumps(r) for r in replies]
        self.stop_reason, self.chunk, self.delay = stop_reason, chunk, delay
        self.calls: list[dict[str, Any]] = []
        self.beta = SimpleNamespace(messages=SimpleNamespace(stream=self._stream))

    @property
    def text(self) -> str:
        return self.texts[0]

    def _stream(self, **kwargs: Any) -> FakeStream:
        text = self.texts[min(len(self.calls), len(self.texts) - 1)]
        self.calls.append(kwargs)
        return FakeStream(text, self.stop_reason, self.chunk, self.delay, kwargs["model"])
