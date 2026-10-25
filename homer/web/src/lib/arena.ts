// The browser as the arena (SPEC "The website"): it hosts the room and drives the
// battle, as the Mac app's arena does. A port of ios/Homer/Net/Battle/BattleClient.swift
// (the arena's duties: askAgentIfNeeded, autoStartIfNeeded, the generation, advanceOnce)
// and ios/Homer/Battle/ArenaConductor.swift (speakIfDue: what Homer says, then advance).
//
// One driver per room: never let the Mac arena and a web arena watch the same room,
// or hands get dealt and verses judged twice. All battle state lives in SpacetimeDB.

import { DbConnection } from '../stdb'
import type { Archer, ArrowShot, DiscusThrow, Fight, Fighter, Heat, Player, Prosody, Punch, Range, Room, Round, Runner, Scene as SceneRow, Score, Turn } from '../stdb/types'
import { AGENT_URL, voiceStatus } from './agent'
import { conductDiscus } from './discus'
import { conductStadion } from './stadion'
import { type Bout, conductPygmachia } from './boxing'
import { conductToxeia, type ToxeiaFeed } from './toxeia'
import { Stage } from './stage'
import { HomerVoice } from './voice'

const STDB_URI = import.meta.env.VITE_STDB_URI || 'wss://maincloud.spacetimedb.com'
export const STDB_DB = import.meta.env.VITE_STDB_DB || 'homer-calhacks'

/** create_room's demo preset (spacetime/CONTRACT.md; BattleReducers.swift demoMode). */
// Poetry turns are free verse: the module sets the window (20 s in demo) and bpm/bars no longer time them.
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

export type GameEvent = 'poetry' | 'debate' | 'discus' | 'coach' | 'stadion' | 'pygmachia' | 'toxeia'

/** The field events: no Claude, no verse; Homer only announces, and each has its own panel and conductor. */
export const FIELD_EVENTS: string[] = ['discus', 'stadion', 'pygmachia', 'toxeia']

/** Free-verse turns (a 3-2-1, one SPEAK window, the arena silent): poetry, and coach ("Talk to Homer"). */
export const freeVerse = (event: string): boolean => event === 'poetry' || event === 'coach'

/** The demo's one debate question, our thesis: "Is it cheating to let an AI write your love letter?" */
const DEMO_QUESTION = 'ai-love-letter'

/** One preset per game (BattleReducers.swift preset(event:demo:)): debate is one round, discus three throws each. */
export const PRESETS: Record<GameEvent, typeof DEMO_ROOM> = {
  poetry: DEMO_ROOM,
  debate: { ...DEMO_ROOM, event: 'debate', rounds: 1 },
  discus: { ...DEMO_ROOM, event: 'discus', rounds: 3 },
  coach: { ...DEMO_ROOM, event: 'coach', rounds: 1 }, // Talk to Homer: the module keeps it open until End
  stadion: { ...DEMO_ROOM, event: 'stadion', rounds: 1 }, // the footrace: rounds are heats (demo: one)
  pygmachia: { ...DEMO_ROOM, event: 'pygmachia', rounds: 1 }, // boxing v1: one 60 s fight
  toxeia: { ...DEMO_ROOM, event: 'toxeia', rounds: 1 }, // archery: archers come from the bow phone (next_archer)
}

/** What a game's conductor gets each tick (discus: lib/discus.ts, multiplayer's). */
export type Conductor = {
  room: Room
  poets: Player[]
  turn: Turn | null
  turns: Turn[]
  throws: DiscusThrow[] // this room's discus_throw rows
  heat: Heat | null // stadion: this room's heat row (go_at, cap_at, ended_at)
  runners: Runner[] // stadion: this room's runner rows, any order
  startRace: () => void // stadion: the host's start_race (the race has no turn, so auto-start doesn't apply)
  bout: Bout | null // pygmachia: the fight, fighters and punches, on this browser's clock
  startFight: () => void // pygmachia: the host's start_fight from `ready`
  sayFresh: (key: string, text: string, maxAgeMs: number) => void // a call dropped if it can't start in time
  lastCall: () => number // when the last fresh call was queued
  revealKey: string | null // the reveal on screen now; carries the generation
  battleKey: string // `${room.id}.${generation}`, for once-keys that reset on rematch
  say: (key: string, text: string, then?: () => void) => void // Homer's line, queued, once per key
  perform: (key: string, task: () => Promise<void>) => void // any timed hold, queued with his lines, once per key
  advanceOnce: (from: string | null) => void
} & ToxeiaFeed // toxeia: the range, the archers and their arrows (lib/toxeia.ts, multiplayer's)

