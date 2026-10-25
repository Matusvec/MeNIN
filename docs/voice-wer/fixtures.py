"""Build test audio for the voice probe: a spoken four-beat verse, a drum loop,
and mixes at several speech-to-beat ratios (the "beat bleed" proxy).

Output: fixtures/*.wav, 16 kHz mono pcm_s16le (what STT gets), plus
fixtures/reference.txt.

This is a synthetic proxy. It does not model room acoustics, phone AGC,
OS noise suppression, or a real voice over a real PA. A live room test still
has to happen (see docs/voice.md).
"""
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

SR = 16000
BPM = 90
OUT = Path(__file__).parent / "fixtures"

VERSE = [
    "The wine-dark sea took my brother's ship.",
    "Grey-eyed Athena would not hear his cry.",
    "When rose-fingered Dawn came early to the shore,",
    "I walked the whale-road and the waves were bare.",
]


def read_wav(path):
    with wave.open(str(path)) as w:
        assert w.getframerate() == SR and w.getnchannels() == 1
        return np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768


def write_wav(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def speak(text, rate=165):
    with tempfile.TemporaryDirectory() as d:
        aiff, wav = Path(d) / "s.aiff", Path(d) / "s.wav"
        subprocess.run(["say", "-r", str(rate), "-o", str(aiff), text], check=True)
        subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@16000", "-c", "1", str(aiff), str(wav)], check=True)
        return read_wav(wav)


def drum_loop(seconds):
    n = int(seconds * SR)
    out = np.zeros(n, np.float32)
    rng = np.random.default_rng(7)
    beat = 60 / BPM
    t = np.arange(int(0.35 * SR)) / SR
    kick = np.sin(2 * np.pi * (50 * t + 70 * 0.04 * (1 - np.exp(-t / 0.04)))) * np.exp(-t / 0.12)
    snare = (rng.standard_normal(t.size) * 0.6 + np.sin(2 * np.pi * 185 * t) * 0.4) * np.exp(-t / 0.06)
    th = t[: int(0.05 * SR)]
    hat = np.diff(rng.standard_normal(th.size + 1)) * np.exp(-th / 0.01) * 0.35  # crude high-pass
    i = 0
    while (start := i * beat / 2) < seconds:
        s = int(start * SR)
        pos = i % 8  # eighth notes in a bar
        hits = [hat]
        if pos in (0, 4):
            hits.append(kick)
        if pos in (2, 6):
            hits.append(snare)
        for h in hits:
            e = min(n, s + h.size)
            out[s:e] += h[: e - s]
        i += 1
    return out / np.max(np.abs(out))


def rms(x):
    return float(np.sqrt(np.mean(x**2)) + 1e-12)


def highpass(x, fc=150.0):
    """2nd-order Butterworth high-pass (RBJ biquad). The cheapest mic-side
    mitigation: strips most kick energy, keeps speech intelligibility."""
    w0 = 2 * np.pi * fc / SR
    alpha = np.sin(w0) / np.sqrt(2)
    c = np.cos(w0)
    b = np.array([(1 + c) / 2, -(1 + c), (1 + c) / 2])
    a = np.array([1 + alpha, -2 * c, 1 - alpha])
    b, a = b / a[0], a / a[0]
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i, xi in enumerate(x):
        yi = b[0] * xi + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2
        x2, x1, y2, y1 = x1, xi, y1, yi
        y[i] = yi
    return y


def main():
    OUT.mkdir(exist_ok=True)
    lead = np.zeros(int(0.5 * SR), np.float32)  # 0.5 s of silence: lets us read the words[] time base
    gap = np.zeros(int(0.35 * SR), np.float32)
    parts = [lead]
    for line in VERSE:
        parts += [speak(line), gap]
    voice = np.concatenate(parts)
    voice *= 0.5 / np.max(np.abs(voice))
    write_wav(OUT / "clean.wav", voice)
    (OUT / "reference.txt").write_text(" ".join(VERSE) + "\n")

    drums = drum_loop(voice.size / SR)
    speech_rms = rms(voice[np.abs(voice) > 0.01])
    for snr_db in (12, 6, 0):
        d = drums * (speech_rms / rms(drums)) / (10 ** (snr_db / 20))
        mix = voice + d
        mix *= 0.9 / max(1.0, np.max(np.abs(mix)))
        write_wav(OUT / f"beat_{snr_db:+d}dB.wav", mix)
        if snr_db == 0:
            hp = highpass(mix)
            write_wav(OUT / "beat_+0dB_hpf150.wav", hp * 0.9 / np.max(np.abs(hp)))
    print(f"wrote {sorted(p.name for p in OUT.glob('*.wav'))}, {voice.size / SR:.1f}s each")


if __name__ == "__main__":
    main()
