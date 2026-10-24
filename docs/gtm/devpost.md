# Devpost draft

Paste this into Devpost. **Never submit a claim that isn't true on Sunday morning.** The guide recommends submitting a draft Saturday night and editing it until 9:00 AM.

**State: Sat Oct 24, 8:30 AM.** Everything outside `[brackets]` is true now. Each bracket waits on one of these:

| Placeholder | Comes from | When |
| --- | --- | --- |
| `[N]`, `[first]`, `[last]`, `[time]`, poet quotes | The first-timer study (`docs/study.md`, run by the poet) and the poet's texts. Use one of pm's line options in study.md. | Sat 8 PM |
| `[real-mic WER]` | swift's rerun of the keyterm test on a real iPhone mic. If it differs from 3%/20%, it replaces those numbers everywhere. | Once the agent is public (it is now) |
| `[composer's name]`, `[how the score was made]` | Matus | Today |
| `[p50]` | Now filled from homer/README: p50 1.0 s, p95 1.5 s (10 calls, Fri). Update it if the Sat 10 AM production checkpoint differs. | Sat 10 AM |
| `[If debate passed]`, `[If discus passed]` | The Sat 8 PM check: 5 runs in a row without a failure. Delete the section if the event failed. | Sat 8 PM |
| `[TestFlight public link]` | Apple's Beta App Review | When approved |
| `[Video]`, `[Figma Slides]` | [video.md](video.md); the Figma Slides deck | Sat 11 PM |
| `[team]` | Every teammate's name and role | Today |

---

**Project name / title:** MeNIN: Ancient Greek Party Games, Hosted by Homer *(fallback: "MeNIN: Party Games of Ancient Greece")*

**Tagline** (200 chars): Rage is the first word of the Iliad. MeNIN turns it into party games: battle in verse over the beat, judged live by Homer, on one screen with your iPhone as the controller.

*Trademarks: no "Wii", "Wii Sports", "Guitar Hero" or "Olympic" anywhere in this page.*

**Try it:** [TestFlight public link] · [playmenin.tech] *(pending Matus registering it)* · Video: [Video] · Figma: [Figma Slides] · Clickable prototypes: [first open → practice](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102) · [a full battle](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364)

---

## Inspiration

The first word of Western literature is μῆνιν (*mēnin*, pronounced "MAY-nin"): **rage**. Homer opened the Iliad with a fight, and so do we.

**AI can write anything now. What it can't do is stand up in a room and move people for you.** That's becoming the skill that matters most, and the Greeks treated it as one you train in public, by contest: rhapsodes competing at the Panathenaic Games, citizens arguing in the Assembly, Socrates questioning strangers in the agora. Most AI talks for you. We wanted AI that makes you talk.

MeNIN is for spoken-word and slam poets in [the poet's scene]. [Poet's name] is one of them. Open mics are once a week, and between them you practice alone in your room, with no one to tell you whether your beat landed. [Quote from a poet interviewed Saturday, with permission.] Improvising out loud is a learnable skill: Homer did it with stock phrases built to fit the beat, and freestyle rappers do it every night. Almost nobody gets to practice it with friends.

So we built ancient Greek party games for your voice, with AI as the coach and the judge, never the speaker, and made the poetry battle the main event.

## What it does

The first time you open MeNIN, Homer speaks before any menu: "The first word of Western literature is *mēnin*. Rage. Give me one line." You say anything, the scene answers your voice, and Homer says, "Good. Now let me show you how I did it."

Homer is a live agent doing real work: he deals, listens, judges, coaches, hosts and writes the song from the room.

One screen is the arena: a Mac or an iPad running the app. Every player's iPhone is their controller. Scan the QR code or type the room code to join. No account needed.

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

**The scene.** Behind everything, a full-screen procedural scene paints the speaker's voice: matte layered color fields, like cut paper. Loudness and pitch move it at 60 fps, and every ~1.5 s an emotion read of your words and voice shifts its colors across eight palettes. Homer never names your emotion; the scene shows it.

