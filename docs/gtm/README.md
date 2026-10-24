# How MeNIN wins Cal Hacks 13.0

GTM brief. Friday Oct 23, 11 PM. Sources: Hacker Guide (organizers call it "the source of truth" over Devpost), Hive's live prize list (58 prizes), every sponsor Slack channel and its threads, and the Figma and Moss track docs.

| File | What it is |
| --- | --- |
| [tracks.md](tracks.md) | Every track we enter: prize, criteria quoted verbatim, how we hit each one, what to submit, who to find |
| [demo-script.md](demo-script.md) | **The 2-minute table demo**, second by second, with fallbacks |
| [run-sheet.md](run-sheet.md) | Judging-day logistics: timeline, devices, charging, table layout, rematch drill, fallbacks, packing list |
| [pitch.md](pitch.md) | Sponsor variants, booth pitches, Q&A bank, video shot list |
| [devpost.md](devpost.md) | Devpost submission draft, ready to paste |
| [reality-check.md](reality-check.md) | Are we building BS? What's strong, what isn't, and what each part of the build should change |
| [figma-stage-log.md](figma-stage-log.md) | Figma stage log, filled in as we build (it's worth $2,000 on its own) |

## Verdict

**The idea is good, but the plan is over-scoped and the code so far doesn't match the spec.**

- **Nobody else is building this.** In #1-team-formation, "agent" appears 41 times, "hardware" 31, "robot" 24, "health" 18 and "fintech" 7. "Poetry", "rap", "music", "multiplayer" and "Spacetime" each appear 0 times, and nothing in any channel mentions poetry. Judges will spend Sunday on agents, and we'll be the one table where they get to perform.
- **It's a natural fit for four sponsors.** Spacetime's brief leads with "multiplayer interaction". Cartesia's idea list includes "tutor, debate partner... with distinct voices". Meta judges "how meaningfully they strengthen human connection". Figma's track rewards process, not scope.
- **Scope is the threat.** We have 3 modes, 6 lessons, a hoard, Elo, spectators, an emotion engine, a benchmark, Apify and Bitdeer, for 3 people in about 34 hours. Judges see a 2-minute flow. Four sponsors said it in writing: Cartesia: "We'll favor a strong working prototype over a large unfinished idea." Anthropic: "One thing done well and usable on Monday beats a broad demo." Mana: "A small thing that works beats an ambitious idea that only exists in slides." The organizers: "having a project spread thin with too many features is harder to implement."
- **`homer/` is off-spec.** It's a chat-window iambic-pentameter professor with a 12-step academic curriculum, and its judge will be slow. Details and fixes are in [reality-check.md](reality-check.md).
- **Going iOS-only (Matus's call, SPEC `dc4363b`) changes the odds.** It helps on feel: a haptic beat in your palm, native audio, and no autoplay tap. It hurts on reach: judges and other hackers can only play on our devices, or through a TestFlight public link once Apple's beta review approves it. The Spacetime Swift client is community-built, not official. Per-track changes are in [tracks.md](tracks.md).

## Plan corrections (the Hacker Guide beats the plan)

| The plan says | Actually |
| --- | --- |
| Most Creative and Hacker's Choice pay "the same MacBook Air M5 per member plus $3,600" | Only **First Overall** gets a MacBook Air 13" M5. Most Creative gets an Instax camera, Hacker's Choice a Logitech MX Master 4, Most Technically Complex a NuPhy keyboard, and Best People-First an Apple Watch SE 3. |
| 3-minute pitch plus 2 minutes of Q&A | **"We recommend preparing a two-minute pitch."** Tables are shared by 2-3 teams, there are 3 judges per project, and a live demo is required. The whole team must be at the table from 10:30 to 12:30. |
| Cartesia, about $1,516 | Meta glasses (TBD). Judged 25% each on problem, use of Cartesia, execution, and **impact and responsibility**. |
| Convex, about $1,308 in gear | $5,000 cash, but it's a second real-time backend. Still skip it (see tracks.md). |
| Moss "Voice AI" fits because Homer is a voice tutor | Moss is sub-10 ms retrieval. It only counts if it does real work: matching formulas live against the streaming transcript. |
| Figma: "five $1,000 gift cards" | **$2,000 Best Figma Workflow, $2,000 Best Stage Log, $500 Best Design, $500 Most Creative.** It needs Figma Slides, a stage log, and Edu verification. |
| Ask whether Devpost caps sponsor tracks | Answered: "nope!" There's no cap. Tag the track on Devpost and meet its criteria. |
| No MLH prizes | MLH has cheap add-ons: Gen AI, .Tech domain (prize includes a desktop mic), Vultr hosting, Commit Fellowship. |

## What we enter

Ranked by value times odds. Every track we enter passes the removal test (if you pull it out, the demo breaks), except process tracks like Figma and MLH tags, which don't need to.

| Tier | Track | Prize | Our odds | Why |
| --- | --- | --- | --- | --- |
| **Core** | Spacetime | $2,048 / $1,024 / $512 cash | **High** | Three places, multiplayer is their first ask, and almost no other team is using it |
| **Core** | Figma (4 prizes) | $2,000 + $2,000 + $500 + $500 | **High if we log** | Process track: "we're not judging on scope or technical difficulty" |
| **Core** | First Overall, Most Creative, People-First, Hacker's Choice, Technically Complex | MacBook / Instax / Watch / mouse / keyboard | Medium on Overall, **high on Creative** | Automatic entry. The experience is our edge. |
| **Core** | Cartesia | Meta glasses | Medium-high | Voice is the product, and now it's measured: 3% word error with the drum at full volume in our tests, using the hand as keyterms (20% without; test recordings, real-mic rerun pending), final transcript in about 75 ms, Homer's first audio in about 100 ms. We still need an answer on impact and responsibility. |
| **Core** | Meta | Round 2 at Menlo Park, travel paid | Medium-high | The battle is "bringing people closer" made literal |
| **Core** | Anthropic | $5k credits, Max 20x for a year, office hours, HQ visit | Medium-low on iOS | The most crowded track. We win it only with a sharply named community, a measured impact number, and a TestFlight public link live by Sunday ("usable Monday"). |
| **Add-on** | MLH Gen AI, .Tech domain, Commit Fellowship | Swag, desktop mic and domain, founder-sprint interview | High per hour spent | A checkbox and a 10-minute domain. The domain redirects to the TestFlight link and the video. |
| **Add-on** | MLH Vultr | M5Stack Tab5 | Medium | Only if Vultr is where we'd host the Python service anyway |
| **If time** | Apify, plus Best Actor | $2,000 / $1,000 / $800 / $400 / $400, plus $400 | Medium (5 places) | Only if an Apify Actor really builds the formula bank in `content/` that the game deals from |
| **Skip** | Moss (now that we're on iOS), Convex, Mana, Elastic, Bitdeer, Bright Data, Microsoft, Hyphenate, Visa, Coinbase, CRS, Capital One, Factory, Fetch, CREAO, Atlassian, SpaceXAI, Notability, ElevenLabs, Presage | | | Reasons in tracks.md |

## The ten moves

Owners are roles. Matus decides who.

| # | When | Move | Owner |
| --- | --- | --- | --- |
| 1 | **Tonight** | Everyone gets **Figma Edu verified** (figma.com/education/apply). It's required for the Figma track and for the booth activation Sat 10-2. | All |
| 2 | **Tonight** | Keep [figma-stage-log.md](figma-stage-log.md) going with honest times. The Stage Log prize goes to "the clearest, most repeatable workflow", and you can't reconstruct that on Sunday. | Matus |
| 3 | **Tonight** | Claim credits: Anthropic $50 per hacker (form in #cohost-anthropic), Cartesia `CARTESIACALHACKS`, and Moss `CALHACKS` / Apify `APIFY_CAL_HACKS` if we go for those. | All |
| 4 | **Tonight** | **Reserve an ethernet cable** in the H@B app for judging, and bring a USB-C ethernet adapter. Venue Wi-Fi is slow and hotspots are banned. | Anyone |
| 5 | **Sat AM** | The poet texts 3-5 poets from their own slam or open-mic scene: "How do you practice between open mics? What's hard?" Get permission to quote them. Anthropic asks for a problem "you've lived... or talked to someone who has." | Poet |
| 6 | **Sat AM** | Cut demo scope to the spine: the turn, a 2-player battle on the arena, Bard lesson 1, and the stitched-song finale. Load the **demo config** from [demo-script.md](demo-script.md). Everything else is optional. | Leader, with Matus approving |
| 6b | **Sat, as early as possible** | **Submit the first stable build for TestFlight external testing** (Beta App Review) so Devpost gets a public "try it" link before Sunday 9 AM. Keep one version number and add builds under it. | iOS lead |
| 6c | **Sat AM** | **Put Figma in the workflow for real.** Right now no Figma file exists (see the artist's stage log). Matus designs the arena and phone screens in Figma Design and connects the Figma MCP so the iOS and art sessions build from the file. Without it there's no Figma Workflow prize. | Matus |
| 7 | **Sat 2-6 PM** | **Booth tour with the app on our iPhones**: Spacetime (Tyler Cloutier, Julien; show them the Swift client), Cartesia (near the big stairs by SpaceX: Grant Timmerman, Vikram, Kelly Arifin), Anthropic (Arinze Obiezue). Sponsor judges who have already played it remember it. | Poet + one builder |
| 8 | **Sat 6-8 PM** | **First-timer study**: 5 hackers who have never improvised do Lesson 1. Record the scanner's Beat score on their first and last attempt. That one real number answers Application, Anthropic's "measure impact", and every "would anyone use this?" question. | Poet |
| 9 | **Sat night** | Submit a Devpost draft (the guide recommends Saturday night). Record the video. Take Homer to **karaoke** with our iPhones and the arena Mac for real battles, and film 15-second clips of the scene reacting. Post them tagging the sponsors; it builds Hacker's Choice buzz. | Matus + poet |
| 10 | **Sun** | Submit by 8:45 with every track tagged. At the table by 10:30 with the whole team, ethernet into the arena Mac, a wired headset mic per poet, a wired speaker, captions on, and the demo config loaded. Rehearse three pitches back to back, since there are 3 judges. | All |

## The one-liner

Frame from SPEC "The games": ancient Greek party games, with the poetry battle as the main event.

> Spoken: **"Ancient Greek party games, like Wii Sports, and the main event is a rap battle judged by Homer."**
> Opener: **"The first word of Western literature is *mēnin*. Rage. Homer opened with a fight, and so do we."**
> Written (Devpost, video, app): **"MeNIN: ancient Greek party games, hosted by Homer. Battle in verse on one screen, with your iPhone as the controller."**

**Name: MeNIN** (μῆνιν, "rage", the first word of the Iliad). Say "MAY-nin" before anyone reads it. Homer hosts the poetry battle and Socrates hosts the debate.

"Wii", "Wii Sports", "Guitar Hero" and "Olympic" are trademarks: say them out loud as comparisons, but never write them in the name, title, tagline or app. Name options for Matus are in [pitch.md](pitch.md).
