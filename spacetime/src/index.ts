// Homer battle module. CONTRACT.md is the reference for every table and
// reducer: who calls it, when, and what it changes.
//
// Tables stay flat (primitive columns, arrays of primitives) so a hand-written
// Swift client can decode them. "None" is 0 for ids, '' for strings, and the
// Unix epoch for timestamps.

import { ScheduleAt, Timestamp } from 'spacetimedb';
import {
  schema,
  table,
  t,
  SenderError,
  type Infer,
  type InferSchema,
  type ReducerCtx,
} from 'spacetimedb/server';

// ---------------------------------------------------------------- tables

const room = table(
  { public: true },
  {
    id: t.u64().primaryKey().autoInc(),
    event: t.string(),
    code: t.string().unique(),
    host: t.identity(),
    phase: t.string(),
    roundNo: t.u32(),
    rounds: t.u32(),
    turnSeconds: t.u32(),
    linesPerTurn: t.u32(),
    bpm: t.u32(),
    form: t.string(),
    maxPlayers: t.u32(),
    autoReady: t.bool(),
    themeChoice: t.bool(),
    demo: t.bool(),
    nextTheme: t.string(),
    currentTurnId: t.u64(),
    createdAt: t.timestamp(),
    // Appended with a default so existing databases migrate without a reset.
    barsPerLine: t.u32().default(2),
  }
);

const player = table(
  { public: true },
  {
    id: t.u64().primaryKey().autoInc(),
    roomId: t.u64().index('btree'),
    identity: t.identity().index('btree'),
    name: t.string(),
    epithet: t.string(),
    named: t.bool(),
    entered: t.bool(),
    hoard: t.array(t.string()),
    seat: t.u32(),
    total: t.u32(),
    connected: t.bool(),
    joinedAt: t.timestamp(),
  }
);

const round = table(
  { public: true },
  {
    id: t.u64().primaryKey().autoInc(),
    roomId: t.u64().index('btree'),
    roundNo: t.u32(),
    theme: t.string(),
    verdict: t.string(),
    bestTurnId: t.u64(),
    bestLine: t.string(),
    dealtAt: t.timestamp(),
  }
);

// One hand per player for the whole battle. Unplayed cards carry over and
// each deal tops the hand back up. Each client sees only its own (handFilter).
const hand = table(
  { public: true },
  {
    playerId: t.u64().primaryKey(),
    roomId: t.u64().index('btree'),
    kind: t.string(),
    cards: t.array(t.string()),
  }
);

const turn = table(
  { public: true },
  {
    id: t.u64().primaryKey().autoInc(),
    roomId: t.u64().index('btree'),
    roundId: t.u64().index('btree'),
    playerId: t.u64(),
    turnNo: t.u32(),
    status: t.string(),
    attempt: t.u32(),
    transcript: t.string(),
    played: t.array(t.string()),
    rescue: t.string(),
    rescues: t.u32(),
    startedAt: t.timestamp(),
    beatAt: t.timestamp(),
    endsAt: t.timestamp(),
  }
);

const score = table(
  { public: true },
  {
    turnId: t.u64().primaryKey(),
    roomId: t.u64().index('btree'),
    roundId: t.u64(),
    playerId: t.u64(),
    axes: t.array(t.u8()), // in the order of the event's rubric
    total: t.u32(),
    verdict: t.string(),
    bestLine: t.string(),
    coined: t.string(),
  }
);

// The color layer: the latest emotion weights for the room's speaker.
const scene = table(
  { public: true },
  {
    roomId: t.u64().primaryKey(),
    turnId: t.u64(),
    playerId: t.u64(),
    anger: t.f32(),
    grief: t.f32(),
    joy: t.f32(),
    awe: t.f32(),
    tenderness: t.f32(),
    fear: t.f32(),
    defiance: t.f32(),
    longing: t.f32(),
    updatedAt: t.timestamp(),
  }
);

// Every scene update, kept so the arena can replay a verse's colors.
const colorSample = table(
  { public: true },
  {
    id: t.u64().primaryKey().autoInc(),
    roomId: t.u64().index('btree'),
    turnId: t.u64().index('btree'),
    ms: t.u32(),
    anger: t.f32(),
    grief: t.f32(),
    joy: t.f32(),
    awe: t.f32(),
    tenderness: t.f32(),
    fear: t.f32(),
    defiance: t.f32(),
    longing: t.f32(),
  }
);

// The instant layer: the speaking phone overwrites this row at ~20 Hz.
const prosody = table(
  { public: true },
  {
    roomId: t.u64().primaryKey(),
    turnId: t.u64(),
    playerId: t.u64(),
    loudness: t.f32(),
    pitch: t.f32(),
    hits: t.u32(),
  }
);

const reaction = table(
  { public: true },
  {
    id: t.u64().primaryKey().autoInc(),
    roomId: t.u64().index('btree'),
    kind: t.string(),
    at: t.timestamp(),
  }
);

const songLine = table(
  { public: true },
  {
    id: t.u64().primaryKey().autoInc(),
    roomId: t.u64().index('btree'),
    lineNo: t.u32(),
    turnId: t.u64(),
    text: t.string(),
  }
);

// Discus: one row per throw. The thrower's phone measures the swing and
// computes the distance; the module only checks the numbers are sane.
const discusThrow = table(
  { public: true },
  {
    id: t.u64().primaryKey().autoInc(),
    roomId: t.u64().index('btree'),
    turnId: t.u64(),
    playerId: t.u64(),
    throwNo: t.u32(), // the room's round number: each round is one throw each
    speed: t.f32(), // peak rotation rate before release, rad/s
    angle: t.f32(), // release angle, degrees above horizontal
    timing: t.f32(), // speed at release over peak speed, 0..1
    distance: t.f32(), // metres; 0 for a foul
    foul: t.bool(),
    at: t.timestamp(),
    // From throw_discus_v2 (0 / '' from older phones): the release in detail.
    releaseSpeed: t.f32().default(0), // m/s off the hand
    roll: t.f32().default(0), // degrees the disc was tilted off flat at release
    spin: t.f32().default(0), // rad/s about the disc's own axis
    foulReason: t.string().default(''), // '' | 'late' (into the crowd) | 'sector' (outside the 34.92° sector)
  }
);

// Private: the module owner and the key the agent service registers with.
const config = table(
  {},
  {
    id: t.u32().primaryKey(),
    owner: t.identity(),
    serviceKey: t.string(),
  }
);

// Private: identities allowed to call the agent-service reducers.
const service = table(
  {},
  {
    identity: t.identity().primaryKey(),
  }
);

// Private: ends a turn on time, so every client agrees when it ended.
const turnTimer = table(
  {},
  {
    scheduledId: t.u64().primaryKey().autoInc(),
    scheduledAt: t.scheduleAt(),
    turnId: t.u64().index('btree'),
  }
);

// The Stadion's current heat, one row per room: the shared gun everyone runs from (go_at),
// the cap, and when it ended. Epoch is "not yet", as everywhere in the module.
const heat = table(
  { public: true },
  {
    roomId: t.u64().primaryKey(),
    heatNo: t.u32(),
    goAt: t.timestamp(),
    capAt: t.timestamp(),
    endedAt: t.timestamp(),
  }
);

// A runner in the Stadion's heat. The phone streams its speed and its own integrated
// distance; the module places it when it crosses the line (place 0 = still running) and
// times it from go_at (time 0 = not finished).
const runner = table(
  { public: true },
  {
    playerId: t.u64().primaryKey(),
    roomId: t.u64().index('btree'),
    heatNo: t.u32(),
    speed: t.f32(),
    distance: t.f32(),
    place: t.u32(),
    time: t.f32(),
    updatedAt: t.timestamp(),
  }
);

// Private: ends a heat at its cap.
const raceTimer = table(
  {},
  {
    scheduledId: t.u64().primaryKey().autoInc(),
    scheduledAt: t.scheduleAt(),
    roomId: t.u64().index('btree'),
    heatNo: t.u32(),
  }
);

// Pygmachia (boxing), one row per room: the bell (go_at), the end, and the result.
const fight = table(
  { public: true },
  {
    roomId: t.u64().primaryKey(),
    goAt: t.timestamp(),
    endsAt: t.timestamp(),
    endedAt: t.timestamp(),
    winnerId: t.u64(), // 0: a draw, or not over
    ko: t.bool(),
  }
);

// A fighter: health, guard, and the live fist aim from the phone (latest wins, ~20 Hz).
// Aim is normalized -1..1: yaw left/right, pitch low/high.
const fighter = table(
  { public: true },
  {
    playerId: t.u64().primaryKey(),
    roomId: t.u64().index('btree'),
    seat: t.u32(),
    health: t.f32(),
    guard: t.bool(),
    aimYaw: t.f32(),
    aimPitch: t.f32(),
    counterUntil: t.timestamp(),
    updatedAt: t.timestamp(),
    stamina: t.f32().default(100), // 0..100: punches cost it, rest refills it (v2)
    combo: t.u32().default(0), // the chain running now: 0 idle, then 1, 2, 3…
  }
);

