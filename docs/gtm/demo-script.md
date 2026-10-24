# The 2-minute table demo

Setup: iPhones plus a Mac arena, at a shared table with 3 judges in a noisy hall. Timings come from `docs/ux-flow.md`: about 80 BPM, so one bar is about 3 s and one line is one bar. A verdict starts about 3 s after the turn ends.

**The job:** in 120 seconds, the judges see two people battle in verse, the room paint their voices, Homer judge them like a title-fight MC, and the whole battle get stitched into one song. History gets one line. The battle gets the rest.

## Cast

| Who | Role | Device |
| --- | --- | --- |
| **Poet** | Poet 1. Opens the battle and tells the community story. | iPhone with a wired headset mic |
| **Matus** | Host and Poet 2. Does the freeze-rescue moment and the how-it-works line. | iPhone with a wired headset mic |
| **Operator** (MechE) | Runs the arena Mac, resets between judges, keeps the backup video one click away, watches the latency HUD. Says nothing. | Mac (arena) |

## Before a judge reaches the table (not part of the 2 minutes)

- The arena Mac runs Homer in arena mode, full screen, mirrored to the largest screen we have. The lobby is open: the room code is showing and both poets have joined under their epithets.
- **Demo config is loaded.** It's the same live engine with a shorter battle, nothing mocked:
  - 1 round, 2 poets, 2 lines per turn
  - The step-up wait is skipped, so the poet is ready automatically
  - Scores count up while Homer speaks the verdict, instead of after it
  - The per-turn best-line re-read and the hoard step are off; the best line is carved once, at round end
  - The tally step is skipped
  - The stitched song is capped at 4 lines
  - The crown is one line with no compliments
- Three theme cards are on screen for the judge to pick from. The poets have rehearsed all three: "A ship that never came home", "The night before the deadline", "A city that never sleeps".
- Headsets are on, and push-to-talk is checked on both phones. Captions are on for everything Homer says, because judges in that hall won't hear every word.
- Ethernet is plugged into the Mac and the wired speaker is on. The backup video is open in a second window. Phones are on charge until the judge arrives.
- Native iOS needs no audio-unlock tap, so the browser autoplay constraint from ux-flow doesn't apply.

## The script

