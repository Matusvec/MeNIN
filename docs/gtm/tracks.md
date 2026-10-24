# Tracks: what we enter and how we win each

Ground rules, confirmed in #0-ask-directors:

- **No cap on tracks.** "nope!" Enter a track by tagging it on Devpost; there's no separate signup. Main prizes are automatic.
- "Please make sure that you have followed the judging criteria for the sponsor tracks in order to sign up for them."
- Only one project per team.
- Judging is **Sun 10:30 to 12:30**, with **3 judges** per project, a mix of sponsor and Cal Hacks judges. Tables are shared by 2-3 teams. The guide recommends **a two-minute pitch**, and a **live demo is required**. **The whole team has to be present** or we don't get judged.
- Sponsors may judge asynchronously from the Devpost video, so the video counts as much as the table.

Since going iOS-only (SPEC `dc4363b`), the judges and other hackers can't install the app at the table. They watch on the arena, or play on our phones. The public way in is a TestFlight link, which needs Apple's beta review to approve it first.

## Re-score after the party-games frame (SPEC "The games", `41bece4`)

Events: the poetry battle (core); Socratic debate and discus (in build now, SPEC `2fb21bf`; each reaches the demo only if it runs 5 times in a row without failing by Sat 8 PM); the rest as locked tiles.

**Original soundtrack (SPEC "Music", `2fb21bf`):** **no prize at Cal Hacks rewards original music.** I checked all 58 prizes on Hive. The only music mentions are AI generation: MLH Gemini ("generate creative content like code, scripts, music") and MLH ElevenLabs. Both are wrong for us, because our score is human-made and ElevenLabs competes with Cartesia. The score still earns its place:
- **Most Creative** and the main **Creativity** criterion: one more unexpected layer, and it's ours.
- **Hacker's Choice:** the fanfare and the champion sting make a room cheer.
- **Intentionality** ("every design choice should feel purposeful"): the music never plays under a speaking poet, and it ducks under Homer.
- **The video:** we own the music, so YouTube won't mute or claim it.
- **Cartesia**'s "Voice clear?": the score gets out of Homer's way. Say that in the README.
Credit the composer by name everywhere, and state honestly how the score was made.

| Track | Before | Now | Why | Condition |
| --- | --- | --- | --- | --- |
| **Hacker's Choice** | Down (iOS reach) | **Up** | Discus is a zero-skill hook: anyone can swing a phone, then stay for the battle. Party games are what hackers actually play at 1 AM. | Discus ships. Still capped by iOS: hackers play on our devices or through TestFlight. |
| **Most Creative** | High | **Higher** | A rap battle judged by Homer, a debate hosted by Socrates and a discus thrown with your phone, all in one product. Nobody else has this. | The poetry battle stays the spine. The frame alone isn't the creativity. |
| **Meta** | Medium-high | **High** | One screen, one room, everyone's phone a controller: party games are the clearest possible "bringing people closer". | The battle works live |
| **Cartesia** | Medium-high | **High, if debate ships** | Their own idea, "Multi-speaker agent: tutor, debate partner... with distinct voices", is now literal: Homer (Carl, "Steady Storyteller": calm depth) and Socrates (quick, wry, questioning) are two distinct Cartesia voices, one of them a debate host. | Socrates ships with his own voice. Otherwise unchanged: Homer as MC, coach and announcer. |
| **Most Technically Complex** | Medium | **Up slightly** | Several events from one engine config, plus Core Motion physics alongside the real-time voice stack | Don't claim events that didn't ship |
| **Spacetime** | High | **Up slightly** | More shared state ("games" is their first example). Discus throws become reducer events that every screen sees at once. | Same Swift-client smoke test |
| **First Overall** | Medium | **Up** | "Like Wii Sports" makes the product clear to any judge in 3 seconds, and that legibility matters at a 2-minute table. | Functionality holds; nothing half-working is shown |
| **Anthropic** | Medium-low | **Slight risk** | A party frame can read as entertainment, not public benefit. Keep the Anthropic story on slam poets and Bard-mode training; the games are why people come back. Don't split the named community (debaters are a "what's next", not a second community). | The first-timer number exists |
| **Figma** | Unchanged | Unchanged | The event menu and locked tiles add a design surface worth logging | Figma is actually used |

