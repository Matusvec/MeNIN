// Scripted phones for an arena someone else drives (the web arena, the Mac app): POETS
// poets join a room by code over real websockets, check in, and play every turn they're
// given until the room has finished BATTLES battles (rematches and set_event included).
// A verse is two lines over about 6 s with a card from the hand worked into it; a discus
// throw is a 2 s wind-up and a throw. Pair it with `npm run watch` for the timeline.
//
//   CODE=ABCD npm run phones                       # local server, database "homer-test"
//   CODE=ABCD POETS=2 BATTLES=5 STDB_DB=... npm run phones
//   HOST=<identity hex> NAMES=Bo BATTLES=1 ...     # the newest lobby that arena hosts
//   HOST=<identity hex> NAMES=Bo STAY=1 ...        # a companion: every battle, until left alone
//   CODE=ABCD LAZY=Bo npm run phones               # Stadion: Bo jogs at 4 m/s (hits the cap)
//
// With HOST, it waits for that arena's newest lobby and follows it if the arena opens a
// new room before the battle begins. It leaves the room after the last battle.
// Never calls an arena or agent reducer.

import { DbConnection } from './bindings/index';
import { identity, sql } from './stdb.mjs';

const URI = (process.env.STDB_URL ?? 'http://127.0.0.1:3000').replace(/^http/, 'ws');
const DBN = process.env.STDB_DB ?? 'homer';
const HOST = (process.env.HOST ?? '').trim().toLowerCase().replace(/^0x/, '');
const BATTLES = Number(process.env.BATTLES ?? 5);
const NAMES = process.env.NAMES ? process.env.NAMES.split(',').map(n => n.trim()) : ['Ada', 'Bo', 'Cy', 'Di', 'Eo'];
const POETS = Number(process.env.POETS ?? (process.env.NAMES ? NAMES.length : 2));
const STAY = process.env.STAY === '1';
const IDLE_MS = 120_000;
const VERSES = [
  ['The sea came grey against the hull at dawn', 'and {card} carried what the wind had drawn'],
  ['We pulled the oars until the oars were bone', 'and {card} brought the long ship home alone'],
  ['The fire was low, the hall was full of night', 'but {card} kept the last of it alight'],
  ['I sing the deadline and the men who ran', 'and {card} sang it louder than a man'],
];
const ARGUMENTS = [
  'Let me {card}: courage is not the absence of fear but knowing which fears are worth it.',
  'I will {card}: a soldier who stands because he cannot run is not brave, only trapped.',
];

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms));
const clock = () => new Date().toLocaleTimeString('en-US', { hour12: false });
const ms = (ts: any) => Number(ts.microsSinceUnixEpoch / 1000n);

// The room to join: by code, or the newest lobby the HOST arena has open.
async function findRoom(): Promise<any> {
  if (!HOST) return (await sql(null, `SELECT * FROM room WHERE code = '${(process.env.CODE ?? '').trim().toUpperCase()}'`))[0];
  for (let said = false; ; said = true) {
    const lobbies = (await sql(null, `SELECT * FROM room WHERE phase = 'lobby'`)).filter((r: any) => r.host[0].toLowerCase() === `0x${HOST}`);
    const newest = lobbies.sort((a: any, b: any) => b.id - a.id)[0];
    if (newest) return newest;
    if (!said) console.log(`${clock()} waiting for a lobby hosted by 0x${HOST.slice(0, 12)}…`);
    await sleep(500);
  }
}
const room = await findRoom();
if (!room) {
  console.error(`no room ${process.env.CODE ?? ''} in ${DBN}: set CODE or HOST`);
  process.exit(2);
}
const CODE: string = room.code;
const RID = BigInt(room.id);
let finished = 0;

class Phone {
  conn!: DbConnection;
  me = 0n;
  handled = new Set<string>();
  verse = 0;
  constructor(public name: string) {}

