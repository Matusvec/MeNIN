// DEV ONLY: a stand-in for the agent service, so a battle can run end to end
// on real devices before the real agent exists. Never run it for a demo.
//
// It watches the database and does the agent's job with placeholders:
// names poets, deals stock cards, posts patterned scores, moves the scene,
// and writes the round verdict and the song. Every theme and verdict it
// writes starts with "[dev]" so its output can't pass for Homer's.
//
//   HOMER_DEV_AGENT=1 npm run dev-agent
//   HOMER_DEV_AGENT=1 HOMER_DEV_ROOM=ABCD npm run dev-agent   # one room only
//   HOMER_DEV_SKIP_HOSTS=<hex>,<hex> ...   # skip rooms these arenas host
//
// Needs the `spacetime` CLI logged in as the database owner (to register as
// a service). Stop it before the real agent service takes over.

import { call, serviceIdentity, sql } from './stdb.mjs';

if (process.env.HOMER_DEV_AGENT !== '1') {
  console.error('dev-agent writes placeholder scores. Set HOMER_DEV_AGENT=1 to run it.');
  process.exit(2);
}
const ONLY_ROOM = process.env.HOMER_DEV_ROOM?.toUpperCase();
// Rooms hosted by these identities belong to the real agent service; leave them alone.
const SKIP_HOSTS = new Set(
  (process.env.HOMER_DEV_SKIP_HOSTS ?? '')
    .split(',')
    .map(h => h.trim().toLowerCase().replace(/^0x/, ''))
    .filter(Boolean)
    .map(h => `0x${h}`)
);

const THEMES = ['A ship that never came home', 'The last fire in the hall', 'A city under siege'];
const CARDS = [
  'the wine-dark sea',
  'the whale-road',
  'when rose-fingered Dawn came early',
  'grey-eyed Athena',
  'swift-footed Achilles',
  'the hollow ships',
  'the loud-roaring sea',
  'the swan-road',
  'the bone-house',
  'the long-haired Achaeans',
  'the earth-shaker',
  'bronze-armored',
];
const EMOTIONS = 8;
const SCENE_EVERY_MS = 1500;
const BUSY_MS = 400; // poll fast while a turn is live or right after acting
const IDLE_MS = 1500; // otherwise, to spare Maincloud credits
const LIVE_PHASES = ['dealing', 'speaking', 'judging'];
const CANDIDATES = 7; // more than a hand, so duplicates can be skipped

const agent = await serviceIdentity();
const lastScene = new Map(); // turn id -> ms of the last set_scene
const reported = new Set(); // error lines already printed
let acted = false; // something was written this tick

function log(line) {
  console.log(`${new Date().toISOString().slice(11, 19)} ${line}`);
}

async function act(what, reducer, ...args) {
  try {
    await call(agent, reducer, ...args);
    acted = true;
    log(what);
  } catch (e) {
    const line = `${what} failed: ${e.message}`;
    if (!reported.has(line)) log(line);
    reported.add(line);
  }
}

const lines = transcript => transcript.split('\n').map(l => l.trim()).filter(Boolean);

// Up to two cards from the poet's hoard, then stock cards in an order that
// changes with the poet and the round.
function candidates(p, roundNo) {
  const out = p.hoard.slice(0, 2);
  for (let i = 0; out.length < CANDIDATES; i++) {
    const c = CARDS[(Number(p.id) * 5 + roundNo * 3 + i) % CARDS.length];
    if (!out.includes(c)) out.push(c);
  }
  return out;
}

async function deal(r, roundNo) {
  const players = await sql(null, `SELECT * FROM player WHERE room_id = ${r.id}`);
  const theme = r.next_theme || THEMES[(roundNo - 1) % THEMES.length];
  await act(
    `${r.code} dealt round ${roundNo}`,
    'deal_round',
    r.id,
    roundNo,
    `[dev] ${theme}`,
    players.map(p => [p.id, candidates(p, roundNo)])
  );
}