**The score.** MeNIN has an original soundtrack composed by [composer's name], on our team: a hall and menu theme, an intro for each event, the discus throw and its fanfare, a champion sting, and ambience for training. Music never plays while a mic in the room is open. During a turn, only the procedural beat plays, and the music ducks under Homer's and Socrates' voices. [How the score was made: instruments, DAW, and whether any AI tools were used. Write it honestly.]

**Bard mode.** Short voiced lessons from Homer, one move each: the beat, the formula, the epithet. Homer shows the move, names it in a sentence, and gives you one note per try until you land it. The epithet you coin becomes your battle name.

**Practice mode.** Spar with Homer, best of three.

**[If debate passed] Socratic debate.** It's the same engine as the battle: timed spoken turns, the scene and a spoken verdict, with no beat. Socrates hosts in his own voice, and sides are dealt by turn order. Your hand holds rhetorical moves ("define your terms", "counterexample", "analogy"). Tap a move as you make it, and the judge checks that you really made it. Freeze, and Socrates whispers you a question to ask. It has its own five axes: Claim, Reason, Answer, Craft and Poise.

**[If discus passed] Discus.** Hold a button with your thumb, swing your iPhone, and lift your thumb to release. You never let go of the phone. Core Motion measures the swing and the release, the arena flies the throw, and Homer calls the distance. No voice, no AI: just physics and bragging rights.

## How we built it

- **One engine, many events.** Each event is a config: host, hand, rubric, turn length, beat on or off. [If debate passed: the debate took (hours) on top of the poetry engine.]
- **Universal iOS app (SwiftUI, iOS 18+, iPhone and iPad).** One app, every mode. A device runs it as the arena or as a player, and Apple Silicon Macs run it as the arena.
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
  - Each judgment is one streamed request to **Claude Opus 5.5**: fast mode, low effort, a cached system prompt and a JSON schema, so the output is always valid. Verdict text lands in **p50 1.0 s, p95 1.5 s** (10 live calls, Fri Oct 23, `homer/scripts/latency.py`). [Update if the Sat 10 AM production check differs.]
  - Claude also names poets and coins epithets, writes Homer's lesson feedback, his sparring verses and the round verdicts, and writes the stitched song. The freeze whisper makes no model call: it picks the formula from your hand that fits the line, so it's instant.
- **The stress scanner** (Python, CMU Pronouncing Dictionary) counts the beat deterministically. The **Beat** score never comes from the model's opinion.
- **Python + FastAPI** service for the Claude calls, the scanner and the formula bank, in Docker behind Caddy on **DigitalOcean**.
- **Figma.** Matus drew the first concept in Figma Design. The art session reads frames, exact values and assets straight from the file through the Figma MCP server, so it builds from the design rather than from screenshots. We compared two design directions, "Atelier" and "Cut paper", in a single Figma variable collection with two modes. Every variable carries its Swift name, so one mode switch in Figma matches one launch flag in the app. The art session built two clickable prototype flows through the MCP, bound to the same tokens: [first open to practice](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-102&starting-point-node-id=15%3A102), and [a full battle from join to champion](https://www.figma.com/proto/qyaXnV3HbIUPIfYVbyqKwv?node-id=15-364&starting-point-node-id=15%3A364). Design file: https://www.figma.com/design/qyaXnV3HbIUPIfYVbyqKwv · Full stage log: [Figma Slides].
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
- **A verdict that lands in three seconds.** Our first judge was a slow, multi-step tool loop. We cut it to one streamed Claude call with the scanner's count already in the prompt, low effort and a fixed JSON schema. [p50 and p95 from Saturday's measurement.]
- **Every phone was syncing every room.** The community Swift SDK subscribes to whole tables, so with a 20 Hz voice stream each phone would have received every room's traffic. We patched it to subscribe per room.
- **We switched from web to iOS mid-build.** On Friday night the scene was already written for the web in React, Three.js and GLSL. The palette and motion lived in plain math tables, so they carried over to Metal almost line for line. The React code didn't survive.
- [Honest additions on Sunday morning.]

## Accomplishments that we're proud of

- [N] people who'd never freestyled took lesson one at Cal Hacks. Their Beat score went from **[first] to [last]** out of 10, in about [time] minutes. *(Beat only, first try vs last. If fewer than three landed, drop the time.)*
- A live battle on iPhones, with a spoken verdict about three seconds after the last word. [Swap in the measured p50.]
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
- **A path from prototype to production:** TestFlight now, then the App Store. The agent service runs in Docker on DigitalOcean, and SpacetimeDB on Maincloud.
- **Responsible design:** captions, push-to-talk, no audio through our server, gentle roasts, and the content and name filters (below).
- **End-to-end functionality:** the live battle runs on real services, with nothing mocked.

## Where it can go wrong (and what we do about it)

- **Speech recognition misses in noisy rooms.** Keyterms from your hand cut word errors from 20% to 3% with the drum at full volume in our tests, but those were recorded test mixes, and a loud hall with a real phone mic is harder. The live transcript is always on screen, so you see what Homer heard, and push-to-talk keeps the mic closed until you choose.
- **Taste is contestable.** Every verdict shows five scores and the quoted line, so you can see why you lost.
- **Emotion reading is approximate.** The scene is art, not a diagnosis, and Homer never names your emotion.
- **English stress has edge cases** with names, slang and loanwords. The scanner flags uncertain syllables instead of marking them wrong.
- **A roast can sting a beginner.** Roasts stay gentle and only in Battle; in lessons Homer is a calm coach.
- **Bad content.** A verse that isn't fit for the hall scores nothing, and Homer won't quote it. Names are filtered before Homer says them.
- **Privacy:** no audio passes through our server. Your phone streams the mic straight to Cartesia for transcription. Transcripts, scores and lines live in the room's tables, and Rematch clears them. [Confirm before submitting: how long finished rooms are kept, and Cartesia's retention setting on our account.]
- **Accessibility:** captions on everything Homer says. The beat is in your palm as haptics, so you can feel it without hearing it.

