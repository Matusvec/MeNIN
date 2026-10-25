# Proof: every claim, the receipt, and what's missing

Written Sat Oct 24, ~5:30 PM, by gtm, from three read-only audits of the repo against devpost.md and the README draft. **The rule: a claim goes in the submission only if a judge can open the receipt.** Sponsor judges may score from the video and Devpost alone ("some categories may need to do a virtual first pass", MLH, Sat 3:40 PM), so the receipts have to be in the repo and linked from the README.

Status key: ✅ the receipt is in the repo · ⚠️ true, but the wording or the receipt needs fixing · ❌ no receipt yet, so fix it or cut the claim.

**Routed by leader (commit 83abf4b, Sat ~5:40 PM):**
- builder: the judge latency rerun (approved), the Moss bench on the 180 bank, the `judge.py` docstrings, and the website URL in `DEPLOY.md`.
- swift: the keyterm WER probe and its results, plus the `CartesiaSTT.swift` comment.
- multiplayer: `CONTRACT.md` line 16.
- artist: the Figma Handoff and Code-generation entries, and the Slides deck.
- leader, at the freeze: the root README and the LICENSE.
- Matus decides: ~~MIT~~ (**decided: MIT**, `LICENSE`, 1fa4be3, Sat 10:52 PM), the Apify "Matus checked them" wording, and Make's AI.

gtm swaps each bracket for its real number as the receipts land.

## Vital, not bolted on (Matus, Sat ~6 PM)

**The test for every sponsor line: say what breaks without it.** If nothing breaks, it's bolted on, and it stays out of the main pitch. Never say "we also used", "integrated" or "behind a switch" in a pitch. The fallbacks are a reliability point ("a battle never stalls on a third-party call"), not a disclaimer.

| Sponsor | Its job in MeNIN | Without it | The line |
| --- | --- | --- | --- |
| **SpacetimeDB** | Runs the battle: the phases, the turn timer, scores, your private cards (row-level security), the speaker's live voice row, seat takeover | There's no shared game: every screen disagrees, and a dropped phone loses its seat | "The server runs the battle, so the phone is just a screen." |
| **Cartesia** | Hears every verse (ink-2 with the dealt phrases as keyterms) and is Homer's voice (sonic-3.6) | There's no game: you play by speaking, and Homer answers out loud | "Voice is the whole game." |
| **Claude** | Judges every verse, writes every theme, call, epithet, verdict and the song; a team of Claude Code sessions built the app (232 of 245 commits) | No judge, no host, no game, and no app | "Homer is a live agent doing real work." |
| **Figma** | The design system: variables carry their Swift names, so one mode switch in Figma is one launch flag in the app; Matus picked the look by flipping modes on the same frames | The look would have been picked from screenshots, and the app's tokens wouldn't trace back to a design | "We designed in Figma, and the code reads it." |
| **Moss** | Deals phrases that fit a theme nobody has seen | Fresh themes would get cards matched by tags, which can't know the theme | "Fresh themes only work because of Moss." |
| **Apify** | Mined nearly a third of the phrase bank (55 of 180); in play, 22% of dealt cards are mined, and 74% of five-phrase deals carry at least one (`homer/bench/mined-share-2026-10-24.txt`, 400 deals) | About one card in five would be gone, and most hands would lose a phrase | "Nearly a third of Homer's bank was mined by our Actor, and about one in five cards you're dealt comes from it." |
| **Meta** | The point of the product: two people answering each other, scored on how well they answer (Answer ×4), and one song made from everyone's lines | — | "You leave having made something together." |
| **Fetch.ai** | Homer outside the hall: the same judge, as an agent anyone can use in ASI:One | Homer only exists in a room with a big screen | "Homer goes where you are." |
| **DigitalOcean** (MLH) | Hosts the agent service and the website | No judge, no arena | — |

