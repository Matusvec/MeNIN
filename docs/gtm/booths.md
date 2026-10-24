# Saturday booth plan

**Goal:** every sponsor judge has played MeNIN before Sunday. A judge who's already been roasted by Homer remembers us at the table.

Sources: the Hive schedule and venue map, the Hacker Guide, and each sponsor's Slack channel, read Sat 8 AM. Booth numbers come from the venue map. **There are no official expo hours.** Sponsors post their own, so check their Slack channel before walking over.

## The route

| Time | Where | Who's there | Why now |
| --- | --- | --- | --- |
| **9:45 AM** | **MLH**, upstairs on the Mezzanine (map sponsor-46) | MLH's coach: "I'm at the MLH table upstairs!" (#1-ask-mlh, Sat 6:50 AM) | Right after the 9:15–9:35 discus tuning. Quick, and no demo needed. |
| 10:00–11:30 AM | *Matus is at the Microsoft workshop (10:00–10:45), then the coffee chat (11:00).* | | |
| **11:45 AM** | **Figma, Booth #35**: the coffee cart activation, 10 AM–2 PM | Figma's team | **Matus goes**, since the designer shows the workflow best, and it's before the 12 PM lunch rush. Bring every teammate's Edu verification proof. Their stage log is worth $2,000 on its own. |
| 1–2 PM *(optional)* | Anthropic workshop, Theater: "Building Agents & Multi-Agent Teams with Claude" | Anthropic's track team | Our build is literally a multi-agent team. Catch the track lead afterwards. |
| **2 PM** | *The battle checkpoint (reality-check.md).* The tour below only shows the battle if it passed. If it failed, show Practice Spar on one phone, or skip the tour. | | |
| **2:30 PM** | **Cartesia**, main floor (sponsor-11), "near the big stairs", beside Meta | Cartesia's team | After the checkpoint, so they hear Homer judge a real turn. Hours are unconfirmed; check #spons-cartesia first. |
| 2:45 PM *(optional)* | Meta, main floor (sponsor-06), right next to Cartesia | No staff named. Their workshop is 2–3 PM at Gate 4. | Two booths in one stop |
| **3:30 PM** | **Spacetime**, main floor (sponsor-14), next to Anthropic, or Spacetime's CEO in the Theater ("all weekend") | Spacetime's CEO and team | Before their 4–5 PM workshop in the Theater, while the CEO is free |
| 3:45 PM *(optional)* | Anthropic, main floor (sponsor-13), next to Spacetime | Anthropic's track team | One step over from Spacetime |
| 5:00 PM | Back at the table for the main video shoot ([video.md](video.md)) | | |

**Who goes:** two people. The poet performs, and one more person explains the tech (Matus, or the operator if Matus is designing). The Mac stays at the build table.

**The booth kit:** iPhone C in landscape as the arena, iPhone A as the poet, both on the latest TestFlight build, one pair of wired EarPods and a power bank. Before leaving, run the demo check from the Mac (run-sheet.md). If the room won't come up, show **Practice Spar on one phone**, where the phone is both the arena and the mic.

**Rules at every booth:**
- **Open the app first, talk second.** Hand them the phone within 30 seconds.
- Three minutes per booth, unless they want more.
- Only show what's built. Never promise a feature.
- **Write down** who you met, whether they judge on Sunday, and what they said they want (the log at the bottom). It goes into the table pitch tomorrow.

## What to show at each booth

### MLH (Mezzanine, 9:45 AM)
- **Ask for DigitalOcean credits.** The prize text says to "reach out to your MLH Coach for credits". Our agent service already runs on a DigitalOcean droplet, so ask whether the credits can go on our existing account.
- **Ask for the free .tech domain code**, then register `playmenin.tech` with it. The .Tech prize includes a .tech domain for up to 10 years.
- **Opt in to the Commit Fellowship** category, if the team wants it.
- Show nothing unless asked. If the coach is curious, hand them a phone.

### Figma (Booth #35, 11:45 AM)
- **If Matus's coffee chat runs past 12:15,** a teammate goes instead, by 1:30 PM at the latest (the activation ends at 2). Open the Directions file in the Figma app on a phone, or on the Mac, and use the same talking points.
- **Edu verification first.** Anyone not verified: Figma's team said to give them your email at the booth (#spons-figma, Fri 7:48 PM).
- **Show the file, then the app.** Open "MeNIN · Directions" (figma.com/design/qyaXnV3HbIUPIfYVbyqKwv):
  - One variable collection with two modes, Atelier and Cut paper. Flip the mode and the whole screen changes direction.
  - Every variable carries its Swift name (`Palette.hero`), so one mode switch in Figma matches one launch flag in the app.
  - Then open the app on the phone in the same direction.
