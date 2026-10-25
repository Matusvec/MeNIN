// The arena screen (SPEC "The website"): the room code and QR, the lobby and
// entrances, the live verse, the verdict and scores, the carved line, the champion.
// The battle itself runs in lib/arena.ts; this only shows it. Read from 2 m: the
// styles (wired.css) are artist's; this sets the hooks they hang on.

import { useCallback, useEffect, useMemo, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import QRCode from 'qrcode'
import CoachPanel from './Coach'
import DiscusPanel from './Discus'
import StadionPanel from './Stadion'
import BoxingPanel from './Boxing'
import ToxeiaPanel from './Toxeia'
import { Arena, FIELD_EVENTS, QUIET_SCENE, SILENT_VERDICT, STDB_DB, type ArenaView, type GameEvent, type SceneFeed } from './lib/arena'
import { webJoinLink } from './lib/links'
import type { SceneTheme } from './scene/moods'
import SceneBackdrop from './scene/SceneBackdrop'
import TailVerse, { type WordMark } from './TailVerse'
import './wired.css'
import { useMusic } from './music'

const FEED_MS = 50 // the phones send prosody at ~20 Hz

/** artist's painted sea (src/scene/), behind the page. It reads the driver at prosody rate on its own,
 *  so a speaker's voice moves the sea without re-rendering the arena. */
function Backdrop({
  feed,
  subscribe,
  theme,
  word,
}: {
  feed: () => SceneFeed
  subscribe: (listener: () => void) => () => void
  theme: SceneTheme
  word: WordMark | null
}) {
  const [scene, setScene] = useState(feed)
  useEffect(() => {
    const pull = () => {
      const next = feed()
      setScene((was) =>
        was.emotion === next.emotion && was.energy === next.energy && was.pitch === next.pitch && was.hits === next.hits && was.turnKey === next.turnKey
          ? was
          : next,
      )
    }
    const stop = subscribe(pull) // a syllable reaches the sea the moment its prosody frame lands
    const id = window.setInterval(pull, FEED_MS)
    return () => {
      stop()
      window.clearInterval(id)
    }
  }, [feed, subscribe])
  return <SceneBackdrop {...scene} theme={theme} word={word} />
}

// Each rubric's bars in display order, as [label, index into score.axes]; score.axes keeps
// homer/homer/events.py's order (poetry: beat, craft, image, answer, range). A poetry battle is
// judged on content only (Image x4, Answer x4, Craft x2 = /100): Flow and Range aren't shown.
const AXES: Record<string, Array<[string, number]>> = {
  poetry: [['Image', 2], ['Answer', 3], ['Craft', 1]],
  debate: [['Claim', 0], ['Reason', 1], ['Answer', 2], ['Craft', 3], ['Poise', 4]],
}

// One ink per seat, so a poet keeps their color all battle (ios/Homer/UI/Tokens.swift Palette.seats, Atelier).
const SEAT_INKS = ['#2D5C66', '#C8452C', '#A8741F', '#5B3F73', '#6E7A2E'] // sea, vermilion, gold, plum; olive for a 5th (= the phone's Palette.seats)
const GAMES: Array<[GameEvent, string]> = [
  ['poetry', 'Poetry battle'],
  ['coach', 'Talk to Homer'],
  ['debate', 'Socratic debate'],
  ['discus', 'Discus'],
  ['stadion', 'Stadion'],
  ['pygmachia', 'Pygmachia (beta)'], // live for Matus's first real fights (build 20); scripted runs follow
  ['toxeia', 'Toxeia (beta)'], // module on prod 18:20; a scripted run passed 18:34 (2 archers, 6 arrows); Matus's real runs next
]

const PHASES: Record<string, string> = {
  lobby: 'Scan the code with the MeNIN app, or type it in',
  theme: 'The judges pick a theme',
  dealing: 'Dealing the hands',
  ready: 'Step up',
  speaking: 'The floor is theirs',
  judging: 'Weighing it',
  scored: 'The verdict',
  round_end: 'The round is called',
  finale: 'The finale, then the crown',
  finished: 'The hall is yours',
}

function useQr(text: string): string {
  const [svg, setSvg] = useState('')
  useEffect(() => {
    if (!text) return
    QRCode.toString(text, { type: 'svg', margin: 1, color: { dark: '#334b5bff', light: '#00000000' } })
      .then(setSvg)
      .catch(() => setSvg(''))
  }, [text])
  return svg
}

/** Every wait over ~300 ms says what it's waiting for, in plain words (Matus: "so I know it's not glitched"). */
function waitingFor(view: ArenaView | null): string {
  if (!view || view.status === 'connecting') return 'Opening the hall…'
  if (view.status === 'offline') return 'Reconnecting…'
  if (view.status === 'other-tab') return ''
  const room = view.room
  const host = room?.event === 'debate' ? 'Socrates' : 'Homer'
  if (view.comeback) return `Waiting for ${view.comeback.name} to come back… ${view.comeback.secondsLeft}`
  if (view.warming) return `${host} is about to speak`
  if (!room) return ''
  const speaker = view.turn ? view.poets.find((p) => p.id === view.turn!.playerId) : undefined
  switch (room.phase) {
    case 'speaking':
      return speaker && room.event !== 'discus' ? `${speaker.name} is speaking` : ''
    case 'lobby':
      return view.poets.length < (room.event === 'coach' ? 1 : 2) ? 'Waiting for poets — scan to join' : ''
    case 'dealing':
      return `${host} is dealing…`
    case 'judging':
      return room.event === 'debate' ? 'Socrates is weighing the argument…' : room.event === 'discus' ? '' : room.event === 'coach' ? 'Homer is answering…' : 'Homer is weighing the verse…'
    case 'round_end':
      return !FIELD_EVENTS.includes(room.event) && !view.round?.verdict ? 'Calling the round…' : ''
    case 'finale':
      if (FIELD_EVENTS.includes(room.event) || view.song.length) return ''
      return room.event === 'debate' ? 'Socrates finds the last question…' : 'Stitching the song…'
    default:
      return ''
  }
}

/** A line of verse with the played formulas marked, for the gold underline. */
function withFormulas(line: string, played: string[]): ReactNode {
  const phrases = played.map((p) => p.trim()).filter(Boolean)
  if (!phrases.length) return line
  const escaped = phrases.map((p) => p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/[-\s]+/g, '[-\\s]+'))
  const parts = line.split(new RegExp(`(${escaped.join('|')})`, 'i'))
  return parts.map((part, i) => (i % 2 ? <mark className="formula" key={i}>{part}</mark> : part))
}

