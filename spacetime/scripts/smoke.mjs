// End-to-end smoke test against a running server: one arena, two phones and
// the agent service, each with its own identity, play a full two-round
// battle over the HTTP API, then a discus event and a switch back to poetry.
// Uses the same calls the agent service will make.
//
//   npm run smoke                     # local server, database "homer-test"
//   STDB_URL=... STDB_DB=... npm run smoke
//
// Needs the `spacetime` CLI logged in as the database owner (to set the
// service key). Creates a new room each run; it does not clear data.

import { call, identity, serviceIdentity, sql } from './stdb.mjs';

let failures = 0;
function check(cond, what) {
  console.log(`${cond ? 'ok  ' : 'FAIL'} ${what}`);
  if (!cond) failures++;
}

async function fails(who, reducer, ...args) {
  try {
    await call(who, reducer, ...args);
    return false;
  } catch {
    return true;
  }
}

const sleep = ms => new Promise(r => setTimeout(r, ms));
const room = async id => (await sql(null, `SELECT * FROM room WHERE id = ${id}`))[0];
const turn = async id => (await sql(null, `SELECT * FROM turn WHERE id = ${id}`))[0];

const cards = n => Array.from({ length: n }, (_, i) => `formula ${i + 1}`);

// ---------------------------------------------------------------- setup

const [arena, ada, bo, agent, stranger] = await Promise.all([
  identity(),
  identity(),
  identity(),
  serviceIdentity(),
  identity(),
]);
check(await fails(stranger, 'claim_service', 'not-the-key-not-the-key'), 'wrong service key is refused');
check(
  !(await fails(agent, 'claim_service', 'not-the-key-not-the-key')),
  'a registered service can re-claim after the key changes'
);
// The agent's registration probe: a no-op for a service, refused for anyone else.
check(!(await fails(agent, 'set_scene', 0, 0, 0, 0, 0, 0, 0, 0, 0)), 'set_scene on turn 0 is a no-op for a service');
check(await fails(stranger, 'set_scene', 0, 0, 0, 0, 0, 0, 0, 0, 0), 'set_scene is refused for a non-service');

// 2 rounds, 2 bars a line (speak + rest), 2 lines, 120 bpm: a bar is 2 s, a turn 8 s.
await call(arena, 'create_room', 'poetry', 2, 2, 2, 120, 'four_beat', false, false, false);
const rooms = (await sql(null, 'SELECT * FROM room')).filter(r => r.host[0] === `0x${arena.hex}`);
const R = rooms.sort((a, b) => b.id - a.id)[0];
check(R.phase === 'lobby' && R.code.length === 4 && R.event === 'poetry', `room ${R.code} is in the lobby`);
check(
  await fails(arena, 'create_room', 'chariots', 1, 2, 2, 80, 'four_beat', true, false, true),
  'unknown events are refused'
);
check(
  await fails(arena, 'create_room', 'poetry', 1, 30, 2, 80, 'four_beat', true, false, true),
  'bars per line is 1 or 2'
);
check(R.turn_seconds === 20 && R.bars_per_line === 2, 'free verse: 10 s a line, so two lines are one 20 s window');

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
// The app's auto-rejoin after a force-quit knows only the code and the name.
await call(ada, 'join_room', R.code, 'ada', '', []);
let ada1 = (await sql(null, `SELECT * FROM player WHERE id = ${A.id}`))[0];
check(ada1.named && ada1.name === 'Ada' && ada1.epithet === 'Iron-Hearted', 'a lobby rejoin keeps the coined epithet');

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
check(adaHand[0].cards.length === 5 && adaHand[0].kind === 'formula', 'hand holds five formula cards');
check((await sql(null, 'SELECT * FROM hand')).length === 0, 'an anonymous client sees no hands');

let T = await turn(r.current_turn_id);
check(T.player_id === A.id && T.turn_no === 0, 'Ada speaks first in round 1');
check(await fails(bo, 'start_turn', T.id), 'Bo cannot start Ada\'s turn');
await call(ada, 'start_turn', T.id);
T = await turn(T.id);
check(T.status === 'speaking' && (await room(R.id)).phase === 'speaking', 'Ada is speaking');
check(T.beat_at[0] - T.started_at[0] === 2_250_000, 'a 3-2-1 count-in (2.25 s), whatever the bpm');
check(T.ends_at[0] - T.beat_at[0] === 20_000_000, 'then one 20 s window, no bars');

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