## Built with

swift · swiftui · metal · avfoundation · core-haptics · [core-motion] · spacetimedb · typescript · python · fastapi · anthropic · claude · claude-code · cartesia · cmu-pronouncing-dictionary · figma · xcodegen · docker · caddy · digitalocean · [apify]

---

## Sponsor-track blurbs (paste only for tracks that really shipped)

Every integration below runs behind a switch, off the demo path (SPEC `5a6a8fe`). Fill each bracket with what's true, or delete the blurb.

**Apify: Epithet Miner.** Homer improvised with stock phrases, and so do you: every turn deals you five. Our Apify Actor, **Epithet Miner**, builds that bank:
- It reads public-domain Homer translations on Project Gutenberg and pulls out the recurring epithets and formulas ("the wine-dark sea", "rosy-fingered Dawn").
- It counts how often each one appears, and outputs them in our bank's format, with the source.
- Our stress scanner counts each phrase's beats, and a person reviews every candidate before it joins the bank.

[N] of the [M] phrases you can be dealt came from the Actor. We built it with [Apify AI Chat / the Apify MCP in Claude Code: say which, honestly] and published it at [Apify Store link].

**Fetch.ai: Homer on Agentverse.** Anyone on ASI:One can send Homer a verse and get his verdict back: five scores, the best line quoted and a one-line verdict, from the same judge that runs our live battles. [If it shipped: and ask him to deal a hand of five formulas for any theme.] It's an agent registered on Agentverse that speaks the Agent Chat Protocol, running inside our agent service behind a switch, so the battle never depends on it. Try it: [ASI:One link or agent address].

**Moss: dealing that fits the theme, in milliseconds.** When Homer announces a theme, every poet gets five stock phrases that fit it. With Moss, the dealer retrieves the formulas closest in meaning to the theme from our bank of [N], in [measured] ms, rather than matching keywords. So "[a real theme]" deals you "[a real formula from the bank that shares no word with it]". Voice games have to answer while the room is still listening, and Moss keeps the deal instant. It runs behind a switch, with our keyword dealer as the fallback.

## Tracks to tag on Devpost

**As of Sat 8:27 AM, Devpost's prize list has no Spacetime, no Anthropic, and no MLH Gen AI, .Tech or DigitalOcean.** It also lists Figma's old five prizes. The Hacker Guide wins, and a question to the directors is drafted ([slack-intel.md](slack-intel.md)). Tag every track below that Devpost offers by Sunday, and follow the directors' answer for the rest.

- [ ] Spacetime
- [ ] Meta: Bringing People Closer Together with AI
- [ ] Cartesia: Best Use of Cartesia
- [ ] Anthropic: Claude for Public Benefit
- [ ] Figma (add the Figma Slides link and the stage log)
- [ ] MLH: Best Use of Gen AI
- [ ] MLH: Best .Tech Domain Name (if registered)
- [ ] MLH: Commit Fellowship (if we want it)
- [ ] **Microsoft: Built for the Real World** and the Customer Impact Award ([opportunities.md](opportunities.md) #3)
- [ ] MLH: Best Domain Name from GoDaddy Registry (only if we register one)
- [ ] **Fetch.ai: Best Use of Fetch.ai** (only if Homer's judge is live on Agentverse and usable from ASI:One)
- [ ] **Moss: Best Use of Moss** (only if theme-fitting dealing really ships behind its switch)
- [ ] MLH: Best Use of DigitalOcean (the agent service runs there)
- [ ] **Apify: Best use** and **Best Actor** (only once Epithet Miner's formulas are really in the bank)

Main prizes are automatic.

## Submission checklist

- [ ] Every teammate added on Devpost
- [ ] No keys in the repo: `.env` gitignored, `.env.example` committed, and the leader's full-history secret scan rerun after the Sat ~11 PM freeze
- [ ] **Repo public by 8:00 AM Sunday:** Sunya (the owner) flips it in Settings → General → Danger Zone. It stays private until then (Matus's call). Matus pings Sunya Saturday night.
- [ ] The GitHub link opens in a logged-out browser (a private window) before the 8:45 submit
- [ ] README has a **Cartesia section**: setup (XcodeGen, signing, `.env`), the Cartesia features used, known limitations
- [ ] README explains where SpacetimeDB is used (tables, reducers, the 20 Hz stream, the private hand, the SDK patches)
- [ ] Video, 2:00, opening with the moment ([video.md](video.md))
- [ ] Figma Slides link, files shared with "Anyone", whole team Edu verified
- [ ] TestFlight public link installs on an iPhone that isn't on our internal tester list
- [ ] Cover image: an arena frame with the carved gold line, matte, no neon
- [ ] Every `[bracket]` filled or deleted. Search the page for `[` before submitting.
- [ ] Submitted by **8:45 AM Sunday** (hard deadline 9:00)
