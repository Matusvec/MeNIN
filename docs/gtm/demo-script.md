# The 2-minute table demo

Setup: iPhones plus a Mac arena, at a shared table with 3 judges in a noisy hall. Timings come from `docs/ux-flow.md`: about 80 BPM, so one bar is about 3 s and one line is one bar. A verdict starts about 3 s after the turn ends.

**The job:** in 120 seconds, the judges see two people battle in verse, the room paint their voices, Homer judge them like a title-fight MC, and the whole battle get stitched into one song. History gets one line. The battle gets the rest.

## Cast

| Who | Role | Device |
| --- | --- | --- |
| **Poet** | Poet 1. Opens the battle and tells the community story. | iPhone with a wired headset mic |
| **Matus** | Host and Poet 2. Does the freeze-rescue moment and the how-it-works line. | iPhone with a wired headset mic |
| **Operator** (MechE) | Runs the arena Mac from beside it, resets between judges, keeps the backup video one click away, watches the latency HUD. Holds iPhone C, the spare. Says nothing. | Mac (arena), plus iPhone C |

## Before a judge reaches the table (not part of the 2 minutes)

- The arena Mac runs MeNIN in arena mode, full screen, **with its display turned to face the judges** (we have no external screen). The lobby is open: the room code is showing and both poets have joined under their epithets. A backup room is already created on the Mac, and its code is taped to the back of each phone.
- **Demo config is loaded.** It's the same live engine with a shorter battle, nothing mocked:
  - 1 round, 2 poets, 2 lines per turn
  - The step-up wait is skipped, so the poet is ready automatically
  - Scores count up while Homer speaks the verdict, instead of after it
  - The per-turn best-line re-read and the hoard step are off; the best line is carved once, at round end
  - The tally step is skipped
  - The stitched song is capped at 4 lines
  - The crown is one line with no compliments
- Three theme cards are on screen for the judge to pick from. The poets have rehearsed all three: "A ship that never came home", "The night before the deadline", "A city that never sleeps".
- Wired EarPods are in, and push-to-talk is checked on both phones. Captions are on for everything Homer says, because judges in that hall won't hear every word.
- Ethernet is plugged into the Mac (through the USB-C adapter), and the speaker is wired into the Mac's headphone jack. The backup video is open in a second window and saved on all three phones. Phones are on power banks until the judge arrives. Full logistics are in [run-sheet.md](run-sheet.md).
- Native iOS needs no audio-unlock tap, so the browser autoplay constraint from ux-flow doesn't apply.

## The script