// Force-quit mid-turn and reopen: the same identity rejoins while its own turn is live.
check(!(await fails(ada, 'join_room', R.code, 'Ada', '', [])), 'a same-device rejoin mid-turn is a reconnect');
T = await turn(T.id);
const handBack = (await sql(ada, 'SELECT * FROM hand')).find(h => h.player_id === A.id);
check(T.status === 'speaking' && T.played.length === 1 && handBack.cards.length === 4, 'the turn, played card and hand survive it');
await call(ada, 'end_turn', T.id, 'wine-dark sea / took my brother\'s ship');
T = await turn(T.id);
check(T.status === 'judging' && T.played.length === 1 && T.rescues === 1, 'Ada\'s verse goes to the judge');
check(await fails(agent, 'post_score', T.id, [11, 5, 5, 5, 5], 'x', 'y', ''), 'scores above 10 are refused');
check(await fails(agent, 'post_score', T.id, [5, 5, 5, 5], 'x', 'y', ''), 'poetry scores need five axes');
await call(agent, 'post_score', T.id, [8, 7, 6, 5, 4], 'Strong bones.', 'took my brother\'s ship', 'storm-throated');
check((await room(R.id)).phase === 'scored', 'scored');
const adaTurnId = T.id;
check((await sql(null, `SELECT * FROM player WHERE id = ${A.id}`))[0].total === 58, 'Ada has 58: content only, image and answer x4, craft x2');

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
await call(agent, 'post_score', T.id, [6, 6, 6, 6, 6], 'Fair.', 'grey-eyed Athena', '');

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
check(bHand.cards.length === 5, 'Bo\'s hand topped back up to five');

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
check(!(await fails(ada, 'join_room', R.code, 'Ada', '', [])), 'a same-device rejoin on the finished screen is a reconnect');
check(await fails(stranger, 'join_room', R.code, 'Cy', '', []), 'a finished room takes no one new');

// ---------------------------------------------------------------- rematch

await call(arena, 'rematch', R.id);
r = await room(R.id);
const after = await sql(null, `SELECT * FROM player WHERE room_id = ${R.id}`);
check(r.phase === 'dealing' && r.round_no === 1, 'rematch: straight back to dealing');
check(after.length === 2 && after.every(p => p.total === 0), 'rematch keeps the poets, clears the scores');
check((await sql(null, `SELECT * FROM turn WHERE room_id = ${R.id}`)).length === 0, 'rematch clears the turns');
check(after.find(p => p.id === A.id).epithet === 'Iron-Hearted', 'rematch keeps epithets');

// ---------------------------------------------------------------- discus

// 2 throws each. The poetry settings are ignored for discus but kept for set_event.
await call(arena, 'create_room', 'discus', 2, 2, 2, 120, 'four_beat', false, false, false);
const D = (await sql(null, 'SELECT * FROM room'))
  .filter(x => x.host[0] === `0x${arena.hex}`)
  .sort((a, b) => b.id - a.id)[0];
check(D.event === 'discus' && D.auto_ready && D.turn_seconds === 30, 'discus room: auto-ready, 30 s in the circle');
await call(ada, 'join_room', D.code, 'Ada', 'Iron-Hearted', []);
await call(bo, 'join_room', D.code, 'Bo', '', []);
const dPlayers = await sql(null, `SELECT * FROM player WHERE room_id = ${D.id}`);
const DA = dPlayers.find(p => p.name === 'Ada');
const DB = dPlayers.find(p => p.name === 'Bo');
check((await sql(ada, 'SELECT * FROM hand')).some(h => h.player_id === DA.id && h.kind === ''), 'a discus hand is empty');

await call(arena, 'start_battle', D.id);
r = await room(D.id);
T = await turn(r.current_turn_id);
check(r.phase === 'ready' && r.round_no === 1 && T.player_id === DA.id, 'discus skips dealing: Ada is up');
const throwOf = async turnId => (await sql(null, `SELECT * FROM discus_throw WHERE turn_id = ${turnId}`))[0];
const totalOf = async id => (await sql(null, `SELECT * FROM player WHERE id = ${id}`))[0].total;

