// Timers that keep running while the arena's tab is in the background. A hidden tab's setTimeout and
// setInterval are throttled (to once a second, then once a minute), so a judge switching tabs, or the
// SpacetimeDB timeline on another desktop, stalled a turn (Talk to Homer HSMJ, Sat 22:54: the agent was
// never asked). A dedicated worker's timers aren't throttled that way, so the arena's tick and its holds
// run from one here. Without workers (or if one can't start), plain window timers stand in.

const SOURCE = `
const timers = new Map()
onmessage = (e) => {
  const { op, id, ms } = e.data
  if (op === 'after') timers.set(id, setTimeout(() => { timers.delete(id); postMessage(id) }, ms))
  else if (op === 'every') timers.set(id, setInterval(() => postMessage(id), ms))
  else { clearTimeout(timers.get(id)); clearInterval(timers.get(id)); timers.delete(id) }
}`

type Job = { fn: () => void; repeat: boolean }

let worker: Worker | null | undefined
let nextId = 1
const jobs = new Map<number, Job>()

function clockWorker(): Worker | null {
  if (worker !== undefined) return worker
  try {
    worker = new Worker(URL.createObjectURL(new Blob([SOURCE], { type: 'text/javascript' })))
    worker.onmessage = (e: MessageEvent<number>) => {
      const job = jobs.get(e.data)
      if (!job) return
      if (!job.repeat) jobs.delete(e.data)
      job.fn()
    }
  } catch {
    worker = null
  }
  return worker
}

function schedule(op: 'after' | 'every', ms: number, fn: () => void): () => void {
  const w = clockWorker()
  if (!w) {
    const id = op === 'every' ? window.setInterval(fn, ms) : window.setTimeout(fn, ms)
    return () => (op === 'every' ? window.clearInterval(id) : window.clearTimeout(id))
  }
  const id = nextId++
  jobs.set(id, { fn, repeat: op === 'every' })
  w.postMessage({ op, id, ms })
  return () => {
    jobs.delete(id)
    w.postMessage({ op: 'clear', id })
  }
}

/** Run `fn` every `ms`, unthrottled in a hidden tab. Returns a stop function. */
export const every = (ms: number, fn: () => void) => schedule('every', ms, fn)

/** Run `fn` once after `ms`, unthrottled in a hidden tab. Returns a cancel function. */
export const after = (ms: number, fn: () => void) => schedule('after', ms, fn)

/** Wait `ms`, unthrottled in a hidden tab. */
export const sleep = (ms: number): Promise<void> => new Promise((resolve) => after(ms, resolve))
