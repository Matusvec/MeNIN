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
//   CODE=ABCD POETS=4 PACIFIST=Ada,Bo npm run phones  # boxing: Ada and Bo only guard (goes to the bell)
//   CODE=ABCD STYLE=Ada:spam,Bo:counter npm run phones # boxing styles: spam, paced (default), counter
//   CODE=ABCD NAMES=Ada,Bo npm run phones            # archery: the first phone is the bow, the second
//                                                      # the arrow; the players shoot in join order
//                                                      # (ARCHERS=Odysseus,Penelope names others)
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
// Archers: the room's players in join order (SPEC), unless ARCHERS names others.
const ARCHERS = (process.env.ARCHERS ?? '').split(',').map(n => n.trim()).filter(Boolean);
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
              `SELECT * FROM heat WHERE room_id = ${RID}`, `SELECT * FROM runner WHERE room_id = ${RID}`,
              `SELECT * FROM fight WHERE room_id = ${RID}`, `SELECT * FROM fighter WHERE room_id = ${RID}`]);
          // Archery's tables on their own, so a database without them yet still works.
          c.subscriptionBuilder()
            .onError(() => {})
            .subscribe([`SELECT * FROM range WHERE room_id = ${RID}`, `SELECT * FROM archer WHERE room_id = ${RID}`,
              `SELECT * FROM arrow_shot WHERE room_id = ${RID}`]);
        })
        .onConnectError((_c, e) => reject(e))
        .build();
    });
    await this.conn.reducers.joinRoom({ code: CODE, name: this.name, epithet: '', hoard: [] });
    const [p] = await sql(null, `SELECT * FROM player WHERE room_id = ${RID} AND name = '${this.name}'`);
    this.me = BigInt(p.id);
    await this.conn.reducers.enter({ roomId: RID });
    console.log(`${clock()} ${this.name} joined ${CODE} and checked in`);
    if (this.room()?.event === 'toxeia') await this.conn.reducers.claimStation({ roomId: RID, role: '' }).catch(() => {});
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
    if (r?.event === 'pygmachia') {
      const f = [...this.conn.db.fight.iter()][0];
      const inBout = [...this.conn.db.fighter.iter()].some(x => x.playerId === this.me);
      const key = f ? `bout ${r.roundNo} ${ms(f.goAt)}` : '';
      if (r.phase === 'speaking' && f && inBout && ms(f.goAt) > 0 && !this.handled.has(key)) {
        this.handled.add(key);
        await this.box(f);
      }
      return;
    }
    if (r?.event === 'toxeia') return this.shoot(r);
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

  // A bout from the bell, in a STYLE (per name, e.g. STYLE=Ada:spam,Bo:counter; default paced):
  //   spam     a punch every 260 ms, never a guard
  //   paced    combos of 2–3 at 0.4 s, then the guard up for 1–1.6 s; counters when it can
  //   counter  the guard up; punches inside the counter window, and a jab now and then
  // The fists wander and the aim streams at 20 Hz with the guard. PACIFIST fighters only aim
  // and guard, so a bout of two of them goes to the bell.
  async box(f: any) {
    await sleep(Math.max(0, ms(f.goAt) - Date.now()));
    const pacifist = (process.env.PACIFIST ?? '').split(',').includes(this.name);
    const styles = Object.fromEntries((process.env.STYLE ?? '').split(',').filter(Boolean).map(x => x.split(':')));
    const style = styles[this.name] ?? 'paced';
    const kinds = ['jab', 'hook', 'uppercut'];
    const seed = Math.random() * 6;
    const t0 = Date.now();
    let next = t0 + 400 + Math.random() * 600;
    let left = 0;
    let guard = style !== 'spam';
    let raiseAt = 0;
    let punches = 0;
    const throwOne = async (pitch: number) => {
      const kind = kinds[Math.floor(Math.random() * kinds.length)];
      const power = style === 'spam' ? 0.6 + Math.random() * 0.3 : 0.6 + Math.random() * 0.4;
      await this.conn.reducers.throwPunch({ roomId: RID, kind, power, aimYaw: 0, aimPitch: pitch }).catch(() => {});
      punches++;
      guard = false;
    };
    for (;;) {
      const fight = [...this.conn.db.fight.iter()][0];
      if (this.room()?.phase !== 'speaking' || !fight || ms(fight.endedAt) > 0) break;
      const now = Date.now();
      const t = (now - t0) / 1000;
      const me = [...this.conn.db.fighter.iter()].find(x => x.playerId === this.me);
      const window = me ? ms(me.counterUntil) > now : false;
      const pitch = Math.random() < 0.55 ? 0.3 + Math.random() * 0.5 : -0.3 - Math.random() * 0.5;
      if (!pacifist) {
        if (style === 'spam' && now >= next) { await throwOne(pitch); next = now + 260; }
        else if (style !== 'spam' && window) { await throwOne(0.5); raiseAt = now + 300; next = Math.max(next, now + 900); }
        else if (style === 'paced' && now >= next) {
          await throwOne(pitch);
          left = left > 0 ? left - 1 : 1 + Math.floor(Math.random() * 2);
          if (left > 0) next = now + 400;
          else { next = now + 1000 + Math.random() * 600; raiseAt = now + 350; }
        } else if (style === 'counter' && now >= next) { await throwOne(0.5); raiseAt = now + 300; next = now + 2500 + Math.random() * 1500; }
      }
      if (raiseAt && now >= raiseAt) { guard = true; raiseAt = 0; }
      if (pacifist) guard = (t + seed) % 3 < 0.8 || style === 'counter';
      await this.conn.reducers.setFistAim({ roomId: RID, yaw: 0.25 * Math.sin(t * 1.3 + seed), pitch: 0.5 * Math.sin(t * 0.7 + seed), guard }).catch(() => {});
      await sleep(50);
    }
    const me = [...this.conn.db.fighter.iter()].find(x => x.playerId === this.me);
    const fight = [...this.conn.db.fight.iter()][0];
    const won = fight && fight.winnerId === this.me;
    const secs = fight ? ((ms(fight.endedAt) - ms(fight.goAt)) / 1000).toFixed(1) : '?';
    console.log(`${clock()} ${this.name} (${pacifist ? 'pacifist' : style}) ${won ? 'won' : fight?.winnerId ? 'lost' : 'drew'}${fight?.ko ? ' by KO' : ' at the bell'} after ${secs} s: ${punches} punches, health ${Math.round(me?.health ?? 0)}, stamina ${Math.round(me?.stamina ?? 0)}`);
  }

  // Archery. The bow phone names the next archer, the players in join order or ARCHERS (then
  // '': that's everyone, though the module ends the range itself after the last player), and
  // aims each arrow: it swings in from off the target, settles, and holds with a tremor, aimed
  // off for a full draw's wind drift with an error that grows with each archer (the first is
  // the best). The arrow phone nocks, draws over 1.2 s streaming the draw, holds, and looses;
  // one arrow in six is a weak draw that drops low.
  async shoot(r: any) {
    const st = [...this.conn.db.range.iter()][0];
    if (!st) return;
    const archers = [...this.conn.db.archer.iter()];
    if (st.bowId === this.me && r.phase === 'ready' && st.archerId === 0n) {
      const key = `name ${finished} ${archers.length}`;
      if (this.handled.has(key)) return;
      this.handled.add(key);
      await sleep(1500);
      const names = ARCHERS.length ? ARCHERS : (await sql(null, `SELECT * FROM player WHERE room_id = ${RID}`)).sort((a: any, b: any) => a.seat - b.seat).map((p: any) => p.name);
      const name = names.find((n: string) => !archers.some(a => a.name.toLowerCase() === n.toLowerCase())) ?? '';
      await this.conn.reducers.nextArcher({ roomId: RID, name })
        .then(() => console.log(`${clock()} ${this.name} (the bow): ${name ? `next archer, ${name}` : "that's everyone"}`))
        .catch(e => console.log(`${clock()} ${this.name}: ${(e as Error).message}`));
      return;
    }
    const key = `arrow ${st.archerId} ${st.arrowNo}`;
    if (r.phase !== 'speaking' || st.archerId === 0n || this.handled.has(key)) return;
    if (st.bowId === this.me) {
      this.handled.add(key);
      await this.aim(st, archers.sort((a, b) => Number(a.id - b.id)).findIndex(a => a.id === st.archerId));
    } else if (st.arrowId === this.me) {
      this.handled.add(key);
      await this.draw(st);
    }
  }

  async aim(st: any, index: number) {
    const sd = 0.04 + 0.04 * Math.max(0, index);
    const gauss = () => Math.sqrt(-2 * Math.log(1 - Math.random())) * Math.cos(2 * Math.PI * Math.random());
    const yaw0 = -0.18 * st.wind * (30 / 70) + sd * gauss();
    const pitch0 = sd * gauss();
    const seed = Math.random() * 6;
    const t0 = Date.now();
    for (;;) {
      const cur = [...this.conn.db.range.iter()][0];
      if (this.room()?.phase !== 'speaking' || !cur || cur.archerId !== st.archerId || cur.arrowNo !== st.arrowNo) break;
      const t = (Date.now() - t0) / 1000;
      const swing = Math.max(0, 1 - t / 1.5);
      const yaw = yaw0 + 0.4 * swing * Math.sin(seed) + 0.008 * Math.sin(t * 7 + seed);
      const pitch = pitch0 + 0.3 * swing * Math.cos(seed) + 0.008 * Math.sin(t * 5.3 + seed);
      await this.conn.reducers.setBowAim({ roomId: RID, yaw, pitch }).catch(() => {});
      await sleep(50);
    }
  }

  async draw(st: any) {
    await sleep(1800 + Math.random() * 1200);
    const weak = Math.random() < 1 / 6;
    const full = weak ? 0.55 + Math.random() * 0.15 : 0.9 + Math.random() * 0.1;
    const t0 = Date.now();
    while (Date.now() - t0 < 1700) {
      if (this.room()?.phase !== 'speaking') return;
      await this.conn.reducers.setDraw({ roomId: RID, draw: full * Math.min(1, (Date.now() - t0) / 1200) }).catch(() => {});
      await sleep(50);
    }
    await this.conn.reducers.loose({ roomId: RID, draw: full }).catch(e => console.log(`${clock()} ${this.name}: ${(e as Error).message}`));
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
const started = Date.now();
phones[0].conn.db.arrowShot.onInsert((_c, x) => {
  if (ms(x.at) < started) return;
  const who = [...phones[0].conn.db.archer.iter()].find(a => a.id === x.archerId)?.name ?? '?';
  console.log(`${clock()} ${who}, arrow ${x.arrowNo}: ${x.flight === 0 ? 'time ran out' : `ring ${x.ring} at (${x.x.toFixed(2)}, ${x.y.toFixed(2)}) m, draw ${x.draw.toFixed(2)}, wind ${x.wind.toFixed(1)} m/s`}`);
});

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
