# Homer: Cal Hacks 13.0 Project Plan

Oct 23, 2026 · @Matus

## The pitch

Homer is a voice-first bard that teaches you to compose and recite poetry out loud, then lets you battle other poets live. You speak, and the room reacts: a procedural scene shifts color and motion with the emotion in your voice. An AI judge scores each verse on meter, imagery, wit, and emotional range, and ranks climb a ladder.

The hook is historical and real. Homer did not memorize 15,000 lines. He composed live using oral-formulaic technique: stock epithets ("swift-footed Achilles", "wine-dark sea") that fit fixed metrical slots in dactylic hexameter, so a bard could improvise for hours without losing the beat. Homer the app teaches that same method and makes it a game.

One line for Devpost: **Learn to compose poetry out loud the way Homer did, then duel other poets live while the scene paints your emotions.**

The bigger why: speaking well in front of people is one of the most valuable skills there is, and almost nobody practices it. The Greeks trained rhetoric and recitation as a core discipline. Homer gives that practice back as a game: diction, rhythm, delivery, and the nerve to perform live, improved together with friends. Use this line in the pitch close.

## Why this beats the field

This is the contrarian trade. The team-formation channel is full of "Microsoft, Hyphenate, or Coinbase" posts, so Sunday's judging room will be a sea of finance agents with a fraud-detection moment, most of them built with Claude open in the next tab. Judges will be numb by the tenth one. Nobody is building a voice poetry battle with a reactive scene.

Three reasons it wins:

1. **Niche depth.** Hackathons reward one thing done deep. Oral-formulaic composition is a specific, defensible idea with a real intellectual history, not a generic "AI tutor".
2. **The demo is an experience.** Judges can step up and battle. That is how you win Hacker's Choice and Most Creative, where the prize is the same MacBook Air M5 per member plus $3,600 as any other main track.
3. **No bolt-ons.** Every sponsor we use is load-bearing: pull it out and the demo breaks. That is the test judges apply, consciously or not.

Main Cal Hacks criteria, and how we hit each:

| Criterion | How Homer hits it |
| --- | --- |
| Application | Spoken-word poets, slam communities, and recitation students get a live practice partner |
| Intentionality | One idea, Homer's method, carried through tutor, battle, judge, and scene |
| Functionality | Full loop works live: speak, get scored, see the scene react, climb a rank |
| Creativity | Voice-driven emotion-to-color scene, multiplayer verse duels, Homeric formula engine |
| Technical complexity | Real-time multiplayer backend, streaming voice, live emotion classification, procedural shaders, constrained generation with a benchmark |

## The product

The battle is the spine. Everything else is an on-ramp to it or a layer on top of it.

**1. Bard mode (solo tutor).** You talk to Homer by voice. Homer teaches one technique at a time: a metrical slot, a stock epithet, a way to open a line. You try it out loud, Homer hears it, and gives feedback on the beat and the image. Sessions are short, two to five minutes. This is the Anthropic "usable Monday" surface.

**2. The Agon (multiplayer battle).** Two to five poets join a room. Homer announces a theme and a form (free verse, rhyming couplets, hexameter for the brave). Poets take turns speaking a verse within a time limit. Everyone hears everyone, and the shared scene reacts to whoever is speaking. Rounds of three; the crowd can react live.

**3. The Judge.** After each round, the AI judge scores every verse on four axes: meter and flow, imagery, wit and response to the opponent, emotional range. It reads a one-line verdict aloud in a bard's voice, with the single best line quoted. Scores are visible so the ranking feels earned, not arbitrary.

**4. Ranks.** Elo-style ladder with Homeric titles: Suitor, Herald, Bard, Rhapsode, Homer. Rank shows on your profile and in the room. Devpost demo video should show a rank climb.

**5. The Scene.** A full-screen procedural visual behind every mode that paints the speaker's emotion in real time. Detail in the next section.

Cut list if time runs out, in order: ranks first, then solo tutor depth, then crowd reactions. Never cut the battle, the judge, or the scene.

## Live emotion engine

