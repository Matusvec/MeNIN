// Toxeia, the archery, on the web arena (SPEC "The games"): one archer at a time on two phones.
// The bow phone streams its aim and names each archer, the arrow phone streams its draw and
// looses, and the module (spacetime/src/index.ts, landing) works out where the arrow struck
// from the aim, the draw and this arrow's wind. This calls it in Homer's voice, holds each
// arrow on screen through its flight and the score, and moves the range on. No Claude.
//
// conductToxeia runs every arena tick in toxeia rooms. An arrow's reveal is the flight
// (FLIGHT_S on the panel), Homer's call, then SCORED_MS on the score, then advance: the
// archer's next arrow, or back to the bow phone for the next name.

import type { Conductor } from './arena'
import { sleep } from './clock' // a Web Worker clock: a backgrounded arena tab can't stretch a hold
import type { Archer, ArrowShot, Player, Range } from '../stdb/types'
import { FLIGHT_S } from '../toxeia/Range'

/** The module's numbers (spacetime/src/index.ts): aim ±1 is AIM_SPAN metres from the gold. */
export const AIM_SPAN = 1
/** The target face's radius in metres: ten rings of 6.1 cm. */
export const FACE = 0.61
export const ARROWS = 3
/** What the arena hook adds for archery (this room's rows), on the Conductor and the ArenaView. */
export type ToxeiaFeed = {
  range: Range | null // the station, the archer up, and the arrow on the string (wind, live aim and draw)
  archers: Archer[] // any order
  arrows: ArrowShot[] // this room's arrow_shot rows, any order
  nextArcher?: (name: string) => void // camera mode: the host's next_archer (there's no bow phone)
}

/** Camera mode (range.camera, appended): the webcam aims and draws, each archer's phone looses. */
export const isCamera = (range: Range | null) => Boolean((range as (Range & { camera?: boolean }) | null)?.camera)

const SCORED_MS = 2500
const CHAMPION_MS = 3000
const STRONG_WIND = 3 // m/s: worth a word before the draw

export const RULES = 'Toxeia. One phone is the bow: point it at the target. The other is the arrow: hold, pull back, let go.'
export const CAMERA_RULES = 'Toxeia. Face the target and raise your bow arm. Phone in the other hand: thumb down, draw it back to your face, lift your thumb to loose.'

/** When this screen first saw each arrow land (local ms), by arrow_shot id. */
const seen = new Map<bigint, number>()

export function seenAt(shot: ArrowShot): number {
  if (!seen.has(shot.id)) seen.set(shot.id, Date.now())
  return seen.get(shot.id)!
}

/** The wind as the panel draws it: a speed, and the way it blows (0° right, 180° left). */
export function windOf(range: Range | null): { speed: number; toward: number } | null {
  if (!range || range.archerId === 0n) return null
  return { speed: Math.abs(range.wind), toward: range.wind < 0 ? 180 : 0 }
}

/** Metres on the face to the panel's units (1 is the outer rim). */
export const onFace = (metres: number) => metres / FACE