check(await fails(ada, 'throw_discus', T.id, 12, 30, 0.95, 32.2, false), 'no throw before the turn starts');
await call(arena, 'start_turn', T.id);
T = await turn(T.id);
check(T.status === 'speaking' && T.ends_at[0] - T.started_at[0] === 30_000_000, 'Ada is in the circle for 30 s');
await call(ada, 'set_prosody', D.id, 0.6, 0, 1);
check((await sql(null, `SELECT * FROM prosody WHERE room_id = ${D.id}`))[0].hits === 1, 'the wind-up streams as prosody');
check(await fails(ada, 'end_turn', T.id, 'words'), 'a discus turn cannot end with words');
check(await fails(bo, 'throw_discus', T.id, 12, 30, 0.95, 32.2, false), 'Bo cannot throw on Ada\'s turn');
check(await fails(ada, 'throw_discus', T.id, 12, 30, 1.5, 32.2, false), 'timing above 1 is refused');
check(await fails(ada, 'throw_discus', T.id, 12, 30, 0.95, 150, false), 'distance above 100 m is refused');
await call(ada, 'throw_discus', T.id, 12, 30, 0.95, 32.2, false);
const th1 = await throwOf(T.id);
check(th1 && Math.abs(th1.distance - 32.2) < 1e-4 && th1.throw_no === 1, 'Ada throws 32.2 m');
check((await room(D.id)).phase === 'scored' && (await totalOf(DA.id)) === 322, 'scored; total is the best in tenths');
check(await fails(ada, 'throw_discus', T.id, 12, 30, 0.95, 40, false), 'one throw per turn');

await call(arena, 'advance', D.id);
T = await turn((await room(D.id)).current_turn_id);
await call(arena, 'start_turn', T.id);
await call(bo, 'throw_discus', T.id, 14, 37, 0.5, 41.4, true);
check((await throwOf(T.id)).distance === 0 && (await totalOf(DB.id)) === 0, 'a foul lands at 0 m');

await call(arena, 'advance', D.id);
r = await room(D.id);
T = await turn(r.current_turn_id);
check(r.phase === 'ready' && r.round_no === 2 && T.player_id === DB.id, 'no verdict: throw 2 starts, Bo first');
await call(arena, 'start_turn', T.id);
check(await fails(bo, 'throw_discus_full', T.id, 14, 37, 0.97, 41.4, false, 24.1, 6, 9.5, 'wobble'), 'throw_discus_full refuses an unknown foul reason');
await call(bo, 'throw_discus_full', T.id, 14, 37, 0.97, 41.4, false, 24.1, 6, 9.5, '');
check((await totalOf(DB.id)) === 414, 'Bo\'s best is 41.4 m');
const full = await throwOf(T.id);
check(Math.abs(full.release_speed - 24.1) < 1e-4 && full.roll === 6 && Math.abs(full.spin - 9.5) < 1e-4 && full.foul_reason === '', 'throw_discus_full keeps the release: 24.1 m/s, 6° of roll, 9.5 rad/s of spin');
const v1 = (await sql(null, `SELECT * FROM discus_throw WHERE room_id = ${D.id}`)).find(x => x.throw_no === 1 && x.player_id === DA.id);
check(v1.release_speed === 0 && v1.foul_reason === '', 'a v1 throw reads 0 and empty for the new columns');

await call(arena, 'advance', D.id);
T = await turn((await room(D.id)).current_turn_id);
await call(arena, 'start_turn', T.id);
console.log('     waiting 34 s for the discus timer...');
await sleep(34_000);
T = await turn(T.id);
check(T.status === 'skipped' && (await room(D.id)).phase === 'scored', 'the timer ends a turn with no throw');
check((await totalOf(DA.id)) === 322, 'a missed throw keeps Ada\'s best');

await call(arena, 'advance', D.id);
check((await room(D.id)).phase === 'finale', 'last throw: finale');
check(await fails(arena, 'set_event', D.id, 'poetry', 2), 'set_event waits for the event to finish');
await call(arena, 'advance', D.id);
check((await room(D.id)).phase === 'finished', 'discus finished');
check((await sql(null, `SELECT * FROM discus_throw WHERE room_id = ${D.id}`)).length === 3, 'three throws recorded');