const TICK_MS = 300
const FINALE_CAP_MS = 45000 // a finale still on screen this long is advanced (a song + crown is ~20 s): insurance only
const STEP_UP_MS = 2000 // auto-ready: a short beat before each turn starts (debate, discus; and after a reconnect)
// Poetry: ready to SPEAK in about 6 s. The phone warms its mic for MIN_READY_MS of `ready`, and the
// count-in (SPEAK = start_turn + 2.25 s) starts while Homer still has OVERLAP_MS to say, so he ends
// at least 0.75 s before the mic opens.
const MIN_READY_MS = 1500
const OVERLAP_MS = 1500
const QUEUE_CAP_MS = 15000 // auto-start waits for Homer's line at most this long
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
  turns: Turn[] // this room's turns in order (Talk to Homer's conversation log)
  scores: Score[]
  song: string[]
  line: string // what Homer is saying now
  speaking: boolean
  error: string
  resumable: Room | null // an unfinished room this browser hosts, after a reload
  throws: DiscusThrow[]
  heat: Heat | null // stadion
  runners: Runner[] // stadion, any order (the panel sorts)
  bout: Bout | null // pygmachia
  prosody: Prosody | null // this room's row: a thrower's wind-up (hits 1, loudness = power), a speaker's level
  warming: boolean // Homer's next line is on its way from the voice, not yet heard
  carvedBy: string // the poet whose line the round carved
  sound: boolean // the hall was started with a click: voice and drum are on
  comeback: { name: string; secondsLeft: number } | null // waiting for a poet's phone to come back, counting down
  voiceNote: string // the operator corner: why Homer is on text ("Voice credits out", "Voice offline"), or ''
} & ToxeiaFeed

/** The verdict the agent posts when the judge never answered (homer/homer/judge.py SILENT_VERDICT): the
 *  score is a neutral fallback, not a judgment, and the scorecard says so. */
export const SILENT_VERDICT = 'Homer is silent on this one.'

export const EMOTIONS = ['anger', 'grief', 'joy', 'awe', 'tenderness', 'fear', 'defiance', 'longing'] as const
export type Emotion = (typeof EMOTIONS)[number]

/** What the painted sea behind the battle draws from (scene/SceneBackdrop's props). Units as in spacetime/CONTRACT.md. */
export type SceneFeed = {
  emotion: Record<Emotion, number> | null // the room's scene row, raw weights 0–1, ~every 1.5 s; null rests
  energy: number // 0–1: the live speaker's loudness (~20 Hz, 100–200 ms behind), a breath while Homer talks
  pitch: number | null // Hz while voiced
  hits: number // poetry: voice onsets this turn (no beat in battles); each rise flashes a strike
  turnKey: string // a new turn starts a new hit count
}