As you speak, the scene turns into a painting of how you feel. Anger floods the frame crimson with jagged motion. Grief sinks to slow, deep blue. Awe rises gold from the bottom. Complex emotions are not picked, they are mixed: the engine outputs a weight vector over emotions every second or two, and the scene blends palettes by those weights.

Pipeline:

1. Mic audio streams to the voice layer (Cartesia STT) and we get a rolling transcript.
2. Every 1.5 seconds, the latest window of transcript plus prosody features (pitch, energy, speaking rate from the raw audio) goes to a fast classifier. Claude Haiku with a strict JSON schema works: it returns weights for anger, grief, joy, awe, tenderness, fear, defiance, longing.
3. The weight vector is smoothed (exponential moving average, so the scene flows rather than flickers) and sent to the scene renderer.
4. The renderer drives shader uniforms: base hue, saturation, turbulence, bloom, particle velocity, and a "wash" effect that sweeps a new color across the frame when the dominant emotion changes.

Emotion palette:

| Emotion | Color | Motion |
| --- | --- | --- |
| Anger | Crimson, orange edges | Jagged, fast, high turbulence |
| Grief | Deep blue, near black | Slow descent, low energy |
| Joy | Warm yellow, pink | Rising, bouncing particles |
| Awe | Gold, white bloom | Slow upward sweep, high bloom |
| Tenderness | Rose, soft lavender | Gentle drift, soft focus |
| Fear | Cold green, grey | Trembling, inward pull |
| Defiance | Violet, hot white | Outward burst, sharp lines |
| Longing | Dusk purple, amber | Slow horizontal drift |

Hard rule: the scene is procedural (WebGL shaders and particles), never generated images per line. Image generation is too slow for a live feel and will break the demo. Shaders cost nothing per frame and look better in motion. A single hero image from Bitdeer can set the backdrop per theme at round start; the live reaction stays procedural on top of it.

In battle mode the scene is shared, so the arena visibly reacts to whoever is landing hits. The judge can cite emotional range because the engine already measured it.

## The formula engine

This is the technical depth and the research-flavored moment of the pitch. Oral-formulaic composition is, in modern terms, constrained generation: fixed metrical slots, a bank of stock phrases that fit them, and improvisation inside those constraints. We can build that as a scaffold around Claude and measure the difference.

The analogy for judges: Homer's bards were doing token generation with a hand-built grammar. Modern LLMs generate freely and lose the meter. Give the model Homer's scaffold and it holds the beat.

How it works:

1. **Formula bank.** Scrape public-domain epic text (Project Gutenberg, Perseus Digital Library) and extract repeated noun-epithet phrases with their metrical shape. A few hundred entries is plenty.
2. **Meter checker.** A syllable and stress scanner that scores a line against a target meter (dactylic hexameter for the epic mode, iambic pentameter for the accessible mode). Open-source scansion libraries exist in Python; a CMU pronouncing dictionary lookup gets stress.
3. **Scaffolded generation.** When Homer composes (teaching an example, or playing as an opponent in a battle), Claude is given the target meter, the formula bank, and a check-and-retry loop: generate a line, scan it, fix the slots that miss.
4. **The benchmark.** Raw Claude versus scaffolded Claude on 50 prompts, scored on meter accuracy. One bar chart in the pitch. That single chart is the "proof" judges remember, and it is honest.

For the human player the same scanner gives live feedback in Bard mode: it highlights the syllables that broke the meter and suggests an epithet that fits.

Scope note: this is not changing how LLMs are trained, and we should not claim it is. It is inference-time structure that reproduces a 2,800-year-old technique. That framing is more credible and still sounds deep.

## Tracks

The test for every sponsor: if we remove it, does the demo break? Only yes gets in.

**Microsoft: no.** Their brief wants a production-minded agent in finance, productivity, or healthcare, judged on customer understanding and a prototype-to-production path. A poetry battle does not fit, and forcing it is exactly the bolt-on judges smell. Keep Microsoft as a recruiting conversation (Sat 11:00 coffee chat), not a track. The project is still a great talking point: real-time systems, streaming voice, and shaders are production engineering.

**Meta: yes.** "Bringing People Closer Together with AI" is the battle, word for word. Strangers in a room, dueling in verse, reacting to each other live. Prize is a paid trip to a Round 2 hackathon at Menlo Park.