await call(arena, 'rematch', D.id);
r = await room(D.id);
check(r.phase === 'ready' && r.round_no === 1, 'discus rematch: straight to the first throw');
check((await sql(null, `SELECT * FROM discus_throw WHERE room_id = ${D.id}`)).length === 0, 'rematch clears the throws');

// ---------------------------------------------------------------- set_event

// The hall stays open: finish the rematch, then switch the room back to poetry.
for (let i = 0; i < 4; i++) {
  await call(arena, 'skip_turn', (await room(D.id)).current_turn_id);
  await call(arena, 'advance', D.id);
}
await call(arena, 'advance', D.id);
check((await room(D.id)).phase === 'finished', 'rematch finished');
check(await fails(ada, 'set_event', D.id, 'poetry', 2), 'only the arena switches events');
check(await fails(arena, 'set_event', D.id, 'chariots', 2), 'set_event refuses unknown events');
await call(arena, 'set_event', D.id, 'poetry', 2);
r = await room(D.id);
check(r.event === 'poetry' && r.phase === 'lobby' && r.rounds === 2, 'set_event: a poetry lobby');
check(!r.auto_ready && r.turn_seconds === 20, 'set_event restores the poetry timing');
const kept = await sql(null, `SELECT * FROM player WHERE room_id = ${D.id}`);
check(kept.length === 2 && kept.find(p => p.id === DA.id).epithet === 'Iron-Hearted', 'set_event keeps poets and epithets');
check((await sql(ada, 'SELECT * FROM hand')).some(h => h.player_id === DA.id && h.kind === 'formula'), 'hands hold formulas again');
await call(arena, 'start_battle', D.id);
check((await room(D.id)).phase === 'dealing', 'the poetry battle begins in dealing');

// ---------------------------------------------------------------- debate

await call(arena, 'create_room', 'debate', 1, 2, 2, 120, 'four_beat', false, false, false);
const E = (await sql(null, 'SELECT * FROM room'))
  .filter(x => x.host[0] === `0x${arena.hex}`)
  .sort((a, b) => b.id - a.id)[0];
check(E.event === 'debate' && E.turn_seconds === 45 && !E.auto_ready, 'debate room: 45 s turns');
await call(ada, 'join_room', E.code, 'Ada', 'Iron-Hearted', []);
await call(bo, 'join_room', E.code, 'Bo', '', []);
const ePlayers = await sql(null, `SELECT * FROM player WHERE room_id = ${E.id}`);
const EA = ePlayers.find(p => p.name === 'Ada');
const EB = ePlayers.find(p => p.name === 'Bo');
await call(arena, 'start_battle', E.id);
await call(agent, 'deal_round', E.id, 1, 'Is courage knowledge?', [
  [EA.id, ['define your terms', 'counterexample', 'analogy']],
  [EB.id, ['define your terms', 'concede and turn']],
]);
const eHand = (await sql(ada, 'SELECT * FROM hand')).find(h => h.player_id === EA.id);
check(eHand.kind === 'move' && eHand.cards.length === 3, 'a debate hand holds move cards');
T = await turn((await room(E.id)).current_turn_id);
await call(ada, 'start_turn', T.id);
T = await turn(T.id);
check(T.beat_at[0] - T.started_at[0] === 3_000_000 && T.ends_at[0] - T.beat_at[0] === 45_000_000, 'a three-count, then 45 s');
await call(ada, 'end_turn', T.id, 'Courage is knowing what to fear.');
check(await fails(agent, 'post_score', T.id, [5, 5, 5, 5], 'x', 'y', ''), 'debate scores need five axes');
await call(agent, 'post_score', T.id, [7, 6, 5, 6, 8], 'Sharp.', 'Courage is knowing what to fear.', '');
check((await room(E.id)).phase === 'scored', 'the debate turn is scored');
check((await sql(null, `SELECT * FROM player WHERE id = ${EA.id}`))[0].total === 32, 'a debate total is the plain sum of its axes');

// ---------------------------------------------------------------- coach

