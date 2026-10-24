# Homer agent service: HTTP API

The Python service in `homer/`. This file is the contract between the service and its callers; `spacetime/CONTRACT.md` is the contract for the battle database.

**Status:** every endpoint here is built and tested. Lesson feedback covers lessons 1 to 3; lessons 4 to 6 return 501 until they're built (they're in the cut order).

| Endpoint | Caller | Status |
| --- | --- | --- |
| `GET /health` | anyone | live |
| `POST /voice/token` | app (all devices) | live |
| `POST /scan` | app (Bard, Practice, beat lane) | live |
| `POST /judge` | app (Practice, Bard) | live |
| `GET /themes` | arena, app | live |
| `POST /deal` | app (Practice) | live |
| `POST /rescue` | phone, any mode | live |
| `POST /battle/deal` | arena | live |
| `POST /battle/judge` | arena | live |
| `POST /emotion` | app (Practice, Bard) | live |
| `POST /spar` | app (Practice, lesson demos) | live |
| `GET /lessons` | app (Bard) | live |
| `POST /lesson/feedback` | app (Bard) | live, lessons 1 to 3 |
| `POST /battle/poet` | arena | live |
| `POST /battle/emotion` | arena | live |
| `POST /battle/verdict` | arena | live |
| `POST /battle/song` | arena | live |
| `GET /debate` | app (debate) | live |
| `POST /debate/whispers` | phone (debate, at step-up) | live |

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

```json
{"ok": true, "judgeModel": "claude-opus-5-5", "judgeEffort": "low", "judgeSpeed": "fast",
 "judge": "warm", "stdb": "claimed", "stdbDb": "homer-calhacks", "events": ["poetry"]}
```

- `judge` is `off`, `warming`, `warm` or `failed`. At startup, one real judge call caches the prompt, so wait for `warm` before a demo.
- `stdb` is `off`, `claimed`, `failed` or `unreachable`: whether this service can write to SpacetimeDB. It's checked with a no-op call, since a rotated service key doesn't unregister a claimed identity.

### `POST /voice/token`

Mints a short-lived Cartesia access token, so the app never holds the API key (docs/voice.md, section 2). The device opens the Cartesia WebSocket itself with `?access_token=…&cartesia_version=…`.

```json
{"role": "phone", "roomCode": "ABCD", "playerId": 12}
```