### Core (build in from hour one)

| Track | Prize | What qualifies us | Load-bearing because |
| --- | --- | --- | --- |
| Anthropic, Claude for Public Benefit | $5,000 credits, 1yr Max 20x, office hours, HQ invite | Named community, lived problem, usable Monday, stated failure modes | Claude is the bard, the judge, and the emotion classifier |
| Meta, Bringing People Closer Together | Menlo Park Round 2, travel paid | Multiplayer social experience | The battle is the product |
| Spacetime (SpacetimeDB) | $2,048 / $1,024 / $512 | Real-time backend is the core; CEO Tyler Cloutier onsite | Rooms, turns, shared scene state, live crowd reactions all run through it |
| Cartesia | \~$1,516 | Voice is core; code CARTESIACALHACKS | Every interaction is spoken; judge speaks verdicts in a bard voice |
| Moss | AirPods Max / Pro | Voice AI, personal agents | Homer is a voice-first personal tutor |
| Cal Hacks main: Most Creative, Hacker's Choice, Most Technically Complex | $3,600 + MacBook Air M5 per member for 1st; themed prizes | Criteria in section above | The whole build |

### Strong (add Saturday morning if the core is working)

| Track | Prize | How it is load-bearing |
| --- | --- | --- |
| Figma | Five $1,000 Amazon GCs + recruiting, Booth 35 | Design the entire UI and the emotion palette system in Figma first; the Figma file is the design source of truth. Matus wants a top-tier UI/UX, so this is free |
| Bitdeer AI Model Studio | $500 credits + mice / $200 + LEGO; workshop Sat 1-2 PM Gate 4 | Hosts the per-theme hero backdrop image model and can host an open emotion or prosody model |
| Apify | $5,000 pool ($2,000 1st) + $400 Best Actor; coupon APIFY\_CAL\_HACKS; workshop Sat 11-12 Breakout 3 | An Apify Actor scrapes Gutenberg and Perseus to build the formula bank. Ship it as a public Actor for Best Actor |

### Stretch (only if a teammate is idle)

| Track | Prize | Angle |
| --- | --- | --- |
| Elastic Agent Builder | Meta Quest 3S / Bose QC | Semantic search over the epithet bank for the judge and tutor |
| Convex | \~$1,308 gear; workshop Sat 4 PM | Alternative to Spacetime for profiles and ranks if Spacetime fights us |
| Mana | $5,000 | Only if the battle can live inside Mana; verify at booth |
| Bright Data | $1,500 credits + $500 GC | Overlaps Apify; pick one, not both |

### Skip

Hyphenate, Visa, Coinbase, CRS, Capital One, Factory, Fetch.ai, Atlassian, SpaceXAI, Armadin, CREAO. None survive the removal test.

### Realistic submission

Five to seven tracks: Anthropic, Meta, Spacetime, Cartesia, Moss, plus Figma and Apify if Saturday goes well. Ask #0-ask-directors whether Devpost caps sponsor tracks per project before submitting.

## Anthropic framing

The track wants a narrowly named community, a lived problem, something usable Monday, and honest failure modes. "People who like poetry" fails the first test. Pick one of these and commit to it in the pitch and the Devpost text:

| Community | Lived problem | Why Homer fits |
| --- | --- | --- |
| Spoken-word and slam poets (recommended) | Open mics are weekly at best, so there is nowhere to practice performing live and get judged in between | Battle mode is a 24/7 open mic with instant feedback and a ladder |
| Students prepping for recitation competitions (Poetry Out Loud reaches over 150,000 US students a year) | No practice partner who can hear meter and delivery, only a mirror | Bard mode listens, scans meter, and coaches delivery |
| ESL learners building English rhythm | Stress and rhythm are the hardest part and textbooks cannot hear you | The meter checker gives live feedback on stress patterns |

Recommended: spoken-word and slam poets, because the UPenn teammate who performs can speak for that community from experience, and because it makes the battle the headline rather than a side mode.

Failure modes to state in the Devpost (judges reward this):

