# Homer: Product Spec

This is the source of truth for what we are building. If the code disagrees with this file, this file wins. If this file is wrong, change it first, then the code.

Background (pitch, tracks, schedule, demo script) lives in `Homer Cal Hacks 13.0 Project Plan.md`. Where the two disagree, this file wins.

## The idea

**Homer teaches you to improvise poetry out loud the way Homer did, then lets you battle other poets live.**

Homer never memorized the Iliad. He improvised it, using formulas: ready-made phrases that fit the beat ("the wine-dark sea", "swift-footed Achilles"). Every oral tradition that improvises works this way: Homer, Beowulf, freestyle rap. Learn the formulas and the beat, and you can improvise. Homer gives you both.

The feel is badass, not academic. Homer is a legendary bard, not a professor. You are learning to spit.

## The three modes

Learn, train, fight. No mode is locked behind another; anyone can open a link and battle.

### 1. Bard mode: learn from Homer

Homer is your mentor. A path of short voiced lessons, one technique each, two to five minutes.

Every lesson runs the same way:

1. Homer spits a verse that shows the move. The scene reacts to Homer's voice.
2. Homer names the move in one or two sentences. Never a lecture.
3. You try it out loud over Homer's beat. The beat lane shows where your stresses landed.
4. Homer gives feedback on one thing, and you go again.
5. Land it and the lesson is done.

Curriculum (first three are the minimum we ship):

| # | Lesson | The move |
| --- | --- | --- |
| 1 | The beat | Four stresses a line, a pause in the middle |
| 2 | The formula | Fill half a line with a stock phrase from your hand. Homer sets a hard line so you freeze, and the freeze rescue saves you |
| 3 | The epithet | Coin your own ("___, Breaker of Deadlines"). It goes into your hoard and becomes your battle name |
| 4 | The turn | Shift the feeling mid-verse; the scene shows it |
| 5 | The answer | Respond to a line Homer throws at you |
| 6 | The boast | Land a closing line that hits |

### 2. Practice mode: spar with Homer

Solo reps with no lesson structure. Same turn as battle mode (below), with Homer as the opponent.

- Pick a theme or get a random one, get dealt a hand, take your turn, get the full judge breakdown.
- Spar: Homer takes a turn, you answer, best of three.
- Homer's verses come from the formula engine (scaffolded generation that holds the beat).
- This is also the demo fallback if multiplayer breaks.

### 3. Battle mode: the Agon

Two to five human poets in one room, Jackbox-style:

- **The arena** is one big shared screen (laptop or TV): the scene, the beat lane, the scoreboard, and a QR code to join.
- **Your phone** is your mic and your hand. Join by scanning the QR code or opening the link; no account needed. Your hand is private, so you can save your best formula for the last round.

How a battle runs:

- **Entrance.** Homer announces every poet by their epithet ("Enter Matus, Breaker of Deadlines!"). A poet without one gets one coined by Homer on join.
- **Rounds.** Three rounds. Each round has a theme; every poet takes one turn; turn order rotates. The scene on the arena reacts to whoever is speaking.
- **Verdict.** The judge scores every verse. At the end of each round Homer reads the verdict aloud, and the best line of the round is carved in gold across the arena.
- **Winner.** Highest total after three rounds.
- **Finale: the song.** Homer stitches every verse of the battle into one poem and performs it over the beat while the scene replays the battle's colors, then crowns the champion. ("Rhapsode", one of the rank titles, means song-stitcher.)
- Ranks (Elo) with Homeric titles: Suitor, Herald, Bard, Rhapsode, Homer.
- Spectators can react from their phones; reactions burst into the scene (layer, not core).

## The turn

Shared by practice and battle. This is the core loop; get it right first.

1. **Theme.** Homer announces it aloud ("A ship that never came home").
2. **Hand.** You are dealt five formulas that fit the beat, drawn from the theme and your hoard: "the whale-road", "grey-eyed Athena", "when rose-fingered Dawn came early".
3. **Speak.** Homer plays the beat: a slow drum-and-lyre loop, four beats a bar, one line per bar. Thirty seconds, four lines (configurable). The beat lane shows the pulses; your words land on it live, and a stressed syllable that hits a beat sounds like a drum strike. A formula card lights up when you use it. The live transcript is always visible.
4. **Freeze rescue.** If you go silent for about a second mid-turn, your hand glows and Homer whispers one formula that fits.
5. **Scene.** Reacts as you speak (see below).
6. **Judge.** Scores 1 to 10 on five axes, speaks a one-line verdict, quotes your best line.
7. **Hoard.** A new formula you coin that scans and that the judge rates well joins your hoard.

### Judge axes

| Axis | What it measures | Source |
| --- | --- | --- |
| Beat | Did the stresses land | Meter scanner, not Claude's guess |
| Craft | Used formulas, varied them, coined new ones | Claude, with the hand and the scanner output |
| Image | Strength of the imagery | Claude |
| Answer | Responded to the last verse (or the theme, if first) | Claude, with the previous verse |
| Range | How much emotional ground the verse covered | Emotion engine |

Scores per axis and the quoted line are always shown, so a verdict is explainable.

## The form

Default: **the four-beat line**. Four stresses, a natural pause in the middle. English is stress-timed, so this is how English improvises (Beowulf, rap bars), and counting four stresses is forgiving for speech-to-text and the scanner.

> **WINE**-dark **SEA** / took my **BROTH**er's **SHIP**

Hard mode, **Homer mode**: dactylic hexameter, for the brave.

## Homer, the character

- Voice: deep, theatrical, confident. Short sentences. Talks like a legend.
- Hypes you up, roasts gently, never condescends.
- Shows before telling: every lesson opens with Homer spitting.
- Never names the user's emotion in words. The scene shows it.

## The scene

Full-screen, always on, behind every mode. It paints the speaker's emotion live.

- Procedural only: WebGL shaders and particles. Never a generated image per line.
- Two layers:
  - **Instant**: loudness and pitch computed in the browser drive motion, turbulence, bloom, and particle speed at 60 fps.
  - **Color**: every ~1.5 seconds the emotion classifier returns weights over eight emotions; the scene blends their palettes, smoothed so it flows instead of flickering.
- Palette per emotion: see "Live emotion engine" in the plan.

## Not building

- Voice chat between players. Battles are in one room; remote players see the live transcript.
- Generated images per line.
- Required accounts. An account only keeps your rank and hoard.
- A fourth deployable. Web app, SpacetimeDB, one Python service.

## Cut order

If time runs out, cut in this order: ranks, spectator reactions, hoard persistence across sessions, Homer mode, Bard lessons 4 to 6, the stitched finale.

Never cut: Bard lessons 1 to 3, the turn (beat, beat lane, freeze rescue, scene, judge), two-player battle on the arena.

## Open questions

- Platform: Matus wants iOS. Web only, an iOS app wrapping the web client, or fully native iOS is undecided.
- Push-to-talk with a headset mic, for a noisy judging hall.
- Turn length (30 s) and lines per turn (4).
