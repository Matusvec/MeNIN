"""Cartesia live probe for docs/voice.md. Needs CARTESIA_API_KEY in the env.

  .venv/bin/python fixtures.py            # once: builds fixtures/*.wav
  .venv/bin/python probe.py stt           # latency, words[], WER per fixture, ink-2 and ink-whisper
  .venv/bin/python probe.py tts           # time to first audio per candidate voice, saves wavs to listen to
  .venv/bin/python probe.py token-expiry  # does an open socket survive its access token expiring?

Every STT/TTS call goes through a short-lived access token in the query string,
the same path a browser would use, so this also tests question 2 (auth).
"""
import asyncio
import base64
import json
import os
import re
import sys
import time
import urllib.request
import wave
from pathlib import Path
from urllib.parse import urlencode

import numpy as np
import websockets

API = "https://api.cartesia.ai"
WSS = "wss://api.cartesia.ai"
VERSION = "2026-08-14"
HERE = Path(__file__).parent
FIX = HERE / "fixtures"
OUT = HERE / "out"

VOICES = {
    "carl-steady-storyteller": "ed82c17b-4704-4d34-be43-5d19065acdf1",
    "damon-commanding-narrator": "dbfa416f-d5c3-4006-854b-235ef6bdf4fd",
    "benedict-royal-narrator": "7cf0e2b1-8daf-4fe4-89ad-f6039398f359",
}
VERDICT = "Iron in that second line. The sea took the ship, and you took the room. Seven."
HAND = ["wine-dark sea", "grey-eyed Athena", "rose-fingered Dawn", "whale-road", "swift-footed"]


def mint_token(expires_in=300, stt=True, tts=True):
    req = urllib.request.Request(
        f"{API}/access-token",
        method="POST",
        data=json.dumps({"grants": {"stt": stt, "tts": tts}, "expires_in": expires_in}).encode(),
        headers={
            "Authorization": f"Bearer {os.environ['CARTESIA_API_KEY']}",
            "Cartesia-Version": VERSION,
            "Content-Type": "application/json",
        },
    )
    t0 = time.perf_counter()
    with urllib.request.urlopen(req) as r:
        body = json.load(r)
    print(f"  token minted in {1000 * (time.perf_counter() - t0):.0f} ms, response keys: {sorted(body)}")
    return body["token"]


def pcm_chunks(path, ms=100):
    with wave.open(str(path)) as w:
        sr = w.getframerate()
        data = w.readframes(w.getnframes())
    step = sr * ms // 1000 * 2
    return sr, [data[i : i + step] for i in range(0, len(data), step)]


def wer(ref, hyp):
    norm = lambda s: re.sub(r"[^a-z' ]", " ", s.lower().replace("-", " ")).split()
    r, h = norm(ref), norm(hyp)
    d = np.arange(len(h) + 1)
    for i in range(1, len(r) + 1):
        prev, d[0] = d.copy(), i
        for j in range(1, len(h) + 1):
            d[j] = min(prev[j] + 1, d[j - 1] + 1, prev[j - 1] + (r[i - 1] != h[j - 1]))
    return d[len(h)] / max(1, len(r))


async def stt_once(token, wav, model, keyterms=False, chunk_ms=100):
    sr, chunks = pcm_chunks(wav, chunk_ms)
    params = [("model", model), ("encoding", "pcm_s16le"), ("sample_rate", sr),
              ("cartesia_version", VERSION), ("access_token", token)]
    if keyterms:
        params += [("keyterm", k) for k in HAND]  # repeated-param form is a guess; check for an error
    t_conn = time.perf_counter()
    async with websockets.connect(f"{WSS}/stt/websocket?{urlencode(params)}", max_size=None) as ws:
        connect_ms = 1000 * (time.perf_counter() - t_conn)
        events = []  # (t since first audio byte, msg)
        t0 = None
        flush_at = None

        async def send():
            nonlocal t0, flush_at
            t0 = time.perf_counter()
            for i, c in enumerate(chunks):  # pace like a live mic
                await asyncio.sleep(max(0, t0 + i * chunk_ms / 1000 - time.perf_counter()))
                await ws.send(c)
            flush_at = time.perf_counter() - t0
            await ws.send("finalize")

        async def recv():
            async for raw in ws:
                msg = json.loads(raw)
                events.append((time.perf_counter() - t0, msg))
                if msg.get("type") in ("flush_done", "done", "error"):
                    return

        sender = asyncio.create_task(send())
        try:
            await asyncio.wait_for(recv(), timeout=len(chunks) * chunk_ms / 1000 + 8)
        except asyncio.TimeoutError:
            events.append((time.perf_counter() - t0, {"type": "probe_timeout"}))
        await sender

    finals = [m for _, m in events if m.get("type") == "transcript" and m.get("is_final")]
    text = "".join(m.get("text", "") for m in finals)
    first = next((t for t, m in events if m.get("type") == "transcript" and m.get("text", "").strip()), None)
    last_final = max((t for t, m in events if m.get("type") == "transcript" and m.get("is_final")), default=None)
    words = [w for m in finals for w in (m.get("words") or [])]
    partial_words = any(m.get("words") for _, m in events if m.get("type") == "transcript" and not m.get("is_final"))
    # How late does a word's timing reach the client, relative to when it was spoken?
    lags = [t - w["end"] for t, m in events if m.get("type") == "transcript" for w in (m.get("words") or [])]
    return {
        "connect_ms": round(connect_ms),
        "first_text_ms": first and round(1000 * first),
        "finalize_to_last_final_ms": last_final and flush_at and round(1000 * (last_final - flush_at)),
        "end_type": events[-1][1].get("type") if events else None,
        "n_msgs": len(events),
        "words_on_finals": len(words),
        "words_on_partials": partial_words,
        "first_word": words[0] if words else None,
        "word_lag_ms_median": round(1000 * float(np.median(lags))) if lags else None,
        "wer": round(wer((FIX / "reference.txt").read_text(), text), 3),
        "text": text.strip(),
        "errors": [m for _, m in events if m.get("type") in ("error", "probe_timeout")],
    }