**The cost:** the "spread thin" critique the organizers warned about. The guard rules are in [pitch.md](pitch.md): at least 80% of the demo is the poetry battle, and an event that isn't solid stays a locked tile.

---

## Core tracks

### Spacetime: Best Use of Spacetime
**Prize:** $2,048 / $1,024 / $512 cash (three places). Cohost.

**What they asked for:**
> "projects where Spacetime is the core real-time backend, especially anything with live shared state, multiplayer interaction, or instant sync between users/agents/systems... great fit not just for games, but also... social experiences... The main thing we'd want is for SpacetimeDB to be meaningfully used, not just added on the side."

**How MeNIN hits it:**
- The arena-plus-phones battle is SpacetimeDB.
- Rooms, turn order, the timer, scores, totals, the winner and the carved best line all live in tables. They're decided in **reducers, server-side**, not on any one device.
- Each phone streams loudness and pitch at about 20 Hz into a table the arena subscribes to, so the scene moves with whoever is speaking. That's "instant sync between users" you can see.
- The emotion vector, every ~1.5 s, goes to the same place.

**Make it undeniable:**
1. Move all battle bookkeeping into reducers. `homer/battle.py` does it in Python today, and it belongs in `spacetime/`.
2. Show the ~20 Hz voice stream in the pitch.
3. Say "zero sync code" in the pitch.

**iOS note:** the Swift client is community-built (for example `avias8/spacetimedb-swift`, v0.21, iOS 17+). I found no official Swift SDK. Smoke-test two phones and the arena before anyone sleeps. Tell Spacetime's team at the booth that we're on Swift, since it's novel and they may help.

**People:** Spacetime's CEO is onsite. Route and times: [booths.md](booths.md).
**Side quest:** the separate Scrabblebot tournament ($1,024 / $512 / $256) is Sat 11:59 PM in the Theater, signup at scrabblebot.spacetimedb.com. Only enter it if a spare Claude session can build the bot without pulling a human off the critical path.

---

### Figma: Idea to Demo (4 prizes)
**Prizes:**
- **Best Figma Workflow, $2,000**
- **Best Stage Log, $2,000**
- Best Design, $500
- Most Creative, $500
- Every winner also gets a session with Figma's Early Career Recruiter.

**What they asked for** (track doc):
> "we're not judging on scope or technical difficulty. We care most about a clear problem, an honest account of how you built it and a demo that works."

Criteria: Workflow Design, Adoptability ("a measurable before and after"), Output Quality, Presentation, Innovation & Creativity.

**What to submit:**
- [ ] Figma Slides (required) with a stage log, 200 words max per stage, covering Ideation, Prototyping, Handoff and Code generation. For each stage: the tool and why, minutes spent, a 1-5 rating, and how the output got into the build.
- [ ] Demo video, 3 min max
- [x] A prototype to embed: "Prototype · Atelier" in "MeNIN · Directions", two flows (artist, Sat AM)
- [ ] The prototype and the Directions file embedded in the deck, plus the repo link (it works once the repo goes public Sun 8 AM)
- [x] "MeNIN · Directions" shared as Anyone with the link → can view (Matus, Sat AM)
- [ ] The deck and any FigJam file also shared with "Anyone"
- [ ] **Every teammate Edu verified** at figma.com/education/apply

**How MeNIN hits it:** one designer plus a team of Claude Code sessions, with Figma as the source of truth between them. That's a workflow another team could copy, which is what "Adoptability" means.