export default function ArenaPanel({
  onLine,
  onSpeaking,
  onStatus,
  onPhase,
}: {
  onLine: (line: string) => void
  onSpeaking: (speaking: boolean) => void
  onStatus: (status: string) => void
  /** The room's phase and event, for Homer's pose (null before a room exists). */
  onPhase?: (phase: string | null, event: string | null) => void
}) {
  const [view, setView] = useState<ArenaView | null>(null)
  const arena = useRef<Arena | null>(null)
  const goneSince = useRef(new Map<bigint, number>()) // poet id -> when we first saw them disconnected
  const feed = useCallback(() => arena.current?.sceneFeed() ?? QUIET_SCENE, [])
  const verseWindow = useCallback(() => arena.current?.verseWindow() ?? null, [])
  const subscribe = useCallback((listener: () => void) => arena.current?.onProsody(listener) ?? (() => {}), [])
  const [word, setWord] = useState<WordMark | null>(null)
  const [picking, setPicking] = useState(false) // "New event": the event picker is open
  const onWord = useCallback((next: WordMark | null) => {
    setWord((was) => (was === next || (was && next && was.n === next.n && was.x === next.x && was.y === next.y) ? was : next))
  }, [])
  useEffect(() => {
    // Dev server only: read the backdrop's feed from the console (window.sceneFeed()).
    if (import.meta.env.DEV) (window as unknown as { sceneFeed?: () => SceneFeed }).sceneFeed = feed
  }, [feed])
  const [, tick] = useState(0)
  // GPU watch: Homer's 3D view and the sea are two WebGL canvases. A lost context (GPU pressure) is reported
  // in the operator corner; three.js restores Homer's itself, and the sea yields (stops) rather than compete.
  // Context events don't bubble, so listen in the capture phase.
  const [glNote, setGlNote] = useState('')
  useEffect(() => {
    let clear = 0
    const who = (e: Event) => ((e.target as Element | null)?.classList?.contains('menin-scene') ? 'The sea' : "Homer's 3D view")
    const lost = (e: Event) => {
      console.warn('MeNIN GPU: context lost:', who(e))
      window.clearTimeout(clear)
      setGlNote(`${who(e)} lost the GPU`)
    }
    const restored = (e: Event) => {
      console.warn('MeNIN GPU: context restored:', who(e))
      setGlNote(`${who(e)} is back`)
      clear = window.setTimeout(() => setGlNote(''), 5000)
    }
    window.addEventListener('webglcontextlost', lost, true)
    window.addEventListener('webglcontextrestored', restored, true)
    return () => {
      window.clearTimeout(clear)
      window.removeEventListener('webglcontextlost', lost, true)
      window.removeEventListener('webglcontextrestored', restored, true)
    }
  }, [])

  useEffect(() => {
    const a = new Arena(setView)
    arena.current = a
    a.connect()
    return () => a.disconnect()
  }, [])

  useEffect(() => {
    if (view?.line) onLine(view.line)
  }, [view?.line, onLine])
  useEffect(() => {
    onSpeaking(Boolean(view?.speaking))
  }, [view?.speaking, onSpeaking])
  // Matus's theme (src/music.ts): ducked under Homer's voice; in the spoken games, out from the
  // count-in through the verdict, so the Mac's speakers never reach a phone's mic.
  const spokenGame = ['poetry', 'debate', 'coach'].includes(view?.room?.event ?? '')
  useMusic({
    hush: spokenGame && ['ready', 'speaking', 'judging', 'scored'].includes(view?.room?.phase ?? ''),
    duck: Boolean(view?.speaking), // the bed in lobbies and results, ducked only under Homer (leader overrides SPEC's "demo stays ducked")
  })
  // A poet's phone that drops for a moment shows nothing; "away" only after 3 s gone.
  const anyGone = Boolean(view?.poets.some((p) => !p.connected))
  useEffect(() => {
    if (!anyGone) return
    const id = window.setInterval(() => tick((n) => n + 1), 1000)
    return () => window.clearInterval(id)
  }, [anyGone])
  const away = (id: bigint, connected: boolean): boolean => {
    if (connected) {
      goneSince.current.delete(id)
      return false
    }
    if (!goneSince.current.has(id)) goneSince.current.set(id, Date.now())
    return Date.now() - goneSince.current.get(id)! > 3000
  }
  const status = waitingFor(view)
  useEffect(() => {
    onStatus(status)
  }, [status, onStatus])
  useEffect(() => {
    onPhase?.(view?.room?.phase ?? null, view?.room?.event ?? null)
  }, [view?.room?.phase, view?.room?.event, onPhase])

  const room = view?.room ?? null
  const qr = useQr(room ? webJoinLink(room.code) : '') // a page that opens MeNIN, or points to TestFlight
  const score = useMemo(
    () => (view?.turn ? view.scores.find((s) => s.turnId === view.turn!.id) ?? null : null),
    [view?.turn, view?.scores],
  )

  // The sea is the first child of every screen that shows it, so React keeps one canvas from the
  // opening screen into the battle. Poetry, debate and coach rooms; discus keeps its own field.
  const event = view?.room?.event
  const sceneTheme: SceneTheme = view?.room?.phase !== 'lobby' && (event === 'debate' || event === 'coach') ? event : 'poetry'
  const live = view?.room && ['speaking', 'judging'].includes(view.room.phase)
  const backdrop = <Backdrop feed={feed} subscribe={subscribe} theme={sceneTheme} word={live ? word : null} />

  if (!view || view.status === 'connecting') {
    return (
      <>
        {backdrop}
        <div className="arena" data-phase="none">
          <Heading kicker="The hall" title="Opening the doors…" note="" />
        </div>
      </>
    )
  }

  if (view.status === 'other-tab') {
    return (
      <div className="arena" data-phase="none">
        <Heading kicker="The hall" title="The hall is open in another tab" note="One screen drives a battle. Close the other tab, then reload this one." />
      </div>
    )
  }

  if (!room) {
    return (
      <>
        {backdrop}
        <div className="arena" data-phase="none">
          <Heading kicker="Host a battle" title="Open the hall" note="This screen is the arena. Phones join with the MeNIN app." />
          {view.status === 'offline' && <p className="wired-note">{view.error || 'Lost the hall. Reconnecting…'}</p>}
          <div className="wired-actions open-choices">
            {GAMES.map(([event, label], i) => (
              <button
                key={event}
                className={i === 0 ? 'primary-action' : 'secondary-action'}
                disabled={view.status !== 'connected'}
                onClick={() => {
                  arena.current?.startSound()
                  arena.current?.createRoom(event)
                }}
              >
                Open the hall: {label}
              </button>
            ))}
            {view.resumable && (
              <button
                className="secondary-action"
                onClick={() => {
                  arena.current?.startSound()
                  arena.current?.resume(view.resumable!)
                }}
              >
                Resume {view.resumable.code}
              </button>
            )}
            {view.status === 'offline' && view.error && (
              <button className="secondary-action" onClick={() => arena.current?.retry()}>
                Try again
              </button>
            )}
          </div>
          {STDB_DB !== 'homer-calhacks' && <p className="wired-note">Test hall: {STDB_DB}</p>}
        </div>
      </>
    )
  }

  const discus = room.event === 'discus'
  const stadion = room.event === 'stadion'
  const boxing = room.event === 'pygmachia'
  const archery = room.event === 'toxeia'
  const field = FIELD_EVENTS.includes(room.event) // the field events: no verse, no judge, no song; their own panels
  const coach = room.event === 'coach' // Talk to Homer: a conversation, no scorecard (Coach.tsx)
  const begun = room.phase !== 'lobby'
  const over = room.phase === 'finale' || room.phase === 'finished'
  const top = over ? [...view.poets].sort((a, b) => b.total - a.total)[0] : undefined
  const champion = top && top.total > 0 ? top : null // nobody scored, nobody crowned
  const speaker = view.turn ? view.poets.find((p) => p.id === view.turn!.playerId) : undefined
  const showVerse = !field && !coach && view.turn?.transcript && ['speaking', 'judging'].includes(room.phase)
  // Ranked once the battle starts; discus keeps join order (a total would give a throw away before its arc lands).
  const board = begun && !field ? [...view.poets].sort((a, b) => b.total - a.total || a.seat - b.seat) : view.poets

  return (
    <>
      {!field && backdrop}
      <div className="arena" data-phase={room.phase}>
        {begun && <span className="join-chip">Join · {room.code}</span>}

        {coach ? (
          <Heading
            kicker={`Talk to Homer · Room ${room.code}`}
            title={room.phase === 'lobby' ? 'Talk to Homer' : view.round?.theme || 'Talk to Homer'}
            note={room.phase === 'lobby' ? 'Join with the MeNIN app, then speak when SPEAK comes up on your phone' : ''}
          />
        ) : (
          <Heading
            kicker={room.phase === 'lobby' || archery ? `Room ${room.code}` : `Room ${room.code} · Round ${room.roundNo} of ${room.rounds}`}
            title={room.phase === 'lobby' ? 'Enter the hall' : stadion ? 'The stadion · 192 m' : boxing ? 'Pygmachia · 60 s' : archery ? 'Toxeia · three arrows each' : view.round?.theme || PHASES[room.phase] || room.phase}
            note={room.phase === 'lobby' ? PHASES.lobby : room.phase === 'ready' && speaker ? `${speaker.name} steps up` : ''}
          />
        )}

        {room.phase === 'lobby' && (
          <div className="join-card">
            <div className="join-qr" dangerouslySetInnerHTML={{ __html: qr }} aria-label={`QR code for room ${room.code}`} />
            <div>
              <strong className="join-code">{room.code}</strong>
              <small>Scan with your phone's camera, or type the code in MeNIN.</small>
            </div>
          </div>
        )}

        {((!coach && !boxing && !archery) || !begun) && <div className="scoreboard">
          {board.map((poet, i) => (
            <div
              key={poet.id.toString()}
              className={[speaker?.id === poet.id ? 'up' : '', begun && !field && i === 0 && poet.total > 0 ? 'lead' : ''].join(' ').trim()}
              style={{ '--seat': SEAT_INKS[poet.seat % SEAT_INKS.length] } as CSSProperties}
            >
              <span className="name">
                {poet.name}
                {poet.epithet && <small className="epithet">{poet.epithet}</small>}
              </span>
              <strong>{room.phase === 'lobby' ? (poet.entered ? '✓' : '…') : field ? '' : poet.total}</strong>
              <small className="status">{champion?.id === poet.id ? 'Champion' : away(poet.id, poet.connected) ? 'away' : ' '}</small>
            </div>
          ))}
        </div>}

        {coach && <CoachPanel view={view} onWord={onWord} />}

        {showVerse && (
          <TailVerse
            turnKey={`${view.turn!.id}-${view.turn!.attempt}`}
            text={view.turn!.transcript}
            className="live-verse"
            lines
            mark={(text) => withFormulas(text, view.turn!.played)}
            onWord={onWord}
          />
        )}

        {room.event === 'poetry' && room.phase === 'speaking' && speaker && (
          <VerseCue window={verseWindow} ink={SEAT_INKS[speaker.seat % SEAT_INKS.length]} />
        )}

        {discus && <DiscusPanel view={view} />}
        {stadion && <StadionPanel view={view} />}
        {boxing && begun && view.bout && <BoxingPanel bout={view.bout} live={room.phase === 'speaking'} />}
        {archery && <ToxeiaPanel view={view} />}

        {room.phase === 'scored' && score && !field && !coach && (
          // A judge that never answered posts SILENT_VERDICT and a neutral score: grey it and say so.
          <div className={`score-panel five${!score.verdict || score.verdict === SILENT_VERDICT ? ' neutral' : ''}`}>
            {(!score.verdict || score.verdict === SILENT_VERDICT) && (
              <small className="neutral-mark">Neutral score: the judge timed out</small>
            )}
            {(AXES[room.event] ?? AXES.poetry).map(([label, i]) => {
              const value = score.axes[i] ?? 0
              return (
                <div key={label} className={value >= 8 ? 'high' : ''} style={{ '--v': value } as CSSProperties}>
                  <strong>{score.axes[i] ?? '–'}</strong>
                  <i className="bar" />
                  <span>{label}</span>
                </div>
              )
            })}
            {score.bestLine && <blockquote className="best-line">{score.bestLine}</blockquote>}
          </div>
        )}

        {!field && room.phase === 'finale' && view.song.length > 0 && (
          <blockquote className="live-verse song">
            {view.song.map((line, i) => (
              <span key={i}>{line}</span>
            ))}
          </blockquote>
        )}

        {!field && champion && room.phase === 'finished' && (
          <div className="crown">
            <span className="label">Champion of the Agon</span>
            <strong className="name">{champion.name}</strong>
            {champion.epithet && <em className="epithet">{champion.epithet}</em>}
            <small className="points">{champion.total} points</small>
          </div>
        )}

        {!field && ['round_end', 'finished'].includes(room.phase) && view.round?.bestLine && (
          <div className="carved">
            <span className="label">Carved</span>
            <p className="carved-line">“{view.round.bestLine}”</p>
            {view.carvedBy && (
              <small className="by">
                — {view.carvedBy}, round {room.roundNo}
              </small>
            )}
          </div>
        )}

        {view.error && <p className="wired-note">{view.error}</p>}

        <div className="wired-actions">
          {room.phase === 'lobby' && (
            <button className="primary-action" disabled={view.poets.length < (coach ? 1 : 2)} onClick={() => arena.current?.startBattle()}>
              {view.poets.length < (coach ? 1 : 2) ? (coach ? 'Waiting for a poet' : archery ? 'Waiting for the bow and the arrow' : 'Waiting for two poets') : 'Begin'}
            </button>
          )}
          {room.phase === 'finished' && (
            <button className="primary-action" onClick={() => arena.current?.rematch()}>
              {coach ? 'New conversation' : 'Rematch'}
            </button>
          )}
          {archery && room.phase !== 'finished' && (
            // Archery by camera (SPEC "Toxeia"): on, the webcam aims and draws; off, the two phones do
            <button className="secondary-action camera-switch" onClick={() => arena.current?.setCamera(!view.cameraOn)}>
              {view.cameraOn ? 'Camera off' : 'Camera on'}
            </button>
          )}
          {['lobby', 'finished'].includes(room.phase) && (
            <button className="secondary-action new-event" onClick={() => setPicking(!picking)}>
              {picking ? 'Cancel' : 'New event'}
            </button>
          )}
          {view.comeback && (
          <button className="secondary-action operator" onClick={() => arena.current?.skipComeback()}>
            Skip
          </button>
        )}
        {coach && !['lobby', 'finished'].includes(room.phase) && (
          <button className="secondary-action operator" onClick={() => arena.current?.endConversation()}>
            End
          </button>
        )}
        {!coach && !view.comeback && !['lobby', 'finished', 'speaking'].includes(room.phase) && (
            <button className="secondary-action operator" onClick={() => arena.current?.advanceOnce()}>
              {archery && room.phase === 'ready' ? 'Finish' : 'Next'}
            </button>
          )}
        </div>

        {/* New event: another game in the same hall; every phone stays joined (set_event → lobby → Begin). */}
        {picking && ['lobby', 'finished'].includes(room.phase) && (
          <div className="wired-actions open-choices event-picker">
            {GAMES.filter(([event]) => event !== room.event).map(([event, label]) => (
              <button
                key={event}
                className="secondary-action"
                onClick={() => {
                  setPicking(false)
                  arena.current?.setEvent(event)
                }}
              >
                {label}
              </button>
            ))}
          </div>
        )}

        {/* Nothing is judged after the crown: the warning goes, the connection and sound notes stay. */}
        {(room.phase !== 'finished' || view.status === 'offline' || !view.sound || view.voiceNote || glNote) && (
          <p className="host-guard">
            {glNote && <strong className="voice-note">{glNote}</strong>}
            {glNote && ' '}
            {view.voiceNote && <strong className="voice-note">{view.voiceNote}</strong>}
            {view.voiceNote && room.phase !== 'finished' && ' '}
            {room.phase !== 'finished' && `This screen hosts room ${room.code}. Don’t open ${room.code} on another arena, or every turn is judged twice.`}
            {view.status === 'offline' && ' Reconnecting…'}
            {!view.sound && ' Sound is off: reload and use Open the hall or Resume to start it.'}
          </p>
        )}
      </div>
    </>
  )
}

