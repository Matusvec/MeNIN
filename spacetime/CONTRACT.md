# Homer battle contract (SpacetimeDB)

This is the shared state for **Battle mode** only. Bard and Practice are single-device and talk to the agent service directly, so they are not modeled here. The module lives in `src/index.ts`; if this file and the code disagree, fix one of them.

**Events.** Each game is a config on one engine (SPEC "The games"). `room.event` picks it: `poetry`, `debate`, `discus`, `coach`, `stadion` or `pygmachia`. The module knows how many score axes an event has, what kind of card the hand holds (`EVENTS` in `src/index.ts`), and its turn timing (`turnWindow`). The axis labels, the host, the beat on or off, and the copy all live in the app's event config.

| Event | Axes | Hand | Turn | Agent |
| --- | --- | --- | --- | --- |
| `poetry` | 5: beat, craft, image, answer, range | `formula` cards | free verse: a 2.25 s count-in (3-2-1), then one window of turn_seconds (10 s a line; the demo's 2 lines = 20 s) | yes |
| `debate` | 5: claim, reason, answer, craft, poise | `move` cards | a 3 s count-in, then 45 s | yes, the same endpoints as poetry |
| `discus` | none | empty | no count-in, 30 s in the circle | **none**: see [Discus](#discus) |
| `coach` | none, or the 5 poetry axes for a verse attempt; Homer's reply is `score.verdict` | empty | free verse: 2.25 s count-in, then 20 s | yes: the theme, then a reply per turn; see [Coach](#coach) |
| `stadion` | none | empty | no turns: everyone runs at once, a 3 s count-in, then up to 40 s | **none**: see [Stadion](#stadion) |
| `pygmachia` | none | empty | no turns: two fighters live, a 3 s count-in, then 60 s or a knockout | **none**: see [Pygmachia](#pygmachia) |

An open hall switches events with `set_event`, keeping its poets (P16).

Server: SpacetimeDB 2.13. Databases: `homer-calhacks` on Maincloud is the demo (the app, the website and the agent); `homer-test` on a local server is smoke's; `homer` is the old local dev database.

## Who's who

| Role | What it is | Talks to |
| --- | --- | --- |
| **arena** | The app in arena mode (Mac, iPad, or mirrored phone). Creates the room and becomes its `host`. Runs the flow, plays Homer's voice, renders the scene. It can also join as a poet. | SpacetimeDB, and the agent service over HTTP |
| **phone** | A poet's app: mic, private hand, controls. | SpacetimeDB only (plus Cartesia STT and the agent's `/rescue`) |
| **agent** | The Python service. It calls reducers over HTTP with its own identity. | SpacetimeDB HTTP API |
| **scheduler** | SpacetimeDB itself. It ends turns on time. | — |
| **owner** | Whoever published the module (the CLI login). It sets the service key once. | CLI |

The rule: **phones and the arena change state through reducers. Anything Claude, the scanner or the formula bank produces is written by the agent.** The arena is the only client that asks the agent to do battle work: it sees a phase change, calls the agent's HTTP endpoint, and the result arrives back through its subscription, never through the HTTP response.

## Changing this contract

Any change to a table schema or a reducer signature waits for the iOS lead's OK before it's published to **any database a build can reach**. That includes Maincloud `homer-calhacks`, which devices use by default, and the local `homer` while devices test against it. Prefer additive changes, such as a new last column with a default, so live data migrates without a reset.

## Conventions

- Tables, columns and reducers are **snake_case** on the wire: `room.current_turn_id`, `post_score`. (The TypeScript source uses camelCase; the module converts.)
- Reducer arguments are **positional**, in the order listed below.
- Tables are **flat**: primitive columns and arrays of primitives. No options, enums or nested structs in any row a client reads.
- "None" is `0` for ids, `''` for strings, and the Unix epoch (`0`) for timestamps. Auto-increment ids start at 1.
- `Timestamp` is i64 microseconds since the Unix epoch. `Identity` is a 32-byte (u256) value.
- `phase` and `status` are plain strings, with the values listed below.
- A reducer that rejects a call throws a `SenderError` with a short message. Over HTTP that is status 530 with the message as the body. Over the SDK it is a failed reducer result. Nothing is half-applied: a reducer either commits everything or nothing.

## The phase machine (`room.phase`)

```
lobby ─start_battle─▶ dealing ─deal_round─▶ ready ─start_turn─▶ speaking ─end_turn / timer─▶ judging ─post_score─▶ scored
          (theme ─choose_theme─▶ dealing,           ▲    ▲                                      │decline_turn / skip_turn   │
           when theme_choice is on)                 │    └── silent first attempt: retry ◀──────┘                           │
                                                    └──────────────── advance (next turn) ◀─────────────────────────────────┘
scored ─advance (last turn)─▶ round_end ─advance─▶ ready (next round, if dealt) │ dealing / theme (if not) │ finale (after the last round)
finale ─advance─▶ finished
any phase but lobby ─rematch─▶ dealing (or theme)
lobby │ finished ─set_event─▶ lobby (another event, same poets)

discus:  lobby ─start_battle─▶ ready ─start_turn─▶ speaking ─throw_discus(_full) / timer─▶ scored
         scored ─advance─▶ ready (next thrower, or the next round's first) │ finale (after the last throw) ─advance─▶ finished

stadion: lobby ─start_battle─▶ ready ─start_race─▶ speaking (racing) ─all across / cap─▶ scored
         scored ─advance─▶ ready (next heat) │ finale ─advance─▶ finished

pygmachia: lobby ─start_battle─▶ ready ─start_fight─▶ speaking (fighting) ─knockout / bell─▶ scored
           scored ─advance─▶ ready (next bout: winner stays on) │ finale ─advance─▶ finished
```

| Phase | Meaning | Who moves it on |
| --- | --- | --- |
| `lobby` | Poets join. Entrances get announced. | arena: `start_battle` |
| `theme` | Only when `theme_choice` is on: the arena shows 3 theme cards and the judges tap one. | arena: `choose_theme` |
| `dealing` | Waiting for the agent to set the theme and deal hands. | agent: `deal_round` |
| `ready` | `current_turn_id` is up. The poet steps up and taps Ready (or the arena auto-starts). | phone or arena: `start_turn` |
| `speaking` | The verse is live: transcript, prosody and scene stream. | phone: `end_turn`, or the scheduler at `ends_at` + 2 s |
| `judging` | The verse is with the judge. | agent: `post_score` or `decline_turn`; arena: `skip_turn` |
| `scored` | The verdict and scores are shown. | arena: `advance` |
| `round_end` | The round verdict and the carved line are shown. | arena: `advance` |
| `finale` | The stitched song, then the crown. | arena: `advance` |
| `finished` | Final standings. | arena: `rematch` |

Turn `status`: `waiting` → `speaking` → `judging` → `scored`, or `skipped` (a no-show, silence twice, or the arena gave up on the judge) or `declined` (the judge refused it).

## Tables

All public tables carry `room_id`, so a client subscribes to exactly one room. **Writer** is who changes the row, always through the reducers listed.

### `room` (public). Writers: arena, agent (phase only, via `deal_round`), scheduler.

| Column | Type | Notes |
| --- | --- | --- |
| id | u64 | primary key |
| event | String | `poetry` (later `debate` or `discus`) |
| code | String | 4 letters, no I or O, unique. Phones join with it (QR or typed); the match is case-insensitive. |
| host | Identity | the arena that created it |
| phase | String | see the phase machine |
| round_no | u32 | 0 in the lobby, then 1..rounds |
| rounds | u32 | 3 by default; 1 in demo |
| turn_seconds | u32 | the speaking window, beat_at to ends_at. Poetry: lines_per_turn × 10 s (free verse, no bars; the demo is 20 s). Debate 45, discus 30. Set when the room is made or switched; start_turn uses the stored value. |
| lines_per_turn | u32 | 4 by default; 2 in demo |
| bpm | u32 | the beat's tempo |
| form | String | `four_beat` or `hexameter` |
| max_players | u32 | 5, or 2 in demo |
| auto_ready | bool | the arena starts each turn itself; phones show no Ready button. Always on in demo. |
| theme_choice | bool | each round opens with the `theme` phase |
| demo | bool | demo mode (SPEC "Demo mode") |
| next_theme | String | the theme the judges picked, until it is dealt |
| current_turn_id | u64 | the turn that is up, live or being judged; 0 between rounds |
| created_at | Timestamp | |
| bars_per_line | u32 | 2: each line is a speaking bar plus a rest bar; 1: no rest bars. Battles no longer use it (free verse): it is kept, with bpm, for lessons and Practice. It is the last column, appended so live databases migrate without a reset. |

### `player` (public). Writers: phone, agent.

| Column | Type | Notes |
| --- | --- | --- |
| id | u64 | primary key |
| room_id | u64 | |
| identity | Identity | the phone's identity |
| name | String | as typed, 1–24 characters. The agent may replace it if it isn't PG. |
| epithet | String | "Breaker of Deadlines". `''` until the agent coins one. |
| named | bool | the agent approved the name and epithet; the arena may speak them |
| entered | bool | the mic check passed; the arena announces the entrance once |
| hoard | [String] | the phone's coined formulas, sent at join so the dealer can use them |
| seat | u32 | join order; turn order rotates over seats each round |
| total | u32 | running battle total |
| connected | bool | has at least one live WebSocket connection (counted per connection, so an old socket closing after a reconnect doesn't clear it). HTTP-only callers read as false. |
| joined_at | Timestamp | |

### `round` (public). Writer: agent.

| Column | Type | Notes |
| --- | --- | --- |
| id | u64 | primary key |
| room_id, round_no | u64, u32 | |
| theme | String | Homer announces it |
| verdict | String | Homer's round verdict; `''` until posted |
| best_turn_id | u64 | the turn the carved line came from |
| best_line | String | carved in gold across the arena |
| dealt_at | Timestamp | |

### `hand` (private to its owner). Writers: agent (`deal_round`), phone (`play_card`).

| Column | Type | Notes |
| --- | --- | --- |
| player_id | u64 | primary key; one hand per poet for the whole battle |
| room_id | u64 | |
| kind | String | `formula` for poetry (debate: `move`) |
| cards | [String] | up to 5 |

Row-level security: a client only receives the hand rows of its own players. `SELECT * FROM hand WHERE room_id = N` is safe to subscribe to on every device. Unplayed cards carry over between rounds, and each deal tops the hand back up to 5, so you can save a card for the last round.

### `turn` (public). Writers: phone, arena, agent, scheduler.

| Column | Type | Notes |
| --- | --- | --- |
| id | u64 | primary key |
| room_id, round_id, player_id | u64 | |
| turn_no | u32 | 0-based position in this round's order |
| status | String | see above |
| attempt | u32 | 1, or 2 after a silent retry ("I heard the wind. Again.") |
| transcript | String | live while speaking, final afterwards. Lines are separated by `\n`. |
| played | [String] | cards spoken from the hand, in order (card reveal, P8) |
| rescue | String | the last card Homer whispered (freeze rescue) |
| rescues | u32 | goes up by one per whisper; the arena whispers when it changes |
| started_at | Timestamp | when Ready was tapped; the count-in starts here |
| beat_at | Timestamp | when the poet speaks: started_at + the count-in (poetry 2.25 s, debate 3 s, discus 0) |
| ends_at | Timestamp | beat_at + turn_seconds. The phone ends the turn at ends_at with its final words; the scheduler closes it at ends_at + 2 s if the phone hasn't. |

### `score` (public). Writer: agent.

| Column | Type | Notes |
| --- | --- | --- |
| turn_id | u64 | primary key, one per scored turn. Skipped and declined turns have none. |
| room_id, round_id, player_id | u64 | |
| axes | [u8] | one 0–10 value per axis, in the order of the event's rubric. Poetry: `[beat, craft, image, answer, range]`. Beat and Range are always 1–10. Craft, Image and Answer are 0 when Claude couldn't score them in time ("Homer is silent on this one"). |
| total | u32 | sum of the axes |
| verdict | String | one line, spoken |
| best_line | String | the quoted line |
| coined | String | a new formula for the poet's hoard, or `''` |

### `scene` (public, one row per room). Writer: agent (`set_scene`).

`room_id` (primary key), `turn_id`, `player_id` (0 when idle), then eight f32 weights 0–1: `anger, grief, joy, awe, tenderness, fear, defiance, longing`, and `updated_at`. These are the raw classifier weights; the renderer does the smoothing.

### `color_sample` (public). Writer: agent (`set_scene`).

Every `set_scene` also appends `id, room_id, turn_id, ms` (milliseconds since `started_at`) and the eight weights. This is for replaying a verse's colors (P11 and the finale).

### `prosody` (public, one row per room). Writer: phone (`set_prosody`).

`room_id` (primary key), `turn_id` (0 in the lobby), `player_id`, `loudness` (0–1), `pitch` (Hz, 0 = unvoiced), and `hits`, a count of stressed syllables on the beat this turn. The arena plays a drum strike each time it goes up. Only the arena needs to subscribe.

### `reaction` (public, cuttable). Writer: anyone.

`id, room_id, kind` (≤16 characters, e.g. an emoji name), `at`. The arena bursts each new row into the scene.

### `song_line` (public). Writer: agent (`post_song`).

`id, room_id, line_no, turn_id` (whose verse it came from), `text`.

### `discus_throw` (public). Writer: phone (`throw_discus`, `throw_discus_full`).

`id, room_id, turn_id, player_id, throw_no` (the round number: each round is one throw each), `speed` (f32, peak rotation rate before release, rad/s), `angle` (f32, release angle in degrees above horizontal), `timing` (f32, speed at release over peak speed, 0–1), `distance` (f32, metres, 0 for a foul), `foul` (bool), `at` (when it landed in the database; the arena flies the discus from here), then the appended release columns, 0 / `''` from older phones: `release_speed` (f32, m/s off the hand), `roll` (f32, degrees the disc was tilted off flat), `spin` (f32, rad/s), `foul_reason` (`''`, `late` or `sector`). A turn that timed out has no row (its status is `skipped`). Older clients decode only the first eleven columns; the SDK ignores trailing ones.

### `heat` (public, one row per room). Writer: arena (`start_race`), the module.

`room_id` (pk), `heat_no`, `go_at` (the gun; epoch until `start_race`), `cap_at` (`go_at` + 40 s), `ended_at` (epoch while running).

### `runner` (public, one row per runner). Writer: phone (`set_stride`), the module.

`player_id` (pk), `room_id`, `heat_no`, `speed` (f32, m/s of game speed), `distance` (f32, metres, never down, at most 192), `place` (u32, 0 while running: the finish order, then the rest by distance at the end), `time` (f32, seconds from `go_at` to the line, interpolated; 0 for a runner who didn't cross), `updated_at`.

### `fight` (public, one row per room). Writer: arena (`start_fight`), the module.

`room_id` (pk), `go_at` (the bell; epoch until `start_fight`), `ends_at` (`go_at` + 60 s), `ended_at` (epoch while on), `winner_id` (0 for a draw, or not over), `ko` (bool).

### `fighter` (public, one row per fighter in the current bout). Writers: phone (`set_fist_aim`, `throw_punch`), the module.

`player_id` (pk), `room_id`, `seat` (0 = the one who stays on, 1 = the challenger), `health` (f32, 100 down to 0), `guard` (bool: the phone upright at the face; it covers the head only), `aim_yaw`, `aim_pitch` (f32, −1…1: left/right, low/high; the latest from the phone), `counter_until` (a block opens this fighter's 0.5 s counter window; epoch for none), `updated_at`. Poets not in the bout have no row: they're waiting.

### `punch` (public, insert-only, one row per punch). Writer: phone (`throw_punch`), resolved by the module.

`id` (insert order), `room_id`, `player_id`, `target_id`, `zone` (`head` if aimed at pitch ≥ 0, else `body`), `power` (f32, 0–1), `aim_yaw`, `aim_pitch`, `result` (`landed`, `blocked` or `missed`), `damage` (f32), `counter` (bool: landed inside the puncher's counter window), `at`, `t` (unused, 0), `kind` (`jab`, `hook` or `uppercut`, from the phone: flavour, for the animation).

### Private tables

`config` (the owner and the service key), `service` (the agent identities), `turn_timer` (the scheduled turn ends), `race_timer` and `fight_timer` (a heat's cap, a bout's final bell), and `presence` (one row per open connection: connection_id, identity; `player.connected` is true while an identity has any). No client sees these.

## Reducers

### Arena

| Reducer | Args | When | Effect |
| --- | --- | --- | --- |
| `create_room` | event String, rounds u32, bars_per_line u32 (1 or 2), lines_per_turn u32, bpm u32 (40–160), form String, auto_ready bool, theme_choice bool, demo bool | Tap "Start a battle". The demo is `("poetry", 1, 2, 2, 80, "four_beat", true, false, true)`: one 20 s window. bars_per_line and bpm are validated and stored but don't time a battle turn. The turn may not exceed 120 s. | A new room in `lobby`. demo forces 1 round, 2 lines, at most 4 poets and auto-ready. Any older lobby of this host is closed, so a double tap leaves one room. Find yours with `SELECT * FROM room WHERE host = <your identity>` and take the highest id. |
| `start_battle` | room_id | Begin (2+ poets) | `lobby` → `dealing` (or `theme`), with round_no = 1 |
| `choose_theme` | room_id, theme | A judge taps a card in `theme` | Sets `next_theme` and moves to `dealing`. The 3 cards come from the content bank on the arena. |
| `start_turn` | turn_id | auto_ready, or after the 5 s step-up wait | Same as the phone's Ready tap |
| `advance` | room_id | After each reveal finishes (verdict TTS, round verdict, song) | `scored` → next turn's `ready`, or `round_end`; `round_end` → next round, or `finale`; `finale` → `finished` |
| `skip_turn` | turn_id | A poet never steps up (the phone dropped: wait 10 s), or the judge never answers | The current turn is `skipped` and the phase becomes `scored` |
| `start_race` | room_id | Stadion: after "Runners, to your marks" | From `ready`: `go_at` = now + 3 s, `cap_at` = `go_at` + 40 s, `speaking`. Errors: `not a stadion`, `the runners are not on the line`. |
| `start_fight` | room_id | Pygmachia: the bell | From `ready`: `go_at` = now + 3 s, `ends_at` = `go_at` + 60 s, `speaking`. Errors: `not a fight`, `the fighters are not in their corners`. |
| `end_battle` | room_id | The host's End button (coach has no end of its own) | Any phase but lobby or finished: `finished`. The live turn (waiting, speaking or judging) becomes `skipped` and its timer is cancelled, so a late `end_turn` or `post_score` is refused. Works for any event. |
| `rematch` | room_id | "Rematch", or to un-wedge a demo | Any phase but lobby: clears rounds, turns, scores, samples, song, reactions and throws; zeroes totals; empties hands; goes straight to `dealing` (discus: straight to the first throw's `ready`). Poets, names, epithets and seats stay. |
| `set_event` | room_id, event String, rounds u32 (1–5; ignored in demo) | "New event" (P16), from `lobby` or `finished` | Switches `room.event` and resets the room like a rematch, then returns it to `lobby` so latecomers can join. Poets, names, epithets and seats stay; hands switch to the new event's card kind. turn_seconds and auto_ready follow the new event (auto_ready goes back to the demo default when leaving discus). Errors: `finish this event first`, `unknown event`. |

### Phone

| Reducer | Args | When | Effect |
| --- | --- | --- | --- |
| `join_room` | code, name, epithet (may be `''`), hoard [String] | J1 Enter | Joins in the lobby. Calling it again from the same identity is a reconnect, in any phase, `finished` included, since the hall stays open between events (the app's auto-rejoin after a force-quit); seat, total, hand and turns are kept. In the lobby a rejoin may also rename, and `''` and `[]` keep the current epithet and hoard. A new identity with the **same name as a disconnected poet** takes over that seat (a phone that died rejoins and keeps its scores). Errors: `no such room` (also for anyone new once the room is `finished`), `the hall is full`, `that name is taken`, `the battle has already begun`. |
| `leave_room` | room_id | Leave | Lobby: removes the poet. Later: marks them disconnected. |
| `enter` | room_id | The mic check heard you | `entered` = true; the arena announces the entrance |
| `start_turn` | turn_id | Ready tap in `ready` | `speaking`. Sets started_at, beat_at and ends_at, and schedules the timer. |
| `update_transcript` | turn_id, transcript | Every STT partial while speaking | Replaces the transcript (max 4000 characters). Speaker only. |
| `play_card` | turn_id, card | The phone matched a card in the transcript | Moves the card from the hand to `turn.played`. It's gone for good. |
| `rescue` | turn_id, card | About 1 s of silence mid-line. The phone picks the card, optionally via the agent's `/rescue`. | Sets `turn.rescue`, `rescues` += 1. The card must be in the hand. |
| `end_turn` | turn_id, final transcript | All lines spoken, Done tapped, or the mic closed at ends_at | An empty transcript on attempt 1 goes back to `ready` with attempt 2. Empty on attempt 2 is `skipped`. Otherwise `judging`. |
| `set_prosody` | room_id, loudness f32, pitch f32, hits u32 | About 20 Hz while you're the speaker. In the lobby any poet may send it (the entrance flare). | Overwrites the room's prosody row. Frames from anyone else, or in other phases, are dropped silently. |
| `react` | room_id, kind | A spectator or poet taps a reaction | Inserts a reaction |
| `throw_discus_full` | turn_id, speed, angle, timing, distance, foul, release_speed f32, roll f32, spin f32, foul_reason String | Newer phones, instead of `throw_discus` | The same as `throw_discus`, plus the release columns (release_speed 0–40, roll −180–180, spin 0–60, foul_reason `''`/`late`/`sector`). |
| `set_stride` | room_id, speed f32, distance f32 | Stadion: about 10 Hz while running | Never an error. Ignored before `go_at`, after crossing, or outside a race. distance is kept monotone and clamped to 25 m/s × elapsed; crossing 192 m places and times the runner; when all are across (or at the cap) the rest are placed by distance and the room moves to `scored`. Points by place go to `player.total` (last gets 1). |
| `set_fist_aim` | room_id, yaw f32, pitch f32, guard bool | Pygmachia: about 20 Hz while fighting | The fighter's aim (clamped to −1…1) and guard. Silent outside a fight. |
| `throw_punch` | room_id, kind String, power f32, yaw f32, pitch f32 | Pygmachia: one per punch | Silent before the bell, after it, for a poet not in the bout, or faster than 4 a second. |yaw| > 0.5 misses; a head punch into a raised guard is blocked (the blocker's counter window opens); otherwise it lands for 4 + 12·power, ×1.5 inside your own counter window. Punching drops your guard. Health 0 is a knockout. |
| `throw_discus` | turn_id, speed f32, angle f32, timing f32, distance f32, foul bool | Discus: once, when the thrower's thumb lifts | Thrower only, while the turn is `speaking`. Refused out of range (speed 0–60, angle −90–90, timing 0–1, distance 0–100). Inserts a `discus_throw` (distance 0 if foul), marks the turn `scored`, raises `player.total` to the best throw in tenths of a metre, and moves to `scored`. |

### Agent service

All of these require the caller to be a registered service identity (or the owner).

| Reducer | Args | Arena trigger | Effect |
| --- | --- | --- | --- |
| `name_poet` | player_id, name, epithet | A player row with `named` = false | Sets a PG name and an epithet (coins one if `''`), and `named` = true |
| `deal_round` | room_id, round_no, theme, hands [[player_id, [card]]] | The phase is `dealing`; or `round_end` for round_no + 1, to deal ahead (not with theme_choice) | Creates the round and its turns in rotated seat order, and tops each hand up to 5 from that poet's list (send at least 5 candidates each, skipping duplicates). In `dealing` it moves to `ready`. It must cover every poet, and each round is dealt once. |
| `post_score` | turn_id, axes [u8], verdict, best_line, coined | The turn's status is `judging` | Inserts the score, adds to the poet's total, and moves to `scored`. The total is the axes weighted in rubric order: poetry [0, 2, 4, 4, 0] (beat/flow, craft, image, answer, range: content only; at most 100 a verse), debate [1, 1, 1, 1, 1] (at most 50). `axes` is stored as sent, in rubric order. It refuses the wrong number of axes for the room's event. Coach takes either `[]` (a talk-back reply, total 0) or the 5 poetry axes (a verse attempt, weighted like poetry). |
| `decline_turn` | turn_id | The verse isn't fit for the hall | The turn is `declined`, scores nothing, and the phase becomes `scored` |
| `post_verdict` | round_id, verdict, best_turn_id, best_line | The phase is `round_end` | Sets the round verdict and the carved line (once per round) |
| `post_song` | room_id, turn_ids [u64], lines [String] | Any time after round 1 (pre-stitch); performed at `finale` | Replaces the song (max 16 lines; the demo cap of 4 is the agent's job) |
| `set_scene` | turn_id, then the 8 weights f32 | Every ~1.5 s while the turn is speaking or judging | Updates `scene` and appends a `color_sample`. Updates for a turn that isn't current are dropped silently. **Guaranteed:** `set_scene` on turn 0 is a silent no-op for a registered service and is refused for anyone else, so the agent can use it to check its registration. |

### Owner and setup

| Reducer | Args | Who | Effect |
| --- | --- | --- | --- |
| `set_service_key` | key (16+ characters) | owner, from the CLI | Stores the key the agent registers with |
| `claim_service` | key | agent, once at startup | Registers the caller's identity as a service. The registration lasts until a data reset. An identity that's already registered succeeds whatever key it sends, so a rotated key never breaks the agent's startup. |
| `turn_timeout` | — | scheduler only | Closes a turn still `speaking` at ends_at + 2 s, with the last transcript it got. A discus turn with no throw is `skipped`. |

## Calling it from the agent service (Python, no SDK)

There is no Python SDK. The agent uses the HTTP API; this has been verified against the local server.

```
POST {STDB_URL}/v1/identity                          -> {"identity": "...", "token": "..."}   once; keep the token in .env
POST {STDB_URL}/v1/database/homer/call/<reducer>     Authorization: Bearer <token>
     Content-Type: application/json
     body: JSON array of positional args, e.g. post_score:
     [42, [8, 7, 6, 5, 4], "Strong bones.", "took my brother's ship", "storm-throated"]
     -> 200 on success; 530 with the error text if the reducer refused
POST {STDB_URL}/v1/database/homer/sql                body: one SQL statement (public tables only)
     -> [{"schema": {...}, "rows": [[...], ...]}]
```

JSON encoding: u64 and other integers are JSON numbers, and bools and strings are plain. An array of structs is an array of arrays, so `deal_round`'s hands are `[[1, ["the whale-road", ...]], [2, [...]]]`. In SQL results there are three quirks:
- A `[u8]` column such as `score.axes` comes back as a hex string (`"0807060504"`), even though calls take a plain array.
- An Identity comes back as `["0x…"]`.
- A Timestamp comes back as `[micros]`.

One-time setup:

```
spacetime call -s local homer set_service_key <random 32-char key>    # as the owner
# agent startup: POST /v1/identity (first run only), then call claim_service [key]
```

`spacetime/scripts/smoke.mjs` does all of this end to end and is the reference client.

### Agent HTTP endpoints the arena calls (final version: homer/API.md)

The arena calls these and ignores the response body; results arrive through SpacetimeDB. Every reducer refuses duplicates, so the arena can retry safely.

| Endpoint | Arena calls it when | Agent then calls |
| --- | --- | --- |
| `POST /battle/poet` {player_id, name, epithet} | A player has `named` = false | `name_poet` |
| `POST /battle/deal` {room_id, round_no, theme or ""}. The agent reads event, demo, form, timing and each poet's hoard from SQL. | `dealing`, or early in `round_end` | `deal_round` |
| `POST /battle/emotion` {turn_id, transcript} | Every ~1.5 s while `speaking` | `set_scene` |
| `POST /battle/judge` {turn_id, form, theme, transcript, played, rescues, previous_best_line} | The turn reaches `judging` | `post_score` or `decline_turn` |
| `POST /battle/verdict` {round_id, theme, verses: [{turn_id, name, transcript, score}]} | `round_end` | `post_verdict` |
| `POST /battle/song` {room_id, verses} | Rounds 1–2 done, then the last round | `post_song` |
| `POST /rescue` {transcript, hand, form} → {card} | Called by the **phone** and answered inline (latency matters) | — (the phone calls `rescue`) |

The hand is private, so the judge sees `played` (the cards actually spoken), not the whole hand. If Craft needs the full hand, the agent can remember what it dealt.

## Coach

Judge mode (SPEC "The website"): a conversation with Homer. Phones speak, the arena shows the words and speaks Homer's replies.

- `create_room` with event `"coach"` (the same arguments; rounds is stored as 1): auto_ready is forced on, turn_seconds is 20, and hands are empty (kind `''`).
- `start_battle` needs only one poet and goes to `dealing`. The agent deals the theme with `deal_round(room, 1, theme, hands)`, where hands may be `[[player_id, []], …]` or `[]`.
- Each turn is a free-verse poetry turn: `beat_at` = `started_at` + 2.25 s, `ends_at` = `beat_at` + 20 s, the timer at `ends_at` + 2 s, one retry on silence.
- The agent answers with `post_score(turn_id, [], reply, '', '')`: no axes (any are refused), total 0, and the reply (up to 600 characters) is `score.verdict`.
- `advance` from `scored` goes to the next poet in seat order. After the last poet, the next cycle of turns is appended to the same round (turn_no keeps counting; round_no stays 1), so a solo poet gets every turn. There is no round_end or finale: the host ends it with `end_battle`.
- Turns, transcripts and replies stay until a rematch, which starts a fresh conversation in `dealing`.

## Stadion

Everyone races at once (SPEC "The games"): no turns, no Claude.

- `start_battle` (one runner is enough: a time trial) lays out the heat (`heat_no` = `round_no`) and a `runner` row per poet at 0 m, and goes to `ready`. The arena calls `start_race` after Homer's marks.
- The phones show the 3-2-1 off `heat.go_at`, then stream `set_stride` with their own integrated distance. The module places each runner as they cross 192 m and ends the heat when all are across or at `cap_at`.
- `scored` shows the places and times; `advance` goes to the next heat or the finale. The champion is the best `player.total` (points by place).

## Pygmachia

Boxing (SPEC "The games"), lean v1: health only, 60 s or a knockout, no Claude.

- `start_battle` needs two poets. With three or four it's winner-stays-on: `room.rounds` = poets − 1 bouts; bout 1 is seats 0 and 1, then the last winner (the incumbent on a draw) meets the next seat. `fighter` holds the two in the current bout.
- The phones calibrate centre at `fight.go_at` and stream `set_fist_aim` (with the guard) and `throw_punch`; the module resolves each punch into a `punch` row and the fighters' health.
- A knockout or the bell ends the bout (`winner_id`, `ko`; the most health wins at the bell, equal is a draw); the winner's `player.total` goes up by one, and the room goes to `scored`.

## Discus

Discus is a motion minigame: no voice, no Claude, no agent (SPEC "The games", UX flow section 9). It reuses rooms, rounds and turns:

- `create_room` with event `"discus"` and rounds = throws each (3 is the format; best counts). The poetry fields must still be valid (pass the standard preset's) because they are kept for `set_event`. auto_ready is forced on and turn_seconds is 30.
- `start_battle` lays out the round's turns itself (rotated seat order, like `deal_round`) and goes straight to `ready`. The arena's auto-start calls `start_turn` after its step-up wait, so `speaking` means "the thrower is in the circle" (D1 and D2), with `beat_at` = `started_at` and `ends_at` 30 s later.
- While the thumb is down, the thrower's phone streams the wind-up over `set_prosody`: `loudness` = swing power 0–1, `pitch` = 0, `hits` = 1 while the discus is held and 0 otherwise. The arena drives its power gauge and the scene's instant layer from it.
- Release is the thumb lifting, never motion alone. The phone computes the distance (one formula, in the app) and calls `throw_discus` once (newer phones: `throw_discus_full`, with the release in detail). The arena reads the new `discus_throw` row, flies it, and calls `advance` after the reveal (D3 to D6). The release angle counts from 10° up (lower falls back to the swing plane's tilt); the sector heading is recorded, but `sector` isn't a foul until it's checked on a real phone.
- No throw by `ends_at` + 2 s: the scheduler marks the turn `skipped` and moves to `scored`; there is no retry.
- `advance` from `scored` goes to the next thrower, or straight into the next round's first throw (no `round_end`), then `finale` (the champion) and `finished`. `end_turn` is refused in a discus room.
- The leaderboard: `player.total` is each poet's best in tenths of a metre; the throws themselves are in `discus_throw`.
- The arena does **not** call the agent for a discus room.

## Timing and rates

- **Poetry (free verse)**: `beat_at` = `started_at` + 2.25 s (the 3-2-1), `ends_at` = `beat_at` + turn_seconds (20 s in the demo). No beat grid and no bars in a battle; lessons and Practice may still use bpm and bars_per_line for their own drills. Each device estimates its offset from server time when `status` flips to `speaking` (offset = local receive time − `started_at`), good to a network one-way trip (~50–150 ms).
- **Prosody**, about 20 Hz: fine for SpacetimeDB, since each call is one small transaction. Keep **at most one `set_prosody` in flight** and drop frames rather than queue them, so a bad network can't build lag. The arena interpolates. Expect 100–200 ms phone-to-arena.
- **Transcript**: on each STT partial (a few per second). `end_turn` carries the final.
- **Scene**: about every 1.5 s, from the agent.
- **Debate**: `beat_at` = `started_at` + 3 s (the three-count), `ends_at` = `beat_at` + 45 s. No beat grid.
- **Discus**: `beat_at` = `started_at`, `ends_at` = 30 s later. The wind-up streams over `set_prosody` at about 20 Hz, under the same one-in-flight rule.

## Running it

```
spacetime start                          # local server on :3000 (all interfaces)
cd spacetime && npm install
npm run typecheck
npm run publish:local                    # keeps data; publish:local:reset wipes it
npm run publish:test                     # the isolated test database `homer-test` (no dev-agent, no shared key)
npm run smoke                            # poetry, discus, set_event, debate, coach, stadion and pygmachia over HTTP against homer-test, 171 checks (~3 min)
npm run logs
```

If the CLI's login isn't the database owner (for example, after logging in to Maincloud), point `smoke` and `dev-agent` at the owner's config: `STDB_CLI_CONFIG=/path/to/owner/cli.toml`.

**Dev stand-in agent (never in the demo path).** `HOMER_DEV_AGENT=1 npm run dev-agent` watches the database and does the agent's job with placeholders: it names poets, deals stock cards, posts patterned scores, drifts the scene, and writes the verdict and song. Every theme and verdict it writes starts with `[dev]`. It refuses to run without the flag. Add `HOMER_DEV_ROOM=ABCD` to limit it to one room, or `HOMER_DEV_SKIP_HOSTS=<hex>,…` to leave alone the rooms hosted by those arena identities (for example the real agent's test rooms). It polls every 400 ms while a turn is dealing, speaking or judging, and every 1.5 s otherwise. Stop it before the real agent service runs, and don't run `smoke` alongside it (they would both act as the agent).

Clients: in dev, `ws://<mac LAN IP>:3000` with database `homer`. **Maincloud** (live, 2.13.0): `https://maincloud.spacetimedb.com` with database `homer-calhacks`. Run smoke there with `STDB_URL=https://maincloud.spacetimedb.com STDB_DB=homer-calhacks STDB_SERVER=maincloud npm run smoke`. The demo runs on Maincloud; see HOSTING.md.

## Open items

- **Swift client: GO.** It uses avias8/spacetimedb-swift (the 2.x protocol, iOS 18), vendored in `ios/`, with hand-written row types. Key every cache by primary key; the SDK's update pairing isn't reliable.
- `TODO(spec):` `player.hoard` is public, so opponents can see a poet's hoard (not their hand). Making it private means the agent reads it some other way.
- `TODO(spec):` rejoining by name lets anyone take a *disconnected* poet's seat by typing their name. That's fine for one room at a table, but not for the open internet.
- Ties: the clients compute the winner from `player.total`. Ties are UX open question 6.
- Ranks (Elo) are not modeled; they are first in the cut order.
