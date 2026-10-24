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
  config,
  service,
  turnTimer,
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

const HAND_SIZE = 5;
const MIN_PLAYERS = 2;
const MAX_PLAYERS = 5;
const DEMO_PLAYERS = 2;
const GRACE_MICROS = 2_000_000n; // the final transcript can land this late
const CODE_LETTERS = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I or O
const FORMS = ['four_beat', 'hexameter'];
const EPOCH = Timestamp.UNIX_EPOCH;

// Each event is a config on the same engine (SPEC "The games"). Axis labels
// live in the app's event config; here we only need how many there are and
// what kind of card the hand holds. Debate will add { axes: 5, card: 'move' }.
const EVENTS: Record<string, { axes: number; card: string }> = {
  poetry: { axes: 5, card: 'formula' }, // beat, craft, image, answer, range
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
  if (n < MIN_PLAYERS) throw new SenderError(`need at least ${MIN_PLAYERS} poets`);
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
  for (const p of [...ctx.db.player.identity.filter(ctx.sender)]) {
    if (!p.connected) ctx.db.player.id.update({ ...p, connected: true });
  }
});

export const onDisconnect = spacetimedb.clientDisconnected(ctx => {
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
export const claimService = spacetimedb.reducer({ key: t.string() }, (ctx, { key }) => {
  const c = ctx.db.config.id.find(0);
  if (!c || c.serviceKey === '' || c.serviceKey !== key) throw new SenderError('wrong key');
  if (!ctx.db.service.identity.find(ctx.sender)) ctx.db.service.insert({ identity: ctx.sender });
});

// ---------------------------------------------------------------- arena

export const createRoom = spacetimedb.reducer(
  {
    event: t.string(),
    rounds: t.u32(),
    turnSeconds: t.u32(),
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
    if (args.turnSeconds < 10 || args.turnSeconds > 120) {
      throw new SenderError('turnSeconds must be 10 to 120');
    }
    if (!args.demo && (args.rounds < 1 || args.rounds > 5)) {
      throw new SenderError('rounds must be 1 to 5');
    }
    if (!args.demo && (args.linesPerTurn < 1 || args.linesPerTurn > 8)) {
      throw new SenderError('linesPerTurn must be 1 to 8');
    }

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
      rounds: args.demo ? 1 : args.rounds,
      turnSeconds: args.turnSeconds,
      linesPerTurn: args.demo ? 2 : args.linesPerTurn,
      bpm: args.bpm,
      form: args.form,
      maxPlayers: args.demo ? DEMO_PLAYERS : MAX_PLAYERS,
      autoReady: args.demo ? true : args.autoReady,
      themeChoice: args.themeChoice,
      demo: args.demo,
      nextTheme: '',
      currentTurnId: 0n,
      createdAt: ctx.timestamp,
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

  if (r.phase === 'scored') {
    const cur = getTurn(ctx, r.currentTurnId);
    const next = turnsOf(ctx, cur.roundId).find(x => x.turnNo === cur.turnNo + 1);
    if (next) setPhase(ctx, r, 'ready', next.id);
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

export const joinRoom = spacetimedb.reducer(
  { code: t.string(), name: t.string(), epithet: t.string(), hoard: t.array(t.string()) },
  (ctx, args) => {
    const r = ctx.db.room.code.find(args.code.trim().toUpperCase());
    if (!r || r.phase === 'finished') throw new SenderError('no such room');
    const name = text(args.name, 'name', 1, 24);
    const epithet = text(args.epithet, 'epithet', 0, 48);
    const hoard = args.hoard.slice(0, 20).map(c => text(c, 'hoard card', 1, 60));
    const players = playersOf(ctx, r.id);
    const lobby = r.phase === 'lobby';

    // Back on the same device.
    const mine = players.find(p => p.identity.isEqual(ctx.sender));
    if (mine) {
      const changed = lobby && (mine.name !== name || mine.epithet !== epithet);
      ctx.db.player.id.update({
        ...mine,
        connected: true,
        ...(lobby ? { name, epithet, hoard } : {}),
        ...(changed ? { named: false } : {}),
      });
      return;
    }

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

  const barMicros = BigInt(Math.round((4 * 60_000_000) / r.bpm)); // one bar of count-in
  const beatAt = after(ctx.timestamp, barMicros);
  const endsAt = after(beatAt, BigInt(r.turnSeconds) * 1_000_000n);
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
    closeTurn(ctx, r, tr, transcript.slice(0, 4000));
  }
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
    const byPlayer = new Map(hands.map(h => [h.playerId, h.cards]));
    if (byPlayer.size !== hands.length || players.some(p => !byPlayer.has(p.id))) {
      throw new SenderError('deal exactly one hand to every poet');
    }

    const rd = ctx.db.round.insert({
      id: 0n,
      roomId,
      roundNo,
      theme: text(theme, 'theme', 1, 120),
      verdict: '',
      bestTurnId: 0n,
      bestLine: '',
      dealtAt: ctx.timestamp,
    });

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

    const offset = (roundNo - 1) % players.length;
    const order = [...players.slice(offset), ...players.slice(0, offset)];
    const turns = order.map((p, i) =>
      ctx.db.turn.insert({
        id: 0n,
        roomId,
        roundId: rd.id,
        playerId: p.id,
        turnNo: i,
        status: 'waiting',
        attempt: 1,
        transcript: '',
        played: [],
        rescue: '',
        rescues: 0,
        startedAt: EPOCH,
        beatAt: EPOCH,
        endsAt: EPOCH,
      })
    );

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
    const want = EVENTS[r.event].axes;
    if (axes.length !== want) throw new SenderError(`${r.event} scores have ${want} axes`);
    if (axes.some(a => a > 10)) throw new SenderError('scores are 0 to 10');
    const total = axes.reduce((a, b) => a + b, 0);

    ctx.db.score.insert({
      turnId: tr.id,
      roomId: tr.roomId,
      roundId: tr.roundId,
      playerId: tr.playerId,
      axes,
      total,
      verdict: args.verdict.trim().slice(0, 300),
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
