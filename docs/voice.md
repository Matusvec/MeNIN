# Voice pipeline (spike)

Spike notes from the swift session, 2026-10-23, updated 2026-10-24 for the iOS app. Covers Cartesia STT and TTS, client auth, and the beat bleeding into the mic. What's built is in "iOS implementation" below.

**Status:** docs research plus endpoint checks. There is no Cartesia key on this machine, so there are no live latency numbers yet. Every item marked **Live test** still needs one. The probe script that runs all of them is ready (see "Live tests still to run").

Already verified without a key: `POST https://api.cartesia.ai/access-token` exists (401 without auth, while an unknown path gives 404). `wss://api.cartesia.ai/stt/websocket` and `wss://api.cartesia.ai/tts/websocket` both reject a bogus `access_token` query param with HTTP 401 at the handshake. So the URLs and the browser token path are live.

## Answers at a glance

| Question | Answer | Confidence |
| --- | --- | --- |
| STT latency, first partial | Not published. **Live test.** | none |
| STT latency, final | Vendor: ink-2 "time to final transcript is 0.1s". Ink-Whisper median 66 ms / p90 98 ms after the last audio (vendor benchmark, June 2025). | vendor claim |
| Word timestamps | The manual endpoint's `transcript` message has an optional `words: [{word, start, end}]` (seconds). The docs don't say which models fill it, whether partials carry it, or the time base. The turns endpoint has no word timing. **Live test.** | schema only |
| Browser auth without the key | Yes. The agent service mints a short-lived access token (max 1 h). The browser passes it as `access_token` in the WebSocket URL. **No audio proxy needed.** | high (docs + handshake check) |
| TTS time to first audio | Vendor: Sonic 3.x "under 90 ms", which is model time only, excluding network. Pre-opening the socket saves about 200 ms of setup. **Live test.** | vendor claim |
| TTS streaming playback | Yes. Raw `pcm_f32le` chunks at the `AudioContext` sample rate, scheduled back to back. | high |
| Voices | Damon "Commanding Narrator", Carl "Steady Storyteller", Benedict "Royal Narrator" (IDs below). Matus picks by ear. | listen first |
| Beat bleed | Echo cancellation can't remove the arena's speakers from a phone mic. Expect it to matter at demo volume unless the phone is held close and the beat ducks while the poet speaks. Mitigations below. **Live test in the room.** | reasoning, untested |

## Recommended pipeline

```
Phone (poet)                          Agent service              Arena (Mac / iPad / phone)
AVAudioEngine input tap (MicEngine)   POST /voice/token  <------ (arena: tts grant)
  48k -> 16k mono s16 (AVAudioConverter)  mints Cartesia tokens
  prosody, onsets, push-to-talk mute       never touches audio
  |-- 100 ms PCM --> Cartesia STT (URLSessionWebSocketTask, access_token)
  |                   <-- partial/final text, words[]
  |-- update_transcript, play_card, end_turn ------------> SpacetimeDB -> arena lane + transcript
  |-- set_prosody ~20 Hz (loudness, pitch, hits) --------> SpacetimeDB -> scene instant layer, drum strikes
  beat as Core Haptics; hits from on-device onsets        arena: Cartesia TTS socket (pre-opened)
                                                            -> AVAudioPlayerNode -> level -> scene
                                                          arena: plays the beat, ducks it in speaking bars
```

The agent service only mints tokens. Audio goes phone to Cartesia and Cartesia to arena, with no extra hop.

## 1. STT

**Endpoint: the manual one, `wss://api.cartesia.ai/stt/websocket`.** The other option, `/stt/turns/websocket`, decides on its own when a turn has ended. For a verse, the 30-second timer has to decide that, because the mid-line pause (the caesura) and a freeze would otherwise end the verse early. The turns endpoint also returns no word timing. It does fit short voice commands, such as the P9 voice menu ("Learn, train, or fight?"), where its `turn.end` event saves us from building end-of-speech detection ourselves.

**Query params:**
- `model=ink-2`
- `encoding=pcm_s16le`
- `sample_rate=16000`
- `cartesia_version=2026-08-14`
- `access_token=<token>`

