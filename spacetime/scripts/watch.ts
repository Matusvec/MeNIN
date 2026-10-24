// Watches a database read-only and prints a timeline, one line per change: rooms and
// phases, joins, connects and disconnects, turns, deals, scores, throws, verdicts, songs.
// Times every reset (start_battle, rematch, set_event) to the first turn ready, the
// first turn started and the first words. Lines starting `!!` are worth a look.
//
//   npm run watch                    # Maincloud, database "homer-calhacks"
//   STDB_URL=http://127.0.0.1:3000 STDB_DB=homer-test npm run watch
//
// An anonymous subscriber: it never calls a reducer.

import { DbConnection } from './bindings/index';

const URI = (process.env.STDB_URL ?? 'http://127.0.0.1:3000').replace(/^http/, 'ws');
const DBN = process.env.STDB_DB ?? 'homer';
const TABLES = ['room', 'player', 'turn', 'round', 'score', 'discus_throw', 'song_line'];

const clock = () => new Date().toLocaleTimeString('en-US', { hour12: false }) + '.' + String(Date.now() % 1000).padStart(3, '0');
const say = (line: string) => console.log(`${clock()} ${line}`);
const secs = (ms: number) => `${(ms / 1000).toFixed(1)} s`;
const micros = (ts: any) => Number(ts.microsSinceUnixEpoch / 1000n);

let conn: DbConnection;
let live = false;
const all = (t: string) => [...((conn.db as any)[t].iter() as Iterable<any>)];
const roomOf = (id: bigint) => all('room').find(r => r.id === id);
const code = (roomId: bigint) => roomOf(roomId)?.code ?? `room ${roomId}`;
const poet = (id: bigint) => all('player').find(p => p.id === id)?.name ?? `poet ${id}`;
const turnOf = (id: bigint) => all('turn').find(t => t.id === id);

// Per room: when the last reset began, and which milestones have been logged since.
const resets = new Map<bigint, { kind: string; at: number; ready?: boolean; started?: boolean; words?: boolean }>();
// Per turn: when it became the current turn and when it went to the judge.
const upAt = new Map<bigint, number>();
const judgingAt = new Map<bigint, number>();
// Turns deleted in the transaction being applied, per room (a reset clears them).
const cleared = new Map<bigint, number>();

function milestone(roomId: bigint, step: 'ready' | 'started' | 'words') {
  const r = resets.get(roomId);
  if (!r || r[step]) return;
  r[step] = true;
  const label = { ready: 'first turn ready', started: 'first turn started', words: 'first words' }[step];
  say(`${code(roomId)}   ${r.kind} -> ${label} in ${secs(Date.now() - r.at)}`);
}

