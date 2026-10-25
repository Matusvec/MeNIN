# Proof: every claim, the receipt, and what's missing

Written Sat Oct 24, ~5:30 PM, by gtm, from three read-only audits of the repo against devpost.md and the README draft. **The rule: a claim goes in the submission only if a judge can open the receipt.** Sponsor judges may score from the video and Devpost alone ("some categories may need to do a virtual first pass", MLH, Sat 3:40 PM), so the receipts have to be in the repo and linked from the README.

Status key: ✅ the receipt is in the repo · ⚠️ true, but the wording or the receipt needs fixing · ❌ no receipt yet, so fix it or cut the claim.

## The three that have to be rock solid

### SpacetimeDB: "something that's hard to build without Spacetime"

**The flex:** the server runs the game. The phones and the website are just screens.

| Claim | Status | Receipt |
| --- | --- | --- |
| The battle is a phase machine in reducers, and a scheduled reducer closes each turn | ✅ | `spacetime/src/index.ts` (`advance`, `start_turn` with `ScheduleAt`, `turnTimeout` with `onSchedule`); `spacetime/CONTRACT.md` lines 44–73 |
| Only your phone can read your hand | ⚠️ wording | It's **row-level security** (a `clientVisibilityFilter` on the `hand` table, `index.ts` ~277), not a private table. `smoke.mjs`: "Ada sees only her own hand", "an anonymous client sees no hands". Say "row-level security". |
| A phone that dies takes its seat back with its score | ✅ code, ❌ live | `index.ts` ~844 (seat takeover by name); `smoke.mjs`; `scripts/hall-soak.ts` ("takes the seat back from a new device mid-turn"). Claim it live only if take 2 of the evening shoot or multiplayer's runs pass. |
| The speaker's voice streams at 20 Hz into a table the arena subscribes to | ⚠️ wording | Only the **speaking** phone streams (one `prosody` row per room, overwritten about every 50 ms). Say "the speaking phone", not "each phone". |
| iOS uses the community Swift SDK with two patches | ✅ | `ios/Vendor/SpacetimeDB/README.md`; `grep -rn "HOMER PATCH" ios/Vendor` |
| The website is a second client of the same module (TypeScript SDK), and it auto-reconnects | ✅ | `homer/web/src/lib/arena.ts` (`withAutomaticReconnect`, the one-tab lock), `Arena.tsx` ("Reconnecting…", "Resume") |
| It's tested | ✅, and say it | `npm run smoke` (about 118 checks: hand privacy, seat takeover, the turn timer, scoring, the song, rematch, discus, debate, coach); `hall-soak.ts` (five battles on real websockets, with drops and rejoins). **Put both in the README.** |
| Two real iPhones in one battle | ❌ | **Multiplayer's count since build 18 (leader, Sat ~5:30 PM):** poetry 1 clean of 2 (one run lost the partner's phone); debate 0 clean of 1 (both turns perfect, then the finale froze when the Mac slept). **The rejoin is untested on build 18 or later.** The evening shoot is the receipt, and the gate needs 5 clean. |

**At the table (10 s):** mid-battle, kill the app on one phone, reopen it, and the poet's seat and score come back. Say: "The server runs the battle, so the phone is just a screen. Kill it, and nothing is lost." Only if it passes tonight.

### Claude: the judge is rock solid

| Claim | Status | Receipt |
| --- | --- | --- |
| One streamed call to Claude Opus 5.5, fast mode, low effort, a cached system prompt and a JSON schema | ✅ | `homer/homer/config.py`, `homer/homer/claude.py` (json_schema, `cache_control`, stream) |
| Content-only scoring: Image ×4, Answer ×4, Craft ×2, anchored (a typical first verse is 4–6) | ✅ | `homer/homer/events.py`, `homer/homer/prompts/judge_poetry.md`, `spacetime/src/index.ts` weights |
| A timeout never stalls the battle: "Homer is silent on this one." and a neutral 4/4/4 | ✅ | `homer/homer/judge.py` (`SILENT_SCORE`). It also covers API errors and bad JSON. Stale docstrings at `judge.py` lines ~14–16 and ~97 ("Answer x3") need fixing. |
| Verdict p50 1.0 s, p95 1.5 s | ⚠️ stale | `homer/scripts/latency.py` exists, but the numbers are from **Friday's judge**, and the judge has changed about nine times since. Results are recorded as prose only. **Rerun the 10 calls on the current judge and commit the raw output** (a few cents; Matus approves the live calls). |
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
| Ideation entries | ⚠️ | 3 entries in `figma-stage-log.md`; the first is still `TODO(Matus)` (lines ~65–67). |
| Prototyping entries | ✅ | 8 entries with tools, minutes, a 1–5 rating, the output and the friction. The clickable prototypes are linked. |
| **Handoff** entries | ❌ | **None, though it's our strongest real story:** the art session reads frames and variables straight from the file through the Figma MCP server, and every variable carries its Swift name (`Palette.hero`, `Metrics.radiusL`), so one mode switch in Figma is one launch flag in the app (`ios/Homer/UI/Tokens.swift`, `enum Direction { atelier, cutPaper }`). Log it with minutes, a rating and what broke. |
| **Code generation** entries | ❌ | None. Log what the art session generated from the Figma file (the SwiftUI screens, the tokens), how long it took and what needed rework. |
| Figma Slides deck | ❌ | **Not made yet, and it's required.** Start from Figma's template (link in `figma-stage-log.md`), one slide per stage, the prototypes embedded, the repo link, sharing set to "View all". |
| Make or Figma's own agent | ❌ | Make is logged, but "Make's own AI was not run". No Figma-agent use anywhere. Either Matus runs one real thing tonight and logs it honestly, or we cut "Make's AI explores variations" and say we chose the MCP instead, and why. |
| The website's look | ⚠️ | The web code has no token names matching Figma. Don't claim one design system across both; claim the app. |

