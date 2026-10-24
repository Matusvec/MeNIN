// End-to-end smoke test against a running server: one arena, two phones and
// the agent service, each with its own identity, play a full two-round
// battle over the HTTP API. Uses the same calls the agent service will make.
//
//   npm run smoke                     # local server, database "homer"
//   STDB_URL=... STDB_DB=... npm run smoke
//
// Needs the `spacetime` CLI logged in as the database owner (to set the
// service key). Creates a new room each run; it does not clear data.

import { execFileSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';

const URL_ = process.env.STDB_URL ?? 'http://127.0.0.1:3000';
const DB = process.env.STDB_DB ?? 'homer';
const SERVER = process.env.STDB_SERVER ?? 'local';

let failures = 0;
function check(cond, what) {
  console.log(`${cond ? 'ok  ' : 'FAIL'} ${what}`);
  if (!cond) failures++;
}

async function identity() {
  const res = await fetch(`${URL_}/v1/identity`, { method: 'POST' });
  const { identity, token } = await res.json();
  return { hex: identity, token };
}

async function call(who, reducer, ...args) {
  const res = await fetch(`${URL_}/v1/database/${DB}/call/${reducer}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${who.token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(args),
  });
  const body = await res.text();
  if (!res.ok) throw new Error(`${reducer}: ${res.status} ${body}`);
}

async function fails(who, reducer, ...args) {
  try {
    await call(who, reducer, ...args);
    return false;
  } catch {
    return true;
  }
}

// Returns rows as objects keyed by column name.
async function sql(who, query) {
  const res = await fetch(`${URL_}/v1/database/${DB}/sql`, {
    method: 'POST',
    headers: who ? { Authorization: `Bearer ${who.token}` } : {},
    body: query,
  });
  if (!res.ok) throw new Error(`sql: ${res.status} ${await res.text()}`);
  const [{ schema, rows }] = await res.json();
  const names = schema.elements.map(e => e.name.some);
  return rows.map(r => Object.fromEntries(names.map((n, i) => [n, r[i]])));
}

const sleep = ms => new Promise(r => setTimeout(r, ms));
const room = async id => (await sql(null, `SELECT * FROM room WHERE id = ${id}`))[0];
const turn = async id => (await sql(null, `SELECT * FROM turn WHERE id = ${id}`))[0];

const cards = n => Array.from({ length: n }, (_, i) => `formula ${i + 1}`);

// ---------------------------------------------------------------- setup

const key = randomBytes(16).toString('hex');
execFileSync('spacetime', ['call', '-s', SERVER, DB, 'set_service_key', key], { stdio: 'ignore' });

const [arena, ada, bo, agent, stranger] = await Promise.all([
  identity(),
  identity(),
  identity(),
  identity(),
  identity(),
]);
await call(agent, 'claim_service', key);
check(await fails(stranger, 'claim_service', 'not-the-key-not-the-key'), 'wrong service key is refused');

await call(arena, 'create_room', 2, 10, 2, 120, 'four_beat', false, false, false);
const rooms = (await sql(null, 'SELECT * FROM room')).filter(r => r.host[0] === `0x${arena.hex}`);
const R = rooms.sort((a, b) => b.id - a.id)[0];
check(R.phase === 'lobby' && R.code.length === 4, `room ${R.code} is in the lobby`);

await call(ada, 'join_room', R.code.toLowerCase(), 'Ada', '', []);
await call(bo, 'join_room', R.code, 'Bo', 'Breaker of Deadlines', ['storm-throated']);
check(await fails(stranger, 'join_room', 'QQQQ', 'X', '', []), 'bad room code is refused');
check(await fails(stranger, 'join_room', R.code, 'ada', '', []) === false, 'a dropped seat can be taken over by name');
// The stranger now holds Ada's seat (HTTP callers count as disconnected);
// Ada takes it back the same way.
await call(ada, 'join_room', R.code, 'Ada', '', []);

const players = await sql(null, `SELECT * FROM player WHERE room_id = ${R.id}`);
const A = players.find(p => p.name === 'Ada');
const B = players.find(p => p.name === 'Bo');
check(players.length === 2 && A && B, 'two poets in the hall');
check(A.identity[0] === `0x${ada.hex}`, 'Ada has her seat back');

check(await fails(ada, 'name_poet', A.id, 'Ada', 'Iron-Hearted'), 'a phone cannot call agent reducers');
await call(agent, 'name_poet', A.id, 'Ada', 'Iron-Hearted');
check((await sql(null, `SELECT * FROM player WHERE id = ${A.id}`))[0].named, 'agent named Ada');

check(await fails(ada, 'start_battle', R.id), 'only the arena starts the battle');
await call(arena, 'start_battle', R.id);
check((await room(R.id)).phase === 'dealing', 'battle starts in dealing');
check(await fails(stranger, 'join_room', R.code, 'Cy', '', []),'no new poets after the battle begins');

// ---------------------------------------------------------------- round 1

check(await fails(agent, 'deal_round', R.id, 1, 'A ship', [[A.id, cards(5)]]), 'every poet must be dealt');
await call(agent, 'deal_round', R.id, 1, 'A ship that never came home', [
  [A.id, cards(5)],
  [B.id, ['storm-throated', ...cards(6)]],
]);
check(await fails(agent, 'deal_round', R.id, 1, 'again', [[A.id, []], [B.id, []]]), 'a round is dealt once');

let r = await room(R.id);
check(r.phase === 'ready' && r.round_no === 1, 'dealt: ready for round 1');
const adaHand = await sql(ada, 'SELECT * FROM hand');
check(adaHand.length === 1 && adaHand[0].player_id === A.id, 'Ada sees only her own hand');
check(adaHand[0].formulas.length === 5, 'hand holds five cards');
check((await sql(null, 'SELECT * FROM hand')).length === 0, 'an anonymous client sees no hands');

let T = await turn(r.current_turn_id);
check(T.player_id === A.id && T.turn_no === 0, 'Ada speaks first in round 1');
check(await fails(bo, 'start_turn', T.id), 'Bo cannot start Ada\'s turn');
await call(ada, 'start_turn', T.id);
T = await turn(T.id);
check(T.status === 'speaking' && (await room(R.id)).phase === 'speaking', 'Ada is speaking');
check(T.beat_at[0] - T.started_at[0] === 2_000_000, 'one bar of count-in at 120 bpm');

await call(ada, 'set_prosody', R.id, 0.7, 180, 1);
await call(bo, 'set_prosody', R.id, 0.9, 90, 9); // not the speaker: dropped
const pr = (await sql(null, `SELECT * FROM prosody WHERE room_id = ${R.id}`))[0];
check(pr.player_id === A.id && pr.hits === 1, 'prosody comes only from the speaker');

await call(ada, 'update_transcript', T.id, 'wine-dark sea took my brother');
check(await fails(bo, 'update_transcript', T.id, 'hijack'), 'Bo cannot write Ada\'s transcript');
await call(ada, 'play_card', T.id, 'formula 2');
check(await fails(ada, 'play_card', T.id, 'formula 2'), 'a played card is gone from the hand');
await call(ada, 'rescue', T.id, 'formula 3');
await call(agent, 'set_scene', T.id, 0.1, 0.6, 0, 0.2, 0, 0, 0.1, 0.3);
const sc = (await sql(null, `SELECT * FROM scene WHERE room_id = ${R.id}`))[0];
check(sc.turn_id === T.id && Math.abs(sc.grief - 0.6) < 1e-6, 'scene shows the speaker\'s emotion');

await call(ada, 'end_turn', T.id, 'wine-dark sea / took my brother\'s ship');
T = await turn(T.id);
check(T.status === 'judging' && T.played.length === 1 && T.rescues === 1, 'Ada\'s verse goes to the judge');
check(await fails(agent, 'post_score', T.id, 11, 5, 5, 5, 5, 'x', 'y', ''), 'scores above 10 are refused');
await call(agent, 'post_score', T.id, 8, 7, 6, 5, 4, 'Strong bones.', 'took my brother\'s ship', 'storm-throated');
check((await room(R.id)).phase === 'scored', 'scored');
const adaTurnId = T.id;
check((await sql(null, `SELECT * FROM player WHERE id = ${A.id}`))[0].total === 30, 'Ada has 30');

await call(arena, 'advance', R.id);
r = await room(R.id);
T = await turn(r.current_turn_id);
check(r.phase === 'ready' && T.player_id === B.id, 'Bo is up');

// Bo starts and never ends: the scheduled timer closes the turn.
await call(bo, 'start_turn', T.id);
await call(bo, 'update_transcript', T.id, 'grey-eyed Athena');
const started = await turn(T.id);
const ms = (started.ends_at[0] - started.started_at[0]) / 1000 + 2000 + 1500;
console.log(`     waiting ${Math.round(ms / 1000)} s for the turn timer...`);
await sleep(ms);
T = await turn(T.id);
check(T.status === 'judging' && T.transcript === 'grey-eyed Athena', 'the timer ended Bo\'s turn');
await call(agent, 'post_score', T.id, 6, 6, 6, 6, 6, 'Fair.', 'grey-eyed Athena', '');

await call(arena, 'advance', R.id);
check((await room(R.id)).phase === 'round_end', 'round 1 is over');
// Deal round 2 during the verdict so it is ready when the arena advances.
await call(agent, 'deal_round', R.id, 2, 'The last fire in the hall', [
  [A.id, cards(5)],
  [B.id, cards(5)],
]);
check((await room(R.id)).phase === 'round_end', 'dealing ahead does not move the phase');
const round1 = (await sql(null, `SELECT * FROM round WHERE room_id = ${R.id}`)).find(x => x.round_no === 1);
await call(agent, 'post_verdict', round1.id, 'The sea takes it.', adaTurnId, 'took my brother\'s ship');
check((await sql(null, `SELECT * FROM round WHERE id = ${round1.id}`))[0].best_line !== '', 'best line carved');

// ---------------------------------------------------------------- round 2

await call(arena, 'advance', R.id);
r = await room(R.id);
T = await turn(r.current_turn_id);
check(r.phase === 'ready' && r.round_no === 2 && T.player_id === B.id, 'round 2: order rotated, Bo first');
const bHand = (await sql(bo, 'SELECT * FROM hand'))[0];
check(bHand.formulas.length === 5, 'Bo\'s hand topped back up to five');

// A silent first attempt gets one retry; a silent second attempt is skipped.
await call(bo, 'start_turn', T.id);
await call(bo, 'end_turn', T.id, '   ');
T = await turn(T.id);
check(T.status === 'waiting' && T.attempt === 2 && (await room(R.id)).phase === 'ready', 'silence: one retry');
await call(arena, 'start_turn', T.id); // the arena may start it (auto-ready)
await call(bo, 'end_turn', T.id, '');
T = await turn(T.id);
check(T.status === 'skipped' && (await room(R.id)).phase === 'scored', 'silence twice: skipped');

await call(arena, 'advance', R.id);
r = await room(R.id);
check(r.phase === 'ready', 'Ada is up');
check(await fails(ada, 'skip_turn', r.current_turn_id), 'only the arena skips');
await call(arena, 'skip_turn', r.current_turn_id);
await call(arena, 'advance', R.id);
check((await room(R.id)).phase === 'round_end', 'round 2 is over');
check(await fails(agent, 'deal_round', R.id, 3, 'too many', [[A.id, []], [B.id, []]]), 'no round 3');

await call(arena, 'advance', R.id);
check((await room(R.id)).phase === 'finale', 'finale');
await call(agent, 'post_song', R.id, [T.id, T.id], ['line one', 'line two']);
check((await sql(null, `SELECT * FROM song_line WHERE room_id = ${R.id}`)).length === 2, 'the song is posted');
await call(arena, 'advance', R.id);
check((await room(R.id)).phase === 'finished', 'finished');

// ---------------------------------------------------------------- rematch

await call(arena, 'rematch', R.id);
r = await room(R.id);
const after = await sql(null, `SELECT * FROM player WHERE room_id = ${R.id}`);
check(r.phase === 'dealing' && r.round_no === 1, 'rematch: straight back to dealing');
check(after.length === 2 && after.every(p => p.total === 0), 'rematch keeps the poets, clears the scores');
check((await sql(null, `SELECT * FROM turn WHERE room_id = ${R.id}`)).length === 0, 'rematch clears the turns');
check(after.find(p => p.id === A.id).epithet === 'Iron-Hearted', 'rematch keeps epithets');

console.log(failures === 0 ? '\nall checks passed' : `\n${failures} check(s) failed`);
process.exit(failures === 0 ? 0 : 1);
