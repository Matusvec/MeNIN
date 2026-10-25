"""Homer's narration for the Devpost video, in his own Cartesia voice (HOMER_VOICE_ID, Carl).

The lines come word for word from docs/gtm/video.md ("The narration" table, Homer's rows only). They're
rendered one at a time (the account allows 2 generations at once) at Homer's normal pace with no beat,
and written as docs/video/vo/vo-NN.wav: 48 kHz mono, Cartesia's own lead-in and tail trimmed, then 0.3 s
of silence at each end.

    .venv/bin/python scripts/render_vo.py            # every Homer line
    .venv/bin/python scripts/render_vo.py 6          # just line 6
    .venv/bin/python scripts/render_vo.py --hear 6   # transcribe vo-06.wav back (a pronunciation check)
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from homer.config import load_env  # noqa: E402
from homer.voice import TTS_URL, VoiceConfig  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "docs/gtm/video.md"
OUT = REPO / "docs/video/vo"
RATE = 48000
PAD_S = 0.3
TRIM_DB = -50  # quieter than this at either end is Cartesia's lead-in or tail, not Homer
STT_URL = "https://api.cartesia.ai/stt"

# What the TTS reads when the written line would come out wrong (the captions keep the written line).
SPEECH: dict[int, str] = {}

ROW = re.compile(r'^\| (\d+) \| [^|]+\| \**Homer\** \| "(.+)" \| \d+ \|$')


def lines() -> dict[int, str]:
    text = SCRIPT.read_text()
    table = text[text.index("### (a) The narration") :]
    return {int(m[1]): m[2] for m in map(ROW.match, table.splitlines()) if m}


def render(cfg: VoiceConfig, n: int, line: str, http: httpx.Client) -> Path:
    res = http.post(
        TTS_URL,
        headers={"X-API-Key": cfg.api_key, "Cartesia-Version": cfg.version},
        json={
            "model_id": cfg.tts_model,
            "transcript": SPEECH.get(n, line),
            "voice": {"mode": "id", "id": cfg.voice_id},
            "output_format": {"container": "wav", "encoding": "pcm_s16le", "sample_rate": RATE},
            "language": "en",
        },
    )
    res.raise_for_status()
    out = OUT / f"vo-{n:02d}.wav"
    with tempfile.NamedTemporaryFile(suffix=".wav") as raw:
        raw.write(res.content)
        raw.flush()
        trim = f"silenceremove=start_periods=1:start_threshold={TRIM_DB}dB:start_silence=0.02"
        pad = int(PAD_S * 1000)
        subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", raw.name,
             "-af", f"{trim},areverse,{trim},areverse,adelay={pad}:all=1,apad=pad_dur={PAD_S}",
             "-ar", str(RATE), "-ac", "1", "-c:a", "pcm_s16le", str(out)],
            check=True,
        )
    return out


def seconds(path: Path) -> float:
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "json", str(path)],
        check=True, capture_output=True, text=True,
    )
    return float(json.loads(probe.stdout)["format"]["duration"])


def hear(cfg: VoiceConfig, path: Path, http: httpx.Client) -> str:
    """What Cartesia's STT hears in a rendered line: a check for names the TTS might mangle."""
    with path.open("rb") as f:
        res = http.post(
            STT_URL,
            headers={"X-API-Key": cfg.api_key, "Cartesia-Version": cfg.version},
            data={"model": "ink-whisper", "language": "en"},
            files={"file": (path.name, f, "audio/wav")},
        )
    res.raise_for_status()
    return res.json().get("text", "").strip()


def main(argv: list[str]) -> None:
    load_env()
    cfg = VoiceConfig.from_env()
    if not cfg.api_key or not cfg.voice_id:
        sys.exit("CARTESIA_API_KEY and HOMER_VOICE_ID must be set (homer/.env)")
    homer = lines()
    with httpx.Client(timeout=60) as http:
        if argv[:1] == ["--hear"]:
            for n in map(int, argv[1:]):
                print(f"vo-{n:02d} heard: {hear(cfg, OUT / f'vo-{n:02d}.wav', http)}")
            return
        OUT.mkdir(parents=True, exist_ok=True)
        for n in map(int, argv) if argv else sorted(homer):
            path = render(cfg, n, homer[n], http)  # one at a time
            print(f"vo-{n:02d}.wav  {seconds(path):5.2f} s  {homer[n]}")


if __name__ == "__main__":
    main(sys.argv[1:])
