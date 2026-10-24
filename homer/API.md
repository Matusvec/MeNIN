# Homer agent service: HTTP API

The Python service in `homer/`. This file is the contract between the service and its callers; `spacetime/CONTRACT.md` is the contract for the battle database.

**Status:** live means built and tested; planned means the shape is settled but the endpoint isn't built yet.

| Endpoint | Caller | Status |
| --- | --- | --- |
| `GET /health` | anyone | live |
| `POST /scan` | app (Bard, Practice, beat lane) | live |
| `POST /judge` | app (Practice, Bard) | live |
| `POST /battle/judge` | arena | live |
| `POST /rescue` | phone, any mode | planned |
| `POST /deal` | app (Practice) | planned |
| `POST /battle/deal` | arena | planned |
| `POST /battle/poet` | arena | planned |
| `POST /emotion`, `POST /battle/emotion` | app / arena | planned |
| `POST /battle/verdict` | arena | planned |
| `POST /battle/song` | arena | planned |
| `POST /spar` | app (Practice) | planned |
| `POST /lesson/feedback` | app (Bard) | planned |

## Conventions

- **JSON keys are camelCase**, to match `ios/Homer/Contracts.swift`. Request bodies also accept snake_case (`turn_id` and `turnId` both work).
- **Times are milliseconds from beat 1 of the turn** (`started_at + one bar`, which is `turn.beat_at` in battle). A count-in word has a negative time.
- **A line is two bars**: one speaking bar and one rest bar (SPEC). Lines in a transcript are separated by `\n`. If a transcript has no newlines but has word timings, the service splits it into lines by bar.
- **Errors** are `{"detail": "..."}` with status 400 (bad input, unknown event), 409 (SpacetimeDB refused: already done or wrong phase), 422 (nothing to judge) or 502 (SpacetimeDB unreachable).
- **The arena ignores battle response bodies.** Results arrive through its SpacetimeDB subscription. Responses still carry the result, for logs and tests. Every battle call is safe to retry: a retry while the first call is still running shares its result, and reducers refuse duplicates.
- Run it: `.venv/bin/uvicorn homer.server:app --host 0.0.0.0 --port 8000` from `homer/`.

## Shared shapes

**Word** (from speech-to-text, already converted to turn time):

```json
{"text": "wind", "start": 0, "end": 300}
```

**Scorecard** (`Scorecard` in Contracts.swift, plus extras):

```json
{
  "scores": {"beat": 9, "craft": 6, "image": 7, "answer": 5, "range": 6},
  "total": 33,
  "verdict": "Strong bones, thin blood. Your third line carried you.",
  "bestLine": "the sea kept time and so did I",
  "coined": "",
  "declined": false,
  "silent": false,
  "scan": { "...": "a VerseScan, below" },
  "timing": {"scan": 9, "first_token": 1300, "verdict": 1650, "done": 1900},
  "model": "claude-opus-5-5"
}
```

- `beat` comes from the scanner and `range` from the emotion engine. They are always 1 to 10.
- `craft`, `image` and `answer` come from Claude. They are 0 when `silent` is true, meaning Claude didn't answer within the timeout (10 s): show "Homer is silent on this one." `verdict` is then `""`.
- `declined: true` means the verse isn't fit for the hall. Homer says the lesson line "Not in my hall. Give me another." The scores mean nothing.
- `coined` is a new formula for the poet's hoard, or `""`. It is always `""` in demo mode.
- `timing` is milliseconds from the request arriving.

**VerseScan**:

```json
{
  "beat": 9,
  "linesExpected": 4,
  "timed": true,
  "bestLine": 0,
  "formulas": ["wine-dark-sea"],
  "lines": [
    {
      "text": "the wine dark sea took my brother's ship",
      "pattern": "the WINE dark SEA / took my BROTHER'S SHIP",
      "hits": 4,
      "breakAfter": 3,
      "breakSource": "pause",
      "weakBeats": [],
      "extras": [],
      "onBeat": 3,
      "offsetMs": -40.5,
      "score": 0.85,
      "words": [
        {"text": "wine", "syllables": 1, "known": true, "beat": true, "hit": true, "weakBeat": false,
         "extra": false, "t": 0, "onBeat": true, "formulaId": "wine-dark-sea", "joined": false}
      ]
    }
  ],
  "beatLane": { "...": "only when bpm is sent; BeatLane in Contracts.swift" }
}
```

- `hits` is the stresses the listener hears: beats on syllables that can carry one, plus extra stresses. Four is the target.
- `breakSource` is where the mid-line break came from: `mark` (a ` / ` in the text), `pause` (a gap of 150 ms or more in the timings), `punctuation`, `phrase` (a new phrase starts with "and", "when" and so on), or `inferred` (text only, between beats 2 and 3). It is `null` when timings show no breath.
- `weakBeats` are words a beat had to land on although they can't carry one ("Your hit fell on {word}"). `extras` are stresses off the beat.
- `onBeat` counts beats within 120 ms of a drum pulse, and `offsetMs` is their mean signed distance from the pulse: negative is early, "rushing the drum". Both are `null` without timings.
- `bestLine` is the index of the best-scanning line.