async def cmd_stt():
    OUT.mkdir(exist_ok=True)
    token = mint_token()
    results = []
    for model, kt in (("ink-2", False), ("ink-2", True), ("ink-whisper", False)):
        for wav in sorted(FIX.glob("*.wav")):
            print(f"\n== {model}{' +keyterms' if kt else ''}  {wav.name}")
            try:
                r = await stt_once(token, wav, model, keyterms=kt)
            except Exception as e:  # keep going so one bad config doesn't hide the rest
                r = {"exception": repr(e)}
            r.update(model=model, keyterms=kt, fixture=wav.name)
            results.append(r)
            print(json.dumps(r, indent=1))
    (OUT / "stt.json").write_text(json.dumps(results, indent=1))
    print(f"\nwrote {OUT / 'stt.json'}")


async def cmd_tts(sample_rate=48000):
    OUT.mkdir(exist_ok=True)
    token = mint_token()
    params = urlencode({"cartesia_version": VERSION, "access_token": token})
    t_conn = time.perf_counter()
    async with websockets.connect(f"{WSS}/tts/websocket?{params}", max_size=None) as ws:
        print(f"  tts socket open in {1000 * (time.perf_counter() - t_conn):.0f} ms (pre-open this in the app)")
        for name, vid in VOICES.items():
            for take in range(2):  # take 0 can include cold-start effects
                ctx = f"{name}-{take}"
                req = {"model_id": "sonic-3.6", "transcript": VERDICT, "voice": {"mode": "id", "id": vid},
                       "output_format": {"container": "raw", "encoding": "pcm_f32le", "sample_rate": sample_rate},
                       "language": "en", "context_id": ctx, "continue": False, "add_timestamps": True}
                t0 = time.perf_counter()
                await ws.send(json.dumps(req))
                first, audio, other = None, [], set()
                async for raw in ws:
                    msg = json.loads(raw)
                    if msg.get("context_id") not in (None, ctx):
                        continue
                    if msg.get("type") == "chunk" and msg.get("data"):
                        first = first or time.perf_counter() - t0
                        audio.append(np.frombuffer(base64.b64decode(msg["data"]), np.float32))
                    else:
                        other.add(msg.get("type"))
                    if msg.get("done") or msg.get("type") in ("done", "error"):
                        if msg.get("type") == "error":
                            print("  ERROR", msg)
                        break
                total = time.perf_counter() - t0
                pcm = np.concatenate(audio) if audio else np.zeros(0, np.float32)
                print(f"  {ctx:32s} first audio {1000 * (first or 0):5.0f} ms  total {1000 * total:5.0f} ms  "
                      f"audio {pcm.size / sample_rate:4.1f} s  other msgs {sorted(filter(None, other))}")
                if take == 1:
                    with wave.open(str(OUT / f"tts_{name}.wav"), "wb") as w:
                        w.setnchannels(1)
                        w.setsampwidth(2)
                        w.setframerate(sample_rate)
                        w.writeframes((np.clip(pcm, -1, 1) * 32767).astype(np.int16).tobytes())
    print(f"\nlisten: open {OUT}/tts_*.wav")


async def cmd_token_expiry():
    token = mint_token(expires_in=10)
    wav = FIX / "clean.wav"
    sr, chunks = pcm_chunks(wav)
    params = urlencode({"model": "ink-2", "encoding": "pcm_s16le", "sample_rate": sr,
                        "cartesia_version": VERSION, "access_token": token})
    async with websockets.connect(f"{WSS}/stt/websocket?{params}", max_size=None) as ws:
        t0 = time.perf_counter()
        # Stream ~30 s (the fixture three times over), well past the 10 s expiry.
        try:
            for i, c in enumerate(chunks * 3):
                await asyncio.sleep(max(0, t0 + i * 0.1 - time.perf_counter()))
                await ws.send(c)
            await ws.send("finalize")
            async for raw in ws:
                msg = json.loads(raw)
                if msg.get("type") in ("flush_done", "error"):
                    print(f"  at {time.perf_counter() - t0:.1f}s: {msg.get('type')} {msg.get('message', '')}")
                    break
            print("  RESULT: socket outlived its token" if msg.get("type") == "flush_done" else "  RESULT: see error")
        except websockets.ConnectionClosed as e:
            print(f"  RESULT: socket closed at {time.perf_counter() - t0:.1f}s ({e.code} {e.reason})")


if __name__ == "__main__":
    if "CARTESIA_API_KEY" not in os.environ:
        sys.exit("set CARTESIA_API_KEY (never commit it)")
    cmd = sys.argv[1] if len(sys.argv) > 1 else "stt"
    asyncio.run({"stt": cmd_stt, "tts": cmd_tts, "token-expiry": cmd_token_expiry}[cmd]())