**Honest weak spot:** Fetch.ai is a second surface, not part of the battle. Pitch it only to Fetch judges and in the Fetch cut of the video, never in the main 2:00. Apify works at build time; its vitality is the share of the bank (31%) and of the cards in play (22%), so lead with those. Never say "a third of what you're dealt": that mixes the two. The main pitch and the main video name only SpacetimeDB, Cartesia and Claude, plus Figma as how we built it.

## The three that have to be rock solid

### SpacetimeDB: "something that's hard to build without Spacetime"

**The flex:** the server runs the game. The phones and the website are just screens.

| Claim | Status | Receipt |
| --- | --- | --- |
| The battle is a phase machine in reducers, and a scheduled reducer closes each turn | ✅ | `spacetime/src/index.ts` (`advance`, `start_turn` with `ScheduleAt`, `turnTimeout` with `onSchedule`); `spacetime/CONTRACT.md` lines 44–73 |
| Only your phone can read your hand | ⚠️ wording | It's **row-level security** (a `clientVisibilityFilter` on the `hand` table, `index.ts` ~277), not a private table. `smoke.mjs`: "Ada sees only her own hand", "an anonymous client sees no hands". Say "row-level security". |
| A phone that loses the network comes back by itself, on the right screen, with no relaunch | ✅ live | Build 31's reconnect fix (`8a50d58`: a reconnect replaces each table's rows instead of stacking ghosts). Matus, on a real iPhone: after the airplane-mode test at Sat 10:49 PM he was on the right screen with everyone listed, no relaunch (leader, Sat 10:52 PM). |
| The verdict doesn't depend on the arena tab (the agent backstop judges a turn left in judging for 6 s straight from SpacetimeDB) | ✅ live | Commit 7ef1c5f (deployed 02:07). **Proven on prod:** in hall UKQR, turn 121 went to judging at 02:16:50 with no arena watching (the arena had opened another hall, PRFL); the backstop judged it at 02:17:05 and posted the score (leader, Sun ~2:25 AM). |
| A phone that dies takes its seat back with its score | ✅ code, ❌ live | `index.ts` ~844 (seat takeover by name); `smoke.mjs`; `scripts/hall-soak.ts` ("takes the seat back from a new device mid-turn"). Claim it live only if take 2 of the evening shoot or multiplayer's runs pass. |
| The speaker's voice streams at 20 Hz into a table the arena subscribes to | ⚠️ wording | Only the **speaking** phone streams (one `prosody` row per room, overwritten about every 50 ms). Say "the speaking phone", not "each phone". |
| iOS uses the community Swift SDK with two patches | ✅ | `ios/Vendor/SpacetimeDB/README.md`; `grep -rn "HOMER PATCH" ios/Vendor` |
| The website is a second client of the same module (TypeScript SDK), and it auto-reconnects | ✅ | `homer/web/src/lib/arena.ts` (`withAutomaticReconnect`, the one-tab lock), `Arena.tsx` ("Reconnecting…", "Resume") |
| It's tested | ✅, and say it | `npm run smoke` (about 118 checks: hand privacy, seat takeover, the turn timer, scoring, the song, rematch, discus, debate, coach); `hall-soak.ts` (five battles on real websockets, with drops and rejoins). **Put both in the README.** |
| One module runs seven games: 27 tables (20 public), 45 reducers, 4 scheduled timers | ✅ | `spacetime/src/index.ts` (2,070 lines); `spacetime/CONTRACT.md` (the event table, line 243 for the private tables) |
| The server decides: archery's landing, boxing's damage and counters are computed in the module; only the agent's identity can post a poetry score | ✅ | `index.ts` `landing()` (~833), the `fighter` stamina and `punch` damage columns (~316–337), `requireService` (~890) on `post_score` and 6 other reducers |
| Live input streams at 10–20 Hz through reducers (voice, strides, fists, bow, draw, webcam aim) | ✅ | `CONTRACT.md` lines ~276–287 and 413–415 |
| Three kinds of client on one module (Swift app, TypeScript website, Python agent over HTTP) | ✅ | `CONTRACT.md` "Who's who"; `ios/Vendor/SpacetimeDB`; `homer/web/src/lib/arena.ts` |
| 232 smoke checks across all seven games | ✅ | `spacetime/CONTRACT.md` line ~429 (`npm run smoke`, 232 checks); the 19:30 commit 40800d6 ("smoke 232/232") |
| Two real iPhones in one battle | ❌ | **Every series starts again on build 31** (leader, Sat 8:13 PM: it fixes stuck game screens after a reconnect, so runs on builds 24–30 don't count). The earlier count, since build 18 (leader, Sat ~5:30 PM): poetry 1 clean of 2 (one run lost the partner's phone); debate 0 clean of 1 (both turns perfect, then the finale froze when the Mac slept). **The rejoin is untested on build 18 or later.** The evening shoot is the receipt, and the gate needs 5 clean. |