Audio goes in as binary frames of about 100 ms each, which is 3200 bytes at 16 kHz s16. It must be raw mono with no header. The docs say "Speech recognition gains little from rates above 16 kHz". They also say the server "might not error" when the encoding or sample rate is wrong; you get garbage instead of an error, so get the resampler right.

**Model:**
- `ink-2` is the default. It supports `keyterm` biasing (up to 100 terms and 1200 characters), and the vendor says it is "robust to background noise without requiring Krisp". It costs 3 credits a second, about 90 per 30-second turn.
- `ink-whisper` is cheaper at 1 credit a second and has `min_volume` and `max_silence_duration_secs`, but no keyterms.
- The probe runs both.

**Keyterms:** pass the five formulas in the hand plus the theme words. Rare compounds like "whale-road" and "rose-fingered Dawn" are exactly the words a recognizer mangles, and exactly the words the formula cards and the Craft axis depend on. How to encode several keyterms in the query string isn't documented; the probe tries a repeated `keyterm=` param.

**Messages from the server:**
- `transcript`: `{is_final, text, words?, duration?, request_id}`. For finals, `text` is the change since the previous final. The docs say to join the final `text` values exactly as received, without adding or trimming whitespace. Use the latest partial as the live tail of the transcript.

**Messages from the client:**
- `finalize`: send it when the turn timer ends; the server answers with the last finals, then `flush_done`.
- `close`: ends the session; the server answers with `done`.

The docs don't make clear whether these go as raw text or as a JSON string. The probe sends raw text.

**Session lifecycle:** open the socket when the poet is up next, before the count-in, so the TLS handshake doesn't clip the first word. Any idle timeout or maximum session length is undocumented. **Live test.**

### Word timestamps and the beat lane

Even with `words[]`, STT timing reaches the phone a few hundred milliseconds after the syllable, so it can't drive a live glow on its own. I suggest building the lane in two layers, the same way the scene does:

1. **Live layer (on the phone, about 20–40 ms):** the AudioWorklet tracks loudness and marks syllable peaks. A peak within about ±120 ms of a pulse counts as a hit. Stressed syllables are the loud ones, so loudness peaks are a decent stand-in for stress. This works with no network at all, and it is also the freeze-rescue signal (about 1 s with no voiced peaks).
2. **Label layer (when STT arrives):** place each word at its `words[].start`. The scanner's stress pattern (CMU dictionary) decides which peak belongs to which stressed syllable. If `words[]` turns out to be empty, place words on the peaks in order. That is coarser, but it still works.

The Beat axis at the end of the turn can use both: the scanner counts stresses from the final text, and the peaks give the timing against the pulses. That is ux-flow open question 3.

**Clock math for `BeatLane` / `BeatWord.t` in `web/src/contracts.ts`:**
- `words[].start` is presumably seconds from the first audio byte. The probe's fixture starts with 0.5 s of silence to confirm this.
- The phone records the epoch time of its first audio frame. Then `BeatWord.t = (frameEpoch + start*1000) - startedAt`.
- `startedAt` comes from the arena, so the phone needs its clock offset to the arena. An NTP-style ping against the server works: take the lowest-RTT result of about 5 pings. Expect ±10–30 ms on decent Wi-Fi.
- The arena should set `startedAt` from when beat 1 actually leaves the speakers, not when it was scheduled: use `AudioContext.outputLatency` / `getOutputTimestamp()`. HDMI to a TV adds tens of milliseconds and Bluetooth speakers add 150 ms or more. That alone would push every hit late.
- **Never drop audio frames mid-turn.** If audio has to be muted, send zeros instead, or every later timestamp shifts.

**Design tension, for Matus:** the spec says "a stressed syllable that hits a beat sounds like a drum strike". A hit detected on the phone reaches the arena 100–200 ms later (per ux-flow). At a slow tempo, a strike that late sounds like an echo, not a hit. Options:
- Play the strike on the phone itself. It's immediate, and its own echo cancellation should keep it out of the mic, but a phone speaker is quiet.
- Make the hit visual on the arena, with a softer sound.
- Accept the lag.

### Latency budget, end of verse to Homer's voice

