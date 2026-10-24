<!--
Draft of the public repo README, written by gtm for the leader to paste into /README.md.
gtm doesn't edit files outside docs/gtm. Fill or delete every [bracket] before the repo goes public Sun 8 AM.
Sponsor judges may score asynchronously from this page and the video alone (Devpost criteria), so each sponsor's part has to stand on its own.
-->

# MeNIN

**Ancient Greek party games, hosted by Homer.** Battle in verse over the beat, judged live by Homer, on one screen with your iPhone as the controller.

μῆνιν (*mēnin*, "MAY-nin") means **rage**. It's the first word of the Iliad.

**Video:** [link] · **Devpost:** [link] · **TestFlight:** [link] · **Figma:** [design file](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv) · prototypes: [first open → practice](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102), [a full battle](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364)

Built at Cal Hacks 13.0 by [team: names and roles], with a team of Claude Code sessions. Original score by [composer's name].

## What it is

One screen is the arena: a Mac or an iPad running the app. Every player's iPhone is their mic and their private hand of cards.

- **The poetry battle** (the main event). Homer deals you five stock phrases that fit the beat, the way Homer himself improvised. He drops a slow drum, which you feel in your palm through haptics, and you speak up to four lines. Freeze, and he whispers you a line. About three seconds after your last word, he scores you on five axes and quotes your best line. At the end, he stitches everyone's lines into one song and crowns a champion.
- [If it passed] **The Socratic debate**, hosted by Socrates in his own voice.
- [If it passed] **The discus**: swing your phone and lift your thumb to release.
- **Bard mode** (lessons) and **Practice mode** (spar with Homer).

**Who it's for:** spoken-word and slam poets in [the poet's scene], who practice alone between weekly open mics with no one to tell them whether their beat landed. The party games are why a room of friends opens it again.

## How it works

```
iPhone (player)                         Mac or iPad (arena)
  mic → on-device syllable onsets ──────► beat lane hits
  mic → Cartesia ink-2 STT (keyterms) ──► live transcript
  loudness + pitch, 20 Hz ──┐
                            ▼
                     SpacetimeDB (rooms, turns, scores, private hands)
                            ▲
  Agent service (Python, FastAPI, DigitalOcean)
    stress scanner (CMU dictionary) → Beat
    Claude → Craft, Image, Answer, the verdict, the song
    Cartesia token minting ──────────────► Cartesia TTS (Homer's voice) on the arena
```

Three deployables: the iOS app (`ios/`), the SpacetimeDB module (`spacetime/`) and the agent service (`homer/`).

## Cartesia: ears and voice

Voice is the whole game: you play by speaking, and Homer answers out loud.

| Feature | How we use it |
| --- | --- |
| **ink-2 streaming STT** over WebSocket | The live transcript of every verse. We send the poet's **hand of five formulas as keyterms**, so rare phrases like "rose-fingered Dawn" and "the wine-dark sea" survive the drum. |
| **sonic-3.6 TTS**, voice Carl ("Steady Storyteller") | Homer: entrances, verdicts, the freeze whisper, lessons and the stitched song |
| **Short-lived access tokens** | Our server mints a token, and the phone streams straight to Cartesia. No audio passes through our server, and the API key never leaves it. |

**Measured:**

| | Result |
| --- | --- |
| Word error rate, drum at full volume (0 dB), **with keyterms** | **3%** |
| Same, **without keyterms** | 20% |
| Final transcript after the poet stops | about 75 ms |
| Homer's first audio | about 100 ms |

