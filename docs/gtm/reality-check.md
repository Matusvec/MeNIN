# Reality check: are we building BS?

Written Fri Oct 23, 11:30 PM, against SPEC.md at `77e0506`. Updated Sat Oct 24, about 2 AM, for `2fb21bf` (debate and discus in build now; an original soundtrack). I'll re-run it at each checkpoint below.

## Verdict

**Not BS. The idea is the strongest thing we have.** What would make us lose isn't the idea. It's shipping a broad, half-working version of it, or a judge that takes 30 seconds to talk.

## What's real (keep it, lean on it)

| Claim | Evidence |
| --- | --- |
| Nobody else is doing this | In #1-team-formation, "agent" appears 41 times, "hardware" 31, "robot" 24, "health" 18 and "fintech" 7. "Poetry", "rap", "music", "multiplayer" and "spacetime" each appear 0 times. A workspace search for "poetry" and "freestyle" returns nothing. |
| The demo is an experience, not a slideshow | Two people battle in verse, the room paints their voices, an MC judges, and the battle gets stitched into a song. Judges remember that table. |
| The intellectual spine is real | Parry and Lord's recordings of Balkan bards are the real history of how Homer composed. The four-beat line is how Beowulf and rap bars both work. |
| The sponsors fit naturally | Spacetime leads with "multiplayer interaction". Cartesia's idea list includes "tutor, debate partner... with distinct voices". Meta asks for "strengthen human connection". Figma's track rewards process, not scope. |
| The spec is now sharp | Arena plus phones, the freeze rescue, epithet battle names, the carved line, the stitched song, demo mode, captions, and the haptic beat with drum ducking. Every one of those is a demo moment. |

## What's at risk, ranked by how much it could cost us

### 1. `homer/` doesn't match the spec, and its judge is too slow for a live turn
The agent service was written before SPEC.md and drifts on almost every axis:

