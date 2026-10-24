# Pitch kit: MeNIN

The table demo is in [demo-script.md](demo-script.md). This file holds everything around it: the lines, the booth pitches, the Q&A and the video.

**Frame (SPEC "The games"):** ancient Greek party games, on one shared screen, with your iPhone as the controller. **The poetry battle is the main event and the spine of every demo.** Socratic debate and discus ship only if the poetry demo passes the Sat 2 PM checkpoint. Everything else appears as locked tiles.

**Tone (Matus):** professional and badass, never academic. History gets **one sharp line**, then straight to the battle. The battle is the loudest part. Say "iPhone", never "anyone".

**Trademarks:** "Wii", "Wii Sports" and "Guitar Hero" belong to Nintendo and Activision. **Use them only out loud, as comparisons** ("like Wii Sports"). Never put them in the product name, the Devpost title or tagline, the video title cards or the app.

## Name: MeNIN (decided by Matus)

**MeNIN** comes from μῆνιν (*mēnin*), "rage", the first word of the Iliad and so the first word of Western literature. **Homer** hosts the poetry battle and announces discus, and **Socrates** hosts the debate. Always write it **MeNIN**, matching the repo and the Figma file.

- **Say it before anyone reads it: "MAY-nin."** Written cold, "MeNIN" gets read as "men-in" or "me-NIN". The opener does the teaching, so the first time a judge hears the word, they learn what it means.
- **Devpost title (recommended): "MeNIN: Ancient Greek Party Games, Hosted by Homer."** Nobody knows "MeNIN" until it's explained, but everyone knows "Homer", so the title borrows his name to carry the poetry. Leader's version, "MeNIN: Party Games of Ancient Greece", is the fallback if a shorter title is wanted.
- **Heads-up:** "menin" is also a protein in cancer biology, so a web search won't find us. That's irrelevant at the table; the domain and the TestFlight link are how people find us.

## The lines