- `role` is `phone` (a battle mic, which gets `stt`), `arena` (Homer's voice, `tts`) or `solo` (Practice and Bard on one phone, both).
- With `roomCode`, the room must exist in SpacetimeDB: 403 if it doesn't, 400 if the code is malformed. If the database can't be reached, the token is minted anyway.

Returns:

```json
{"token": "…", "expiresAt": 1761300300000, "cartesiaVersion": "2026-08-14",
 "stt": {"model": "ink-2", "encoding": "pcm_s16le", "sampleRate": 16000},
 "tts": {"model": "sonic-3.6", "voiceId": "…"}}
```

- `stt` and `tts` are present only when granted. Models and the voice come from the server's env, so they change without an app build.
- Tokens last 300 s. If an open socket dies when its token expires, mint one per turn.
- The limit is 30 tokens a minute per IP: over it you get 429. With no `CARTESIA_API_KEY` set on the server you get 503.

### `GET /themes?n=3&demo=false`

`{"themes": ["A ship that never came home", "…", "…"]}`. These are the arena's theme cards. With `demo=true` you get the three rehearsed demo themes, in order.

### `POST /deal`

A Practice hand. `{"theme": "", "hoard": ["storm-throated"], "exclude": [], "n": 5}` returns `{"theme": "…", "hand": [FormulaCard]}`. An empty theme gets a random one. Each card is `{"id", "text", "kind", "used": false, "beats", "hoard"}`: `FormulaCard` plus `beats` (the hits it fills, 1 or 2) and `hoard` (the poet's own card). A hand mixes kinds, holds up to two hoard cards, and leans to the theme.

### `POST /rescue`

The freeze rescue: which card Homer whispers. `{"transcript": "the verse so far", "hand": ["…"], "played": ["…"], "theme": "…"}` returns `{"formula": "the whale-road", "card": FormulaCard}`. There is no model call; it takes a few ms.

- It fills what the current line (after the last `\n`) still needs: a half-line at a line start, a two-hit card with two or more hits to go, else a one-hit card. Spent cards are skipped.
- 409 means every card is spent.

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

### `POST /battle/deal`

The arena calls this in `dealing`, or early in `round_end` to deal round_no + 1. The agent then calls `deal_round`.

```json
{"roomId": 10, "roundNo": 1, "theme": ""}
```

- `theme` is `room.next_theme` when the judges picked one. Empty means the agent picks one this room hasn't had yet.
- Poets and their hoards are read from SQL. Each poet is offered 8 candidates, different from the other poets' and from anything offered to them earlier in the battle. The module tops each hand up to 5.
- Returns `{"theme": "…", "hands": {"<playerId>": ["card", …]}}`.

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

### `POST /emotion`

The scene's color layer for Practice and Bard. Call it about every 1.5 s while the poet speaks.

```json
{"text": "the transcript so far", "loudness": 0.7, "pitch": 180}
```

Returns `{"weights": {"anger": 0.1, "grief": 0.8, "joy": 0, "awe": 0.1, "tenderness": 0.2, "fear": 0.1, "defiance": 0, "longing": 0.6}}`.

- Only the latest ~40 words are read. The words can be sent as `text` or `transcript`. `loudness` (0 to 1) and `pitch` (Hz) are hints; in battle, take them from the room's `prosody` row.
- Weights run 0 to 1 each and don't sum to 1. The renderer normalizes and smooths them.
- Keep every sample in order and send them to `/judge` as `emotionHistory`; Range is scored from them.
- The classifier is Claude Haiku 5.5 with thinking off: about 1.1 s warm.
- 422 means there was no text; 503 means no reading within 2.5 s. Skip that tick.

### `POST /spar`

Homer's own verse, for a Practice spar or to show a move. It is built from a hand of formulas, checked by the scanner, and lines that miss four hits get one fix-up pass.

```json
{"theme": "A storm on the open sea", "lines": 4, "answerTo": "the poet's verse Homer answers", "hand": ["…"], "bpm": 80}
```

- `hand` is optional; without it, cards are dealt from the theme. An empty `theme` gets a random one.
- Returns `{"theme": "…", "lines": ["…"], "scan": VerseScan}`. The scan has a `beatLane` when `bpm` is sent.
- Lines are lowercase and plain, ready for TTS. 503 means Claude didn't answer.

### `GET /lessons?bpm=80`

The Bard path, parsed from `content/lessons.md`, so pm's edits show up without an app build.

```json
{"lessons": [{"id": "beat", "n": 1, "title": "The beat",
  "move": "Four hits a line. A breath in the middle.",
  "exercise": "Two lines about the road that brought you here. …",
  "demo": ["the WIND was COLD / the WAVES were GREY", "…"],
  "demoSpoken": "the wind was cold the waves were grey\n…",
  "demoLane": BeatLane, "success": "Four and four. …", "feedback": true}]}
```

- `demoSpoken` is the demo verse for TTS. `demoLane` puts its hits on the pulses.
- `feedback` is true where `/lesson/feedback` works.

### `POST /lesson/feedback`

Homer's one line after a try: the first miss in the lesson's table that applies, or the success line.

```json
{"lesson": "formula", "transcript": "…", "words": [Word], "bpm": 80,
 "hand": ["the whale-road", "…"], "rescue": "the whale-road", "name": "Matus"}
```

- `hand` and `rescue` (the card Homer whispered on this try, if he did) are for lesson 2. `name` is for lesson 3, which reads the title after it on the first line.
- `words` and `bpm` let lesson 1 hear "rushing the drum".

Returns `{"landed": false, "line": "Three hits. I need four. Add a word with weight.", "miss": "Three hits or fewer", "title": "", "scan": VerseScan}`.

- `miss` is the table row that applied, or `null` when the try landed. With no words it is `"No speech heard"`.
- On lesson 3, `title` is the coined epithet when it lands: put it in the hoard and use it as the battle name. Lesson 3's "generic" check is a judge call (about 1 s); the other checks are instant.

### `POST /battle/poet`

The arena sees a player with `named` = false. The agent PG-checks the name, coins an epithet if the poet brought none, and calls `name_poet`.

`{"playerId": 12}` is all that's needed: the name and epithet are read from SQL, or can be sent as `name` and `epithet`. Returns `{"name": "Matus", "epithet": "Breaker of Deadlines"}`.

### `POST /battle/emotion`

Call about every 1.5 s while a battle turn is speaking. The agent classifies the speech, calls `set_scene [turn_id, 8 weights]`, and keeps the sample for that turn's Range.

`{"turnId": 42, "transcript": "turn.transcript", "loudness": 0.7, "pitch": 180}` returns `{"weights": {…}}`, or `{"weights": null}` when there was nothing to read. A call made while one for the same turn is still running shares its result, so slow replies don't pile up.

### `POST /battle/verdict`

In `round_end`. The agent reads the round's scored verses from SQL, Homer calls the round, the best line is chosen, and `post_verdict` is called.

`{"roundId": 5}` returns `{"verdict": "The round goes to Ada, and the line that stung: I stand on the shore with salt in my teeth", "bestTurnId": 21, "bestLine": "I stand on the shore with salt in my teeth"}`.

- `verdict` (written to `round.verdict`) is the whole thing Homer speaks, about 7 s: a lead-in of at most twelve words, then the carved line verbatim. **Speak `round.verdict` once; don't read `best_line` again.** Show `best_line` carved in gold.

- The carved line is always a real line from a scored verse; an invented one is never carved.
- If Claude fails, `verdict` is `""` and the carved line is the top-scoring verse's best line.

### `POST /battle/song`

Stitches every scored verse so far into one poem and calls `post_song`. Call it after round 1 to pre-stitch, and again after the last round.

`{"roomId": 10}` returns `{"lines": [{"turnId": 21, "text": "the wine dark sea took my brother's ship"}, …]}`.

- Demo rooms (`room.demo`) get at most 4 lines; others get at most 16.
- Song lines keep the poets' own words and cite their turn. If Claude fails, the song is each verse's best line, in order.

## Socratic debate

Debate runs on the same endpoints as poetry, with `event: "debate"`. Its host is Socrates, the rubric is `[claim, reason, answer, craft, poise]` (the order of `post_score`'s axes), the hand holds moves, and there is no beat. The content comes from `content/debate.md` and `content/moves.json`, read at runtime. The flow is in `docs/ux-flow.md`, section 8.

**What changes per endpoint:**

| Endpoint | With `event: "debate"` |
| --- | --- |
| `POST /judge`, `POST /battle/judge` | Also send `side` (the side dealt), `turnSeconds`, and `spokenSeconds` (Go to the end of the turn). `played` is the moves tapped (P17). The result's `scores` are the five debate axes. `scan` is `null`, and there are three extras: `delivery` (what Poise was measured from), `made` (move ids the judge heard made, tapped or not) and `tappedUnmade` (tapped but not made, so they earn no Craft). `coined` is always `""`. |
| `POST /battle/deal` | The room's `event` is read from SQL. `theme` may be a question's id or words; when it's empty, the agent picks a question the room hasn't had. Each debater gets 8 move candidates with every role among the first four. `round.theme` is the question, exactly as Socrates asks it. |
| `POST /deal` | Returns `{"theme": question, "question": Question, "hand": [MoveCard]}`. |
| `POST /rescue` | Send `hand`, `played`, `previous` (the turn being answered), `elapsedS`, `turnSeconds` and `whispers` (from `/debate/whispers`). Returns `{"whisper": "What do you mean by fair?", "card": MoveCard}`: a move whose role fits the moment (open early, attack once there's a turn to answer, close in the last ~12 s), and its prepared whisper or, failing that, its filled template. Asking the whisper plays that move. |
| `POST /spar` | `{event, theme, side, lines, answerTo}` returns `{"theme", "side", "lines"}`: Socrates' turn, mostly questions. |
| `POST /battle/verdict` | Socrates' lead-in, then the carved sentence. |
| `POST /battle/song` | The finale is Socrates' last question: `post_song` gets two lines, the night's strongest point quoted, then the question nobody answered. Both cite the quoted turn. If Claude fails, the top turn's best line stands alone. |
| `POST /battle/poet` | Socrates names the debater (the epithet carries over between events). |

**Poise** is measured, never scored by Claude, the way Beat comes from the scanner. It counts fillers ("um", "uh", "you know", and ", like,"), checks the pace stays within 120–180 words a minute, counts dead air (silences of 2 s or more, plus each freeze rescue), and checks the debater kept the floor (at least a word a second of the turn). Pace uses word timings when there are any, else `spokenSeconds`, else `turnSeconds`.

**MoveCard** is `FormulaCard` with `kind: "move"`, plus `role` (`open`, `attack`, `defend` or `close`) and `template`, how the move sounds as a question:

```json
{"id": "counterexample", "text": "counterexample", "kind": "move", "used": false, "beats": 0, "hoard": false,
 "role": "attack", "template": "What about {case}?"}
```

**Question:** `{"id": "invisible", "ask": "If you could turn invisible, would you stay honest?", "sides": ["Yes", "No"], "kind": "classic"}`. Sides alternate by turn order: turn 0 argues `sides[0]`, turn 1 `sides[1]`, and so on.

### `GET /debate`

`{"questions": [Question], "moves": [MoveCard], "lines": {"shared": {…}, "training": {…}, "battle": {…}}}` from `content/debate.md`. Lines are keyed by the "When" column. Repeated rows (the verdict samples) become `"Verdict, a sample 2"`, `"… 3"`.

### `POST /debate/whispers`

At step-up (ux-flow T1): one rescue question per move in the hand, so the freeze rescue plays instantly.

```json
{"question": "If you could turn invisible, would you stay honest?", "side": "No",
 "hand": ["counterexample", "ask for proof", "…"], "previous": "the turn this debater answers, if any"}
```

Returns `{"whispers": {"counterexample": "What about people who lie once nobody's watching?", …}}`. Each is a single question under ten words, in the debater's own voice. Every move gets its filled template first, and Claude's version replaces it only if it passes. It takes about 3 s, so call it at step-up, not at the freeze.

**Voices:** `/voice/token`'s `tts.voices` is `{"homer": "…", "socrates": "…"}`. Socrates' voice is empty until Matus picks one.