| SPEC says | `homer/` does | Where |
| --- | --- | --- |
| Four-beat line by default; "no jargon", never "iamb", "scansion" or "meter" | Judges **iambic pentameter**, with "scansion notation" in every reply | `homer/prompts/persona.md:3`, `homer/prompts/judge.md:3,16` |
| A pro coach in lessons, a title-fight MC in battle; short sentences | "Warm, theatrical, wise... a chat window", with long structured reports (per-line scansion, deviations, revisions) | `homer/prompts/persona.md`, `homer/prompts/judge.md` |
| Lessons: the beat, the formula, the epithet | A 12-step academic curriculum: syllables, iamb, feet, notation, spondees, elision... | `homer/state.py:17` |
| Five axes: Beat (from the scanner), Craft, Image, Answer, Range | Four axes: metrical_accuracy (Claude's call), naturalness, imagery_diction, overall_craft | `homer/tools.py:18` |
| Judge each verse with the previous verse in view (the Answer axis) | Batch-judges a round of **shuffled, anonymised** entries, so nothing can be scored as an answer | `homer/prompts/battle.md:3,11` |
| A verdict that starts about 3 s after the turn (ux-flow latency budget) | `claude-opus-5-5`, adaptive thinking at **high** effort, up to 12 tool rounds, 16k max tokens, long prose | `homer/agent.py:19-22,170` |
| FastAPI service | CLI only; no HTTP layer | `homer/` |

**What's worth keeping:**
- The CMU-dictionary lookup and stress lean in `scansion.py`. Counting four stresses is simpler than fitting iambs, so the hard part is already done.
- The prompt-injection wrapping (`wrap_submission`).
- The strict tool schemas and the validator pattern.
- The offline test harness.

**The fix** (it belongs to whoever owns `homer/`; the leader should route it):
- **A fast judge path.** One call, no extended thinking or low effort, with the scanner's output passed into the prompt (not a tool loop), strict JSON (`craft`, `image`, `answer`, `best_line`, `verdict`), under about 80 output tokens, and streamed so TTS can start on `verdict`. Put the rubric, the hand and the previous verse in a cached prefix. **Measure p50 and p95**, with the target from ux-flow: Claude done by 2.2 s.
- **A Beat score from the scanner:** stresses per line against 4, plus whether there's a break in the middle. Never ask Claude.
- **Rewrite the persona** to SPEC's voice: coach in lessons, MC in battle, no jargon, two sentences maximum.
- **Replace the curriculum** with lessons 1 to 3 from SPEC.
- **Battle bookkeeping** (turn order, totals, winner, ties) **moves into SpacetimeDB reducers**. It makes the Spacetime track undeniable, and the Python service then only judges.
- **Add the stitched-song endpoint:** one call that takes the battle's verses and returns about 4 lines, started as soon as the last transcript is final.

### 2. Scope
Four sponsors and the organizers said it in writing; their quotes are in [README.md](README.md). What has to work for the 2-minute demo:

**Must work:**
- The turn, with the beat, the beat lane, the freeze rescue, the scene and the spoken verdict
- A 2-poet battle on the arena, in demo mode
- The carved line
- The stitched song
- Bard lesson 1, which is where the first-timer study number comes from

**Nice to have:** lessons 2 and 3, the hoard, the epithet entrance, Practice Spar (it's the fallback, so it ranks above the other nice-to-haves).

**Not this weekend:** ranks, spectators, Homer mode, lessons 4 to 6, the benchmark (see 3), and any sponsor we don't truly use. *(Apify did happen after all, the honest way: a build-time Actor off the demo path, with a person reviewing its output. See [opportunities.md](opportunities.md).)*

SPEC's "never cut" list includes Bard lessons 1 to 3. My proposal to Matus: protect lesson 1 at all costs and treat 2 and 3 as the first things to finish after the battle works.

### 3. The benchmark is a likely dud, so replace it with a human number
The plan's "raw Claude vs scaffolded Claude on meter accuracy, 50 prompts" chart has two problems:
- **Four stresses per line is easy.** Raw Claude may already land it, and a flat chart is worse than no chart.
- **It measures Homer's verses, not the user's growth.** None of the five criteria rewards it directly.

**Run instead: the first-timer study** (Sat 6-8 PM, about an hour). Five hackers who've never freestyled do Lesson 1, and we record the scanner's Beat score on their first and last try. It's real data, it answers Application and Anthropic's "measure its impact", and it closes the pitch. Only run the benchmark if a 15-minute pilot shows a real gap.

### 4. Figma isn't in the workflow yet
The artist's stage log says no Figma file exists, because the session had no Figma connector. Without real Figma use, the $2,000 Workflow prize is out, and the Stage Log prize gets much weaker. **Fix it Saturday morning:** Matus designs the arena and phone screens in Figma Design, and the sessions build from them through the Figma MCP.

### 5. Going iOS-only: reach and dependency risk
It was Matus's call, and it buys real things: the haptic beat, native audio, and no autoplay tap. The risks:

| Risk | Mitigation |
| --- | --- |
| The SpacetimeDB Swift client is community-built, not official | A two-phone smoke test before anyone sleeps (now a hard checkpoint). Show Spacetime's team at the booth. |
| The TestFlight public link needs Apple's beta review, and "usable Monday" depends on it | Submit the first stable build Saturday morning. Have a fallback line ready for Q&A. |
| Judges and hackers can't just open a link | The judges were never going to join in 2 minutes anyway. For Hacker's Choice, run battles on our phones. |
| The web scene work was thrown away mid-build | The artist reports the shader math carries over to Metal. Log the friction (it's good for the Figma log). |

### 6. Noise in the judging hall
Tables are shared by 2-3 teams. Wired headset mics, the hands-free mic that opens only on your turn, free-verse battles with no drum under a speaking poet (SPEC 5fb8baf), and captions are all in SPEC now. **Test them in the hall at peak noise on Saturday night.** Until that test passes, the Q&A line "works in this noise" is unproven.

swift's measurement helps: ink-2 with the hand as keyterms gets 3% word error with the drum at full volume (0 dB), versus 20% without. That proves the drum and the keyterms, not the hall. It came from test recordings (a four-line verse with a synthetic drum mixed in digitally, not a real iPhone mic), which docs/voice.md calls an optimistic lower bound. Quote it as "with the drum at full volume in our tests", never as "in a loud hall". swift reruns on a real iPhone mic once the agent is public, and those numbers replace these if they differ.

### 7. The party-games frame (SPEC "The games", `41bece4`)
**Good call for winning, with one condition.** "Like Wii Sports" makes the product clear to a judge in 3 seconds, and it lifts Most Creative, Hacker's Choice, Meta and Cartesia (two distinct host voices). The danger is the organizers' warning: "a project spread thin with too many features is harder to implement." The guard:
- Debate and discus are in build now (Matus's call, SPEC `2fb21bf`). They reach the demo **only** by passing the Sat 8 PM check (5 runs in a row without a failure), and SPEC still puts them first in the cut order.
- At least 80% of the demo is the poetry battle.
- Anything not solid stays a locked tile. Never demo a half-working event.
- Discus has no voice and no Claude, so it's cheap. **It passed its check early: 5 of 5 clean real-phone runs on the website (16:46–16:49 PM, build 18) plus 5 scripted runs, throws of 19.8 to 66.9 m, one real foul handled, no stalls or drops (leader, Sat ~4:50 PM), and it's unlocked in SPEC.** It's the best judge moment we have after the battle.

### 8. The original soundtrack (SPEC "Music", `2fb21bf`)
**Not BS:** a human-made score is rare at a hackathon, it lifts Most Creative and Hacker's Choice, and it keeps the video safe from copyright claims. The risks are small and already handled in SPEC: no music under a speaking poet, and the music ducks under Homer. Two things to watch:
- Its level in the hall. Set it in the Sat 9 PM noise test with the beat, so it never covers Homer's verdict.
- Event intros must never delay a turn or the theme cards. Judges get 2 minutes.

## The removal test, per track (would the demo break without it?)

| Track | Remove it and... | Verdict |
| --- | --- | --- |
| SpacetimeDB | There's no shared hall: no turns, no arena, no voice stream | Load-bearing |
| Cartesia | Nobody hears you and Homer has no voice | Load-bearing |
| Claude | There's no judge, no coach, no MC and no song | Load-bearing |
| Meta (theme) | N/A; it's the product's purpose | Fits |
| Figma | Process track; it only needs to be really used | Fits **once Figma is actually used** |
| Apify | The demo runs fine; only the bank's origin changes | Build-time only. Be honest about that. |
| Moss, Convex, Mana, Elastic, Bitdeer, Bright Data | Nothing changes | Bolt-on. Skipped. |

## Checkpoints (go or no-go, posted to the leader)

| When | Check | If it fails |
| --- | --- | --- |
| Before anyone sleeps (Fri night) | Two iPhones and the arena in one SpacetimeDB room; turns advance | Debug the Swift client first thing Saturday. Ask the Spacetime booth at 9 AM. |
| Sat 10 AM | The fast judge path, turn end to verdict text: p50 ≤ 2.5 s, p95 ≤ 4 s | Drop to a smaller model and cut output tokens. Never fake a verdict. |
| ~~Sat 1:30 PM~~ **Sat 5:00 PM** (Matus deferred it; it's now the video shoot) | A full demo-mode battle on the arena, end to end, with spoken verdicts, on two real phones running build 18 (0.1.0, `202610241606`) plus the website, with Cartesia working (go/no-go at 4:45; else 5:30, then 8:20), **on Moss-dealt phrases** (the dealer is on for judging). Take 2 includes one phone force-quitting and rejoining. Debate and discus are already in build; this is still the check that matters most. | Freeze features. Everyone on debate and discus moves to the battle until it passes. |
| Sat 8 PM | Debate runs 5 times in a row without a failure (**discus already passed**, Sat 4:46–4:49 PM, 5 of 5 on build 18) | Debate goes back to a locked tile for the demo |
| Sat 8 PM | First-timer study done (6–8 PM, run by the poet, `docs/study.md`): Beat score, first try vs last, in Bard lesson 1 | The pitch drops the number line (demo-script.md 1:26) and Devpost drops the accomplishment |
| Sat 9 PM | Hall noise test at demo volume, with the score's level set alongside the beat | Switch to the stage-mic option (ux-flow option A). Turn the score down until Homer is clear. |
| Sat 11 PM | Feature freeze; Devpost draft submitted; video recorded | Cut, don't fix |