// Judge mode: Homer replies to each turn; the conversation runs until the host ends it.
await call(arena, 'create_room', 'coach', 3, 2, 2, 80, 'four_beat', false, false, false);
const C = (await sql(null, 'SELECT * FROM room'))
  .filter(x => x.host[0] === `0x${arena.hex}`)
  .sort((a, b) => b.id - a.id)[0];
check(C.event === 'coach' && C.auto_ready && C.turn_seconds === 20 && C.rounds === 1, 'coach room: auto-ready, 20 s turns, one conversation');
await call(ada, 'join_room', C.code, 'Ada', 'Iron-Hearted', []);
await call(bo, 'join_room', C.code, 'Bo', '', []);
const cPlayers = await sql(null, `SELECT * FROM player WHERE room_id = ${C.id}`);
const CA = cPlayers.find(p => p.name === 'Ada');
const CB = cPlayers.find(p => p.name === 'Bo');
check((await sql(ada, 'SELECT * FROM hand')).some(h => h.player_id === CA.id && h.kind === ''), 'a coach hand holds nothing');
await call(arena, 'start_battle', C.id);
check((await room(C.id)).phase === 'dealing', 'coach begins in dealing, for the theme');
await call(agent, 'deal_round', C.id, 1, 'The wine-dark sea', []);
r = await room(C.id);
T = await turn(r.current_turn_id);
check(r.phase === 'ready' && T.player_id === CA.id && T.turn_no === 0, 'dealt with no hands: Ada is up');
await call(arena, 'start_turn', T.id);
T = await turn(T.id);
check(T.beat_at[0] - T.started_at[0] === 2_250_000 && T.ends_at[0] - T.beat_at[0] === 20_000_000, 'a coach turn is free verse: 3-2-1, then 20 s');
await call(ada, 'end_turn', T.id, 'The sea took the ship.');
check(await fails(agent, 'post_score', T.id, [5, 5, 5, 5, 5], 'x', '', ''), 'coach takes no axes');
const reply = 'Strong opening; now make the sea do something. '.repeat(11).trim(); // ~520 chars
await call(agent, 'post_score', T.id, [], reply, '', '');
const cScore = (await sql(null, `SELECT * FROM score WHERE turn_id = ${T.id}`))[0];
check(cScore.total === 0 && cScore.verdict.length > 300 && (await room(C.id)).phase === 'scored', "Homer's reply is kept whole (up to 600 chars), total 0");
const firstRound = T.round_id;
const order = [CA.id];
for (let i = 0; i < 3; i++) {
  await call(arena, 'advance', C.id);
  r = await room(C.id);
  T = await turn(r.current_turn_id);
  order.push(T.player_id);
  check(r.phase === 'ready' && T.round_id === firstRound && T.turn_no === i + 1 && r.round_no === 1, `coach turn ${i + 1}: the same round, turn_no ${i + 1}`);
  await call(arena, 'skip_turn', T.id);
}
check(JSON.stringify(order) === JSON.stringify([CA.id, CB.id, CA.id, CB.id]), 'two poets take turns, Ada, Bo, Ada, Bo: no round_end, no rotation');
await call(arena, 'advance', C.id);
T = await turn((await room(C.id)).current_turn_id);
await call(arena, 'start_turn', T.id);
check(await fails(ada, 'end_battle', C.id), 'only the host ends a conversation');
await call(arena, 'end_battle', C.id);
check((await room(C.id)).phase === 'finished' && (await turn(T.id)).status === 'skipped', 'end_battle: finished, and the live turn is skipped');
check(await fails(ada, 'end_turn', T.id, 'too late'), 'a late end_turn is refused');
check(await fails(arena, 'end_battle', C.id), 'a finished conversation cannot be ended again');
check((await sql(null, `SELECT * FROM turn WHERE room_id = ${C.id}`)).length === 6 && (await sql(null, `SELECT * FROM score WHERE room_id = ${C.id}`)).length === 1, 'the conversation (3 cycles, 6 turns) stays until a rematch');
await call(arena, 'rematch', C.id);
check((await room(C.id)).phase === 'dealing' && (await sql(null, `SELECT * FROM turn WHERE room_id = ${C.id}`)).length === 0, 'rematch: a fresh conversation');

