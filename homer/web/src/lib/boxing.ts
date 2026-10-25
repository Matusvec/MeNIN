// Pygmachia (boxing) on the web arena: the fight's view model, the mapping from the module's rows to artist's
// rig (src/boxing/), and Homer's calls. The module resolves every punch (multiplayer's); this only shows it.
// SPEC "The games", Pygmachia v1 (after Wii Sports Boxing): one phone per fighter, held like a fist; the two
// fists mirror each other (Matus), and a punch throws the hand on the side the phone points to.

import type { Conductor } from './arena'
import type { Aim, Hand, Punch as RigPunch, ThrowPhase } from '../boxing/rig'

export type BoutFighter = {
  id: bigint
  name: string
  seat: number
  hp: number // 0..100
  guard: boolean
  yaw: number // -1..1: where the phone points, left/right
  pitch: number // -1..1: low..high
  stamina: number // 0..100 (v2): low is a tired, sagging fighter
  combo: number // the current chain (v2): 0 idle, 1, 2, 3…
}

export type BoutPunch = {
  id: string
  from: bigint
  to: bigint
  kind: string // jab | hook | uppercut
  zone: string // head | body
  power: number // 0..1
  yaw: number
  result: string // landed | blocked | missed
  damage: number
  counter: boolean
  combo: number // this punch's place in its chain (v2): 1, 2, 3…
  at: number // this browser's clock when it arrived
}

export type Bout = {
  fighters: BoutFighter[] // by seat
  punches: BoutPunch[] // in the module's insert order
  goAt: number | null // this browser's clock: the bell (after the 3-2-1)
  endsAt: number | null
  ended: boolean
  endedAt: number | null // this browser's clock: the KO or the bell
  ko: boolean
  winnerId: bigint // 0n: a draw, or not over
}

// A punch's beats (artist's rig): cocked by the chin, fired, carried through.
const WINDUP_MS = 70
const SNAP_MS = 70
const FOLLOW_MS = 180
export const THROW_MS = WINDUP_MS + SNAP_MS + FOLLOW_MS
export const HIT_MS = 320 // the target rocks (boxing.css .hit is 0.32 s)
export const COUNTER_SLOWMO_MS = 300 // a counter lands in slow motion
export const KO_SLOWMO_MS = 1500 // and so does the KO fall (artist's fall is ~1.5 s)
export const FLASH_MS = 900 // a COUNTER! banner or a combo stamp stays up this long
export const TIRED = 25 // stamina under this sags the fighter
const CALL_GAP_MS = 2500 // Homer calls at most this often
const CALL_STALE_MS = 900 // a call that can't start this soon after the punch is dropped: never over the action

/** Where in its beats a punch is at `now`, or null when it's done. */
export function throwPhase(p: BoutPunch | undefined, now: number): ThrowPhase | null {
  if (!p) return null
  const t = now - p.at
  return t < 0 ? null : t < WINDUP_MS ? 'windup' : t < WINDUP_MS + SNAP_MS ? 'snap' : t < THROW_MS ? 'follow' : null
}

/** Slow motion: a counter's landing, then the KO fall. */
export function slowmo(bout: Bout, now: number): boolean {
  if (bout.ko && bout.endedAt !== null && now - bout.endedAt < KO_SLOWMO_MS) return true
  const last = bout.punches[bout.punches.length - 1]
  return Boolean(last?.counter && last.result === 'landed' && now - last.at < COUNTER_SLOWMO_MS)
}

/** The newest punch matching `pick` that's still within `ms`, if any. */
export function recent(bout: Bout, now: number, ms: number, pick: (p: BoutPunch) => boolean): BoutPunch | undefined {
  for (let i = bout.punches.length - 1; i >= 0; i--) {
    const p = bout.punches[i]
    if (now - p.at > ms) break
    if (pick(p)) return p
  }
  return undefined
}

/** The rig's hand: a fighter facing right leads with the left, so pointing left throws the lead hand. */
export function rigHand(yaw: number): Hand {
  return yaw < 0 ? 'lead' : 'rear'
}

export function rigPunch(p: BoutPunch): RigPunch {
  if (p.zone === 'body') return 'body'
  return p.kind === 'hook' ? 'hook' : p.kind === 'uppercut' ? 'uppercut' : 'straight'
}

/** The rig's aim from the phone's: both fists at one height (0 head .. 1 belly); reach follows the punch's beat. */
export function rigAim(f: BoutFighter, phase: ThrowPhase | null): Aim {
  const x = phase === 'windup' ? 0.15 : phase === 'snap' ? 1 : phase === 'follow' ? 0.9 : 0.35
  return { x, y: Math.max(0, Math.min(1, (1 - f.pitch) / 2)) }
}

