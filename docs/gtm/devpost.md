# Devpost draft

Paste this into Devpost. **Never submit a claim that isn't true on Sunday morning.** The guide recommends submitting a draft Saturday night and editing it until 9:00 AM.

**State: Sat Oct 24, 4:15 PM (SPEC through b37e419: fresh Homeric themes and epithets, Homer's three phrases, free verse, content-only scoring, the website as the only arena).** Everything outside `[brackets]` is true now. What's left:

| Placeholder | Kind | Comes from | When |
| --- | --- | --- | --- |
| `[N]`, `[first]`, `[last]`, `[time]` (**only in the [A] lines; if the study doesn't run, use the [B] lines**: Matus hasn't confirmed it) | **Number** | The first-timer study on the build named in `docs/study.md` (build 18, 0.1.0 (202610241606); if it's missing, the newest of builds 14, 11 and 4), using one of pm's line options. It's a lesson, so it's the strict "Beat" score, not the battle's Flow. | Sat 8 PM |
| `[real-mic WER]` | **Number** | swift's rerun of the keyterm test on a real iPhone mic. If it differs from 3%/20%, it replaces those numbers everywhere. | When swift runs it |
| `[turn-to-voice p50]` | **Number** | The measured time from a turn's end to Homer's first word, on the evening shoot's build (its latency HUD), or multiplayer's check-run tally if it has the number | Sat ~9 PM |
| `[poet's name]`, `[the poet's scene]`, `[poet quote]`, `[composer's name]`, `[how the score was made]`, `[team]` | **A fact only Matus has** | Matus (the list went to leader) | Today |
| `[If debate passed]` | Checkpoint | The Sat 8 PM check: 5 runs in a row without a failure. Delete the section if it failed. **`[If discus passes on 31]`** works the same way: discus needs 5 clean real-phone runs on build 31 (leader and pm, Sat ~8:25 PM: the build-18 pass came before discus v2 shipped in build 21). Its earlier 5 of 5 on build 18 no longer counts. | Sat 8 PM, and the 31 runs |
| ~~`[URL]`~~ | Link | **Filled: https://play.206.189.237.157.sslip.io** (`homer/DEPLOY.md`; it answered HTTP 200 at Sat 5:50 PM). Still open it on a phone on cellular before submitting. | Done |
| `[TestFlight public link]`, `[Video]`, `[ASI:One link]` (the Figma Slides link is filled: https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm) | Link | Apple's Beta App Review; [video.md](video.md); the Slides deck; builder | As each lands |

---

**Project name / title:** MeNIN: Ancient Greek Party Games, Hosted by Homer *(fallback: "MeNIN: Party Games of Ancient Greece")*

**Tagline** (200 chars; 180 used): A live voice poetry battle: speak a verse into your iPhone, Homer judges it out loud within seconds, and the sea on the big screen moves with your voice. Ancient Greek party games.

*Lead (leader, Sat ~8:45 PM): organizers shortlist each project "for the track we best believe your project fits" (#0-ask-directors, Sat 7:51 PM), so the tagline and the first paragraph lead with the live voice battle, name Cartesia, SpacetimeDB and Claude, and aim the main prizes at Most Creative. Camera archery gets one line, never the lead.*

*Trademarks: no "Wii", "Wii Sports", "Guitar Hero" or "Olympic" anywhere in this page.*

**Try it:** **https://play.206.189.237.157.sslip.io**: open it on a laptop and it becomes the arena, then join from your iPhone · iPhone app: [TestFlight public link] · [playmenin.tech, if registered] · Video: [Video] · Figma Slides (the stage log): https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm · Clickable prototypes: [first open → practice](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102) · [a full battle](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364)

---

**MeNIN is a live voice poetry battle.** Poets battle on their iPhones in front of one big screen. You speak a verse into your phone. **Cartesia** hears it, with Homer's phrases as hints. **Claude**, as Homer, judges it out loud within seconds, on Image, Answer and Craft, out of 100 (his verdict is written in under a second: p50 0.9 s, measured from a laptop). [Once `[turn-to-voice p50]` is read off the shoot's latency HUD, tighten "within seconds" to "[turn-to-voice p50] seconds after your last word", here and in the tagline.] The sea on the arena moves with your voice. **SpacetimeDB** runs the battle itself: the turns, the timer, your private phrase cards and the scores, so every phone and the arena agree. At the end, the best lines from the room are stitched into one song. [If archery passes on 31: Tonight we added camera-tracked archery: the laptop's webcam follows your bow arm and your draw, and your own phone looses the arrow.]

## Inspiration

The first word of Western literature is μῆνιν (*mēnin*, pronounced "MAY-nin"): **rage**. Homer opened the Iliad with a fight, and so do we.

**AI can write anything now. What it can't do is stand up in a room and move people for you.** That's becoming the skill that matters most, and the Greeks treated it as one you train in public, by contest: rhapsodes competing at the Panathenaic Games, citizens arguing in the Assembly, Socrates questioning strangers in the agora. Most AI talks for you. We wanted AI that makes you talk.

MeNIN is for spoken-word and slam poets in [the poet's scene]. [poet's name] is one of them. Open mics are once a week, and between them you practice alone in your room, with no one to tell you whether your beat landed. [poet quote: one line from a poet texted Saturday, with permission] Improvising out loud is a learnable skill: Homer did it with stock phrases built to fit the beat, and freestyle rappers do it every night. Almost nobody gets to practice it with friends.

So we built ancient Greek party games for your voice, with AI as the coach and the judge, never the speaker, and made the poetry battle the main event.

## What it does

The first time you open MeNIN, Homer speaks before any menu: "The first word of Western literature is *mēnin*. Rage. Give me one line." You say anything, the scene answers your voice, and Homer says, "Good. Now let me show you how I did it."

Homer is a live agent doing real work: he writes each round's theme, deals, listens, judges, coaches, hosts and writes the song from the room.

One screen is the arena: our website at https://play.206.189.237.157.sslip.io, open in any laptop browser. Every player's iPhone is their controller. Scan the QR code or type the room code to join. No account needed.

| Event | Host | You |
| --- | --- | --- |
| **Poetry battle** (main event) | Homer | Improvise free verse, answering the poet before you |
| [If debate passed] **Socratic debate** | Socrates | Argue a question in timed spoken turns |
| **[If discus passes on 31]** **Discus** | Homer announces | Swing your phone; its motion sensors measure the throw |
| **Talk to Homer** | Homer | Speak a verse; Homer answers out loud in two sentences, quoting your words, with one fix. A conversation with no scorecard. |
| [If it passed] **Stadion** | Homer announces | Pump your arms with the phone in your hand like a sprinter; everyone races at once, live on the screen |

Other events show as locked tiles, because we only unlock what's solid: an event goes live only after 5 clean runs on real phones.

**The poetry battle.** Two to five poets in one room, three rounds. Each poet's iPhone is their mic and their private cards.
- Homer announces each poet with a fresh epithet he coins for this battle: "Enter Matus, Breaker of Horses!"
- Homer writes a fresh theme every round, six words or fewer and always from Homer's world, like "The ship that left without you". Nothing in a theme or an epithet was invented after the Bronze Age; the feeling can be modern, the objects can't.
- Your phone shows three of **Homer's phrases**, stock phrases that fit the theme and the beat ("the whale-road", "grey-eyed Athena"), under one line: "Stuck? Use one of Homer's phrases. It scores Craft." They're optional help, not homework.
- **No metronome. The beat is how Homer trains you; in battle you spit free.** It lives in the Bard lessons and comes back under Homer's stitched song.
- A 3, 2, 1 with a haptic tick, then SPEAK fills your phone and the arena in your color, once, for the whole verse. The mic is hands-free: you get one window with a countdown ring (10 s a line, 20 s in demo mode), and "I'm done" ends it early. A line is whatever you say between breaths. Use one of Homer's phrases and it pops "+Craft" and flips onto the arena.
- Freeze for a second and Homer's phrases come forward, the one that fits raised, while Homer whispers it to you.
- About three seconds after your last word, Homer delivers the verdict like a title-fight MC: three scores, Image, Answer and Craft, adding up to a total out of 100, and your best line, quoted. The scale is honest: a typical first verse lands at 4 to 6 out of 10, and a 9 or 10 is a line you'd quote tomorrow.
- The best line of each round is carved in gold across the arena.
- At the end, Homer becomes a rhapsode, a song-stitcher. He stitches every poet's lines into one song and performs it over the beat while the arena replays the battle's colors. Then he crowns the champion.

**The scene.** Behind everything, a full-screen procedural scene paints the speaker's voice: matte layers of painted color. Loudness and pitch move it at 60 fps, and every ~1.5 s an emotion read of your words and voice shifts its colors across eight palettes. Homer never names your emotion; the scene shows it.

**The score.** MeNIN has an original soundtrack composed by [composer's name], on our team: a hall and menu theme, an intro for each event, the discus fanfare, a champion sting, and ambience for training. Music never plays while a mic in the room is open. During a turn, only the procedural beat plays, and the music ducks under Homer's and Socrates' voices. There are no sound effects beyond the beat and a soft strike on a hit. [How the score was made: instruments, DAW, and whether any AI tools were used. Write it honestly.]

**Bard mode.** Short voiced lessons from Homer, one move each: the beat, the formula, the epithet. Homer shows the move, names it in a sentence, and gives you one note per try until you land it. The epithet you coin joins your hoard; in battle, Homer coins you a fresh one every time.

**Practice mode.** Spar with Homer, best of three.

**[If debate passed] Socratic debate.** It's the same engine as the battle: timed spoken turns, the scene and a spoken verdict, with no beat. Socrates hosts in his own voice, and sides are dealt by turn order. Our demo question: "Is it cheating to let an AI write your love letter?" Your hand holds rhetorical moves ("define your terms", "counterexample", "analogy"). Tap a move as you make it, and the judge checks that you really made it. Freeze, and Socrates whispers you a question to ask. It has its own five axes: Claim, Reason, Answer, Craft and Poise.

**[If discus passes on 31]** **Discus.** Hold a button with your thumb, swing your iPhone, and lift your thumb to release. You never let go of the phone. Core Motion measures the swing and the release, the arena flies the throw in silence, the distance lands with a fanfare, and Homer calls the throw ("Strong arm."). No voice, no AI: just physics and bragging rights.

## How we built it

- **One engine, many events.** Each event is a config: host, cards, rubric, turn length, beat on or off. [If debate passed: the debate took (hours) on top of the poetry engine.]
- **The website (https://play.206.189.237.157.sslip.io) is the arena,** and the only one people see. It's static files served from our droplet over HTTPS, on SpacetimeDB's TypeScript SDK and the same agent service as the app. Open it on a laptop and it hosts the room, drives the battle and speaks as Homer. Phones join its room with the app.
- **iOS app (SwiftUI, iOS 18+).** On your iPhone, the app is the controller (join by code or QR) plus training (Bard and Practice). Its own arena mode stays in the code, behind the Dev screen, as an emergency fallback.
  - AVAudioEngine captures the mic with voice processing.
  - Core Haptics plays the turn's thump and the 3-2-1 ticks, and the beat in your hand during lessons.
  - Metal shaders render the scene.
  - In lessons, syllable onsets detected on the phone itself drive the beat lane, so a hit never waits for the transcript.
  - Views take plain value models and never touch state, so the design could change twice without rewriting the logic.
- **SpacetimeDB** is the hall: rooms, players, rounds, turns, scores, the carved lines, the stitched song and the discus throws.
  - The whole battle is a phase machine in **reducers**, server-side, from lobby to theme, dealing, speaking, judging, round end, finale and champion. A scheduled reducer closes each turn on time.
  - The phrases Homer deals you are guarded by **row-level security** (a client visibility filter in the module), so only your phone can read your cards.
  - The speaking phone streams its loudness and pitch about 20 times a second into the room's live row, which the arena subscribes to, so the scene moves with whoever is speaking.
  - The iPhone client is the community Swift SDK (avias8/spacetimedb-swift 0.23.0), vendored with two patches. Upstream subscribes every client to whole tables, which would send every phone every room's 20 Hz voice stream, so each phone now subscribes only to its own room. The second patch lists each row once when subscriptions overlap.
- **Cartesia** is the ears and the voice.
  - Streaming speech-to-text (**ink-2**, over WebSocket) writes the live transcript. We send every phrase Homer dealt the poet, plus the theme, as **keyterms**, so it catches "the wine-dark sea" through the noise. **Measured** (receipt: [`docs/voice-wer/`](docs/voice-wer/): the scripts, the raw output and the method): with a drum at full volume (0 dB) as the test noise, the word error rate is **3% with keyterms and 20% without**; clean, it's 3% vs 9%. The final transcript arrives **62–81 ms** after the phone signals the end of speech. These are synthetic test clips (a TTS voice and our drum, mixed digitally), not a real room or phone mic, so treat them as a best case. [real-mic WER] Battles no longer play a drum, so at the table the enemy is the hall; lessons still play it, on the same phone.
  - The phone streams straight to Cartesia with a short-lived token from our server, so no audio passes through us.
  - Cartesia TTS is Homer (**sonic-3.6**, the voice Carl, "Steady Storyteller"), with first audio in under 0.1 s (78–90 ms, measured from the arena laptop on Wi-Fi; receipt `docs/voice-wer/`): lessons, entrances, verdicts, the freeze whisper and the stitched song.
- **Claude (Anthropic)** is the judge, the coach and the MC.
  - The judge reads content, not rhythm. It gets the phrases Homer dealt you, the verse you're answering and the scanner's output, and returns Image, Answer and Craft (1 to 10 each, anchored so a typical first-timer verse lands at 4 to 6), the best line and a one-line verdict. The total is out of 100: Image ×4, Answer ×4, Craft ×2.
  - Each judgment is one streamed request to **Claude Opus 5.5**: fast mode, low effort, a cached system prompt and a JSON schema, so the output is always valid. Verdict text, the line Homer speaks, lands in **p50 0.9 s, p95 1.9 s**, and the whole judgment (scores and JSON) in p50 1.0 s, p95 2.0 s: 10 of 10 live calls answered, all reading the cached prompt (current judge, Sat Oct 24, measured from a laptop calling the API; receipt `homer/bench/latency-2026-10-24.txt`, from `homer/scripts/latency.py`).
  - Claude also writes each round's fresh theme and Homer's call to the first poet, coins a fresh epithet for every poet each battle, writes Homer's lesson feedback, his sparring verses and the round verdicts, and writes the stitched song. The freeze whisper makes no model call: it picks the dealt phrase that fits the line, so it's instant.
- **The stress scanner** (Python, CMU Pronouncing Dictionary) counts the beat deterministically. It scores **Beat** in the lessons, where Homer teaches it, and it never comes from the model's opinion. Battles aren't scored on rhythm at all.
- **Python + FastAPI** service for the Claude calls, the scanner and the formula bank, in Docker behind Caddy on **DigitalOcean**.
- **Figma.** Matus drew the first concept in Figma Design. The art session reads frames, exact values and assets straight from the file through the Figma MCP server, so it builds from the design rather than from screenshots. We compared two design directions, "Atelier" and "Cut paper", in a single Figma variable collection with two modes. Every variable carries its Swift name, so one mode switch in Figma matches one launch flag in the app. Matus picked Atelier by flipping the same frames between modes, and it's the look that ships. The art session built two clickable prototype flows through the MCP, bound to the same tokens: [first open to practice](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102), and [a full battle from join to champion](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364). **Saturday night, one hall:** the website began as a Figma Make app with its own palette, so the app and the big screen looked like two products. We added a third mode, **Hall**, to the same variable collection, built from the website's real tokens (its CSS had 128 hard-coded colors and no variables; they became 37 named tokens), and laid out the changed frames in Figma first: flipping a frame to Hall turned 72 of its 73 fills in one step. The app then took it as one new case in its `Direction` switch (build 32). The whole-app reskin was +69/−36 lines of tokens plus 5 small view edits. 119 views took the new look untouched, in 22 minutes from the token table to the build, with 3 rework rounds. The friction is in the log: the sync is by convention, not live (the values went into Swift by hand, not read back from Figma), and 13 colors are still hard-coded. **The designer stayed in the loop through Figma:** every scene render in the file came from the website's real scene code, run with a scripted voice, so Matus judged what the phone would actually do. He took it through four rounds in 17 minutes, from "keep the cool wavy white" to **"blue at rest, colours on voice"**. Then he called the buttons "generic and boring", and they became one component set of 12 variants on 16 variables. Build 33 shipped round 3, and round 4 and the buttons followed in build 34. Figma files: [the flip, Atelier → Hall](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=36-128) · [Turn, mid-shoot](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=34-179) · [Join, at rest](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=31-179) · [the button system](https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv/?node-id=48-216). 14 PNG copies (the 12 Hall frames, the flip and the button sheet) are in the repo under `docs/figma/`, so they survive any change to the files. Design file: https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv · Full stage log: https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm.
- **Original score by [composer's name].**
- Built by [team] and a team of Claude Code sessions (leader, product, art, multiplayer, iOS, agent service and go-to-market), working from one spec with one folder each.

### Judge axes (poetry battle)

| Axis | What it measures | Scored by |
| --- | --- | --- |
| Image (×4) | Strength of the imagery | Claude |
| Answer (×4) | Responded to the last verse (or the theme, if first) | Claude |
| Craft (×2) | Used Homer's phrases, varied them, coined new ones | Claude, with the scanner's output |
| Range (not scored) | How much emotional ground you covered. It paints the scene. | Emotion engine |

The total is out of 100. Clichés and dodging the theme cost. In the lessons, **Beat** (did your stresses land on the drum) is scored by the stress scanner, deterministically.

## Challenges we ran into

- **One room, many mics.** The drum and Homer's voice bled into every phone's mic. First we moved the beat into your palm as haptics and ducked the arena drum while you spoke. Then Matus playtested it and said, "I just want to spit poetry without the metronome." So battles went free verse: nothing plays under a speaking poet, and the beat stays in the lessons, where it teaches.
- **Hearing "rose-fingered Dawn" through noise.** Recognizers mangle exactly the rare phrases the game runs on. We feed the phrases Homer dealt you to the recognizer as keyterms, and in our tests, with a drum at full volume as test noise, the word error rate fell from 20% to 3%.
- **A verdict that lands in three seconds.** Our first judge was a slow, multi-step tool loop. We cut it to one streamed Claude call with the scanner's count already in the prompt, low effort and a fixed JSON schema. On the current judge, the verdict line arrives in p50 0.9 s (p95 1.9 s) over 10 live calls from a laptop (`homer/bench/latency-2026-10-24.txt`), and Homer's first audio comes under 0.1 s after the request (measured from a laptop on Wi-Fi, `docs/voice-wer/`).
- **Every phone was syncing every room.** The community Swift SDK subscribes to whole tables, so with a 20 Hz voice stream each phone would have received every room's traffic. We patched it to subscribe per room.
- **We switched from web to iOS mid-build.** On Friday night the scene was already written for the web in React, Three.js and GLSL. The palette and motion lived in plain math tables, so they carried over to Metal almost line for line. The React code didn't survive. On Saturday we brought the arena back to the browser: the website is now the only arena, so anyone can open it at a public URL.
- **Six AI sessions on one 24 GB laptop.** The whole team of Claude Code sessions, plus Xcode and the simulators, shared one MacBook Air. We set a memory budget (keep 25% free, one simulator at a time, shut everything down after each screenshot) so the machine never ran out mid-build.
- **An agent the Agentverse button couldn't reach.** Our Fetch.ai agent runs inside Docker on the server, where the Inspector's Connect button can't reach it, so we register its mailbox with an API key from inside the container instead.
- **Meaning-based dealing can skew.** With Moss, any theme about a city kept dealing Troy epithets, the Iliad's city. We retagged the Troy cards and added three modern city epithets, and Troy cards in city hands dropped to 0%. Then we cut those three again, with 33 other modern phrases, when Homer's world became the rule: nothing in a theme or a phrase invented after the Bronze Age. The first list our Apify Actor mined was full of "dear son" and "great wealth" before we restricted it to Homer's fixed epithets.

## Accomplishments that we're proud of

- **[A: the study ran]** [N] people who'd never freestyled took lesson one at Cal Hacks. Their Beat score went from **[first] to [last]** out of 10, in about [time] minutes. *(Beat only, first try vs last. If fewer than three landed, drop the time.)* **[B: no study]** *(Delete this bullet.)*
- A live battle on iPhones, with Homer's spoken verdict [turn-to-voice p50] s after the last word.
- 3% word error rate in our tests, with a drum at full volume as test noise, down from 20%, by feeding the phrases Homer dealt each poet to the recognizer.
- The stitched song: the room leaves with one poem it made together.
- [If discus passes on 31: The discus: 5 of 5 clean runs on real phones on build 31, with throws from [min] to [max] m.] [If debate passed: three events in one hall.]

## What we learned

*(Draft. Each line is true now; reread them Sunday morning.)*
- A recognizer does far better when you tell it what to expect. Feeding it the verse's formulas as keyterms took word errors from 20% to 3% in our tests, with a drum at full volume as test noise.
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
- **Measurable usefulness:** the stress scanner's Beat score is an objective measure, and every lesson try gets one, so a poet sees their first try against their last. **[A: the study ran]** [N] first-timers went from [first] to [last] out of 10 in one lesson. **[B: no study]** *(End the bullet after "their last".)*
- **A path from prototype to production:** TestFlight now, then the App Store. The website is live at https://play.206.189.237.157.sslip.io, served from the same DigitalOcean droplet as the agent service (Docker), and SpacetimeDB runs on Maincloud.
- **Responsible design:** captions, a hands-free mic that opens only on your turn, no audio through our server, gentle roasts, and the content and name filters (below).
- **End-to-end functionality:** the live battle runs on real services, with nothing mocked.

## Where it can go wrong (and what we do about it)

- **Speech recognition misses in noisy rooms.** Keyterms from Homer's phrases cut word errors from 20% to 3% in our tests, with a drum at full volume as test noise, but those were recorded test mixes, and a loud hall with a real phone mic is harder. The live transcript is always on screen, so you see what Homer heard, and the hands-free mic opens only on your turn.
- **Taste is contestable.** Every verdict shows all three scores and the quoted line, so you can see why you lost, and the scale is anchored, so a 5 means the same thing every time.
- **Emotion reading is approximate.** The scene is art, not a diagnosis, and Homer never names your emotion.
- **English stress has edge cases** with names, slang and loanwords. The scanner flags uncertain syllables instead of marking them wrong.
- **A roast can sting a beginner.** Roasts stay gentle and only in Battle; in lessons Homer is a calm coach.
- **Bad content.** A verse that isn't fit for the hall scores nothing, and Homer won't quote it. Names are filtered before Homer says them.
- **Privacy:** no audio passes through our server. Your phone streams the mic straight to Cartesia for transcription. Transcripts, scores and lines live in the room's tables on SpacetimeDB, and Rematch clears them. Finished rooms aren't deleted yet; an automatic cleanup is on our list. On our current plan Cartesia's standard data terms apply. For launch we'd turn on Cartesia's zero-data-retention option, which covers STT audio and transcripts and is available on their enterprise plan.
- **Accessibility:** captions on everything Homer says. In battles, a haptic thump and the 3-2-1 ticks tell you your turn has started; in lessons, the beat is in your palm as haptics, so you can feel it without hearing it.

## Built with

swift · swiftui · metal · avfoundation · core-haptics · core-motion · spacetimedb · typescript · python · fastapi · anthropic · claude · claude-code · cartesia · cmu-pronouncing-dictionary · figma · xcodegen · docker · caddy · digitalocean · apify · crawlee · moss · fetch-ai · agentverse · uagents

---

## Sponsor-track blurbs (paste only for tracks that really shipped)

*(gtm note, don't paste: each blurb opens with the job that sponsor's tech does in MeNIN and what breaks without it, never "we also used". Fill each bracket with what's true, or delete the blurb.)*

Each of these does a job MeNIN needs, and each one has a fallback, so a battle never stalls on a third-party call.

**Apify: the phrases you play with.** MeNIN runs on Homer's stock phrases: they're the cards on your phone, the Craft points you score, and the line Homer whispers when you freeze. **Nearly a third of that bank (55 of 180) was mined by our Apify Actor**, Epithet Miner, from four public-domain translations of Homer. In play, **about one in five cards Homer deals (22%) is a mined phrase, and 74% of the five-phrase hands the dealer builds carry at least one** (400 deals over all 16 written themes, Moss on the live bank; receipt `homer/bench/mined-share-2026-10-24.txt`). **Epithet Miner is an Apify Actor, built with AI chat:** Claude Opus 5.5 in Claude Code wrote it from our prompts, on the Apify SDK and Crawlee.
- **Sources:** four public-domain Homer translations on Project Gutenberg, 3.2 million characters in all: Lang, Leaf and Myers's Iliad, Butcher and Lang's Odyssey, and Samuel Butler's Iliad and Odyssey.
- **How it works:** it finds noun-epithet formulas with readable rules and no language model. It folds Roman names to Greek (Jove becomes Zeus) and merges synonyms. It counts each phrase's beats with the same CMU-dictionary rule as our stress scanner, and ranks phrases by how often and how widely they recur ("aegis-bearing Zeus" appears 60 times across two translations).
- **What it produced:** 150 candidates. Our product session (a Claude Code agent) reviewed all 150 and kept 55 [Matus: add "and Matus checked them" only if true], so the bank grew from 158 to 213 formulas. It's 180 now, after modern phrases were cut for Homer's world, so nearly a third of what Homer can deal you (55 of 180) came from the Actor.

It's published on the Apify Store: https://apify.com/matusnator/epithet-miner (Actor ID `v4i7ItNXjHMmnKzfo`). It's how the bank grows: point it at another translation, review the list, and the dealer has new cards. It runs at build time by design, so a battle never waits on a crawl. The full, honest build log is in `apify/BUILD_LOG.md`, including what went wrong: the first list was full of "dear son" and "great wealth".

**Fetch.ai: Homer outside the hall.** Homer is an agent, and on Agentverse he works for anyone, not just a room with a big screen. In an ASI:One chat, ask him for a theme and he deals you five stock phrases that fit it; send a verse with them, and the same judge that runs our live battles scores it, quotes your best line and gives you a one-line verdict with content scores (Image, Answer, Craft) out of 100 [true once the next agent deploy lands; builder confirms]. It's an agent registered on Agentverse that speaks the Agent Chat Protocol, running in its own container next to our agent service, so a busy chat never slows a live battle. Agentverse's Inspector button can't reach an agent inside Docker, so we register its mailbox with an Agentverse API key from inside the container (`homer/scripts/agentverse_connect.py`). Agent: `homer-bard` (`agent1qf8cydj43pd7tue06mk9avnp45avcc4ss9gjm98r4lkjczsw0gskzw97edc`). Try it: [ASI:One link].

**Moss: dealing that fits the theme, in milliseconds.** Homer writes a fresh theme every round, so no tag list can know it in advance. When he announces it, every poet's phone shows three of Homer's phrases that fit it. Moss ranks our whole bank of 180 formulas by meaning against the theme, including the 55 our Apify Actor mined, and the dealer draws from the closest matches. Before Moss, the dealer matched tags.
- **Before and after**, same seed (receipt: `homer/bench/moss-2026-10-24-droplet.txt`): for "The night before the battle", the tag dealer deals "the sea-wolf" and "the holy night"; Moss deals "the battle-sweat" and "the last to leave". For "A ship that never came home", Moss finds "and the ships went down" and "the one who stayed".
- **Measured on our production server** (the DigitalOcean droplet, 1 vCPU, inside the live agent container), on the 180-formula bank, 40 runs over 16 themes (receipt `homer/bench/moss-2026-10-24-droplet.txt`, from `homer/scripts/moss_bench.py`): a ranked lookup of the whole bank takes **p50 13.2 ms**, p95 14.9 ms, and a whole deal p50 14.7 ms, p95 17.0 ms. On a MacBook Air it's 1.55 ms (`homer/bench/moss-2026-10-24-mac.txt`).

**Fresh themes only work because of Moss.** A tag list can't know a theme Homer wrote ten seconds ago; meaning search can. And voice games have to answer while the room is still listening, so the deal has to be instant. It also can't stall a battle: if Moss is ever slower than 500 ms or errors, the tag dealer deals instead, and we tested both failures live.

## Tracks to tag on Devpost

**Rechecked Sat 4:17 PM:** Devpost splits Apify into two entries again (tag both), merges Microsoft's two prizes into one entry, and still has no MLH Gen AI, .Tech or DigitalOcean. **As of Sat 12:20 PM, Devpost lists "[Spacetime] Best Use of Spacetime" and "[Anthropic] Claude for Public Benefit". Tag both** (leader). It still has no MLH Gen AI, .Tech or DigitalOcean (Hive has all three; Devpost lists Vultr instead). **As of Sat 2:20 PM, Figma's five old entries are one: "[Figma] Best Figma Workflow Hack".** MLH: "you can opt in to multiple prize categories at time of submission!" An organizer: "Devpost will also be updated soon!" (#0-ask-directors, Sat 10:40–10:50 AM). Tag every track below that Devpost offers on Sunday morning. **How:** tracks are picked on the submission form ("step 3 or 4"), after joining the Cal Hacks 13.0 Devpost (MLH, #0-ask-directors, Sat 12:24 PM). A hacker reported that Step 4 lists individual prize names, such as "1st place from Microsoft", so tick every prize line under each track we enter.

- [ ] **Spacetime: Best Use of Spacetime** (on Devpost since Sat ~12 PM)
- [ ] **Meta: "[Meta] Meta/Facebook: Bringing People Closer Together with AI"**: an "Invitation to advance to the Round 2 Hackathon hosted at Meta's Menlo Park campus. Travel and accommodations provided." (Devpost, Sat 4:17 PM)
- [ ] Cartesia: Best Use of Cartesia
- [ ] **Anthropic: Claude for Public Benefit** (on Devpost since Sat ~12 PM)
- [ ] **Figma: "[Figma] Best Figma Workflow Hack"** (one entry since Sat ~2 PM; add the Figma Slides link and the stage log). Devpost shows "$1,000 in cash, 1 winner" in Amazon gift cards, but Figma's brief still lists four prizes: Best Figma Workflow $2,000, Best Stage Log $2,000, Best Design $500, Most Creative $500. The booth activation ended at 2 PM, so Matus can ask in #spons-figma (draft in [slack-intel.md](slack-intel.md)). We submit the same three deliverables either way: the video (3 minutes max), the stage log and the Figma Slides deck.
- [ ] MLH: Best Use of Gen AI
- [ ] MLH: Best .Tech Domain Name (if registered)
- [ ] MLH: Commit Fellowship (if we want it)
- [ ] **Microsoft: "[Microsoft] Built for the Real World (1st), Customer Impact Award (2nd)"**, one entry since Sat ~4 PM ([opportunities.md](opportunities.md) #3)
- [ ] MLH: Best Domain Name from GoDaddy Registry (only if we register one)
- [ ] **Fetch.ai: Best Use of Fetch.ai** (only if Homer's judge is live on Agentverse and usable from ASI:One)
- [ ] **Moss: Best Use of Moss.** Shipped: `HOMER_DEALER=moss` is live on the droplet, a ranked lookup p50 13.2 ms on the droplet, 180-formula bank (`homer/bench/moss-2026-10-24-droplet.txt`), with a tested fallback. Tag it.
- [ ] MLH: Best Use of DigitalOcean (the agent service runs there)
- [ ] **Apify, two entries again (Devpost, Sat 4:17 PM): tag both.** "[Apify] Best Use of Apify" (5 winners: $2,000 / $1,000 / $800 / $400 / $400) and **"[Apify] Best Actor sponsored by Apify"** ($400, 1 winner: "a Best Actor award for building an actor for this event. Project must be using Apify in a meaningful way."). Epithet Miner was built at this event and mined 55 of the bank's 180 formulas. The blurb still says **Epithet Miner is an Apify Actor, built with AI chat**, and gives the Store link and Actor ID `v4i7ItNXjHMmnKzfo`, as Apify staff asked ("in your submission just share the link and id for us", #spons-apify, Sat 1:13 PM).

Main prizes are automatic.

## Submission checklist

- [ ] Every teammate added on Devpost. **Use the same email as your Cal Hacks sign-up:** asked whether it must match, an organizer said "no but ideally yes" (#0-ask-directors, Sat 4:46 PM).
- [ ] **Team name, a 2–3 sentence elevator pitch and our table number.** The Hive FAQ: "All submissions must include a 2-3 sentence elevator pitch / summary, team location (your table number), and the team name." Tables are assigned "shortly after the 9:00 AM submission deadline" (Hacker Guide), so add the table number then if Devpost has a field for it.
- [ ] No keys in the repo: `.env` gitignored, `.env.example` committed, and the leader's full-history secret scan rerun after the Sat ~11 PM freeze
- [ ] **Repo public by 8:00 AM Sunday:** Sunya (the owner) flips it in Settings → General → Danger Zone. It stays private until then (Matus's call). Matus pings Sunya Saturday night.
- [ ] The GitHub link opens in a logged-out browser (a private window) before the 8:45 submit
- [ ] README has a **Cartesia section**: setup (XcodeGen, signing, `.env`), the Cartesia features used, known limitations
- [ ] README explains where SpacetimeDB is used (tables, reducers, the 20 Hz stream, the private cards, the SDK patches)
- [ ] Video, 2:00, opening with the moment ([video.md](video.md))
- [ ] **Figma deck ready:** **Matus, in the Figma Slides app** (the MCP can't create embeds): share the deck as "Anyone with the link → can view"; on slide 8, paste or Insert → Embed Flow 1 (https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102) and Flow 2 (https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364) over the stand-in images; on slide 9, embed the Directions file (https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv); put the team's names on slide 1. The Make file counts as an embed too, but it was never prompted, so the prototypes are the better proof.
- [ ] **Figma entry, exactly as Figma staff said** (#spons-figma, Sat 3:07 PM): the Figma Slides link goes in Project Details → **"Try it Out links"**; select **"[Figma] Best Figma Workflow Hack"** under Sponsors & Special Prizes; set the Slides sharing to **"View all"**. The design files are shared with "Anyone" too, and the whole team is Edu verified.
- [ ] **Matus submits the judging build (probably build 34, `202610242129`, if its visual pass is clean; leader confirms at 11 PM) for external review (Beta App Review) as soon as it finishes processing**, so the public TestFlight link gives judges the build that passed the 8 PM runs. Build 18 is only the study's build now (leader, Sat ~7 PM). Leader confirms the judging build at the 11 PM freeze.
- [ ] TestFlight public link installs on an iPhone that isn't on our internal tester list
- [ ] **The website opens at https://play.206.189.237.157.sslip.io** in a private window on a laptop, and on a phone on cellular with Wi-Fi off, so we know it works off our network. Then an iPhone joins its room
- [ ] Cover image: an arena frame with the carved gold line, matte, no neon
- [ ] Every `[bracket]` filled or deleted. Search the page for `[` before submitting.
- [ ] Submitted by **8:45 AM Sunday** (hard deadline 9:00)