// Solo: one poet, the same poet every turn.
await call(arena, 'create_room', 'coach', 1, 2, 2, 80, 'four_beat', true, false, true);
const S = (await sql(null, 'SELECT * FROM room'))
  .filter(x => x.host[0] === `0x${arena.hex}`)
  .sort((a, b) => b.id - a.id)[0];
await call(ada, 'join_room', S.code, 'Ada', '', []);
await call(arena, 'start_battle', S.id);
await call(agent, 'deal_round', S.id, 1, 'A ship that never came home', [[(await sql(null, `SELECT * FROM player WHERE room_id = ${S.id}`))[0].id, []]]);
const solo = [];
for (let i = 0; i < 3; i++) {
  T = await turn((await room(S.id)).current_turn_id);
  solo.push(T.player_id);
  await call(arena, 'skip_turn', T.id);
  await call(arena, 'advance', S.id);
}
check(solo.length === 3 && new Set(solo).size === 1, 'solo: one poet is enough, and gets every turn');
await call(arena, 'create_room', 'poetry', 1, 2, 2, 80, 'four_beat', true, false, true);
const P1 = (await sql(null, 'SELECT * FROM room'))
  .filter(x => x.host[0] === `0x${arena.hex}`)
  .sort((a, b) => b.id - a.id)[0];
await call(ada, 'join_room', P1.code, 'Ada', '', []);
check(await fails(arena, 'start_battle', P1.id), 'a poetry battle still needs two poets');

// ---------------------------------------------------------------- stadion

// Everyone races at once: phones stream strides, the module places them at 192 m.
await call(arena, 'create_room', 'stadion', 1, 2, 2, 80, 'four_beat', false, false, true);
const St = (await sql(null, 'SELECT * FROM room'))
  .filter(x => x.host[0] === `0x${arena.hex}`)
  .sort((a, b) => b.id - a.id)[0];
check(St.event === 'stadion' && St.auto_ready && St.turn_seconds === 40 && St.rounds === 1, 'stadion room: auto-ready, one heat, a 40 s cap');
await call(ada, 'join_room', St.code, 'Ada', '', []);
await call(bo, 'join_room', St.code, 'Bo', '', []);
const sPlayers = await sql(null, `SELECT * FROM player WHERE room_id = ${St.id}`);
const SA = sPlayers.find(p => p.name === 'Ada');
const SB = sPlayers.find(p => p.name === 'Bo');
const runnerOf = async id => (await sql(null, `SELECT * FROM runner WHERE player_id = ${id}`))[0];
const heatOf = async () => (await sql(null, `SELECT * FROM heat WHERE room_id = ${St.id}`))[0];
check(await fails(arena, 'start_race', St.id), 'no race before the battle begins');
await call(arena, 'start_battle', St.id);
r = await room(St.id);
let ht = await heatOf();
check(r.phase === 'ready' && r.current_turn_id === 0 && ht.heat_no === 1 && ht.go_at[0] === 0
  && (await sql(null, `SELECT * FROM runner WHERE room_id = ${St.id}`)).length === 2, 'stadion skips dealing: two runners on the line, no turns');
await call(ada, 'set_stride', St.id, 10, 50);
check((await runnerOf(SA.id)).distance === 0, 'a stride before the race is ignored, without an error');
check(await fails(ada, 'start_race', St.id), 'only the arena fires the gun');
check(await fails(arena, 'start_race', E.id), 'start_race is for the stadion only');