STT finalize (about 0.1 s) + Claude judge call (several seconds) + TTS first audio (about 0.1–0.4 s). Voice is not the bottleneck; the judge call is.

## 2. Auth

Cartesia's position: never put the API key in a browser, and use access tokens instead. Verified against the live API (see Status above).

**Minting a token:**
- Request: `POST https://api.cartesia.ai/access-token`
- Headers: `Authorization: Bearer $CARTESIA_API_KEY`, `Cartesia-Version: 2026-08-14`, `Content-Type: application/json`
- Body: `{"grants": {"stt": true, "tts": true}, "expires_in": 300}`. The maximum is 3600 seconds.
- Response: `{"token": "..."}`. The auth guide also reads an `expires_in` field from the response, but the API reference doesn't list one.
- Grants:
  - `stt` covers `/stt/websocket`, `/stt` and `/audio/transcriptions`.
  - `tts` covers `/tts/websocket`, `/tts/sse` and `/tts/bytes`.

**Using a token:**
- WebSocket: `?access_token=<token>&cartesia_version=2026-08-14`. Browsers can't set headers on a WebSocket.
- HTTP: `Authorization: Bearer <token>`.

**What the agent service needs:** one endpoint, `POST /voice/token`, that mints a token and returns it. No audio proxy.
- Grants: phones get `stt` (plus `tts` in solo modes); the arena gets `tts`.
- Only mint for a valid room and player, rate-limit per player, and keep expiry short. Anyone who can call this endpoint is spending our credits.
- The browser keeps the token in memory only. The guide's advice to use an `httpOnly` cookie doesn't work, since JavaScript must read the token to build the WebSocket URL.
- `CARTESIA_API_KEY` goes in `.env`, with a line in `.env.example`.

**Unknown:** whether an open socket survives its token expiring. **Live test** (`probe.py token-expiry`). If it doesn't, mint one token per turn with `expires_in` of about 120 s.

**Fallback, only if direct connection fails** (for example, venue Wi-Fi blocking the connection): a WebSocket relay in the agent service that forwards binary frames and adds `X-API-Key`. It costs one extra hop. Don't build it unless we need it.

**Version mismatch:** one snippet in the auth guide uses `cartesia_version=2026-03-01`; every API reference uses `2026-08-14`. Use `2026-08-14`.

## 3. TTS

**Model:** `sonic-3.6`, the current recommended model. `sonic-2` and `sonic-turbo` stopped working on Oct 20, 2026, so don't copy old snippets.

**Transport:** WebSocket `wss://api.cartesia.ai/tts/websocket`, opened when the arena loads and kept open. Use one `context_id` per utterance. The response comes as a stream of `chunk` messages with base64 audio, then `done`. With `add_timestamps: true`, `timestamps` messages also arrive with `word_timestamps`.

**Request:**
```json
{"model_id": "sonic-3.6", "transcript": "...", "voice": {"mode": "id", "id": "<voice>"},
 "output_format": {"container": "raw", "encoding": "pcm_f32le", "sample_rate": 48000},
 "language": "en", "context_id": "verdict-r1-p2", "continue": false, "add_timestamps": true}
```
Set `sample_rate` to `AudioContext.sampleRate`, usually 48000. A mismatch means resampling and extra latency.

**Playback:**
- Decode each chunk into a `Float32Array`, wrap it in an `AudioBuffer`, and start each one at `nextTime = max(ctx.currentTime + 0.05, nextTime)`, then add the chunk's duration to `nextTime`.
- Route playback through an `AnalyserNode` so the scene's instant layer reacts to Homer (spec: "The scene reacts to Homer's voice").
- `word_timestamps` drive Homer's words lighting up on the lane (ux-flow F1, the Homer spar turn).

**Text:** a verdict line is known in full, so send it as one request. If we stream Claude's output, send sentence-sized pieces with `continue: true` and the same `context_id`, keep the leading spaces, and end the last piece with `continue: false`. Unfinished sentences sit in a buffer (default `max_buffer_delay_ms` 3000).

**Homer over the beat** (Bard verses, spar, the finale): render each line separately and start each one on its bar's downbeat. If a line runs longer than its bar, use `generation_config.speed` (0.6–1.5) to fit it. Stresses won't land exactly on the beat, but every line starts on the one.