- Speech recognition misses in noisy rooms; we show the transcript so the poet can see what Homer heard.
- The judge has taste and taste is contestable; scores are shown per axis with the quoted line so verdicts are explainable, and losers can see why.
- Emotion classification from text and prosody is approximate; the scene is art, not a diagnosis, and we never label the user's emotion in words.
- Meter scanning for English is imperfect on proper nouns and loanwords; we flag uncertain syllables rather than mark them wrong.

Usable Monday: one link, join a room, speak. No account needed to play; an account only to keep a rank.

## Architecture and stack

One web app, one real-time database, one Python service. Keep it to three deployables so the demo cannot break on a fourth.

**Front-end (web, React + Vite, TypeScript).** Lobby, battle room, scoreboard, ranks, Bard mode. WebGL scene via Three.js with custom GLSL shaders for the emotion palette. Subscribes to SpacetimeDB for all room state. Captures mic audio and streams it.

**SpacetimeDB (real-time core).** Tables: Room, Player, Turn, Verse, Score, Rank, SceneState, Reaction. Reducers: create\_room, join\_room, start\_round, submit\_verse, post\_score, react. Every client sees the same turn order and the same emotion vector, so the shared scene stays in sync without us writing any sync code.

**Agent service (Python, FastAPI).** Holds the Claude calls and the formula engine.

- Bard: Claude Sonnet with the curriculum prompt and the formula bank; produces lessons, example lines, and feedback.
- Judge: Claude Sonnet with the rubric; returns per-axis scores and a verdict line as strict JSON.
- Emotion: Claude Haiku on a 1.5 second window of transcript plus prosody features; returns the weight vector as JSON.
- Meter scanner: Python, CMU dictionary stress plus a scansion pass; scores lines against hexameter or pentameter.
- Formula bank: JSON built by the Apify Actor from Gutenberg and Perseus.

**Voice (Cartesia).** Streaming STT from the browser for transcripts; TTS in a bard voice for Homer's lessons and the judge's verdicts.

**Design (Figma).** Design system, screens, and the emotion palette defined first, then built. Dark theme, serif display type for the Homeric feel, one accent that shifts with emotion.

**Optional (Bitdeer).** One hero backdrop image per battle theme generated at round start, placed under the procedural layer.

Data flow for one spoken verse: mic audio streams to Cartesia STT; transcript chunks go to the agent service; emotion vector and transcript write to SpacetimeDB SceneState and Verse; all clients render the shader from SceneState; at turn end the judge scores the full verse and writes Score; the scoreboard and the TTS verdict read from Score.

## Build order

Spine first, then layers. Each milestone is demoable on its own, so a cut at any point still leaves a working product.

| When | Milestone |
| --- | --- |
| Fri 7 PM to 9 PM | Figma design system and the five screens; SpacetimeDB schema and reducers deployed; repo and FastAPI skeleton; claim Cartesia, Apify, Bitdeer, Anthropic credits; gather Homer sources |
| Fri 9 PM to 1 AM | Two browsers in one room taking turns with typed text; judge returns JSON scores; scoreboard renders them; judge rubric written |
| Sat 8 AM to 10 AM | Cartesia STT streaming into the room; verses are spoken, not typed |
| Sat 10:00 to 11:30 | Matus at Microsoft workshop and coffee chat; base shader scene; Devpost and curriculum drafts |
| Sat 11:30 to 2 PM | Emotion classifier live; emotion vector drives the shader; first full battle with the scene reacting |
| Sat 2 PM to 5 PM | TTS judge voice; Bard mode solo loop; meter scanner feedback; Apify Actor builds the formula bank |
| Sat 5 PM to 8 PM | Ranks and ladder; crowd reactions; polish screens to the Figma spec; Bitdeer backdrop if time |
| Sat 8 PM to 11 PM | Benchmark run (raw vs scaffolded Claude, 50 prompts); record demo video; Devpost draft complete |
| Sat 11 PM to 1 AM | Full rehearsal of the 3-minute pitch twice; fix the top three bugs; freeze features |
| Sun 7 AM to 8:45 AM | Final deploy, submit on Devpost by 8:45, buffer to 9:00 hard deadline |
| Sun 10:30 to 12:30 | Judging, full team at the table |

