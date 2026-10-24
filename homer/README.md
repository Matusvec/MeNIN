# Homer

Homer, the blind bard of Ionia, teaches and judges English iambic pentameter. He runs on Claude (`claude-opus-5-5`) through the Anthropic Messages API, with a deterministic scansion tool built on the CMU Pronouncing Dictionary.

## Setup

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
export ANTHROPIC_API_KEY=...   # or use an `ant auth login` profile
```

## Using it

```bash
.venv/bin/python -m homer --mode bard
.venv/bin/python -m homer --mode judge --json
.venv/bin/python -m homer --mode battle --players Alice,Bob --rounds 2 --lines 4 --themes "a sea voyage|a winter morning"
```

In the CLI, `/mode <bard|judge|battle>` switches mode (this starts a new session), `/json` toggles the structured data, and `/quit` leaves. Battle mode adds `/submit <player> <line / line / ...>`, `/close`, `/next`, `/finish`, and `/standings`.

From code:

```python
from homer.agent import HomerAgent
from homer.state import Mode, Session

agent = HomerAgent()
reply = agent.judge(Session(Mode.JUDGE), "Shall I compare thee to a summer's day?")
reply.text                 # Homer's in-character answer
reply.data["judgment"]     # structured verdict (schema below)
```

## How it works

| File | Role |
|---|---|
| `homer/prompts/persona.md` | Shared voice, safety, PG rules, public-domain-only quoting, scansion notation |
| `homer/prompts/{bard,judge,battle}.md` | One section per mode; only the active one is loaded |
| `homer/prompts.py` | Builds persona + mode section; wraps user text as data |
| `homer/state.py` | `Mode`, `Session`, curriculum, and bard progress. The app owns these |
| `homer/scansion.py` | Deterministic CMU-dictionary scansion (no LLM) |
| `homer/tools.py` | Strict tool schemas and validators for the structured records |
| `homer/agent.py` | Tool-use loop, mode entry points (`bard`, `judge`), refusal handling |
| `homer/battle.py` | Battle bookkeeping: blind shuffling, scoring, ties, late or missing entries |

**The mode comes from the app.** `Session.mode` is set when a session is created. Each request loads only that mode's prompt section and tools, so nothing a user types can change the mode. When asked to switch, Homer explains how; the hint text is configurable through `HomerAgent(switch_hint=...)`.

**Scansion reliability.** Homer calls `scan_poem` before he scans anything. For each line it returns the syllable count, each word's CMU stress options, a lexical stress lean, a suggested iambic fit with feet, stress clashes from fixed (polysyllabic) stresses, hints (trochaic inversion, feminine ending, possible spondee or pyrrhic), caesurae, elision candidates with an alternative fit when elision helps (`th'expense`), and the words missing from the dictionary. Monosyllables are never treated as fixed; that call is left to Homer.

Notation: `ˇ` unstressed, `/` stressed, `?` ambiguous, `|` between feet.

**Structured output.** Judge mode requires a `record_judgment` call, or `decline_submission` for inappropriate content. Battle mode requires `record_round`. Tools are `strict`, so inputs always match their schemas. The code then checks what a schema can't express (line counts, labels, whether the declared winner matches the scores) and sends errors back to Homer to fix.

```jsonc
// reply.data["judgment"]
{
  "input_kind": "line | stanza | poem | not_verse",
  "lines": [{"line_number": 1, "text": "...", "syllables": 10, "scansion": "ˇ / | ˇ / | ˇ / | ˇ / | ˇ /", "feet": 5,
             "deviations": [{"foot": 1, "type": "trochaic_inversion", "classification": "variation | error", "explanation": "..."}]}],
  "scores": {"metrical_accuracy": 1-10, "naturalness": 1-10, "imagery_diction": 1-10, "overall_craft": 1-10},
  "revisions": [{"original": "...", "revised": "...", "reason": "..."}],
  "verdict": "..."
}
```

**Battle fairness is enforced in code.** Entries are shuffled with a seeded RNG and shown to Homer as `Entry A/B/...`, with no player names. Round points are the four rubric scores summed (4 to 40), minus 5 for an off-theme entry; a disqualified or missing entry scores 0. The app computes the winner from these totals. A tie for the championship starts a tiebreaker round for the tied players only. Late submissions are rejected. User text is escaped, so it can't close or forge the `<entry>` and `<submission>` tags.

**API settings.** Adaptive thinking with per-mode effort (bard `medium`, judge and battle `high`), plus server-side refusal fallbacks (`fallbacks="default"`). On a refusal, the turn is rolled back and Homer gives a short, plain reply.

## Extending

- **Change Homer's voice or rules:** edit the markdown in `homer/prompts/`. No code changes needed.
- **Add a curriculum step:** add it to `CURRICULUM` in `homer/state.py`. The prompt and the `update_progress` enum pick it up automatically.
- **Add a mode:** add a `Mode` value, write `homer/prompts/<mode>.md`, list its tools in `MODE_TOOLS` and its effort level in `EFFORT`, then add an entry point next to `HomerAgent.judge`.
- **Change scoring:** `entry_total` and `ROUND_PENALTY_OFF_THEME` in `homer/tools.py`.
- **Teach the scansion tool new words:** add archaic forms to `ARCHAIC` and squeezable words to `ELIDABLE` in `homer/scansion.py`.
- **Plug into a web app:** keep one `Session` (or `Battle`) per user or room, call the mode entry points from your request handler, and render `reply.text` plus `reply.data`.

## Tests

```bash
.venv/bin/python -m pytest              # offline: scansion, prompts, agent loop, battle engine
HOMER_LIVE=1 .venv/bin/python -m pytest tests/test_live.py   # real API calls
.venv/bin/python scripts/samples.py     # live transcripts for every mode -> samples/
```

The offline suite drives the agent with a scripted fake client (`tests/fakes.py`). Its battle simulation uses a deterministic fake Homer that really calls `scan_poem` and scores entries from the scansion. Fixtures in `tests/fixtures/` cover clean pentameter, legitimate variations, broken lines, empty input, prose, prompt injection, and a 2-player, 2-round battle.