**How we measured:** a four-line verse spoken by a synthetic voice (macOS `say`), mixed digitally with a 90 BPM drum loop at +12, +6 and 0 dB, then run through ink-2 with and without keyterms. These are test recordings, not a real phone mic in a loud room, so treat them as a best case. [real-mic WER: replace or add swift's iPhone-mic numbers.]

**The beat lane isn't STT.** Hits come from syllable onsets detected on the phone itself, because STT timing arrives too late to drive a live hit.

**Known limitations:**
- Loud rooms. Our mitigations: wired headset mics, push-to-talk, the beat moved into haptics, and the arena drum ducked while you speak.
- Accents, names, slang and loanwords. The transcript is always on screen, so you see what Homer heard, and the stress scanner flags uncertain syllables instead of marking them wrong.

## SpacetimeDB: the hall

- **The battle is a phase machine in reducers**, server-side: lobby → theme → dealing → ready → speaking → judging → scored → round end → finale → finished. A scheduled reducer closes each turn on time. The rules are in [`spacetime/CONTRACT.md`](spacetime/CONTRACT.md).
- **Your hand is in a private table** that only your phone can read.
- **Every phone streams loudness and pitch at about 20 Hz** into one table the arena subscribes to, so the arena's scene moves with whoever is speaking.
- **A phone that dies can rejoin** and take its seat back with its score. [Keep this only if it passed the Sat 2 PM test.]
- **The iPhone client** is the community Swift SDK [avias8/spacetimedb-swift](https://github.com/avias8/spacetimedb-swift) 0.23.0, vendored with two patches (`ios/Vendor/SpacetimeDB/README.md`):
  - Upstream subscribes every client to whole tables, which would send every phone every room's 20 Hz stream. Ours subscribes per room.
  - When subscriptions overlap, rows are listed once.

## Claude: the judge, the coach, the MC

- **Homer is a live agent doing real work:** he names every poet, judges every verse, coaches you through lessons, hosts the battle and writes the stitched song.
- **The judge** is one streamed call to Claude Opus 5.5 (fast mode, low effort) with a cached system prompt and a JSON schema, so the output is always valid. Verdict text in **p50 1.0 s, p95 1.5 s** (10 live calls, Fri Oct 23; `homer/scripts/latency.py`).
- **Beat is never the model's opinion.** A deterministic stress scanner (CMU Pronouncing Dictionary) counts it, and Claude gets that count with your hand and the verse you're answering. Range comes from an emotion classifier (Claude Haiku 5.5) that reads your words and voice every ~1.5 s.
- **Built with Claude, too:** the whole app was built by a team of Claude Code sessions (leader, product, art, multiplayer, iOS, agent service and go-to-market), each in its own folder, working from one spec ([`SPEC.md`](SPEC.md)).

## Figma

Matus drew the first concept in Figma Design. The art session reads frames, exact values and assets straight from the file through the Figma MCP server. Both design directions live in one variable collection with two modes, and every variable carries its Swift name. The clickable prototypes and the stage log are linked above and in our Figma Slides deck: [link].

## Impact and responsibility

- **Who it's for, and how we measure it:** spoken-word and slam poets in [the poet's scene]. The stress scanner's Beat score is an objective skill measure. At Cal Hacks, [N] people who'd never freestyled took lesson one, and their Beat score went from [first] to [last] out of 10. Next, we track Beat accuracy across a poet's first five sessions.
- **Accessibility:** captions on everything Homer says. The beat is in your palm as haptics, so you can feel it without hearing it.
- **Consent:** in battles the mic is push-to-talk, open only while you hold it.
- **Privacy:** no audio passes through our server, because phones stream straight to Cartesia. Transcripts, scores and lines live in the room's tables, and Rematch clears them. [Confirm before publishing: how long finished rooms are kept, and Cartesia's retention setting on our account.] No account is required.
- **Content:** a verse that isn't fit for the hall scores nothing, and Homer won't quote it. Names are filtered before Homer says them.
- **The emotion read is art, not diagnosis.** It colors the scene, and Homer never names your emotion.
- **A roast can sting a beginner,** so roasts stay gentle and only in battles. In lessons, Homer is a calm coach.

## Run it

**iOS app** (Xcode, iOS 18+):
```bash
cd ios
xcodegen generate        # Homer.xcodeproj is generated, not committed
open Homer.xcodeproj     # set your own signing team, then run on an iPhone, an iPad or a Mac ("Designed for iPad")
```
The optional app key goes in `ios/Homer/Support/Secrets.xcconfig` (gitignored).

**Agent service:** see [`homer/README.md`](homer/README.md). Copy `homer/.env.example` to `homer/.env`, then add your Anthropic and Cartesia keys.

**SpacetimeDB module:** see [`spacetime/HOSTING.md`](spacetime/HOSTING.md) and [`spacetime/CONTRACT.md`](spacetime/CONTRACT.md).

## Repo map

| Folder | What's in it |
| --- | --- |
| `ios/` | The universal SwiftUI app: audio, haptics, Metal scene, UI, the vendored SpacetimeDB SDK |
| `spacetime/` | The SpacetimeDB module (TypeScript) and its contract |
| `homer/` | The agent service: the judge, the scanner, the dealer, voice tokens |
| `content/` | Lessons and the formula bank |
| `docs/` | The UX flow, voice research, the music brief, and go-to-market (`docs/gtm/`) |