// Every punch thrown, in order, and what the module made of it (the `punch` table).
const punches = table(
  { public: true },
  {
    id: t.u64().primaryKey().autoInc(),
    roomId: t.u64().index('btree'),
    playerId: t.u64(),
    targetId: t.u64(),
    zone: t.string(), // 'head' | 'body'
    power: t.f32(),
    aimYaw: t.f32(),
    aimPitch: t.f32(),
    result: t.string(), // 'landed' | 'blocked' | 'missed'
    damage: t.f32(),
    counter: t.bool(),
    at: t.timestamp(),
    t: t.f32(), // unused (0): the module times punches by `at`
    kind: t.string().default(''), // 'jab' | 'hook' | 'uppercut', from the phone: flavour, for the animation
    combo: t.u32().default(0), // this punch's place in its chain: 1, 2, 3… (v2)
  }
);

// Private: rings the final bell.
const fightTimer = table(
  {},
  {
    scheduledId: t.u64().primaryKey().autoInc(),
    scheduledAt: t.scheduleAt(),
    roomId: t.u64().index('btree'),
  }
);

// Private: one row per open connection. A poet is connected while any of their
// sockets is open, so a phone that reconnects before the server notices its old
// socket died isn't marked gone when that old socket finally closes.
const presence = table(
  {},
  {
    connectionId: t.connectionId().primaryKey(),
    identity: t.identity().index('btree'),
  }
);

const spacetimedb = schema({
  room,
  player,
  round,
  hand,
  turn,
  score,
  scene,
  colorSample,
  prosody,
  reaction,
  songLine,
  discusThrow,
  config,
  service,
  turnTimer,
  presence,
  heat,
  runner,
  raceTimer,
  fight,
  fighter,
  punch: punches,
  fightTimer,
});
export default spacetimedb;

// Hands are private: a client only receives the hand of its own player rows.
export const handFilter = spacetimedb.clientVisibilityFilter.sql(
  'SELECT hand.* FROM hand JOIN player ON hand.player_id = player.id WHERE player.identity = :sender'
);

// ---------------------------------------------------------------- rules

type Ctx = ReducerCtx<InferSchema<typeof spacetimedb>>;
type Room = Infer<typeof room.rowType>;
type Player = Infer<typeof player.rowType>;
type Turn = Infer<typeof turn.rowType>;
type Fight = Infer<typeof fight.rowType>;
type Fighter = Infer<typeof fighter.rowType>;
type Punch = Infer<typeof punches.rowType>;

const HAND_SIZE = 5;
const MIN_PLAYERS = 2;
const MAX_PLAYERS = 5;
const DEMO_PLAYERS = 4; // up to four on the big screen
const GRACE_MICROS = 2_000_000n; // the final transcript can land this late
const CODE_LETTERS = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I or O
const FORMS = ['four_beat', 'hexameter'];
const EPOCH = Timestamp.UNIX_EPOCH;
const DEBATE_COUNT_IN_SECONDS = 3; // a three-count, no drum
const DEBATE_SECONDS = 45;
const POETRY_COUNT_IN_MICROS = 2_250_000n; // 3-2-1, then free verse: no metronome, no bars
const POETRY_SECONDS_PER_LINE = 10; // the demo's two lines: one 20 s window
const COACH_SECONDS = 20; // a coach turn: free verse, one 20 s window
const STADION_METRES = 192; // one stadion, Olympia's track
const STADION_COUNT_IN_MICROS = 3_000_000n; // 3-2-1, then the gun
const STADION_CAP_SECONDS = 40; // a heat ends here even if someone is still running
const STADION_MAX_SPEED = 25; // m/s of game speed; a hard arm pump is about 14
const FIGHT_COUNT_IN_MICROS = 3_000_000n; // 3-2-1, then the bell
const FIGHT_SECONDS = 60;
const FIGHT_HEALTH = 100;
const COUNTER_MICROS = 600_000n; // blocking a head shot opens a counter window this long
const PUNCH_GAP_MICROS = 250_000n; // at most four punches a second
// Boxing v2 (SPEC), tuned offline so spam loses to paced or counter fighters and a fight runs
// about 30–50 s: damage = base × power × stamina × combo × counter × guard.
const HEAD_BASE = 3.5;
const BODY_BASE = 2;
const BODY_DRAIN = 15; // a body shot takes this much of the target's stamina
const PUNCH_COST = 12; // stamina per punch
const RAPID_COST = 8; // more for a punch under RAPID_MICROS after your last
const RAPID_MICROS = 300_000n;
const BLOCKED_COST = 10; // more for a punch into a raised guard
const STAMINA_REGEN = 20; // per second, always
const LOW_STAMINA = 30; // below this: half damage and no combo bonus
const COMBO_MICROS = 1_200_000n; // the next punch within this keeps the chain
const GUARD_HEAD = 0.25; // a raised guard lets this much of a head shot through
const GUARD_BODY = 0.5; // and this much of a body shot
const THROW_SECONDS = 30; // a discus thrower's time in the circle
const MAX_SPEED = 60; // rad/s; a phone gyro tops out near 35
const MAX_DISTANCE = 100; // metres
const MAX_RELEASE_SPEED = 40; // m/s off the hand; the world record's is about 25

// Each event is a config on the same engine (SPEC "The games"). Axis labels
// live in the app's event config; here we only need how many there are and
// what kind of card the hand holds. Timing is in turnWindow. Discus has no
// hand, no judge and no agent: see isDiscus.
// A verse's total is its axes weighted in rubric order: poetry is judged on content only,
// Image, Answer and Craft (out of 100); debate weighs every axis the same (out of 50).
const EVENTS: Record<string, { axes: number; card: string; weights: number[] }> = {
  poetry: { axes: 5, card: 'formula', weights: [0, 2, 4, 4, 0] }, // beat (flow), craft, image, answer, range
  debate: { axes: 5, card: 'move', weights: [1, 1, 1, 1, 1] }, // claim, reason, answer, craft, poise
  discus: { axes: 0, card: '', weights: [] },
  coach: { axes: 0, card: '', weights: [] }, // Judge mode: Homer replies in score.verdict, no scores
  stadion: { axes: 0, card: '', weights: [] }, // everyone races at once: no turns, no Claude
  pygmachia: { axes: 0, card: '', weights: [] }, // boxing: two fighters, live, no Claude
};

// ---------------------------------------------------------------- helpers

function text(value: string, field: string, min: number, max: number): string {
  const v = value.trim();
  if (v.length < min || v.length > max) {
    throw new SenderError(`${field} must be ${min} to ${max} characters`);
  }
  return v;
}

function clamp01(x: number): number {
  return Number.isFinite(x) ? Math.min(1, Math.max(0, x)) : 0;
}

function after(ts: Timestamp, micros: bigint): Timestamp {
  return new Timestamp(ts.microsSinceUnixEpoch + micros);
}

function isDiscus(r: Room): boolean {
  return r.event === 'discus';
}

function isCoach(r: Room): boolean {
  return r.event === 'coach';
}

function isStadion(r: Room): boolean {
  return r.event === 'stadion';
}

function isPygmachia(r: Room): boolean {
  return r.event === 'pygmachia';
}

function seconds(s: number): bigint {
  return BigInt(s) * 1_000_000n;
}

// A turn's count-in (start to beat_at) and speaking window (beat_at to
// ends_at). A verse is free verse (SPEC "The turn"): a 3-2-1, then one window of
// the room's turn_seconds, like a debater's three-count and 45 s; a thrower gets
// the circle at once. bpm and bars stay on the room for lessons and Practice only.
function turnWindow(event: string, turnSeconds: number): { countIn: bigint; speak: bigint } {
  if (event === 'discus') return { countIn: 0n, speak: seconds(THROW_SECONDS) };
  if (event === 'debate') return { countIn: seconds(DEBATE_COUNT_IN_SECONDS), speak: seconds(DEBATE_SECONDS) };
  return { countIn: POETRY_COUNT_IN_MICROS, speak: seconds(turnSeconds) };
}

// The settings an event decides: demo plays one round, and discus always
// auto-starts each thrower's turn (there is no Ready tap).
function eventSettings(
  event: string,
  demo: boolean,
  rounds: number,
  autoReady: boolean,
  lines: number
): { rounds: number; turnSeconds: number; autoReady: boolean } {
  const coach = event === 'coach'; // one open-ended conversation, so rounds don't apply
  if (!demo && !coach && (rounds < 1 || rounds > 5)) throw new SenderError('rounds must be 1 to 5');
  const turnSeconds =
    event === 'discus' ? THROW_SECONDS
    : event === 'debate' ? DEBATE_SECONDS
    : coach ? COACH_SECONDS
    : event === 'stadion' ? STADION_CAP_SECONDS
    : event === 'pygmachia' ? FIGHT_SECONDS
    : lines * POETRY_SECONDS_PER_LINE;
  if (turnSeconds > 120) throw new SenderError('a turn cannot run past 120 seconds');
  return { rounds: demo || coach ? 1 : rounds, turnSeconds, autoReady: event === 'discus' || event === 'stadion' || event === 'pygmachia' || coach || demo || autoReady };
}

// Inserts a round and its turns in seat order, rotated by one seat each
// round. Returns the turns in order.
function layOutRound(ctx: Ctx, roomId: bigint, roundNo: number, theme: string): Turn[] {
  const rd = ctx.db.round.insert({
    id: 0n,
    roomId,
    roundNo,
    theme,
    verdict: '',
    bestTurnId: 0n,
    bestLine: '',
    dealtAt: ctx.timestamp,
  });
  const players = playersOf(ctx, roomId);
  const offset = (roundNo - 1) % players.length;
  const order = [...players.slice(offset), ...players.slice(0, offset)];
  return order.map((p, i) => newTurn(ctx, roomId, rd.id, p.id, i));
}

