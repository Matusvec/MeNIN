// Renders a timeline log (scripts/timeline.ts with LOG=…) as video: 1920×1080, 60 fps, the
// terminal timeline's look in big type, the window around the first verdict. Frame-stepped:
// the picture changes exactly when an event arrived (wall clock, to the ms), like the
// terminal, and a sidecar JSON gives frame 0's wall-clock time so the edit can sync it.
//
//   node scripts/render-timeline.mjs ../docs/video/timeline-take.log ../docs/video/broll/timeline.mp4
//   BEFORE=4000 AFTER=4000 AT=verdict node scripts/render-timeline.mjs <log> <out.mp4>
//
// AT is the reducer whose first event centres the window (default verdict). Needs Google
// Chrome (headless, for the type) and ffmpeg with libx264.

import { spawn, execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';

const [logPath, outPath] = process.argv.slice(2);
if (!logPath || !outPath) {
  console.error('usage: node scripts/render-timeline.mjs <timeline log> <out.mp4>');
  process.exit(2);
}
const BEFORE = Number(process.env.BEFORE ?? 4000);
const AFTER = Number(process.env.AFTER ?? 4000);
const AT = process.env.AT ?? 'verdict';
const ROWS = 14; // lines on screen
const COLOUR = { phone: '#56c8d8', agent: '#d77ce0', arena: '#e5c07b', timer: '#6f9cf2', other: '#c8ccd4' };
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

// ---------------------------------------------------------------- the log

const events = readFileSync(logPath, 'utf8')
  .split('\n')
  .filter(l => l && !l.startsWith('#'))
  .map(l => {
    const [wall, ms, who, reducer, text, colour] = l.split('\t');
    return { wall, t: Number(ms), who, reducer, text, colour };
  })
  .filter(e => Number.isFinite(e.t))
  .sort((a, b) => a.t - b.t);
const anchor = events.find(e => e.reducer === AT);
if (!anchor) {
  console.error(`no ${AT} event in ${logPath}`);
  process.exit(1);
}
const start = anchor.t - BEFORE;
const end = anchor.t + AFTER;

// The screen at each change: everything up to then, the last ROWS lines.
const changes = [start, ...events.filter(e => e.t > start && e.t <= end).map(e => e.t)];
const states = [...new Set(changes)].map(t => ({ t, lines: events.filter(e => e.t <= t).slice(-ROWS) }));

// ---------------------------------------------------------------- the look

const html = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
function page(lines, newest) {
  const rows = lines.map(e => {
    const swatch = e.colour ? `<i style="background:${e.colour}"></i>` : '';
    const fresh = e.t === newest ? ' class="fresh"' : '';
    return `<p${fresh}><span class="t">${html(e.wall.slice(3))}</span><b style="color:${COLOUR[e.who] ?? COLOUR.other}">${html(e.reducer.padEnd(17))}</b>${swatch}<span class="x">${html(e.text)}</span></p>`;
  }).join('');
  const tag = (who, label) => `<b style="color:${COLOUR[who]}">${label}</b>`;
  return `<!doctype html><meta charset="utf-8"><style>
    html, body { margin: 0; width: 1920px; height: 1080px; background: #0e1116; overflow: hidden; }
    body { font: 44px/1.42 ui-monospace, 'SF Mono', Menlo, monospace; color: #c8ccd4; padding: 56px 72px; box-sizing: border-box; }
    header { color: #6b7280; margin-bottom: 28px; white-space: pre; }
    header b { margin-left: 28px; }
    main { position: absolute; left: 72px; right: 72px; bottom: 56px; }
    p { margin: 0; white-space: pre; overflow: hidden; text-overflow: ellipsis; }
    p.fresh { background: rgba(255,255,255,0.06); }
    .t { color: #6b7280; margin-right: 26px; }
    b { font-weight: 700; margin-right: 26px; }
    i { display: inline-block; width: 1.1em; height: 0.8em; margin-right: 18px; vertical-align: -0.05em; border-radius: 3px; }
    .x { color: #e6e8eb; }
  </style><header>SpacetimeDB · homer-calhacks${tag('phone', 'phone')}${tag('agent', 'Homer')}${tag('arena', 'arena')}${tag('timer', 'timer')}</header><main>${rows}</main>`;
}

// ---------------------------------------------------------------- render

const work = mkdtempSync(join(tmpdir(), 'timeline-'));
const chrome = spawn(CHROME, ['--headless=new', '--remote-debugging-port=9355', `--user-data-dir=${work}/profile`,
  '--window-size=1920,1080', '--hide-scrollbars', '--no-first-run', 'about:blank'], { stdio: 'ignore' });
const sleep = ms => new Promise(r => setTimeout(r, ms));
let target;
for (let i = 0; i < 60 && !target; i++) {
  await sleep(250);
  try { target = (await (await fetch('http://127.0.0.1:9355/json')).json()).find(t => t.type === 'page'); } catch {}
}
if (!target) { chrome.kill(); console.error('Chrome did not start'); process.exit(1); }
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise(r => (ws.onopen = r));
let id = 0;
const pending = new Map();
ws.onmessage = m => { const d = JSON.parse(m.data); if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); } };
const cdp = (method, params = {}) => new Promise(r => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
await cdp('Page.enable');
await cdp('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false });
const frameId = (await cdp('Page.getFrameTree')).frameTree.frame.id;

const list = [];
for (const [i, s] of states.entries()) {
  await cdp('Page.setDocumentContent', { frameId, html: page(s.lines, s.t === start ? -1 : s.t) });
  await sleep(40);
  const shot = await cdp('Page.captureScreenshot', { format: 'png' });
  const file = join(work, `state-${String(i).padStart(3, '0')}.png`);
  writeFileSync(file, Buffer.from(shot.data, 'base64'));
  const next = states[i + 1]?.t ?? end;
  list.push(`file '${file}'`, `duration ${((next - s.t) / 1000).toFixed(3)}`);
}
list.push(`file '${join(work, `state-${String(states.length - 1).padStart(3, '0')}.png`)}'`); // concat wants the last again
writeFileSync(join(work, 'list.txt'), list.join('\n') + '\n');
ws.close();
chrome.kill();

mkdirSync(dirname(resolve(outPath)), { recursive: true });
execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', join(work, 'list.txt'),
  '-vf', 'fps=60,format=yuv420p', '-c:v', 'libx264', '-preset', 'slow', '-crf', '14', '-movflags', '+faststart',
  '-t', ((end - start) / 1000).toFixed(3), outPath]);
const sidecar = {
  video: outPath, fps: 60, width: 1920, height: 1080, seconds: (end - start) / 1000,
  frame0: { epochMs: start, wall: new Date(start).toTimeString().slice(0, 8) + '.' + String(start % 1000).padStart(3, '0') },
  anchor: { reducer: AT, epochMs: anchor.t, wall: anchor.wall, atSecond: BEFORE / 1000, text: anchor.text },
  changes: states.length,
};
writeFileSync(outPath.replace(/\.mp4$/, '') + '.json', JSON.stringify(sidecar, null, 2) + '\n');
if (process.env.KEEP) console.log(`frames kept in ${work}`);
else rmSync(work, { recursive: true, force: true });
console.log(`${outPath}: ${states.length} states, ${sidecar.seconds} s at 60 fps; frame 0 = ${sidecar.frame0.wall} (${start}); ${AT} at ${sidecar.anchor.atSecond} s`);
