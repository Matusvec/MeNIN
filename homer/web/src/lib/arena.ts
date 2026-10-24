// The browser as the arena (SPEC "The website"): it hosts the room and drives the
// battle, as the Mac app's arena does. A port of ios/Homer/Net/Battle/BattleClient.swift
// (the arena's duties: askAgentIfNeeded, autoStartIfNeeded, the generation, advanceOnce)
// and ios/Homer/Battle/ArenaConductor.swift (speakIfDue: what Homer says, then advance).
//
// One driver per room: never let the Mac arena and a web arena watch the same room,
// or hands get dealt and verses judged twice. All battle state lives in SpacetimeDB.

import { DbConnection } from '../stdb'
import type { Player, Room, Round, Score, Turn } from '../stdb/types'
import { AGENT_URL } from './agent'
import { Stage } from './stage'
import { HomerVoice } from './voice'

const STDB_URI = import.meta.env.VITE_STDB_URI || 'wss://maincloud.spacetimedb.com'
export const STDB_DB = import.meta.env.VITE_STDB_DB || 'homer-calhacks'

/** create_room's demo preset (spacetime/CONTRACT.md; BattleReducers.swift demoMode). */
export const DEMO_ROOM = {
  event: 'poetry',
  rounds: 1,
  barsPerLine: 2,
  linesPerTurn: 2,
  bpm: 80,
  form: 'four_beat',
  autoReady: true,
  themeChoice: false,
  demo: true,
}

const TICK_MS = 300
const STEP_UP_MS = 2000 // auto-ready: a short beat before each turn starts
const COMEBACK_MS = 20000 // a poet reopening the app gets this long to come back
const ADVANCE_AFTER_MS = 500 // after Homer's line, before the next reveal
const CONNECT_WATCHDOG_MS = 15000 // a connect that hangs never errors; give up and offer a retry
// Races the server already refuses safely (a phone's Ready tap vs auto-start; an advance that
// another caller won): nothing to show on the big screen.
const QUIET = [/this turn is not up/i, /cannot advance from/i]

export type ArenaView = {
  status: 'connecting' | 'connected' | 'offline' | 'other-tab'
  room: Room | null
  poets: Player[]
  round: Round | null
  turn: Turn | null
  scores: Score[]
  song: string[]
  line: string // what Homer is saying now
  speaking: boolean
  error: string
  resumable: Room | null // an unfinished room this browser hosts, after a reload
  sound: boolean // the hall was started with a click: voice and drum are on
}

/** Text only: hold each line long enough to read it, briskly. With the voice, the line's own length rules. */
export function readingTime(text: string): number {
  const words = text.split(/\s+/).filter(Boolean).length
  return Math.min(4000, 1500 + words * 250)
}

function tokenKey(): string {
  return `menin.stdb.token.${STDB_DB}`
}

function loadToken(): string | undefined {
  try {
    return localStorage.getItem(tokenKey()) ?? undefined
  } catch {
    return undefined
  }
}

function saveToken(token: string): void {
  try {
    localStorage.setItem(tokenKey(), token)
  } catch {
    /* private window: a new identity next time, which only loses the resume */
  }
}