function newTurn(ctx: Ctx, roomId: bigint, roundId: bigint, playerId: bigint, turnNo: number): Turn {
  return ctx.db.turn.insert({
    id: 0n,
    roomId,
    roundId,
    playerId,
    turnNo,
    status: 'waiting',
    attempt: 1,
    transcript: '',
    played: [],
    rescue: '',
    rescues: 0,
    startedAt: EPOCH,
    beatAt: EPOCH,
    endsAt: EPOCH,
  });
}

// A coach conversation never runs out of turns: after the last poet, the next cycle joins
// the same round in seat order, turn_no counting on, so the transcript stays one round.
function appendCycle(ctx: Ctx, roomId: bigint, roundId: bigint, firstTurnNo: number): Turn[] {
  return playersOf(ctx, roomId).map((p, i) => newTurn(ctx, roomId, roundId, p.id, firstTurnNo + i));
}

// Discus rounds need no agent: the module lays out each throw itself.
function startThrowRound(ctx: Ctx, r: Room, roundNo: number): void {
  const turns = layOutRound(ctx, r.id, roundNo, `Throw ${roundNo}`);
  ctx.db.room.id.update({ ...r, roundNo, phase: 'ready', nextTheme: '', currentTurnId: turns[0].id });
}

// A Stadion heat: every poet on the line at 0 m, waiting for the arena's start_race.
function startHeat(ctx: Ctx, r: Room, heatNo: number): void {
  const row = { roomId: r.id, heatNo, goAt: EPOCH, capAt: EPOCH, endedAt: EPOCH };
  if (ctx.db.heat.roomId.find(r.id)) ctx.db.heat.roomId.update(row);
  else ctx.db.heat.insert(row);
  ctx.db.runner.roomId.delete(r.id);
  for (const p of playersOf(ctx, r.id)) {
    ctx.db.runner.insert({ playerId: p.id, roomId: r.id, heatNo, speed: 0, distance: 0, place: 0, time: 0, updatedAt: ctx.timestamp });
  }
  ctx.db.room.id.update({ ...getRoom(ctx, r.id), phase: 'ready', roundNo: heatNo, nextTheme: '', currentTurnId: 0n });
}

// Closes a heat: whoever hasn't crossed is placed by distance after the finishers, every
// runner scores points by place (last gets 1), and the race goes to the results.
function endRace(ctx: Ctx, roomId: bigint): void {
  const runners = [...ctx.db.runner.roomId.filter(roomId)];
  const crossed = runners.filter(x => x.place > 0).length;
  runners
    .filter(x => x.place === 0)
    .sort((a, b) => b.distance - a.distance)
    .forEach((x, i) => ctx.db.runner.playerId.update({ ...x, place: crossed + i + 1 }));
  for (const x of [...ctx.db.runner.roomId.filter(roomId)]) {
    const p = ctx.db.player.id.find(x.playerId);
    if (p) ctx.db.player.id.update({ ...p, total: p.total + (runners.length - x.place + 1) });
  }
  const h = ctx.db.heat.roomId.find(roomId);
  if (h) ctx.db.heat.roomId.update({ ...h, endedAt: ctx.timestamp });
  ctx.db.raceTimer.roomId.delete(roomId);
  idleScene(ctx, roomId);
  setPhase(ctx, getRoom(ctx, roomId), 'scored', 0n);
}

// A bout: both fighters at full health, guards down, waiting for the arena's start_fight.
// With three or four in the room it's winner-stays-on: bout 1 is seats 0 and 1, then the last
// winner (the incumbent, on a draw) meets the next seat in line, so n poets fight n - 1 bouts.
function startBout(ctx: Ctx, r: Room, boutNo: number): void {
  const players = playersOf(ctx, r.id);
  const last = ctx.db.fight.roomId.find(r.id);
  const was = [...ctx.db.fighter.roomId.filter(r.id)].sort((a, b) => a.seat - b.seat);
  let pair = players.slice(0, 2);
  if (boutNo > 1 && last && was.length === 2) {
    const stays = players.find(p => p.id === (last.winnerId || was[0].playerId)) ?? players[0];
    pair = [stays, players[boutNo] ?? players.find(p => p.id !== stays.id)!];
  }
  const row = { roomId: r.id, goAt: EPOCH, endsAt: EPOCH, endedAt: EPOCH, winnerId: 0n, ko: false };
  if (last) ctx.db.fight.roomId.update(row);
  else ctx.db.fight.insert(row);
  ctx.db.fighter.roomId.delete(r.id);
  ctx.db.punch.roomId.delete(r.id);
  pair.forEach((p, seat) =>
    ctx.db.fighter.insert({
      playerId: p.id, roomId: r.id, seat, health: FIGHT_HEALTH, guard: false,
      aimYaw: 0, aimPitch: 0, counterUntil: EPOCH, updatedAt: ctx.timestamp, stamina: 100, combo: 0,
    })
  );
  ctx.db.room.id.update({ ...getRoom(ctx, r.id), phase: 'ready', roundNo: boutNo, nextTheme: '', currentTurnId: 0n });
}

// The final bell or a knockout: the winner scores a point and the fight goes to the result.
function endFight(ctx: Ctx, roomId: bigint, winnerId: bigint, ko: boolean): void {
  const f = ctx.db.fight.roomId.find(roomId);
  if (f) ctx.db.fight.roomId.update({ ...f, endedAt: ctx.timestamp, winnerId, ko });
  const w = winnerId ? ctx.db.player.id.find(winnerId) : undefined;
  if (w) ctx.db.player.id.update({ ...w, total: w.total + 1 });
  ctx.db.fightTimer.roomId.delete(roomId);
  idleScene(ctx, roomId);
  setPhase(ctx, getRoom(ctx, roomId), 'scored', 0n);
}

// The sender's fighter and their opponent in a fight that is on (count-in included), or null.
function inFight(ctx: Ctx, roomId: bigint): { f: Fight; me: Fighter; foe: Fighter } | null {
  const r = ctx.db.room.id.find(roomId);
  const f = ctx.db.fight.roomId.find(roomId);
  if (!r || !f || !isPygmachia(r) || r.phase !== 'speaking' || f.endedAt.microsSinceUnixEpoch !== 0n) return null;
  const p = playerOf(ctx, roomId);
  const fighters = [...ctx.db.fighter.roomId.filter(roomId)];
  const me = fighters.find(x => x.playerId === p?.id);
  const foe = fighters.find(x => x.playerId !== p?.id);
  return me && foe ? { f, me, foe } : null;
}

const unit = (x: number) => (Number.isFinite(x) ? Math.min(1, Math.max(-1, x)) : 0);

// A fighter's stamina, refilled for the time since their row last changed.
function rested(ctx: Ctx, f: Fighter): Fighter {
  const dt = Number(ctx.timestamp.microsSinceUnixEpoch - f.updatedAt.microsSinceUnixEpoch) / 1e6;
  return { ...f, stamina: Math.min(100, f.stamina + STAMINA_REGEN * Math.max(0, dt)), updatedAt: ctx.timestamp };
}

function getRoom(ctx: Ctx, roomId: bigint): Room {
  const r = ctx.db.room.id.find(roomId);
  if (!r) throw new SenderError('no such room');
  return r;
}

function getTurn(ctx: Ctx, turnId: bigint): Turn {
  const tr = ctx.db.turn.id.find(turnId);
  if (!tr) throw new SenderError('no such turn');
  return tr;
}

function requireHost(ctx: Ctx, r: Room): void {
  if (!r.host.isEqual(ctx.sender)) throw new SenderError('only the arena can do that');
}

function isOwner(ctx: Ctx): boolean {
  const c = ctx.db.config.id.find(0);
  return c !== null && c !== undefined && c.owner.isEqual(ctx.sender);
}

function requireService(ctx: Ctx): void {
  if (!ctx.db.service.identity.find(ctx.sender) && !isOwner(ctx)) {
    throw new SenderError('only the agent service can do that');
  }
}

function playersOf(ctx: Ctx, roomId: bigint): Player[] {
  return [...ctx.db.player.roomId.filter(roomId)].sort((a, b) => a.seat - b.seat);
}

function playerOf(ctx: Ctx, roomId: bigint): Player | undefined {
  for (const p of ctx.db.player.identity.filter(ctx.sender)) {
    if (p.roomId === roomId) return p;
  }
  return undefined;
}

function turnsOf(ctx: Ctx, roundId: bigint): Turn[] {
  return [...ctx.db.turn.roundId.filter(roundId)].sort((a, b) => a.turnNo - b.turnNo);
}

function findRound(ctx: Ctx, roomId: bigint, roundNo: number) {
  for (const rd of ctx.db.round.roomId.filter(roomId)) {
    if (rd.roundNo === roundNo) return rd;
  }
  return undefined;
}

// The speaker of the room's current turn, if the sender is that speaker.
function requireSpeaker(ctx: Ctx, turnId: bigint): { r: Room; tr: Turn } {
  const tr = getTurn(ctx, turnId);
  const r = getRoom(ctx, tr.roomId);
  const p = ctx.db.player.id.find(tr.playerId);
  if (!p || !p.identity.isEqual(ctx.sender)) throw new SenderError('not your turn');
  if (r.currentTurnId !== tr.id || tr.status !== 'speaking') {
    throw new SenderError('this turn is not live');
  }
  return { r, tr };
}