**Freeze rescue (P2):** render the five formulas in the hand when they are dealt, and cache the audio, so the whisper plays instantly.

**Expressiveness:**
- Sonic 3.6 varies pacing and intonation from the text alone.
- `generation_config.emotion` is beta, English only. The schema lists `neutral`, `calm`, `angry`, `content` and `sad`.
- Inline tags: `<speed ratio=".."/>`, `<volume ratio=".."/>`, `<break time="1s"/>`, `[laughter]`.
- No pitch control is documented. Depth comes from choosing the voice.

### Candidate voices

| Voice | ID | Description (Cartesia) | Notes |
| --- | --- | --- | --- |
| Damon, "Commanding Narrator" | `dbfa416f-d5c3-4006-854b-235ef6bdf4fd` | "Deep and serious male voice with steady gravitas, ideal for documentaries and impactful storytelling" | US. Tagged Emotive. Closest to "deep, theatrical, confident". |
| Carl, "Steady Storyteller" | `ed82c17b-4704-4d34-be43-5d19065acdf1` | "Matured male voice with calm depth and measured pacing, perfect for narrations and documentaries" | US. Tagged Emotive. Sounds older; may be too calm for roasts. |
| Benedict, "Royal Narrator" | `7cf0e2b1-8daf-4fe4-89ad-f6039398f359` | "Confident, firm male for narrations" | British. The epic-trailer option. |

Also worth a listen in the playground:
- "Oracle" ("A deep, wise British voice for storytelling")
- "Overlord" ("deep, commanding British voice")
- Alaric "Wizard" (`87748186-23bb-4158-a1eb-332911b0b708`, from a URL slug, not confirmed)

The pages I read showed no ID for Oracle or Overlord. A custom clone is possible if none of these fit. `probe.py tts` renders the same verdict line in each candidate voice, so they can be compared side by side.

## 4. Beat bleed

ux-flow's "Risk: the beat bleeds into the speaker's mic" section states the problem correctly. A phone's echo cancellation subtracts only what that phone itself played. The arena's speakers are unrelated noise to it.

**Rough numbers (back of the envelope, untested):**
- Projected speech is about 70 dB SPL at 1 m, and each halving of the mic distance adds 6 dB:
  - Phone held like a mic at about 10 cm: around 90 dB at the mic.
  - Phone at chest height, about 30 cm: around 80 dB.
- A demo beat that the room can feel is maybe 75–85 dB at the poet. So:
  - Held close: speech-to-beat ratio of about +5 to +15 dB.
  - At the chest: about −5 to +5 dB.
- The fixtures mix speech and drums at +12, +6 and 0 dB to cover that range, plus 0 dB with the 150 Hz high-pass.
- The lyre is the dangerous part. A kick drum sits below speech, but a harmonic lyre sits right in the 200 Hz–2 kHz band that STT relies on. Drums with vocals or melody are worse still, because STT transcribes sung words.

**What breaks** (from ux-flow, plus one):
- STT accuracy.
- The instant layer moving with the drum.
- The P2 whisper getting transcribed as the poet's own words.
- New: the drum hitting the onset detector and registering as false beat-lane hits.

**Mitigations, mapped to ux-flow's options A–E, plus F and G:**

| Option | Verdict |
| --- | --- |
| A. Stage mic at the arena | The most reliable path, and it matches the plan's "wired mic" demo insurance. Prepare it either way. It still needs testing: whether Chrome's echo cancellation removes the page's own Web Audio output (not only WebRTC audio) varies by platform. |
| B. Duck the beat in speaking bars | Free and the biggest win. Duck the lyre fully and keep a soft kick. The arena already knows the turn state from SpacetimeDB. |
| C. Beat on the speaker's phone | Needs a device test on iOS Safari and Android Chrome. On iOS, `getUserMedia` echo cancellation should run in the OS's voice-processing mode, which covers the page's own output, but verify. Phone speakers are weak, so the room loses the drum. |
| D. Haptic beat | iPhone Safari has no `navigator.vibrate`. Android only. |
| E. Filter it | The 150 Hz high-pass in the worklet costs nothing and removes the kick. Gate the instant layer and the onset detector on detected voice. The probe measures the STT effect at 0 dB. |
| F. Hold it like a mic (new) | A UI prompt plus a level meter that rewards a close mic. About +6 dB for each halving of distance, and it costs nothing. |
| G. Mute the uplink during Homer's whisper (new) | The poet is silent then anyway, which is why the whisper fired. The phone sends zeros to STT for the whisper window plus about 300 ms. This fixes the whisper-in-transcript bug. It needs a "whisper started at T for D ms" event the phone can see. |

