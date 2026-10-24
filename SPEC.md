# MeNIN: Product Spec

This is the source of truth for what we are building. If the code disagrees with this file, this file wins. If this file is wrong, change it first, then the code.

Background (pitch, tracks, schedule, demo script) lives in `Homer Cal Hacks 13.0 Project Plan.md`. Where the two disagree, this file wins.

## The idea

**MeNIN teaches you to improvise poetry out loud the way Homer did, then lets you battle other poets live.**

The name: μῆνιν (*mēnin*, "rage", said "MAY-nin") is the first word of the Iliad, and so the first word of Western literature.

Homer never memorized the Iliad. He improvised it, using formulas: ready-made phrases that fit the beat ("the wine-dark sea", "swift-footed Achilles"). Every oral tradition that improvises works this way: Homer, Beowulf, freestyle rap. Learn the formulas and the beat, and you can improvise. MeNIN gives you both, with Homer himself as your teacher.

Why it matters: AI can write anything now, but it can't stand up and move a room for you. A powerful voice matters more than ever, and the Greeks trained it like a sport. **Most AI talks for you. MeNIN makes you talk.**

The feel is professional and badass, never academic. Homer is a legendary bard, not a professor. You are learning to spit.

## Platform

MeNIN is a universal iOS app (SwiftUI, iOS 18+, iPhone and iPad), shared with the team through TestFlight. Universal so the arena runs full-screen on an iPad or a Mac. The display name is MeNIN; internal names (the `Homer` Xcode target, the `homer/` folder, the bundle id) stay as they are. The same app runs every mode; in a battle each device runs it as either the arena or a player.