Feature freeze is Saturday 11 PM. Anything not working by then is cut, not fixed at 3 AM.

## The demo

Format is a 3-minute pitch plus 2 minutes of Q&A, live demo required. Open with the moment, not the slides.

**0:00 to 0:30, the hook.** The poet steps up, no intro, and speaks four lines of verse into the mic. The scene behind him turns gold, then crimson, as the verse turns. He stops. "That was Homer. Not the app. The method. Homer never memorized the Iliad. He composed it live, with a formula. We built the formula, and we made it a game."

**0:30 to 1:15, the battle.** Matus and the MechE are already in a room. One judge is invited to join on their phone with a room code. Two quick verses, 20 seconds each, the shared scene reacting to each speaker. The AI judge reads the verdict aloud in a bard's voice and the scoreboard lands. If the judge who joined wins a point, let the room feel it.

**1:15 to 1:45, how it works.** One slide: the architecture in five boxes. SpacetimeDB keeps every player in the same turn and the same scene. Cartesia hears and speaks. Claude is the bard, the judge, and the emotion engine. Shaders paint the emotion. Say "nothing here is a mocked response" out loud.

**1:45 to 2:15, the proof.** One chart: raw Claude versus scaffolded Claude on meter accuracy. "We gave a modern model a 2,800-year-old grammar and it held the beat." Then the Anthropic framing: slam poets have an open mic once a week; now they have one every night, with a ladder.

**2:15 to 2:45, Bard mode in 20 seconds.** Matus speaks a line, the meter checker flags one syllable, Homer suggests an epithet that fits, Matus says it again and it scans. That is the "usable Monday" beat.

**2:45 to 3:00, close.** Ranks screen with the Homeric titles. "Join a room, speak, climb. Homer is live right now at the link on the screen."

Q&A prep: have answers ready for "how do you stop the judge being arbitrary" (per-axis scores, quoted line, rubric visible), "what breaks" (noisy rooms, English meter edge cases, we show the transcript), and "what happens Monday" (no account to play, one link).

Demo insurance: a recorded 90-second backup video on a laptop, a wired mic, phones on venue WiFi tested the night before, and a second room pre-created in case the live one wedges.

## Setup checklist, codes, links, schedule

Do tonight, before any code:

- [ ] Claude API credits
- [ ] Cartesia: code CARTESIACALHACKS
- [ ] SpacetimeDB account and CLI; grab the slides and find Tyler Cloutier at the booth
- [ ] Apify: sign up with coupon APIFY\_CAL\_HACKS
- [ ] Bitdeer credits form
- [ ] Figma team file created and shared with all three
- [ ] GitHub repo created, all work starts at the event (rule)
- [ ] Ask #0-ask-directors whether Devpost caps sponsor tracks per project
- [ ] Confirm Meta track submission mechanics on Devpost
- [ ] Devpost project page created with the one-line pitch

Sponsor events worth attending for this build:

| When | What | Where | Who goes |
| --- | --- | --- | --- |
| Sat 10:00 to 10:45 | Microsoft workshop, System Design for Deployed Agents | The Theatre | Matus |
| Sat 11:00 to 11:20 | Microsoft coffee chat with Monika Anonuevo | Onsite | Matus |
| Sat 11:00 to 12:00 | Apify workshop | Breakout 3 | Poet (or skip if building) |
| Sat 1:00 to 2:00 | Bitdeer workshop | Gate 4, Breakout 4 | MechE (optional) |
| Sat 4:00 PM | Convex workshop | TBD | Skip unless Spacetime fails |
| All weekend | Figma Booth 35, Spacetime booth, Cartesia, Moss, Anthropic | Expo | Poet does the rounds Sat afternoon with the demo on a laptop |

Submission: Devpost by Sun 9:00 AM hard deadline, venue by 8:00. GitHub repo link, cover image, demo video opening with the moment. Judging Sun 10:30 to 12:30, whole team at the table. Closing 2:00 to 4:00 PM.

Reference docs: Hacker Guide, Devpost, Figma track doc, Food menu. WiFi: Cal Hacks 13.0 / hackers!