function newCode(ctx: Ctx): string {
  for (let i = 0; i < 50; i++) {
    let code = '';
    for (let j = 0; j < 4; j++) {
      code += CODE_LETTERS[ctx.random.integerInRange(0, CODE_LETTERS.length - 1)];
    }
    if (!ctx.db.room.code.find(code)) return code;
  }
  throw new Error('could not find a free room code');
}

function setPhase(ctx: Ctx, r: Room, phase: string, currentTurnId = r.currentTurnId): Room {
  return ctx.db.room.id.update({ ...r, phase, currentTurnId });
}

function startOfRound(ctx: Ctx, r: Room): string {
  return r.themeChoice ? 'theme' : 'dealing';
}

function clearBattle(ctx: Ctx, roomId: bigint): void {
  for (const tr of [...ctx.db.turn.roomId.filter(roomId)]) {
    ctx.db.turnTimer.turnId.delete(tr.id);
    ctx.db.turn.id.delete(tr.id);
  }
  ctx.db.round.roomId.delete(roomId);
  ctx.db.score.roomId.delete(roomId);
  ctx.db.colorSample.roomId.delete(roomId);
  ctx.db.songLine.roomId.delete(roomId);
  ctx.db.reaction.roomId.delete(roomId);
  ctx.db.discusThrow.roomId.delete(roomId);
  ctx.db.heat.roomId.delete(roomId);
  ctx.db.runner.roomId.delete(roomId);
  ctx.db.raceTimer.roomId.delete(roomId);
  ctx.db.fight.roomId.delete(roomId);
  ctx.db.fighter.roomId.delete(roomId);
  ctx.db.punch.roomId.delete(roomId);
  ctx.db.fightTimer.roomId.delete(roomId);
  for (const p of playersOf(ctx, roomId)) {
    ctx.db.player.id.update({ ...p, total: 0 });
    const h = ctx.db.hand.playerId.find(p.id);
    if (h) ctx.db.hand.playerId.update({ ...h, cards: [] });
  }
  idleScene(ctx, roomId);
}

function idleScene(ctx: Ctx, roomId: bigint): void {
  const s = ctx.db.scene.roomId.find(roomId);
  if (s) ctx.db.scene.roomId.update({ ...s, turnId: 0n, playerId: 0n, updatedAt: ctx.timestamp });
  const pr = ctx.db.prosody.roomId.find(roomId);
  if (pr) {
    ctx.db.prosody.roomId.update({ ...pr, turnId: 0n, playerId: 0n, loudness: 0, pitch: 0, hits: 0 });
  }
}

function beginBattle(ctx: Ctx, r: Room): void {
  const n = playersOf(ctx, r.id).length;
  const min = isCoach(r) || isStadion(r) ? 1 : MIN_PLAYERS; // Judge mode: one poet and Homer; a lone runner races the clock
  if (n < min) throw new SenderError(`need at least ${min} poet${min === 1 ? '' : 's'}`);
  if (isDiscus(r)) {
    startThrowRound(ctx, r, 1);
    return;
  }
  if (isStadion(r)) {
    startHeat(ctx, r, 1);
    return;
  }
  if (isPygmachia(r)) {
    if (n < 2) throw new SenderError('a fight needs two fighters');
    ctx.db.room.id.update({ ...r, rounds: n - 1 }); // winner-stays-on: one bout per challenger
    startBout(ctx, r, 1);
    return;
  }
  ctx.db.room.id.update({
    ...r,
    phase: startOfRound(ctx, r),
    roundNo: 1,
    nextTheme: '',
    currentTurnId: 0n,
  });
}

// Ends the live turn. A silent first attempt gets one retry; a silent
// second attempt scores nothing. Otherwise the verse goes to the judge.
function closeTurn(ctx: Ctx, r: Room, tr: Turn, transcript: string): void {
  ctx.db.turnTimer.turnId.delete(tr.id);
  const words = transcript.trim();
  if (words.length === 0 && tr.attempt < 2) {
    ctx.db.turn.id.update({
      ...tr,
      status: 'waiting',
      attempt: tr.attempt + 1,
      transcript: '',
      startedAt: EPOCH,
      beatAt: EPOCH,
      endsAt: EPOCH,
    });
    setPhase(ctx, r, 'ready');
  } else if (words.length === 0) {
    ctx.db.turn.id.update({ ...tr, status: 'skipped', transcript: '' });
    setPhase(ctx, r, 'scored');
  } else {
    ctx.db.turn.id.update({ ...tr, status: 'judging', transcript });
    setPhase(ctx, r, 'judging');
  }
}

// ---------------------------------------------------------------- lifecycle

export const init = spacetimedb.init(ctx => {
  ctx.db.config.insert({ id: 0, owner: ctx.sender, serviceKey: '' });
});

export const onConnect = spacetimedb.clientConnected(ctx => {
  if (ctx.connectionId && !ctx.db.presence.connectionId.find(ctx.connectionId)) {
    ctx.db.presence.insert({ connectionId: ctx.connectionId, identity: ctx.sender });
  }
  for (const p of [...ctx.db.player.identity.filter(ctx.sender)]) {
    if (!p.connected) ctx.db.player.id.update({ ...p, connected: true });
  }
});

export const onDisconnect = spacetimedb.clientDisconnected(ctx => {
  if (ctx.connectionId) ctx.db.presence.connectionId.delete(ctx.connectionId);
  // Another socket of this identity is still open: a reconnect that beat this close.
  if ([...ctx.db.presence.identity.filter(ctx.sender)].length > 0) return;
  for (const p of [...ctx.db.player.identity.filter(ctx.sender)]) {
    if (p.connected) ctx.db.player.id.update({ ...p, connected: false });
  }
});

// ---------------------------------------------------------------- owner

// Run once from the CLI: spacetime call <db> set_service_key '"<key>"'
export const setServiceKey = spacetimedb.reducer({ key: t.string() }, (ctx, { key }) => {
  if (!isOwner(ctx)) throw new SenderError('only the owner can do that');
  const c = ctx.db.config.id.find(0)!;
  ctx.db.config.id.update({ ...c, serviceKey: text(key, 'key', 16, 200) });
});

// The agent service calls this once with the key from its .env.
// Already registered identities succeed whatever the key, so a key rotated
// since (smoke sets a fresh one each run) doesn't break the agent's startup.
export const claimService = spacetimedb.reducer({ key: t.string() }, (ctx, { key }) => {
  if (ctx.db.service.identity.find(ctx.sender)) return;
  const c = ctx.db.config.id.find(0);
  if (!c || c.serviceKey === '' || c.serviceKey !== key) throw new SenderError('wrong key');
  ctx.db.service.insert({ identity: ctx.sender });
});

// ---------------------------------------------------------------- arena

export const createRoom = spacetimedb.reducer(
  {
    event: t.string(),
    rounds: t.u32(),
    barsPerLine: t.u32(),
    linesPerTurn: t.u32(),
    bpm: t.u32(),
    form: t.string(),
    autoReady: t.bool(),
    themeChoice: t.bool(),
    demo: t.bool(),
  },
  (ctx, args) => {
    if (!EVENTS[args.event]) throw new SenderError('unknown event');
    if (!FORMS.includes(args.form)) throw new SenderError('unknown form');
    if (args.bpm < 40 || args.bpm > 160) throw new SenderError('bpm must be 40 to 160');
    if (args.barsPerLine !== 1 && args.barsPerLine !== 2) {
      throw new SenderError('barsPerLine is 1 (no rest bar) or 2 (a rest bar after each line)');
    }
    if (!args.demo && (args.linesPerTurn < 1 || args.linesPerTurn > 8)) {
      throw new SenderError('linesPerTurn must be 1 to 8');
    }
    // The poetry settings are kept for discus too, so set_event can switch back.
    const lines = args.demo ? 2 : args.linesPerTurn;
    const s = eventSettings(args.event, args.demo, args.rounds, args.autoReady, lines);

    // A host has one open lobby at a time; a double tap must not leave two.
    for (const old of [...ctx.db.room.iter()]) {
      if (old.host.isEqual(ctx.sender) && old.phase === 'lobby') setPhase(ctx, old, 'finished');
    }

    const r = ctx.db.room.insert({
      id: 0n,
      event: args.event,
      code: newCode(ctx),
      host: ctx.sender,
      phase: 'lobby',
      roundNo: 0,
      rounds: s.rounds,
      turnSeconds: s.turnSeconds,
      linesPerTurn: lines,
      bpm: args.bpm,
      form: args.form,
      maxPlayers: args.demo ? DEMO_PLAYERS : MAX_PLAYERS,
      autoReady: s.autoReady,
      themeChoice: args.themeChoice,
      demo: args.demo,
      nextTheme: '',
      currentTurnId: 0n,
      createdAt: ctx.timestamp,
      barsPerLine: args.barsPerLine,
    });
    ctx.db.scene.insert({
      roomId: r.id,
      turnId: 0n,
      playerId: 0n,
      anger: 0,
      grief: 0,
      joy: 0,
      awe: 0,
      tenderness: 0,
      fear: 0,
      defiance: 0,
      longing: 0,
      updatedAt: ctx.timestamp,
    });
    ctx.db.prosody.insert({ roomId: r.id, turnId: 0n, playerId: 0n, loudness: 0, pitch: 0, hits: 0 });
  }
);

export const startBattle = spacetimedb.reducer({ roomId: t.u64() }, (ctx, { roomId }) => {
  const r = getRoom(ctx, roomId);
  requireHost(ctx, r);
  if (r.phase !== 'lobby') throw new SenderError('the battle has already begun');
  beginBattle(ctx, r);
});