**The website** (Matus's call, Sat 12:20 PM; the battle screen, Sat 1:00 PM) is the big screen anyone can open: MeNIN's hall of Greek games in a browser, at a public HTTPS URL, with HohHamNap's 3D Homer in front of MeNIN's live scene (the painted colors that answer the speaker's voice, the same scene as the app; Matus, Sat 3 PM). The poetry battle is the focus. Open it on a laptop and it becomes the arena: it hosts the room, drives the battle and speaks as Homer, the same arena contract as the Mac app (`spacetime/CONTRACT.md`). Phones join its room with the app and keep the app's own Atelier look. It is deployed, never localhost: judges must be able to open it themselves. It's static files served from our droplet, talking to the same SpacetimeDB database and agent service as the app. One big screen, one story (Matus, Sat 2:30 PM): **the website is the only arena people see.** The app on a phone is the controller (join a battle by code or QR) plus training (Bard, Practice). The app's own arena mode stays in the code behind the Dev screen as an emergency fallback, never offered in the menus.

The look is **Atelier** (Matus's pick, Sat 11:55 AM): cream cards with Bodoni display type and Inter UI, wine and gold accents, over the full-screen scene of matte, painted color. Open and simple, lots of negative space, no glow or neon. Names and the wordmark must read from 2 m away on a laptop screen. On a phone, every screen is one vertical stack: context at the top (event, theme, who's up), content in the middle, and one primary action at the bottom in the thumb zone. Nothing clips, overflows or needs scrolling mid-turn on any iPhone from the SE to the Pro Max. **Nothing ever looks frozen** (Matus, Sat 2:40 PM): every wait over about 300 ms, on the phone and the website, shows a loading icon (a matte animated mark, never a system spinner) and one plain line saying what's happening ("Homer is weighing your verse…", "Reconnecting…").

## The games

MeNIN is ancient Greek Wii Sports: party games from the Greek *agon* (contest), on one shared screen with phones as controllers. It's historically real: the Greeks didn't separate sport from poetry, and at the Panathenaic Games rhapsodes competed reciting Homer alongside the athletes.

| Event | Host | What you do | Status |
| --- | --- | --- | --- |
| Poetry battle | Homer | Improvise verse over the beat | Core. The rest of this spec describes it |
| Socratic debate | Socrates | Argue a question in timed spoken turns | In build now |
| Discus | Homer announces | Swing your phone; its motion sensors measure the throw | In build now |
| Other events | | Locked tiles on the event menu | Not building |

- Each event is a config on one engine: host, hand, rubric, turn length, beat on or off.
- **Socratic debate** reuses the poetry battle's turns, scene, and verdict. Your hand holds rhetorical moves instead of formulas ("define your terms", "counterexample", "analogy"). The freeze rescue becomes Socrates whispering a question to ask. You tap a move card as you make the move, and the judge checks you really made it. Sides are dealt by turn order. It has its own five-axis rubric (Claim, Reason, Answer, Craft, Poise) and no beat.
- **Discus** is a self-contained motion minigame: no voice, no Claude. Core Motion measures the swing and the release, and the arena shows the throw. You hold a button with your thumb while you swing and release by lifting your thumb; you never let go of the phone.
- The 2-minute demo stays at least 80% poetry battle. An extra event that can't run 5 times in a row without failing by Sat 8 PM stays a locked tile for the demo. All checkpoints are in `docs/gtm/reality-check.md`.
- Bard mode and Practice mode are the training, like Wii Sports Training.

## Music

MeNIN has an original soundtrack composed by a teammate: a hall and menu theme, an intro per event, the discus throw and fanfare, a champion sting, and training ambience. Music never plays while any mic in the room is open; during poetry turns only the procedural beat plays, and music ducks under Homer's and Socrates' voices. In a hall, only the arena plays music. In demo mode the hall theme stays ducked, and an operator key mutes all music. The brief for the composer (cue list, lengths, formats, loudness, loop points) is `docs/audio.md`.

## First open

The first time someone opens MeNIN, Homer speaks before any menu: "The first word of Western literature is mēnin. Rage. Give me one line." You say anything, the scene answers your voice, and Homer says: "Good. Now let me show you how I did it." Then the event menu. Every later launch opens straight on the menu. The TTS must say mēnin as "MAY-nin": write it as "may-nin" (lowercase, hyphenated) in the TTS input, since capitals get spelled out. The caption still shows mēnin.

## The three modes

Learn, train, fight. No mode is locked behind another.

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

- **The arena** is one big shared screen: the app in arena mode on a Mac (Apple Silicon runs iPhone apps), an iPad, or a phone mirrored to a TV. It shows the scene, the beat lane, the scoreboard, and a QR code to join.
- **Your phone** is your mic and your hand. Join by scanning the QR code or typing the room code; no account needed. Your hand is private, so you can save your best formula for the last round.

How a battle runs:

- **Entrance.** Homer announces every poet by their epithet ("Enter Matus, Breaker of Deadlines!"). A poet without one gets one coined by Homer on join.
- **Rounds.** Three rounds. Each round has a theme; every poet takes one turn; turn order rotates. The scene on the arena reacts to whoever is speaking. The mic is hands-free everywhere (Matus's call, Sat 2 PM; push-to-talk confused first-timers): it opens with a haptic thump when your turn goes live and stays open for the whole verse, your words show live on the arena as you speak, and "I'm done" ends early.
- **The hall stays open.** When an event ends, the arena returns to the event menu with everyone still joined.
- **Verdict.** The judge scores every verse. At the end of each round Homer reads the verdict aloud, and the best line of the round is carved in gold across the arena.
- **Winner.** Highest total after three rounds.
- **Finale: the song.** Homer stitches every verse of the battle into one poem and performs it over the beat while the scene replays the battle's colors, then crowns the champion. ("Rhapsode", one of the rank titles, means song-stitcher.)
- Ranks (Elo) with Homeric titles: Suitor, Herald, Bard, Rhapsode, Homer.
- Spectators can react from their phones; reactions burst into the scene (layer, not core).

## The turn

Shared by practice and battle. This is the core loop; get it right first.

1. **Theme.** Homer announces it aloud ("A ship that never came home").
2. **Hand.** You are dealt five formulas that fit the beat, drawn from the theme and your hoard: "the whale-road", "grey-eyed Athena", "when rose-fingered Dawn came early".
3. **Speak.** Homer plays the beat: a slow drum-and-lyre loop, four beats a bar. Each line is one bar, followed by a rest bar to breathe (demo mode may drop the rests if we run long). In a battle the arena ducks the drum while a poet speaks, and the speaker's phone carries the beat as haptics, so the beat doesn't bleed into the mic. Thirty seconds, four lines (configurable). The beat lane shows the pulses; your words land on it live, and a stressed syllable that hits a beat sounds like a drum strike. A formula card lights up when you use it. The live transcript is always visible.
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

- Voice: deep, confident, controlled. Short sentences. Talks like a legend, never like a lecturer.
- No jargon. Homer never says "iamb", "trochee", "scansion", or "meter" when "beat" will do, and never explains for more than two sentences.
- Bard and Practice: a pro coach. Calm authority, precise feedback, one fix at a time.
- Battle: full badass. An MC at a title fight: big entrances, hype, gentle roasts, verdicts that land like a knockout.
- Never condescends.
- Everything Homer says is captioned on screen.
- Shows before telling: every lesson opens with Homer spitting.
- Never names the user's emotion in words. The scene shows it.

## The scene

Full-screen, always on, behind every mode. It paints the speaker's emotion live.

- Procedural only: Metal shaders and SwiftUI. Never a generated image per line.
- Two layers:
  - **Instant**: loudness and pitch computed on the speaker's phone drive motion and texture at 60 fps. In a battle they stream to the arena at about 20 Hz.
  - **Color**: every ~1.5 seconds the emotion classifier returns weights over eight emotions; the scene blends their palettes, smoothed so it flows instead of flickering.
- Palette per emotion: see "Live emotion engine" in the plan.

## Demo mode

Judging is a 2-minute pitch with a live demo at a shared table, three times over. Demo mode is the same live engine with a shorter battle, never a mock:

- 1 round, 2 poets, 2 lines per turn. Poets are auto-ready.
- Scores count up while Homer speaks the verdict.
- The carved line appears once, at round end. No hoard step, no tally.
- The stitched song is capped at 4 lines; the crown is one line.
- Optional: the judges pick from 3 theme cards on the arena (first thing to cut).
- Rematch resets in under 10 seconds.
- One operator tap on the arena replays the first-open line with captions (the same pre-rendered audio), since we pitch three times on the same arena.
- Judges play on team iPhones handed to them, already on the join screen. Judges can't install TestFlight builds at the table.

The script is `docs/gtm/demo-script.md`.

## Not building

- Voice chat between players. Battles are in one room; remote players see the live transcript.
- Generated images per line.
- Required accounts. An account only keeps your rank and hoard.
- A fifth deployable. Four: the iOS app, the website (static, served from the droplet), SpacetimeDB, one Python service.
- A demo that depends on a side quest. Sponsor side integrations (an Apify Actor that mines the formula bank at build time; a Fetch.ai agent and Moss retrieval inside the agent service) are allowed only behind switches, with today's path as the fallback, and the demo never needs them.

## Cut order

If time runs out, cut in this order: discus, Socratic debate, ranks, spectator reactions, hoard persistence across sessions, Homer mode, Bard lessons 4 to 6, the stitched finale.

Never cut: Bard lessons 1 to 3, the turn (beat, beat lane, freeze rescue, scene, judge), two-player battle on the arena.

## Open questions

- Turn length (30 s) and lines per turn (4).
