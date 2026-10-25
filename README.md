# MeNIN

**A live voice poetry battle, judged out loud by Homer.** MeNIN trains your voice the way the Greeks did, like a sport: Homer teaches you to improvise poetry out loud, you spar with him, you battle other poets live, you debate the way Socrates did, and then you play Greek games with your friends. Most AI talks for you. MeNIN makes you talk. One big screen, with your iPhone as the mic and the controller.

μῆνιν (*mēnin*, "MAY-nin") means **rage**. It's the first word of the Iliad.

**Try it: https://play.206.189.237.157.sslip.io** (open it on a laptop, choose Homer, and "Host a battle" makes it the arena; https://play.206.189.237.157.sslip.io/homer goes straight in) · **iPhone app:** https://testflight.apple.com/join/r9KCHkhc (live once Apple approves the beta; submitted Sun 3:27 AM) · **Video:** https://youtu.be/gvGEeuahLdE (2:41) · **Devpost:** [Devpost link] · **Figma:** [stage log deck](https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm), [design file](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv) · prototypes: [first open → practice](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102), [a full battle](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364)

Built at Cal Hacks 13.0 by Matus, Sunya and Paul, with a team of Claude Code sessions. Original score by Paul. (See Credits.)

## What it is

One screen is the arena: our website at https://play.206.189.237.157.sslip.io, open in any laptop browser. Every player's iPhone is their mic and their private cards.

- **The poetry battle** (the main event). Homer writes a fresh theme every round and coins each poet a fresh epithet. Your phone shows three of Homer's phrases, stock phrases that fit the theme and the beat, the way Homer himself improvised. They're optional: "Stuck? Use one of Homer's phrases. It scores Craft." There's no metronome: the beat is how Homer trains you, and in battle you spit free. 3, 2, 1, SPEAK, and you get one window with a countdown ring, into a hands-free mic. Go quiet for about two and a half seconds, and he whispers you a phrase that fits. Within seconds of your last word, he judges you out loud on Image, Answer and Craft, out of 100, and quotes your best line. At the end, he stitches everyone's lines into one song and crowns a champion.
- **The Socratic debate**, hosted by Socrates in his own voice. You argue a side you didn't choose, with a hand of rhetorical moves, on 22 real dilemmas from Homer's world and Greek thought, like Achilles' own choice: a long, forgotten life, or a short one, sung forever.
- **The discus**: swing your phone and lift your thumb to release. Homer calls the throw.
- **Talk to Homer**: say a verse, and Homer answers out loud in two sentences. He quotes you, gives you one fix and scores it.
- **The Stadion**: pump your arms with the phone like a sprinter; everyone races at once on the screen.
- **Pygmachia** (boxing, beta): your phone is your fist; the server resolves every punch. **Toxeia** (archery, beta): the laptop's webcam tracks your bow arm and your draw, and your own phone looses the arrow.
- **Bard mode**: six short lessons (the beat, the formula, the epithet, the turn, the answer, the boast). Lesson one opens with the first line of the Iliad, whose first word in Greek is *mēnin*, our name. **Practice mode**: spar with Homer.
- *Experimental:* no install needed. A judge or friend can play from their own phone's browser at `https://play.206.189.237.157.sslip.io/join/CODE?web=1` → "Play in your browser" (poetry and Talk to Homer only).

**Who it's for:** spoken-word and slam poets, who practice alone between weekly open mics with no one to tell them whether their beat landed. Battling friends, and the Greek games after, are why a room opens it again.

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
    Moss → the three phrases that fit the theme
    backstop: a turn left in judging 6 s → judged straight from SpacetimeDB
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
| Final transcript after the end of speech | 62–81 ms |
| Homer's first audio, from the arena laptop on Wi-Fi | 78–90 ms |