async function race(label) {
  await call(arena, 'start_race', St.id);
  const h = await heatOf();
  check((await room(St.id)).phase === 'speaking' && h.cap_at[0] - h.go_at[0] === 40_000_000, `${label}: the gun, a 3-2-1, then 40 s at most`);
  await call(ada, 'set_stride', St.id, 10, 30);
  check((await runnerOf(SA.id)).distance === 0, `${label}: no head start during the 3-2-1`);
  await sleep(3500);
  await call(ada, 'set_stride', St.id, 14, 150);
  const early = (await runnerOf(SA.id)).distance;
  check(early > 0 && early <= 25 * 1.5, `${label}: nobody outruns 25 m/s (${early.toFixed(1)} m about 0.5 s after the gun)`);
  console.log('     waiting 8 s for the runners...');
  await sleep(8000);
  await call(ada, 'set_stride', St.id, 14, 195);
  const a = await runnerOf(SA.id);
  check(a.place === 1 && a.distance === 192 && a.time > 7.6 && a.time < 9.5, `${label}: Ada crosses first, in ${a.time.toFixed(2)} s, timed to the line`);
  await call(ada, 'set_stride', St.id, 14, 250);
  check((await runnerOf(SA.id)).time === a.time, `${label}: strides after the line change nothing`);
  await call(bo, 'set_stride', St.id, 8, 100);
  await call(bo, 'set_stride', St.id, 8, 80);
  check((await runnerOf(SB.id)).distance === 100 && (await room(St.id)).phase === 'speaking', `${label}: distance never goes down, and the race runs until all are across`);
}

await race('heat 1');
await call(bo, 'set_stride', St.id, 9, 193);
check((await runnerOf(SB.id)).place === 2 && (await room(St.id)).phase === 'scored', 'Bo crosses second: all across, the results');
let sTotals = await sql(null, `SELECT * FROM player WHERE room_id = ${St.id}`);
check(sTotals.find(p => p.id === SA.id).total === 2 && sTotals.find(p => p.id === SB.id).total === 1, 'points by place: I gets 2, II gets 1');
check((await heatOf()).ended_at[0] > 0, 'the heat records when it ended');
await call(arena, 'advance', St.id);
check((await room(St.id)).phase === 'finale', 'one heat: the finale');
await call(arena, 'advance', St.id);
check((await room(St.id)).phase === 'finished', 'stadion finished');

await call(arena, 'rematch', St.id);
check((await room(St.id)).phase === 'ready' && (await runnerOf(SA.id)).distance === 0 && (await runnerOf(SA.id)).place === 0, 'rematch: back on the line');
await race('rematch');
const capped = await heatOf();
console.log(`     waiting ${Math.round((Number(capped.cap_at[0]) / 1000 - Date.now()) / 1000) + 2} s for the cap...`);
await sleep(Number(capped.cap_at[0]) / 1000 - Date.now() + 2000);
const b = await runnerOf(SB.id);
check((await room(St.id)).phase === 'scored' && b.place === 2 && b.time === 0, 'the cap ends the heat: Bo, still running, is placed II by distance, untimed');
sTotals = await sql(null, `SELECT * FROM player WHERE room_id = ${St.id}`);
check(sTotals.find(p => p.id === SA.id).total === 2 && sTotals.find(p => p.id === SB.id).total === 1, 'the rematch counted from zero');

// ---------------------------------------------------------------- pygmachia

// Boxing: two fighters live; phones send aim, guard and punches, the module resolves them.
await call(arena, 'create_room', 'pygmachia', 1, 2, 2, 80, 'four_beat', false, false, true);
const Bx = (await sql(null, 'SELECT * FROM room'))
  .filter(x => x.host[0] === `0x${arena.hex}`)
  .sort((a, b) => b.id - a.id)[0];