// Same poets, same epithets, a fresh battle. Works from any phase so a
// wedged demo can be reset in one tap.
export const rematch = spacetimedb.reducer({ roomId: t.u64() }, (ctx, { roomId }) => {
  const r = getRoom(ctx, roomId);
  requireHost(ctx, r);
  if (r.phase === 'lobby') throw new SenderError('the battle has not begun');
  clearBattle(ctx, roomId);
  beginBattle(ctx, getRoom(ctx, roomId));
});

// The hall stays open (P16): from the lobby, or once an event has finished,
// the arena switches the room to another event. Poets keep their seats and
// epithets; scores, throws and hands start over, and the room is a lobby
// again, so latecomers can join before the next event begins.
export const setEvent = spacetimedb.reducer(
  { roomId: t.u64(), event: t.string(), rounds: t.u32() },
  (ctx, { roomId, event, rounds }) => {
    const r = getRoom(ctx, roomId);
    requireHost(ctx, r);
    if (!EVENTS[event]) throw new SenderError('unknown event');
    if (r.phase !== 'lobby' && r.phase !== 'finished') throw new SenderError('finish this event first');
    const s = eventSettings(event, r.demo, rounds, r.autoReady && !isDiscus(r), r.linesPerTurn);
    clearBattle(ctx, roomId);
    for (const h of [...ctx.db.hand.roomId.filter(roomId)]) {
      ctx.db.hand.playerId.update({ ...h, kind: EVENTS[event].card, cards: [] });
    }
    ctx.db.room.id.update({
      ...getRoom(ctx, roomId),
      event,
      ...s,
      phase: 'lobby',
      roundNo: 0,
      nextTheme: '',
      currentTurnId: 0n,
    });
  }
);

export const chooseTheme = spacetimedb.reducer(
  { roomId: t.u64(), theme: t.string() },
  (ctx, { roomId, theme }) => {
    const r = getRoom(ctx, roomId);
    requireHost(ctx, r);
    if (r.phase !== 'theme') throw new SenderError('not choosing a theme now');
    ctx.db.room.id.update({ ...r, phase: 'dealing', nextTheme: text(theme, 'theme', 1, 120) });
  }
);

// Moves the battle on after a reveal: scored -> next turn or round end,
// round end -> next round or finale, finale -> finished.
export const advance = spacetimedb.reducer({ roomId: t.u64() }, (ctx, { roomId }) => {
  const r = getRoom(ctx, roomId);
  requireHost(ctx, r);

  if (r.phase === 'scored' && (isStadion(r) || isPygmachia(r))) {
    // The motion games have no turns: the next heat or bout, or the champion.
    if (r.roundNo < r.rounds) (isStadion(r) ? startHeat : startBout)(ctx, r, r.roundNo + 1);
    else setPhase(ctx, r, 'finale', 0n);
  } else if (r.phase === 'scored') {
    const cur = getTurn(ctx, r.currentTurnId);
    const next = turnsOf(ctx, cur.roundId).find(x => x.turnNo === cur.turnNo + 1);
    if (next) setPhase(ctx, r, 'ready', next.id);
    // Coach goes round again: the next cycle of turns, in the same round, with no verdict.
    else if (isCoach(r)) setPhase(ctx, r, 'ready', appendCycle(ctx, r.id, cur.roundId, cur.turnNo + 1)[0].id);
    // Discus has no verdict: the next round of throws starts at once.
    else if (isDiscus(r) && r.roundNo < r.rounds) startThrowRound(ctx, r, r.roundNo + 1);
    else if (isDiscus(r)) setPhase(ctx, r, 'finale', 0n);
    else setPhase(ctx, r, 'round_end', 0n);
  } else if (r.phase === 'round_end') {
    if (r.roundNo >= r.rounds) {
      setPhase(ctx, r, 'finale', 0n);
      return;
    }
    const nextNo = r.roundNo + 1;
    const dealt = findRound(ctx, roomId, nextNo);
    if (dealt) {
      const first = turnsOf(ctx, dealt.id)[0];
      ctx.db.room.id.update({ ...r, roundNo: nextNo, phase: 'ready', currentTurnId: first.id });
    } else {
      ctx.db.room.id.update({ ...r, roundNo: nextNo, phase: startOfRound(ctx, r), currentTurnId: 0n });
    }
  } else if (r.phase === 'finale') {
    setPhase(ctx, r, 'finished', 0n);
  } else {
    throw new SenderError(`cannot advance from ${r.phase}`);
  }
});

// For a poet who never steps up, or a verse the judge never returns.
export const skipTurn = spacetimedb.reducer({ turnId: t.u64() }, (ctx, { turnId }) => {
  const tr = getTurn(ctx, turnId);
  const r = getRoom(ctx, tr.roomId);
  requireHost(ctx, r);
  if (r.currentTurnId !== tr.id) throw new SenderError('not the current turn');
  if (tr.status !== 'waiting' && tr.status !== 'judging') {
    throw new SenderError(`cannot skip a turn that is ${tr.status}`);
  }
  ctx.db.turn.id.update({ ...tr, status: 'skipped' });
  setPhase(ctx, r, 'scored');
});

// ---------------------------------------------------------------- phone

// The host ends a battle where it stands. A coach conversation has no end of its own; this is
// its End button, and it works for any event. A live turn is marked skipped and its timer
// cancelled, so a late end_turn or score is refused.
export const endBattle = spacetimedb.reducer({ roomId: t.u64() }, (ctx, { roomId }) => {
  const r = getRoom(ctx, roomId);
  requireHost(ctx, r);
  if (r.phase === 'lobby' || r.phase === 'finished') throw new SenderError(`cannot end from ${r.phase}`);
  ctx.db.raceTimer.roomId.delete(roomId);
  ctx.db.fightTimer.roomId.delete(roomId);
  for (const tr of [...ctx.db.turn.roomId.filter(roomId)]) {
    ctx.db.turnTimer.turnId.delete(tr.id);
    if (tr.id === r.currentTurnId && ['waiting', 'speaking', 'judging'].includes(tr.status)) {
      ctx.db.turn.id.update({ ...tr, status: 'skipped' });
    }
  }
  idleScene(ctx, roomId);
  setPhase(ctx, r, 'finished', 0n);
});

export const joinRoom = spacetimedb.reducer(
  { code: t.string(), name: t.string(), epithet: t.string(), hoard: t.array(t.string()) },
  (ctx, args) => {
    const r = ctx.db.room.code.find(args.code.trim().toUpperCase());
    if (!r) throw new SenderError('no such room');
    const name = text(args.name, 'name', 1, 24);
    const epithet = text(args.epithet, 'epithet', 0, 48);
    const hoard = args.hoard.slice(0, 20).map(c => text(c, 'hoard card', 1, 60));
    const players = playersOf(ctx, r.id);
    const lobby = r.phase === 'lobby';

    // Back on the same device: a reconnect, in any phase, finished included (the
    // hall stays open between events, P16). In the lobby it may also
    // rename; '' and [] keep the current epithet and hoard, so a rejoin that only
    // knows the name doesn't wipe an epithet the agent coined.
    const mine = players.find(p => p.identity.isEqual(ctx.sender));
    if (mine) {
      const next = {
        name: lobby && name.toLowerCase() !== mine.name.toLowerCase() ? name : mine.name,
        epithet: lobby && epithet !== '' ? epithet : mine.epithet,
        hoard: lobby && hoard.length > 0 ? hoard : mine.hoard,
      };
      const changed = next.name !== mine.name || next.epithet !== mine.epithet;
      ctx.db.player.id.update({ ...mine, ...next, connected: true, ...(changed ? { named: false } : {}) });
      return;
    }
    if (r.phase === 'finished') throw new SenderError('no such room');

    // Back on a new device: take over the dropped seat with the same name.
    const dropped = players.find(p => !p.connected && p.name.toLowerCase() === name.toLowerCase());
    if (dropped) {
      ctx.db.player.id.update({ ...dropped, identity: ctx.sender, connected: true });
      return;
    }

    if (!lobby) throw new SenderError('the battle has already begun');
    if (players.length >= r.maxPlayers) throw new SenderError('the hall is full');
    if (players.some(p => p.name.toLowerCase() === name.toLowerCase())) {
      throw new SenderError('that name is taken');
    }
    const p = ctx.db.player.insert({
      id: 0n,
      roomId: r.id,
      identity: ctx.sender,
      name,
      epithet,
      named: false,
      entered: false,
      hoard,
      seat: players.length === 0 ? 0 : players[players.length - 1].seat + 1,
      total: 0,
      connected: true,
      joinedAt: ctx.timestamp,
    });
    ctx.db.hand.insert({ playerId: p.id, roomId: r.id, kind: EVENTS[r.event].card, cards: [] });
  }
);

export const leaveRoom = spacetimedb.reducer({ roomId: t.u64() }, (ctx, { roomId }) => {
  const r = getRoom(ctx, roomId);
  const p = playerOf(ctx, roomId);
  if (!p) return;
  if (r.phase === 'lobby') {
    ctx.db.hand.playerId.delete(p.id);
    ctx.db.player.id.delete(p.id);
  } else {
    ctx.db.player.id.update({ ...p, connected: false });
  }
});

// The mic check passed: the arena announces this poet's entrance.
export const enter = spacetimedb.reducer({ roomId: t.u64() }, (ctx, { roomId }) => {
  const p = playerOf(ctx, roomId);
  if (!p) throw new SenderError('you are not in this room');
  if (!p.entered) ctx.db.player.id.update({ ...p, entered: true });
});

