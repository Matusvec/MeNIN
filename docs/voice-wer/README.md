# Speech-to-text word error, with and without keyterms

The receipt behind "3% word error with keyterms, 20% without, drum at full volume" (docs/voice.md, CartesiaSTT.swift).

**When:** Fri Oct 23, 2026, about 10:59 PM PT (05:59 UTC Oct 24), by the iOS lead.

**Method:**
- Fixtures (`fixtures.py`): a four-line formulaic verse spoken by macOS `say`, a 90 BPM drum loop, and digital mixes with the drum at +12, +6 and 0 dB relative to the voice, plus 0 dB with a 150 Hz high-pass.
- Probe (`probe.py stt`): streams each fixture to Cartesia's manual `/stt/websocket` as 16 kHz `pcm_s16le` in 100 ms chunks, the same path the phone uses, then sends `finalize`.
- Models: `ink-2` without keyterms, `ink-2` with keyterms (the verse's formulas as repeated `keyterm` params, as the phone sends its hand), and `ink-whisper`.
- WER is the word error rate of the final transcript against the script.
- Run: `CARTESIA_API_KEY=… python probe.py stt` from a venv with `websockets` and `numpy`. The key comes from your shell only; never commit it.

**Results** (raw lines in `results.txt`):

| Model | Clean | Drum +12 dB | Drum +6 dB | Drum 0 dB | 0 dB, 150 Hz high-pass |
| --- | --- | --- | --- | --- | --- |
| ink-2 | 9% | 6% | 6% | 20% | 20% |
| ink-2 + keyterms | 3% | 3% | 3% | 3% | 3% |
| ink-whisper | 6% | 9% | 9% | 11% | 9% |

Also measured: the final transcript arrives about 62–81 ms after `finalize` on ink-2. ink-2 returned no word timestamps on these runs.

**Caveat:** the fixtures are synthetic: a clean TTS voice, mixed digitally, with no room, no phone mic, no AGC and no noise suppression. Treat these as an optimistic lower bound. A rerun through a real iPhone mic with the drum from a speaker 1–2 m away is still to do.
