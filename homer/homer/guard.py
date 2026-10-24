"""Keep strangers from spending our Claude and Cartesia credits once the repo is public.

Three layers, all cheap:
- per-IP rate limits on every endpoint that reaches Claude or Cartesia, sized
  for real play behind one venue IP (a turn every ~30 s a device, a few devices);
- a global hourly budget of model calls, checked in homer/claude.py: past it,
  calls fail like a timeout, so the judge goes silent (never a canned verdict);
- an app key header (X-Homer-Key) the iOS app sends. It only deters. While
  HOMER_APP_KEY_REQUIRED is off it is checked only when sent, so builds
  without it keep working until the next TestFlight build carries it.
"""

from __future__ import annotations

import hmac
import os
import time
from collections import deque
from dataclasses import dataclass

APP_KEY_HEADER = "x-homer-key"

# path -> (calls, window seconds) per client IP. Calls Claude or Cartesia unless noted.
LIMITS: dict[str, tuple[int, float]] = {
    "/judge": (20, 60),
    "/battle/judge": (30, 60),
    "/emotion": (150, 60),  # ~every 1.5 s while a poet speaks
    "/battle/emotion": (150, 60),
    "/spar": (10, 60),
    "/debate/whispers": (20, 60),
    "/lesson/feedback": (20, 60),
    "/battle/poet": (30, 60),
    "/battle/verdict": (10, 60),
    "/battle/song": (10, 60),
    "/voice/token": (30, 60),
    "/battle/deal": (20, 60),  # no model call, but it writes to SpacetimeDB
}
CHEAP_LIMIT = (300, 60)  # every other path, each on its own: no model call, but keep the CPU sane
OPEN = frozenset({"/health"})  # never limited: the demo gate and Docker's healthcheck
KEYED = frozenset(LIMITS)  # endpoints that need the app key when it's required


class RateLimit:
    """At most `limit` calls per `window` seconds per key."""

    def __init__(self, limit: int = 30, window: float = 60.0) -> None:
        self.limit, self.window = limit, window
        self.hits: dict[str, deque[float]] = {}

    def allow(self, key: str, now: float | None = None) -> bool:
        now = time.monotonic() if now is None else now
        q = self.hits.setdefault(key, deque())
        while q and now - q[0] > self.window:
            q.popleft()
        if len(q) >= self.limit:
            return False
        q.append(now)
        return True


class Guard:
    """Per-IP limits on every path; one limiter per (path, IP)."""

    def __init__(self, limits: dict[str, tuple[int, float]] | None = None, cheap: tuple[int, float] = CHEAP_LIMIT) -> None:
        self.limits = LIMITS if limits is None else limits
        self.cheap = cheap
        self._by_path: dict[str, RateLimit] = {}

    def allow(self, path: str, ip: str, now: float | None = None) -> bool:
        if path in OPEN:
            return True
        limit, window = self.limits.get(path, self.cheap)
        limiter = self._by_path.setdefault(path, RateLimit(limit, window))  # each path its own cap
        return limiter.allow(ip, now)


@dataclass
class AppKey:
    key: str
    required: bool

    @classmethod
    def from_env(cls) -> AppKey:
        return cls(os.environ.get("HOMER_APP_KEY", "").strip(), os.environ.get("HOMER_APP_KEY_REQUIRED", "0") in ("1", "true"))

    def ok(self, sent: str | None) -> bool:
        """No key configured: open. Required: must match. Optional: only a wrong key is refused."""
        if not self.key:
            return True
        if sent is None or sent == "":
            return not self.required
        return hmac.compare_digest(sent.encode(), self.key.encode())


class BudgetExceeded(RuntimeError):
    """The hourly budget for this kind of call is spent: treat it like a call that timed out."""


class Budget:
    """A global cap on calls per hour, by kind (a sliding hour)."""

    def __init__(self, caps: dict[str, int], window: float = 3600.0) -> None:
        self.caps, self.window = caps, window
        self.calls: dict[str, deque[float]] = {k: deque() for k in caps}

    def spend(self, kind: str, now: float | None = None) -> None:
        cap = self.caps.get(kind)
        if cap is None:
            return
        now = time.monotonic() if now is None else now
        q = self.calls[kind]
        while q and now - q[0] > self.window:
            q.popleft()
        if len(q) >= cap:
            raise BudgetExceeded(f"hourly budget for {kind} spent ({cap})")
        q.append(now)

    def used(self) -> dict[str, int]:
        now = time.monotonic()
        return {k: sum(1 for t in q if now - t <= self.window) for k, q in self.calls.items()}


def budget_from_env() -> Budget:
    e = os.environ.get
    return Budget(
        {
            "claude": int(e("HOMER_MAX_CLAUDE_PER_HOUR", "600")),  # Opus and Sonnet: judging, naming, verdicts, songs
            "claude_cheap": int(e("HOMER_MAX_CHEAP_PER_HOUR", "4000")),  # Haiku: the emotion classifier
            "cartesia": int(e("HOMER_MAX_VOICE_TOKENS_PER_HOUR", "600")),
        }
    )


def kind_of(model: str) -> str:
    return "claude_cheap" if "haiku" in model else "claude"


def client_ip(headers: dict[str, str] | object, fallback: str = "?") -> str:
    """The caller's IP. Caddy sets X-Forwarded-For to the real client and ignores what clients send."""
    xff = headers.get("x-forwarded-for", "") if hasattr(headers, "get") else ""
    return xff.split(",")[0].strip() or fallback
