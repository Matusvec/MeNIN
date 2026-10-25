// The rough cut's burned captions (rough_cut.py captions): one transparent 1920×1080 PNG per word state, in the
// arena's live-words manner. The words said so far in cream, the word being said bright, the rest of the line laid
// out but not shown yet (so the line never reflows). One headless Chrome, closed at the end.
//   node captions.mjs <work/captions>   (reads states.json, writes png/<id>.png and png/blank.png)
import { spawn } from 'node:child_process'
import { readFileSync, writeFileSync } from 'node:fs'

const dir = process.argv[2]
const states = JSON.parse(readFileSync(`${dir}/states.json`, 'utf8'))
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const PORT = 9348
const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', ['--headless=new', `--remote-debugging-port=${PORT}`,
  `--user-data-dir=${dir}/profile`, '--window-size=1920,1080', '--hide-scrollbars', '--no-first-run', 'about:blank'], { stdio: 'ignore' })
let target
for (let i = 0; i < 40 && !target; i++) { await sleep(250); try { target = (await (await fetch(`http://127.0.0.1:${PORT}/json`)).json()).find((t) => t.type === 'page') } catch {} }
const ws = new WebSocket(target.webSocketDebuggerUrl)
await new Promise((r) => (ws.onopen = r))
let id = 0
const pending = new Map()
ws.onmessage = (m) => { const d = JSON.parse(m.data); if (d.id && pending.has(d.id)) { pending.get(d.id)(d); pending.delete(d.id) } }
const cdp = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })) })
const js = (expr) => cdp('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true })

const page = `<!doctype html><html><head><meta charset="utf-8"><style>
html, body { margin: 0; width: 1920px; height: 1080px; background: transparent; }
.cap { position: absolute; left: 50%; bottom: 290px; transform: translateX(-50%); width: max-content; max-width: 1560px;
  text-align: center; font: 500 46px/1.25 "Inter", "Helvetica Neue", Helvetica, Arial, sans-serif; color: #efe6d2;
  text-shadow: 0 2px 12px rgba(0, 0, 0, 0.55), 0 0 2px rgba(0, 0, 0, 0.75); }
.cap .said { opacity: 0.86; }
.cap .now { color: #ffffff; opacity: 1; text-shadow: 0 2px 12px rgba(0, 0, 0, 0.55), 0 0 2px rgba(0, 0, 0, 0.75), 0 0 20px rgba(255, 246, 225, 0.35); }
.cap .later { visibility: hidden; }
</style></head><body><div class="cap" id="cap"></div></body></html>`
await cdp('Page.enable')
await cdp('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false })
await cdp('Emulation.setDefaultBackgroundColorOverride', { color: { r: 0, g: 0, b: 0, a: 0 } })
await cdp('Page.navigate', { url: `data:text/html;base64,${Buffer.from(page).toString('base64')}` })
await sleep(800)
await js(`document.fonts.ready`)

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
const shoot = async (name) => {
  const r = await cdp('Page.captureScreenshot', { format: 'png' })
  writeFileSync(`${dir}/png/${name}.png`, Buffer.from(r.result.data, 'base64'))
}
await shoot('blank')
for (const s of states) {
  if (s.html) {  // a whole transparent overlay (rough_cut.py's C0 placeholder)
    await js(`document.body.innerHTML = ${JSON.stringify(s.html)}`)
    await sleep(900) // a web font (an @import in the overlay) has time to land
    await js(`document.fonts.ready.then(() => true)`)
    await shoot(s.id)
    continue
  }
  const html = s.words.map((w, i) => `<span class="${i < s.k ? 'said' : i === s.k ? 'now' : 'later'}">${esc(w)}</span>`).join(' ')
  // Over a card (its own type sits where captions do), the line drops to the foot of the frame.
  await js(`(() => { const c = document.getElementById('cap'); c.style.bottom = ${s.low ? "'56px'" : "'290px'"}; c.innerHTML = ${JSON.stringify(html)}; return true })()`)
  await shoot(s.id)
}
console.log(`${states.length} caption states`)
ws.close()
chrome.kill()
process.exit(0)