| Length | Line |
| --- | --- |
| **The opener (spoken, the first 8 s)** | "The first word of Western literature is *mēnin*. Rage. Homer opened with a fight, and so do we. **MeNIN** is ancient Greek party games, like Wii Sports, with your iPhone as the controller. The main event is a poetry battle, judged by Homer." |
| 5 s (written) | **MeNIN: ancient Greek party games, hosted by Homer. Battle in verse on one screen, with your iPhone as the controller.** |
| The second history line (only for Q&A or Devpost, never in the opener) | "The Greeks didn't separate sport and poetry: at the Panathenaic Games, poets competed reciting Homer right next to the athletes." |
| The hand, in one line (mechanics, not history) | "You're dealt phrases that already fit the beat. That's how Homer improvised, and how freestyle works." |
| Finale | "A rhapsode was a song-stitcher. So Homer stitches your battle into one song." |
| Close | "That's MeNIN. Want to throw the discus?" (or, if discus didn't ship, "Want to battle us?") |

One history line in the opener, and that line is *mēnin*. The Panathenaic line gets saved for the judge who asks "why poetry in a games app?"

Don't say: "oral-formulaic composition", "scansion", "meter", "iamb", "pedagogy", "learning platform", "AI tutor", "Olympics" or "Olympic" (the IOC protects both), or anything else that sounds like a lecture.

## How we hit the main judging criteria

The criteria are from #0-ask-directors. Every claim below has to be true by Sunday.

| Criterion (their words) | Our proof at the table |
| --- | --- |
| **Application**: "who they help, what problem they solve, and why people would actually use them" | Slam and spoken-word poets practice alone between weekly open mics. MeNIN gives them a stage every night that hears your beat. Party games are why a room of friends opens it again. **Saturday's first-timer number** goes here. |
| **Intentionality**: "Every design choice should feel purposeful" | One engine, and every event is a config: host, hand, rubric, beat. One idea carried everywhere in the poetry battle: the formula, in your hand, in the rescue, in the judging, in the stitched song. |
| **Functionality**: "live demo that runs smoothly... clear, meaningful video demo on devpost" | A live poetry battle on iPhones and the arena, a verdict in about 3 s, a rehearsed fallback to Practice, a 2-minute video. **Only events that pass the checkpoint are unlocked; the rest are locked tiles, never half-working.** |
| **Creativity**: "unexpected combinations of ideas or technologies" | Greek *agon* as party games: a rap battle judged by Homer, a debate hosted by Socrates, and a discus you throw with your phone, all on a matte paper-cut scene that paints your voice |
| **Technical Complexity**: "engineering depth that goes beyond basic implementation" | Streaming STT from the phone, voice levels at 20 Hz through SpacetimeDB to Metal shaders on the arena, battle logic in server-side reducers, a deterministic stress scanner feeding a Claude judge under 3 s, multiple events from one engine config, Core Motion discus physics, the haptic beat |

## Spread-thin guard (GTM watchdog rule)

The new frame raises the ceiling on Most Creative, Hacker's Choice and Meta. It also invites the one critique the organizers warned about: "a project spread thin with too many features." So:

- **At least 80% of the 2 minutes is the poetry battle.** The other events get one line and a tile.
- **An event that isn't solid stays a locked tile.** A locked tile reads as a roadmap; a broken event reads as spread thin.
- If neither debate nor discus passes the checkpoint, the frame still holds: "Every party game starts with one great event. Ours is a poetry battle."

## Booth pitches (Saturday afternoon, 30 seconds each, phone in hand)

Goal: every sponsor judge has played Homer before Sunday. Open the app first and talk second.

**Spacetime** (Tyler Cloutier, Julien)
> "MeNIN is ancient Greek party games, and SpacetimeDB *is* the arena. Every event runs on one shared state: turn order, scoring and the winner in reducers. Each phone streams its voice at about twenty hertz so the arena's scene moves with whoever's speaking. The client is Swift on iPhone. Want to take a turn?"
Ask them: "What would make this a top-three Spacetime project for you?" Write down the answer and build toward it.

**Cartesia** (Grant Timmerman, Vikram, Kelly Arifin)
> "Voice is the whole game. Your words hit a beat lane as you say them, through Cartesia streaming STT. Homer answers in about three seconds as a title-fight MC, through Cartesia TTS, and whispers you a line when you freeze. [If debate shipped:] Socrates hosts the debate in a completely different voice: dry, patient, always asking."
Ask them: "How many winners are there, and what does great 'impact and responsibility' look like to you?"

**Anthropic** (Arinze Obiezue)
> "For slam poets between open mics. Claude judges every verse with a stress count from our scanner, so it never guesses the beat, and every score shows its quote. The app is also being built by a team of Claude Code sessions."
Keep the Anthropic story on the poets and on training (Bard mode). The party frame is why people come back, not the public-benefit claim.
Ask them: "Is our community narrow enough?"

**Meta** (find them at their workshop)
> "Party games for one room: one screen, everyone's phone is a controller. The main event is a poetry battle where the judge scores how well you answer the person before you, and at the end Homer stitches everyone's lines into one song."

**Figma** (Booth #35, TK Dang)
> "One designer and six Claude Code sessions, with Figma as the source of truth between them. We're keeping a stage log, including what broke, like the web-to-iOS pivot."
Ask them: "What makes a stage log win?"

## Q&A bank

Answer in one breath, then stop.

| They ask | We say |
| --- | --- |
| What does MeNIN mean? | "*Mēnin*, rage. It's the first word of the Iliad. Homer started Western literature with a fight." |
| Why poetry in a games app? | "The Greeks didn't separate them. At the Panathenaic Games, poets competed next to the athletes." |
| How is the AI judge not arbitrary? | "Beat isn't the AI's opinion; a stress scanner counts it. Range comes from the emotion engine. Claude scores Craft, Image and Answer with your hand and the verse you answered in front of it. You always see all five scores and the line it quoted." |
| Why several events? | "One engine. Each event is a config: who hosts, what's in your hand, how it's judged, beat on or off. Poetry came first; the debate took [hours] on the same engine." *(Only if debate shipped.)* |
| Isn't this just a game? | "The games are why you come back. Bard mode is where you get good. Five first-timers went from [X] to [Y] in one lesson." |
| Does it work in this noise? | "Headset mic, push-to-talk, captions, and the transcript is always on screen so you can see what Homer heard." *(Only say it if Saturday's hall test passed.)* |
| Isn't this just for poets? | "It's for anyone who has to speak in front of people. Poets are where we start, because they already practice this and have nowhere to do it." |
| Why Homer and not Shakespeare? | "Shakespeare wrote. Homer improvised. Improvising is the skill." |
| What's AI and what isn't? | "Deterministic: the beat count, the scoring math and the discus physics. Claude: the judgment, the coaching, Homer's and Socrates' lines and the stitched song. Cartesia: ears and voice. Nothing is mocked." |
| Why iPhone only? | "Your phone is the mic, the controller and the discus, and the beat lives in your hand through haptics. That needs native. The same app runs the arena on an iPad or a Mac." |
| What happens Monday? | "Tap the TestFlight link on your iPhone. No account, open a room, play." *(Only if the public link is approved. Otherwise: "TestFlight now, App Store next.")* |
| How fast is the verdict? | "About three seconds from your last word to Homer's voice." *(Quote the measured p50, not a guess.)* |
| What did you cut? | "Ranks, spectators, and every event that wasn't solid. Those are the locked tiles." |
| What's hardest? | "Voices bleeding into each other's mics in one room. We moved the beat into your palm." |
| What about bad content? | "Homer won't speak it: the turn scores zero and nothing gets quoted. Names are filtered before he says them." |

## Video (2:00; covers Cartesia's "2-minute, demo-first" and Figma's 3-minute cap)

Open with the moment, not a title card. Captions burned in. Real footage, nothing mocked. No Nintendo or Activision names on screen.

| Time | Shot |
| --- | --- |
| 0:00–0:10 | Cold open: the poet, headset on, spits two lines. The arena scene floods with color, the beat lane fills, a card flips. No narration. |
| 0:10–0:15 | Title card: **μῆνιν · MeNIN**, with "Rage. The first word of Western literature." underneath, then the event menu: poetry battle lit, the other shipped events lit, the rest locked. |
| 0:15–0:50 | The poetry battle on the arena, intercut with the phones: the private hand, the haptic beat (close-up), the freeze rescue glow and whisper. Homer's verdict lands with five scores. |
| 0:50–1:00 | The round verdict: the best line carved in gold. |
| 1:00–1:15 | Bard lesson 1: a first-timer misses, gets one note from Homer, lands it. Show the before and after Beat number. |
| 1:15–1:25 | *Only if shipped:* 5 s of Socrates hosting the debate (a different voice), then 5 s of a discus throw: a phone swing, the arena throw, Homer calls the distance. |
| 1:25–1:40 | How it's built, in one frame: iPhone → Cartesia STT → SpacetimeDB → arena Metal scene, and the Claude judge with the scanner. One engine, events as configs. Say "nothing mocked". |
| 1:40–1:55 | The stitched song over the battle's colors, each line with its poet's name. |
| 1:55–2:00 | The champion and the TestFlight link or domain. |

Thumbnail / Devpost cover: one arena frame with the carved gold line over matte color fields. No neon, no glow.

## Hacker's Choice ground game (Saturday night)

- **Discus is the hook** if it ships. Anyone can swing a phone, with no poetry nerves. "Throw the discus, then stay for the battle."
- Battles at our table on our iPhones, plus the arena. Say "Two minutes, five phrases in your hand, you can't fail" and let the hand do the work.
- **Karaoke** (Sat night) is a room full of people holding mics in a performing mood. Bring the arena and two phones.
- Film 15-second clips (a discus throw, the scene flooding during a verse) and post them tagging the sponsors.
- Never block the build for this. One person, one hour.
