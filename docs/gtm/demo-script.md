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
| **0:00–0:04** | Homer | The operator triggers **the first-open line** (demo mode: *replay opening*). The scene stirs to his voice, with captions. | Homer: "The first word of Western literature is *mēnin*. Rage." *(This is SPEC "First open", P12. The TTS must say "MAY-nin", so check the pronunciation.)* |
| **0:04–0:10** | Matus | **The event menu** over the idling scene: the poetry battle lit, other shipped events lit, the rest locked tiles. | "**MeNIN**. Ancient Greek party games, like Wii Sports, with your iPhone as the controller. The main event is a poetry battle, judged by Homer." *("Wii Sports" is a spoken comparison only and never appears on screen.)* |
| **0:10–0:14** | Judge | Matus opens the poetry battle, and three theme cards appear. | Matus: "Pick our battleground." The judge points and the operator taps. *(This is the 10-second judge moment: low pressure, and it proves nothing is pre-scripted. Cut it first if we're over time. If discus shipped, the judge's real moment is the throw after 2:00.)* |
| **0:14–0:18** | Homer | The theme lands and both phones get their private hands. | Homer, MC voice: "A ship that never came home. **Salt-Tongued** Priya, the sea is yours." *(The epithet is whatever the poet forged in lesson 3; the name here is a placeholder.)* |
| **0:18–0:33** | Poet | **Turn 1: count-in, then 2 lines with a rest bar after each (15 s).** The beat lane fills as stresses hit pulses and land like drum strikes. The poet's phone pulses the beat in their hand. A formula card flips onto the arena when it's spoken. The scene moves with the poet's voice, and its color fields shift as the feeling turns. | The poet spits. Prepared bones, live delivery. *(The hand gets explained here, in the moment: "Five phrases that already fit the beat. That's how Homer improvised.")* |
| **0:33–0:39** | Homer | "Hah." at 0.3 s. The verdict starts by about 3 s, with five axes counting up and the best line quoted. | Homer: one knockout line, e.g. "Strong bones. That second line drowned the whole fleet." |
| **0:39–0:57** | Matus | **Turn 2 (about 18 s), with a planned freeze.** Matus starts line 1, then stops. After about 1 s his hand comes forward on the phone, one card is raised on the arena, and Homer whispers a formula that fits. Matus grabs it, finishes the line, and lands line 2. The card flips. | Matus spits. The freeze is staged, but the rescue is the real feature running live. |
| **0:57–1:03** | Homer | Verdict and scores. | Homer roasts gently: "Saved by the Muse. Your second line earned the rescue back." |
| **1:03–1:10** | Homer | **Round verdict.** The best line of the round is carved in gold across the arena and stays there. The scoreboard sorts. | "The round goes to the line that sank the ship:" and Homer reads it. |
| **1:10–1:26** | Matus | The carved line stays up. The scene idles under it. | "Nothing here is mocked. **SpacetimeDB** runs the hall: turns, scores, and every phone's voice streaming to the arena twenty times a second. **Cartesia** hears every word and gives Homer his voice, about three seconds after your last syllable. **Claude** judges, with the beat already counted by our stress scanner." *(Trimmed to about 16 s to make room for Homer's opening.)* |
| **1:26–1:38** | Poet | Same. | "I do slam. Open mics are once a week, and in between you practice alone in your room. MeNIN is a stage every night that hears your beat. Tonight we sat five people who'd never freestyled in front of lesson one. Their beat went from **[X] to [Y]** in four minutes." *(Use the real number from Saturday's first-timer study. If there's no number, drop the last two sentences.)* |
| **1:38–1:41** | Homer | Totals roll. | "Before I crown anyone, listen." |
| **1:41–1:55** | Homer | **The stitched song: 4 lines over the beat.** Each line appears with its poet's name, the gold line returns, and the scene replays each line's colors. *(Generation starts the moment Matus's transcript is final, about 0:54, so it has about 45 s of headroom.)* | Homer performs the battle back as one poem. A rhapsode was a song-stitcher. Let the line land; don't explain it. |
| **1:55–2:00** | Homer, Matus | The champion and the room code. | Homer: "Salt-Tongued takes the hall." Matus: "That's MeNIN. Want to throw the discus?" *(If discus didn't ship: "Want to battle us?")* |

**Total: 2:00.** The 2 minutes stay about 90% poetry battle. Other events get one sentence and a tile.

**After 2:00, if the judge stays (this is where Hacker's Choice gets won):**
- **Discus (if shipped):** hand the judge Matus's iPhone. "Swing it like a discus, and lift your thumb to release. Keep hold of the phone." The arena shows the throw and Homer calls the distance. It takes about 10 seconds, needs zero skill, and gets a laugh.
  - **Safety:** the release is a thumb lift, never opening your hand. Use a phone with a grippy case, and only swing where there's arm room, away from the shared table's laptops.
- **Or a rematch:** hand them the phone and headset, deal a fresh hand, and run a battle against the poet.
- **Socrates (if shipped, and especially for a Cartesia judge):** play 10 seconds of Socrates opening a debate, so they hear the second voice.

## If we run long (cut in this order)

1. Drop the judge's theme pick and preload the theme: −4 s
2. Drop the rest bars in both turns: −12 s. It's the cheapest real saving, but it costs some of the feel.
3. Cut the round verdict; the carved line appears in the finale instead: −7 s
4. Cut the how-it-works line to the three names alone ("SpacetimeDB runs the hall, Cartesia gives Homer his voice, Claude judges"): −8 s

Never cut the turns, Homer's spoken verdict, or the stitched song. Those three are the demo.

## When the judge is a sponsor

Swap the 1:10–1:26 line for theirs. Same length, same spot.

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
| Network down | The ethernet should prevent this. If not, play the **backup video**. Practice isn't an offline fallback, since it still needs Claude and Cartesia. | Use a hotspot (banned at the venue by a Cal Hacks announcement) |
| The judge has 60 seconds, not 120 | Run only 0:00–0:39 (the opening, one turn and one verdict), then jump to the stitched song from a prior battle. That's still live: it's the last real battle's song. | Rush the whole script |

## Rehearsal

- Run it **three times back to back**, because there are 3 judges and they may come one at a time. The operator resets with **Rematch** (same poets, new theme) in under 10 seconds.
- Do one full rehearsal **in the hall at peak noise on Saturday night**, at demo volume. Beat bleed is decided in SPEC: duck the arena drum during speaking bars, and the speaker feels the beat as haptics (ux-flow options B + D). The test **confirms** that choice. If STT still picks up the drum or the room, the fallback is the stage-mic option (ux-flow option A).
- Time every run. If p50 from turn end to first verdict audio is over 3.5 s, tell the leader before feature freeze.