**At the table (10 s):** mid-battle, kill the app on one phone, reopen it, and the poet's seat and score come back. Say: "The server runs the battle, so the phone is just a screen. Kill it, and nothing is lost." Only if it passes tonight.

### Claude: the judge is rock solid

| Claim | Status | Receipt |
| --- | --- | --- |
| One streamed call to Claude Opus 5.5, fast mode, low effort, a cached system prompt and a JSON schema | ✅ | `homer/homer/config.py`, `homer/homer/claude.py` (json_schema, `cache_control`, stream) |
| Content-only scoring: Image ×4, Answer ×4, Craft ×2, anchored (a typical first verse is 4–6) | ✅ | `homer/homer/events.py`, `homer/homer/prompts/judge_poetry.md`, `spacetime/src/index.ts` weights |
| A timeout never stalls the battle: "Homer is silent on this one." and a neutral 4/4/4 | ✅ | `homer/homer/judge.py` (`SILENT_SCORE`). It also covers API errors and bad JSON. Stale docstrings at `judge.py` lines ~14–16 and ~97 ("Answer x3") need fixing. |
| Verdict latency, current judge | ✅ | **`homer/bench/latency-2026-10-24.txt`** (builder, Sat 5:20 PM, 10 live calls + a warm-up, **from the MacBook calling the API**; the droplet's live battle calls run 1.4–3.0 s end to end, per its logs): the verdict line p50 904 ms, p95 1864 ms; the whole judgment p50 1017 ms, p95 2024 ms; first token p50 729 ms; 10/10 answered, 10/10 read the cached prompt. Quote "p50 0.9 s, p95 1.9 s". |
| Turn end to Homer's first word, about 3 s | ❌ | `[turn-to-voice p50]` is still empty. Read it off the latency HUD at the evening shoot. |
| Fresh Homeric themes (never one of the last 20), fresh epithets (never one of the poet's last 5), the song, the round verdicts | ✅ | `homer/homer/host.py`, `homer/homer/arena.py` (`RECENT_THEMES = 20`, `WORN = 5`) |
| An emotion read on Claude Haiku 5.5 paints the scene, not scored | ✅ | `homer/homer/emotion.py`, `config.py` |
| The freeze whisper makes no model call | ✅ | `homer/homer/deal.py`, `server.py` ("No model call") |
| Unfit verses score nothing and aren't quoted; names are PG-checked | ✅ (one edge) | `judge_poetry.md` (`fit`), `index.ts`; the name check is a Claude call, and if it fails the name is kept as typed (`host.py`). |
| Built by a team of Claude Code sessions | ✅, and say it | **232 of 245 commits are co-authored by Claude Opus 5.5** (`git log`), from one `SPEC.md` with one folder per session (`AGENTS.md`). Put the number in the README and the Anthropic blurb. |
| Impact is measured | ❌ until 8 PM | The protocol is in `docs/study.md`; its results tables are empty. |

### Figma: their brief judges the workflow, so the stage log is the entry

Judged on workflow design, adoptability, output quality, presentation and innovation. Required: a video of 3 minutes at most, a stage log covering ideation, prototyping, handoff and code generation, and **a Figma Slides deck** embedding the files and the repo link.

| Need | Status | Receipt or gap |
| --- | --- | --- |
| Ideation entries | ✅ | 3 entries in `figma-stage-log.md`. The first is now filled: **Paul** ran the Figma AI agent in Figma Design (Matus, Sun ~3:40 AM) (the stage text is from Sunya's log), and it turned the app description into a screen per part of the iOS experience (~45 min, 5/5; leader, Sun ~3:25 AM). |
| Prototyping entries | ✅ | 8 entries with tools, minutes, a 1–5 rating, the output and the friction. The clickable prototypes are linked. |
| **Handoff** entries | ✅ | Two entries (artist, committed 17:23): the Swift tokens, then Figma variables named after them, and the same tokens handed to the website team. Times checked against git and the session transcript. |
| **Code generation** entries | ✅ | Two entries: Matus's concept frame to SwiftUI (9 minutes from frame to `HomeView`, checked against git), and the icons and Homer's portrait pulled straight from the file. |
| Figma Slides deck | ⚠️ drafted | **https://www.figma.com/slides/oYPLd3JeIjhnkNyt75qfOm** (artist): 10 slides, the problem, the workflow, one slide per stage (tool and why, minutes, a 1–5 rating, what made it in, the friction), the prototype, two directions with one switch, before and after, and the repo link. **Matus must:** (1) share it as "Anyone with the link → can view" (judges can't open it until then); (2) **embed** the prototypes on slides 8 and 9 (Insert → Embed; the MCP can't create embeds, and the exact links are in the devpost.md checklist). The brief says "Must embed your Figma files (Make(s) and/or Figma prototypes)", so that isn't optional; (3) put the team's names on slide 1. |
| Make or Figma's own agent | ❌ | Make is logged, but "Make's own AI was not run". No Figma-agent use anywhere. Either Matus runs one real thing tonight and logs it honestly, or we cut "Make's AI explores variations" and say we chose the MCP instead, and why. |
| The website's look | ⚠️ | The web code has no token names matching Figma. Don't claim one design system across both; claim the app. |

## The other tracks

| Track | What holds | What to fix |
| --- | --- | --- |
| **Cartesia** | ink-2 over WebSocket with keyterms = the dealt phrases + the hoard + the theme (`TurnRecorder.swift`, `CartesiaSTT.swift`); sonic-3.6 (`voice.py`); short-lived tokens, no audio through our server (`voice.py`, `/voice/token`); `/voice/status` for credit outages. ✅ **The WER receipt is in `docs/voice-wer/`** (swift, Sat ~5:45 PM): `probe.py`, `fixtures.py`, the raw `results.txt` and a README with the date (Fri Oct 23, ~10:59 PM PT) and method. ink-2 with keyterms: 3% on every clip, including 0 dB; without: 9% clean, 6% at +12/+6 dB, 20% at 0 dB. The final transcript arrives 62–81 ms after `finalize`. Label all of it "synthetic test clips". | ✅ Homer's first audio: **78–90 ms** after the request, measured from the arena laptop on Wi-Fi (`docs/voice-wer/README.md`, "Homer's voice (TTS) timing", Sat 2:33 PM). On a phone, live lines play once the whole line arrives (~0.4 s). Say "under 0.1 s, from a laptop on Wi-Fi". ⚠️ The real-mic rerun hasn't happened. `docs/voice.md` and the `CartesiaSTT.swift` comment now match the receipt (swift). Voice "Carl" is set only in `.env.example`; name the voice id in the README. |
| **Apify** (Best Use + Best Actor) | `apify/` (Apify SDK, Crawlee, the four Gutenberg IDs, rules with no language model, the copied scanner rule), `BUILD_LOG.md` (built by Claude Opus 5.5 in Claude Code), 55 entries with `source` and `count` in `content/formulas.json`, never called at runtime | ⚠️ "**A person** kept 55": our own notes say pm, a Claude Code session, kept them. Settle who reviewed, and say exactly that. The Store URL and the Actor ID are now in `apify/README.md` (83abf4b). Optionally name the Actor in each mined entry. |
| **Moss** | `HOMER_DEALER=moss`, the 500 ms fallback (`homer/homer/moss_dealer.py`). ✅ **`homer/bench/moss-2026-10-24-droplet.txt`** (production droplet, 1 vCPU, inside the live agent container, 180-formula bank, 40 runs over 16 themes): a ranked lookup p50 13.22 ms, p95 14.86 ms; a whole deal p50 14.68 ms, p95 17.02 ms; the index loads in 3.3 s. The same script on the MacBook Air: 1.55 ms (`moss-2026-10-24-mac.txt`). Both have identical same-seed hands for the three demo themes, tags vs Moss; the Devpost before/after uses them. | The "grandmother's kitchen" example had no receipt and is cut. |
| **Fetch.ai** | `homer/fetch_agent.py` (`homer-bard`, the chat protocol), `AGENTVERSE.md`, `agentverse_connect.py` | ⚠️ It's a **sidecar container** (`docker-compose.yml`, the `fetch` profile), not "inside our agent service". Mention ASI:One in `AGENTVERSE.md`. |
| **Meta** | The battle scores Answer (×4, how well you answered the person before you) and ends with one stitched song from everyone's lines | Its proof is the demo and the video, so the video must show two people answering each other and the song. |
| **Microsoft** | Our five-capability section in devpost.md | It inherits every fix above, especially the website URL (the "path to production"). |

## The repo itself (judges open it)

- ❌ **The root `README.md` is just `# MeNIN`.** Paste `readme-draft.md`, fill or cut its 14 placeholders, and add a **Receipts** section linking each number to its file (below).
- ✅ **The website is at https://play.206.189.237.157.sslip.io**, recorded in `homer/DEPLOY.md` (builder). It answered HTTP 200 at 5:50 PM; Devpost and the README draft now use it. Still open it on a phone on cellular with Wi-Fi off.
- ❌ No `LICENSE`. Matus picks one (MIT is the usual hackathon default).
- ✅ A root `.gitignore` now covers `.env*`, `.token-*`, `*.p8`, `Secrets.xcconfig` and `node_modules` (83abf4b).
- ⚠️ Stadion and boxing exist only as uncommitted changes. Claim them only once they're committed and pass 5 clean runs.
- ⚠️ `spacetime/CONTRACT.md` line 16 still names the local database `homer`; the demo one is `homer-calhacks`.
- ✅ License: MIT (`LICENSE`, commit 1fa4be3; Matus, Sat 10:52 PM). The README draft links it.
- ✅ No secrets are committed: the freeze secret scan (gitleaks, all 365 commits) came back clean (leader, Sat ~10:05 PM). The droplet IP is public in a few files, which is fine.
- ✅ The Google Calendar link in `slack-intel.md` is removed (gtm, Sat ~5:30 PM).

## The Receipts section (for the README and Devpost)

Paste once the ❌ rows are fixed:

> **Every number here has a receipt.** Hand privacy, seat takeover and the turn timer: `spacetime/scripts/smoke.mjs` (about 118 checks; `npm run smoke`) and `spacetime/scripts/hall-soak.ts`. Judge latency: `homer/bench/latency-2026-10-24.txt` (from `homer/scripts/latency.py`). Word error with keyterms and the final-transcript time: `docs/voice-wer/` (scripts, raw output, method). Moss retrieval and the before/after hands: `homer/bench/moss-2026-10-24-droplet.txt` (and `-mac.txt`) (from `homer/scripts/moss_bench.py`). Homer's first audio: `docs/voice-wer/README.md`. The mined phrases: `apify/BUILD_LOG.md` and the `source` field in `content/formulas.json`. How the team of Claude Code sessions worked: `AGENTS.md`, `SPEC.md`, and the commit log (232 of 245 commits co-authored by Claude Opus 5.5 as of Sat 5:30 PM).
