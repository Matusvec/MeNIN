"""Short-lived Cartesia access tokens, so the app never holds the API key.

docs/voice.md, section 2: the service mints a token with only the grants a
device needs. The device opens the Cartesia WebSocket itself with
`?access_token=...`. There is no audio proxy.
"""

from __future__ import annotations

import os
import time
from collections import deque
from dataclasses import dataclass

import httpx2

TOKEN_URL = "https://api.cartesia.ai/access-token"

# What each device needs: a battle phone listens, the arena speaks, a solo phone does both.
GRANTS = {"phone": {"stt": True}, "arena": {"tts": True}, "solo": {"stt": True, "tts": True}}


class VoiceError(RuntimeError):
    pass


@dataclass(frozen=True)
class VoiceConfig:
    api_key: str
    version: str
    ttl: int  # seconds; Cartesia allows up to 3600
    stt_model: str
    stt_encoding: str
    stt_sample_rate: int
    tts_model: str
    voice_id: str

    @classmethod
    def from_env(cls) -> VoiceConfig:
        e = os.environ.get
        return cls(
            api_key=e("CARTESIA_API_KEY", "").strip(),
            version=e("CARTESIA_VERSION", "2026-08-14"),
            ttl=int(e("HOMER_VOICE_TOKEN_TTL", "300")),
            stt_model=e("HOMER_STT_MODEL", "ink-2"),
            stt_encoding=e("HOMER_STT_ENCODING", "pcm_s16le"),
            stt_sample_rate=int(e("HOMER_STT_SAMPLE_RATE", "16000")),
            tts_model=e("HOMER_TTS_MODEL", "sonic-3.6"),
            voice_id=e("HOMER_VOICE_ID", ""),
        )


class RateLimit:
    """At most `limit` calls per `window` seconds per key (an IP)."""

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


async def mint(cfg: VoiceConfig, role: str, http: httpx2.AsyncClient) -> dict:
    """A token for `role`, plus the models and voice the app should use."""
    if role not in GRANTS:
        raise ValueError(f"unknown role: {role}")
    if not cfg.api_key:
        raise VoiceError("CARTESIA_API_KEY is not set")
    res = await http.post(
        TOKEN_URL,
        headers={"Authorization": f"Bearer {cfg.api_key}", "Cartesia-Version": cfg.version},
        json={"grants": GRANTS[role], "expires_in": cfg.ttl},
    )
    if res.status_code >= 300:
        raise VoiceError(f"Cartesia access-token: HTTP {res.status_code} {res.text[:200]}")
    body = res.json()
    ttl = int(body.get("expires_in") or cfg.ttl)
    out: dict = {
        "token": body["token"],
        "expiresAt": int((time.time() + ttl) * 1000),
        "cartesiaVersion": cfg.version,
    }
    if "stt" in GRANTS[role]:
        out["stt"] = {"model": cfg.stt_model, "encoding": cfg.stt_encoding, "sampleRate": cfg.stt_sample_rate}
    if "tts" in GRANTS[role]:
        out["tts"] = {"model": cfg.tts_model, "voiceId": cfg.voice_id}
    return out
