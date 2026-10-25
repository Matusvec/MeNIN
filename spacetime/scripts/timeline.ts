// A camera-ready live timeline of one battle, for the video's "how it works" split screen:
// one event per line, a millisecond timestamp, the reducer that caused it in its caller's
// colour (phone, Homer's agent, the arena, the server's timer), and plain words. No ids, no
// identities: names and the hall's join code only. Read-only and anonymous, like watch.ts.
//
//   npm run -s timeline                     # homer-calhacks; follows the newest hall
//   ROOM=ABCD npm run -s timeline           # one hall
//   STDB_URL=http://127.0.0.1:3000 STDB_DB=homer-test npm run -s timeline
//
// Lines are cut to the terminal's width, so nothing wraps; about 60 columns shows them whole.

import { setGlobalLogLevel } from 'spacetimedb';
import { DbConnection } from './bindings/index';

setGlobalLogLevel('warn'); // no SDK chatter on the recording

const URI = (process.env.STDB_URL ?? 'https://maincloud.spacetimedb.com').replace(/^http/, 'ws');
const DBN = process.env.STDB_DB ?? 'homer-calhacks';
const ROOM = (process.env.ROOM ?? '').trim().toUpperCase();

// Who calls each reducer, by colour.
const PHONE = 36, AGENT = 35, ARENA = 33, TIMER = 34;
const CALLER: Record<string, number> = {
  join_room: PHONE, enter: PHONE, update_transcript: PHONE, play_card: PHONE, end_turn: PHONE, throw_discus: PHONE,
  name_poet: AGENT, deal_round: AGENT, set_scene: AGENT, post_score: AGENT, verdict: AGENT,
  post_verdict: AGENT, post_song: AGENT, decline_turn: AGENT,
  create_room: ARENA, start_battle: ARENA, start_turn: ARENA, advance: ARENA, skip_turn: ARENA, end_battle: ARENA,
  turn_timeout: TIMER,
};
// The arena's colour for each emotion (homer/web/src/scene/moods.ts, each mood's middle ink).
const MOOD: Record<string, number> = {
  anger: 0xec4a1c, grief: 0x294c98, joy: 0xffc23a, awe: 0xe8b73a,
  tenderness: 0xb6a2e0, fear: 0x6f8f7f, defiance: 0xae84ff, longing: 0xc0694a,
};
const EMOTIONS = Object.keys(MOOD);