type VerseWindow = { key: string; startMs: number; endMs: number }
type Cue = { kind: 'count'; n: number } | { kind: 'speak'; left: number; total: number } | { kind: 'done' }

const COUNT_STEP_MS = 750 // the phone's count-in (build 13): 3, 2, 1 at fixed 0.75 s steps before SPEAK
const CLOCK_STEP_S = 0.25 // the clock moves four times a second

/** What the poet does now, as the phone reads it: 3-2-1 before beat_at, one SPEAK with the clock until
 *  ends_at (free verse, no metronome), then Time until the turn closes. */
function cueAt(w: VerseWindow, now: number): Cue | null {
  const toStart = w.startMs - now
  if (toStart > 0) {
    const n = Math.ceil(toStart / COUNT_STEP_MS)
    return n <= 3 ? { kind: 'count', n } : null
  }
  const total = Math.max(1, (w.endMs - w.startMs) / 1000)
  const left = Math.ceil((w.endMs - now) / 1000 / CLOCK_STEP_S) * CLOCK_STEP_S
  return left > 0 ? { kind: 'speak', left, total } : { kind: 'done' }
}

/** The big cue over the verse. It reads the window on its own timer and re-renders only when the cue changes. */
function VerseCue({ window: verse, ink }: { window: () => VerseWindow | null; ink: string }) {
  const [cue, setCue] = useState<Cue | null>(null)
  useEffect(() => {
    const id = window.setInterval(() => {
      const w = verse()
      const next = w ? cueAt(w, Date.now()) : null
      setCue((was) => (JSON.stringify(was) === JSON.stringify(next) ? was : next))
    }, 50)
    return () => window.clearInterval(id)
  }, [verse])
  if (!cue) return null
  const style = { '--ink': ink } as CSSProperties
  if (cue.kind === 'count') {
    return (
      <div className="verse-cue" data-cue="count" style={style}>
        <strong key={cue.n}>{cue.n}</strong>
        <small>Get ready</small>
      </div>
    )
  }
  if (cue.kind === 'speak') {
    return (
      <div className="verse-cue" data-cue="speak" style={style}>
        <strong>SPEAK</strong>
        <span className="clock-wrap">
          <span className={`clock${cue.left <= 5 ? ' last' : ''}`} style={{ '--p': cue.left / cue.total } as CSSProperties} />
          <b>{Math.ceil(cue.left)}</b>
        </span>
        <small>The mic is open. Just go.</small>
      </div>
    )
  }
  return (
    <div className="verse-cue" data-cue="done" style={style}>
      <strong>Time</strong>
    </div>
  )
}

function Heading({ kicker, title, note }: { kicker: string; title: string; note: string }) {
  return (
    <div className="workspace-heading">
      <span>{kicker}</span>
      <h2>{title}</h2>
      {note && <p>{note}</p>}
    </div>
  )
}