/** Archers in shooting order. */
export function order(archers: Archer[]): Archer[] {
  return [...archers].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

/** Archers go in join order (SPEC): the first player who hasn't shot yet, or null when all have. */
export function nextUp(poets: Player[], archers: Archer[]): Player | null {
  const shot = new Set(archers.map((a) => a.name.toLowerCase()))
  return [...poets].sort((a, b) => a.seat - b.seat).find((p) => !shot.has(p.name.toLowerCase())) ?? null
}

/** The arrows of one archer, in order. */
export function arrowsOf(shots: ArrowShot[], archerId: bigint): ArrowShot[] {
  return shots.filter((s) => s.archerId === archerId).sort((a, b) => a.arrowNo - b.arrowNo)
}

/** The newest arrow in the room, or null. */
export function newest(shots: ArrowShot[]): ArrowShot | null {
  return shots.reduce<ArrowShot | null>((top, s) => (!top || s.id > top.id ? s : top), null)
}

/** The standings: the best total first; a tie goes to more golds, then to whoever shot first. */
export function standings(archers: Archer[], shots: ArrowShot[]): Archer[] {
  const golds = (a: Archer) => shots.filter((s) => s.archerId === a.id && s.ring === 10).length
  return order(archers)
    .map((a, i) => ({ a, i, golds: golds(a) }))
    .sort((x, y) => y.a.total - x.a.total || y.golds - x.golds || x.i - y.i)
    .map((x) => x.a)
}

export function champion(archers: Archer[], shots: ArrowShot[]): Archer | null {
  return standings(archers, shots)[0] ?? null
}

/** Homer's word on an arrow, or null for a middling one (the stamp says it). */
function call(shot: ArrowShot): string | null {
  if (shot.flight === 0) return "Too slow. That arrow stays in the quiver."
  if (shot.ring === 10) return 'Into the gold!'
  const drift = 0.18 * shot.wind * shot.flight
  const blown = Math.abs(drift) >= 0.12 && Math.sign(shot.x) === Math.sign(shot.wind) && Math.abs(shot.x) >= 0.15
  const short = shot.draw < 0.6 && shot.y < -0.15 // below a 0.6 draw the arrow drops (the module's landing)
  if (shot.ring === 0 && short) return 'A soft draw. It fell short.'
  if (shot.ring === 0 && blown) return 'The wind took it.'
  if (shot.ring === 0) return 'Off the face.'
  if (shot.ring >= 8) return 'A fine arrow.'
  if (blown) return 'The wind took it.'
  if (short) return 'Draw it all the way. It dropped.'
  return null
}

export function conductToxeia(c: Conductor & ToxeiaFeed): void {
  const { room, range } = c
  const from = c.revealKey
  const archers = order(c.archers)
  const up = range && range.archerId ? archers.find((a) => a.id === range.archerId) : undefined
  switch (room.phase) {
    case 'ready': {
      // The rules once per hall, then whoever's next in join order. Two phones: Ready on the bow
      // starts them. Camera: there's no bow phone, so this calls them up once Homer has said it.
      const camera = isCamera(range)
      if (!archers.length) c.say(`toxeia rules ${room.id}`, camera ? CAMERA_RULES : RULES)
      const next = nextUp(c.poets, archers)
      if (next && camera) c.say(`toxeia step ${c.battleKey} ${next.id}`, `${next.name}, step up to the line.`, () => c.nextArcher?.(next.name))
      else if (next) c.say(`toxeia next ${c.battleKey} ${next.id}`, archers.length ? `Pass both phones to ${next.name}.` : `${next.name}, take both phones.`)
      return
    }
    case 'speaking': {
      if (!range || !up) return
      if (range.arrowNo === 1) c.say(`toxeia up ${up.id}`, `${up.name} steps to the line.`)
      if (Math.abs(range.wind) >= STRONG_WIND) {
        const way = range.wind > 0 ? 'to the right' : 'to the left'
        c.sayFresh(`toxeia wind ${up.id}.${range.arrowNo}`, `A strong wind, ${way}.`, 3000)
      }
      return
    }
    case 'scored': {
      const shot = newest(c.arrows)
      if (!shot) return
      const archer = archers.find((a) => a.id === shot.archerId)
      const land = seenAt(shot) + (shot.flight > 0 ? FLIGHT_S * 1000 : 0)
      c.perform(`toxeia flight ${shot.id}`, () => sleep(Math.max(0, land - Date.now())))
      const word = call(shot)
      if (word) c.say(`toxeia call ${shot.id}`, word)
      if (archer && shot.arrowNo === ARROWS) c.say(`toxeia total ${archer.id}`, `${archer.name} finishes on ${archer.total}.`)
      c.perform(`toxeia scored ${shot.id}`, async () => {
        await sleep(SCORED_MS)
        c.advanceOnce(from)
      })
      return
    }
    case 'finale': {
      const winner = champion(archers, c.arrows)
      const key = `toxeia champion ${c.battleKey}`
      c.say(key, winner ? `The bow goes to ${winner.name}, with ${winner.total}.` : 'No archer came forward. The bow stays with Apollo.')
      c.perform(`${key} hold`, async () => {
        await sleep(CHAMPION_MS)
        c.advanceOnce(from)
      })
      return
    }
  }
}
