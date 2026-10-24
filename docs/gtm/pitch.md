# Pitch kit: MeNIN

The table demo is in [demo-script.md](demo-script.md). This file holds everything around it: the lines, the booth pitches, the Q&A and the video.

**Frame (SPEC "The games"):** ancient Greek party games, on one shared screen, with your iPhone as the controller. **The poetry battle is the main event and the spine of every demo.** Socratic debate and discus are in build now (SPEC `2fb21bf`). Each one reaches the demo only if it runs 5 times in a row without failing by Sat 8 PM. Everything else appears as locked tiles.

**Tone (Matus):** professional and badass, never academic. History gets **one sharp line**, then straight to the battle. The battle is the loudest part. Say "iPhone", never "anyone".

**Trademarks:** "Wii", "Wii Sports" and "Guitar Hero" belong to Nintendo and Activision. **Use them only out loud, as comparisons** ("like Wii Sports"). Never put them in the product name, the Devpost title or tagline, the video title cards or the app.

## Name: MeNIN (decided by Matus)

**MeNIN** comes from μῆνιν (*mēnin*), "rage", the first word of the Iliad and so the first word of Western literature. **Homer** hosts the poetry battle and announces discus, and **Socrates** hosts the debate. Always write it **MeNIN**, matching the repo and the Figma file.

- **Say it before anyone reads it: "MAY-nin."** Written cold, "MeNIN" gets read as "men-in" or "me-NIN". The opener does the teaching, so the first time a judge hears the word, they learn what it means.
- **Devpost title (recommended): "MeNIN: Ancient Greek Party Games, Hosted by Homer."** Nobody knows "MeNIN" until it's explained, but everyone knows "Homer", so the title borrows his name to carry the poetry. Leader's version, "MeNIN: Party Games of Ancient Greece", is the fallback if a shorter title is wanted.
- **Heads-up:** "menin" is also a protein in cancer biology, so a web search won't find us. That's irrelevant at the table; the domain and the TestFlight link are how people find us.

## The thesis (Matus's vision)

**AI can write anything now. What's left, and what matters more than ever, is a human who can stand up and move people.** The Greeks treated that as a skill you train in public, by contest: rhapsodes competing at the Panathenaic Games, citizens arguing in the Assembly, Socrates questioning people in the agora. MeNIN brings the contest back as party games, with AI as the coach and the judge, never the speaker.