| Time | Who | What happens on the arena | What's said |
| --- | --- | --- | --- |
| **0:00–0:08** | Matus | The scene idles, matte color fields drifting. | "Homer never memorized the Iliad. He improvised it, with formulas: phrases that already fit the beat. Same trick as freestyle. So we built **Guitar Hero meets a rap battle, taught by Homer.**" |
| **0:08–0:12** | Judge | Three theme cards. | Matus: "Pick our battleground." The judge points and the operator taps. *(This is the 10-second judge moment: low pressure, and it proves nothing is pre-scripted. Cut it first if we're over time.)* |
| **0:12–0:16** | Homer | The theme lands and both phones get their private hands. | Homer, MC voice: "A ship that never came home. **Salt-Tongued** Priya, the sea is yours." *(The epithet is whatever the poet forged in lesson 3; the name here is a placeholder.)* |
| **0:16–0:31** | Poet | **Turn 1: count-in, then 2 lines with a rest bar after each (15 s).** The beat lane fills as stresses hit pulses and land like drum strikes. The poet's phone pulses the beat in their hand. A formula card flips onto the arena when it's spoken. The scene floods with color as the feeling turns. | The poet spits. Prepared bones, live delivery. |
| **0:31–0:37** | Homer | "Hah." at 0.3 s. The verdict starts by about 3 s, with five axes counting up and the best line quoted. | Homer: one knockout line, e.g. "Strong bones. That second line drowned the whole fleet." |
| **0:37–0:55** | Matus | **Turn 2 (about 18 s), with a planned freeze.** Matus starts line 1, then stops. After about 1 s his hand glows on the phone and on the arena, and Homer whispers a formula that fits. Matus grabs it, finishes the line, and lands line 2. The card flips. | Matus spits. The freeze is staged, but the rescue is the real feature running live. |
| **0:55–1:01** | Homer | Verdict and scores. | Homer roasts gently: "Saved by the Muse. Your second line earned the rescue back." |
| **1:01–1:08** | Homer | **Round verdict.** The best line of the round is carved in gold across the arena and stays there. The scoreboard sorts. | "The round goes to the line that sank the ship:" and Homer reads it. |
| **1:08–1:26** | Matus | The carved line stays up. The scene idles under it. | "Nothing here is mocked. **SpacetimeDB** runs the hall: turns, scores, and our voices streaming from each phone to the arena about twenty times a second, all in one shared state. **Cartesia** hears every word and gives Homer his voice, and the verdict lands about three seconds after the last syllable. **Claude** judges with the beat already counted by our stress scanner, so every score shows its reasons." |
| **1:26–1:38** | Poet | Same. | "I do slam. Open mics are once a week, and in between you practice alone in your room. Homer is a stage every night that hears your beat. Tonight we sat five people who'd never freestyled in front of lesson one. Their beat went from **[X] to [Y]** in four minutes." *(Use the real number from Saturday's first-timer study. If there's no number, drop the last two sentences.)* |
| **1:38–1:41** | Homer | Totals roll. | "Before I crown anyone, listen." |
| **1:41–1:55** | Homer | **The stitched song: 4 lines over the beat.** Each line appears with its poet's name, the gold line returns, and the scene replays each line's colors. *(Generation starts the moment Matus's transcript is final, about 0:52, so it has about 45 s of headroom.)* | Homer performs the battle back as one poem. A rhapsode was a song-stitcher. Let the line land; don't explain it. |
| **1:55–2:00** | Homer, Matus | The champion and the room code. | Homer: "Salt-Tongued takes the hall." Matus: "That's Homer. Want to battle us?" |

**Total: 2:00.** If a judge stays, the next move is "Want to take a turn?" Hand them Matus's phone and headset, deal a fresh hand, and run a rematch. That's where Hacker's Choice gets won.

## If we run long (cut in this order)

1. Drop the judge's theme pick and preload the theme: −4 s
2. Drop the rest bars in both turns: −12 s. It's the cheapest real saving, but it costs some of the feel.
3. Cut the round verdict; the carved line appears in the finale instead: −7 s
4. Cut the how-it-works line to the three names alone ("SpacetimeDB runs the hall, Cartesia gives Homer his voice, Claude judges"): −8 s

Never cut the turns, Homer's spoken verdict, or the stitched song. Those three are the demo.

## When the judge is a sponsor

Swap the 1:08–1:26 line for theirs. Same length, same spot.

| Judge from | Say this instead |
| --- | --- |
| **Spacetime** | "SpacetimeDB is the hall. Rooms, turn order, scoring and the winner all run in reducers, server-side. Each phone streams its voice levels at about twenty hertz into one table, and the arena subscribes, so the scene moves with whoever's speaking. We wrote zero sync code, and the iPhone client is Swift." |
| **Cartesia** | "Cartesia is both ears and voice. Streaming speech-to-text puts every word on the beat lane as you say it, and Homer's voice is Cartesia text-to-speech. The pre-rendered 'Hah' covers the first beat, so the verdict starts about three seconds after your last word. Captions run under all of it, for accessibility and for halls like this one." |
| **Anthropic** | "Claude is the judge and the coach. It gets your hand, the verse you're answering, and a beat count from a deterministic scanner, so it never guesses the beat. Every verdict shows five scores and the line it's quoting. Where it can go wrong: taste is contestable, so you see exactly why you lost." |
| **Meta** | "Two strangers, answering each other in verse, in one room. The judge literally scores how well you answer the person before you. And at the end, Homer stitches everyone's lines into one song. You leave having made something together." |
| **Figma** | "Every screen and all eight emotion palettes started in Figma, and the agents building the app read the Figma file directly. The stage log in our Devpost shows each handoff, including what broke." |

## Fallbacks, decided now so nobody improvises

| What breaks | Do this | Don't |
| --- | --- | --- |
| A phone won't join, or SpacetimeDB wedges | Switch to **Practice Spar** on one device: the poet against Homer. The turn, verdict and scene are the same. | Debug at the table |
| STT is garbage (noise) | Push-to-talk, headset closer to the mouth, one retry. If it fails again, play the backup video. | Retry three times |
| No verdict at 4 s | Homer's pre-recorded stall line plays ("The Muse is still counting.") and Beat and Range show. Keep talking. | Fill silence with apologies |
| No verdict at 10 s | Beat and Range only, then move on. Never show a canned verdict; that would be a mocked response. | Fake it |
| Network down | The ethernet should prevent this. If not, play the backup video and run Practice where it works offline. | Use a hotspot (banned at the venue) |
| The judge has 60 seconds, not 120 | Run only 0:00–0:37 (one turn and one verdict), then jump to the stitched song from a prior battle. That's still live: it's the last real battle's song. | Rush the whole script |

## Rehearsal

- Run it **three times back to back**, because there are 3 judges and they may come one at a time. The operator resets with **Rematch** (same poets, new theme) in under 10 seconds.
- Do one full rehearsal **in the hall at peak noise on Saturday night**, at demo volume, to settle the beat-bleed question (ux-flow risk options A to E). With native iOS, option D (the haptic beat in your hand) works on iPhone, which mobile Safari couldn't do. Duck the arena's beat during speaking bars (option B), so the drum fills the count-in and rests and the beat lives in your palm while you speak.
- Time every run. If p50 from turn end to first verdict audio is over 3.5 s, tell the leader before feature freeze.