**BeatLane** (Contracts.swift):

```json
{"bpm": 80, "beatsPerLine": 4, "lines": 2, "startedAt": 1761300000000,
 "words": [{"text": "wind", "t": 0, "stressed": true, "onBeat": true, "formulaId": null}]}
```

An untimed verse (Homer's own, or typed text) is laid on the grid: each beat on its pulse, the other words spaced between.

## Endpoints

### `GET /health`

`{"ok": true, "judgeModel": "claude-opus-5-5", "judgeEffort": "low", "events": ["poetry"]}`

### `POST /scan`

Scans a verse for hits, the break and the beat lane, with no Claude call. It takes about 10 ms for four lines, so the app can call it on every final line.

```json
{"transcript": "line one\nline two", "words": [Word], "bpm": 80, "linesExpected": 4,
 "hand": ["the whale-road"], "startedAt": 1761300000000, "event": "poetry"}
```

Every field is optional except a transcript or words. `hand` cards are matched as formulas in addition to the whole bank. Returns a VerseScan.

### `POST /judge`

Judges one verse in Practice or Bard mode.

```json
{
  "transcript": "...", "words": [Word], "bpm": 80, "linesExpected": 4,
  "mode": "practice", "event": "poetry", "theme": "A ship that never came home",
  "hand": ["the whale-road", "grey-eyed Athena"], "played": ["the whale-road"], "rescues": 1,
  "previous": "the verse this one answers, if any",
  "emotionHistory": [{"anger": 0.1, "grief": 0.7, "...": 0}],
  "hoard": ["storm-throated"], "demo": false
}
```

- `mode` is `practice`, `lesson` or `battle`. It sets Homer's tone: a coach, or the MC.
- `emotionHistory` is the classifier samples taken during the turn, in order, which Range is scored from. Without it, a word list stands in.

Returns a Scorecard. Send `Accept: text/event-stream` to get server-sent events instead, so text-to-speech can start before the scores are done:

```
event: verdict
data: {"verdict": "Strong bones, thin blood. Your third line carried you."}

event: scorecard
data: {Scorecard}
```

`verdict` comes first, usually a few hundred ms before `scorecard`. It is skipped when the verse is declined. On failure the stream sends `event: error`.

### `POST /battle/judge`

The arena calls this when a turn reaches `judging`. The agent then calls `post_score [turn_id, [beat, craft, image, answer, range], verdict, best_line, coined]`, or `decline_turn [turn_id]`.

```json
{
  "turnId": 42, "playerId": 7, "transcript": "turn.transcript",
  "event": "poetry", "form": "four_beat", "theme": "round.theme",
  "played": ["turn.played"], "rescues": 1,
  "previous": "the previous turn's transcript in this round, or empty for the first poet",
  "linesExpected": 4, "hoard": ["player.hoard"], "demo": false
}
```

`previousBestLine` is accepted instead of `previous`, but send the whole previous verse when you have it, since Answer is judged against it. The agent remembers the hand it dealt each poet. Returns `{"posted": "post_score" | "decline_turn", ...Scorecard}`; `posted` tells you which reducer was called.

### Planned

These shapes may still change; they'll be confirmed here when built.

- **`POST /rescue`** `{transcript, hand, theme, played}` → `{"formula": "the whale-road"}`. Answered inline in well under 100 ms, with no Claude call. It picks the hand card that best fits the hits left in the current line and the theme. The phone then calls the `rescue` reducer.
- **`POST /deal`** `{theme?, hoard, n: 5}` → `{"theme", "hand": [FormulaCard]}`, for Practice.
- **`POST /battle/deal`** `{roomId, roundNo, theme, event, poets: [{playerId, name, epithet, hoard}]}` calls `deal_round`. An empty `theme` means the agent picks one.
- **`POST /battle/poet`** `{playerId, name, epithet}` calls `name_poet`, with a PG-checked name and an epithet coined if it's empty.
- **`POST /emotion`** `{text, loudness?, pitch?}` returns the 8 weights. **`POST /battle/emotion`** `{turnId, text, loudness?, pitch?}` calls `set_scene` and keeps the sample for Range. Call either about every 1.5 s while speaking.
- **`POST /battle/verdict`** `{roundId, theme, verses: [{turnId, name, transcript, total, bestLine}]}` calls `post_verdict`.
- **`POST /battle/song`** `{roomId, demo, verses: [{turnId, name, transcript}]}` calls `post_song`. The song is capped at 4 lines in demo mode.
- **`POST /spar`** `{theme, previous?, lines}` returns Homer's verse, built by the formula engine and checked by the scanner.
- **`POST /lesson/feedback`** `{lesson, transcript, words, bpm}` → `{"landed": bool, "line": "Homer's one line"}`, using the miss tables in `content/lessons.md`.
