# Devpost draft

Paste this into Devpost. **Never submit a claim that isn't true on Sunday morning.** The guide recommends submitting a draft Saturday night and editing it until 9:00 AM.

**State: Sat Oct 24, 11:30 AM.** Everything outside `[brackets]` is true now. What's left:

| Placeholder | Kind | Comes from | When |
| --- | --- | --- | --- |
| `[N]`, `[first]`, `[last]`, `[time]` | **Number** | The first-timer study on build 4 (`docs/study.md`), using one of pm's line options | Sat 8 PM |
| `[real-mic WER]` | **Number** | swift's rerun of the keyterm test on a real iPhone mic. If it differs from 3%/20%, it replaces those numbers everywhere. | When swift runs it |
| `[turn-to-voice p50]` | **Number** | The measured time from a turn's end to Homer's first word, on build 4 (the 1:30 PM run's latency HUD) | Sat 1:30 PM |
| `[poet's name]`, `[the poet's scene]`, `[poet quote]`, `[composer's name]`, `[how the score was made]`, `[team]` | **A fact only Matus has** | Matus (the list went to leader) | Today |
| `[If debate passed]`, `[If discus passed]` | Checkpoint | The Sat 8 PM check: 5 runs in a row without a failure. Delete the section if the event failed. | Sat 8 PM |
| `[URL]` | Link | **The website** (SPEC, Sat 12:20 PM): the arena in a browser at a public HTTPS URL, served from the droplet. It's the first "try it" link. | When it's deployed |
| `[TestFlight public link]`, `[Video]`, `[Figma Slides]`, `[ASI:One link]` | Link | Apple's Beta App Review; [video.md](video.md); the Slides deck; builder | As each lands |

---

**Project name / title:** MeNIN: Ancient Greek Party Games, Hosted by Homer *(fallback: "MeNIN: Party Games of Ancient Greece")*

**Tagline** (200 chars): Rage is the first word of the Iliad. MeNIN turns it into party games: battle in verse over the beat, judged live by Homer, on one screen with your iPhone as the controller.

*Trademarks: no "Wii", "Wii Sports", "Guitar Hero" or "Olympic" anywhere in this page.*

**Try it:** **[URL]**: open it on a laptop and it becomes the arena, then join from your iPhone · iPhone app: [TestFlight public link] · [playmenin.tech, if registered] · Video: [Video] · Figma: [Figma Slides] · Clickable prototypes: [first open → practice](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102) · [a full battle](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364)

---

## Inspiration

The first word of Western literature is μῆνιν (*mēnin*, pronounced "MAY-nin"): **rage**. Homer opened the Iliad with a fight, and so do we.

**AI can write anything now. What it can't do is stand up in a room and move people for you.** That's becoming the skill that matters most, and the Greeks treated it as one you train in public, by contest: rhapsodes competing at the Panathenaic Games, citizens arguing in the Assembly, Socrates questioning strangers in the agora. Most AI talks for you. We wanted AI that makes you talk.

MeNIN is for spoken-word and slam poets in [the poet's scene]. [poet's name] is one of them. Open mics are once a week, and between them you practice alone in your room, with no one to tell you whether your beat landed. [poet quote: one line from a poet texted Saturday, with permission] Improvising out loud is a learnable skill: Homer did it with stock phrases built to fit the beat, and freestyle rappers do it every night. Almost nobody gets to practice it with friends.

So we built ancient Greek party games for your voice, with AI as the coach and the judge, never the speaker, and made the poetry battle the main event.

## What it does

The first time you open MeNIN, Homer speaks before any menu: "The first word of Western literature is *mēnin*. Rage. Give me one line." You say anything, the scene answers your voice, and Homer says, "Good. Now let me show you how I did it."

Homer is a live agent doing real work: he deals, listens, judges, coaches, hosts and writes the song from the room.

One screen is the arena: any laptop browser at [URL], or a Mac or an iPad running the app. Every player's iPhone is their controller. Scan the QR code or type the room code to join. No account needed.

| Event | Host | You |
| --- | --- | --- |
| **Poetry battle** (main event) | Homer | Improvise verse over the beat |
| [If debate passed] **Socratic debate** | Socrates | Argue a question in timed spoken turns |
| [If discus passed] **Discus** | Homer announces | Swing your phone; its motion sensors measure the throw |

Other events show as locked tiles, because we only unlock what's solid.

**The poetry battle.** Two to five poets in one room, three rounds. Each poet's iPhone is their mic and their private hand.
- Homer announces each poet by their epithet: "Enter Matus, Breaker of Deadlines!"
- Every turn you're dealt five formulas that fit the beat: "the whale-road", "grey-eyed Athena", "when rose-fingered Dawn came early".
- Homer drops a slow drum-and-lyre beat, and you feel it in your palm through haptics. The arena ducks the drum while you speak, so it doesn't bleed into your mic.
- You hold to talk and speak up to four lines, one per bar. Each stress that lands on the beat hits like a drum strike on the beat lane, and every formula you use flips onto the arena.
- Freeze for a second and your hand comes forward with one card raised, while Homer whispers you a line that fits.
- About three seconds after your last word, Homer delivers the verdict like a title-fight MC: five scores and your best line, quoted.
- The best line of each round is carved in gold across the arena.
- At the end, Homer becomes a rhapsode, a song-stitcher. He stitches every poet's lines into one song and performs it over the beat while the arena replays the battle's colors. Then he crowns the champion.

**The scene.** Behind everything, a full-screen procedural scene paints the speaker's voice: matte layers of painted color. Loudness and pitch move it at 60 fps, and every ~1.5 s an emotion read of your words and voice shifts its colors across eight palettes. Homer never names your emotion; the scene shows it.

**The score.** MeNIN has an original soundtrack composed by [composer's name], on our team: a hall and menu theme, an intro for each event, the discus throw and its fanfare, a champion sting, and ambience for training. Music never plays while a mic in the room is open. During a turn, only the procedural beat plays, and the music ducks under Homer's and Socrates' voices. [How the score was made: instruments, DAW, and whether any AI tools were used. Write it honestly.]

**Bard mode.** Short voiced lessons from Homer, one move each: the beat, the formula, the epithet. Homer shows the move, names it in a sentence, and gives you one note per try until you land it. The epithet you coin becomes your battle name.

**Practice mode.** Spar with Homer, best of three.

**[If debate passed] Socratic debate.** It's the same engine as the battle: timed spoken turns, the scene and a spoken verdict, with no beat. Socrates hosts in his own voice, and sides are dealt by turn order. Your hand holds rhetorical moves ("define your terms", "counterexample", "analogy"). Tap a move as you make it, and the judge checks that you really made it. Freeze, and Socrates whispers you a question to ask. It has its own five axes: Claim, Reason, Answer, Craft and Poise.

**[If discus passed] Discus.** Hold a button with your thumb, swing your iPhone, and lift your thumb to release. You never let go of the phone. Core Motion measures the swing and the release, the arena flies the throw, and Homer calls the distance. No voice, no AI: just physics and bragging rights.

## How we built it

- **One engine, many events.** Each event is a config: host, hand, rubric, turn length, beat on or off. [If debate passed: the debate took (hours) on top of the poetry engine.]
- **Universal iOS app (SwiftUI, iOS 18+, iPhone and iPad).** One app, every mode. A device runs it as the arena or as a player, and Apple Silicon Macs run it as the arena.
- **The website ([URL]).** The arena in a browser: static files served from our droplet over HTTPS, on SpacetimeDB's TypeScript SDK and the same agent service as the app. Phones join its room with the app, the same way they join a Mac arena.
  - AVAudioEngine captures the mic with voice processing.
  - Core Haptics plays the beat in your hand.
  - Metal shaders render the scene.
  - Syllable onsets detected on the phone itself drive the beat lane, so a hit never waits for the transcript.
  - Views take plain value models and never touch state, so the design could change twice without rewriting the logic.
- **SpacetimeDB** is the hall: rooms, players, rounds, turns, scores, the carved lines, the stitched song and the discus throws.
  - The whole battle is a phase machine in **reducers**, server-side, from lobby to theme, dealing, speaking, judging, round end, finale and champion. A scheduled reducer closes each turn on time.
  - Your hand is in a **private table** that only your phone can read, so nobody sees your cards.
  - Each phone streams loudness and pitch at about 20 Hz into a table the arena subscribes to, so the arena's scene moves with whoever is speaking.
  - The iPhone client is the community Swift SDK (avias8/spacetimedb-swift 0.23.0), vendored with two patches. Upstream subscribes every client to whole tables, which would send every phone every room's 20 Hz voice stream, so each phone now subscribes only to its own room. The second patch lists each row once when subscriptions overlap.
- **Cartesia** is the ears and the voice.
  - Streaming speech-to-text (**ink-2**, over WebSocket) writes the live transcript. We send the poet's hand of formulas as **keyterms**, so it hears "the wine-dark sea" through the drum. With the drum at full volume (0 dB) in our tests, the word error rate is **3% with keyterms and 20% without**. Those tests used recorded verse with the drum mixed in digitally. [real-mic WER] The final transcript arrives about **75 ms** after the poet stops.
  - The phone streams straight to Cartesia with a short-lived token from our server, so no audio passes through us.
  - Cartesia TTS is Homer (**sonic-3.6**, the voice Carl, "Steady Storyteller"), with first audio in about **100 ms**: lessons, entrances, verdicts, the freeze whisper and the stitched song.
- **Claude (Anthropic)** is the judge, the coach and the MC.
  - The judge gets your hand, the verse you're answering and the scanner's stress count. It returns five scores, the best line and a one-line verdict.
  - Each judgment is one streamed request to **Claude Opus 5.5**: fast mode, low effort, a cached system prompt and a JSON schema, so the output is always valid. Verdict text lands in **p50 1.0 s, p95 1.5 s** (10 live calls, Fri Oct 23, `homer/scripts/latency.py`).
  - Claude also names poets and coins epithets, writes Homer's lesson feedback, his sparring verses and the round verdicts, and writes the stitched song. The freeze whisper makes no model call: it picks the formula from your hand that fits the line, so it's instant.
- **The stress scanner** (Python, CMU Pronouncing Dictionary) counts the beat deterministically. The **Beat** score never comes from the model's opinion.
- **Python + FastAPI** service for the Claude calls, the scanner and the formula bank, in Docker behind Caddy on **DigitalOcean**.
- **Figma.** Matus drew the first concept in Figma Design. The art session reads frames, exact values and assets straight from the file through the Figma MCP server, so it builds from the design rather than from screenshots. We compared two design directions, "Atelier" and "Cut paper", in a single Figma variable collection with two modes. Every variable carries its Swift name, so one mode switch in Figma matches one launch flag in the app. Matus picked Atelier by flipping the same frames between modes, and it's the look that ships. The art session built two clickable prototype flows through the MCP, bound to the same tokens: [first open to practice](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102), and [a full battle from join to champion](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364). Design file: https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv · Full stage log: [Figma Slides].
- **Original score by [composer's name].**
- Built by [team] and a team of Claude Code sessions (leader, product, art, multiplayer, iOS, agent service and go-to-market), working from one spec with one folder each.

### Judge axes (poetry battle)

| Axis | What it measures | Scored by |
| --- | --- | --- |
| Beat | Did your stresses land | Stress scanner (deterministic) |
| Craft | Used formulas, varied them, coined new ones | Claude |
| Image | Strength of the imagery | Claude |
| Answer | Responded to the last verse | Claude |
| Range | How much emotional ground you covered | Emotion engine |

## Challenges we ran into

- **One room, many mics.** The drum and Homer's voice bleed into every phone's mic. We put the beat in your palm through haptics and duck the arena drum while you speak.
- **Hearing "rose-fingered Dawn" through a drum.** Recognizers mangle exactly the rare phrases the game runs on. We feed your hand to the recognizer as keyterms, and with the drum at full volume in our tests the word error rate fell from 20% to 3%.
- **A verdict that lands in three seconds.** Our first judge was a slow, multi-step tool loop. We cut it to one streamed Claude call with the scanner's count already in the prompt, low effort and a fixed JSON schema. Verdict text now arrives in p50 1.0 s and p95 1.5 s, and Homer's voice starts about 100 ms later.
- **Every phone was syncing every room.** The community Swift SDK subscribes to whole tables, so with a 20 Hz voice stream each phone would have received every room's traffic. We patched it to subscribe per room.
- **We switched from web to iOS mid-build.** On Friday night the scene was already written for the web in React, Three.js and GLSL. The palette and motion lived in plain math tables, so they carried over to Metal almost line for line. The React code didn't survive. [If the website ships:] On Saturday we brought the arena back to the browser, so anyone can open it at a public URL.
- **Six AI sessions on one 24 GB laptop.** The whole team of Claude Code sessions, plus Xcode and the simulators, shared one MacBook Air. We set a memory budget (keep 25% free, one simulator at a time, shut everything down after each screenshot) so the machine never ran out mid-build.
- **An agent the Agentverse button couldn't reach.** Our Fetch.ai agent runs inside Docker on the server, where the Inspector's Connect button can't reach it, so we register its mailbox with an API key from inside the container instead.
- **Meaning-based dealing can skew.** With Moss, "A city that never sleeps" kept dealing Troy epithets, the Iliad's city, so that theme came off the judging cards while we retag the bank and add modern city formulas. The first list our Apify Actor mined was full of "dear son" and "great wealth" before we restricted it to Homer's fixed epithets.

## Accomplishments that we're proud of

- [N] people who'd never freestyled took lesson one at Cal Hacks. Their Beat score went from **[first] to [last]** out of 10, in about [time] minutes. *(Beat only, first try vs last. If fewer than three landed, drop the time.)*
- A live battle on iPhones, with Homer's spoken verdict [turn-to-voice p50] s after the last word.
- 3% word error rate with the drum at full volume in our tests, down from 20%, by feeding each poet's hand to the recognizer.
- The stitched song: the room leaves with one poem it made together.
- [If debate or discus passed: three events on one engine.]

## What we learned

*(Draft. Each line is true now; reread them Sunday morning.)*
- A recognizer does far better when you tell it what to expect. Five phrases in the hand took word errors from 20% to 3% under the drum in our tests.
- Keep the model away from anything you can count. The beat is arithmetic, so a scanner scores it, and Claude judges what only taste can.
- With six-plus agent sessions building at once, one spec and one folder per session mattered more than any single prompt.

## What's next

- Public TestFlight now, then the App Store
- More events on the same engine: the locked tiles
- Open-mic nights: a host runs the arena, the audience battles from their iPhones
- Hard mode: Homer's own dactylic hexameter
- Ranks with Homeric titles: Suitor, Herald, Bard, Rhapsode, Homer

## Built for the real world

*(For Microsoft's track. Each line answers one of their five capabilities.)*
- **Customer understanding:** we started from one community, spoken-word and slam poets in [the poet's scene], and tested on people who'd never freestyled.
- **Measurable usefulness:** the stress scanner's Beat score is an objective measure. [N] first-timers went from [first] to [last] out of 10 in one lesson.
- **A path from prototype to production:** TestFlight now, then the App Store. The website is live at [URL], served from the same DigitalOcean droplet as the agent service (Docker), and SpacetimeDB runs on Maincloud.
- **Responsible design:** captions, push-to-talk, no audio through our server, gentle roasts, and the content and name filters (below).
- **End-to-end functionality:** the live battle runs on real services, with nothing mocked.

## Where it can go wrong (and what we do about it)

- **Speech recognition misses in noisy rooms.** Keyterms from your hand cut word errors from 20% to 3% with the drum at full volume in our tests, but those were recorded test mixes, and a loud hall with a real phone mic is harder. The live transcript is always on screen, so you see what Homer heard, and push-to-talk keeps the mic closed until you choose.
- **Taste is contestable.** Every verdict shows five scores and the quoted line, so you can see why you lost.
- **Emotion reading is approximate.** The scene is art, not a diagnosis, and Homer never names your emotion.
- **English stress has edge cases** with names, slang and loanwords. The scanner flags uncertain syllables instead of marking them wrong.
- **A roast can sting a beginner.** Roasts stay gentle and only in Battle; in lessons Homer is a calm coach.
- **Bad content.** A verse that isn't fit for the hall scores nothing, and Homer won't quote it. Names are filtered before Homer says them.
- **Privacy:** no audio passes through our server. Your phone streams the mic straight to Cartesia for transcription. Transcripts, scores and lines live in the room's tables on SpacetimeDB, and Rematch clears them. Finished rooms aren't deleted yet; an automatic cleanup is on our list. On our current plan Cartesia's standard data terms apply. For launch we'd turn on Cartesia's zero-data-retention option, which covers STT audio and transcripts and is available on their enterprise plan.
- **Accessibility:** captions on everything Homer says. The beat is in your palm as haptics, so you can feel it without hearing it.

## Built with

swift · swiftui · metal · avfoundation · core-haptics · core-motion · spacetimedb · typescript · python · fastapi · anthropic · claude · claude-code · cartesia · cmu-pronouncing-dictionary · figma · xcodegen · docker · caddy · digitalocean · apify · crawlee · moss · fetch-ai · agentverse · uagents

---

## Sponsor-track blurbs (paste only for tracks that really shipped)

Every integration below runs behind a switch, off the demo path (SPEC `5a6a8fe`). Fill each bracket with what's true, or delete the blurb.

**Apify: Epithet Miner.** **Epithet Miner is an Apify Actor, built with AI chat:** Claude Opus 5.5 in Claude Code wrote it from our prompts, on the Apify SDK and Crawlee. Homer improvised with stock phrases, and so do you: every turn deals you five. The Actor mined part of that bank:
- **Sources:** four public-domain Homer translations on Project Gutenberg, 3.2 million characters in all: Lang, Leaf and Myers's Iliad, Butcher and Lang's Odyssey, and Samuel Butler's Iliad and Odyssey.
- **How it works:** it finds noun-epithet formulas with readable rules and no language model. It folds Roman names to Greek (Jove becomes Zeus) and merges synonyms. It counts each phrase's beats with the same CMU-dictionary rule as our stress scanner, and ranks phrases by how often and how widely they recur ("aegis-bearing Zeus" appears 60 times across two translations).
- **What it produced:** 150 candidates. A person reviewed them and kept 55, so the bank grew from 158 to 213 formulas: about a quarter of what Homer can deal you now came from the Actor.

It's published on the Apify Store: https://apify.com/matusnator/epithet-miner It runs at build time; the game never calls Apify live. The full, honest build log is in `apify/BUILD_LOG.md`, including what went wrong: the first list was full of "dear son" and "great wealth".

**Fetch.ai: Homer on Agentverse.** The whole battle turn works inside an ASI:One conversation. Ask Homer for a theme, and he deals you five stock phrases that fit it. Write your verse with them, and he judges it with the same scanner and Claude judge that run our live battles: five scores, your best line quoted and a one-line verdict.  It's an agent registered on Agentverse that speaks the Agent Chat Protocol, running inside our agent service behind a switch, so the battle never depends on it. Agentverse's Inspector button can't reach an agent inside Docker, so we register its mailbox with an Agentverse API key from inside the container (`homer/scripts/agentverse_connect.py`). Agent: `homer-bard` (`agent1qf8cydj43pd7tue06mk9avnp45avcc4ss9gjm98r4lkjczsw0gskzw97edc`). Try it: [ASI:One link].

**Moss: dealing that fits the theme, in milliseconds.** When Homer announces a theme, every poet gets five stock phrases that fit it. Moss ranks our whole bank of 213 formulas by meaning against the theme, including the 55 our Apify Actor mined, and the dealer draws your hand from the closest matches. Before Moss, the dealer matched tags.
- **Before and after:** "The war between two brothers" used to deal "breaker of horses". Now it deals "the battle-light" and "the battle-sweat". "My grandmother's kitchen" finds "in my mother's kitchen" and "the high-roofed hall", which shares no word with the theme.
- **Measured on our production server** (a 2 GB DigitalOcean droplet, CPU only), over 60 queries across 20 themes: Moss retrieval p50 **13.7 ms**, p95 32.2 ms (1.4 ms p50 on a MacBook). The whole deal request takes p50 43 ms.

Voice games have to answer while the room is still listening, and Moss keeps the deal instant. It runs behind a switch: if Moss is ever slower than 500 ms or errors, our old tag dealer deals instead, silently. We tested both failures live.

## Tracks to tag on Devpost

**As of Sat 12:20 PM, Devpost lists "[Spacetime] Best Use of Spacetime" and "[Anthropic] Claude for Public Benefit". Tag both** (leader). It still has no MLH Gen AI, .Tech or DigitalOcean (Hive has all three; Devpost lists Vultr instead), and it still shows Figma's old five prizes. MLH: "you can opt in to multiple prize categories at time of submission!" An organizer: "Devpost will also be updated soon!" (#0-ask-directors, Sat 10:40–10:50 AM). Tag every track below that Devpost offers on Sunday morning.

- [ ] **Spacetime: Best Use of Spacetime** (on Devpost since Sat ~12 PM)
- [ ] Meta: Bringing People Closer Together with AI
- [ ] Cartesia: Best Use of Cartesia
- [ ] **Anthropic: Claude for Public Benefit** (on Devpost since Sat ~12 PM)
- [ ] Figma (add the Figma Slides link and the stage log)
- [ ] MLH: Best Use of Gen AI
- [ ] MLH: Best .Tech Domain Name (if registered)
- [ ] MLH: Commit Fellowship (if we want it)
- [ ] **Microsoft: Built for the Real World** and the Customer Impact Award ([opportunities.md](opportunities.md) #3)
- [ ] MLH: Best Domain Name from GoDaddy Registry (only if we register one)
- [ ] **Fetch.ai: Best Use of Fetch.ai** (only if Homer's judge is live on Agentverse and usable from ASI:One)
- [ ] **Moss: Best Use of Moss.** Shipped: `HOMER_DEALER=moss` is live on the droplet, p50 13.7 ms, with a tested fallback. Tag it.
- [ ] MLH: Best Use of DigitalOcean (the agent service runs there)
- [ ] **Apify: "[Apify] Best Use of Apify".** Devpost now has one Apify entry with 6 winners, covering Best Use and "Best Actor Built with AI Chat (make sure to tag in your submission that is an actor)". So tag it, and the Apify blurb says outright that **Epithet Miner is an Apify Actor, built with AI chat** (leader, Sat 12:30 PM). Ready: 55 of the bank's 213 formulas came from it, and it's live on the Store (https://apify.com/matusnator/epithet-miner).

Main prizes are automatic.

## Submission checklist

- [ ] Every teammate added on Devpost
- [ ] **Team name, a 2–3 sentence elevator pitch and our table number.** The Hive FAQ: "All submissions must include a 2-3 sentence elevator pitch / summary, team location (your table number), and the team name." Tables are assigned "shortly after the 9:00 AM submission deadline" (Hacker Guide), so add the table number then if Devpost has a field for it.
- [ ] No keys in the repo: `.env` gitignored, `.env.example` committed, and the leader's full-history secret scan rerun after the Sat ~11 PM freeze
- [ ] **Repo public by 8:00 AM Sunday:** Sunya (the owner) flips it in Settings → General → Danger Zone. It stays private until then (Matus's call). Matus pings Sunya Saturday night.
- [ ] The GitHub link opens in a logged-out browser (a private window) before the 8:45 submit
- [ ] README has a **Cartesia section**: setup (XcodeGen, signing, `.env`), the Cartesia features used, known limitations
- [ ] README explains where SpacetimeDB is used (tables, reducers, the 20 Hz stream, the private hand, the SDK patches)
- [ ] Video, 2:00, opening with the moment ([video.md](video.md))
- [ ] Figma Slides link, files shared with "Anyone", whole team Edu verified
- [ ] **Matus submits build 4 (0.1.0, `202610240956`) for external review (Beta App Review) as soon as it finishes processing.** Not build 2 or 3: build 4 has lesson 1, debate, discus and the force-quit rejoin, and its stricter Beat matches our study numbers.
- [ ] TestFlight public link installs on an iPhone that isn't on our internal tester list
- [ ] **The website opens at [URL]** in a private window on a laptop, and on a phone on cellular with Wi-Fi off, so we know it works off our network. Then an iPhone joins its room
- [ ] Cover image: an arena frame with the carved gold line, matte, no neon
- [ ] Every `[bracket]` filled or deleted. Search the page for `[` before submitting.
- [ ] Submitted by **8:45 AM Sunday** (hard deadline 9:00)
