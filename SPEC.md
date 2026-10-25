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

**The website** (Matus's call, Sat 12:20 PM; the battle screen, Sat 1:00 PM) is the big screen anyone can open: MeNIN's hall of Greek games in a browser, at a public HTTPS URL, with HohHamNap's 3D Homer in front of MeNIN's live scene (the painted colors that answer the speaker's voice, the same scene as the app; Matus, Sat 3 PM). The poetry battle is the focus. Open it on a laptop and it becomes the arena: it hosts the room, drives the battle and speaks as Homer, the same arena contract as the Mac app (`spacetime/CONTRACT.md`). Phones join its room with the app, which now wears the website's palette (the Hall look). It is deployed, never localhost: judges must be able to open it themselves. It's static files served from our droplet, talking to the same SpacetimeDB database and agent service as the app. **Judge mode: talk to Homer** (Matus, Sat 4:25 PM). Same shape as a battle: you talk into your phone and the website screen updates live. The website opens a Judge hall; one or more poets join with the app. Homer opens with a Homeric theme; you speak hands-free (SPEAK, your words live on the screen); Homer answers out loud on the screen in two sentences (quoting your words, one fix, honest, a coach), and you answer him or try again: a conversation. Each verse attempt is also scored on the battle's content axes (out of 100), and the screen shows the trend across attempts ("34 → 41 ↑", the best so far), so you can keep working a verse until it's good; a reply to a question or a talk-back isn't scored (Matus, Sat 5:25 PM). It's a `coach` event on the same engine: rooms, turns and live transcripts as in poetry, with Homer's reply in place of the score. Bard mode stays the app's lessons tonight (the study runs on them) and has no website page until it works phone-to-screen; it moves to the screen after the freeze if there's time.

One big screen, one story (Matus, Sat 2:30 PM): **the website is the only arena people see.** The app on a phone is the controller (join a battle by code or QR) plus training (Bard, Practice). The app's own arena mode stays in the code behind the Dev screen as an emergency fallback, never offered in the menus.

The look is **Atelier** (Matus's pick, Sat 11:55 AM): cream cards with Bodoni display type and Inter UI, wine and gold accents, over the full-screen scene of matte, painted color. **The app now matches the website** (Matus, Sat 8:40 PM, "now it's about polish"): the website's palette (its blue and creams) as a third token mode, **Hall**, in the Figma Directions variables and the app's `Direction` switch. On the app the scene is **blue at rest, colors on voice** (Matus, Sat 9:35 PM, his final call after trying blue only): at rest, the website's wavy white with the site's cool blue. While someone speaks (the phone's own mic on its turn, or the room's live scene), the voice's emotion colors shoot in, then settle back to white and blue. It sits behind more of the app's screens (join, the event menu, the waits, the verdict, and the poet's own turn). Designed in Figma first, then built through the tokens, and logged in `docs/gtm/figma-stage-log.md`. The website itself is unchanged. Open and simple, lots of negative space, no glow or neon. Names and the wordmark must read from 2 m away on a laptop screen. On a phone, every screen is one vertical stack: context at the top (event, theme, who's up), content in the middle, and one primary action at the bottom in the thumb zone. Nothing clips, overflows or needs scrolling mid-turn on any iPhone from the SE to the Pro Max. **Nothing ever looks frozen** (Matus, Sat 2:40 PM): every wait over about 300 ms, on the phone and the website, shows a loading icon (a matte animated mark, never a system spinner) and one plain line saying what's happening ("Homer is weighing your verse…", "Reconnecting…").

## The games

MeNIN is ancient Greek Wii Sports: party games from the Greek *agon* (contest), on one shared screen with phones as controllers. It's historically real: the Greeks didn't separate sport from poetry, and at the Panathenaic Games rhapsodes competed reciting Homer alongside the athletes.

| Event | Host | What you do | Status |
| --- | --- | --- | --- |
| Poetry battle | Homer | Spit free verse on a theme; Homer judges | Core. The rest of this spec describes it |
| Socratic debate | Socrates | Argue a question in timed spoken turns | In build now |
| Discus | Homer announces | Swing your phone; its motion sensors measure the throw | Unlocked: passed 5 of 5 real-phone runs on the website, Sat 4:49 PM |
| Stadion (running) | Homer announces | Pump your arms with the phone in your hand like a sprinter; everyone races at once, live on the screen | In build now (Matus, Sat 4:55 PM). Same gate: 5 clean real-phone runs, or it stays a locked tile |
| Pygmachia (boxing) | Homer announces | A live fight: the phone tracks punch and block and drives your fighter's arms on the screen | Next, only after the Stadion passes |
| Toxeia (archery) | Homer announces | Two phones: one is the bow, the other is drawn back like the arrow; aim at a target on the screen, then pass both phones on | In build now (Matus, Sat 6:05 PM) |
| Pale (wrestling), other events | | Locked tiles on the event menu | Not building |

- Each event is a config on one engine: host, hand, rubric, turn length, beat on or off.
- **Socratic debate** reuses the poetry battle's turns, scene, and verdict. Your hand holds rhetorical moves instead of formulas ("define your terms", "counterexample", "analogy"). The freeze rescue becomes Socrates whispering a question to ask. You tap a move card as you make the move, and the judge checks you really made it. Sides are dealt by turn order. It has its own five-axis rubric (Claim, Reason, Answer, Craft, Poise) and no beat.
- **Mode by mode** (Matus): the motion games come one at a time, each in ancient Greek style (black-figure pottery figures, the stadium, the wine-dark palette), each with no voice and no Claude, and each only after the one before it passes its runs.
- **Discus** is a self-contained motion minigame: no voice, no Claude. Core Motion measures the swing and the release, and the arena shows the throw. You hold a button with your thumb while you swing and release by lifting your thumb; you never let go of the phone. **How you throw matters** (Matus, Sat 5 PM), modeled on real discus physics: release speed from the swing; the release angle (best around 33–38°, a steep throw stalls, a flat one plows into the ground); keeping the disc flat (a tilted release loses its lift); spin, which steadies the flight; and direction, so a throw outside the sector is a foul. The arena shows the angle and speed, and Homer calls the technique ("Too steep, the wind took it").
- **Toxeia (archery)**, after GamePigeon's archery: one archer at a time holds two phones. Each phone says what it is in big type: the **bow** (hold it out and point it at the screen; its aim is a live dot on the target. The aim is how the whole phone turns, left/right and up/down, from where it pointed at the start of each arrow, so it doesn't matter how the phone is held (Matus, Sat 7:00 PM); the whole target is about ±20° of turn) and the **arrow** (hold its button to nock, pull it back toward your face to draw, let go to loose). The screen is **only the target**, filling the scene (Greek rings, no drawn archer), with a **dot where the bow is aiming**, live, like GamePigeon; plus a draw meter and the **wind** for each arrow (a direction arrow and a speed in m/s), which pushes the arrow sideways; a weak draw drops the arrow low. **No names to type** (Matus, Sat 6:45 PM): the first phone to join is the bow and its player is the first archer, the second phone is the arrow, and archers go in join order, each named from the room. Ready on the bow starts the archer. Three arrows each, scored on the rings; then the bow says "Pass both phones to {next}" and Ready starts them. After the last joined player shoots, the results come up. Highest total wins. No voice, no Claude.
  - **Camera** (Matus, Sat 7:20 PM: "it isn't gonna work with just phones, we need to wire in a camera as well"): the Mac's webcam watches the archer from the website, with pose tracking in the browser (nothing leaves the Mac). The **aim follows the bow arm**, zeroed at the start of each arrow like the phone. The **draw follows the drawing hand** pulled back toward the face. The archer's **own phone, in the drawing hand, nocks and looses with the thumb**, so it's one phone per archer and nobody passes phones. A small live camera view with the tracked skeleton sits in a corner of the range, so everyone sees it's tracking them. If the camera is off, denied, or loses the archer, the two-phone mode above takes over. Boxing gets the camera next, once archery passes.
- **Pygmachia (boxing)**, after Wii Sports Boxing (version 2 from Matus's first fights, Sat 5:40 PM): one phone per fighter, held like a fist; both of the fighter's fists mirror the phone, and pointing left or right picks the hand, low or high picks body or head. Phone yaw drifts, so it never decides a hit. **The mechanics feel real:** a punch's damage comes from its speed (peak force); stamina drains with every punch and refills when you pause, so spamming makes you weak; two or three quick punches in a row are a combo (a bonus and a COMBO banner); holding the phone upright is the guard, which takes most of a head shot and costs the attacker stamina; and a punch thrown right after you block is a **COUNTER** (double damage, a slow-motion flash). Body shots drain stamina. **The animations are dramatic:** wind-up and follow-through, the target snapping back, screen shake on big hits, slow motion on counters and the KO. Phones send punch and guard events; the server resolves hits; the arena animates two black-figure fighters live. KO, or the most health at the bell, wins.
- The 2-minute demo stays at least 80% poetry battle. An extra event that can't run 5 times in a row without failing by Sat 8 PM stays a locked tile for the demo. All checkpoints are in `docs/gtm/reality-check.md`.
- Bard mode and Practice mode are the training, like Wii Sports Training. Solo discus is gone from the app's home (Matus, Sat 10:30 PM: "we have that on the website"); discus lives on the website, with phones as the controller.

## Music

MeNIN has an original soundtrack composed by a teammate: a hall and menu theme, an intro per event, the discus throw and fanfare, a champion sting, and training ambience. Music never plays while any mic in the room is open; no sound effects beyond the beat and a soft strike on a hit (Matus: weird effects are worse than silence); battle turns are silent apart from the poet's voice, Homer's stitched song keeps its beat, and music ducks under Homer's and Socrates' voices. In a hall, only the arena plays music. In a hall the theme plays at its bed in the lobby and the results and ducks only under Homer's and Socrates' voices (Matus, Sat 8:25 PM: he couldn't hear it ducked), and an operator key (M) mutes all music. The brief for the composer (cue list, lengths, formats, loudness, loop points) is `docs/audio.md`. In poetry, debate and Talk to Homer the music is off for the whole battle, from Begin to the crown (Matus, Sat 10:40 PM); it plays in the lobbies, the results and under the motion games. **The hall theme is in** (Matus, Sat 8:15 PM): `homer/web/public/audio/menin-theme.m4a` (3:38). The website loops it in the menu, the lobby, the results and under the motion games, starts it on the first click, and has a speaker toggle in the header.

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
| 3 | The epithet | Coin your own ("___, Breaker of Horses"). It goes into your hoard; in battle Homer coins you a fresh one each time, and yours is the fallback |
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

- **The arena** is one big shared screen: the website, full screen in a laptop's browser (see Platform). It shows the live scene, the poet's live words, the scoreboard, and a QR code to join.
- **Your phone** is your mic and Homer's phrases. Join by scanning the QR code or typing the room code; no account needed. Your phrases are private and dealt fresh each round.

How a battle runs:

- **Entrance.** Homer announces every poet with a fresh Homeric epithet he coins for this battle ("of the bronze spear", never modern nouns) ("Enter Matus, Breaker of Horses!"), never one of that poet's last five; the hoard epithet is only a fallback (Matus, Sat 3:30 PM: the same one every time is boring).
- **Rounds.** Three rounds. Each round has a theme; every poet takes one turn; turn order rotates. The scene on the arena reacts to whoever is speaking. The mic is hands-free everywhere (Matus's call, Sat 2 PM; push-to-talk confused first-timers): it opens with a haptic thump when your turn goes live and stays open for the whole verse, your words show live on the arena as you speak, and "I'm done" ends early.
- **The hall stays open.** When an event ends, the arena returns to the event menu with everyone still joined.
- **Verdict.** The judge scores every verse. At the end of each round Homer reads the verdict aloud, and the best line of the round is carved in gold across the arena.
- **Winner.** Highest total after three rounds.
- **Finale: the song.** Homer stitches every verse of the battle into one poem and performs it over the beat while the scene replays the battle's colors, then crowns the champion. ("Rhapsode", one of the rank titles, means song-stitcher.)
- Ranks (Elo) with Homeric titles: Suitor, Herald, Bard, Rhapsode, Homer.
- Spectators can react from their phones; reactions burst into the scene (layer, not core).

## The turn

Shared by practice and battle. This is the core loop; get it right first.

1. **Theme.** Fresh every round: Homer generates a vivid, specific theme of six words or fewer from Homer's own world (ships, war, gods, exile, homecoming; nothing invented after the Bronze Age, Matus: "umbrellas did not exist"), with a feeling anyone can riff on, never one of the last twenty ("The ship that left without you"), and announces it aloud. The written themes are the fallback.
2. **Homer's phrases.** Optional help, not homework: your phone shows three stock phrases that fit the theme and the beat ("the whale-road", "grey-eyed Athena"), under one line: "Stuck? Use one of Homer's phrases. It scores Craft." Using one pops "+Craft".
3. **Speak.** In a battle you spit free, with no metronome behind you (Matus, Sat 3:30 PM: "I just want to spit poetry without the metronome"). A 3-2-1 with a haptic tick, then SPEAK fills the phone and the arena in the poet's color, once, for the whole verse. No drum, no beat haptics, no per-line Speak/Breathe while a poet speaks: you get one window (20 seconds in demo mode) with a countdown ring, and "I'm done" ends early. Your words show live on the arena; the scene answers your voice's loudness and feeling. A phrase card lights up when you use it. Lines are whatever you say between breaths. The beat lives in Bard lessons, which teach it, and under Homer's stitched song. **Bard judges content first** (Matus, Sat 9:52 PM: "care more about content than exact timing, keep the beats"): the drum and the beat lane stay, but timing never fails a lesson. A line of 3 to 5 hits counts as a four-beat line, and Homer's verdict weighs the image, the answer and the craft, as in battles. No harpsichord between lines (Matus, Sat 9:45 PM), and **no beatbox** (Matus, Sat 10:10 PM: "what is this, 50 Cent?"): the pulse is one soft, low, woody strike, like a rhapsode's staff on stone, with no snare, rim or backbeat. Homer's demo verses are **real Homer** from public-domain translations, credited, spoken naturally like an epic, not rapped to the pulse.
4. **Freeze rescue.** If you go silent for about 2.5 seconds mid-turn (never in the first 3 seconds after SPEAK; lessons: about a second inside a speaking bar), your phrases glow and Homer whispers one that fits; at most twice a turn, so an ordinary breath never triggers it.
5. **Scene.** Reacts as you speak (see below).
6. **Judge.** Judges the content, honestly (Matus, Sat 4:05 PM: "judge more on content"): Image, Answer and Craft, 1 to 10 each, out of 100 (Image ×4, Answer ×4, Craft ×2). Scores are anchored: a typical first-timer verse lands at 4 to 6, and 9 or 10 is rare, a line you'd quote tomorrow. Clichés and dodging the theme cost. It speaks a one-line verdict that quotes your best line.
7. **Hoard.** A new formula you coin that scans and that the judge rates well joins your hoard.

### Judge axes

| Axis | What it measures | Source |
| --- | --- | --- |
| Beat (lessons only; key `beat`) | Did the stresses land on the drum | Meter scanner, not Claude's guess. Not scored in battle or Practice |
| Craft | Used formulas, varied them, coined new ones | Claude, with the hand and the scanner output |
| Image | Strength of the imagery | Claude |
| Answer | Responded to the last verse (or the theme, if first) | Claude, with the previous verse |
| Range (not scored) | How much emotional ground the verse covered | Emotion engine; it paints the scene but isn't part of the score |

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
- **Every flash means something** (Matus, Sat 4:35 PM: "lean into the color flashing, but not random flashes"): a loud syllable from the speaker's voice is a strike, a new word landing is a ripple, a change of feeling is a wash of new color, and silence settles it. No idle or timer-driven flashes. It reacts in real time (motion within about 100 ms of the voice). The website's battle, debate and Judge screens all use it.
- Two layers:
  - **Instant**: loudness and pitch computed on the speaker's phone drive motion and texture at 60 fps. In a battle they stream to the arena at about 20 Hz.
  - **Color**: every ~1.5 seconds the emotion classifier returns weights over eight emotions; the scene blends their palettes, smoothed so it flows instead of flickering.
- Palette per emotion: see "Live emotion engine" in the plan.

## Demo mode

Judging is a 2-minute pitch with a live demo at a shared table, three times over. Demo mode is the same live engine with a shorter battle, never a mock:

- 1 round, 2 poets, a 20-second free-verse window per turn. Poets are auto-ready.
- Scores count up while Homer speaks the verdict.
- The carved line appears once, at round end. No hoard step, no tally.
- The stitched song is capped at 4 lines; the crown is one line.
- Optional: the judges pick from 3 theme cards on the arena (first thing to cut).
- Rematch resets in under 10 seconds.
- One operator tap on the arena replays the first-open line with captions (the same pre-rendered audio), since we pitch three times on the same arena.
- Judges play on team iPhones handed to them, already on the join screen. Judges can't install TestFlight builds at the table. Overnight (after the 11 PM freeze), the website also becomes a phone controller in Safari (scan the QR, play in the browser, no app), poetry first, as the fallback if the public TestFlight beta isn't approved by morning. The public beta is submitted for review once the judging build is frozen.

The script is `docs/gtm/demo-script.md`.

## Not building

- Voice chat between players. Battles are in one room; remote players see the live transcript.
- Generated images per line.
- Required accounts. An account only keeps your rank and hoard.
- A fifth deployable. Four: the iOS app, the website (static, served from the droplet), SpacetimeDB, one Python service.
- A demo that depends on a side quest. Sponsor side integrations (an Apify Actor that mines the formula bank at build time; a Fetch.ai agent and Moss retrieval inside the agent service) are allowed only behind switches, with today's path as the fallback, and the demo never needs them.

## Cut order

If time runs out, cut in this order: discus, Socratic debate, ranks, spectator reactions, hoard persistence across sessions, Homer mode, Bard lessons 4 to 6, the stitched finale.

Never cut: Bard lessons 1 to 3 (with the beat and the beat lane), the turn (SPEAK, live words, freeze rescue, scene, judge), two-player battle on the arena.

## Open questions

- Turn window: 20 s in demo, 10 s a line otherwise. Practice is free verse too; only Bard lessons use the beat.
