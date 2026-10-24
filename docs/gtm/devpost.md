# Devpost draft

Paste this into Devpost. Anything in `[brackets]` needs a real number or link before submitting. **Never submit a claim that isn't true on Sunday morning.** The guide recommends submitting a draft Saturday night and editing it until 9:00 AM.

---

**Project name / title:** MeNIN: Ancient Greek Party Games, Hosted by Homer *(fallback: "MeNIN: Party Games of Ancient Greece")*

**Tagline** (200 chars): Rage is the first word of the Iliad. MeNIN turns it into party games: battle in verse over the beat, judged live by Homer, on one screen with your iPhone as the controller.

*Trademarks: no "Wii", "Wii Sports", "Guitar Hero" or "Olympic" anywhere in this page.*

**Try it:** [TestFlight public link] · [playmenin.tech] *(pending Matus registering it)* · Video: [link]

---

## Inspiration

The first word of Western literature is μῆνιν (*mēnin*, pronounced "MAY-nin"): **rage**. Homer opened the Iliad with a fight, and so do we.

[Poet's name] performs spoken word. Open mics are once a week, and between them you practice alone in your room, with no one to tell you whether your beat landed. [Quote from a poet interviewed Saturday, with permission.] Improvising out loud is a learnable skill: Homer did it with phrases built to fit the beat, and freestyle rappers do it every night. Almost nobody gets to practice it with friends.

So we built ancient Greek party games, and made the poetry battle the main event.

## What it does

One screen is the arena: an iPad or a Mac running the app. Every player's iPhone is their controller. No account needed.

| Event | Host | You |
| --- | --- | --- |
| **Poetry battle** (main event) | Homer | Improvise verse over the beat |
| [Socratic debate, only if shipped] | Socrates | Argue a question in timed spoken turns |
| [Discus, only if shipped] | Homer announces | Swing your phone; its motion sensors measure the throw |

Other events show as locked tiles, because we only unlock what's solid.

**The poetry battle.** Two to five poets in one room. Each poet's iPhone is their mic and their private hand.
- Homer announces each poet by their epithet.
- Every turn you're dealt five formulas that fit the beat.
- Homer drops a slow drum, and you feel it in your palm through haptics.
- You speak two to four lines. Each stress that lands on the beat hits like a drum strike on the beat lane, and every formula you use flips onto the arena.
- Freeze for a second and your hand comes forward with one card raised, while Homer whispers you a line that fits.
- About three seconds after your last word, Homer delivers the verdict like a title-fight MC: five scores and your best line, quoted.
- The best line of each round is carved in gold across the arena.
- At the end, Homer becomes a rhapsode, a song-stitcher. He stitches every poet's lines into one song and performs it over the beat while the arena replays the battle's colors. Then he crowns the champion.

**The scene.** Behind everything, a full-screen procedural scene paints the speaker's voice: matte layered color fields, like cut paper. Loudness and pitch move it at 60 fps, and every ~1.5 s an emotion read shifts its colors. Homer never names your emotion; the scene shows it.

**Bard mode.** Short voiced lessons from Homer, one move each: the beat, the formula, the epithet. Homer shows the move, names it in a sentence, and gives you one note per try until you land it. The epithet you coin becomes your battle name.

**Practice mode.** Spar with Homer, best of three.

**[Socratic debate, only if shipped.]** It's the same engine as the battle: timed spoken turns, the scene and a spoken verdict. But Socrates hosts, in his own voice, and your hand holds rhetorical moves ("define your terms", "counterexample", "analogy"). Freeze, and he whispers you a question to ask.

**[Discus, only if shipped.]** Swing your iPhone and lift your thumb to release. Core Motion measures the swing and the release, the arena shows the throw, and Homer calls the distance. No voice, no AI: just physics and bragging rights.

## How we built it

- **One engine, many events.** Each event is a config: host, hand, rubric, turn length, beat on or off. [If debate shipped: the debate took (hours) on top of the poetry engine.]
- **Universal iOS app (SwiftUI, iOS 18+, iPhone and iPad).** One app, every mode. A device runs it as the arena or as a player.
  - AVAudioEngine captures the mic with voice processing.
  - Core Haptics plays the beat in your hand.
  - Metal shaders render the scene.
  - Syllable onsets detected on the phone itself drive the beat lane, so a hit never waits for the transcript.
- **SpacetimeDB** is the hall: rooms, players, turn order, timers, verses, scores and the carved lines.
  - Battle logic runs in **reducers**, server-side.
  - Each phone streams loudness and pitch at about 20 Hz into a table the arena subscribes to, so the arena's scene moves with whoever is speaking.
  - [Swift client: name the SDK used.]
- **Cartesia** is the ears and the voice.
  - Streaming speech-to-text (**ink-2**, over WebSocket) writes the live transcript. We send the poet's hand of formulas as **keyterms**, so it hears "the wine-dark sea" through the drum. With the drum at full volume (0 dB), word error rate is **3% with keyterms and 20% without**. The final transcript arrives about **75 ms** after the poet stops.
  - Cartesia TTS is Homer (**sonic-3.6**, the voice Carl, "Steady Storyteller"), with first audio in about **100 ms**: lessons, entrances, verdicts, the freeze whisper and the stitched song.
- **Claude (Anthropic)** is the judge, the coach and the MC.
  - The judge gets your hand, the verse you're answering and the scanner's stress count, and returns scores, the best line and a one-line verdict as strict JSON in about [1.5] s.
  - Claude also writes Homer's lessons, his sparring verses and the stitched song.
- **The stress scanner** (Python, CMU Pronouncing Dictionary) counts the beat deterministically. The **Beat** score never comes from the model's opinion.
- **Python + FastAPI** service for the Claude calls, the scanner and the formula bank, served at `api.playmenin.tech`.
- **Figma** [only once true: designs, palettes, and the Figma-to-SwiftUI handoff; stage log linked below].
- Built by one designer and a team of Claude Code sessions (leader, product, art, multiplayer, iOS, go-to-market) working from one spec.

### Judge axes

| Axis | What it measures | Scored by |
| --- | --- | --- |
| Beat | Did your stresses land | Stress scanner (deterministic) |
| Craft | Used formulas, varied them, coined new ones | Claude |
| Image | Strength of the imagery | Claude |
| Answer | Responded to the last verse | Claude |
| Range | How much emotional ground you covered | Emotion engine |

## Challenges we ran into

- **One room, many mics.** The drum and Homer's voice bleed into every phone's mic. We put the beat in your palm through haptics and duck the arena drum while you speak.
- **Hearing "rose-fingered Dawn" through a drum.** Recognizers mangle exactly the rare phrases the game runs on. We feed your hand to the recognizer as keyterms, and with the drum at full volume the word error rate fell from 20% to 3%.
- **A verdict that lands in three seconds.** [What we measured, and what we cut to get there.]
- [The platform switch from web to iOS mid-build, and what carried over.]
- [Honest additions on Sunday morning.]

## Accomplishments that we're proud of

- [N] first-timers went through lesson one at Cal Hacks. Their Beat score went from **[X] to [Y]** in about four minutes.
- A live battle on iPhones with a spoken verdict about [3] s after the last word.
- 3% word error rate with the drum at full volume, down from 20%, by feeding each poet's hand to the recognizer.
- The stitched song: the room leaves with one poem it made together.

## What we learned

[Two or three true sentences, written Sunday morning.]

## What's next

- Public TestFlight now, then the App Store
- More events on the same engine: the locked tiles
- Open-mic nights: a host runs the arena, the audience battles from their iPhones
- Hard mode: Homer's own dactylic hexameter
- Ranks with Homeric titles: Suitor, Herald, Bard, Rhapsode, Homer

## Where it can go wrong (and what we do about it)

- **Speech recognition misses in noisy rooms.** Keyterms from your hand cut word errors from 20% to 3% under the drum, but a loud hall is harder than our test mix. The live transcript is always on screen, so you see what Homer heard, and push-to-talk keeps the mic closed until you choose.
- **Taste is contestable.** Every verdict shows five scores and the quoted line, so you can see why you lost.
- **Emotion reading is approximate.** The scene is art, not a diagnosis, and Homer never names your emotion.
- **English stress has edge cases** with names, slang and loanwords. The scanner flags uncertain syllables instead of marking them wrong.
- **A roast can sting a beginner.** Roasts stay gentle and only in Battle; in lessons Homer is a calm coach.
- **Privacy:** [what we store, e.g. "no audio is stored; transcripts live only for the room". Write it once it's true.]
- **Accessibility:** captions on everything Homer says.

## Built with

swift · swiftui · metal · avfoundation · core-haptics · [core-motion] · spacetimedb · typescript · python · fastapi · anthropic · claude · cartesia · cmu-pronouncing-dictionary · figma · xcodegen · [vultr] · [apify]

---

## Tracks to tag on Devpost

- [ ] Spacetime
- [ ] Meta: Bringing People Closer Together with AI
- [ ] Cartesia: Best Use of Cartesia
- [ ] Anthropic
- [ ] Figma (add the Figma Slides link and the stage log)
- [ ] MLH: Best Use of Gen AI
- [ ] MLH: Best .Tech Domain Name (if registered)
- [ ] MLH: Commit Fellowship (if we want it)
- [ ] MLH: Best Use of Vultr (only if the service runs on Vultr)
- [ ] Apify plus Best Actor (only if the Actor builds the bank)

Main prizes are automatic.

## Submission checklist

- [ ] Every teammate added on Devpost
- [ ] Repo public, with no keys (`.env` gitignored, `.env.example` committed)
- [ ] README has a **Cartesia section**: setup (XcodeGen, signing, `.env`), the Cartesia features used, known limitations
- [ ] README explains where SpacetimeDB is used (tables, reducers, the 20 Hz stream)
- [ ] Video, 2:00, opening with the moment
- [ ] Figma Slides link, files shared with "Anyone", whole team Edu verified
- [ ] TestFlight public link installs on an iPhone that isn't on our internal tester list
- [ ] Cover image: an arena frame with the carved gold line, matte, no neon
- [ ] Submitted by **8:45 AM Sunday** (hard deadline 9:00)
