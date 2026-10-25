# The 2-minute table demo

Setup: iPhones plus the website as the arena, full screen in a browser on the Mac, at a shared table with 3 judges in a noisy hall. Battles are free verse (SPEC 5fb8baf): no metronome, one SPEAK per turn and a 20 s window in demo mode, which the poet ends early with "I'm done". A verdict starts about 3 s after the turn ends.

**The job:** in 120 seconds, the judges see two people battle in verse, the room paint their voices, Homer judge them like a title-fight MC, and the whole battle get stitched into one song. History gets one line. The battle gets the rest.

## Cast

| Who | Role | Device |
| --- | --- | --- |
| **Poet** | Poet 1. Opens the battle and tells the community story. | iPhone with a wired headset mic |
| **Matus** | Host and Poet 2. Does the freeze-rescue moment and the how-it-works line. | iPhone with a wired headset mic |
| **Operator** (MechE) | Runs the arena (the website on the Mac) from beside it, resets between judges, keeps the backup video one click away, watches the latency HUD. Holds iPhone C, the spare. Says nothing. | Mac (arena), plus iPhone C |

## Before a judge reaches the table (not part of the 2 minutes)

- The Mac runs **the website, full screen in a browser**, **with its display turned to face the judges** (we have no external screen). SPEC: the website is the only arena people see. The lobby is open: the room code is showing and both poets have joined.
- **Open https://play.206.189.237.157.sslip.io/homer** (not "/", which is now the Poets' Hall landing page), **click "Host a battle", then "Open the hall: Poetry battle", and check Homer speaks.** That click is also what lets the browser play sound; after a reload, it's "Host a battle" → "Resume [code]". Check it before every judge.
- **Demo config is loaded.** It's the same live engine with a shorter battle, nothing mocked:
  - 1 round, 2 poets, a 20-second free-verse window per turn with a countdown ring (SPEC 69c5135); "I'm done" ends it early
  - The step-up wait is skipped, so the poet is ready automatically
  - Scores count up while Homer speaks the verdict, instead of after it
  - The per-turn best-line re-read and the hoard step are off; the best line is carved once, at round end
  - The tally step is skipped
  - The stitched song is capped at 4 lines
  - The crown is one line with no compliments
- **Nothing is preloaded, and nothing fixed is left to rehearse** (SPEC 7866476). Homer writes a fresh theme every round, six words or fewer, never one of the last twenty. **Fresh theme by default; the operator can switch on the 3 judge cards** (leader, Sat ~4:15 PM). The demo preset has theme choice off, so Homer coins a fresh Homeric theme each round. With theme choice switched on, the arena shows three fixed cards from `/themes?demo=true`: "A ship that never came home", "The night before the battle" and "The war between two brothers". The written themes are only a fallback. Each poet gets a fresh epithet Homer coins for this battle, never one of their last five. So **the poets rehearse improvising on themes they haven't seen**, not set pieces. [demo-hands.md](demo-hands.md) no longer works as a rehearsal plan.
- **Homer calls each poet up** (ux-flow P21 and P21b). He writes each theme and its call in one go, so the call is new every time too. The pattern for the first poet: **"[theme]. [Name], [epithet]. [Homer's call]."** An example, not a promise: "The ship that left without you. Priya, of the bronze spear. Call it back." Themes and epithets come only from Homer's world (SPEC 961bc37): nothing invented after the Bronze Age, though the feeling can be modern. To Matus, every time: **"Matus. Answer that."** That one is fixed.
- Wired EarPods are in. The mic is hands-free (SPEC 971fda0): it opens with a haptic thump when your turn goes live, and "I'm done" ends it early. Check both phones pick up. Captions are on for everything Homer says, because judges in that hall won't hear every word.
- Ethernet is plugged into the Mac (through the USB-C adapter), and the speaker is wired into the Mac's headphone jack. The backup video is open in a second window and saved on all three phones. Phones are on power banks until the judge arrives. Full logistics are in [run-sheet.md](run-sheet.md).

