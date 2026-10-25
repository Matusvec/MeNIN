<!--
Draft of the public repo README, written by gtm for the leader to paste into /README.md.
gtm doesn't edit files outside docs/gtm. Fill or delete every [bracket] before the repo goes public Sun 8 AM.
Sponsor judges may score asynchronously from this page and the video alone (Devpost criteria), so each sponsor's part has to stand on its own.
-->

# MeNIN

**Ancient Greek party games, hosted by Homer.** Battle in free verse, judged live by Homer, on one screen with your iPhone as the controller.

μῆνιν (*mēnin*, "MAY-nin") means **rage**. It's the first word of the Iliad.

**Try it: [URL]** (open it on a laptop and it's the arena) · **iPhone app:** [TestFlight link] · **Video:** [link] · **Devpost:** [link] · **Figma:** [design file](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv) · prototypes: [first open → practice](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102), [a full battle](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364)

Built at Cal Hacks 13.0 by [team: names and roles], with a team of Claude Code sessions. Original score by [composer's name].

## What it is

One screen is the arena: our website at [URL], open in any laptop browser. Every player's iPhone is their mic and their private cards.

- **The poetry battle** (the main event). Homer writes a fresh theme every round and coins each poet a fresh epithet. Your phone shows three of Homer's phrases, stock phrases that fit the theme and the beat, the way Homer himself improvised. They're optional: "Stuck? Use one of Homer's phrases. It scores Craft." There's no metronome: the beat is how Homer trains you, and in battle you spit free. 3, 2, 1, SPEAK, and you get one window with a countdown ring, into a hands-free mic. Go quiet for about two and a half seconds, and he whispers you a phrase that fits. About three seconds after your last word, he scores you on five axes and quotes your best line. At the end, he stitches everyone's lines into one song and crowns a champion.
- [If it passed] **The Socratic debate**, hosted by Socrates in his own voice.
- **The discus**: swing your phone and lift your thumb to release. Homer calls the throw.
- **Talk to Homer**: speak, and Homer answers out loud in two sentences, quoting you, with one fix. A conversation, no score.
- [If it passed] **The Stadion**: pump your arms with the phone like a sprinter; everyone races at once on the screen.
- **Bard mode** (lessons) and **Practice mode** (spar with Homer).

**Who it's for:** spoken-word and slam poets in [the poet's scene], who practice alone between weekly open mics with no one to tell them whether their beat landed. The party games are why a room of friends opens it again.

## How it works

```
iPhone (player)                         website in a browser (arena)
  mic → on-device syllable onsets ──────► beat lane hits (lessons)
  mic → Cartesia ink-2 STT (keyterms) ──► live transcript
  loudness + pitch, 20 Hz ──┐
                            ▼
                     SpacetimeDB (rooms, turns, scores, private cards)
                            ▲
  Agent service (Python, FastAPI, DigitalOcean)
    stress scanner (CMU dictionary) → Beat (lessons)
    Claude → Image, Answer, Craft (out of 100), the verdict, the song
    Cartesia token minting ──────────────► Cartesia TTS (Homer's voice) on the arena
```

Four deployables: the iOS app (`ios/`), the website (`homer/web/`, static files served from our droplet), the SpacetimeDB module (`spacetime/`) and the agent service (`homer/`).

## Cartesia: ears and voice

Voice is the whole game: you play by speaking, and Homer answers out loud.

| Feature | How we use it |
| --- | --- |
| **ink-2 streaming STT** over WebSocket | The live transcript of every verse. We send **every phrase Homer dealt the poet, plus the theme, as keyterms**, so rare phrases like "rose-fingered Dawn" and "the wine-dark sea" survive the noise. |
| **sonic-3.6 TTS**, voice Carl ("Steady Storyteller") | Homer: entrances, verdicts, the freeze whisper, lessons and the stitched song |
| **Short-lived access tokens** | Our server mints a token, and the phone streams straight to Cartesia. No audio passes through our server, and the API key never leaves it. |

**Measured:**

| | Result |
| --- | --- |
| Word error rate, a drum at full volume (0 dB) as test noise, **with keyterms** | **3%** |
| Same, **without keyterms** | 20% |
| Final transcript after the poet stops | about 75 ms |
| Homer's first audio | about 100 ms |

**How we measured:** a four-line verse spoken by a synthetic voice (macOS `say`), mixed digitally with a 90 BPM drum loop at +12, +6 and 0 dB, then run through ink-2 with and without keyterms (five dealt phrases). These are test recordings, not a real phone mic in a loud room, so treat them as a best case. Battles no longer play a drum, so at the table the noise is the hall; lessons still play it. [real-mic WER: replace or add swift's iPhone-mic numbers.]

**In lessons, the beat lane isn't STT.** Hits come from syllable onsets detected on the phone itself, because STT timing arrives too late to drive a live hit.

**Known limitations:**
- Loud rooms. Our mitigations: wired headset mics, a mic that opens only on your turn, and battles in free verse, so nothing plays under a speaking poet.
- Accents, names, slang and loanwords. The transcript is always on screen, so you see what Homer heard, and the stress scanner flags uncertain syllables instead of marking them wrong.

## SpacetimeDB: the hall

- **The battle is a phase machine in reducers**, server-side: lobby → theme → dealing → ready → speaking → judging → scored → round end → finale → finished. A scheduled reducer closes each turn on time. The rules are in [`spacetime/CONTRACT.md`](spacetime/CONTRACT.md).
- **The phrases Homer deals you sit in a private table** that only your phone can read.
- **Every phone streams loudness and pitch at about 20 Hz** into one table the arena subscribes to, so the arena's scene moves with whoever is speaking.
- **A phone that dies can rejoin** and take its seat back with its score. [Keep this only if it passed in the 5 PM gate's take 2.]
- **The iPhone client** is the community Swift SDK [avias8/spacetimedb-swift](https://github.com/avias8/spacetimedb-swift) 0.23.0, vendored with two patches (`ios/Vendor/SpacetimeDB/README.md`):
  - Upstream subscribes every client to whole tables, which would send every phone every room's 20 Hz stream. Ours subscribes per room.
  - When subscriptions overlap, rows are listed once.

## Claude: the judge, the coach, the MC

- **Homer is a live agent doing real work:** he writes every round's theme, coins every poet a fresh epithet, judges every verse, coaches you through lessons, hosts the battle and writes the stitched song.
- **The judge** is one streamed call to Claude Opus 5.5 (fast mode, low effort) with a cached system prompt and a JSON schema, so the output is always valid. Verdict text in **p50 1.0 s, p95 1.5 s** (10 live calls, Fri Oct 23; `homer/scripts/latency.py`).
- **Battles are judged on content:** Image ×4, Answer ×4 and Craft ×2, out of 100, on an anchored scale where a typical first-timer verse lands at 4 to 6 out of 10. Claude gets the phrases Homer dealt you, the verse you're answering and the stress scanner's output. **The beat is never the model's opinion:** in the lessons, a deterministic stress scanner (CMU Pronouncing Dictionary) scores Beat. Range comes from an emotion classifier (Claude Haiku 5.5) that reads your words and voice every ~1.5 s; it paints the scene and isn't scored.
- **Built with Claude, too:** the whole app was built by a team of Claude Code sessions (leader, product, art, multiplayer, iOS, agent service and go-to-market), each in its own folder, working from one spec ([`SPEC.md`](SPEC.md)).

## Apify: Epithet Miner

**Epithet Miner is an Apify Actor, built with AI chat:** Claude Opus 5.5 in Claude Code wrote it from our prompts. It mined part of the stock-phrase bank. The code is in [`apify/`](apify/), and it's on the Apify Store: [apify.com/matusnator/epithet-miner](https://apify.com/matusnator/epithet-miner) (Actor ID `v4i7ItNXjHMmnKzfo`). It reads four public-domain Homer translations from Project Gutenberg and finds noun-epithet formulas with readable rules, no language model. Then it counts their beats with our scanner's rule and ranks them by how often they recur. It mined 150 candidates. A person kept 55, so the bank grew from 158 to 213 (180 now, after modern phrases were cut for Homer's world: 55 of 180 are mined, nearly a third). It runs at build time only, and the game never calls Apify. How it was built, honestly: [`apify/BUILD_LOG.md`](apify/BUILD_LOG.md).

## Moss: dealing that fits the theme

Homer writes a fresh theme every round, always from his own world (nothing invented after the Bronze Age), so no tag list can know it in advance. The dealer uses [Moss](https://moss.dev) to rank all 180 formulas by meaning against the theme, then deals Homer's phrases from the closest matches. So in our tests the query "my grandmother's kitchen" (a test, not a game theme) finds "the high-roofed hall" with no shared word. Measured on our production droplet (2 GB, CPU only), on the earlier 213-formula bank: p50 13.7 ms, p95 32.2 ms. It runs behind `HOMER_DEALER=moss`, and if Moss is slow (over 500 ms) or errors, the tag dealer deals instead.

## Fetch.ai: Homer on Agentverse

[Keep only if it's live.] Homer's dealer and judge also run as the agent **homer-bard** on Agentverse (`agent1qf8cydj43pd7tue06mk9avnp45avcc4ss9gjm98r4lkjczsw0gskzw97edc`), with the Agent Chat Protocol, so a whole battle turn works inside an ASI:One chat. Ask for a theme and get five formulas, then send a verse and get judged. It sits behind a switch, off the demo path. See [`homer/AGENTVERSE.md`](homer/AGENTVERSE.md). Try it: [ASI:One link].

## Figma

Matus drew the first concept in Figma Design. The art session reads frames, exact values and assets straight from the file through the Figma MCP server. We compared two design directions in one variable collection with two modes, every variable carrying its Swift name, and picked Atelier, the look that ships. The clickable prototypes and the stage log are linked above and in our Figma Slides deck: [link].

## Impact and responsibility

- **Who it's for, and how we measure it:** spoken-word and slam poets in [the poet's scene]. The stress scanner's Beat score is an objective skill measure. At Cal Hacks, [N] people who'd never freestyled took lesson one, and their Beat score went from [first] to [last] out of 10. Next, we track Beat accuracy across a poet's first five sessions.
- **Accessibility:** captions on everything Homer says. In battles, a haptic thump and the 3-2-1 ticks tell you your turn has started; in lessons, the beat is in your palm as haptics, so you can feel it without hearing it.
- **Consent:** the mic is hands-free but opens only on your turn, with a haptic thump, and "I'm done" closes it early.
- **Privacy:** no audio passes through our server, because phones stream straight to Cartesia. Transcripts, scores and lines live in the room's tables, and Rematch clears them. [Confirm before publishing: how long finished rooms are kept, and Cartesia's retention setting on our account.] No account is required.
- **Content:** a verse that isn't fit for the hall scores nothing, and Homer won't quote it. Names are filtered before Homer says them.
- **The emotion read is art, not diagnosis.** It colors the scene, and Homer never names your emotion.
- **A roast can sting a beginner,** so roasts stay gentle and only in battles. In lessons, Homer is a calm coach.

## Run it

**iOS app** (Xcode, iOS 18+):
```bash
cd ios
xcodegen generate        # Homer.xcodeproj is generated, not committed
open Homer.xcodeproj     # set your own signing team, then run on an iPhone
```
The optional app key goes in `ios/Homer/Support/Secrets.xcconfig` (gitignored).

**Website** (`homer/web/`): [how to build and serve it]. The live one is at [URL].

**Agent service:** see [`homer/README.md`](homer/README.md). Copy `homer/.env.example` to `homer/.env`, then add your Anthropic and Cartesia keys.

**SpacetimeDB module:** see [`spacetime/HOSTING.md`](spacetime/HOSTING.md) and [`spacetime/CONTRACT.md`](spacetime/CONTRACT.md).

## Repo map

| Folder | What's in it |
| --- | --- |
| `ios/` | The universal SwiftUI app: audio, haptics, Metal scene, UI, the vendored SpacetimeDB SDK |
| `homer/web/` | The website: the arena in a browser, on SpacetimeDB's TypeScript SDK |
| `spacetime/` | The SpacetimeDB module (TypeScript) and its contract |
| `homer/` | The agent service: the judge, the scanner, the dealer, voice tokens |
| `content/` | Lessons and the formula bank |
| `docs/` | The UX flow, voice research, the music brief, and go-to-market (`docs/gtm/`) |