export const QUIET_SCENE: SceneFeed = { emotion: null, energy: 0, pitch: null, hits: 0, turnKey: '' }
const HOMER_ENERGY = 0.15 // the sea breathes with Homer; he has no level of his own here
// A voice onset, for the sea's strike flash: the speaker's loudness rises past HIGH after dipping under LOW.
const ONSET_HIGH = 0.35
const ONSET_LOW = 0.2
const VOICE_REST_MS = 10000 // after the voice fails, Homer stays on text this long before trying again
const CREDITS_REST_MS = 60000 // ... and this long when Cartesia says the credits are out

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
  // Archery's tables, apart and only while the room's event is toxeia: a hall without them (prod before the
  // module ships there) never subscribes, and a set_event switch tears it down and sets it up.
  private toxSub: { roomId: bigint; sub: { unsubscribe: () => void } } | null = null
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
  private pending = 0 // lines and performances queued or running
  private lineEndsAt: number | null = null // a text-only line's end (a voiced line's end comes from the voice)
  private line = ''
  private speaking = false
  private warming = false
  private status: ArenaView['status'] = 'connecting'
  private error = ''
  // W2: Homer's voice and the drum, once a click has unlocked audio
  private voice: HomerVoice | null = null
  private stage: Stage | null = null
  private voiceDownUntil = 0 // Homer is on text until then
  private voiceNote = ''
  private comeback: { turnId: bigint; name: string; until: number } | null = null // the absent poet the arena waits for
  private skipWait = false // the operator pressed Skip
  private finaleSince: { key: string; at: number; done: boolean } | null = null
  private prosodyListeners = new Set<() => void>() // the backdrop, told the moment a prosody frame lands
  private heardEntrance = new Set<bigint>() // poets whose "Enter X, epithet!" was spoken in this hall
  private punchSeen = new Map<bigint, number>() // punch id -> when it arrived here
  private fightClock: { go: number; offset: number } | null = null // server go_at -> this browser's clock
  private lastFreshCall = 0
  private onsets = { turn: 0n, count: 0, armed: true } // the live verse's voice onsets

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
  connect(attempt = 1): void {
    const locks = (navigator as Navigator & { locks?: LockManager }).locks
    if (!locks) {
      this.open()
      return
    }
    void locks.request(`menin-arena-${STDB_DB}`, { ifAvailable: true }, (lock) => {
      // An arena disposed before the lock arrived (a remount; React StrictMode in dev) lets it go at once.
      if (this.disposed) return
      if (!lock) {
        // A remount's old arena lets go within milliseconds; another tab holds on. Ask again, briefly.
        if (attempt < 4) window.setTimeout(() => !this.disposed && this.connect(attempt + 1), 500)
        else {
          this.status = 'other-tab'
          this.publish()
        }
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
        db.prosody.onUpdate((_ctx, _old, row) => {
          this.countOnset(row)
          for (const listener of this.prosodyListeners) listener()
          if (this.room()?.event === 'discus') this.publish()
        })
        // Boxing: each punch's arrival on this browser's clock, so the arm, the hit and Homer's call line up.
        db.punch.onInsert((_ctx, row) => {
          if (!this.punchSeen.has(row.id)) this.punchSeen.set(row.id, Date.now())
        })
        // The fighters' aim and guard stream ~20 Hz: re-render only in a fight (like discus's wind-up).
        db.fighter.onUpdate(() => {
          if (this.room()?.event === 'pygmachia') this.publish()
        })
        for (const table of [db.room, db.player, db.round, db.turn, db.score, db.songLine, db.discusThrow, db.heat, db.runner, db.fight, db.fighter, db.punch, db.range, db.archer, db.arrowShot]) {
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
    this.side('', 0) // load the debate's questions and sides now, before any call-up needs them
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

  private disposed = false
  private sceneRow: SceneRow | null = null
  private sceneWeights: Record<Emotion, number> | null = null

  disconnect(): void {
    this.disposed = true
    window.clearTimeout(this.watchdog)
    window.clearInterval(this.ticker)
    this.releaseLock?.()
    this.stage?.stopBeat()
    this.voice?.close()
    this.roomSub?.unsubscribe()
    this.dropToxeia()
    this.conn?.disconnect()
    this.conn = null
  }

  // ----- the arena's reducers ---------------------------------------------------

  createRoom(event: GameEvent = 'poetry'): void {
    if (!this.conn) return
    this.awaitingCreated = true
    this.call(() => this.conn!.reducers.createRoom(PRESETS[event]))
  }

  resume(room: Room): void {
    this.watch(room.id)
  }

  startBattle(): void {
    this.call(() => this.conn!.reducers.startBattle({ roomId: this.roomId }))
  }

  /** Talk to Homer never ends on its own: the host closes it (end_battle → finished). */
  endConversation(): void {
    this.call(() => this.conn!.reducers.endBattle({ roomId: this.roomId }))
  }

  /** "New event" (SPEC: the hall stays open): the room switches games and returns to the lobby with the poets
   *  still joined (set_event, from lobby or finished). The phones follow room.event; the conductors and the
   *  archery subscription follow it on the next tick. */
  setEvent(event: GameEvent): void {
    this.call(() => this.conn!.reducers.setEvent({ roomId: this.roomId, event, rounds: PRESETS[event].rounds }))
  }

  rematch(): void {
    this.newBattle()
    this.lastPhaseSeen = null // already counted; don't count finished → dealing again
    this.call(() => this.conn!.reducers.rematch({ roomId: this.roomId }))
  }

  /** The reveal on screen now. An advance is valid only from the reveal it was meant for. */
  private revealKey(): string | null {
    const room = this.room()
    if (!room) return null
    const key = `${room.id}.${this.generation} ${room.phase} ${room.roundNo} ${room.currentTurnId}`
    if (room.event !== 'toxeia') return key
    // Archery has no turns, and an archer's three arrows share a round: each arrow is its own reveal.
    const range = [...this.conn!.db.range.iter()].find((r) => r.roomId === room.id)
    return range ? `${key} ${range.archerId}.${range.arrowNo}` : key
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
      ['player', 'round', 'turn', 'score', 'scene', 'song_line', 'prosody', 'discus_throw', 'heat', 'runner', 'fight', 'fighter', 'punch'].map((t) => `SELECT * FROM ${t} WHERE room_id = ${id}`),
    )
    this.roomSub = this.conn.subscriptionBuilder().onApplied(() => this.changed()).subscribe(queries)
    this.dropToxeia()
  }

  /** Archery's subscription follows the room's event (see toxSub). Errors are ignored: a hall without the tables. */
  private followToxeia(room: Room): void {
    if (room.event !== 'toxeia' || room.id !== this.roomId) return this.dropToxeia()
    if (!this.conn || this.toxSub?.roomId === room.id) return
    this.dropToxeia()
    const sub = this.conn
      .subscriptionBuilder()
      .onApplied(() => this.changed())
      .onError(() => {})
      .subscribe(['range', 'archer', 'arrow_shot'].map((t) => `SELECT * FROM ${t} WHERE room_id = ${room.id}`))
    this.toxSub = { roomId: room.id, sub }
  }

  private dropToxeia(): void {
    if (!this.toxSub) return
    try {
      this.toxSub.sub.unsubscribe()
    } catch {
      // never applied (a hall without the tables): nothing to drop
    }
    this.toxSub = null
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
    this.followToxeia(room)
    this.autoStartIfNeeded(room)
    this.askAgentIfNeeded(room)
    if (room.event === 'discus') conductDiscus(this.conductor(room))
    else if (room.event === 'stadion') conductStadion(this.conductor(room))
    else if (room.event === 'pygmachia') conductPygmachia(this.conductor(room))
    else if (room.event === 'toxeia') conductToxeia(this.conductor(room))
    else this.speakIfDue(room)
    if (room.event === 'debate') this.debateClock(room)
    this.finaleBackstop(room)
  }

  /** A finale that never advances (a stuck line, a missing song) moves on after FINALE_CAP_MS, by the clock. */
  private finaleBackstop(room: Room): void {
    if (room.phase !== 'finale') {
      this.finaleSince = null
      return
    }
    const key = `${room.id}.${this.generation}`
    if (this.finaleSince?.key !== key) this.finaleSince = { key, at: Date.now(), done: false }
    else if (!this.finaleSince.done && Date.now() - this.finaleSince.at > FINALE_CAP_MS) {
      this.finaleSince.done = true
      this.advanceOnce()
    }
  }

  private conductor(room: Room): Conductor {
    return {
      room,
      poets: this.poets(),
      turn: this.currentTurn(room),
      turns: this.turns(),
      throws: this.throws(),
      heat: this.heat(),
      runners: this.runners(),
      startRace: () => this.call(() => this.conn!.reducers.startRace({ roomId: room.id })),
      bout: this.bout(),
      ...this.toxeia(),
      startFight: () => this.call(() => this.conn!.reducers.startFight({ roomId: room.id })),
      sayFresh: (key, text, maxAgeMs) => this.sayFresh(key, text, maxAgeMs),
      lastCall: () => this.lastFreshCall,
      revealKey: this.revealKey(),
      battleKey: `${room.id}.${this.generation}`,
      say: (key, text, then) => this.say(key, text, then),
      perform: (key, task) => this.perform(task, key),
      advanceOnce: (from) => this.advanceOnce(from),
    }
  }

  /** This room's range, archers and arrows (archery); empty in any other event. */
  private toxeia(): ToxeiaFeed {
    const db = this.conn!.db
    if (this.room()?.event !== 'toxeia') return { range: null, archers: [], arrows: [] }
    return {
      range: [...db.range.iter()].find((r: Range) => r.roomId === this.roomId) ?? null,
      archers: [...db.archer.iter()].filter((a: Archer) => a.roomId === this.roomId),
      arrows: [...db.arrowShot.iter()].filter((s: ArrowShot) => s.roomId === this.roomId),
    }
  }

  private throws(): DiscusThrow[] {
    return [...this.conn!.db.discusThrow.iter()].filter((t) => t.roomId === this.roomId)
  }

  /** The fight on this browser's clock. The server's go_at is start_fight + 3 s, so first sight of a new
   *  go_at fixes the offset (good to a network one-way trip, like the turn clock). */
  private bout(): Bout | null {
    const db = this.conn!.db
    const fight: Fight | undefined = [...db.fight.iter()].find((f) => f.roomId === this.roomId)
    const names = new Map(this.poets().map((p) => [p.id, p.name]))
    const fighters = [...db.fighter.iter()]
      .filter((f: Fighter) => f.roomId === this.roomId)
      .sort((a, b) => a.seat - b.seat)
      .map((f) => ({
        id: f.playerId, name: names.get(f.playerId) ?? 'Fighter', seat: f.seat, hp: f.health, guard: f.guard,
        yaw: f.aimYaw, pitch: f.aimPitch, stamina: f.stamina, combo: f.combo,
      }))
    const goMs = fight ? Number(fight.goAt.toMillis()) : 0
    if (goMs > 0 && this.fightClock?.go !== goMs) this.fightClock = { go: goMs, offset: Date.now() - (goMs - 3000) }
    const local = (ms: number) => (ms > 0 && this.fightClock ? ms + this.fightClock.offset : null)
    const punches = [...db.punch.iter()]
      .filter((p: Punch) => p.roomId === this.roomId)
      .sort((a, b) => (a.id < b.id ? -1 : 1))
      .map((p) => ({
        id: String(p.id), from: p.playerId, to: p.targetId, kind: p.kind, zone: p.zone, power: p.power, yaw: p.aimYaw,
        result: p.result, damage: p.damage, counter: p.counter, combo: p.combo, at: this.punchSeen.get(p.id) ?? 0,
      }))
    return {
      fighters,
      punches,
      goAt: local(goMs),
      endsAt: fight ? local(Number(fight.endsAt.toMillis())) : null,
      ended: Boolean(fight && Number(fight.endedAt.toMillis()) > 0),
      endedAt: fight ? local(Number(fight.endedAt.toMillis())) : null,
      ko: Boolean(fight?.ko),
      winnerId: fight?.winnerId ?? 0n,
    }
  }

  private heat(): Heat | null {
    return [...this.conn!.db.heat.iter()].find((h) => h.roomId === this.roomId) ?? null
  }

  private runners(): Runner[] {
    return [...this.conn!.db.runner.iter()].filter((r) => r.roomId === this.roomId)
  }

  // ----- debate ------------------------------------------------------------------

  private debate: { ask: string; id: string; sides: string[] }[] | null = null
  private debateAsked = false
  private clockOffset = new Map<string, number>() // turn attempt -> this browser's offset from the server clock

  /** This browser's offset from the server clock, estimated once as the turn goes live (the phones do the same). */
  private offsetFor(turn: Turn): number {
    const key = `${turn.id}-${turn.attempt}`
    if (!this.clockOffset.has(key)) this.clockOffset.set(key, Date.now() - Number(turn.startedAt.toMillis()))
    return this.clockOffset.get(key)!
  }

  /** The side a debater argues: by turn order (DebateContent.swift side(for:turnNo:)). */
  private side(question: string, turnNo: number): string {
    if (!this.debate && !this.debateAsked) {
      this.debateAsked = true
      void fetch(`${AGENT_URL}/debate`)
        .then((r) => r.json())
        .then((d: { questions: { ask: string; id: string; sides: string[] }[] }) => (this.debate = d.questions))
        .catch(() => (this.debateAsked = false))
    }
    const q = this.debate?.find((x) => x.ask === question || x.id === question)
    return q && q.sides.length >= 2 ? q.sides[turnNo % 2] : ''
  }

  /** No beat in debate. Socrates is silent but for the ten-second call (ArenaConductor.tick). */
  private debateClock(room: Room): void {
    const turn = this.currentTurn(room)
    if (!turn || turn.status !== 'speaking' || turn.endsAt.toMillis() === 0n) return
    const endsLocal = Number(turn.endsAt.toMillis()) + this.offsetFor(turn)
    if (Date.now() >= endsLocal - 10000) this.say(`ten ${turn.id} ${turn.attempt}`, 'Ten seconds.')
  }

  /** A voice onset in the live verse (the sea's strike flash, now that battles have no beat to hit). */
  private countOnset(p: Prosody): void {
    if (p.roomId !== this.roomId || p.turnId === 0n) return
    if (this.onsets.turn !== p.turnId) this.onsets = { turn: p.turnId, count: 0, armed: true }
    if (this.onsets.armed && p.loudness > ONSET_HIGH) {
      this.onsets.count += 1
      this.onsets.armed = false
    } else if (p.loudness < ONSET_LOW) this.onsets.armed = true
  }

  /** The live verse's window on this browser's clock, for the arena's 3-2-1, SPEAK and clock. Poetry only:
   *  SPEAK at beat_at, Time at ends_at; "I'm done" on the phone ends the turn (and this) early. */
  verseWindow(): { key: string; startMs: number; endMs: number } | null {
    const room = this.disposed ? null : this.room()
    const turn = room && this.currentTurn(room)
    if (!room || !turn || !freeVerse(room.event) || turn.status !== 'speaking') return null
    if (turn.beatAt.toMillis() === 0n || turn.endsAt.toMillis() === 0n) return null
    const offset = this.offsetFor(turn)
    return {
      key: `${turn.id}-${turn.attempt}`,
      startMs: Number(turn.beatAt.toMillis()) + offset,
      endMs: Number(turn.endsAt.toMillis()) + offset,
    }
  }

  /** The stitched song on the drum: a fresh grid, each line spoken as its line begins. */
  private async singOnBeat(room: Room, song: string[]): Promise<void> {
    if (!this.stage || !this.voice) return
    const beatMs = 60000 / Math.max(room.bpm, 1)
    const lineMs = beatMs * 4 // one line a bar: the rest bar is for poets drawing breath, not for Homer
    const beatAt = Date.now() + 300 + beatMs * 4 // after a count-in bar
    const gen = this.generation
    // Next in the finale (or a rematch) ends the song at the line it's on.
    const over = () => gen !== this.generation || this.room()?.phase !== 'finale'
    this.stage.playBeat({ beatAtLocalMs: beatAt, bpm: room.bpm, barsPerLine: 1, lines: song.length })
    try {
      for (const [i, text] of song.entries()) {
        await sleep(Math.max(0, beatAt + lineMs * i - 250 - Date.now()))
        if (over()) return
        this.line = text
        this.publish()
        await this.voiced(text).catch(() => this.hold(Math.min(readingTime(text), lineMs - 250), gen)) // text keeps to the bar
      }
      if (!over()) await sleep(Math.max(0, beatAt + lineMs * song.length - Date.now()))
    } finally {
      this.stage.stopBeat()
    }
  }

  /** Bumped each time this room starts over, so per-battle work (deals, the song) is asked again. */
  private trackGeneration(room: Room): void {
    if (this.lastPhaseSeen === 'finished' && room.phase !== 'finished') this.newBattle()
    this.lastPhaseSeen = room.phase
  }

  /** A rematch: the last battle's lines are dropped, and Homer stops mid-line (the crown after a skipped song). */
  private newBattle(): void {
    this.generation += 1
    this.voice?.hush()
  }

  /** Hold for `ms`, or less if the battle moves on. */
  private async hold(ms: number, gen: number): Promise<void> {
    const end = Date.now() + ms
    while (Date.now() < end && gen === this.generation) await sleep(Math.min(100, end - Date.now()))
  }

  /** auto_ready rooms (always on in demo): start each turn after a short step-up beat. */
  private autoStartIfNeeded(room: Room): void {
    const turn = this.currentTurn(room)
    if (!room.autoReady || room.phase !== 'ready' || !turn || turn.status !== 'waiting') return
    if (room.event === 'toxeia') return // the bow phone's next_archer starts each archer
    const key = `${turn.id}-${turn.attempt}`
    if (this.autoStarted === key) return
    this.autoStarted = key
    // Every wait here is capped by the clock, not by counting sleeps: a hidden tab's timers are throttled.
    const poetry = freeVerse(room.event)
    const overlap = poetry ? OVERLAP_MS : 0 // other events keep the count-in after Homer's last word
    const homerDone = async () => {
      const cap = Date.now() + QUEUE_CAP_MS
      while (Date.now() < cap && this.homerLeftMs() > overlap) await sleep(100)
    }
    void (async () => {
      await sleep(poetry ? MIN_READY_MS : STEP_UP_MS)
      // His voice never meets an open mic (docs/ux-flow.md T1): the count-in may overlap his last words only.
      await homerDone()
      // A poet reopening the app gets up to 20 s (capped: a phone that never comes back can't stall the battle;
      // the turn goes ahead and the timer skips it).
      let away = false
      const giveUp = Date.now() + COMEBACK_MS
      this.skipWait = false
      while (Date.now() < giveUp && !this.skipWait && this.poets().find((p) => p.id === turn.playerId)?.connected === false) {
        if (!away) {
          away = true
          this.comeback = { turnId: turn.id, name: this.poets().find((p) => p.id === turn.playerId)?.name ?? 'the poet', until: giveUp }
        }
        this.publish() // the countdown never looks frozen
        await sleep(500)
      }
      this.comeback = null
      this.publish()
      if (this.skipWait) return // the operator skipped the turn (skipComeback): nothing to start
      // A phone that just came back must see `ready` before `speaking`, or it takes the turn for one it
      // reopened mid-verse and stays silent (Matus's WMCN attempt 2 started 0.19 s after he reconnected).
      if (away && this.poets().find((p) => p.id === turn.playerId)?.connected) {
        await sleep(STEP_UP_MS)
        await homerDone()
      }
      const now = this.room()
      const current = now && this.currentTurn(now)
      if (current?.id === turn.id && current.status === 'waiting') {
        this.call(() => this.conn!.reducers.startTurn({ turnId: turn.id }))
      }
    })()
  }

  /** The operator's Skip while the arena waits for an absent poet: the turn is skipped now, not 20 s later. */
  skipComeback(): void {
    const wait = this.comeback
    if (!wait) return
    this.skipWait = true
    this.call(() => this.conn!.reducers.skipTurn({ turnId: wait.turnId }))
  }

  /** Battle work from the agent when the phase calls for it, once per step; results arrive by subscription. */
  private askAgentIfNeeded(room: Room): void {
    if (FIELD_EVENTS.includes(room.event)) return // no Claude in the field events
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
      case 'dealing': {
        const theme = room.nextTheme || (room.event === 'debate' && room.demo ? DEMO_QUESTION : '')
        once(`deal ${battle} ${room.roundNo}`, () => this.deal(room.id, room.roundNo, theme))
        return
      }
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
            ...(room.event === 'debate'
              ? {
                  side: this.side(this.currentRound(room)?.theme ?? '', turn.turnNo),
                  turnSeconds: room.turnSeconds,
                  // beat_at (Go) to now, the moment the turn reached judging, capped at the turn
                  spokenSeconds: Math.min(room.turnSeconds, Math.max(0, (Date.now() - (this.clockOffset.get(`${turn.id}-${turn.attempt}`) ?? 0) - Number(turn.beatAt.toMillis())) / 1000)),
                }
              : {}),
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

  /** A call that only makes sense right now (a punch): queued like any line, dropped if it can't start in time. */
  private sayFresh(key: string, text: string, maxAgeMs: number): void {
    if (this.said.has(key) || !text) return
    this.said.add(key)
    const gen = this.generation
    const queued = Date.now()
    this.lastFreshCall = queued
    this.pending += 1
    this.queue = this.queue.then(async () => {
      try {
        if (Date.now() - queued > maxAgeMs) return // the action moved on: never over the action
        await this.sayNow(gen, text)
      } finally {
        this.pending -= 1
        this.lineEndsAt = null
      }
    })
  }

  private say(key: string, text: string, then?: () => void): void {
    if (this.said.has(key) || !text) return
    this.said.add(key)
    const gen = this.generation
    this.pending += 1
    this.queue = this.queue.then(async () => {
      try {
        // An entrance still queued when the battle starts is stale: Begin cuts the lobby short.
        if (key.startsWith('enter ') && this.room()?.phase !== 'lobby') return
        await this.sayNow(gen, text, then)
        if (key.startsWith('enter ')) this.heardEntrance.add(BigInt(key.slice('enter '.length)))
      } finally {
        this.pending -= 1
        this.lineEndsAt = null
      }
    })
  }

  private async sayNow(gen: number, text: string, then?: () => void): Promise<void> {
    // A line from a battle that's over (Next in the finale, then Rematch) is dropped, not read late.
    if (gen !== this.generation) return
    // Homer is silent while a verse is live: a line still queued when the count-in starts is dropped.
    const now = this.room()
    if (now && freeVerse(now.event) && now.phase === 'speaking') return then?.()
    this.line = text
    this.speaking = true
    this.publish()
    // The voice never holds a reveal hostage: at most the read time plus 4 s, then the battle moves on.
    const host = this.room()?.event === 'debate' ? 'socrates' : 'homer'
    if (this.voice && this.voiceUp()) {
      this.warming = true
      this.publish()
      const heard = () => {
        this.warming = false
        this.publish()
      }
      const fallback = () => {
        heard() // no voice coming: the line is up as text, nothing is "about to speak"
        this.lineEndsAt = Date.now() + readingTime(text)
        return this.hold(readingTime(text), gen)
      }
      await Promise.race([this.voiced(text, heard, host).catch(fallback), this.hold(readingTime(text) + 4000, gen)])
      this.warming = false
    } else {
      this.lineEndsAt = Date.now() + readingTime(text)
      await this.hold(readingTime(text), gen)
    }
    this.speaking = false
    this.publish()
    if (gen !== this.generation) return // hushed by a rematch: the old battle's `then` (an advance) is void
    then?.()
  }

  /** How long Homer still has to talk: 0 when he's quiet, Infinity while a line is arriving or more wait. */
  private homerLeftMs(): number {
    if (this.pending === 0) return 0
    if (this.pending > 1 || !this.speaking) return Infinity
    if (this.lineEndsAt !== null) return Math.max(0, this.lineEndsAt - Date.now())
    return this.voice?.remainingMs() ?? Infinity
  }

  /** Homer's voice, or a throw while it rests. A failure asks the agent why (credits out?) and rests it a while,
   *  so a spent account costs each line nothing: the callers fall back to text and the battle moves on. */
  private async voiced(text: string, onStart?: () => void, host: 'homer' | 'socrates' = 'homer'): Promise<void> {
    if (!this.voice || !this.voiceUp()) throw new Error('voice resting')
    try {
      await this.voice.speak(text, onStart, host)
    } catch (error) {
      if (!(error instanceof Error && ['one generation at a time', 'hushed'].includes(error.message))) this.voiceFailed()
      throw error
    }
    if (this.voiceNote) {
      this.voiceNote = ''
      this.publish()
    }
  }

  private voiceUp(): boolean {
    return Date.now() >= this.voiceDownUntil
  }

  private voiceFailed(): void {
    if (!this.voiceUp()) return // resting already, and already asked why
    this.voiceDownUntil = Date.now() + VOICE_REST_MS
    void voiceStatus().then((s) => {
      this.voiceNote = s.voice === 'out' ? 'Voice credits out' : s.voice === 'ok' ? '' : 'Voice offline'
      if (s.voice === 'out') this.voiceDownUntil = Date.now() + CREDITS_REST_MS
      this.publish()
    })
  }

  /** Queue any performance behind Homer's lines, one at a time (once per key, when given one). */
  private perform(task: () => Promise<void>, key?: string): void {
    if (key) {
      if (this.said.has(key)) return
      this.said.add(key)
    }
    const gen = this.generation
    this.pending += 1
    this.queue = this.queue.then(async () => {
      try {
        if (gen === this.generation) await this.performNow(task)
      } finally {
        this.pending -= 1
      }
    })
  }

  private async performNow(task: () => Promise<void>): Promise<void> {
    this.speaking = true
    this.publish()
    await task().catch(() => {})
    this.speaking = false
    this.publish()
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
        if (room.event === 'coach') return this.coachCallUp(round, turn, poet, poets.length)
        // The theme once, as the round opens. Then P21: the round's first poet gets the theme's call,
        // every later poet answers the line before, and a retry is just "Again." The theme and the first
        // call-up are one line: one trip to the voice, so the count-in starts sooner.
        const opening = !this.said.has(`theme ${round.id}`)
        if (opening) this.said.add(`theme ${round.id}`)
        const theme = opening ? `${round.theme.trim()}${/[.!?]$/.test(round.theme.trim()) ? '' : '.'} ` : ''
        const first = turn.turnNo === Math.min(...this.turns().filter((t) => t.roundId === round.id).map((t) => t.turnNo))
        // The epithet once per hall: at the entrance, or here if the entrance was cut short (Begin in the lobby).
        const heard = this.heardEntrance.has(poet.id)
        const title = poet.epithet && !heard ? `${poet.name}, ${poet.epithet}.` : `${poet.name}.`
        const side = room.event === 'debate' ? this.side(round.theme, turn.turnNo) : ''
        const call =
          turn.attempt > 1 ? 'Again.'
          : side ? (first ? `${title} You argue ${side}.` : `${poet.name}, you argue ${side}. Answer that.`)
          : first ? `${title} ${this.calls.get(room.roundNo) ?? 'The floor is yours.'}`
          : `${poet.name}. Answer that.`
        this.say(`up ${turn.id} ${turn.attempt}`, theme + call)
        return
      }
      case 'scored': {
        if (!turn) return
        const score = [...this.conn!.db.score.iter()].find((s) => s.turnId === turn.id)
        if (score) this.say(`verdict ${turn.id}`, score.verdict || SILENT_VERDICT, advance)
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
        // A battle where every turn was skipped has no song and no champion: close it and move on.
        const sung = this.turns().some((t) => t.status === 'scored')
        if (!sung) return this.say(key, 'No verse tonight, so no song. The hall is still open.', advance)
        if (!song.length || this.said.has(key)) return
        this.said.add(key)
        const champion = [...poets].sort((a, b) => b.total - a.total)[0]
        if (room.event === 'poetry' && this.voice && this.stage) this.perform(() => this.singOnBeat(room, song))
        else song.forEach((text, i) => this.say(`${key} line ${i}`, text))
        if (champion) {
          const crown = `${champion.name}${champion.epithet ? `, ${champion.epithet}` : ''}. The hall is yours.`
          this.say(`${key} crown`, crown, advance)
        } else advance?.()
        return
      }
    }
  }

  /** Talk to Homer: the opening once per conversation, then only names (2+ poets) or "Again." Homer's
   *  replies are the verdicts (scored). The opening matches the agent's opening_line (homer/homer/arena.py),
   *  so what Homer said and what he remembers saying agree. */
  private coachCallUp(round: Round, turn: Turn, poet: Player, poets: number): void {
    const key = `up ${turn.id} ${turn.attempt}`
    if (turn.attempt > 1) return this.say(key, 'Again.')
    if (!this.said.has(`theme ${round.id}`)) {
      this.said.add(`theme ${round.id}`)
      const t = round.theme.trim().replace(/\.$/, '')
      const opening = t ? `Give me a verse about ${t.slice(0, 1).toLowerCase()}${t.slice(1)}.` : 'Give me a verse.'
      return this.say(key, poets > 1 ? `${opening} ${poet.name}, you first.` : opening)
    }
    if (poets > 1) this.say(key, `${poet.name}.`)
  }

  private carvedBy(room: Room): string {
    const round = this.currentRound(room)
    const turn = round?.bestTurnId ? this.turns().find((t) => t.id === round.bestTurnId) : undefined
    return turn ? this.poets().find((p) => p.id === turn.playerId)?.name ?? '' : ''
  }

  private songLines(): string[] {
    return [...this.conn!.db.songLine.iter()]
      .filter((l) => l.roomId === this.roomId)
      .sort((a, b) => a.lineNo - b.lineNo)
      .map((l) => l.text)
  }

  // ----- the view ---------------------------------------------------------------

  /** Call `listener` on every prosody frame (~20 Hz), so the scene answers a syllable at once. */
  onProsody(listener: () => void): () => void {
    this.prosodyListeners.add(listener)
    return () => this.prosodyListeners.delete(listener)
  }

  /** The backdrop's inputs, cheap enough to read 20 times a second: one prosody row and one scene row. */
  sceneFeed(): SceneFeed {
    const room = this.disposed ? null : this.room()
    const breath = this.speaking ? HOMER_ENERGY : 0
    // The lobby rests (light Aegean); Homer's entrances still breathe.
    if (!room || room.phase === 'lobby') return breath ? { ...QUIET_SCENE, energy: breath } : QUIET_SCENE
    const turn = this.currentTurn(room)
    const p = turn ? [...this.conn!.db.prosody.iter()].find((r) => r.roomId === room.id && r.turnId === turn.id) : undefined
    const live = room.phase === 'speaking' && p
    // The weights stay on the row between turns, so a verse's colors hold through its verdict.
    const s = [...this.conn!.db.scene.iter()].find((r) => r.roomId === room.id) ?? null
    if (s !== this.sceneRow) {
      this.sceneRow = s // the SDK hands a new row object per update: same object, same feeling
      this.sceneWeights = s ? (Object.fromEntries(EMOTIONS.map((e) => [e, s[e]])) as Record<Emotion, number>) : null
    }
    return {
      emotion: this.sceneWeights,
      energy: live ? p.loudness : breath,
      pitch: live && p.pitch > 0 ? p.pitch : null,
      // Build 19+ phones count loud syllables in prosody.hits; older ones send 0, so fall back to our onsets.
      hits:
        room.event === 'discus' ? (p?.hits ?? 0)
        : p && p.hits > 0 ? p.hits
        : turn && this.onsets.turn === turn.id ? this.onsets.count
        : 0,
      turnKey: String(turn?.id ?? ''),
    }
  }

  private publish(): void {
    if (this.disposed) return
    const room = this.room()
    const hosted = this.hostedRooms().sort((a, b) => (a.id < b.id ? 1 : -1))[0] ?? null
    this.onView({
      status: this.status,
      room,
      poets: room ? this.poets() : [],
      round: room ? this.currentRound(room) : null,
      turn: room ? this.currentTurn(room) : null,
      turns: room ? this.turns().sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0)) : [],
      scores: room ? [...this.conn!.db.score.iter()].filter((s) => s.roomId === this.roomId) : [],
      song: room ? this.songLines() : [],
      line: this.line,
      speaking: this.speaking,
      error: this.error,
      resumable: !room && hosted ? hosted : null,
      throws: room ? this.throws() : [],
      heat: room ? this.heat() : null,
      runners: room ? this.runners() : [],
      bout: room?.event === 'pygmachia' ? this.bout() : null,
      ...(room ? this.toxeia() : { range: null, archers: [], arrows: [] }),
      prosody: room ? [...this.conn!.db.prosody.iter()].find((p) => p.roomId === this.roomId) ?? null : null,
      warming: this.warming,
      carvedBy: room ? this.carvedBy(room) : '',
      sound: Boolean(this.stage),
      voiceNote: this.voiceNote,
      comeback: this.comeback ? { name: this.comeback.name, secondsLeft: Math.max(0, Math.ceil((this.comeback.until - Date.now()) / 1000)) } : null,
    })
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => window.setTimeout(resolve, ms))
}