const esc = (code: string) => `\x1b[${code}m`;
const width = () => process.stdout.columns || 64;
const stamp = () => {
  const d = new Date();
  const two = (n: number) => String(n).padStart(2, '0');
  return `${two(d.getMinutes())}:${two(d.getSeconds())}.${String(d.getMilliseconds()).padStart(3, '0')}`;
};
const visible = (s: string) => s.replace(/\x1b\[[0-9;]*m/g, '');
// Cuts a line to the terminal's width, keeping colour codes intact.
function fit(line: string): string {
  const max = width() - 1;
  if (visible(line).length <= max) return line;
  let out = '', seen = 0;
  for (const part of line.split(/(\x1b\[[0-9;]*m)/)) {
    if (part.startsWith('\x1b[')) { out += part; continue; }
    const room = max - 1 - seen;
    if (room <= 0) break;
    out += part.slice(0, room);
    seen += Math.min(part.length, room);
  }
  return out + '…' + esc('0');
}
function say(reducer: string, text: string, swatch = '') {
  const label = reducer.padEnd(17);
  console.log(fit(`${esc('2')}${stamp()}${esc('0')} ${esc(`1;${CALLER[reducer] ?? 37}`)}${label}${esc('0')} ${swatch}${text}`));
}
const quote = (s: string, n: number) => {
  const t = s.replace(/\s+/g, ' ').trim();
  return `“${t.length > n ? t.slice(0, n - 1) + '…' : t}”`;
};
const tail = (s: string, words: number) => {
  const w = s.trim().split(/\s+/);
  return (w.length > words ? '…' : '') + w.slice(-words).join(' ');
};
// The mood's colour as a two-cell block: 24-bit where the terminal says it can (iTerm2 sets
// COLORTERM=truecolor), else the nearest of the 256-colour cube, which Terminal.app renders.
function swatch(hex: number): string {
  const [r, g, b] = [(hex >> 16) & 255, (hex >> 8) & 255, hex & 255];
  if (/truecolor|24bit/.test(process.env.COLORTERM ?? '')) return `${esc(`48;2;${r};${g};${b}`)}  ${esc('0')} `;
  const six = (v: number) => Math.round((v / 255) * 5);
  return `${esc(`48;5;${16 + 36 * six(r) + 6 * six(g) + six(b)}`)}  ${esc('0')} `;
}

let conn: DbConnection;
let roomId = 0n;
const all = (t: string) => [...((conn.db as any)[t].iter() as Iterable<any>)];
const name = (playerId: bigint) => all('player').find(p => p.id === playerId)?.name ?? 'a poet';
const mine = (row: { roomId: bigint }) => roomId !== 0n && row.roomId === roomId;
const shown = new Map<bigint, { at: number; words: number }>(); // the last transcript line per turn
let songLines = 0;
let songTimer: ReturnType<typeof setTimeout> | undefined;
let live = false;

function follow(r: any, why: string) {
  roomId = r.id;
  shown.clear();
  const event = r.event === 'coach' ? 'Talk to Homer' : r.event[0].toUpperCase() + r.event.slice(1);
  console.log('');
  say('create_room', `${why}: ${event} · hall ${r.code}`);
}

function wire() {
  conn.db.room.onInsert((_c, r) => {
    if (live && (!ROOM || r.code === ROOM)) follow(r, 'new hall');
  });
  conn.db.room.onUpdate((_c, a, b) => {
    if (b.id !== roomId || a.phase === b.phase) return;
    const up = b.currentTurnId ? all('turn').find(t => t.id === b.currentTurnId) : undefined;
    if (a.phase === 'lobby' && b.phase !== 'finished') say('start_battle', 'the battle begins');
    else if (a.phase === 'scored' && b.phase === 'ready' && up) say('advance', `next up: ${name(up.playerId)}`);
    else if (b.phase === 'round_end') say('advance', `round ${b.roundNo} ends`);
    else if (a.phase === 'round_end' && (b.phase === 'ready' || b.phase === 'dealing')) say('advance', `round ${b.roundNo}`);
    else if (b.phase === 'finale') say('advance', 'the finale');
    else if (b.phase === 'finished') say('advance', 'finished');
  });
  conn.db.player.onInsert((_c, p) => {
    if (live && mine(p)) say('join_room', `${p.name} joins`);
  });
  conn.db.player.onUpdate((_c, a, b) => {
    if (!mine(b)) return;
    if (!a.entered && b.entered) say('enter', `${b.name} checks in`);
    if (!a.named && b.named && b.epithet) say('name_poet', `${b.name}, ${b.epithet}`);
  });
  conn.db.round.onInsert((_c, r) => {
    if (live && mine(r) && r.theme) say('deal_round', `theme: ${quote(r.theme, 40)}`);
  });
  conn.db.round.onUpdate((_c, a, b) => {
    if (!mine(b)) return;
    if (!a.verdict && b.verdict) say('post_verdict', quote(b.verdict, 44));
    if (!a.bestLine && b.bestLine) say('post_verdict', `carved: ${quote(b.bestLine, 36)}`);
  });
  conn.db.turn.onUpdate((_c, a, b) => {
    if (!mine(b)) return;
    const who = name(b.playerId);
    const discus = all('room').find(r => r.id === b.roomId)?.event === 'discus';
    if (discus) {
      // A thrower's turn: into the circle, then the throw (discus_throw) or none.
      if (a.status !== 'speaking' && b.status === 'speaking') say('start_turn', `${who} steps into the circle`);
      if (a.status === 'speaking' && b.status === 'skipped') say('turn_timeout', `${who} · no throw`);
      return;
    }
    if (a.status !== 'speaking' && b.status === 'speaking') say('start_turn', `${who} · 3-2-1, then speak`);
    if (b.status === 'speaking' && a.transcript !== b.transcript && b.transcript.trim()) {
      const words = b.transcript.trim().split(/\s+/).length;
      const last = shown.get(b.id) ?? { at: 0, words: 0 };
      if (Date.now() - last.at >= 700 && words !== last.words) {
        shown.set(b.id, { at: Date.now(), words });
        say('update_transcript', `${who}: ${tail(b.transcript, 5)}`);
      }
    }
    if (b.played.length > a.played.length) say('play_card', `${who} plays ${quote(b.played[b.played.length - 1], 28)}`);
    if (a.status === 'speaking' && b.status !== 'speaking') {
      const words = b.transcript.trim() ? b.transcript.trim().split(/\s+/).length : 0;
      const late = Date.now() - Number(b.endsAt.microsSinceUnixEpoch / 1000n) > 1500;
      const what = b.status === 'judging' ? `${words} words → Homer` : b.status === 'waiting' ? 'silence: one more try' : 'silence: skipped';
      say(late ? 'turn_timeout' : 'end_turn', `${who} · ${what}`);
    }
    if (a.status === 'judging' && b.status === 'skipped') say('skip_turn', `${who} · no verdict, skipped`);
    if (a.status === 'judging' && b.status === 'declined') say('decline_turn', `${who} · Homer declines`);
  });
  conn.db.score.onInsert((_c, s) => {
    if (!live || !mine(s)) return;
    const who = name(s.playerId);
    const room = all('room').find(r => r.id === s.roomId);
    const of = room?.event === 'debate' ? 50 : 100;
    say('post_score', s.axes.length ? `${who} · ${s.total}/${of}` : `${who} · Homer replies`);
    if (s.verdict) say('verdict', quote(s.verdict, 44));
  });
  conn.db.scene.onUpdate((_c, a, b) => {
    if (!mine(b) || !b.turnId) return;
    const ranked = EMOTIONS.map(e => ({ e, w: Number((b as any)[e]) })).sort((x, y) => y.w - x.w);
    const before = EMOTIONS.map(e => Number((a as any)[e])).join();
    if (before === EMOTIONS.map(e => Number((b as any)[e])).join() || ranked[0].w <= 0) return;
    const second = ranked[1].w > 0.25 ? ` · ${ranked[1].e} ${ranked[1].w.toFixed(2)}` : '';
    say('set_scene', `${ranked[0].e} ${ranked[0].w.toFixed(2)}${second}`, swatch(MOOD[ranked[0].e]));
  });
  conn.db.discusThrow.onInsert((_c, d) => {
    if (live && mine(d)) say('throw_discus', `${name(d.playerId)} · ${d.foul ? 'foul' : `${d.distance.toFixed(1)} m`}`);
  });
  conn.db.songLine.onInsert((_c, l) => {
    if (!live || !mine(l)) return;
    songLines++;
    clearTimeout(songTimer);
    songTimer = setTimeout(() => (say('post_song', `the song: ${songLines} lines`), (songLines = 0)), 300);
  });
}

function legend() {
  const tag = (c: number, s: string) => `${esc(`1;${c}`)}${s}${esc('0')}`;
  console.log(fit(`${esc('2')}SpacetimeDB · ${DBN}${esc('0')}  ${tag(PHONE, 'phone')} ${tag(AGENT, 'Homer')} ${tag(ARENA, 'arena')} ${tag(TIMER, 'timer')}`));
}

let attempt = 0;
function connect(): void {
  const mineAttempt = ++attempt;
  conn = DbConnection.builder()
    .withUri(URI)
    .withDatabaseName(DBN)
    .onConnect(c => {
      if (mineAttempt !== attempt) return c.disconnect();
      c.subscriptionBuilder()
        .onApplied(() => {
          if (!roomId) {
            const rooms = all('room').filter(r => !ROOM || r.code === ROOM);
            const newest = rooms.reduce((top: any, r: any) => (!top || r.id > top.id ? r : top), undefined);
            if (newest) follow(newest, 'watching');
          }
          setTimeout(() => (live = true), 500);
        })
        .subscribe(['room', 'player', 'round', 'turn', 'score', 'scene', 'song_line', 'discus_throw'].map(t => `SELECT * FROM ${t}`));
    })
    .onConnectError(() => setTimeout(connect, 3000))
    .onDisconnect(() => setTimeout(connect, 2000))
    .build();
  wire();
}

legend();
connect();