  async join() {
    const who = await identity();
    await new Promise<void>((resolve, reject) => {
      this.conn = DbConnection.builder()
        .withUri(URI)
        .withDatabaseName(DBN)
        .withToken(who.token)
        .withAutomaticReconnect()
        .onConnect(c => {
          c.subscriptionBuilder()
            .onApplied(() => resolve())
            .subscribe([`SELECT * FROM room WHERE id = ${RID}`, `SELECT * FROM turn WHERE room_id = ${RID}`, 'SELECT * FROM hand',
              `SELECT * FROM heat WHERE room_id = ${RID}`, `SELECT * FROM runner WHERE room_id = ${RID}`]);
        })
        .onConnectError((_c, e) => reject(e))
        .build();
    });
    await this.conn.reducers.joinRoom({ code: CODE, name: this.name, epithet: '', hoard: [] });
    const [p] = await sql(null, `SELECT * FROM player WHERE room_id = ${RID} AND name = '${this.name}'`);
    this.me = BigInt(p.id);
    await this.conn.reducers.enter({ roomId: RID });
    console.log(`${clock()} ${this.name} joined ${CODE} and checked in`);
  }

  room() {
    return [...this.conn.db.room.iter()][0];
  }
  turn(id: bigint) {
    return [...this.conn.db.turn.iter()].find(t => t.id === id);
  }
  card(): string {
    const h = [...this.conn.db.hand.iter()].find(x => x.playerId === this.me);
    return h?.cards[0] ?? '';
  }

  // Called on every tick: acts once per turn attempt (once per heat in the Stadion).
  async step() {
    const r = this.room();
    if (r?.event === 'stadion') {
      const h = [...this.conn.db.heat.iter()][0];
      const key = h ? `heat ${h.heatNo} ${ms(h.goAt)}` : '';
      if (r.phase === 'speaking' && h && ms(h.goAt) > 0 && !this.handled.has(key)) {
        this.handled.add(key);
        await this.run(h);
      }
      return;
    }
    if (!r || !r.currentTurnId) return;
    const t = this.turn(r.currentTurnId);
    if (!t || t.playerId !== this.me) return;
    const key = `${t.id}.${t.attempt}`;
    if (r.phase === 'ready' && t.status === 'waiting' && !r.autoReady && !this.handled.has(`ready ${key}`)) {
      this.handled.add(`ready ${key}`);
      await sleep(1500);
      await this.conn.reducers.startTurn({ turnId: t.id }).catch(() => {});
    }
    if (r.phase !== 'speaking' || t.status !== 'speaking' || this.handled.has(key)) return;
    this.handled.add(key);
    const wait = ms(t.beatAt) - Date.now() + 800;
    if (wait > 0) await sleep(wait);
    if (r.event === 'discus') return this.throw(t.id);
    const card = this.card();
    const lines = r.event === 'debate'
      ? [ARGUMENTS[this.verse++ % ARGUMENTS.length].replace('{card}', card || 'define my terms')]
      : VERSES[this.verse++ % VERSES.length].map(l => l.replace('{card}', card || 'the wine-dark sea'));
    const call = (work: () => Promise<void>) => work().catch(e => console.log(`${clock()} ${this.name}: ${(e as Error).message}`));
    await call(() => this.conn.reducers.updateTranscript({ turnId: t.id, transcript: lines[0] }));
    await sleep(2500);
    if (card) await call(() => this.conn.reducers.playCard({ turnId: t.id, card }));
    const all = lines.join('\n');
    await call(() => this.conn.reducers.updateTranscript({ turnId: t.id, transcript: all }));
    await sleep(2500);
    await call(() => this.conn.reducers.endTurn({ turnId: t.id, transcript: all }));
    console.log(`${clock()} ${this.name} spoke${card ? ` (played "${card}")` : ''}`);
  }

  // A sprint from the gun: up to a top speed of 12–15 m/s over 2 s (LAZY runners jog at 4),
  // streaming its own distance at 10 Hz until the module places it or the race ends.
  async run(h: any) {
    await sleep(Math.max(0, ms(h.goAt) - Date.now()));
    const lazy = (process.env.LAZY ?? '').split(',').includes(this.name);
    const top = lazy ? 4 : 12 + Math.random() * 3;
    const t0 = Date.now();
    let distance = 0;
    let last = t0;
    for (;;) {
      const now = Date.now();
      const speed = top * Math.min(1, (now - t0) / 2000);
      distance += speed * ((now - last) / 1000);
      last = now;
      await this.conn.reducers.setStride({ roomId: RID, speed, distance }).catch(() => {});
      const me = [...this.conn.db.runner.iter()].find(x => x.playerId === this.me);
      if ((me && me.place > 0) || this.room()?.phase !== 'speaking') {
        console.log(`${clock()} ${this.name} ${me && me.time > 0 ? `crossed in ${me.time.toFixed(2)} s, place ${me.place}` : `stopped at ${Math.round(me?.distance ?? 0)} m, place ${me?.place ?? 0}`}`);
        return;
      }
      await sleep(100);
    }
  }

