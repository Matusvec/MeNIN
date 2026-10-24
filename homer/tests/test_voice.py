import asyncio
import json

import httpx2
import pytest

from homer.voice import RateLimit, VoiceConfig, VoiceError, mint

CFG = VoiceConfig(api_key="sk_test", version="2026-08-14", ttl=120, stt_model="ink-2", stt_encoding="pcm_s16le",
                  stt_sample_rate=16000, tts_model="sonic-3.6", voice_id="homer-voice")


def cartesia(seen):
    def handler(request: httpx2.Request) -> httpx2.Response:
        seen.append((request.headers, json.loads(request.content)))
        return httpx2.Response(200, json={"token": "tok_123"})

    return httpx2.AsyncClient(transport=httpx2.MockTransport(handler))


@pytest.mark.parametrize("role, grants", [("phone", {"stt": True}), ("arena", {"tts": True}), ("solo", {"stt": True, "tts": True})])
def test_grants_follow_the_role(role, grants):
    seen = []
    out = asyncio.run(mint(CFG, role, cartesia(seen)))
    headers, body = seen[0]
    assert headers["authorization"] == "Bearer sk_test" and headers["cartesia-version"] == "2026-08-14"
    assert body == {"grants": grants, "expires_in": 120}
    assert out["token"] == "tok_123" and out["cartesiaVersion"] == "2026-08-14"
    assert ("stt" in out) == ("stt" in grants) and ("tts" in out) == ("tts" in grants)
    if "tts" in out:
        assert out["tts"] == {"model": "sonic-3.6", "voiceId": "homer-voice"}


def test_no_key_no_token():
    with pytest.raises(VoiceError):
        asyncio.run(mint(VoiceConfig.from_env(), "phone", cartesia([])))


def test_rate_limit_per_ip():
    rl = RateLimit(limit=2, window=60)
    assert rl.allow("a", 0) and rl.allow("a", 1) and not rl.allow("a", 2)
    assert rl.allow("b", 2)
    assert rl.allow("a", 62)
