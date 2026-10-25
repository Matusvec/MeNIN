// A poet with no app: the phone's job, in the browser (the Safari controller; the judges' fallback and a
// no-install path). Poetry battle and Talk to Homer only. The same reducers and contract as the app
// (spacetime/CONTRACT.md, "Phone"): join_room, enter, update_transcript, play_card, set_prosody, end_turn.
// The arena (in demo rooms, auto_ready) starts each turn; this waits for the turn to be `speaking`, opens the
// mic at the count-in, streams Cartesia STT, and ends the turn at "I'm done" or when the window closes.
// State and logic only; WebPoet.tsx draws it.

import { DbConnection } from '../stdb'
import type { Hand, Player, Room, Round, Score, Turn } from '../stdb/types'
import { AGENT_URL } from '../lib/agent'
import { BrowserMic, type MicFrame } from './mic'
import { BrowserStt, type SttToken } from './stt'

const STDB_URI = import.meta.env.VITE_STDB_URI || 'wss://maincloud.spacetimedb.com'
const STDB_DB = import.meta.env.VITE_STDB_DB || 'homer-calhacks'
const TRANSCRIPT_EVERY_MS = 250 // update_transcript at ~4 Hz, like the app
const TOKEN_KEY = `menin.poet.token.${STDB_DB}` // never the arena's (menin.stdb.token.*): one laptop may run both

export type PoetStage =
  | 'connecting' // reaching the hall
  | 'no-room' // the code isn't an open hall
  | 'name' // pick a name (one tap also opens the mic)
  | 'rejoin' // back after a reload: one tap reopens the mic, same seat
  | 'joining'
  | 'lobby' // in, waiting for Begin
  | 'waiting' // someone else is up
  | 'up-next' // your turn is next: get ready
  | 'count-in' // 3-2-1 (the mic is open)
  | 'speak' // SPEAK: your window
  | 'judging' // your verse is with the judge
  | 'verdict' // your score or Homer's reply
  | 'finished'
  | 'unsupported' // a game this page doesn't play (the motion games need the app)

export type PoetView = {
  stage: PoetStage
  code: string
  event: string
  name: string
  seat: number
  theme: string
  speaker: string // who's up, when it isn't you
  countIn: number | null // 3, 2, 1
  secondsLeft: number | null // in your window
  windowSeconds: number
  words: string // your live transcript
  cards: { text: string; played: boolean }[]
  verdict: string
  total: number | null
  error: string
}