Also: pass keyterms (section 1); try `noiseSuppression: true` (and Safari's voice isolation where available) and measure, since it can smear the syllable peaks the lane needs; and leave `autoGainControl` off if it pumps the beat up in silences. Not worth trying: subtracting the known loop ourselves. The room's acoustics and the delay are unknown, and that is the echo canceller's job anyway.

**Suggested test order (ux-flow open question 2, Matus's call):**
1. B + E + F + G together as the default. They are cheap and stack.
2. A ready as the demo fallback.
3. C only if B still bleeds at demo volume.

Whatever we choose, do one test at the venue at demo volume, with the real speakers.

## iOS implementation

Built in `ios/Homer/` (the swift session owns it). Verified with unit tests and a dev-only protocol stand-in; nothing has run against real Cartesia yet because there is no key.

- **Mic (`Audio/MicEngine.swift`):** a single AVAudioEngine input tap feeds three outputs.
  - Prosody for the scene, using the web prototype's RMS dBFS mapping and first-peak autocorrelation, done with Accelerate.
  - 16 kHz mono `pcm_s16le` in 100 ms chunks for STT, via AVAudioConverter.
  - Energy-rise onsets with epoch-ms timestamps, at least 120 ms apart. A unit test finds three synthetic syllables within 15 ms.
  - Push-to-talk mute sends **zeros, never gaps**, so STT word times stay on the turn's clock.
  - Voice processing (the system echo canceller) is a start option for solo modes, where the phone plays the beat itself.
- **STT (`Net/Voice/CartesiaSTT.swift`):** URLSessionWebSocketTask on the manual endpoint. It handles partial (replace), final (append exactly), `flush_done`, `done` and `error`. `finalize` is sent as raw text.
- **Turn (`Battle/TurnRecorder.swift`):**
  - Gets a token from `POST /voice/token` and opens STT plus the mic while the poet is up next, before the count-in.
  - One press of the talk button is one line. On release it sends `finalize`, and the line break lands on `flush_done`.
  - Hits are onsets within ±120 ms of a speaking beat (`Audio/BeatClock.swift`), on a grid shifted by the clock offset `local receive − started_at`.
  - The beat plays as one Core Haptics pattern for the whole turn: strong downbeats, medium speaking beats, faint rest bars. A hit adds an immediate strike.
  - `set_prosody` runs at 20 Hz.
  - `play_card` fires when a card's words appear in the final text.
  - Freeze rescue: after more than 1 s with no onset during a speaking bar while talking, it calls `/rescue`, then `rescue`, once per line.
  - The turn ends at `ends_at` or on Done: finalize, wait for the flush (1.5 s at most), then `end_turn`.
- **Fallback:** if the agent or Cartesia is unreachable, the poet's screen offers typing. This is a dev fallback; with a key, the demo path is voice.
- **Simulator caveat:** on the iOS 27 simulators, `AVAudioEngine.inputNode` can deadlock in `AURemoteIO::Initialize` ("RPC timeout. Apparently deadlocked. Aborting now"). Test voice on a device, or on the Mac as Designed for iPad.
- **Still to build:** TTS playback for Homer (AVAudioPlayerNode over the TTS socket), the arena's beat with ducking, and pre-rendered fixed lines (first open, rescue whispers).

## Live tests still to run

**Setup:** the probe lives in the swift session's scratchpad, not the repo:

`/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/2ad722dd-4ba3-4bf9-a094-3e6eeba175bb/scratchpad/voice-probe/`

It contains:
- `fixtures.py`: a four-line verse spoken by macOS `say`, a 90 BPM drum loop, and mixes at +12, +6 and 0 dB plus 0 dB with the 150 Hz high-pass. These are already generated.
- `probe.py`: all live calls go through an access token in the query string, the same path a browser uses.

Run from that directory with `CARTESIA_API_KEY` set in your shell only:

1. `.venv/bin/python probe.py stt`
   - Covers ink-2, ink-2 with keyterms, and ink-whisper, against each fixture.
   - Prints connect time, time to first text, `finalize` to last final, and whether `words[]` appears on finals or partials. It also prints the first word's `start` (it should be about 0.5 if timestamps count from the stream start), the median lag from word end to arrival, and WER.
2. `.venv/bin/python probe.py tts`: socket setup time, plus time to first audio and total time for each candidate voice (two takes each). It writes `out/tts_<voice>.wav` to listen to.
3. `.venv/bin/python probe.py token-expiry`: streams 30 s on a 10-second token.

**Still manual:**
- The real room at demo volume: arena speakers, an iPhone held close versus at the chest, the beat on versus ducked. Compare transcripts.
- Option C on an iPhone: page plays the beat while recording; does the transcript stay clean?
- The arena's `outputLatency` on the demo laptop with the actual TV or speakers.
- First-partial latency and word-lag from a real phone on venue Wi-Fi, not the laptop.

The fixtures are synthetic: a clean TTS voice mixed digitally with no room, no phone AGC and no noise suppression. Treat the probe's bleed numbers as an optimistic lower bound.

## Handoffs (suggestions; the owners decide)

- **`homer/` (agent service):**
  - `POST /voice/token` is live (builder). It returns 503 until `CARTESIA_API_KEY` is set on the server.
- **`ios/`**: built, see "iOS implementation" above.
- **`spacetime/` (multiplayer owns the contract):**
  - The arena needs the speaking-bar state to duck the beat.
  - Phones need `startedAt` and `bpm` for the turn, and a whisper-window event (option G).
- **`Contracts.swift`:** `BeatWord.t` works with the clock math above. Consider adding an `onsetsMs: number[]` to `BeatLane` so the live layer and the replay don't depend on STT `words[]`.

## Sources

- Cartesia STT WebSocket (manual): https://docs.cartesia.ai/api-reference/stt/websocket
- Cartesia STT turns WebSocket: https://docs.cartesia.ai/api-reference/stt/turns/websocket
- STT models and endpoint comparison: https://docs.cartesia.ai/build-with-cartesia/stt/latest, https://docs.cartesia.ai/use-the-api/stt/compare-endpoints, https://docs.cartesia.ai/build-with-cartesia/stt/older-models
- STT audio input: https://docs.cartesia.ai/build-with-cartesia/stt/audio-input
- Ink-2 page (latency, noise robustness, pricing): https://www.cartesia.ai/ink
- Ink-Whisper launch benchmark: https://www.cartesia.ai/blog/introducing-ink-speech-to-text
- Client auth and access tokens: https://docs.cartesia.ai/get-started/authenticate-your-client-applications
- TTS WebSocket: https://docs.cartesia.ai/api-reference/tts/websocket
- TTS continuations: https://docs.cartesia.ai/build-with-cartesia/capability-guides/stream-inputs-using-continuations
- TTS endpoint comparison: https://docs.cartesia.ai/use-the-api/compare-tts-endpoints
- TTS models: https://docs.cartesia.ai/build-with-cartesia/tts-models/latest
- Sonic overview (TTFA claims): https://www.cartesia.ai/sonic
- Choosing a voice: https://docs.cartesia.ai/build-with-cartesia/capability-guides/choosing-a-voice
- Voice pages: https://www.cartesia.ai/voices/library/damon-commanding-narrator-dbfa416f-d5c3-4006-854b-235ef6bdf4fd, https://www.cartesia.ai/voices/library/carl-steady-storyteller-ed82c17b-4704-4d34-be43-5d19065acdf1, https://www.cartesia.ai/voices/library/benedict-royal-narrator-7cf0e2b1-8daf-4fe4-89ad-f6039398f359
- Echo cancellation scope (MDN): https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/echoCancellation