/** The punch this fighter is throwing at `now`, if any. */
export function throwing(bout: Bout, id: bigint, now: number): BoutPunch | undefined {
  for (let i = bout.punches.length - 1; i >= 0; i--) {
    const p = bout.punches[i]
    if (now - p.at > THROW_MS) break
    if (p.from === id) return p
  }
  return undefined
}

/** The landed punch rocking this fighter at `now`, if any. */
export function rocking(bout: Bout, id: bigint, now: number): BoutPunch | undefined {
  for (let i = bout.punches.length - 1; i >= 0; i--) {
    const p = bout.punches[i]
    if (now - p.at > HIT_MS) break
    if (p.to === id && p.result === 'landed') return p
  }
  return undefined
}

/** Seconds left on the clock, or null before the fight. */
export function secondsLeft(bout: Bout, now: number): number | null {
  if (bout.endsAt === null) return null
  return Math.max(0, Math.ceil((bout.endsAt - now) / 1000))
}

const WHERE = (p: BoutPunch) => (p.zone === 'body' ? 'to the ribs' : p.kind === 'uppercut' ? 'under the chin' : 'to the jaw')
const WHAT: Record<string, string> = { jab: 'A jab', hook: 'A hook', uppercut: 'An uppercut' }

/** Homer's call for a punch: short, only landed punches; a counter and a combo outrank a plain hit. */
export function callFor(p: BoutPunch, attacker: string, defender: string): string | null {
  if (p.result !== 'landed') return null
  const what = WHAT[p.kind] ?? 'A blow'
  if (p.counter) return 'COUNTER!'
  if (p.combo >= 3) return p.combo === 3 ? `A combo! Three for ${attacker}!` : `${p.combo} in a row! ${defender} is reeling!`
  if (p.damage >= 14) return `A hard ${p.kind} ${WHERE(p)}! ${defender} staggers!`
  return p.id.endsWith('0') || p.id.endsWith('5') ? `${attacker} lands ${WHERE(p)}!` : `${what} ${WHERE(p)}!`
}

/** Runs every arena tick in pygmachia rooms, like discus's conductor: the bell, the calls, the result. */
export function conductPygmachia(c: Conductor): void {
  const { room, bout } = c
  if (!bout) return
  const from = c.revealKey
  const name = (id: bigint) => bout.fighters.find((f) => f.id === id)?.name ?? 'the fighter'
  switch (room.phase) {
    case 'ready': {
      const [a, b] = bout.fighters
      if (!a || !b) return
      c.say(`box intro ${c.battleKey}`, `${a.name} and ${b.name}. Fists up.`, () => c.startFight())
      return
    }
    case 'speaking': {
      // Calls for landed punches, fresh only, spaced out: Homer never talks over the action.
      const now = Date.now()
      for (let i = bout.punches.length - 1; i >= 0; i--) {
        const p = bout.punches[i]
        if (now - p.at > CALL_STALE_MS) break
        const line = callFor(p, name(p.from), name(p.to))
        if (line && now - c.lastCall() >= CALL_GAP_MS) {
          c.sayFresh(`box ${p.id}`, line, CALL_STALE_MS)
          return
        }
      }
      // Out of wind: said once a fight per fighter, only when nothing else is being called.
      for (const f of bout.fighters) {
        if (f.stamina < TIRED && now - c.lastCall() >= CALL_GAP_MS) {
          c.sayFresh(`box tired ${c.battleKey} ${room.roundNo} ${f.id}`, `${f.name} is tired!`, CALL_STALE_MS)
          return
        }
      }
      return
    }
    case 'scored': {
      const winner = bout.winnerId ? name(bout.winnerId) : ''
      const loser = bout.fighters.find((f) => f.id !== bout.winnerId)?.name ?? ''
      const line = bout.ko && winner ? `${loser} is down! The fight goes to ${winner}!`
        : winner ? `The bell! ${winner} takes it on the cards.` : 'The bell! Neither falls. A draw.'
      c.say(`box result ${c.battleKey}`, line, () => window.setTimeout(() => c.advanceOnce(from), 2500))
      return
    }
    case 'finale': {
      const winner = bout.winnerId ? name(bout.winnerId) : ''
      c.say(`box crown ${c.battleKey}`, winner ? `${winner}. The ring is yours.` : 'No crown tonight.', () => c.advanceOnce(from))
      return
    }
  }
}