**Where we are (Sat AM):** the workflow is real now.
- Matus drew the concept in Figma Design. The art session reads it through the Figma MCP, building from the file rather than from screenshots.
- "MeNIN · Directions" holds both design directions in one variable collection with two modes, and every variable carries its Swift name.
- The artist built two clickable prototype flows on the "Prototype · Atelier" page, bound to the same tokens.
- The file is shared with Anyone. The stage log has seven entries, with honest friction in each.

**The Figma Slides deck plan.** Duplicate Figma's example deck (figma.com/slides/hViyGFvaHxTBqzYKkaYPho). Artist drafts it through the Figma MCP from [figma-stage-log.md](figma-stage-log.md), and Matus edits.

| # | Slide | Content |
| --- | --- | --- |
| 1 | Title | MeNIN: ancient Greek party games, hosted by Homer. Team. |
| 2 | The problem | Poets practice alone between weekly open mics. One sentence. |
| 3 | The workflow | One designer plus a team of Claude Code sessions, with Figma as the handoff between them. Reuse the FigJam how-it's-built diagram from [video.md](video.md). |
| 4–7 | The stage log | One slide each for Ideation, Prototyping, Handoff and Code generation, **200 words max each**: the tool and why, minutes, a 1–5 rating, what made it in, and the friction. Pull from the log's entries; keep the dead ends (glow → matte, web → iOS). |
| 8 | The prototype | **Embed the "Prototype · Atelier" flows**: "1 · First open → Practice" and "2 · Battle: join → arena → champion" |
| 9 | Two directions, one switch | **Embed the Directions file.** One mode switch flips Atelier ↔ Cut paper, and every token has its Swift name. |
| 10 | Before and after (Adoptability) | Comparing directions went from two code branches plus a rebuild per screen to one mode switch in Figma or one launch flag in the app. Add minutes from frame to component, and rework rounds, from the log. |
| 11 | The demo | Embed the 2:00 video (under Figma's 3-minute cap) |
| 12 | Links | The repo (public from Sun 8 AM), Devpost, TestFlight |

**When:** a draft Sat afternoon, after asking Figma's team at the 11:45 booth visit what makes a stage log win. Final at Sat 11 PM, once the video is embedded. Share the deck as Anyone can view, and link it on Devpost.

**Log:** [figma-stage-log.md](figma-stage-log.md).
**Booth:** #35, with an activation Sat 10 AM to 2 PM; bring proof of Edu verification. People: Figma's booth team.

---

### Cal Hacks main prizes (automatic)
| Prize | Item | Our angle |
| --- | --- | --- |
| **First Overall** | MacBook Air 13" M5 | Ancient Greek party games that anyone gets in 3 seconds, with a poetry battle that judges remember |
| Second Overall | Nintendo Switch 2 | |
| Third Overall | Google Intelligent Eyewear | |
| **Most Creative Hack** | Instax camera plus film | Our strongest main-track bet. Nothing like it is in the field. |
| **Most Technically Complex** | NuPhy Air60 HE | Real-time multiplayer on SpacetimeDB, streaming STT biased by the poet's hand (3% word error with the drum at full volume in our tests, 20% without), on-device onset detection for the beat lane, TTS, Metal shaders driven by live audio, a deterministic stress scanner, a Claude judge under 3 s |
| **Best People-First Hack** | Apple Watch SE 3 | Practicing to speak in front of people, with friends |
| **Hacker's Choice** | Logitech MX Master 4 | Discus as the hook (if shipped), then the battle. Hackers play on our phones Saturday night, at the table and at karaoke. |

**Main criteria** (Wallace, #0-ask-directors): Application, Intentionality, Functionality, Creativity, Technical Complexity. How we hit each one is in [pitch.md](pitch.md).

---

### Cartesia: Best Use of Cartesia
**Prize:** Meta glasses ("still TBD"). The number of winners isn't stated; ask at the booth.

**What they asked for:**
> "Build a useful voice experience with Cartesia. Voice should be core to the product–not just a feature added for the demo... make clear what Cartesia contributes... We'll favor a strong working prototype over a large unfinished idea."

**Criteria, 25% each:**
- Problem and originality
- Use of Cartesia: "Voice clear, responsive, and natural?"
- Execution: "Likely edge cases handled?"
- **Impact and responsibility**: "Accessibility, privacy, and responsible use considered?"

Their own idea list includes "**Multi-speaker agent**: tutor, debate partner... with distinct voices" and "**Live coach**: low-latency back-and-forth where voice quality matters." That's us, and literally so if the Socratic debate ships. Then Homer and Socrates are two distinct Cartesia voices, and Socrates is a debate host. Homer is Carl, "Steady Storyteller" (older, calm, measured), so pick Socrates' voice to contrast: quicker, wry and conversational. Name both voice choices in the README.

**Our measured numbers (from swift; quote them as they are):**
- **STT:** ink-2, with the poet's hand of formulas sent as keyterms, gets a **3% word error rate even with the drum at full volume (0 dB)**. Without keyterms it's **20%**. These come from test recordings (a four-line verse with the drum mixed in digitally), not a real iPhone mic. Say "with the drum at full volume in our tests". Asked how we measured: "On test recordings with our drum mixed in at full volume. The real-mic test in the hall is Saturday night." swift reruns on a real iPhone mic once the agent is public, and those numbers replace these if they differ. The line: "We feed your hand to the recognizer, so it hears the wine-dark sea through the drum."
- **The final transcript** arrives about **75 ms** after the poet stops.
- **Homer's voice** (Carl, sonic-3.6): first audio in about **100 ms**.
- **The beat lane is not Cartesia.** Its timing comes from onsets detected on the phone, not STT timestamps. Never credit STT for the lane.

These hit "Voice clear, responsive, and natural?" directly. The keyterm trick is also our answer to "Likely edge cases handled?": the rare compounds the game runs on ("whale-road", "rose-fingered Dawn") are exactly what a recognizer mangles.

**What to submit:**
- [ ] A 2-minute, **demo-first** presentation: "one complete user flow, then a brief problem + how you built it". This is our video and our table script.
- [ ] A README section covering **setup** (XcodeGen, signing, `.env`), **the Cartesia features used** (ink-2 streaming STT over WebSocket with the hand as keyterms, plus the 3%-vs-20% number and how it was measured; sonic-3.6 TTS as Carl for Homer's voice, the whisper and the stitched song), and **known limitations** (noise, accents, names)
- [ ] Source access, with no keys in the repo

**Impact and responsibility is our weak quarter. Fix it with true statements:**
- Captions on everything Homer says (accessibility, and it helps in a loud hall)
- Push-to-talk, so the mic is only open when you choose
- A PG name filter before TTS speaks names (already in ux-flow)
- What we store: decide it, then say it. My proposal: no audio stored, transcripts kept only for the room's lifetime. Only claim this once it's true.

**People:** Cartesia's team. Booth "near SpaceX, behind all the chairs", "Near the big stairs".
**Code:** `CARTESIACALHACKS` (a month of the startup plan). Docs: docs.cartesia.ai/calhacks

---

### Meta: Bringing People Closer Together with AI
**Prize:** an invitation to Round 2 at Meta's Menlo Park campus, with travel and accommodations, plus a swag bag. "advancement subject to eligibility verification and compliance with Meta's Round 2 Official Rules"

**Criteria:**
> "how meaningfully they strengthen human connection, how essential and well-integrated AI is, originality, and the strength of the working demo."

**How MeNIN hits it:**
- **Party games for one room:** one screen, everyone's phone a controller. That's the most literal "bringing people closer" format there is.
- **Human connection:** people in one room answering each other out loud. The Answer axis literally scores responding to the person before you. The stitched song turns the room into co-authors.
- **AI is essential:** Homer is the MC, the judge, the coach and the stitcher. Take him out and there's no game.
- **Originality:** see the field. **Demo:** the table script.

No Meta staff have posted in Slack. Their workshop is "From Chatbots to Agent Teams: Agentic Engineering at Meta" (time on the live site); go and find them there.

---

### Anthropic: Claude for Public Benefit
**Prize:** $5,000 in Claude credits, a year of Claude Max 20x for the team, office hours with the Applied AI team, and an invite to visit Anthropic HQ.

**Criteria.** Two versions exist; satisfy both.

Slack (#cohost-anthropic, Fri 4:37 PM, Anthropic staff; the newer one):
1. "A named community: 'Students' is too broad."
2. "A real problem: You've lived it or you've talked to someone who has."
3. "A working high-impact product... It should also be clear **how you plan to measure its impact** on your target community"
4. "Thoughtful use of Claude: Claude is used meaningfully in the **product's development and functioning**."

Also: "we'll prefer if you built things more creative".

Hacker Guide and Hive add: "One thing done well and usable on Monday beats a broad demo" and "you know where it could go wrong for the people using it."

**Our answers:**
1. **Community:** spoken-word and slam poets between open mics. Name the poet's own scene specifically. "Poets" alone is too broad.
2. **Problem:** "Open mics are weekly. Between them you practice alone, and nobody can tell you if your beat landed." The poet has lived it. Add quotes from 3-5 poets texted Saturday morning, with their permission.
3. **Works, and impact is measured:** the scanner's Beat score is an objective skill measure. Run the **first-timer study** Saturday evening: 5 people, Lesson 1, Beat score on their first and last try. Then commit to one Monday metric: Beat accuracy across a poet's first 5 sessions.
4. **Claude in functioning and development:**
   - Functioning: Claude is the judge (with scanner output, the hand and the previous verse), the coach (lesson feedback, the freeze whisper), the MC, and the stitcher.
   - Development: the app is built by a team of Claude Code sessions: leader, pm, artist, multiplayer, iOS and gtm.
5. **Failure modes** (state them in the Devpost):
   - STT misses in noise. Keyterms from the hand cut word errors from 20% to 3% with the drum at full volume in our tests, and the transcript is always shown
   - Taste is contestable, so we show five axes and the quoted line
   - Emotion reading is approximate, so the scene is art, not a diagnosis, and never names your emotion
   - English stress has edge cases with names and slang, so the scanner flags uncertain syllables instead of marking them wrong
   - A judge that roasts could sting a nervous beginner, so roasts stay gentle and only in Battle; Bard is a calm coach
6. **"Usable Monday" on iOS:** a TestFlight public link, if Apple's beta review approves it before Sunday. Say "any iPhone", not "anyone". Without a public link, this criterion is weak.

**People:** Anthropic's track lead (who also runs credits), their team, and at least one Anthropic judge.
**Credits:** $50 per hacker through the form in #cohost-anthropic. It goes to the Console, not claude.ai.

---

## Cheap add-ons (MLH)

| Prize | Item | What it takes | Do it? |
| --- | --- | --- | --- |
| Best Use of Gen AI | Assorted | Uses a public GenAI API (Anthropic counts). Tag it. | **Yes**, it's free |
| Best .Tech Domain Name | **Desktop microphone** and a .tech domain for 10 years | Register a .tech domain and use it. Redirect it to the TestFlight link and video. Domain: **`playmenin.tech`**, used only for this prize (the agent service runs at an `sslip.io` address on DigitalOcean and needs no domain). `menin.tech` is reserved by the .tech registry. Available fallbacks: `meninthegame.tech`, `meningames.tech`. Pending Matus registering it. | **Yes**, 10 minutes |
| Commit Fellowship | Interview for a 3-week founder sprint, plus *The Lean Startup* | "working prototype with a team, demonstrate a real problem worth solving, opt into the Commit Fellowship Prize Category" | **Yes**, if the team might continue after Sunday |
| Best Use of DigitalOcean | Retro wireless mouse, "for you and each of your teammates" | The Python agent service runs on DigitalOcean (Matus's pick). Credits come through the MLH coach: "reach out to your MLH Coach for credits". | **Yes**, it's free since we host there anyway. Name DigitalOcean in the Devpost and README. |
| GoDaddy Registry domain | Digital gift card | Register a GoDaddy Registry domain | Skip; one domain is enough |

---

## If someone is idle

### Apify: Best Use of Apify, plus Best Actor
**Prizes:** $2,000 / $1,000 / $800 / $400 / $400 (five places), plus **Best Actor, $400**.

**Criteria:** "Project must be using Apify in a meaningful way." Best Actor is "for building an actor for this event".

**The honest version:** a public Apify Actor ("Epithet Miner") crawls public-domain epic and ballad text on Gutenberg and Perseus. It extracts noun-epithet formulas with their stress shape (CMU dictionary) and writes the bank in `content/` that every hand is dealt from. Without it, there's no formula bank.

**The weak spot:** it's build-time, not live. Say so, and point out that scraping is what Apify is for.

Only do it if the bank isn't otherwise being built. A teammate hand-writing 200 formulas is also fine.

**Workshop:** Sat 11-12, Breakout 3. Coupon `APIFY_CAL_HACKS` ($200). Person: Petros Hong.

---

## Skip (and why, for when someone asks)

| Track | Prize | Why not |
| --- | --- | --- |
| Moss | AirPods Pro/Max, plus a social-post prize | Now that we're iOS-only, its Python and JS SDKs would sit behind a network hop in the Python service, and on-device matching does the formula detection. A bolt-on. |
| Convex | $5,000 | A second real-time backend next to SpacetimeDB. That's the bolt-on judges smell, and SPEC caps us at three deployables. |
| Mana | $5,000 | They judge "Meaningful use of Mana (30%)" during the build, plus a bonus for living inside Mana. We build with Claude Code, so faking it would be BS. |
| Elastic | Quest 3S / Bose | No criteria were ever posted, and search over the formula bank would be a bolt-on |
| Bitdeer | $500 credits + mice | It would replace a Claude role or add embeddings we don't need |
| Bright Data | $1,500 credits + $500 card | Needs live public web data at the core; the bank is static. They disqualify mocked data. |
| Microsoft | Surface per member | "production-minded AI agent... finance, productivity, healthcare". Keep it as a recruiting chat (Sat 10:00 workshop, 11:00 coffee). |
| Hyphenate | $8k / $5k / $3k | Finance only |
| Visa, Coinbase, CRS, Capital One | various | Payments and credit |
| Factory | $2,000 | The Droid SDK has to "do real work in the running product", and Homer has no code-work surface |
| Fetch.ai | $1,250 top | Register on Agentverse and use the chat protocol. That drops voice. |
| CREAO | $2,500 top | "Runs take minutes... no live token streaming", so it can't power a live judge |
| Atlassian, SpaceXAI, Armadin | various | Wrong domain. SpaceXAI also requires Cursor plus Grok Voice. |
| Notability | 1 year of Pro | Process notes in Notability; the Figma log already covers our process |
| MLH ElevenLabs | earbuds | It competes with Cartesia, our core voice |
| MLH Presage | Fitbit | Emotion from the camera is scope creep; our scene reads the voice |

## Freebies that cost no build time
Do these during downtime only, never instead of building:

- **Fetch.ai asi1.ai mini-challenges**, about 10 minutes each. Prizes: Meta glasses, Instax, Beats (5 winners each), plus a trip for finishing all three. The "AI Investor" challenge is just pitching Homer.
- **ASUS survey** (ROG tool set)
- **Greptile credits**, at the link in #spons-greptile; one redemption per team