const PLAYED_GAMES = new Set(['poetry', 'coach'])
const LOCK_RETRY_MS = 5000 // a refused wake lock (no gesture, not visible) is asked for again at most this often
const MIC_LOST = 'Your mic stopped: the screen locked, or another app took it.'
const clean = (s: string) => s.toLowerCase().replace(/-/g, ' ').replace(/[^a-z' ]/g, ' ').replace(/\s+/g, ' ').trim()

type Session = {
  key: string // `${turn.id}.${turn.attempt}`
  turnId: bigint
  stt: BrowserStt | null
  ready: Promise<void> | null
  streaming: boolean
  finished: boolean
  offset: number // local ms minus server ms, fixed when the turn was first seen speaking
  played: Set<string>
  sentAt: number
  trailing: number
  prosodyBusy: boolean
  hits: number
}

export class PoetClient {
  private conn: DbConnection | null = null
  private identityHex = ''
  private roomId = 0n
  private subscribed = false
  private mic = new BrowserMic()
  private session: Session | null = null
  private error = ''
  private joining = false
  private lock: WakeLockSentinel | null = null
  private wantLock = false
  private lockTriedAt = 0

  constructor(
    readonly code: string,
    private readonly onView: (view: PoetView) => void,
  ) {}

  get micLevel(): number {
    return this.mic.level
  }

  /** Test halls: what the mic and the STT are doing (headless runs read it). */
  get debug(): Record<string, unknown> {
    const stt = this.session?.stt
    return {
      audio: this.mic.audioState, micFrames: this.mic.frames, level: Math.round(this.mic.level * 100) / 100,
      session: this.session?.key ?? '', streaming: this.session?.streaming ?? false, finished: this.session?.finished ?? false,
      sttOpen: Boolean(stt), sent: stt?.sent ?? 0, received: stt?.received ?? 0, last: stt?.last ?? '', closed: stt?.closed ?? '',
      awake: Boolean(this.lock),
    }
  }

  connect(): void {
    document.addEventListener('visibilitychange', this.onVisibility)
    this.conn = DbConnection.builder()
      .withUri(STDB_URI)
      .withDatabaseName(STDB_DB)
      .withToken(loadToken())
      .withAutomaticReconnect()
      .onConnect((conn, identity, token) => {
        saveToken(token)
        this.identityHex = identity.toHexString()
        const db = conn.db
        for (const table of [db.room, db.player, db.turn, db.round, db.score, db.hand]) {
          table.onInsert(() => this.changed())
          table.onDelete(() => this.changed())
          const updatable = table as unknown as { onUpdate?: (cb: () => void) => void }
          updatable.onUpdate?.(() => this.changed())
        }
        conn.subscriptionBuilder().onApplied(() => this.changed()).subscribe([`SELECT * FROM room WHERE code = '${this.code}'`])
        this.publish()
      })
      .onConnectError((_ctx, error) => {
        this.error = `Can't reach the hall: ${error.message}`
        this.publish()
      })
      .build()
  }

  /** Join with a name. Call from the tap: it also opens the mic (iOS Safari asks from a gesture). */
  async join(name: string): Promise<void> {
    if (!this.conn || this.joining) return
    this.joining = true
    this.error = ''
    this.publish()
    try {
      await this.mic.open()
    } catch {
      this.joining = false
      this.error = 'The mic is off. Allow the microphone for this page, then tap Join again.'
      this.publish()
      return
    }
    this.lockTriedAt = 0
    this.keepAwake(true) // inside the tap, where Safari grants it
    try {
      await this.conn.reducers.joinRoom({ code: this.code, name: name.trim(), epithet: '', hoard: [] })
    } catch (e) {
      this.joining = false
      this.error = e instanceof Error ? e.message : String(e)
      this.publish()
    }
  }

  /** "I'm done": end the turn now. */
  done(): void {
    void this.finish()
  }

  dispose(): void {
    document.removeEventListener('visibilitychange', this.onVisibility)
    this.keepAwake(false)
    this.session?.stt?.close()
    this.mic.close()
    this.conn?.disconnect()
  }

  // Back in front: wake the mic if only its graph slept; a dead track drops to Rejoin (one tap). The browser let
  // go of the wake lock on the way out: publish() asks for it again.
  private readonly onVisibility = (): void => {
    if (document.visibilityState === 'visible') void this.mic.wake().then(() => this.publish())
  }

  /** Keep the screen on while the mic is live (iOS Safari 16.4+): a locked iPhone kills the mic. */
  private keepAwake(want: boolean): void {
    this.wantLock = want
    if (!want) {
      void this.lock?.release().catch(() => {})
      this.lock = null
      return
    }
    if (this.lock || !('wakeLock' in navigator) || document.visibilityState !== 'visible') return
    if (Date.now() - this.lockTriedAt < LOCK_RETRY_MS) return
    this.lockTriedAt = Date.now()
    navigator.wakeLock.request('screen').then(
      (lock) => {
        if (!this.wantLock) return void lock.release().catch(() => {})
        this.lock = lock
        lock.addEventListener('release', () => {
          if (this.lock === lock) this.lock = null
        })
      },
      () => {}, // refused (Low Power Mode, no gesture): the poet keeps the page in front
    )
  }

  // ----- the room ----------------------------------------------------------------

  private room(): Room | null {
    return this.conn ? [...this.conn.db.room.iter()].find((r) => r.code === this.code) ?? null : null
  }

  private me(): Player | undefined {
    if (!this.conn || !this.roomId) return undefined
    return [...this.conn.db.player.iter()].find((p) => p.roomId === this.roomId && p.identity.toHexString() === this.identityHex)
  }

  private changed(): void {
    const room = this.room()
    if (room && !this.subscribed && this.conn) {
      this.subscribed = true
      this.roomId = room.id
      this.conn
        .subscriptionBuilder()
        .onApplied(() => this.changed())
        .subscribe([
          ...['player', 'turn', 'round', 'score'].map((t) => `SELECT * FROM ${t} WHERE room_id = ${room.id}`),
          'SELECT * FROM hand', // the visibility filter returns only this poet's row
        ])
    }
    const me = this.me()
    if (me && this.joining) {
      this.joining = false
      if (!me.entered) this.conn?.reducers.enter({ roomId: me.roomId }).catch(() => {}) // the mic check passed
    }
    if (room && me) this.followTurn(room, me)
    this.publish()
  }

  /** The turn on the floor: prepare the STT when it's ours, stream from the count-in, end at the window's close. */
  private followTurn(room: Room, me: Player): void {
    const turn = this.currentTurn(room)
    const mine = turn && turn.playerId === me.id
    if (!turn || !mine) return
    const key = `${turn.id}.${turn.attempt}`
    if (this.session?.key !== key) {
      if (this.session && !this.session.finished) this.session.stt?.close()
      this.session = {
        key, turnId: turn.id, stt: null, ready: null, streaming: false, finished: false, offset: 0,
        played: new Set(turn.played), sentAt: 0, trailing: 0, prosodyBusy: false, hits: 0,
      }
    }
    const s = this.session!
    if ((turn.status === 'waiting' || turn.status === 'speaking') && !s.ready && !s.finished) s.ready = this.prepare(s, room)
    if (turn.status === 'speaking' && !s.streaming && !s.finished) {
      s.streaming = true
      s.offset = Date.now() - ms(turn.startedAt)
      void s.ready?.then(() => this.stream(s, room))
      const endsLocal = ms(turn.endsAt) + s.offset
      window.setTimeout(() => void this.finish(), Math.max(0, endsLocal - Date.now()))
    }
    if (turn.status !== 'speaking' && turn.status !== 'waiting' && s.streaming && !s.finished) {
      // The window closed on the server's side (the scheduler, or a skip): stop listening.
      s.finished = true
      this.mic.listen(null)
      s.stt?.close()
    }
  }

  /** The STT session for this attempt, opened while the poet is up next (so the first word isn't clipped). */
  private async prepare(s: Session, room: Room): Promise<void> {
    try {
      const res = await fetch(`${AGENT_URL}/voice/token`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ role: 'phone', room_code: this.code }),
      })
      if (!res.ok) throw new Error(`voice token: HTTP ${res.status}`)
      const token = (await res.json()) as SttToken
      const theme = this.currentRound(room)?.theme ?? ''
      const terms = [...this.hand(), ...theme.split(/\s+/).filter((w) => w.length > 3)]
      const stt = new BrowserStt(token, terms, (text) => this.heard(s, text))
      await stt.open()
      if (s.finished) return stt.close()
      s.stt = stt
    } catch (e) {
      this.error = `No live words: ${e instanceof Error ? e.message : String(e)}`
      this.publish()
    }
  }

  /** From the count-in to the end: every mic frame to the STT, and the voice's loudness to the arena's sea. */
  private stream(s: Session, room: Room): void {
    if (s.finished || !s.stt) return
    this.mic.listen((frame: MicFrame) => {
      s.stt?.send(frame.pcm)
      if (frame.onset) s.hits += 1
      if (!s.prosodyBusy && this.conn) {
        s.prosodyBusy = true // at most one in flight (~10 Hz)
        this.conn.reducers
          .setProsody({ roomId: room.id, loudness: frame.loudness, pitch: 0, hits: s.hits })
          .catch(() => {})
          .finally(() => (s.prosodyBusy = false))
      }
    })
  }

  /** The live words: the room's transcript at ~4 Hz, and a card played the moment its words land. */
  private heard(s: Session, text: string): void {
    if (s.finished || !this.conn) return
    const now = Date.now()
    const send = () => {
      s.sentAt = Date.now()
      this.conn?.reducers.updateTranscript({ turnId: s.turnId, transcript: s.stt?.text() ?? text }).catch(() => {})
    }
    window.clearTimeout(s.trailing)
    if (now - s.sentAt >= TRANSCRIPT_EVERY_MS) send()
    else s.trailing = window.setTimeout(send, TRANSCRIPT_EVERY_MS - (now - s.sentAt))
    const said = ` ${clean(text)} `
    for (const card of this.hand()) {
      if (!s.played.has(card) && said.includes(` ${clean(card)} `)) {
        s.played.add(card)
        this.conn.reducers.playCard({ turnId: s.turnId, card }).catch(() => {})
      }
    }
    this.publish()
  }

  /** End this attempt: stop the mic, flush the STT, end_turn with the final words. Once per attempt. */
  private async finish(): Promise<void> {
    const s = this.session
    if (!s || s.finished || !s.streaming) return
    s.finished = true
    this.mic.listen(null)
    window.clearTimeout(s.trailing)
    const transcript = s.stt ? await s.stt.finalize() : ''
    s.stt?.close()
    try {
      await this.conn?.reducers.endTurn({ turnId: s.turnId, transcript })
    } catch {
      // the scheduler closed it first (ends_at + 2 s): the server has the words it was sent
    }
    this.publish()
  }

  // ----- the view ------------------------------------------------------------------

  private currentTurn(room: Room): Turn | undefined {
    return room.currentTurnId ? [...this.conn!.db.turn.iter()].find((t) => t.id === room.currentTurnId) : undefined
  }

  private currentRound(room: Room): Round | undefined {
    return [...this.conn!.db.round.iter()].find((r) => r.roomId === room.id && r.roundNo === room.roundNo)
  }

  private hand(): string[] {
    const me = this.me()
    const h: Hand | undefined = me ? [...this.conn!.db.hand.iter()].find((x) => x.playerId === me.id) : undefined
    return h ? [...h.cards] : []
  }

  private stage(room: Room | null, me: Player | undefined, turn: Turn | undefined): PoetStage {
    if (!this.conn || !this.identityHex) return 'connecting'
    if (!room) return this.subscribed ? 'no-room' : 'connecting'
    if (!PLAYED_GAMES.has(room.event)) return 'unsupported'
    if (!me) return this.joining ? 'joining' : 'name'
    if (!this.mic.isOpen) return this.joining ? 'joining' : 'rejoin'
    if (room.phase === 'finished') return 'finished'
    if (room.phase === 'lobby') return 'lobby'
    const s = this.session
    if (turn && turn.playerId === me.id) {
      if (turn.status === 'waiting') return 'up-next'
      if (turn.status === 'speaking') {
        if (s?.finished) return 'judging'
        return Date.now() < ms(turn.beatAt) + (s?.offset ?? 0) ? 'count-in' : 'speak'
      }
      if (turn.status === 'judging') return 'judging'
      return 'verdict' // scored, declined or skipped: until the next turn takes the floor
    }
    return 'waiting' // (the last verdict rides along in the view)
  }

  publish(): void {
    const room = this.room()
    const me = this.me()
    const turn = room ? this.currentTurn(room) : undefined
    const stage = this.stage(room, me, turn)
    this.keepAwake(this.mic.isOpen && stage !== 'finished')
    const s = this.session
    const offset = s?.offset ?? 0
    const mine = turn && me && turn.playerId === me.id
    const score: Score | undefined = me
      ? [...this.conn!.db.score.iter()].filter((x) => x.playerId === me.id).sort((a, b) => (a.turnId < b.turnId ? 1 : -1))[0]
      : undefined
    const speaker = turn && !mine ? [...this.conn!.db.player.iter()].find((p) => p.id === turn.playerId)?.name ?? '' : ''
    const played = new Set([...(turn && mine ? turn.played : []), ...(s?.played ?? [])])
    this.onView({
      stage,
      code: this.code,
      event: room?.event ?? '',
      name: me?.name ?? '',
      seat: me?.seat ?? 0,
      theme: room ? this.currentRound(room)?.theme ?? '' : '',
      speaker,
      countIn: stage === 'count-in' && turn ? Math.max(1, Math.ceil((ms(turn.beatAt) + offset - Date.now()) / 750)) : null,
      secondsLeft: stage === 'speak' && turn ? Math.max(0, Math.ceil((ms(turn.endsAt) + offset - Date.now()) / 1000)) : null,
      windowSeconds: room?.turnSeconds ?? 20,
      words: mine ? s?.stt?.text() || turn?.transcript || '' : '',
      cards: this.hand().map((text) => ({ text, played: played.has(text) })),
      verdict: score?.verdict ?? '',
      total: score && score.axes.length ? score.total : null,
      error: this.error || (stage === 'rejoin' && this.mic.lost ? MIC_LOST : ''),
    })
  }
}

const ms = (t: { toMillis: () => bigint }) => Number(t.toMillis())

function loadToken(): string | undefined {
  try {
    return localStorage.getItem(TOKEN_KEY) ?? undefined
  } catch {
    return undefined
  }
}

function saveToken(token: string): void {
  try {
    localStorage.setItem(TOKEN_KEY, token)
  } catch {
    // a private window: a new identity next time
  }
}