## The other tracks

| Track | What holds | What to fix |
| --- | --- | --- |
| **Cartesia** | ink-2 over WebSocket with keyterms = the dealt phrases + the hoard + the theme (`TurnRecorder.swift`, `CartesiaSTT.swift`); sonic-3.6 (`voice.py`); short-lived tokens, no audio through our server (`voice.py`, `/voice/token`); `/voice/status` for credit outages | ❌ **The 3% vs 20% word-error test isn't in the repo** ("the probe lives in the swift session's scratchpad", `docs/voice.md`). swift commits the script and the raw results with the date; a code comment says "6–20%" and must match. ❌ **"75 ms to the final transcript" and "about 100 ms to Homer's first audio" were never measured by us** (`docs/voice.md`: "no live latency numbers yet"). Cut them, or measure them at the shoot. Voice "Carl" is set only in `.env.example`; that's fine, but name the voice id in the README. |
| **Apify** (Best Use + Best Actor) | `apify/` (Apify SDK, Crawlee, the four Gutenberg IDs, rules with no language model, the copied scanner rule), `BUILD_LOG.md` (built by Claude Opus 5.5 in Claude Code), 55 entries with `source` and `count` in `content/formulas.json`, never called at runtime | ⚠️ "**A person** kept 55": our own notes say pm, a Claude Code session, kept them. Settle who reviewed, and say exactly that. Add the Store URL and the Actor ID to `apify/README.md`. Optionally name the Actor in each mined entry. |
| **Moss** | `HOMER_DEALER=moss`, the 500 ms fallback (`homer/homer/moss_dealer.py`) | ❌ **The 13.7 ms / 32.2 ms benchmark has no script or results**, and it was run on the 213-formula bank. Commit a bench script and its output on the 180 bank. ❌ The "breaker of horses" before/after is contradicted by our own samples (`demo-hands.md`); re-pick both examples from real output. |
| **Fetch.ai** | `homer/fetch_agent.py` (`homer-bard`, the chat protocol), `AGENTVERSE.md`, `agentverse_connect.py` | ⚠️ It's a **sidecar container** (`docker-compose.yml`, the `fetch` profile), not "inside our agent service". Mention ASI:One in `AGENTVERSE.md`. |
| **Meta** | The battle scores Answer (×4, how well you answered the person before you) and ends with one stitched song from everyone's lines | Its proof is the demo and the video, so the video must show two people answering each other and the song. |
| **Microsoft** | Our five-capability section in devpost.md | It inherits every fix above, especially the website URL (the "path to production"). |

## The repo itself (judges open it)

- ❌ **The root `README.md` is just `# MeNIN`.** Paste `readme-draft.md`, fill or cut its 14 placeholders, and add a **Receipts** section linking each number to its file (below).
- ❌ **The website's public URL is in no file** (`WEB_HOST=` is empty in `.env.example`; Devpost says `[URL]`). Deploy it, record the URL, and open it on a phone on cellular.
- ❌ No `LICENSE`. Matus picks one (MIT is the usual hackathon default).
- ⚠️ No root `.gitignore`. Add `.env`, `.env.*`, `.token-*` and `node_modules/` before `scrabble/` is committed (its `.env` and token files are ignored only by its own `.gitignore`).
- ⚠️ Stadion and boxing exist only as uncommitted changes. Claim them only once they're committed and pass 5 clean runs.
- ⚠️ `spacetime/CONTRACT.md` line 16 still names the local database `homer`; the demo one is `homer-calhacks`.
- ✅ No secrets are committed. The droplet IP is public in a few files, which is fine.
- ✅ The Google Calendar link in `slack-intel.md` is removed (gtm, Sat ~5:30 PM).

## The Receipts section (for the README and Devpost)

Paste once the ❌ rows are fixed:

> **Every number here has a receipt.** Hand privacy, seat takeover and the turn timer: `spacetime/scripts/smoke.mjs` (about 118 checks; `npm run smoke`) and `spacetime/scripts/hall-soak.ts`. Judge latency: `homer/scripts/latency.py` and [its output]. Word error with keyterms: [the committed probe and results]. Moss retrieval: [the bench script and output]. The mined phrases: `apify/BUILD_LOG.md` and the `source` field in `content/formulas.json`. How the team of Claude Code sessions worked: `AGENTS.md`, `SPEC.md`, and the commit log (232 of 245 commits co-authored by Claude Opus 5.5 as of Sat 5:30 PM).