async function judge(r) {
  const [t] = await sql(null, `SELECT * FROM turn WHERE id = ${r.current_turn_id}`);
  if (!t || t.status !== 'judging') return;
  const ls = lines(t.transcript);
  const words = t.transcript.split(/\s+/).filter(Boolean).length;
  const axes = [
    Math.min(10, 3 + ls.length * 2), // beat
    Math.min(10, 3 + t.played.length * 2), // craft
    4 + (words % 5), // image
    6, // answer
    5 + (t.rescues === 0 ? 1 : 0), // range
  ];
  const best = ls.reduce((a, b) => (b.length > a.length ? b : a), '');
  await act(`${r.code} scored turn ${t.id}`, 'post_score', t.id, axes, '[dev] placeholder verdict', best, '');
}

async function scene(r) {
  const turnId = r.current_turn_id;
  const now = Date.now();
  if (now - (lastScene.get(turnId) ?? 0) < SCENE_EVERY_MS) return;
  lastScene.set(turnId, now);
  // Two emotions lead at a time and drift every few seconds.
  const k = Math.floor(now / 4500);
  const w = Array.from({ length: EMOTIONS }, (_, i) =>
    i === k % EMOTIONS ? 0.7 : i === (k + 3) % EMOTIONS ? 0.4 : 0.05
  );
  await act(`${r.code} scene for turn ${turnId}`, 'set_scene', turnId, ...w);
}

async function roundEnd(r) {
  const rounds = await sql(null, `SELECT * FROM round WHERE room_id = ${r.id}`);
  const cur = rounds.find(x => x.round_no === r.round_no);
  if (cur && cur.verdict === '') {
    const scores = await sql(null, `SELECT * FROM score WHERE round_id = ${cur.id}`);
    const best = scores.reduce((a, b) => (!a || b.total > a.total ? b : a), null);
    await act(
      `${r.code} verdict for round ${r.round_no}`,
      'post_verdict',
      cur.id,
      '[dev] placeholder round verdict',
      best ? best.turn_id : 0,
      best ? best.best_line : ''
    );
  }
  // Deal the next round ahead, as the real agent should.
  const next = r.round_no + 1;
  if (!r.theme_choice && next <= r.rounds && !rounds.some(x => x.round_no === next)) await deal(r, next);
}

async function finale(r) {
  const song = await sql(null, `SELECT * FROM song_line WHERE room_id = ${r.id}`);
  if (song.length > 0) return;
  const turns = await sql(null, `SELECT * FROM turn WHERE room_id = ${r.id}`);
  const picked = turns
    .filter(t => t.status === 'scored')
    .sort((a, b) => a.id - b.id)
    .map(t => [t.id, lines(t.transcript)[0]])
    .filter(([, line]) => line)
    .slice(0, r.demo ? 4 : 12);
  if (picked.length === 0) return;
  await act(`${r.code} song (${picked.length} lines)`, 'post_song', r.id, picked.map(x => x[0]), picked.map(x => x[1]));
}

async function tick() {
  const rooms = (await sql(null, 'SELECT * FROM room')).filter(
    r => r.phase !== 'finished' && (!ONLY_ROOM || r.code === ONLY_ROOM) && !SKIP_HOSTS.has(r.host[0])
  );
  const roomIds = new Set(rooms.map(r => r.id));
  for (const p of await sql(null, 'SELECT * FROM player WHERE named = false')) {
    if (!roomIds.has(p.room_id)) continue;
    await act(`named ${p.name}`, 'name_poet', p.id, p.name, p.epithet || 'of the Dev Build');
  }
  for (const r of rooms) {
    if (r.phase === 'dealing') await deal(r, r.round_no);
    else if (r.phase === 'speaking') await scene(r);
    else if (r.phase === 'judging') await judge(r);
    else if (r.phase === 'round_end') await roundEnd(r);
    else if (r.phase === 'finale') await finale(r);
  }
  return rooms.some(r => LIVE_PHASES.includes(r.phase));
}

log(`DEV AGENT running as ${agent.hex.slice(0, 12)}…${ONLY_ROOM ? ` (room ${ONLY_ROOM} only)` : ''}`);
for (;;) {
  acted = false;
  let live = false;
  try {
    live = await tick();
  } catch (e) {
    const line = `tick failed: ${e.message}`;
    if (!reported.has(line)) log(line);
    reported.add(line);
  }
  await new Promise(r => setTimeout(r, live || acted ? BUSY_MS : IDLE_MS));
}