async function postAgent(path: string, body: unknown): Promise<unknown> {
  const res = await fetch(`${AGENT_URL}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body, (_key, value) => (typeof value === 'bigint' ? Number(value) : value)),
  })
  if (!res.ok) {
    const detail = await res.json().then((b) => b?.detail, () => '')
    throw new Error(`${path}: ${detail || `HTTP ${res.status}`}`)
  }
  return res.json()
}

export class Arena {
  private conn: DbConnection | null = null
  private identityHex = ''
  private roomId: bigint = 0n
  private roomSub: { unsubscribe: () => void } | null = null
  private awaitingCreated = false
  private ticker = 0
  // BattleClient's arena duties
  private generation = 0
  private lastPhaseSeen: string | null = null
  private asked = new Set<string>()
  private autoStarted = ''
  private advancedFrom = new Set<string>()
  // ArenaConductor
  private said = new Set<string>()
  private calls = new Map<number, string>() // round_no -> Homer's call-up, from /battle/deal
  private queue: Promise<void> = Promise.resolve()
  private line = ''
  private speaking = false
  private status: ArenaView['status'] = 'connecting'
  private error = ''
  // W2: Homer's voice and the drum, once a click has unlocked audio
  private voice: HomerVoice | null = null
  private stage: Stage | null = null
  private beatFor = ''
  private lastHits = { turn: 0n, hits: 0 }

  constructor(private onView: (view: ArenaView) => void) {}

  /** "Start the hall": call from a click, so the browser lets the page play sound. */
  startSound(): void {
    if (this.stage) return
    const ctx = new AudioContext()
    void ctx.resume()
    this.stage = new Stage(ctx)
    this.voice = new HomerVoice(ctx)
    this.publish()
  }

  // ----- connection -------------------------------------------------------------

  /**
   * One tab drives the hall: two tabs share the token, so both would be the host and both
   * would drive. Holds a Web Lock for as long as this arena lives; without one, it only shows.
   */
  connect(): void {
    const locks = (navigator as Navigator & { locks?: LockManager }).locks
    if (!locks) {
      this.open()
      return
    }
    void locks.request(`menin-arena-${STDB_DB}`, { ifAvailable: true }, (lock) => {
      if (!lock) {
        this.status = 'other-tab'
        this.publish()
        return
      }
      this.open()
      return new Promise<void>((release) => (this.releaseLock = release))
    })
  }

  private releaseLock: (() => void) | null = null
  private watchdog = 0

  private open(): void {
    window.clearTimeout(this.watchdog)
    this.watchdog = window.setTimeout(() => {
      if (this.status !== 'connecting') return
      this.status = 'offline'
      this.error = "Can't reach the hall. Try again."
      this.publish()
    }, CONNECT_WATCHDOG_MS)
    this.conn = DbConnection.builder()
      .withUri(STDB_URI)
      .withDatabaseName(STDB_DB)
      .withToken(loadToken())
      .withAutomaticReconnect()
      .onAutomaticReconnect((_conn, _identity, token) => {
        saveToken(token)
        this.status = 'connected'
        this.error = ''
        this.publish()
      })
      .onConnect((conn, identity, token) => {
        saveToken(token)
        this.identityHex = identity.toHexString()
        this.status = 'connected'
        // Rooms are found by host because reducers can't return values.
        conn.subscriptionBuilder().subscribe(`SELECT * FROM room WHERE host = 0x${this.identityHex}`)
        const db = conn.db
        for (const table of [db.room, db.player, db.round, db.turn, db.score, db.songLine]) {
          table.onInsert(() => this.changed())
          table.onDelete(() => this.changed())
          const updatable = table as unknown as { onUpdate?: (cb: () => void) => void }
          updatable.onUpdate?.(() => this.changed())
        }
        this.publish()
      })
      .onConnectError((_ctx, error, nextAttempt) => {
        this.status = 'offline'
        // A failed automatic reconnect will be retried: the screen just says "Reconnecting…".
        this.error = nextAttempt === undefined ? `Can't reach the hall: ${error.message}` : ''
        this.publish()
      })
      .onDisconnect(() => {
        this.status = 'offline' // the SDK reconnects by itself; onAutomaticReconnect brings it back
        this.publish()
      })
      .build()
    window.clearInterval(this.ticker)
    this.ticker = window.setInterval(() => this.tick(), TICK_MS)
  }

  /** After the watchdog gave up: try again from scratch. */
  retry(): void {
    this.conn?.disconnect()
    this.conn = null
    this.roomSub = null
    this.status = 'connecting'
    this.error = ''
    this.publish()
    this.open()
  }

  disconnect(): void {
    window.clearTimeout(this.watchdog)
    window.clearInterval(this.ticker)
    this.releaseLock?.()
    this.stage?.stopBeat()
    this.voice?.close()
    this.roomSub?.unsubscribe()
    this.conn?.disconnect()
    this.conn = null
  }

  // ----- the arena's reducers ---------------------------------------------------

  createRoom(): void {
    if (!this.conn) return
    this.awaitingCreated = true
    this.call(() => this.conn!.reducers.createRoom(DEMO_ROOM))
  }

  resume(room: Room): void {
    this.watch(room.id)
  }

  startBattle(): void {
    this.call(() => this.conn!.reducers.startBattle({ roomId: this.roomId }))
  }

  rematch(): void {
    this.generation += 1
    this.lastPhaseSeen = null // already counted; don't count finished → dealing again
    this.call(() => this.conn!.reducers.rematch({ roomId: this.roomId }))
  }

  /** The reveal on screen now. An advance is valid only from the reveal it was meant for. */
  private revealKey(): string | null {
    const room = this.room()
    return room ? `${room.id}.${this.generation} ${room.phase} ${room.roundNo} ${room.currentTurnId}` : null
  }

  /** Advances once per reveal, however many callers ask. */
  advanceOnce(from: string | null = null): void {
    const key = this.revealKey()
    const phase = this.room()?.phase
    if (!key || (from !== null && from !== key) || this.advancedFrom.has(key) || phase === 'finished' || phase === 'lobby') return
    this.advancedFrom.add(key)
    this.call(() => this.conn!.reducers.advance({ roomId: this.roomId }))
  }

  private call(work: () => Promise<void>): void {
    if (!this.conn) return
    this.error = ''
    work().catch((error: unknown) => {
      const message = error instanceof Error ? error.message : String(error)
      if (QUIET.some((quiet) => quiet.test(message))) return
      this.error = message
      this.publish()
    })
  }

  private watch(id: bigint): void {
    if (!this.conn || (id === this.roomId && this.roomSub)) return
    this.roomSub?.unsubscribe()
    this.roomId = id
    const queries = [`SELECT * FROM room WHERE id = ${id}`].concat(
      ['player', 'round', 'turn', 'score', 'scene', 'song_line', 'prosody'].map((t) => `SELECT * FROM ${t} WHERE room_id = ${id}`),
    )
    this.roomSub = this.conn.subscriptionBuilder().onApplied(() => this.changed()).subscribe(queries)
  }

  // ----- derived state ----------------------------------------------------------

  private room(): Room | null {
    if (!this.conn || !this.roomId) return null
    return [...this.conn.db.room.iter()].find((r) => r.id === this.roomId) ?? null
  }

  private poets(): Player[] {
    return [...this.conn!.db.player.iter()].filter((p) => p.roomId === this.roomId).sort((a, b) => a.seat - b.seat)
  }

  private currentRound(room: Room): Round | null {
    return [...this.conn!.db.round.iter()].find((r) => r.roomId === this.roomId && r.roundNo === room.roundNo) ?? null
  }

  private turns(): Turn[] {
    return [...this.conn!.db.turn.iter()].filter((t) => t.roomId === this.roomId)
  }

  private currentTurn(room: Room): Turn | null {
    return room.currentTurnId ? this.turns().find((t) => t.id === room.currentTurnId) ?? null : null
  }

  private hostedRooms(): Room[] {
    if (!this.conn || !this.identityHex) return []
    return [...this.conn.db.room.iter()].filter((r) => r.host.toHexString() === this.identityHex && r.phase !== 'finished')
  }

  // ----- the loop ---------------------------------------------------------------

  private changed(): void {
    if (this.awaitingCreated) {
      const newest = this.hostedRooms().sort((a, b) => (a.id < b.id ? 1 : -1))[0]
      if (newest && newest.id > this.roomId) {
        this.awaitingCreated = false
        this.watch(newest.id)
      }
    }
    this.publish()
  }

  private tick(): void {
    const room = this.room()
    if (!room || this.status !== 'connected') return
    this.trackGeneration(room)
    this.autoStartIfNeeded(room)
    this.askAgentIfNeeded(room)
    this.speakIfDue(room)
    this.drum(room)
  }

  /** The beat on the turn's grid while a verse is live, and a strike per hit (ArenaConductor.tick). */
  private drum(room: Room): void {
    if (!this.stage) return
    const turn = this.currentTurn(room)
    if (room.event !== 'poetry' || !turn || turn.status !== 'speaking' || turn.beatAt.toMillis() === 0n) {
      if (this.beatFor && !this.singing) {
        this.beatFor = ''
        this.stage.stopBeat()
      }
      return
    }
    const key = `${turn.id}-${turn.attempt}`
    if (this.beatFor !== key) {
      this.beatFor = key
      // This browser's offset from the server clock, estimated as the turn goes live.
      const offset = Date.now() - Number(turn.startedAt.toMillis())
      this.stage.playBeat({
        beatAtLocalMs: Number(turn.beatAt.toMillis()) + offset,
        bpm: room.bpm,
        barsPerLine: room.barsPerLine,
        lines: room.linesPerTurn,
      })
    }
    const prosody = [...this.conn!.db.prosody.iter()].find((p) => p.roomId === this.roomId && p.turnId === turn.id)
    if (prosody) {
      if (this.lastHits.turn !== turn.id) this.lastHits = { turn: turn.id, hits: 0 }
      if (prosody.hits > this.lastHits.hits) {
        this.stage.strike()
        this.lastHits.hits = prosody.hits
      }
    }
  }

  private singing = false

  /** The stitched song on the drum: a fresh grid, each line spoken as its line begins. */
  private async singOnBeat(room: Room, song: string[]): Promise<void> {
    if (!this.stage || !this.voice) return
    const beatMs = 60000 / Math.max(room.bpm, 1)
    const lineMs = beatMs * 4 // one line a bar: the rest bar is for poets drawing breath, not for Homer
    const beatAt = Date.now() + 300 + beatMs * 4 // after a count-in bar
    this.singing = true
    this.stage.playBeat({ beatAtLocalMs: beatAt, bpm: room.bpm, barsPerLine: 1, lines: song.length })
    try {
      for (const [i, text] of song.entries()) {
        await sleep(Math.max(0, beatAt + lineMs * i - 250 - Date.now()))
        this.line = text
        this.publish()
        await this.voice.speak(text).catch(() => sleep(readingTime(text)))
      }
      await sleep(Math.max(0, beatAt + lineMs * song.length - Date.now()))
    } finally {
      this.stage.stopBeat()
      this.singing = false
    }
  }

  /** Bumped each time this room starts over, so per-battle work (deals, the song) is asked again. */
  private trackGeneration(room: Room): void {
    if (this.lastPhaseSeen === 'finished' && room.phase !== 'finished') this.generation += 1
    this.lastPhaseSeen = room.phase
  }

  /** auto_ready rooms (always on in demo): start each turn after a short step-up beat. */
  private autoStartIfNeeded(room: Room): void {
    const turn = this.currentTurn(room)
    if (!room.autoReady || room.phase !== 'ready' || !turn || turn.status !== 'waiting') return
    const key = `${turn.id}-${turn.attempt}`
    if (this.autoStarted === key) return
    this.autoStarted = key
    void (async () => {
      await sleep(STEP_UP_MS)
      // The count-in waits until Homer finishes his call (docs/ux-flow.md T1), so his voice never meets an open mic.
      await this.queue
      // A poet reopening the app gets up to 20 s (capped: a stale `connected = false` can't stall the battle).
      for (let waited = 0; waited < COMEBACK_MS; waited += 500) {
        if (this.poets().find((p) => p.id === turn.playerId)?.connected !== false) break
        await sleep(500)
      }
      const now = this.room()
      const current = now && this.currentTurn(now)
      if (current?.id === turn.id && current.status === 'waiting') {
        this.call(() => this.conn!.reducers.startTurn({ turnId: turn.id }))
      }
    })()
  }

  /** Battle work from the agent when the phase calls for it, once per step; results arrive by subscription. */
  private askAgentIfNeeded(room: Room): void {
    if (room.event === 'discus') return // discus has no Claude
    const quietly = (key: string, work: () => Promise<unknown>) => {
      if (this.asked.has(key)) return
      this.asked.add(key)
      work().catch(() => {})
    }
    const once = (key: string, work: () => Promise<unknown>) => {
      if (this.asked.has(key)) return
      this.asked.add(key)
      work().catch(async (error: unknown) => {
        this.error = error instanceof Error ? error.message : String(error)
        this.publish()
        await sleep(2000)
        this.asked.delete(key) // then retry
      })
    }
    for (const poet of this.poets().filter((p) => !p.named)) {
      once(`poet ${poet.id}`, () => postAgent('/battle/poet', { playerId: poet.id }))
    }
    const battle = `${room.id}.${this.generation}`
    switch (room.phase) {
      case 'speaking': {
        // The scene's color layer: about every 1.5 s while a verse is live.
        const turn = this.currentTurn(room)
        if (!turn || !turn.transcript) return
        const prosody = [...this.conn!.db.prosody.iter()].find((p) => p.roomId === this.roomId && p.turnId === turn.id)
        const tick = Math.floor(Date.now() / 1500)
        quietly(`emotion ${turn.id} ${tick}`, () =>
          postAgent('/battle/emotion', {
            turnId: turn.id,
            transcript: turn.transcript,
            loudness: prosody?.loudness ?? null,
            pitch: prosody && prosody.pitch > 0 ? prosody.pitch : null,
          }),
        )
        return
      }
      case 'dealing':
        once(`deal ${battle} ${room.roundNo}`, () => this.deal(room.id, room.roundNo, room.nextTheme))
        return
      case 'scored': {
        // The round's last verdict is on screen: have the agent work out the round's call now,
        // so round_end posts it at once (it's posted only in round_end).
        const round = this.currentRound(room)
        const turns = round ? this.turns().filter((t) => t.roundId === round.id) : []
        const done = turns.length > 0 && turns.every((t) => ['scored', 'skipped', 'declined'].includes(t.status))
        if (round && done) quietly(`verdict ahead ${round.id}`, () => postAgent('/battle/verdict', { roundId: round.id }))
        return
      }
      case 'round_end': {
        const round = this.currentRound(room)
        if (round) once(`verdict ${round.id}`, () => postAgent('/battle/verdict', { roundId: round.id }))
        // The song: pre-stitched after round 1, final after the last round.
        if (room.roundNo === 1 || room.roundNo === room.rounds) {
          once(`song ${battle} ${room.roundNo}`, () => postAgent('/battle/song', { roomId: room.id }))
        }
        // Deal the next round ahead, so the next turn is ready the moment the verdict ends.
        if (room.roundNo < room.rounds && !room.themeChoice) {
          once(`deal ${battle} ${room.roundNo + 1}`, () => this.deal(room.id, room.roundNo + 1, ''))
        }
        return
      }
      case 'judging': {
        const turn = this.currentTurn(room)
        const poet = turn && this.poets().find((p) => p.id === turn.playerId)
        if (!turn || turn.status !== 'judging' || !poet) return
        const previous = this.turns().find((t) => t.roundId === turn.roundId && t.turnNo + 1 === turn.turnNo)?.transcript ?? ''
        once(`judge ${turn.id} ${turn.attempt}`, () =>
          postAgent('/battle/judge', {
            turnId: turn.id,
            playerId: poet.id,
            transcript: turn.transcript,
            event: room.event,
            form: room.form,
            theme: this.currentRound(room)?.theme ?? '',
            played: turn.played,
            rescues: turn.rescues,
            previous,
            linesExpected: room.linesPerTurn,
            hoard: poet.hoard,
            demo: room.demo,
          }),
        )
        return
      }
    }
  }

  private async deal(roomId: bigint, roundNo: number, theme: string): Promise<void> {
    const dealt = (await postAgent('/battle/deal', { roomId, roundNo, theme })) as { call?: string }
    if (dealt.call) this.calls.set(roundNo, dealt.call)
  }

  // ----- Homer (ArenaConductor.speakIfDue) -------------------------------------

  private say(key: string, text: string, then?: () => void): void {
    if (this.said.has(key) || !text) return
    this.said.add(key)
    this.queue = this.queue.then(async () => {
      this.line = text
      this.speaking = true
      this.publish()
      // The voice never holds a reveal hostage: at most the read time plus 4 s, then the battle moves on.
      if (this.voice) await Promise.race([this.voice.speak(text).catch(() => sleep(readingTime(text))), sleep(readingTime(text) + 4000)])
      else await sleep(readingTime(text))
      this.speaking = false
      this.publish()
      then?.()
    })
  }

  /** Queue any performance behind Homer's lines, one at a time. */
  private perform(task: () => Promise<void>): void {
    this.queue = this.queue.then(async () => {
      this.speaking = true
      this.publish()
      await task().catch(() => {})
      this.speaking = false
      this.publish()
    })
  }

  private speakIfDue(room: Room): void {
    if (room.phase === 'speaking') return
    const from = this.revealKey()
    const advance = room.autoReady
      ? () => {
          window.setTimeout(() => this.advanceOnce(from), ADVANCE_AFTER_MS)
        }
      : undefined
    const poets = this.poets()
    for (const poet of poets.filter((p) => p.entered && p.named)) {
      this.say(`enter ${poet.id}`, poet.epithet ? `Enter ${poet.name}, ${poet.epithet}!` : `Enter ${poet.name}!`)
    }
    const turn = this.currentTurn(room)
    switch (room.phase) {
      case 'ready': {
        const round = this.currentRound(room)
        const poet = turn && poets.find((p) => p.id === turn.playerId)
        if (!round || !turn || !poet) return
        // The theme once, as the round opens. Then P21: the round's first poet gets the theme's call,
        // every later poet answers the line before, and a retry is just "Again."
        this.say(`theme ${round.id}`, round.theme)
        const first = turn.turnNo === Math.min(...this.turns().filter((t) => t.roundId === round.id).map((t) => t.turnNo))
        const title = poet.epithet ? `${poet.name}, ${poet.epithet}.` : `${poet.name}.`
        const call =
          turn.attempt > 1 ? 'Again.'
          : first ? `${title} ${this.calls.get(room.roundNo) ?? 'The floor is yours.'}`
          : `${poet.name}. Answer that.`
        this.say(`up ${turn.id} ${turn.attempt}`, call)
        return
      }
      case 'scored': {
        if (!turn) return
        const score = [...this.conn!.db.score.iter()].find((s) => s.turnId === turn.id)
        if (score) this.say(`verdict ${turn.id}`, score.verdict || 'Homer is silent on this one.', advance)
        else if (turn.status === 'declined') this.say(`verdict ${turn.id}`, 'Not in my hall.', advance)
        else if (turn.status === 'skipped') this.say(`verdict ${turn.id}`, 'The hall waited. No verse came.', advance)
        return
      }
      case 'round_end': {
        const round = this.currentRound(room)
        if (round?.verdict) this.say(`round ${round.id}`, round.verdict, advance)
        return
      }
      case 'finale': {
        const song = this.songLines()
        const key = `song ${room.id}.${this.generation} ${room.roundNo}`
        if (!song.length || this.said.has(key)) return
        this.said.add(key)
        const champion = [...poets].sort((a, b) => b.total - a.total)[0]
        if (this.voice && this.stage) this.perform(() => this.singOnBeat(room, song))
        else song.forEach((text, i) => this.say(`${key} line ${i}`, text))
        if (champion) {
          const crown = `${champion.name}${champion.epithet ? `, ${champion.epithet}` : ''}. The hall is yours.`
          this.say(`${key} crown`, crown, advance)
        } else advance?.()
        return
      }
    }
  }

  private songLines(): string[] {
    return [...this.conn!.db.songLine.iter()]
      .filter((l) => l.roomId === this.roomId)
      .sort((a, b) => a.lineNo - b.lineNo)
      .map((l) => l.text)
  }

  // ----- the view ---------------------------------------------------------------

  private publish(): void {
    const room = this.room()
    const hosted = this.hostedRooms().sort((a, b) => (a.id < b.id ? 1 : -1))[0] ?? null
    this.onView({
      status: this.status,
      room,
      poets: room ? this.poets() : [],
      round: room ? this.currentRound(room) : null,
      turn: room ? this.currentTurn(room) : null,
      scores: room ? [...this.conn!.db.score.iter()].filter((s) => s.roomId === this.roomId) : [],
      song: room ? this.songLines() : [],
      line: this.line,
      speaking: this.speaking,
      error: this.error,
      resumable: !room && hosted ? hosted : null,
      sound: Boolean(this.stage),
    })
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => window.setTimeout(resolve, ms))
}
