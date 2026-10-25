// Discus on the web arena (SPEC "The games"): a port of DiscusDirector and DiscusPresenter
// (ios/Homer/Events/Discus/DiscusPresenter.swift). No Claude: the phone measures the throw,
// the server stores it in discus_throw, and this paces the reveal and moves the battle on.
//
// conductDiscus runs every arena tick in discus rooms. A throw's reveal is the flight
// (1.5 + 1.5·d/80 s), Homer's call on the landing, then 3 s on the landing, then advance.
// The flight starts when Homer's queue reaches it, and the panel reads that start from here,
// so the arc and his voice stay in step whatever the device clocks say.

import type { Conductor } from './arena'
import type { DiscusThrow, Player } from '../stdb/types'

/** The Phayllos line: the ancient legend's throw, marked on the field (DiscusPhysics.phayllos). */
export const PHAYLLOS = 29
/** The field is 80 m; nothing lands past it. */
export const FIELD = 80
const GOOD = 20 // shorter is a gentle toss
const LANDED_MS = 3000
const NO_THROW_MS = 2000
const CHAMPION_MS = 3000

export const RULES = 'Grip it. Swing. Let go of the button, not the phone.'

export function flightMs(metres: number): number {
  return (1.5 + 1.5 * Math.min(1, Math.max(0, metres) / FIELD)) * 1000
}

/** When each throw's flight began on this screen (local ms), by turn id. */
const flights = new Map<bigint, { start: number; ms: number }>()

export function flightOf(turnId: bigint): { start: number; ms: number } | undefined {
  return flights.get(turnId)
}

/** The longest landed throw in `rows`; fouls fly nowhere. */
export function best(rows: DiscusThrow[]): number | null {
  const landed = rows.filter((t) => !t.foul).map((t) => t.distance)
  return landed.length ? Math.max(...landed) : null
}

export type Landing = 'hall' | 'phayllos' | 'personal' | null

/** What a landing earned: the hall's best beats passing Phayllos, which beats a personal best. */
export function landing(row: DiscusThrow, all: DiscusThrow[]): Landing {
  if (row.foul) return null
  const before = all.filter((t) => t.id < row.id)
  const hall = best(before)
  if (hall !== null && row.distance > hall) return 'hall'
  if (row.distance > PHAYLLOS) return 'phayllos'
  // A personal best needs an earlier throw to beat.
  const mine = before.filter((t) => t.playerId === row.playerId)
  if (mine.length && row.distance > (best(mine) ?? 0)) return 'personal'
  return null
}

/** The release, as the arena shows it: "38° · 24 m/s". Null for throws from older phones. */
export function releaseLabel(row: DiscusThrow): string | null {
  return row.releaseSpeed > 0 ? `${Math.round(row.angle)}° · ${Math.round(row.releaseSpeed)} m/s` : null
}

/** Homer's word on the technique, from the release (newer phones only), or null. */
export function technique(row: DiscusThrow): string | null {
  if (row.foul || row.releaseSpeed <= 0) return null
  const off = Math.abs(row.roll - row.angle)
  if (row.angle > 45) return 'Too steep. The wind took it.'
  if (row.angle < 20) return 'Too flat. It dug in early.'
  if (off > 35) return 'It wobbled. Keep the disc flat on its line.'
  if (row.spin < 4) return 'No spin on it. It wandered.'
  if (row.angle >= 30 && row.angle <= 42 && off <= 20) return 'Flat and fast. That one flew.'
  return null
}

function landingLine(row: DiscusThrow, all: DiscusThrow[]): string {
  if (row.foul && row.foulReason === 'sector') return 'Out of the sector. A foul.'
  if (row.foul) return "Into the crowd. They'll live."
  switch (landing(row, all)) {
    case 'hall':
      return 'New mark. Remember that name.'
    case 'phayllos':
      return "Past Phayllos. They'll carve that one."
    default:
      return row.distance >= GOOD ? 'Strong arm.' : 'A gentle toss. The crowd forgives you.'
  }
}

/** The longest landed throw's thrower; a tie goes to whoever threw it first. */
export function champion(poets: Player[], throws: DiscusThrow[]): Player | null {
  let top: DiscusThrow | null = null
  for (const t of throws) {
    if (t.foul || t.distance <= 0) continue
    if (!top || t.distance > top.distance || (t.distance === top.distance && t.id < top.id)) top = t
  }
  return top ? poets.find((p) => p.id === top!.playerId) ?? null : null
}

export function conductDiscus(c: Conductor): void {
  const { room, turn } = c
  const from = c.revealKey
  const poet = turn ? c.poets.find((p) => p.id === turn.playerId) : undefined
  // Entrances as poets check in. No Claude names anyone in discus, so the epithet is the one
  // the phone sent at join, if any. Same keys as poetry's, so nobody is announced twice.
  if (room.phase !== 'speaking') {
    for (const p of c.poets.filter((p) => p.entered)) {
      c.say(`enter ${p.id}`, p.epithet ? `Enter ${p.name}, ${p.epithet}!` : `Enter ${p.name}!`)
    }
  }
  switch (room.phase) {
    case 'ready':
    case 'speaking':
      if (!turn || !poet) return
      // The rules once per hall, not every rematch: auto-start waits for Homer's queue.
      c.say(`discus rules ${room.id}`, RULES)
      c.say(`discus in ${turn.id}`, `${poet.name} steps into the circle.`)
      return
    case 'scored': {
      if (!turn) return
      const row = c.throws.find((t) => t.turnId === turn.id)
      if (row) {
        const ms = flightMs(row.foul ? 0 : row.distance)
        c.perform(`discus flight ${turn.id}`, async () => {
          flights.set(turn.id, { start: Date.now(), ms })
          await sleep(ms)
        })
        c.say(`discus land ${turn.id}`, landingLine(row, c.throws))
        const word = technique(row)
        if (word) c.say(`discus technique ${turn.id}`, word)
        c.perform(`discus landed ${turn.id}`, async () => {
          await sleep(LANDED_MS)
          c.advanceOnce(from)
        })
      } else if (turn.status === 'skipped') {
        c.say(`discus miss ${turn.id}`, 'Out of time. No throw this round.')
        c.perform(`discus missed ${turn.id}`, async () => {
          await sleep(NO_THROW_MS)
          c.advanceOnce(from)
        })
      }
      return
    }
    case 'finale': {
      const winner = champion(c.poets, c.throws)
      const key = `discus champion ${c.battleKey}`
      c.say(key, winner ? `The discus goes to ${winner.name}.` : 'Nothing landed. The discus stays with the gods.')
      c.perform(`${key} hold`, async () => {
        await sleep(CHAMPION_MS)
        c.advanceOnce(from)
      })
      return
    }
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => window.setTimeout(resolve, ms))
}