## The script

| Time | Who | What happens on the arena | What's said |
| --- | --- | --- | --- |
| **0:00–0:04** | Homer | The operator triggers **the first-open line** (demo mode: *replay opening*). The scene stirs to his voice, with captions. | Homer: "The first word of Western literature is *mēnin*. Rage." *(This is SPEC "First open", P12. The TTS must say "MAY-nin", so check the pronunciation.)* |
| **0:04–0:14** | Matus | **The event menu** over the idling scene: the poetry battle lit, other shipped events lit, the rest locked tiles. On "party games", Matus opens the poetry battle. | "AI can write anything now. It can't stand up and move a room for you. The Greeks trained that like a sport. **MeNIN** is their games: party games for your voice, with your iPhone as the controller." *(Matus's thesis, about 10 s. Say it like a fact, not a lecture. It takes the theme-pick slot, so Homer announces his fresh theme with no pick. If the judge seems eager, keep the theme pick and drop "The Greeks trained that like a sport".)* |
| | | *(Theme pick: off by default now. The opener took its 4 s. Put it back only by trimming the opener, as noted above.)* | |
| **0:14–0:18** | Homer | The fresh theme lands, and each phone shows its three phrases. | Homer, MC voice: **"[theme]. [Name], [epithet]. [Homer's call]."** For example: "The ship that left without you. Priya, of the bronze spear. Call it back." *(Every part is live: Homer writes the theme and the call, and coins the epithet for this battle. The count-in waits until Homer finishes.)* |
| **0:18–0:33** | Poet | **Turn 1: 3, 2, 1 with a haptic tick, then one SPEAK fills the phone and the arena in the poet's color for the whole verse. Free verse, no metronome: one 20 s window with a countdown ring, and the poet ends it with "I'm done" at about 15 s.** Their words show live on the arena. A phrase that's used pops "+Craft", and its card flips onto the arena (P8). The scene moves with the poet's voice, and its color fields shift as the feeling turns. | The poet spits, improvising on a theme they've never seen. *(Homer's phrases get explained here, in the moment: "Homer's phrases: three stock phrases that fit the theme. Use one and it scores Craft. That's how Homer improvised.")* |
| **0:33–0:39** | Homer | "Hah." at 0.3 s. The verdict starts by about 3 s, with three scores (Image, Answer, Craft) counting up to a total out of 100, and the best line quoted. **Scores are honest and anchored: a typical verse lands at 20 to 45 out of 100.** Never react to a 30 as a failure; it's a good verse. If a judge asks: "Homer's a hard judge. A 9 is a line you'd quote tomorrow." | Homer: one knockout line, live, e.g. "Strong bones. That second line hit like a hammer." |
| **0:39–0:57** | Matus | **Turn 2 (about 18 s), with a planned freeze.** Matus says **at least one full line (over 3 s)**, then stops and **holds the silence for about 3 s**, until the whisper. After about two and a half seconds of silence (SPEC 8d6afad; never in the first 3 s after SPEAK, at most twice a turn), Homer's phrases come forward on his phone, the one that fits is raised on the arena, and Homer whispers it. Matus uses it to finish the line ("+Craft"), lands one more, and says "I'm done". The card flips. | Homer: "Matus. Answer that." *(About 1.5 s. It's new, so time it in rehearsal. If the run goes long, the first cut in "If we run long" pays for it.)* Then Matus spits. The freeze is staged, but the rescue is the real feature running live. |
| **0:57–1:03** | Homer | Verdict and scores. | Homer roasts gently: "Saved by the Muse. Your second line earned the rescue back." |
| **1:03–1:10** | Homer | **Round verdict.** The best line of the round is carved in gold across the arena and stays there. The scoreboard sorts. | Homer gives the round and reads its best line. *(Live, so don't script his words.)* |
| **1:10–1:26** | Matus | The carved line stays up. The scene idles under it. | "Nothing here is mocked. **SpacetimeDB** runs the hall: turns, scores, and the speaker's voice streaming to the arena twenty times a second. **Cartesia** hears every word in this hall, because we feed it Homer's phrases, and gives Homer his voice. And Homer is a live agent on **Claude**: he judges, coaches and writes the song." *(About 17 s. This is the pitch's one "agent": most Cal Hacks judges are agent engineers, and one said they're "most excited to see teams make agents do real work" (#1-introductions, Oct 19). Don't repeat it elsewhere in the 2 minutes. The judges just watched the 3-second verdict, so don't say it.)* |
| **1:26–1:38** | Poet | Same. | *(Two versions. **[B] is the default until Matus confirms the 6 PM study ran** (leader, Sat ~9:45 PM); if it did, use [A], with the scoped number. Keep one, delete the other.)*<br>**[A: the study ran]** "I do slam in [the poet's scene]. Open mics are once a week, and in between you practice alone in your room. MeNIN is a stage every night that hears your beat. Last night, five people who'd never freestyled took lesson one. On its beat-scored version, their Beat score went from **[first] to [last]** out of 10, in about **[time]** minutes." *(The real numbers from the study, run on build 18, using one of pm's line options in `docs/study.md`. **Say "beat-scored", and "Beat score", not Flow:** the study measured the strict beat version. Tonight lesson one changed (Matus: "care more about content than exact timing; keep the beats"): timing never fails a try, and content (Craft 6+) is needed to land. If a judge asks why the lesson feels gentler: "We measured the strict beat version. Tonight we made the lesson forgive timing, so beginners spend their effort on what they say." If fewer than three people landed, drop the time. Leader may cut the number instead.)*<br>**[B: no study]** "I do slam in [the poet's scene]. Open mics are once a week, and in between you practice alone in your room. MeNIN is a stage every night that hears your beat, and every lesson try gets a Beat score, so you watch yourself get better." *(About 10 s; the 2 s it frees go to the song.)* |
| **1:38–1:41** | Homer | Totals roll. | "Before I crown anyone, listen." |
| **1:41–1:55** | Homer | **The stitched song: 4 lines over the beat.** Battles are free verse, so this is where the beat comes back: the payoff. Each line appears with its poet's name, the gold line returns, and the scene replays each line's colors. *(Generation starts the moment Matus's transcript is final, about 0:54, so it has about 45 s of headroom.)* | Homer performs the battle back as one poem. A rhapsode was a song-stitcher. Let the line land; don't explain it. |
| **1:55–2:00** | Homer, Matus | The champion, the room code and the **champion sting** from the score. | Homer: "[epithet] takes the hall." *(Whatever epithet Homer coined this battle.)* Matus: "**Most AI talks for you. Homer makes you talk.** That's MeNIN." *(The line judges repeat afterwards. The discus invitation moves to just after 2:00.)* |

**Total: 2:00.** The 2 minutes stay about 90% poetry battle. Other events get one sentence and a tile.

**Music (SPEC "Music"):** the original score plays on the menu, as each event's intro, as the fanfare after a discus throw and as the champion sting. It never plays under a speaking poet: battle turns are silent apart from the poet's voice, Homer's stitched song keeps its beat, and the music ducks under Homer's voice. **No sound effects** (Matus: weird effects are worse than silence). Set the score's and the song beat's levels in the Saturday-night hall test.

**After 2:00, if the judge stays (this is where Hacker's Choice gets won):**
- **To switch games:** from the results screen, the operator clicks **New event**, picks the game, then **Begin**. It's the same hall and every phone stays joined, so there's no new code (every phone on build 31 or later; if one stays on the old game, it rejoins with the same code).
- **If debate passed the Sat 8 PM check, Socrates goes first** (decided with leader). He's the thesis made literal: the art of moving people, hosted by the man who questioned Athens. Play 10–15 s of Socrates opening a debate, then offer the judge a side: "Want to argue with Socrates?" It's especially strong for Cartesia, since it's the second voice, and for Anthropic.
  - **The question is fixed in demo mode:** "Is it cheating to let an AI write your love letter?" It's our thesis turned into a question: most AI talks for you.
  - **Sides are dealt by turn order:** the first debater says Yes and the second says No. Socrates says it out loud at step-up: "{name}, {title}. You say {side}. The floor is yours. Try not to fall through it." To give the judge a side, give them that turn slot.
  - **Rehearse both sides,** because whoever debates the judge has to argue the other one.
- **Then the invitation:** [If discus passes on 31: "Want to throw the discus?", or] "Want to battle us?"
- **[If discus passes on 31] Discus** (it needs 5 clean runs on build 31 (leader and pm, Sat ~8:25 PM: the build-18 pass came before discus v2 shipped in build 21)): hand the judge Matus's iPhone. "Swing it like a discus, and lift your thumb to release. Keep hold of the phone." The arena shows the throw in silence (there's no whoosh), the distance appears with the fanfare, and Homer calls the throw ("Strong arm." or "A gentle toss. The crowd forgives you."). He doesn't say the number. It takes about 10 seconds, needs zero skill, and gets a laugh.
  - **Safety:** the release is a thumb lift, never opening your hand. Use a phone with a grippy case, and only swing where there's arm room, away from the shared table's laptops.
- **Or a rematch:** hand them the phone and headset; Homer writes a fresh theme and deals fresh phrases, and they battle the poet.

## If we run long (cut in this order)

1. *(Already done: the opener took the theme pick's slot.)* Next, cut "The Greeks trained that like a sport" from the opener: −3 s
2. Cut the round verdict; the carved line appears in the finale instead: −7 s
3. Cut the how-it-works line to the three names alone ("SpacetimeDB runs the hall, Cartesia gives Homer his voice, Claude judges"): −8 s

Never cut the turns, Homer's spoken verdict, or the stitched song. Those three are the demo.

## When the judge is a sponsor

Swap the 1:10–1:26 line for theirs. Same length, same spot.

| Judge from | Say this instead |
| --- | --- |
| **Spacetime** | "SpacetimeDB is the hall. Rooms, turn order, scoring and the winner all run in reducers, server-side. The speaking phone streams its voice levels twenty times a second, and the arena subscribes, so the scene moves with whoever's speaking. We wrote zero sync code, and the iPhone client is Swift." |
| **Cartesia** | "Cartesia is ears and voice. We feed Homer's phrases to the recognizer, so it catches the wine-dark sea in a loud hall: in our tests, with a drum at full volume as the noise, three percent word error, twenty without, and the final transcript lands under a tenth of a second after you stop." *(Receipt: `docs/voice-wer/`. Synthetic test clips, so say "in our tests".)* *(The lessons' beat lane runs on onsets detected on the phone, not on STT timestamps. Don't credit Cartesia for it.)* |
| **Anthropic** | "Claude is the judge and the coach. It judges content only, image, answer and craft, on an anchored scale, with Homer's phrases and the verse you're answering in front of it. Every verdict shows the three scores and the line it's quoting. Where it can go wrong: taste is contestable, so you see exactly why you lost." |
| **Meta** | "Two strangers, answering each other in verse, in one room. The judge literally scores how well you answer the person before you. And at the end, Homer stitches everyone's lines into one song. You leave having made something together." |
| **Apify** | "Nearly a third of Homer's phrase bank was mined by an Apify Actor from four public-domain Homer translations, and about one in five cards he deals you comes from it. Our Actor reads the translations with plain rules, no language model, counts every phrase's beat with our own scanner, and a person reviewed every one it found." |
| **Moss** *(the dealer is on for judging)* | "Homer's phrases were dealt by Moss. Homer writes a new theme every round, so no tag list could know it in advance. Moss ranks all 180 of our formulas by meaning against it in about thirteen milliseconds on our server. For 'the night before the battle', tags dealt 'the sea-wolf'; Moss deals 'the battle-sweat'. If Moss ever stalls, the old dealer takes over silently." *(Receipt: `homer/bench/moss-2026-10-24-droplet.txt`.)* |
| **Fetch.ai** *(only if homer-bard is live)* | "Homer is also an agent on Agentverse. From ASI:One you can ask him for a theme, get five phrases, send a verse and get judged by the same scanner and judge you just watched." *(The agent still deals five, per `homer/AGENTVERSE.md`.)* |
| **Figma** | "Every screen and all eight emotion palettes started in Figma, and the agents building the app read the Figma file directly. The stage log in our Devpost shows each handoff, including what broke." |

## Fallbacks, decided now so nobody improvises

| What breaks | Do this | Don't |
| --- | --- | --- |
| A phone won't join, or SpacetimeDB wedges | **Reload the website's tab and click "Resume [code]"**: same room, same code, same scores, and the battle carries on from its phase (nothing advances while the tab is gone; the phones just wait). If that fails, click **"Open the hall"** for a new room, and the poets type its new code. If that fails too, switch to **Practice Spar** on one device: the poet against Homer, with the same turn, verdict and scene. | Debug at the table |
| The Mac dies | **Open https://play.206.189.237.157.sslip.io/homer in Safari on another device**: the iPad, a teammate's laptop, or iPhone C (under 900 px it lays out as one column). Click "Host a battle", then "Open the hall: Poetry battle" for a **new room**, and the poets join its new code: another device can't take over the Mac's room, because the host identity lives in that browser. Last resort only: the app's emergency arena on iPhone C, behind the Dev screen. | Apologize for the screen size more than once |
| STT is garbage (noise) | Headset closer to the mouth, one retry. If it fails again, play the backup video. | Retry three times |
| No verdict at 4 s | Homer's pre-recorded stall line plays ("The Muse is still counting."). Keep talking. | Fill silence with apologies |
| No verdict at 10 s | Nothing to do: the arena doesn't stall. Homer says "Homer is silent on this one.", the verse gets a neutral Image 4 / Answer 4 / Craft 4 = 40/100, its best line still shows, and the battle moves on (builder, Sat 4:15 PM). Say it plainly if a judge notices: "The judge timed out, so that turn got a neutral score." Never show a canned verdict; that would be a mocked response. | Fake it |
| Network down | The ethernet should prevent this. If not, play the **backup video**. Practice isn't an offline fallback, since it still needs Claude and Cartesia. | Use a hotspot (banned at the venue by a Cal Hacks announcement) |
| The judge has 60 seconds, not 120 | Run only 0:00–0:39 (the opening, one turn and one verdict), then jump to the stitched song from a prior battle. That's still live: it's the last real battle's song. | Rush the whole script |

## Rehearsal

- **Before every rehearsal and every judge: keep the arena Mac awake.** Run `caffeinate -dims` in a Terminal for the whole session, keep the Mac plugged in if there's power (on battery, `-i` still keeps it awake), keep the arena tab in front, and keep the lid open. On Sat 4:24 PM both phones and the arena dropped in the same second (leader). A network blip self-recovers (the arena shows "Reconnecting…" and finishes the battle), so only a sleeping Mac or a closed tab kills it. The full checklist is in [run-sheet.md](run-sheet.md#before-each-judge-about-2-minutes).
- Run it **three times back to back**, because there are 3 judges and they may come one at a time. The operator resets with **Rematch** (same poets, new theme) in under 10 seconds.
- Do one full rehearsal **in the hall at peak noise on Saturday night**, at demo volume. Battles have no drum now, so the test checks two things: that STT holds up in the hall's noise, and that the arena's rescue whisper is loud enough to hear but doesn't get picked up by the speaking poet's mic. If STT still picks up the room, the fallback is the stage-mic option (ux-flow option A).
- Time every run. If p50 from turn end to first verdict audio is over 3.5 s, tell the leader before feature freeze.
