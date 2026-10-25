// The Stadion on the web arena (SPEC "The games"): everyone races at once. The phones stream
// their strides (set_stride) and the module places them at 192 m; this calls the race in
// Homer's voice, fires the gun, and moves on after the results. No Claude.
//
// conductStadion runs every arena tick in stadion rooms. The gun is the heat's go_at (server
// time); this screen's offset from the server clock is estimated the moment it sees the race
// begin, so the 3-2-1 on screen and Homer's "They're off!" land with the phones' haptics.

import type { Conductor } from './arena'
import { sleep } from './clock' // a Web Worker clock: a backgrounded arena tab can't stretch a hold
import type { Heat, Player, Runner } from '../stdb/types'

/** One stadion, Olympia's track. */
export const STADION_METRES = 192
/** A hard arm pump, in the module's game speed (m/s): the gait scale on the panel. */
export const SPRINT_SPEED = 14
const COUNT_IN_MS = 3000
const RESULTS_MS = 4000
const CHAMPION_MS = 3000

const ROMAN = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X']
export const roman = (n: number) => ROMAN[n] ?? String(n)

const heatKey = (h: Heat) => `${h.roomId}.${h.heatNo}.${h.goAt.toMillis()}`
const offsets = new Map<string, number>()

/** Local ms minus server ms for this heat, fixed when this screen first sees the race begin. */
export function serverOffset(h: Heat): number {
  const key = heatKey(h)
  if (!offsets.has(key)) offsets.set(key, Date.now() - (Number(h.goAt.toMillis()) - COUNT_IN_MS))
  return offsets.get(key)!
}

/** When the gun goes off on this screen's clock, or null before start_race. */
export function gunAt(h: Heat | null): number | null {
  if (!h || h.goAt.toMillis() === 0n) return null
  return Number(h.goAt.toMillis()) + serverOffset(h)
}

/** Race order: the placed by place, then everyone still running by distance. */
export function raceOrder(runners: Runner[]): Runner[] {
  return [...runners].sort((a, b) => (a.place || 1e9) - (b.place || 1e9) || b.distance - a.distance)
}

/** Crossed the line (the cap places the rest by distance, short of it and untimed). */
export const crossed = (r: Runner) => r.place > 0 && r.time > 0

const seconds = (t: number) => `${t.toFixed(2)} seconds`

/** The best total wins the meeting (points by place each heat); a tie goes to the earlier seat. */
function champion(poets: Player[]): Player | null {
  return [...poets].sort((a, b) => b.total - a.total || a.seat - b.seat)[0] ?? null
}

export function conductStadion(c: Conductor): void {
  const { room, heat, runners } = c
  const from = c.revealKey
  const key = `${c.battleKey} ${room.roundNo}`
  const name = (r: Runner) => c.poets.find((p) => p.id === r.playerId)?.name ?? 'A runner'
  // Entrances as poets check in: no Claude names anyone, so the epithet is the phone's own.
  if (room.phase !== 'speaking') {
    for (const p of c.poets.filter((p) => p.entered)) {
      c.say(`enter ${p.id}`, p.epithet ? `Enter ${p.name}, ${p.epithet}!` : `Enter ${p.name}!`)
    }
  }
  switch (room.phase) {
    case 'ready':
      // The rules once per hall, then the marks; the gun goes when Homer has said it.
      if (!heat || heat.goAt.toMillis() !== 0n) return
      c.say(`stadion rules ${room.id}`, 'One stadion. Phone in hand, pump your arms like a sprinter.')
      c.say(`stadion marks ${key}`, 'Runners, to your marks.', () => c.startRace())
      return
    case 'speaking': {
      const gun = gunAt(heat)
      if (gun === null) return
      // Hold the queue through the 3-2-1 so "They're off!" is the gun itself.
      c.perform(`stadion count ${key}`, () => sleep(Math.max(0, gun - Date.now())))
      c.say(`stadion off ${key}`, "They're off!")
      const first = runners.find((r) => r.place === 1 && crossed(r))
      if (first) c.say(`stadion first ${key}`, `${name(first)} breaks the tape!`)
      return
    }
    case 'scored': {
      const order = raceOrder(runners)
      const first = order[0]
      if (!first || !crossed(first)) c.say(`stadion first ${key}`, 'Nobody reached the line. The track wins this one.')
      else if (order.length === 1) c.say(`stadion first ${key}`, `${name(first)} breaks the tape!`)
      const line =
        first && crossed(first)
          ? order.length === 1
            ? `${name(first)}, ${seconds(first.time)}.`
            : `${name(first)} takes the heat in ${seconds(first.time)}.`
          : ''
      if (line) c.say(`stadion result ${key}`, line)
      c.perform(`stadion results ${key}`, async () => {
        await sleep(RESULTS_MS)
        c.advanceOnce(from)
      })
      return
    }
    case 'finale': {
      const winner = champion(c.poets)
      const key = `stadion champion ${c.battleKey}`
      c.say(key, winner ? `The stadion goes to ${winner.name}.` : 'The stadion goes to the gods.')
      c.perform(`${key} hold`, async () => {
        await sleep(CHAMPION_MS)
        c.advanceOnce(from)
      })
      return
    }
  }
}
