# Pitch kit

The table demo is in [demo-script.md](demo-script.md). This file holds everything around it: the lines, the booth pitches, the Q&A and the video.

**Tone (Matus):** professional and badass, never academic. History gets **one sharp line**, then straight to the battle. The battle is the loudest part. Say "iPhone", never "anyone".

## The lines

| Length | Line |
| --- | --- |
| 5 s | **Guitar Hero meets a rap battle, taught by Homer.** |
| 15 s | Homer never memorized the Iliad. He improvised it, with formulas: phrases that already fit the beat. We built the formulas and made it a battle. You speak, the room paints your voice, and Homer judges you like a title fight. |
| History, one line only | "In the 1930s, Milman Parry recorded bards in the Balkans improvising epics thousands of lines long, same method. A rhapsode was a song-stitcher, so at the end Homer stitches your battle into one song." |
| Close | "That's Homer. Want to battle us?" |

Don't say: "oral-formulaic composition", "scansion", "meter", "iamb", "pedagogy", "learning platform", "AI tutor", or anything else that sounds like a lecture.

## How we hit the main judging criteria

The criteria are from #0-ask-directors. Every claim below has to be true by Sunday.

| Criterion (their words) | Our proof at the table |
| --- | --- |
| **Application**: "who they help, what problem they solve, and why people would actually use them" | Slam and spoken-word poets practice alone between weekly open mics. Homer gives them a stage every night that hears your beat. **Saturday's first-timer number** goes here. |
| **Intentionality**: "Every design choice should feel purposeful" | One idea carried everywhere: the formula. It's in your hand, it rescues you when you freeze, it's how you're judged, and Homer stitches the battle with it. Matte paper-cut look, Homer as an MC, no menus. |
| **Functionality**: "live demo that runs smoothly... clear, meaningful video demo on devpost" | Live battle on iPhones and the arena, a verdict in about 3 s, a rehearsed fallback to Practice, a 2-minute video |
| **Creativity**: "unexpected combinations of ideas or technologies" | A 2,800-year-old improv technique, a rap battle, Jackbox-style phones, and a scene that paints your voice |
| **Technical Complexity**: "engineering depth that goes beyond basic implementation" | Streaming STT from the phone, voice levels at 20 Hz through SpacetimeDB to Metal shaders on the arena, battle logic in server-side reducers, a deterministic stress scanner feeding a Claude judge under 3 s, the stitched-song generation, the haptic beat |

## Booth pitches (Saturday afternoon, 30 seconds each, phone in hand)

Goal: every sponsor judge has played Homer before Sunday. Open the app first and talk second.

**Spacetime** (Tyler Cloutier, Julien)
> "We built a Jackbox-style poetry battle where SpacetimeDB *is* the hall. Turn order, scoring and the winner run in reducers, and each phone streams its voice at about twenty hertz so the arena's scene moves with whoever's speaking. Our client is Swift on iPhone. Want to take a turn?"
Ask them: "What would make this a top-three Spacetime project for you?" Write down the answer and build toward it.

**Cartesia** (Grant Timmerman, Vikram, Kelly Arifin)
> "Homer is voice-first. Your words hit a beat lane as you say them, through Cartesia streaming STT, and Homer answers in about three seconds as an MC, through Cartesia TTS. He even whispers you a line when you freeze."
Ask them: "How many winners are there, and what does great 'impact and responsibility' look like to you?"

**Anthropic** (Arinze Obiezue)
> "For slam poets between open mics. Claude judges every verse with a stress count from our scanner, so it never guesses the beat, and every score shows its quote. The app is also being built by a team of Claude Code sessions."
Ask them: "Is our community narrow enough?"

**Meta** (find them at their workshop)
> "A room of strangers answering each other in verse. The judge scores how well you answer the person before you, and the finale stitches everyone's lines into one song."

**Figma** (Booth #35, TK Dang)
> "One designer and six Claude Code sessions, with Figma as the source of truth between them. We're keeping a stage log, including what broke."
Ask them: "What makes a stage log win?"

## Q&A bank

Answer in one breath, then stop.

| They ask | We say |
| --- | --- |
| How is the AI judge not arbitrary? | "Beat isn't the AI's opinion; a stress scanner counts it. Range comes from the emotion engine. Claude scores Craft, Image and Answer with your hand and the verse you answered in front of it. You always see all five scores and the line it quoted." |
| Does it work in this noise? | "Headset mic, push-to-talk, captions, and the transcript is always on screen so you can see what Homer heard." *(Only say it if Saturday's hall test passed.)* |
| Isn't this just for poets? | "It's for anyone who has to speak in front of people. Poets are where we start, because they already practice this and have nowhere to do it." |
| Why Homer and not Shakespeare? | "Shakespeare wrote. Homer improvised. Improvising is the skill." |
| What's AI and what isn't? | "Deterministic: the beat count, the timing and the scoring math. Claude: the judgment, the coaching, Homer's lines and the stitched song. Cartesia: ears and voice. Nothing is mocked." |
| Why iPhone only? | "Your phone is the mic and the beat lives in your hand through haptics, which needs native. One app runs the arena too, on a Mac or an iPad." |
| What happens Monday? | "Tap the TestFlight link on your iPhone. No account, open a room, battle." *(Only if the public link is approved. Otherwise: "TestFlight now, App Store next.")* |
| How fast is the verdict? | "About three seconds from your last word to Homer's voice." *(Quote the measured p50, not a guess.)* |
| How do you know it works? | "We put five first-timers through lesson one last night. Their beat went from [X] to [Y]." |
| What did you cut? | "Ranks and spectators. We put everything into the battle." |
| What's hardest? | "Voices bleeding into each other's mics in one room. We moved the beat into your palm." |
| What about bad content? | "Homer won't speak it: the turn scores zero and nothing gets quoted. Names are filtered before he says them." |

## Video (2:00; covers Cartesia's "2-minute, demo-first" and Figma's 3-minute cap)

Open with the moment, not a title card. Captions burned in. Real footage, nothing mocked.

| Time | Shot |
| --- | --- |
| 0:00–0:10 | Cold open: the poet, headset on, spits two lines. The arena scene floods with color, the beat lane fills, a card flips. No narration. |
| 0:10–0:15 | Title: **Homer. Guitar Hero meets a rap battle, taught by Homer.** |
| 0:15–0:50 | The battle on the arena, intercut with the phones: the private hand, the haptic beat (close-up), the freeze rescue glow and whisper. Homer's verdict lands with five scores. |
| 0:50–1:05 | The round verdict: the best line carved in gold. |
| 1:05–1:25 | Bard lesson 1: a first-timer misses, gets one note from Homer, lands it. Show the before and after Beat number. |
| 1:25–1:40 | How it's built, in one frame: iPhone → Cartesia STT → SpacetimeDB → arena Metal scene, and the Claude judge with the scanner. Say "nothing mocked". |
| 1:40–1:55 | The stitched song over the battle's colors, each line with its poet's name. |
| 1:55–2:00 | The champion and the TestFlight link or domain. |

Thumbnail / Devpost cover: one arena frame with the carved gold line over matte color fields. No neon, no glow.

## Hacker's Choice ground game (Saturday night)

- Battles at our table on our iPhones, plus the arena Mac. Say "Two minutes, five phrases in your hand, you can't fail" and let the hand do the work.
- **Karaoke** (Sat night) is a room full of people holding mics in a performing mood. Bring the arena and two phones.
- Film 15-second clips of the scene reacting and post them tagging the sponsors.
- Never block the build for this. One person, one hour.