| Time | Who | What happens on the arena | What's said |
| --- | --- | --- | --- |
| **0:00–0:04** | Homer | The operator triggers **the first-open line** (demo mode: *replay opening*). The scene stirs to his voice, with captions. | Homer: "The first word of Western literature is *mēnin*. Rage." *(This is SPEC "First open", P12. The TTS must say "MAY-nin", so check the pronunciation.)* |
| **0:04–0:14** | Matus | **The event menu** over the idling scene: the poetry battle lit, other shipped events lit, the rest locked tiles. On "party games", Matus opens the poetry battle. | "AI can write anything now. It can't stand up and move a room for you. The Greeks trained that like a sport. **MeNIN** is their games: party games for your voice, with your iPhone as the controller." *(Matus's thesis, about 10 s. Say it like a fact, not a lecture. It takes the theme-pick slot, so the theme is preloaded. If the judge seems eager, keep the theme pick and drop "The Greeks trained that like a sport".)* |
| | | *(Theme pick: off by default now. The opener took its 4 s. Put it back only by trimming the opener, as noted above.)* | |
| **0:14–0:18** | Homer | The theme lands and both phones get their private hands. | Homer, MC voice: "A ship that never came home. **Salt-Tongued** Priya, the sea is yours." *(The epithet is whatever the poet forged in lesson 3; the name here is a placeholder.)* |
| **0:18–0:33** | Poet | **Turn 1: count-in, then 2 lines with a rest bar after each (15 s).** The beat lane fills as stresses hit pulses and land like drum strikes. The poet's phone pulses the beat in their hand. A formula card flips onto the arena when it's spoken. The scene moves with the poet's voice, and its color fields shift as the feeling turns. | The poet spits. Prepared bones, live delivery. *(The hand gets explained here, in the moment: "Five phrases that already fit the beat. That's how Homer improvised.")* |
| **0:33–0:39** | Homer | "Hah." at 0.3 s. The verdict starts by about 3 s, with five axes counting up and the best line quoted. | Homer: one knockout line, e.g. "Strong bones. That second line drowned the whole fleet." |
| **0:39–0:57** | Matus | **Turn 2 (about 18 s), with a planned freeze.** Matus starts line 1, then stops. After about 1 s his hand comes forward on the phone, one card is raised on the arena, and Homer whispers a formula that fits. Matus grabs it, finishes the line, and lands line 2. The card flips. | Matus spits. The freeze is staged, but the rescue is the real feature running live. |
| **0:57–1:03** | Homer | Verdict and scores. | Homer roasts gently: "Saved by the Muse. Your second line earned the rescue back." |
| **1:03–1:10** | Homer | **Round verdict.** The best line of the round is carved in gold across the arena and stays there. The scoreboard sorts. | "The round goes to the line that sank the ship:" and Homer reads it. |
| **1:10–1:26** | Matus | The carved line stays up. The scene idles under it. | "Nothing here is mocked. **SpacetimeDB** runs the hall: turns, scores, and every phone's voice streaming to the arena twenty times a second. **Cartesia** hears every word through the drum, because we feed it your hand, and gives Homer his voice. And Homer is a live agent on **Claude**: he judges, coaches and writes the song, while our stress scanner counts the beat." *(About 17 s. This is the pitch's one "agent": most Cal Hacks judges are agent engineers, and one said they're "most excited to see teams make agents do real work" (#1-introductions, Oct 19). Don't repeat it elsewhere in the 2 minutes. The judges just watched the 3-second verdict, so don't say it.)* |
| **1:26–1:38** | Poet | Same. | "I do slam in [the poet's scene]. Open mics are once a week, and in between you practice alone in your room. MeNIN is a stage every night that hears your beat. Last night, five people who'd never freestyled took lesson one. Their Beat score went from **[first] to [last]** out of 10, in about **[time]** minutes." *(Fill in the real numbers from Saturday's first-timer study, using one of pm's line options in `docs/study.md`. If fewer than three people landed, drop the time. If there's no number at all, drop the last two sentences.)* |
| **1:38–1:41** | Homer | Totals roll. | "Before I crown anyone, listen." |
| **1:41–1:55** | Homer | **The stitched song: 4 lines over the beat.** Each line appears with its poet's name, the gold line returns, and the scene replays each line's colors. *(Generation starts the moment Matus's transcript is final, about 0:54, so it has about 45 s of headroom.)* | Homer performs the battle back as one poem. A rhapsode was a song-stitcher. Let the line land; don't explain it. |
| **1:55–2:00** | Homer, Matus | The champion, the room code and the **champion sting** from the score. | Homer: "Salt-Tongued takes the hall." Matus: "**Most AI talks for you. Homer makes you talk.** That's MeNIN." *(The line judges repeat afterwards. The discus invitation moves to just after 2:00.)* |

**Total: 2:00.** The 2 minutes stay about 90% poetry battle. Other events get one sentence and a tile.

**Music (SPEC "Music"):** the original score plays on the menu, as each event's intro, under the discus throw and as the champion sting. It never plays under a speaking poet: during turns only the procedural beat plays, and the music ducks under Homer's voice. Set the score's level in the Saturday-night hall test along with the beat.

**After 2:00, if the judge stays (this is where Hacker's Choice gets won):**
- **If debate passed the Sat 8 PM check, Socrates goes first** (decided with leader). He's the thesis made literal: the art of moving people, hosted by the man who questioned Athens. Play 10–15 s of Socrates opening a debate, then offer the judge a side: "Want to argue with Socrates?" It's especially strong for Cartesia, since it's the second voice, and for Anthropic.
- **Then the invitation:** "Want to throw the discus?" (if it passed at 8 PM), or "Want to battle us?"
- **Discus (if it passed the Sat 8 PM check):** hand the judge Matus's iPhone. "Swing it like a discus, and lift your thumb to release. Keep hold of the phone." The arena shows the throw over its cue from the score, the fanfare hits, and Homer calls the distance. It takes about 10 seconds, needs zero skill, and gets a laugh.
  - **Safety:** the release is a thumb lift, never opening your hand. Use a phone with a grippy case, and only swing where there's arm room, away from the shared table's laptops.
- **Or a rematch:** hand them the phone and headset, deal a fresh hand, and run a battle against the poet.

## If we run long (cut in this order)

1. *(Already done: the opener took the theme pick's slot.)* Next, cut "The Greeks trained that like a sport" from the opener: −3 s
2. Drop the rest bars in both turns: −12 s. It's the cheapest real saving, but it costs some of the feel.
3. Cut the round verdict; the carved line appears in the finale instead: −7 s
4. Cut the how-it-works line to the three names alone ("SpacetimeDB runs the hall, Cartesia gives Homer his voice, Claude judges"): −8 s

Never cut the turns, Homer's spoken verdict, or the stitched song. Those three are the demo.

## When the judge is a sponsor

Swap the 1:10–1:26 line for theirs. Same length, same spot.

| Judge from | Say this instead |
| --- | --- |
| **Spacetime** | "SpacetimeDB is the hall. Rooms, turn order, scoring and the winner all run in reducers, server-side. Each phone streams its voice levels at about twenty hertz into one table, and the arena subscribes, so the scene moves with whoever's speaking. We wrote zero sync code, and the iPhone client is Swift." |
| **Cartesia** | "Cartesia is ears and voice. We feed your hand to the recognizer, so it hears the wine-dark sea through the drum: in our tests, three percent word error with the drum at full volume, twenty without. The final transcript lands seventy-five milliseconds after you stop, and Homer's voice starts in about a hundred." *(The beat lane runs on onsets detected on the phone, not on STT timestamps. Don't credit Cartesia for it.)* |
| **Anthropic** | "Claude is the judge and the coach. It gets your hand, the verse you're answering, and a beat count from a deterministic scanner, so it never guesses the beat. Every verdict shows five scores and the line it's quoting. Where it can go wrong: taste is contestable, so you see exactly why you lost." |
| **Meta** | "Two strangers, answering each other in verse, in one room. The judge literally scores how well you answer the person before you. And at the end, Homer stitches everyone's lines into one song. You leave having made something together." |
| **Figma** | "Every screen and all eight emotion palettes started in Figma, and the agents building the app read the Figma file directly. The stage log in our Devpost shows each handoff, including what broke." |

## Fallbacks, decided now so nobody improvises

| What breaks | Do this | Don't |
| --- | --- | --- |
| A phone won't join, or SpacetimeDB wedges | **Switch the Mac to the backup room**, and the poets rejoin with the taped code (about 15 s). If that fails too, switch to **Practice Spar** on one device: the poet against Homer, with the same turn, verdict and scene. | Debug at the table |
| The Mac dies | **iPhone C becomes the arena**, in arena mode and landscape, propped facing the judges. Small, but it's live. | Apologize for the screen size more than once |
| STT is garbage (noise) | Push-to-talk, headset closer to the mouth, one retry. If it fails again, play the backup video. | Retry three times |
| No verdict at 4 s | Homer's pre-recorded stall line plays ("The Muse is still counting.") and Beat and Range show. Keep talking. | Fill silence with apologies |
| No verdict at 10 s | Beat and Range only, then move on. Never show a canned verdict; that would be a mocked response. | Fake it |
| Network down | The ethernet should prevent this. If not, play the **backup video**. Practice isn't an offline fallback, since it still needs Claude and Cartesia. | Use a hotspot (banned at the venue by a Cal Hacks announcement) |
| The judge has 60 seconds, not 120 | Run only 0:00–0:39 (the opening, one turn and one verdict), then jump to the stitched song from a prior battle. That's still live: it's the last real battle's song. | Rush the whole script |

## Rehearsal

- Run it **three times back to back**, because there are 3 judges and they may come one at a time. The operator resets with **Rematch** (same poets, new theme) in under 10 seconds.
- Do one full rehearsal **in the hall at peak noise on Saturday night**, at demo volume. Beat bleed is decided in SPEC: duck the arena drum during speaking bars, and the speaker feels the beat as haptics (ux-flow options B + D). The test **confirms** that choice. If STT still picks up the drum or the room, the fallback is the stage-mic option (ux-flow option A).
- Time every run. If p50 from turn end to first verdict audio is over 3.5 s, tell the leader before feature freeze.