- **The contrast that wins the room:** most AI talks *for* you; Homer makes *you* talk. Nearly every other table is building AI that speaks or acts for the user, so this is the one idea nobody else at Cal Hacks is pitching.
- **The newest idea is the oldest one.** The Iliad is about 2,700 years old. "The future of AI is 2,700 years old" works as a Q&A or Devpost hook. Keep it out of the opener, which already has one history line.
- **Each event is one part of the voice.** The poetry battle is improvising, the debate with Socrates is persuading, the discus is the fun that gets you in the door.
- **How it lands per sponsor:**
  - **Anthropic:** AI that makes people more capable, not replaced: a public-benefit story. The community stays narrow (slam poets in [the poet's scene]), and the vision is why it matters.
  - **Meta:** people speaking to each other in one room.
  - **Cartesia:** voice is literally the product, yours and Homer's.
- **Guardrails:**
  - Two sentences of vision, then the demo proves it. A thesis without the battle is a TED talk.
  - Say "move people" or "change minds", never "persuade" or "influence", which sound like manipulation.
  - Never claim "a totally new way of thinking". Show it.
  - The proof is tonight's study number: a first lesson measurably improved how people speak.

## The lines

| Length | Line |
| --- | --- |
| **The opener (first 14 s)** | **Homer** (the app's own first-open line, P12): "The first word of Western literature is *mēnin*. Rage." Then **Matus**: "AI can write anything now. It can't stand up and move a room for you. The Greeks trained that like a sport. MeNIN is their games: party games for your voice, with your iPhone as the controller." If the app can't play Homer's line, Matus says it himself. *(The old "like Wii Sports" opener is the fallback for a judge who looks lost: spoken only.)* |
| 5 s (written) | **MeNIN: ancient Greek party games, hosted by Homer. Battle in verse on one screen, with your iPhone as the controller.** |
| The second history line (only for Q&A or Devpost, never in the opener) | "The Greeks didn't separate sport and poetry: at the Panathenaic Games, poets competed reciting Homer right next to the athletes." |
| The hand, in one line (mechanics, not history) | "You're dealt phrases that already fit the beat. That's how Homer improvised, and how freestyle works." |
| The agent line (once per pitch) | "Homer is a live agent doing real work: he listens, judges, coaches, hosts and writes the song from the room, about three seconds per verdict." Most Cal Hacks judges are agent engineers (#1-introductions). Say it once; more than once and it sounds like buzzwords. |
| Finale | "A rhapsode was a song-stitcher. So Homer stitches your battle into one song." |
| Close | "**Most AI talks for you. Homer makes you talk.** That's MeNIN." Then the invitation: "Want to throw the discus?" (or "Want to battle us?") |

One history line in the opener, and that line is *mēnin*. The Panathenaic line gets saved for the judge who asks "why poetry in a games app?"

Don't say: "oral-formulaic composition", "scansion", "meter", "iamb", "pedagogy", "learning platform", "AI tutor", "Olympics" or "Olympic" (the IOC protects both), or anything else that sounds like a lecture.

## How we hit the main judging criteria

The criteria are from #0-ask-directors. Every claim below has to be true by Sunday.

| Criterion (their words) | Our proof at the table |
| --- | --- |
| **Application**: "who they help, what problem they solve, and why people would actually use them" | Spoken-word and slam poets in [the poet's scene] practice alone between weekly open mics. MeNIN gives them a stage every night that hears your beat. Party games are why a room of friends opens it again. **Saturday's first-timer number** goes here. |
| **Intentionality**: "Every design choice should feel purposeful" | One engine, and every event is a config: host, cards, rubric, beat. One idea carried everywhere in the poetry battle: Homer's phrases, on your phone, in the rescue, in the judging (Craft), in the stitched song. |
| **Functionality**: "live demo that runs smoothly... clear, meaningful video demo on devpost" | A live poetry battle on iPhones and the arena, a verdict in about 3 s, a rehearsed fallback to Practice, a 2-minute video. **Only events that pass the checkpoint are unlocked; the rest are locked tiles, never half-working.** |
| **Creativity**: "unexpected combinations of ideas or technologies" | Greek *agon* as party games: a rap battle judged by Homer, a debate hosted by Socrates, and a discus you throw with your phone, all on a matte paper-cut scene that paints your voice, with an original score by a teammate |
| **Technical Complexity**: "engineering depth that goes beyond basic implementation" | Streaming STT biased with the poet's hand as keyterms (3% word error with the drum at full volume in our tests, 20% without), on-device onset detection for the beat lane, voice levels at 20 Hz through SpacetimeDB to Metal shaders on the arena, battle logic in server-side reducers, a deterministic stress scanner feeding a Claude judge under 3 s, multiple events from one engine config, Core Motion discus physics, the haptic beat |

## Spread-thin guard (GTM watchdog rule)

The new frame raises the ceiling on Most Creative, Hacker's Choice and Meta. It also invites the one critique the organizers warned about: "a project spread thin with too many features." So:

- **At least 80% of the 2 minutes is the poetry battle.** The other events get one line and a tile.
- **An event that isn't solid stays a locked tile.** A locked tile reads as a roadmap; a broken event reads as spread thin.
- If neither debate nor discus passes the checkpoint, the frame still holds: "Every party game starts with one great event. Ours is a poetry battle."

## Booth pitches (Saturday afternoon, 30 seconds each, phone in hand)

Goal: every sponsor judge has played Homer before Sunday. Open the app first and talk second. **The route, times, booth numbers and what to show at each are in [booths.md](booths.md).** These are the 30-second lines.

**Spacetime**
> "MeNIN is ancient Greek party games, and SpacetimeDB *is* the arena. Every event runs on one shared state: turn order, scoring and the winner in reducers. Each phone streams its voice at about twenty hertz so the arena's scene moves with whoever's speaking. The client is Swift on iPhone. Want to take a turn?"
Ask them: "What would make this a top-three Spacetime project for you?" Write down the answer and build toward it.

**Cartesia**
> "Voice is the whole game. We feed Homer's phrases to the recognizer, so it hears the wine-dark sea through the drum: in our tests, 3% word error with the drum at full volume using ink-2 keyterms, 20% without. The final transcript lands about 75 ms after you stop. Homer is Carl on Sonic 3.6, with first audio in about 100 ms. He judges you like a title-fight MC and whispers you a line when you freeze. [If debate shipped:] Socrates hosts the debate in a completely different voice: quick, wry, always asking."
Ask them: "How many winners are there, and what does great 'impact and responsibility' look like to you?"

**Anthropic**
> "For spoken-word and slam poets in [the poet's scene], who practice alone between weekly open mics. We measure it: Beat score, first try vs last, and next, Beat across a poet's first five sessions. Claude judges every verse with a stress count from our scanner, so it never guesses the beat, and every score shows its quote. The app is also being built by a team of Claude Code sessions."
Keep the Anthropic story on the poets and on training (Bard mode). The party frame is why people come back, not the public-benefit claim.
Ask them: "Is our community narrow enough?"

**Meta** (find them at their workshop)
> "Party games for one room: one screen, everyone's phone is a controller. The main event is a poetry battle where the judge scores how well you answer the person before you, and at the end Homer stitches everyone's lines into one song."

**Figma** (Booth #35)
> "One designer and six Claude Code sessions, with Figma as the source of truth between them. We're keeping a stage log, including what broke, like the web-to-iOS pivot."
Ask them: "What makes a stage log win?"

## Q&A bank

Answer in one breath, then stop.

| They ask | We say |
| --- | --- |
| Why does AI make speaking matter more? | "When anyone can generate a perfect paragraph, writing stops being the signal. Standing up and saying it, live, in your own voice, is what's left. The Greeks trained exactly that." |
| Isn't training persuasion dangerous? | "Homer scores whether you answered the person in front of you, and shows you why with five scores and the quoted line. It trains you to listen and respond, not to manipulate." |
| What does MeNIN mean? | "*Mēnin*, rage. It's the first word of the Iliad. Homer started Western literature with a fight." |
| Why poetry in a games app? | "The Greeks didn't separate them. At the Panathenaic Games, poets competed next to the athletes." |
| How is the AI judge not arbitrary? | "Flow isn't the AI's opinion; a stress scanner counts it. Range comes from the emotion engine. Claude scores Craft, Image and Answer with the phrases Homer dealt you and the verse you answered in front of it. You always see all five scores and the line it quoted." |
| Why several events? | "One engine. Each event is a config: who hosts, what cards you get, how it's judged, beat on or off. Poetry came first; the debate took [hours] on the same engine." *(Only if debate shipped.)* |
| Isn't this just a game? | "The games are why you come back. Bard mode is where you get good. Last night, five first-timers went from [first] to [last] out of 10 on Beat, in one lesson." *(Use the study's real numbers and pm's wording in docs/study.md.)* |
| Does it work in this noise? | "Headset mic, a mic that opens only on your turn, captions, and the transcript is always on screen so you can see what Homer heard." *(Only say it if Saturday's hall test passed.)* |
| How does it hear you over the drum? | "We feed Homer's phrases to the recognizer, so it hears the wine-dark sea through the drum. Cartesia ink-2 with keyterms: 3% word error with the drum at full volume in our tests. Without them, 20%." |
| How did you measure that? | "On test recordings with our drum mixed in at full volume. The real-mic test in the hall is Saturday night." *(If that test ran, give its number instead.)* |
| Doesn't the beat lane lag behind speech? | "No. The lane runs on syllable onsets detected on the phone itself. It never waits for the transcript." |
| Isn't this just for poets? | "It's for anyone who has to speak in front of people. Poets are where we start, because they already practice this and have nowhere to do it." |
| Why Homer and not Shakespeare? | "Shakespeare wrote. Homer improvised. Improvising is the skill." |
| Is Homer an agent? | "Yes, a live one. Every round he writes a fresh theme and deals you phrases for it, then hears you through Cartesia, scores you with Claude plus our scanner, and speaks the verdict. Then he writes the round into a song. Every step writes to SpacetimeDB, so the whole room sees it." |
| What's AI and what isn't? | "Deterministic: the beat count, the scoring math and the discus physics. Claude: the judgment, the coaching, Homer's and Socrates' lines and the stitched song. Cartesia: ears and voice. Nothing is mocked." |
| Why iPhone only? | "Your phone is the mic, the controller and the discus, and the beat lives in your hand through haptics. That needs native. The big screen is our website, so any laptop at the table becomes the arena." |
| What happens Monday? | "Tap the TestFlight link on your iPhone. No account, open a room, play." *(Only if the public link is approved. Otherwise: "TestFlight now, App Store next.")* |
| How fast is the verdict? | "About three seconds from your last word to Homer's voice. The transcript is final 75 ms after you stop, and Homer's voice starts about 100 ms after the verdict is written. The rest is Claude judging." *(Quote the measured p50, not a guess.)* |
| Is the music AI? | "No. [Composer's name] on our team composed the score. Claude judges your verse; a person wrote the music." *(Only if that's true for every cue. If any cue used AI tools, say which.)* |
| What did you cut? | "Ranks, spectators, and every event that wasn't solid. Those are the locked tiles." |
| What's hardest? | "Voices bleeding into each other's mics in one room. We moved the beat into your palm." |
| What about bad content? | "Homer won't speak it: the turn scores zero and nothing gets quoted. Names are filtered before he says them." |

## Video

The full plan is in [video.md](video.md): the 2:00 shot list, who records what, when (the main shoot is Sat 5:00–5:30 PM, on build 11 and the website), the capture settings and the 90 s backup video. Open with the moment, not a title card. Real footage only, and no "Wii" anywhere in it, not even spoken.

Thumbnail / Devpost cover: one arena frame with the carved gold line over matte color fields. No neon, no glow.

## Hacker's Choice ground game (Saturday night)

- **Discus is the hook** if it passes the Sat 8 PM check. The fanfare from the score sells the throw. Anyone can swing a phone, with no poetry nerves. "Throw the discus, then stay for the battle."
- Battles at our table on our iPhones, plus the arena. Say "Two minutes, and Homer's phrases are there if you get stuck" and let the phrases do the work.
- **Karaoke** (Sat 8–9:30 PM, Theater) is a room full of people holding mics in a performing mood. Bring the arena and two phones.
- Film 15-second clips (a discus throw, the scene shifting color during a verse) and post them tagging the sponsors.
- Never block the build for this. One person, one hour.
