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
const TABLES = ['room', 'player', 'turn', 'round', 'score', 'discus_throw', 'song_line', 'fight', 'fighter', 'punch', 'heat', 'runner'];
// Newer events' tables, subscribed on their own: a database that doesn't have them yet still
// gets watched for everything else.
const OPTIONAL = ['range', 'archer', 'arrow_shot'];

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
// The live bout per room (aim update times per fighter, the punches) and the heat's strides.
type Bout = { go: number; aims: Map<bigint, number[]>; punches: { playerId: bigint; result: string; damage: number; counter: boolean; lat: number }[] };
const bouts = new Map<bigint, Bout>();
const strides = new Map<bigint, Map<bigint, number[]>>();
// The arrow on the string per room: when it went up, and the bow's aim and the arrow's draw updates.
const arrows = new Map<bigint, { up: number; aims: number[]; draws: number[] }>();
const rate = (ts: number[]) => {
  const span = ts.length > 1 ? (ts[ts.length - 1] - ts[0]) / 1000 : 0;
  let gap = 0;
  for (let i = 1; i < ts.length; i++) gap = Math.max(gap, ts[i] - ts[i - 1]);
  return `${span ? (ts.length / span).toFixed(1) : '0'} Hz (longest gap ${gap} ms)`;
};

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
        const late = Date.now() - micros(a.endsAt); // a retry resets ends_at to the epoch
        // The timer fires 2 s (GRACE_MICROS) past ends_at; anything sooner was the phone.
        why = late >= 1800 ? `, closed by the timer (${secs(late)} after ends_at)`
          : late >= 0 ? `, ended by the phone ${secs(late)} after ends_at` : `, ended ${secs(-late)} early`;
        if (b.transcript) why += `, ${b.transcript.split(/\s+/).filter(Boolean).length} words`;
      }
      if (b.status === 'judging') judgingAt.set(b.id, Date.now());
      if (b.status === 'waiting') upAt.set(b.id, Date.now()); // a silent first attempt gets a retry
      say(`${c} ${name}'s turn ${a.status} -> ${b.status}${b.attempt > 1 ? ` (attempt ${b.attempt})` : ''}${why}`);
    }
    if (!a.transcript && b.transcript) milestone(b.roomId, 'words');
    if (a.transcript !== b.transcript && b.transcript) {
      // Every live transcript update, timed from the downbeat: is STT streaming, and how late?
      const words = (s: string) => s.split(/\s+/).filter(Boolean).length;
      const since = Date.now() - micros(b.beatAt);
      say(`${c} ${name} words ${words(a.transcript)} -> ${words(b.transcript)}, ${secs(since)} after the downbeat${b.status !== 'speaking' ? ` (${b.status})` : ''}`);
    }
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
  // Pygmachia: every punch with its push latency (server `at` to this screen), the bell, and
  // a per-fighter summary when the bout ends: the aim stream's rate and longest gap, punches
  // a minute, and what they did. Aim rows update at ~20 Hz, so they're counted, not logged.
  conn.db.fight.onUpdate((_c, a, b) => {
    const c = code(b.roomId);
    if (micros(b.goAt) && !micros(a.goAt)) {
      bouts.set(b.roomId, { go: micros(b.goAt), aims: new Map(), punches: [] });
      say(`${c} the bell: bout ${roomOf(b.roomId)?.roundNo ?? '?'}, ${secs(micros(b.endsAt) - micros(b.goAt))} from go`);
    }
    // The knockout punch arrives in the same transaction as the end: summarize once it's in.
    if (micros(b.endedAt) && !micros(a.endedAt)) setTimeout(() => {
      const how = b.ko ? 'by knockout' : b.winnerId ? 'on health at the bell' : 'a draw at the bell';
      say(`${c} bout over ${secs(micros(b.endedAt) - micros(b.goAt))} after the bell: ${b.winnerId ? poet(b.winnerId) + ' wins ' : ''}${how}`);
      const bout = bouts.get(b.roomId);
      if (bout) for (const f of all('fighter').filter(x => x.roomId === b.roomId)) {
        const aims = bout.aims.get(f.playerId) ?? [];
        const span = aims.length > 1 ? (aims[aims.length - 1] - aims[0]) / 1000 : 0;
        let gap = 0;
        for (let i = 1; i < aims.length; i++) gap = Math.max(gap, aims[i] - aims[i - 1]);
        const mine = bout.punches.filter(x => x.playerId === f.playerId);
        const n = (r: string) => mine.filter(x => x.result === r).length;
        const minutes = (micros(b.endedAt) - micros(b.goAt)) / 60000;
        const lat = mine.map(x => x.lat).sort((x, y) => x - y);
        say(`${c}   ${poet(f.playerId)}: aim ${span ? (aims.length / span).toFixed(1) : '0'} Hz (longest gap ${gap} ms), ` +
          `${mine.length} punches (${minutes > 0 ? Math.round(mine.length / minutes) : 0}/min): ${n('landed')} landed, ${n('blocked')} blocked, ${n('missed')} missed, ` +
          `${mine.filter(x => x.counter).length} counters, ${Math.round(mine.reduce((t, x) => t + x.damage, 0))} damage; health ${Math.round(f.health)}, stamina ${Math.round(f.stamina)}` +
          `${lat.length ? `; push ${lat[Math.floor(lat.length / 2)]} ms median, ${lat[lat.length - 1]} max` : ''}`);
      }
    }, 0);
  });
  conn.db.fighter.onUpdate((_c, a, b) => {
    const bout = bouts.get(b.roomId);
    if (!bout || (a.aimYaw === b.aimYaw && a.aimPitch === b.aimPitch && a.guard === b.guard)) return;
    const list = bout.aims.get(b.playerId) ?? [];
    list.push(Date.now());
    bout.aims.set(b.playerId, list);
    if (a.guard !== b.guard) say(`${code(b.roomId)} ${poet(b.playerId)} guard ${b.guard ? 'up' : 'down'}`);
  });
  conn.db.punch.onInsert((_c, p) => {
    if (!live) return;
    const lat = Date.now() - micros(p.at);
    bouts.get(p.roomId)?.punches.push({ playerId: p.playerId, result: p.result, damage: p.damage, counter: p.counter, lat });
    say(`${code(p.roomId)} ${poet(p.playerId)} ${p.kind || 'punch'} at the ${p.zone} (power ${p.power.toFixed(2)}): ${p.result}` +
      `${p.damage ? `, ${p.damage.toFixed(1)} damage` : ''}${p.combo > 1 ? `, combo ${p.combo}` : ''}${p.counter ? ', a COUNTER' : ''}; pushed in ${lat} ms`);
  });

  // The Stadion: the gun, each runner over the line, and the stride stream's rate per runner.
  conn.db.heat.onUpdate((_c, a, b) => {
    const c = code(b.roomId);
    if (micros(b.goAt) && !micros(a.goAt)) {
      strides.set(b.roomId, new Map());
      say(`${c} the gun: heat ${b.heatNo}, go in ${secs(micros(b.goAt) - Date.now())}`);
    }
    if (micros(b.endedAt) && !micros(a.endedAt)) {
      say(`${c} heat ${b.heatNo} over ${secs(micros(b.endedAt) - micros(b.goAt))} after the gun`);
      for (const [id, ts] of strides.get(b.roomId) ?? []) {
        const span = ts.length > 1 ? (ts[ts.length - 1] - ts[0]) / 1000 : 0;
        say(`${c}   ${poet(id)}: strides ${span ? (ts.length / span).toFixed(1) : '0'} Hz over ${span.toFixed(1)} s`);
      }
    }
  });
  conn.db.runner.onUpdate((_c, a, b) => {
    const m = strides.get(b.roomId);
    if (m && a.distance !== b.distance) m.set(b.playerId, [...(m.get(b.playerId) ?? []), Date.now()]);
    if (!a.place && b.place) say(`${code(b.roomId)} ${poet(b.playerId)} ${b.time > 0 ? `crosses in ${b.time.toFixed(2)} s` : `stops at ${Math.round(b.distance)} m`}: place ${b.place}`);
  });

  // Toxeia: the stations, each archer and arrow (its wind), the aim and draw streams' rates
  // per arrow, and where it landed, with the loose's push latency.
  const archerName = (id: bigint) => all('archer').find(a => a.id === id)?.name ?? `archer ${id}`;
  conn.db.range.onUpdate((_c, a, b) => {
    const c = code(b.roomId);
    if (a.bowId !== b.bowId || a.arrowId !== b.arrowId) {
      say(`${c} stations: bow ${b.bowId ? poet(b.bowId) : '-'}, arrow ${b.arrowId ? poet(b.arrowId) : '-'}`);
    }
    if (b.archerId && (a.archerId !== b.archerId || a.arrowNo !== b.arrowNo)) {
      arrows.set(b.roomId, { up: Date.now(), aims: [], draws: [] });
      say(`${c} ${archerName(b.archerId)}, arrow ${b.arrowNo}: wind ${b.wind >= 0 ? '→' : '←'} ${Math.abs(b.wind).toFixed(1)} m/s`);
      return;
    }
    const m = arrows.get(b.roomId);
    if (m && (a.aimYaw !== b.aimYaw || a.aimPitch !== b.aimPitch)) m.aims.push(Date.now());
    if (m && a.draw !== b.draw) m.draws.push(Date.now());
  });
  conn.db.archer.onInsert((_c, x) => {
    if (live) say(`${code(x.roomId)} next archer: ${x.name}`);
  });
  conn.db.arrowShot.onInsert((_c, x) => {
    if (!live) return;
    const c = code(x.roomId);
    const m = arrows.get(x.roomId);
    arrows.delete(x.roomId);
    const total = all('archer').find(a => a.id === x.archerId)?.total ?? 0;
    if (x.flight === 0) say(`${c}   time ran out: arrow ${x.arrowNo} lost`);
    else say(`${c}   loosed at draw ${x.draw.toFixed(2)}: ring ${x.ring} at (${x.x.toFixed(2)}, ${x.y.toFixed(2)}) m, ${x.flight.toFixed(2)} s in the air; pushed in ${Date.now() - micros(x.at)} ms`);
    if (m) say(`${c}   ${secs(micros(x.at) - m.up)} on the string; bow aim ${rate(m.aims)}, draw ${rate(m.draws)}; ${archerName(x.archerId)} has ${total}`);
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
      c.subscriptionBuilder()
        .onError(() => say(`no ${OPTIONAL.join('/')} tables on ${DBN} yet; watching the rest`))
        .subscribe(OPTIONAL.map(t => `SELECT * FROM ${t}`));
    })
    .onConnectError((_c, e) => retry(`connect failed: ${e.message}`, 3000))
    .onDisconnect(() => retry('watcher lost its connection', 2000))
    .build();
  conn = c;
  wire();
}

connect();