**How we measured** (receipt: [`docs/voice-wer/`](docs/voice-wer/), with the scripts and the raw output, Fri Oct 23): a four-line verse spoken by a synthetic voice (macOS `say`), mixed digitally with a 90 BPM drum loop at +12, +6 and 0 dB, then run through ink-2 with and without keyterms (the verse's own formulas, the way the phone sends its dealt phrases). These are test recordings, not a real phone mic in a loud room, so treat them as a best case. Battles no longer play a drum, so at the table the noise is the hall; lessons still play it. We haven't yet measured a real phone mic in a loud room.

**In lessons, the beat lane isn't STT.** Hits come from syllable onsets detected on the phone itself, because STT timing arrives too late to drive a live hit.

**Known limitations:**
- Loud rooms. Our mitigations: wired headset mics, a mic that opens only on your turn, and battles in free verse, so nothing plays under a speaking poet.
- Accents, names, slang and loanwords. The transcript is always on screen, so you see what Homer heard, and the stress scanner flags uncertain syllables instead of marking them wrong.

## SpacetimeDB: the hall

**The server runs the game, so every phone is just a screen.** One module (`spacetime/src/index.ts`, about 2,070 lines of TypeScript) runs all seven games. It has 27 tables (20 public), 45 reducers and four scheduled timers, and it's live on Maincloud as `homer-calhacks`.

- **The server decides, so nobody can fake a score.** Phones send only inputs. An arrow's landing (the drop from a soft draw, the wind drift, the 10 rings) and a punch's damage, stamina and counters are computed in the module. Only Homer's agent identity can post a poetry score (`post_score` and 6 other reducers check a service identity).
- **Live input at 10–20 Hz through reducers:** the speaking poet's voice, Stadion strides, boxing fists, and archery's bow aim, draw and webcam pose tracking (about 40 updates a second in archery).
- **Three kinds of client on one module:** the iPhone app (Swift SDK), the website arena (TypeScript SDK 2.13) and the Python agent (HTTP API, its own identity).
- **The verdict never depends on the arena tab.** If the arena's browser stalls, Homer's agent picks up any turn left in judging for 6 s and judges it from the database itself: the transcript, the theme and the dealt hand.
- **Tested like a backend:** `npm run smoke` runs 232 checks across all seven games, `scripts/hall-soak.ts` plays five battles on real websockets with drops and rejoins, and `npm run watch` prints the live timeline from Maincloud.

- **The battle is a phase machine in reducers**, server-side: lobby → theme → dealing → ready → speaking → judging → scored → round end → finale → finished. A scheduled reducer closes each turn on time. The rules are in [`spacetime/CONTRACT.md`](spacetime/CONTRACT.md).
- **Row-level security guards your cards:** a client visibility filter on the `hand` table means only your phone can read the phrases Homer dealt you.
- **The speaking phone streams loudness and pitch about 20 times a second** into one row per room that the arena subscribes to, so the scene moves with whoever is speaking.
- **A phone that drops loses nothing.** Lose the network mid-battle and it comes back on the right screen by itself, with no relaunch (tested on a real iPhone in airplane mode). A new connection with the same name takes a disconnected seat back with its score (`join_room`; covered by `npm run smoke` and `hall-soak.ts`).
- **The iPhone client** runs on the community Swift SDK [avias8/spacetimedb-swift](https://github.com/avias8/spacetimedb-swift) 0.23.0 (Clockwork Labs has no official Swift SDK), vendored in `ios/Vendor/SpacetimeDB` with three fixes for bugs that showed up on real phones:
  - Every phone was subscribed to every table on connect, so it would have received every room's 20 Hz stream. Now the app's own per-room subscriptions decide what a phone holds.
  - When subscriptions overlap, each row is listed once, not twice.
  - A reconnect replaces each table's cached rows, so a phone that drops comes back on the right screen instead of keeping ghost rows.
  - **The fixes are public and sent upstream:** our fork [Matusvec/spacetimedb-swift](https://github.com/Matusvec/spacetimedb-swift) has the fixes, their tests (`swift test`: 86 passed, 0 failures) and a [FORK.md](https://github.com/Matusvec/spacetimedb-swift/blob/menin-fixes/FORK.md) on how they were tested; the draft PR is [avias8/spacetimedb-swift#3](https://github.com/avias8/spacetimedb-swift/pull/3). The license is unchanged: SpacetimeDB's Business Source License 1.1.

## Claude: the judge, the coach, the MC

- **Homer is a live agent doing real work:** he writes every round's theme, coins every poet a fresh epithet, judges every verse, coaches you through lessons, hosts the battle and writes the stitched song.
- **The judge** is one streamed call to Claude Opus 5.5 (fast mode, low effort) with a cached system prompt and a JSON schema, so the output is always valid. Verdict text in **p50 0.9 s, p95 1.9 s**, the whole judgment in p50 1.0 s, p95 2.0 s, over 10 live calls on the current judge, from a laptop calling the API ([`homer/bench/latency-2026-10-24.txt`](homer/bench/latency-2026-10-24.txt), from `homer/scripts/latency.py`).
- **Battles are judged on content:** Image ×4, Answer ×4 and Craft ×2, out of 100, on an anchored scale where a typical first-timer verse lands at 4 to 6 out of 10. Claude gets the phrases Homer dealt you, the verse you're answering and the stress scanner's output. **The beat is never the model's opinion:** in the lessons, a deterministic stress scanner (CMU Pronouncing Dictionary) scores Beat. Range comes from an emotion classifier (Claude Haiku 5.5) that reads your words and voice every ~1.5 s; it paints the scene and isn't scored.
- **Built with Claude, too:** the whole app was built by two designers and a team of Claude Code sessions (leader, product, art, multiplayer, iOS, agent service and go-to-market), each in its own folder, working from one spec ([`SPEC.md`](SPEC.md)). More than 95% of the commits are co-authored by Claude.

## Apify: Epithet Miner

**Epithet Miner is an Apify Actor, built with AI chat:** Claude Opus 5.5 in Claude Code wrote it from our prompts. It mined nearly a third of the phrase bank (55 of 180), and in play about one in five cards Homer deals is a mined phrase ([`homer/bench/mined-share-2026-10-24.txt`](homer/bench/mined-share-2026-10-24.txt)): the cards on your phone, the Craft you score, the line Homer whispers when you freeze. The code is in [`apify/`](apify/), and it's on the Apify Store: [apify.com/matusnator/epithet-miner](https://apify.com/matusnator/epithet-miner) (Actor ID `v4i7ItNXjHMmnKzfo`). It reads four public-domain Homer translations from Project Gutenberg and finds noun-epithet formulas with readable rules, no language model. Then it counts their beats with our scanner's rule and ranks them by how often they recur. It mined 150 candidates. Our product session (a Claude Code agent) kept 55, so the bank grew from 158 to 213 (180 now, after modern phrases were cut for Homer's world: 55 of 180 are mined, nearly a third). It runs at build time by design, so a battle never waits on a crawl; rerun it on another translation and the dealer has new cards. How it was built, honestly: [`apify/BUILD_LOG.md`](apify/BUILD_LOG.md).

## Moss: dealing that fits the theme

Homer writes a fresh theme every round, always from his own world (nothing invented after the Bronze Age), so no tag list can know it in advance. The dealer uses [Moss](https://moss.dev) to rank all 180 formulas by meaning against the theme, then deals Homer's phrases from the closest matches. Same seed, "The night before the battle": the tag dealer deals "the sea-wolf" and "the holy night"; Moss deals "the battle-sweat" and "the last to leave". Measured on our production droplet (1 vCPU, inside the live agent container), 180-formula bank, 40 runs ([`homer/bench/moss-2026-10-24-droplet.txt`](homer/bench/moss-2026-10-24-droplet.txt)): a ranked lookup p50 13.2 ms, p95 14.9 ms. **Fresh themes only work because of Moss:** a tag list can't know a theme Homer wrote ten seconds ago. It can't stall a battle either: it runs behind `HOMER_DEALER=moss`, and if Moss is slow (over 500 ms) or errors, the tag dealer deals instead.

## Fetch.ai: Homer on Agentverse

**Homer outside the hall:** Homer's dealer and judge also run as the agent **homer-bard** on Agentverse (`agent1qf8cydj43pd7tue06mk9avnp45avcc4ss9gjm98r4lkjczsw0gskzw97edc`), speaking the Agent Chat Protocol, so a battle turn can happen in an ASI:One chat: ask for a theme and get five formulas, then send a verse and get judged. It runs in its own container, so a busy chat never slows a live battle. See [`homer/AGENTVERSE.md`](homer/AGENTVERSE.md). Try it: [ASI:One link].

## Figma

Two designers: Matus drew the app's first concept in Figma Design, and Paul made the website in **Figma Make**. The art session reads frames, exact values and assets straight from the files through the Figma MCP server. Every design token is a Figma variable named after its Swift code, with one mode per look (Atelier, Cut paper and Hall). So when the app took on the website's palette, the reskin was one new mode in Figma and one new case in code: the website's 128 hard-coded colors became 37 tokens, and 119 views restyled with no edits. The full stage log, with the friction, is in our Figma Slides deck: https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm. PNG copies of the frames are in [`docs/figma/`](docs/figma/), and the process is in [`docs/gtm/figma-stage-log.md`](docs/gtm/figma-stage-log.md).

## Impact and responsibility

- **Who it's for, and how we measure it:** spoken-word and slam poets. The stress scanner's Beat score is an objective skill measure, and every lesson try gets one, so a poet sees their first try against their last. Next, we track Beat accuracy across a poet's first five sessions.
- **Accessibility:** captions on everything Homer says. In battles, a haptic thump and the 3-2-1 ticks tell you your turn has started; in lessons, the beat is in your palm as haptics, so you can feel it without hearing it.
- **Consent:** the mic is hands-free but opens only on your turn, with a haptic thump, and "I'm done" closes it early.
- **Privacy:** no audio passes through our server, because phones stream straight to Cartesia. Transcripts, scores and lines live in the room's tables on SpacetimeDB, and Rematch clears them. Cartesia's standard data terms apply on our plan (zero data retention is an Enterprise option). No account is required.
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

**Website** (`homer/web/`, React + Vite): `pnpm install && pnpm run dev` for local work, `pnpm run build` for the static files. Deploying is `homer/scripts/web_deploy.sh` (see [`homer/DEPLOY.md`](homer/DEPLOY.md)). The live one is at https://play.206.189.237.157.sslip.io (the arena: `/homer`).

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

## Credits

- **Matus, Sunya and Paul** built MeNIN at Cal Hacks 13.0. Matus designed the app; Paul made the website in Figma Make.
- **Original score by Paul.**
- **A team of Claude Code sessions** co-authored more than 95% of the commits, working from one spec.
- The Iliad and Odyssey lines in the lessons are from public-domain translations: Lang, Leaf and Myers (1883) and Butcher and Lang (1879). The Epithet Miner reads public-domain translations from Project Gutenberg.

## License

MIT. See [`LICENSE`](LICENSE). The one exception is the vendored Swift SDK in `ios/Vendor/SpacetimeDB`, which keeps its own SpacetimeDB Business Source License 1.1 ([`ios/Vendor/SpacetimeDB/LICENSE.txt`](ios/Vendor/SpacetimeDB/LICENSE.txt)), as does our public fork of it.