// The speaker taps Ready. The arena may also call it (auto-ready, or after
// the step-up wait).
export const startTurn = spacetimedb.reducer({ turnId: t.u64() }, (ctx, { turnId }) => {
  const tr = getTurn(ctx, turnId);
  const r = getRoom(ctx, tr.roomId);
  const p = ctx.db.player.id.find(tr.playerId);
  const isSpeaker = p !== null && p !== undefined && p.identity.isEqual(ctx.sender);
  if (!isSpeaker && !r.host.isEqual(ctx.sender)) throw new SenderError('not your turn');
  if (r.phase !== 'ready' || r.currentTurnId !== tr.id || tr.status !== 'waiting') {
    throw new SenderError('this turn is not up');
  }

  const w = turnWindow(r.event, r.turnSeconds);
  const beatAt = after(ctx.timestamp, w.countIn);
  const endsAt = after(beatAt, w.speak);
  ctx.db.turn.id.update({ ...tr, status: 'speaking', startedAt: ctx.timestamp, beatAt, endsAt });
  ctx.db.turnTimer.insert({
    scheduledId: 0n,
    scheduledAt: ScheduleAt.time(endsAt.microsSinceUnixEpoch + GRACE_MICROS),
    turnId: tr.id,
  });
  setPhase(ctx, r, 'speaking');

  const s = ctx.db.scene.roomId.find(r.id);
  if (s) ctx.db.scene.roomId.update({ ...s, turnId: tr.id, playerId: tr.playerId, updatedAt: ctx.timestamp });
  const pr = ctx.db.prosody.roomId.find(r.id);
  if (pr) {
    ctx.db.prosody.roomId.update({ ...pr, turnId: tr.id, playerId: tr.playerId, loudness: 0, pitch: 0, hits: 0 });
  }
});

// The live transcript, replaced whole on every STT update. Lines are
// separated by '\n'.
export const updateTranscript = spacetimedb.reducer(
  { turnId: t.u64(), transcript: t.string() },
  (ctx, { turnId, transcript }) => {
    const { tr } = requireSpeaker(ctx, turnId);
    ctx.db.turn.id.update({ ...tr, transcript: transcript.slice(0, 4000) });
  }
);

// The speaker used a card from their hand. It leaves the hand for good.
export const playCard = spacetimedb.reducer(
  { turnId: t.u64(), card: t.string() },
  (ctx, { turnId, card }) => {
    const { tr } = requireSpeaker(ctx, turnId);
    const h = ctx.db.hand.playerId.find(tr.playerId);
    const i = h ? h.cards.indexOf(card) : -1;
    if (!h || i < 0) throw new SenderError('that card is not in your hand');
    ctx.db.hand.playerId.update({ ...h, cards: h.cards.filter((_, j) => j !== i) });
    ctx.db.turn.id.update({ ...tr, played: [...tr.played, card] });
  }
);

// Freeze rescue: the speaker went silent, and the host whispers this card.
export const rescue = spacetimedb.reducer(
  { turnId: t.u64(), card: t.string() },
  (ctx, { turnId, card }) => {
    const { tr } = requireSpeaker(ctx, turnId);
    const h = ctx.db.hand.playerId.find(tr.playerId);
    if (!h || !h.cards.includes(card)) throw new SenderError('that card is not in your hand');
    ctx.db.turn.id.update({ ...tr, rescue: card, rescues: tr.rescues + 1 });
  }
);

// The speaker finished: all lines spoken, Done tapped, or time ran out and
// this carries the final transcript.
export const endTurn = spacetimedb.reducer(
  { turnId: t.u64(), transcript: t.string() },
  (ctx, { turnId, transcript }) => {
    const { r, tr } = requireSpeaker(ctx, turnId);
    if (isDiscus(r)) throw new SenderError('a discus turn ends with throw_discus');
    closeTurn(ctx, r, tr, transcript.slice(0, 4000));
  }
);

// The thrower's phone, once, when the thumb lifts. A foul lands at 0 m.
// player.total keeps the best throw in tenths of a metre, so it ranks the field.
// The arena fires the gun: a 3-2-1, then everyone runs at once until all have crossed
// or the cap.
export const startRace = spacetimedb.reducer({ roomId: t.u64() }, (ctx, { roomId }) => {
  const r = getRoom(ctx, roomId);
  requireHost(ctx, r);
  if (!isStadion(r)) throw new SenderError('not a stadion');
  if (r.phase !== 'ready') throw new SenderError('the runners are not on the line');
  const h = ctx.db.heat.roomId.find(roomId)!;
  const goAt = after(ctx.timestamp, STADION_COUNT_IN_MICROS);
  const capAt = after(goAt, seconds(STADION_CAP_SECONDS));
  ctx.db.heat.roomId.update({ ...h, goAt, capAt, endedAt: EPOCH });
  ctx.db.raceTimer.insert({ scheduledId: 0n, scheduledAt: ScheduleAt.time(capAt.microsSinceUnixEpoch), roomId, heatNo: h.heatNo });
  setPhase(ctx, r, 'speaking', 0n);
});

// A runner's phone, about 10 Hz: its arm-pump speed and its own integrated distance.
// Never an error (a stream must not spam refusals): before the gun, after crossing or
// outside a race it is ignored. Distance never goes down and can't outrun the max speed.
export const setStride = spacetimedb.reducer(
  { roomId: t.u64(), speed: t.f32(), distance: t.f32() },
  (ctx, { roomId, speed, distance }) => {
    const r = ctx.db.room.id.find(roomId);
    if (!r || !isStadion(r) || r.phase !== 'speaking') return;
    const p = playerOf(ctx, roomId);
    const h = ctx.db.heat.roomId.find(roomId);
    const me = p ? ctx.db.runner.playerId.find(p.id) : undefined;
    if (!h || !me || me.place > 0 || !Number.isFinite(speed) || !Number.isFinite(distance)) return;
    const elapsed = Number(ctx.timestamp.microsSinceUnixEpoch - h.goAt.microsSinceUnixEpoch) / 1e6;
    if (elapsed <= 0) return;
    const v = Math.min(STADION_MAX_SPEED, Math.max(0, speed));
    const d = Math.max(me.distance, Math.min(distance, STADION_MAX_SPEED * elapsed));
    if (d < STADION_METRES) {
      ctx.db.runner.playerId.update({ ...me, speed: v, distance: d, updatedAt: ctx.timestamp });
      return;
    }
    // Crossed: back out the overshoot at this speed, never faster than the max speed allows.
    const overshoot = v > 0 ? (d - STADION_METRES) / v : 0;
    const time = Math.max(STADION_METRES / STADION_MAX_SPEED, elapsed - overshoot);
    const place = [...ctx.db.runner.roomId.filter(roomId)].filter(x => x.place > 0).length + 1;
    ctx.db.runner.playerId.update({ ...me, speed: v, distance: STADION_METRES, place, time: Math.round(time * 1000) / 1000, updatedAt: ctx.timestamp });
    if ([...ctx.db.runner.roomId.filter(roomId)].every(x => x.place > 0)) endRace(ctx, roomId);
  }
);

export const raceTimeout = spacetimedb.reducer(
  { onSchedule: raceTimer },
  { timer: raceTimer.rowType },
  (ctx, { timer }) => {
    const r = ctx.db.room.id.find(timer.roomId);
    const h = ctx.db.heat.roomId.find(timer.roomId);
    if (!r || !h || !isStadion(r) || r.phase !== 'speaking' || h.heatNo !== timer.heatNo) return;
    endRace(ctx, r.id);
  }
);

// The arena rings the bell: a 3-2-1, then 60 s or a knockout.
export const startFight = spacetimedb.reducer({ roomId: t.u64() }, (ctx, { roomId }) => {
  const r = getRoom(ctx, roomId);
  requireHost(ctx, r);
  if (!isPygmachia(r)) throw new SenderError('not a fight');
  if (r.phase !== 'ready') throw new SenderError('the fighters are not in their corners');
  const f = ctx.db.fight.roomId.find(roomId)!;
  const goAt = after(ctx.timestamp, FIGHT_COUNT_IN_MICROS);
  const endsAt = after(goAt, seconds(FIGHT_SECONDS));
  ctx.db.fight.roomId.update({ ...f, goAt, endsAt, endedAt: EPOCH, winnerId: 0n, ko: false });
  ctx.db.fightTimer.insert({ scheduledId: 0n, scheduledAt: ScheduleAt.time(endsAt.microsSinceUnixEpoch), roomId });
  setPhase(ctx, r, 'speaking', 0n);
});

// A fighter's phone, about 20 Hz: where the fists point, and whether the guard is up (the
// phone held upright at the face; it covers the head only). Silent outside a fight.
export const setFistAim = spacetimedb.reducer(
  { roomId: t.u64(), yaw: t.f32(), pitch: t.f32(), guard: t.bool() },
  (ctx, { roomId, yaw, pitch, guard }) => {
    const live = inFight(ctx, roomId);
    if (live) ctx.db.fighter.playerId.update({ ...rested(ctx, live.me), aimYaw: unit(yaw), aimPitch: unit(pitch), guard });
  }
);