function wire() {
  conn.db.room.onInsert((_c, r) => {
    if (live) say(`${r.code} created: ${r.event}${r.demo ? ' demo' : ''}, ${r.rounds} round(s), ${r.turnSeconds} s turns, auto-ready ${r.autoReady}`);
  });
  // A reset deletes the old turns in the same transaction; read the count once all of
  // its rows have been applied.
  conn.db.room.onUpdate((_c, a, b) => queueMicrotask(() => {
    const n = cleared.get(b.id) ?? 0;
    cleared.delete(b.id);
    if (a.event !== b.event) {
      say(`${b.code} set_event ${a.event} -> ${b.event}: ${b.rounds} round(s), ${b.turnSeconds} s turns`);
    }
    if (a.phase !== b.phase) {
      const who = b.currentTurnId ? ` (${poet(turnOf(b.currentTurnId)?.playerId ?? 0n)} up)` : '';
      say(`${b.code} phase ${a.phase} -> ${b.phase}, round ${b.roundNo}${who}${n ? `, ${n} old turn(s) cleared` : ''}`);
      if (b.phase === 'lobby') resets.delete(b.id);
      else if (a.phase === 'lobby') resets.set(b.id, { kind: 'start_battle', at: Date.now() });
      else if (n > 0 || a.phase === 'finished') resets.set(b.id, { kind: 'rematch', at: Date.now() });
    }
    if (a.currentTurnId !== b.currentTurnId && b.currentTurnId) upAt.set(b.currentTurnId, Date.now());
    if (b.phase === 'ready' && b.roundNo === 1) milestone(b.id, 'ready');
  }));
  conn.db.player.onInsert((_c, p) => {
    if (live) say(`${code(p.roomId)} joined: ${p.name}${p.epithet ? `, ${p.epithet}` : ''} (seat ${p.seat})`);
  });
  conn.db.player.onUpdate((_c, a, b) => {
    const c = code(b.roomId);
    if (a.connected !== b.connected) {
      const r = roomOf(b.roomId);
      const t = r?.currentTurnId ? turnOf(r.currentTurnId) : undefined;
      const theirs = t && t.playerId === b.id && ['waiting', 'speaking'].includes(t.status);
      say(`${theirs && !b.connected ? '!! ' : ''}${c} ${b.name} ${b.connected ? 'connected' : 'disconnected'}${theirs ? ` during their ${t.status} turn` : ''}`);
    }
    if (!a.identity.isEqual(b.identity)) say(`${c} ${b.name}'s seat moved to a new device`);
    if (a.name !== b.name || a.epithet !== b.epithet) say(`${c} named: ${b.name}, ${b.epithet}`);
    if (a.entered !== b.entered && b.entered) say(`${c} ${b.name} entered`);
    if (a.total !== b.total && b.total !== 0) say(`${c} ${b.name} total ${a.total} -> ${b.total}`);
  });
  conn.db.player.onDelete((_c, p) => say(`${code(p.roomId)} left: ${p.name}`));
  conn.db.turn.onDelete((_c, t) => cleared.set(t.roomId, (cleared.get(t.roomId) ?? 0) + 1));
  conn.db.turn.onUpdate((_c, a, b) => {
    const c = code(b.roomId);
    const name = poet(b.playerId);
    if (a.status !== b.status) {
      let why = '';
      if (b.status === 'speaking') {
        const up = upAt.get(b.id);
        why = `${up ? `, started ${secs(Date.now() - up)} after being called up` : ''}, window ${secs(micros(b.endsAt) - micros(b.startedAt))}`;
        if (up && Date.now() - up > 10_000) why += ' !! slow start';
        milestone(b.roomId, 'started');
      } else if (a.status === 'speaking') {
        const late = Date.now() - micros(b.endsAt);
        why = late >= 1000 ? `, closed by the timer (${secs(late)} after ends_at)` : `, ended ${secs(-late)} early`;
        if (b.transcript) why += `, ${b.transcript.split(/\s+/).filter(Boolean).length} words`;
      }
      if (b.status === 'judging') judgingAt.set(b.id, Date.now());
      if (b.status === 'waiting') upAt.set(b.id, Date.now()); // a silent first attempt gets a retry
      say(`${c} ${name}'s turn ${a.status} -> ${b.status}${b.attempt > 1 ? ` (attempt ${b.attempt})` : ''}${why}`);
    }
    if (!a.transcript && b.transcript) milestone(b.roomId, 'words');
    if (a.played.length !== b.played.length) say(`${c} ${name} played "${b.played[b.played.length - 1]}"`);
    if (a.rescues !== b.rescues) say(`${c} ${name} rescued (${b.rescues})`);
  });
  conn.db.round.onInsert((_c, r) => {
    if (live) say(`${code(r.roomId)} dealt round ${r.roundNo}: "${r.theme}"`);
  });
  conn.db.round.onUpdate((_c, a, b) => {
    if (!a.verdict && b.verdict) say(`${code(b.roomId)} verdict for round ${b.roundNo}, best line "${b.bestLine}"`);
  });
  conn.db.score.onInsert((_c, s) => {
    if (!live) return;
    const j = judgingAt.get(s.turnId);
    say(`${code(s.roomId)} scored ${poet(s.playerId)}: ${s.total} [${s.axes}]${j ? `, judged in ${secs(Date.now() - j)}` : ''}`);
  });
  conn.db.discusThrow.onInsert((_c, d) => {
    if (live) say(`${code(d.roomId)} ${poet(d.playerId)} threw ${d.foul ? 'a foul' : `${d.distance.toFixed(1)} m`} (speed ${d.speed.toFixed(1)}, angle ${d.angle.toFixed(0)}, timing ${d.timing.toFixed(2)})`);
  });
  let songTimer: ReturnType<typeof setTimeout> | undefined;
  let songLines = 0;
  conn.db.songLine.onInsert((_c, l) => {
    if (!live) return;
    songLines++;
    clearTimeout(songTimer);
    songTimer = setTimeout(() => (say(`${code(l.roomId)} song posted: ${songLines} line(s)`), (songLines = 0)), 200);
  });
}

let attempt = 0;
function connect() {
  const mine = ++attempt;
  live = false;
  // Only the newest connection may start another; a retired one's callbacks are ignored.
  const retry = (why: string, ms: number) => {
    if (mine !== attempt) return;
    attempt++;
    clearTimeout(watchdog);
    say(`!! ${why}; reconnecting in ${ms / 1000} s (changes in the gap are not logged)`);
    setTimeout(connect, ms);
  };
  // A connect that hangs never reports an error: start over if nothing arrives in 15 s.
  const watchdog = setTimeout(() => {
    retry('no subscription after 15 s', 1000);
    c.disconnect();
  }, 15_000);
  const c = DbConnection.builder()
    .withUri(URI)
    .withDatabaseName(DBN)
    .onConnect(c => {
      if (mine !== attempt) return c.disconnect(); // retired by the watchdog while it hung
      c.subscriptionBuilder()
        .onApplied(() => {
          clearTimeout(watchdog);
          const open = all('room').filter(r => r.phase !== 'finished');
          say(`watching ${DBN}: ${all('room').length} rooms (${open.map(r => `${r.code} ${r.event} ${r.phase}`).join(', ') || 'none open'}), ${all('player').filter(p => p.connected).length} poets connected`);
          // The snapshot's own insert callbacks run after onApplied; skip them.
          setTimeout(() => (live = true), 500);
        })
        .subscribe(TABLES.map(t => `SELECT * FROM ${t}`));
    })
    .onConnectError((_c, e) => retry(`connect failed: ${e.message}`, 3000))
    .onDisconnect(() => retry('watcher lost its connection', 2000))
    .build();
  conn = c;
  wire();
}

connect();