  async throw(turnId: bigint) {
    for (let i = 1; i <= 10; i++) {
      await this.conn.reducers.setProsody({ roomId: RID, loudness: i / 10, pitch: 0, hits: 1 }).catch(() => {});
      await sleep(200);
    }
    // Every fourth throw is a foul, so the arena's foul reveal gets played too.
    const foul = this.verse++ % 4 === 3;
    const distance = foul ? 0 : Math.round((20 + Math.random() * 25) * 10) / 10;
    await this.conn.reducers.throwDiscus({ turnId, speed: 12, angle: 33, timing: foul ? 0.3 : 0.95, distance, foul })
      .catch(e => console.log(`${clock()} ${this.name}: ${(e as Error).message}`));
    console.log(`${clock()} ${this.name} threw ${foul ? 'a foul' : `${distance} m`}`);
  }
}

const phones = NAMES.slice(0, POETS).map(n => new Phone(n));
// Stopped early (Ctrl-C, a task stop): leave first, so no ghost seat is left in a lobby.
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, async () => {
    for (const p of phones) await p.conn?.reducers.leaveRoom({ roomId: RID }).catch(() => {});
    console.log(`${clock()} stopped; left ${CODE}`);
    process.exit(130);
  });
}
for (const p of phones) await p.join();

// Counted from the subscription: an arena can rematch faster than a poll would see `finished`.
let closed = false;
phones[0].conn.db.room.onUpdate((_c, a, b) => {
  if (b.phase !== 'finished' || a.phase === 'finished') return;
  if (a.phase === 'lobby') {
    closed = true; // the arena opened a new room before this one began
    return;
  }
  finished++;
  console.log(`${clock()} battle ${finished}${STAY ? '' : ` of ${BATTLES}`} finished`);
});
// STAY: a companion for a human's battles. It plays every battle and rematch, moves when the
// HOST arena opens a newer lobby, and leaves once no one else has been connected for 2 min.
let lonelySince = Date.now();
let met = false;
let checked = 0;
let idle = false;
while (STAY ? !closed && !idle : finished < BATTLES && !closed) {
  for (const p of phones) void p.step();
  if (STAY && Date.now() - checked > 2000) {
    checked = Date.now();
    const mine = new Set(phones.map(p => p.me));
    const others = (await sql(null, `SELECT * FROM player WHERE room_id = ${RID}`)).filter((p: any) => !mine.has(BigInt(p.id)));
    // The clock starts once someone has come and gone: an empty lobby waits for its human.
    if (others.some((p: any) => p.connected)) {
      met = true;
      lonelySince = Date.now();
    } else if (met && Date.now() - lonelySince > IDLE_MS) idle = true;
    if (HOST) {
      const newer = (await sql(null, `SELECT * FROM room WHERE phase = 'lobby'`))
        .some((r: any) => r.host[0].toLowerCase() === `0x${HOST}` && BigInt(r.id) > RID);
      if (newer) {
        console.log(`${clock()} the arena opened a newer lobby`);
        closed = true;
      }
    }
  }
  await sleep(200);
}
if (idle) console.log(`${clock()} no one else here for ${IDLE_MS / 60000} min`);
for (const p of phones) {
  await p.conn.reducers.leaveRoom({ roomId: RID }).catch(() => {});
  p.conn.disconnect();
}
if (closed) {
  // Exit 3: the arena opened a new room. In HOST mode, run this in a loop that restarts on 3
  // (`until ...; [ $? -ne 3 ]; do :; done`) to follow the arena to it.
  console.log(`${clock()} ${CODE} closed before it began`);
  process.exit(3);
}
console.log(`${clock()} left ${CODE}`);
process.exit(0);