// A punch (boxing v2). Aimed high it goes for the head, low for the body; there are no misses
// on aim (phone yaw drifts). Damage = base × power × stamina × combo × counter × guard:
// - stamina: each punch costs 12 (8 more when thrown under 0.3 s after your last, 10 more
//   into a guard); it refills 20 a second; below 30 a punch does half and can't combo.
// - combo: the 2nd punch within 1.2 s of your last does ×1.25, the 3rd and on ×1.5, unless
//   your last was blocked or you've been hit since.
// - counter: blocking a head shot opens a 0.6 s window; a punch in it does ×2 (`counter`).
// - guard: a raised guard lets 25% of a head shot through ('blocked') and 50% of a body shot.
// Body shots that land also drain the target's stamina. Punching drops your guard. Silent
// before the bell, after it, for a poet not in the bout, or faster than 4 a second.
export const throwPunch = spacetimedb.reducer(
  { roomId: t.u64(), kind: t.string(), power: t.f32(), aimYaw: t.f32(), aimPitch: t.f32() },
  (ctx, args) => {
    const live = inFight(ctx, args.roomId);
    if (!live || ctx.timestamp.microsSinceUnixEpoch < live.f.goAt.microsSinceUnixEpoch) return;
    const now = ctx.timestamp.microsSinceUnixEpoch;
    const log = [...ctx.db.punch.roomId.filter(args.roomId)];
    let last: Punch | undefined;
    for (const x of log) if (x.playerId === live.me.playerId && (!last || x.id > last.id)) last = x;
    if (last && now - last.at.microsSinceUnixEpoch < PUNCH_GAP_MICROS) return;
    const me = rested(ctx, live.me);
    const foe = rested(ctx, live.foe);
    const power = Math.max(0, Math.min(1, Number.isFinite(args.power) ? args.power : 0));
    const yaw = unit(args.aimYaw);
    const pitch = unit(args.aimPitch);
    const zone = pitch >= 0 ? 'head' : 'body';
    const counter = me.counterUntil.microsSinceUnixEpoch > now;
    const since = last ? now - last.at.microsSinceUnixEpoch : -1n;
    const hitSince = last !== undefined && log.some(x => x.playerId === foe.playerId && x.result === 'landed' && x.id > last!.id);
    const chained = last !== undefined && since <= COMBO_MICROS && last.result !== 'blocked' && !hitSince;
    const combo = chained ? last!.combo + 1 : 1;
    const tired = me.stamina < LOW_STAMINA;
    const comboBonus = tired ? 1 : combo >= 3 ? 1.5 : combo === 2 ? 1.25 : 1;
    const blocked = foe.guard && zone === 'head';
    const guardLet = !foe.guard ? 1 : zone === 'head' ? GUARD_HEAD : GUARD_BODY;
    const base = zone === 'head' ? HEAD_BASE : BODY_BASE;
    const damage = Math.round(base * power * (tired ? 0.5 : 1) * comboBonus * (counter ? 2 : 1) * guardLet * 10) / 10;
    const cost = PUNCH_COST + (last && since < RAPID_MICROS ? RAPID_COST : 0) + (blocked ? BLOCKED_COST : 0);
    ctx.db.punch.insert({
      id: 0n, roomId: args.roomId, playerId: me.playerId, targetId: foe.playerId, zone, power, aimYaw: yaw, aimPitch: pitch,
      result: blocked ? 'blocked' : 'landed', damage, counter, at: ctx.timestamp, t: 0,
      kind: ['jab', 'hook', 'uppercut'].includes(args.kind) ? args.kind : 'jab', combo,
    });
    ctx.db.fighter.playerId.update({
      ...me, guard: false, stamina: Math.max(0, me.stamina - cost), combo: blocked ? 0 : combo,
      counterUntil: counter ? EPOCH : me.counterUntil,
    });
    const health = Math.max(0, foe.health - damage);
    ctx.db.fighter.playerId.update({
      ...foe,
      health,
      stamina: zone === 'body' ? Math.max(0, foe.stamina - BODY_DRAIN) : foe.stamina,
      combo: blocked ? foe.combo : 0, // a landed punch breaks the target's chain
      counterUntil: blocked ? after(ctx.timestamp, COUNTER_MICROS) : foe.counterUntil,
    });
    if (health <= 0) endFight(ctx, args.roomId, me.playerId, true);
  }
);

export const fightTimeout = spacetimedb.reducer(
  { onSchedule: fightTimer },
  { timer: fightTimer.rowType },
  (ctx, { timer }) => {
    const r = ctx.db.room.id.find(timer.roomId);
    const f = ctx.db.fight.roomId.find(timer.roomId);
    if (!r || !f || !isPygmachia(r) || r.phase !== 'speaking' || f.endedAt.microsSinceUnixEpoch !== 0n) return;
    const [a, b] = [...ctx.db.fighter.roomId.filter(r.id)];
    const winner = !a || !b || a.health === b.health ? 0n : a.health > b.health ? a.playerId : b.playerId;
    endFight(ctx, r.id, winner, false);
  }
);

type ThrowArgs = { turnId: bigint; speed: number; angle: number; timing: number; distance: number; foul: boolean };
type Release = { releaseSpeed: number; roll: number; spin: number; foulReason: string };

// One throw, from either reducer: the phone measures it and works out the distance; the
// module checks the numbers are plausible, keeps the best, and moves to the reveal.
function recordThrow(ctx: Ctx, a: ThrowArgs, release: Release): void {
  const { r, tr } = requireSpeaker(ctx, a.turnId);
  if (!isDiscus(r)) throw new SenderError('this is not a discus event');
  const ranges: [string, number, number, number][] = [
    ['speed', a.speed, 0, MAX_SPEED],
    ['angle', a.angle, -90, 90],
    ['timing', a.timing, 0, 1],
    ['distance', a.distance, 0, MAX_DISTANCE],
    ['release_speed', release.releaseSpeed, 0, MAX_RELEASE_SPEED],
    ['roll', release.roll, -180, 180],
    ['spin', release.spin, 0, MAX_SPEED],
  ];
  for (const [name, v, lo, hi] of ranges) {
    if (!Number.isFinite(v) || v < lo || v > hi) throw new SenderError(`${name} must be ${lo} to ${hi}`);
  }
  if (!['', 'late', 'sector'].includes(release.foulReason)) throw new SenderError("foul_reason is '', 'late' or 'sector'");
  const distance = a.foul ? 0 : a.distance;
  ctx.db.turnTimer.turnId.delete(tr.id);
  ctx.db.discusThrow.insert({
    id: 0n,
    roomId: r.id,
    turnId: tr.id,
    playerId: tr.playerId,
    throwNo: r.roundNo,
    speed: a.speed,
    angle: a.angle,
    timing: a.timing,
    distance,
    foul: a.foul,
    at: ctx.timestamp,
    ...release,
    foulReason: a.foul ? release.foulReason || 'late' : '',
  });
  ctx.db.turn.id.update({ ...tr, status: 'scored' });
  const p = ctx.db.player.id.find(tr.playerId)!;
  const best = Math.round(distance * 10);
  if (best > p.total) ctx.db.player.id.update({ ...p, total: best });
  idleScene(ctx, r.id);
  setPhase(ctx, r, 'scored');
}

// The first discus phones (build 18 and 19): kept exactly as it was.
export const throwDiscus = spacetimedb.reducer(
  { turnId: t.u64(), speed: t.f32(), angle: t.f32(), timing: t.f32(), distance: t.f32(), foul: t.bool() },
  (ctx, a) => recordThrow(ctx, a, { releaseSpeed: 0, roll: 0, spin: 0, foulReason: '' })
);

// Newer phones send the release in detail too, for the arena's technique call.
export const throwDiscusFull = spacetimedb.reducer(
  {
    turnId: t.u64(), speed: t.f32(), angle: t.f32(), timing: t.f32(), distance: t.f32(), foul: t.bool(),
    releaseSpeed: t.f32(), roll: t.f32(), spin: t.f32(), foulReason: t.string(),
  },
  (ctx, { releaseSpeed, roll, spin, foulReason, ...a }) => recordThrow(ctx, a, { releaseSpeed, roll, spin, foulReason })
);

// ~20 Hz from the speaking phone. In the lobby any poet may send it, so the
// scene can flare during their mic check. Stale frames are dropped quietly.
export const setProsody = spacetimedb.reducer(
  { roomId: t.u64(), loudness: t.f32(), pitch: t.f32(), hits: t.u32() },
  (ctx, { roomId, loudness, pitch, hits }) => {
    const r = ctx.db.room.id.find(roomId);
    const pr = ctx.db.prosody.roomId.find(roomId);
    const p = r ? playerOf(ctx, roomId) : undefined;
    if (!r || !pr || !p) return;
    let turnId = 0n;
    if (r.phase === 'speaking') {
      const tr = ctx.db.turn.id.find(r.currentTurnId);
      if (!tr || tr.playerId !== p.id) return;
      turnId = tr.id;
    } else if (r.phase !== 'lobby') {
      return;
    }
    ctx.db.prosody.roomId.update({
      roomId,
      turnId,
      playerId: p.id,
      loudness: clamp01(loudness),
      pitch: Number.isFinite(pitch) ? Math.max(0, pitch) : 0,
      hits,
    });
  }
);

// Anyone watching, poet or spectator.
export const react = spacetimedb.reducer(
  { roomId: t.u64(), kind: t.string() },
  (ctx, { roomId, kind }) => {
    getRoom(ctx, roomId);
    ctx.db.reaction.insert({ id: 0n, roomId, kind: text(kind, 'kind', 1, 16), at: ctx.timestamp });
  }
);

