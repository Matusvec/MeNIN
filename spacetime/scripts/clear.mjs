// Is the database quiet enough to publish or deploy? Read-only, anonymous, over HTTP.
// A room is in play when it's mid-battle (any phase but lobby and finished) and a connected
// phone is in it now. A phone is in the room of its newest seat: `player.connected` is per
// identity, so every old seat of a connected phone reads connected too, and an abandoned room
// (a lost arrow left in `scored`, say) with nobody in it is idle.
//
//   npm run -s clear                      # homer-calhacks on Maincloud
//   WAIT=600 npm run -s clear             # poll every 10 s until clear, at most 600 s
//   STDB_URL=http://127.0.0.1:3000 STDB_DB=homer-test npm run -s clear
//
// Exit 0: clear (nothing in play, no phone connected). 1: a room is in play. 2: nothing in
// play, but phones are connected (idle in a lobby, say: fine for a deploy, not for a
// reconnect test).

import { sql } from './stdb.mjs';

const LIVE = ['dealing', 'theme', 'ready', 'speaking', 'judging', 'scored', 'round_end', 'finale'];
const WAIT = Number(process.env.WAIT ?? 0);
const clock = () => new Date().toTimeString().slice(0, 8);

async function status() {
  const [rooms, players] = await Promise.all([sql(null, 'SELECT * FROM room'), sql(null, 'SELECT * FROM player')]);
  const newest = new Map(); // identity -> its newest seat
  for (const p of players) {
    const id = p.identity[0];
    if (!newest.has(id) || p.id > newest.get(id).id) newest.set(id, p);
  }
  const phones = [...newest.values()].filter(p => p.connected);
  const inPlay = rooms.filter(r => LIVE.includes(r.phase) && phones.some(p => p.room_id === r.id));
  const where = p => rooms.find(r => r.id === p.room_id);
  if (inPlay.length) {
    const who = r => phones.filter(p => p.room_id === r.id).map(p => p.name).join(', ');
    return { code: 1, line: `busy: ${inPlay.map(r => `${r.code} (${r.event}, ${r.phase}: ${who(r)})`).join('; ')}` };
  }
  if (phones.length) {
    return { code: 2, line: `idle, but ${phones.length} phone(s) connected: ${phones.map(p => `${p.name} in ${where(p)?.code ?? '?'} (${where(p)?.phase ?? '?'})`).join('; ')}` };
  }
  return { code: 0, line: 'clear: nothing in play, no phone connected' };
}

const end = Date.now() + WAIT * 1000;
for (;;) {
  const s = await status();
  console.log(`${clock()} ${s.line}`);
  if (s.code === 0 || Date.now() >= end) process.exit(s.code);
  await new Promise(r => setTimeout(r, 10_000));
}