check(Bx.event === 'pygmachia' && Bx.auto_ready && Bx.turn_seconds === 60, 'pygmachia room: auto-ready, 60 s');
await call(ada, 'join_room', Bx.code, 'Ada', '', []);
check(await fails(arena, 'start_battle', Bx.id), 'a fight needs two fighters');
await call(bo, 'join_room', Bx.code, 'Bo', '', []);
const bPlayers = await sql(null, `SELECT * FROM player WHERE room_id = ${Bx.id}`);
const BA = bPlayers.find(p => p.name === 'Ada');
const BB = bPlayers.find(p => p.name === 'Bo');
const fighterOf = async id => (await sql(null, `SELECT * FROM fighter WHERE player_id = ${id}`))[0];
const fightOf = async () => (await sql(null, `SELECT * FROM fight WHERE room_id = ${Bx.id}`))[0];
const punchesIn = async () => sql(null, `SELECT * FROM punch WHERE room_id = ${Bx.id}`);
await call(arena, 'start_battle', Bx.id);
check((await room(Bx.id)).phase === 'ready' && (await fighterOf(BA.id)).health === 100 && (await fighterOf(BB.id)).seat === 1, 'two fighters in their corners at full health');
check(await fails(ada, 'start_fight', Bx.id), 'only the arena rings the bell');
await call(arena, 'start_fight', Bx.id);
const bell = await fightOf();
check((await room(Bx.id)).phase === 'speaking' && bell.ends_at[0] - bell.go_at[0] === 60_000_000, 'the bell: a 3-2-1, then 60 s');
await call(ada, 'throw_punch', Bx.id, 'jab', 1, 0, 0.5);
check((await punchesIn()).length === 0, 'no punching during the 3-2-1');
await call(ada, 'set_fist_aim', Bx.id, 0.2, 2, false);
check((await fighterOf(BA.id)).aim_yaw > 0.19 && (await fighterOf(BA.id)).aim_pitch === 1, 'fist aim streams in, clamped to -1..1');
await sleep(3200);
await call(ada, 'throw_punch', Bx.id, 'jab', 1, 0.1, 0.5);
let hit = (await punchesIn()).at(-1);
check(hit.result === 'landed' && hit.zone === 'head' && hit.damage === 16 && (await fighterOf(BB.id)).health === 84, 'a full-power jab to the head lands for 16');
await call(ada, 'throw_punch', Bx.id, 'jab', 1, 0.1, 0.5);
check((await punchesIn()).length === 1, 'no more than four punches a second');
await sleep(300);
await call(bo, 'set_fist_aim', Bx.id, 0, 0.5, true);
await call(ada, 'throw_punch', Bx.id, 'jab', 0.5, 0, 0.6);
hit = (await punchesIn()).at(-1);
const bb = await fighterOf(BB.id);
check(hit.result === 'blocked' && hit.damage === 0 && bb.health === 84 && bb.counter_until[0] > 0, "a head punch into Bo's guard is blocked, opening his counter window");
await call(bo, 'throw_punch', Bx.id, 'jab', 1, 0, 0.2);
hit = (await punchesIn()).at(-1);
check(hit.result === 'landed' && hit.counter && hit.damage === 24 && (await fighterOf(BA.id)).health === 76 && !(await fighterOf(BB.id)).guard, 'his counter lands half again (24), and punching dropped his guard');
await call(bo, 'set_fist_aim', Bx.id, 0, 0.5, true);
await sleep(300);
await call(ada, 'throw_punch', Bx.id, 'jab', 0, 0, -0.5);
hit = (await punchesIn()).at(-1);
check(hit.result === 'landed' && hit.zone === 'body' && hit.damage === 4, 'the guard covers the head only: a body shot gets through');
await sleep(300);
await call(ada, 'throw_punch', Bx.id, 'jab', 1, 0.9, 0.5);
hit = (await punchesIn()).at(-1);
check(hit.result === 'missed' && hit.damage === 0, 'a punch aimed wide misses');
await call(bo, 'set_fist_aim', Bx.id, 0, 0.5, false);
for (let i = 0; i < 8 && (await room(Bx.id)).phase === 'speaking'; i++) {
  await sleep(270);
  await call(ada, 'throw_punch', Bx.id, 'jab', 1, 0, 0.5);
}
const ko = await fightOf();
check((await room(Bx.id)).phase === 'scored' && ko.ko && ko.winner_id === BA.id && (await fighterOf(BB.id)).health === 0, 'Bo goes down: a knockout, Ada wins');
check((await sql(null, `SELECT * FROM player WHERE id = ${BA.id}`))[0].total === 1, "the winner's total goes up by one");
const afterKo = (await punchesIn()).length;
await sleep(300);
await call(ada, 'throw_punch', Bx.id, 'jab', 1, 0, 0.5);
check((await punchesIn()).length === afterKo, 'no punches after the knockout');
await call(arena, 'advance', Bx.id);
check((await room(Bx.id)).phase === 'finale', 'one bout: the finale');
await call(arena, 'rematch', Bx.id);
check((await room(Bx.id)).phase === 'ready' && (await fighterOf(BB.id)).health === 100 && (await punchesIn()).length === 0, 'rematch: back in the corners, healed');

console.log(failures === 0 ? '\nall checks passed' : `\n${failures} check(s) failed`);
process.exit(failures === 0 ? 0 : 1);