// ---------------------------------------------------------------- scheduler

export const turnTimeout = spacetimedb.reducer(
  { onSchedule: turnTimer },
  { timer: turnTimer.rowType },
  (ctx, { timer }) => {
    const tr = ctx.db.turn.id.find(timer.turnId);
    if (!tr || tr.status !== 'speaking') return;
    const r = ctx.db.room.id.find(tr.roomId);
    if (!r || r.currentTurnId !== tr.id) return;
    if (isDiscus(r)) {
      // The thrower never let go: no throw this round.
      ctx.db.turn.id.update({ ...tr, status: 'skipped' });
      idleScene(ctx, r.id);
      setPhase(ctx, r, 'scored');
      return;
    }
    closeTurn(ctx, r, tr, tr.transcript);
  }
);

// ---------------------------------------------------------------- agent

// Approves the poet's name for TTS, and coins an epithet if they had none.
export const namePoet = spacetimedb.reducer(
  { playerId: t.u64(), name: t.string(), epithet: t.string() },
  (ctx, args) => {
    requireService(ctx);
    const p = ctx.db.player.id.find(args.playerId);
    if (!p) throw new SenderError('no such player');
    ctx.db.player.id.update({
      ...p,
      name: text(args.name, 'name', 1, 24),
      epithet: text(args.epithet, 'epithet', 1, 48),
      named: true,
    });
  }
);

const HandDeal = t.object('HandDeal', {
  playerId: t.u64(),
  cards: t.array(t.string()),
});

// Sets the round's theme, tops every hand back up to five, and lays out the
// turns in rotated seat order. Allowed while dealing, or during the previous
// round's verdict so the next round is ready when the arena advances.
export const dealRound = spacetimedb.reducer(
  { roomId: t.u64(), roundNo: t.u32(), theme: t.string(), hands: t.array(HandDeal) },
  (ctx, { roomId, roundNo, theme, hands }) => {
    requireService(ctx);
    const r = getRoom(ctx, roomId);
    const now = r.phase === 'dealing' && roundNo === r.roundNo;
    const ahead =
      r.phase === 'round_end' && !r.themeChoice && roundNo === r.roundNo + 1 && roundNo <= r.rounds;
    if (!now && !ahead) throw new SenderError(`cannot deal round ${roundNo} now`);
    if (findRound(ctx, roomId, roundNo)) throw new SenderError(`round ${roundNo} is already dealt`);

    const players = playersOf(ctx, roomId);
    // Coach has no cards: its deal is only the theme, with empty hands or none at all.
    const dealt = isCoach(r) && hands.length === 0 ? players.map(p => ({ playerId: p.id, cards: [] as string[] })) : hands;
    const byPlayer = new Map(dealt.map(h => [h.playerId, h.cards]));
    if (byPlayer.size !== dealt.length || players.some(p => !byPlayer.has(p.id))) {
      throw new SenderError('deal exactly one hand to every poet');
    }

    const turns = layOutRound(ctx, roomId, roundNo, text(theme, 'theme', 1, 120));

    for (const p of players) {
      const h = ctx.db.hand.playerId.find(p.id)!;
      const cards = [...h.cards];
      for (const c of byPlayer.get(p.id)!) {
        const card = c.trim().slice(0, 60);
        if (cards.length >= HAND_SIZE) break;
        if (card && !cards.includes(card)) cards.push(card);
      }
      ctx.db.hand.playerId.update({ ...h, cards });
    }

    if (now) ctx.db.room.id.update({ ...r, phase: 'ready', nextTheme: '', currentTurnId: turns[0].id });
  }
);

// The judge's scores, one 0-10 value per axis of the event's rubric. An axis
// Claude could not score in time is 0 (for poetry: craft, image, answer).
export const postScore = spacetimedb.reducer(
  {
    turnId: t.u64(),
    axes: t.array(t.u8()),
    verdict: t.string(),
    bestLine: t.string(),
    coined: t.string(),
  },
  (ctx, args) => {
    requireService(ctx);
    const tr = getTurn(ctx, args.turnId);
    if (tr.status !== 'judging') throw new SenderError(`turn is ${tr.status}, not judging`);
    const r = getRoom(ctx, tr.roomId);
    const { axes } = args;
    // Talk to Homer scores a verse attempt on the poetry rubric; a talk-back reply has no axes.
    const attempt = isCoach(r) && axes.length === EVENTS.poetry.axes;
    const want = attempt ? EVENTS.poetry.axes : EVENTS[r.event].axes;
    if (axes.length !== want) {
      throw new SenderError(isCoach(r) ? 'coach scores have 0 or 5 axes' : `${r.event} scores have ${want} axes`);
    }
    if (axes.some(a => a > 10)) throw new SenderError('scores are 0 to 10');
    const weights = attempt ? EVENTS.poetry.weights : EVENTS[r.event].weights;
    const total = axes.reduce((sum, a, i) => sum + a * (weights[i] ?? 1), 0);

    ctx.db.score.insert({
      turnId: tr.id,
      roomId: tr.roomId,
      roundId: tr.roundId,
      playerId: tr.playerId,
      axes,
      total,
      verdict: args.verdict.trim().slice(0, isCoach(r) ? 600 : 300), // a coach verdict is Homer's spoken reply
      bestLine: args.bestLine.trim().slice(0, 200),
      coined: args.coined.trim().slice(0, 60),
    });
    ctx.db.turn.id.update({ ...tr, status: 'scored' });
    const p = ctx.db.player.id.find(tr.playerId);
    if (p) ctx.db.player.id.update({ ...p, total: p.total + total });
    if (r.currentTurnId === tr.id && r.phase === 'judging') setPhase(ctx, getRoom(ctx, r.id), 'scored');
  }
);

// The verse was not fit for the hall. It scores nothing and is not quoted.
export const declineTurn = spacetimedb.reducer({ turnId: t.u64() }, (ctx, { turnId }) => {
  requireService(ctx);
  const tr = getTurn(ctx, turnId);
  if (tr.status !== 'judging') throw new SenderError(`turn is ${tr.status}, not judging`);
  ctx.db.turn.id.update({ ...tr, status: 'declined' });
  const r = getRoom(ctx, tr.roomId);
  if (r.currentTurnId === tr.id && r.phase === 'judging') setPhase(ctx, r, 'scored');
});

// Homer's round verdict and the line carved in gold.
export const postVerdict = spacetimedb.reducer(
  { roundId: t.u64(), verdict: t.string(), bestTurnId: t.u64(), bestLine: t.string() },
  (ctx, args) => {
    requireService(ctx);
    const rd = ctx.db.round.id.find(args.roundId);
    if (!rd) throw new SenderError('no such round');
    if (rd.verdict !== '') throw new SenderError('this round already has a verdict');
    if (args.bestTurnId !== 0n) {
      const best = ctx.db.turn.id.find(args.bestTurnId);
      if (!best || best.roundId !== rd.id) throw new SenderError('best turn is not in this round');
    }
    ctx.db.round.id.update({
      ...rd,
      verdict: text(args.verdict, 'verdict', 1, 600),
      bestTurnId: args.bestTurnId,
      bestLine: args.bestLine.trim().slice(0, 200),
    });
  }
);

// The stitched song, one line per entry, each credited to the turn it came
// from. Replaces any earlier version.
export const postSong = spacetimedb.reducer(
  { roomId: t.u64(), turnIds: t.array(t.u64()), lines: t.array(t.string()) },
  (ctx, { roomId, turnIds, lines }) => {
    requireService(ctx);
    getRoom(ctx, roomId);
    if (turnIds.length !== lines.length) throw new SenderError('one turn id per line');
    ctx.db.songLine.roomId.delete(roomId);
    lines.slice(0, 16).forEach((line, i) => {
      ctx.db.songLine.insert({
        id: 0n,
        roomId,
        lineNo: i,
        turnId: turnIds[i],
        text: line.trim().slice(0, 200),
      });
    });
  }
);

// The emotion engine, every ~1.5 s while a verse is live. Updates for a
// turn that is no longer current are dropped quietly.
export const setScene = spacetimedb.reducer(
  {
    turnId: t.u64(),
    anger: t.f32(),
    grief: t.f32(),
    joy: t.f32(),
    awe: t.f32(),
    tenderness: t.f32(),
    fear: t.f32(),
    defiance: t.f32(),
    longing: t.f32(),
  },
  (ctx, args) => {
    requireService(ctx);
    const tr = ctx.db.turn.id.find(args.turnId);
    if (!tr || (tr.status !== 'speaking' && tr.status !== 'judging')) return;
    const r = ctx.db.room.id.find(tr.roomId);
    if (!r || r.currentTurnId !== tr.id) return;

    const w = {
      anger: clamp01(args.anger),
      grief: clamp01(args.grief),
      joy: clamp01(args.joy),
      awe: clamp01(args.awe),
      tenderness: clamp01(args.tenderness),
      fear: clamp01(args.fear),
      defiance: clamp01(args.defiance),
      longing: clamp01(args.longing),
    };
    ctx.db.scene.roomId.update({
      roomId: r.id,
      turnId: tr.id,
      playerId: tr.playerId,
      ...w,
      updatedAt: ctx.timestamp,
    });
    const ms = (ctx.timestamp.microsSinceUnixEpoch - tr.startedAt.microsSinceUnixEpoch) / 1000n;
    ctx.db.colorSample.insert({ id: 0n, roomId: r.id, turnId: tr.id, ms: Number(ms), ...w });
  }
);