- **The line:** "One designer and a team of Claude Code sessions. The art session reads Matus's frames straight from Figma through the MCP, and we log every handoff, including what broke."
- **Ask:**
  - "What makes a stage log win?"
  - "In the Slides deck, do you want the full log or 200 words per stage?"
- Log the visit in [figma-stage-log.md](figma-stage-log.md).

### Cartesia (sponsor-11, 2:30 PM)
- **Show the keyterms live.** With the drum on, the poet speaks a formula from the hand ("the wine-dark sea"), and the live transcript catches it. Then Homer delivers the verdict in Carl's voice.
- **The line:** "We feed your hand to the recognizer, so it hears the wine-dark sea through the drum. In our tests, with the drum at full volume, that's 3% word error with ink-2 keyterms and 20% without. The final transcript lands about 75 ms after you stop, and Homer's first audio comes in about 100 ms." If debate passed by then, play 10 s of Socrates, the second voice.
- **Ask:**
  - "How many winners are there, and what does great 'impact and responsibility' look like to you?"
  - **"Does Cartesia keep STT audio or transcripts, and can we turn that off?"** The answer fills the privacy line on Devpost.
  - "Our numbers come from test recordings. Is a real-mic test in a loud room what you'd want to see?"
- Their brief asks for "a 2-minute, demo-first presentation: one complete user flow, then a brief problem + how you built it", so the table script already fits.

### Meta (sponsor-06, optional)
- **Show** two people answering each other in verse, then the stitched song.
- **The line:** "Party games for one room. The judge literally scores how well you answer the person before you."
- **Ask:** "Who judges the Meta track on Sunday?"

### Spacetime (sponsor-14 or the Theater, 3:30 PM)
- **Show the Swift client live.** A phone joins the room and the arena reacts at once. Then the scene moving with the poet's voice, which is the 20 Hz stream into one table the arena subscribes to.
- **The line:** "The whole battle is a phase machine in reducers, from the lobby to the crown, with a scheduled reducer for the turn timer. Your hand is in a private table only your phone can read. The iPhone client is the community Swift SDK, and we patched it. Upstream, every client subscribes to whole tables, so every phone got every room's voice stream. Now each phone subscribes to its own room."
- **The CEO will care about the patches.** Ask whether they'd want them upstream.
- **Ask:** "What would make this a top-three Spacetime project for you?" Write the answer down and tell leader.
- **Credits:** `spacetimedb.com/redeem?code=CALHACKS13` (#cohost-spacetime, Sat 12:10 AM, Spacetime staff).

### Anthropic (sponsor-13, optional)
- **Show** a verdict, then point at the five scores: "Beat is a deterministic stress scanner, not Claude's opinion. Claude scores the rest with your hand and the verse you answered in front of it."
- **The line:** "For slam poets, who practice alone between weekly open mics. Tonight we run a first-timer study for one real number. And the app itself is built by a team of Claude Code sessions."
- **Ask:** "Is our community narrow enough?" Their track is "Claude for Public Benefit", and it wants a named community, a real problem, a working product with impact measured, and meaningful use of Claude.

## Booth log (fill in as you go)

| Time | Booth | Who we met | Judging Sunday? | What they want | Follow-up |
| --- | --- | --- | --- | --- | --- |
| | MLH | | | | |
| | Figma | | | | |
| | Cartesia | | | | |
| | Spacetime | | | | |
| | | | | | |

## Saturday's other times, for reference

- **Meals** (Annapurna Labs, by boarding group): breakfast 8–9:30, lunch 12–1:30, dinner 6–7:30. The study runs 6–8 PM, so the poet eats before it.
- **Workshops:** Anthropic 1 PM (Theater), Meta 2 PM (Gate 4), SpacetimeDB 4 PM (Theater)
- **Karaoke:** 8–9:30 PM in the Theater
- **Scrabblebot finals** (Spacetime): midnight in the Theater
- **Mentors:** the queue at hive.hackberkeley.org/mentorship-queue. There are no scheduled office hours.
