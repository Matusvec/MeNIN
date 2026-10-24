// The arena screen (SPEC "The website"): the room code and QR, the lobby and
// entrances, the live verse, the verdict and scores, the carved line, the champion.
// The battle itself runs in lib/arena.ts; this only shows it. Read from 2 m: the
// styles (wired.css) are artist's; this sets the hooks they hang on.

import { useEffect, useMemo, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import QRCode from 'qrcode'
import DiscusPanel from './Discus'
import { Arena, STDB_DB, type ArenaView, type GameEvent } from './lib/arena'
import { webJoinLink } from './lib/links'
import './wired.css'

// Each rubric in score.axes order (homer/homer/events.py)
const AXES: Record<string, string[]> = {
  poetry: ['Beat', 'Craft', 'Image', 'Answer', 'Range'],
  debate: ['Claim', 'Reason', 'Answer', 'Craft', 'Poise'],
}
const GAMES: Array<[GameEvent, string]> = [
  ['poetry', 'Poetry battle'],
  ['debate', 'Socratic debate'],
  ['discus', 'Discus'],
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
  if (view.warming) return `${host} is about to speak`
  if (!room) return ''
  switch (room.phase) {
    case 'lobby':
      return view.poets.length < 2 ? 'Waiting for poets — scan to join' : ''
    case 'dealing':
      return `${host} is dealing…`
    case 'judging':
      return room.event === 'debate' ? 'Socrates is weighing the argument…' : room.event === 'discus' ? '' : 'Homer is weighing the verse…'
    case 'round_end':
      return room.event !== 'discus' && !view.round?.verdict ? 'Calling the round…' : ''
    case 'finale':
      if (room.event === 'discus' || view.song.length) return ''
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
}: {
  onLine: (line: string) => void
  onSpeaking: (speaking: boolean) => void
  onStatus: (status: string) => void
}) {
  const [view, setView] = useState<ArenaView | null>(null)
  const arena = useRef<Arena | null>(null)

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
  const status = waitingFor(view)
  useEffect(() => {
    onStatus(status)
  }, [status, onStatus])

  const room = view?.room ?? null
  const qr = useQr(room ? webJoinLink(room.code) : '') // a page that opens MeNIN, or points to TestFlight
  const score = useMemo(
    () => (view?.turn ? view.scores.find((s) => s.turnId === view.turn!.id) ?? null : null),
    [view?.turn, view?.scores],
  )

  if (!view || view.status === 'connecting') {
    return (
      <div className="arena" data-phase="none">
        <Heading kicker="The hall" title="Opening the doors…" note="" />
      </div>
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
    )
  }

  const discus = room.event === 'discus'
  const begun = room.phase !== 'lobby'
  const over = room.phase === 'finale' || room.phase === 'finished'
  const champion = over ? [...view.poets].sort((a, b) => b.total - a.total)[0] : null
  const speaker = view.turn ? view.poets.find((p) => p.id === view.turn!.playerId) : undefined
  const showVerse = !discus && view.turn?.transcript && ['speaking', 'judging'].includes(room.phase)
  // Ranked once the battle starts; discus keeps join order (a total would give a throw away before its arc lands).
  const board = begun && !discus ? [...view.poets].sort((a, b) => b.total - a.total || a.seat - b.seat) : view.poets

  return (
    <div className="arena" data-phase={room.phase}>
      {begun && <span className="join-chip">Join · {room.code}</span>}

      <Heading
        kicker={room.phase === 'lobby' ? `Room ${room.code}` : `Room ${room.code} · Round ${room.roundNo} of ${room.rounds}`}
        title={room.phase === 'lobby' ? 'Enter the hall' : view.round?.theme || PHASES[room.phase] || room.phase}
        note={speaker && ['ready', 'speaking', 'judging'].includes(room.phase) ? `${speaker.name}: ${PHASES[room.phase]}` : PHASES[room.phase] ?? ''}
      />

      {room.phase === 'lobby' && (
        <div className="join-card">
          <div className="join-qr" dangerouslySetInnerHTML={{ __html: qr }} aria-label={`QR code for room ${room.code}`} />
          <div>
            <strong className="join-code">{room.code}</strong>
            <small>Scan with your phone's camera, or type the code in MeNIN.</small>
          </div>
        </div>
      )}

      <div className="scoreboard">
        {board.map((poet, i) => (
          <div
            key={poet.id.toString()}
            className={[speaker?.id === poet.id ? 'up' : '', begun && !discus && i === 0 && poet.total > 0 ? 'lead' : ''].join(' ').trim()}
          >
            <span className="name">
              {poet.name}
              {poet.epithet && <small className="epithet">{poet.epithet}</small>}
            </span>
            <strong>{room.phase === 'lobby' ? (poet.entered ? '✓' : '…') : discus ? '' : poet.total}</strong>
            <small className="status">{champion?.id === poet.id ? 'Champion' : poet.connected ? ' ' : 'Reconnecting'}</small>
          </div>
        ))}
      </div>

      {showVerse && (
        <blockquote className="live-verse">
          {view.turn!.transcript
            .split('\n')
            .filter((line) => line.trim())
            .map((line, i) => (
              <span key={i}>{withFormulas(line, view.turn!.played)}</span>
            ))}
        </blockquote>
      )}

      {discus && <DiscusPanel view={view} />}

      {room.phase === 'scored' && score && !discus && (
        <div className="score-panel five">
          {(AXES[room.event] ?? AXES.poetry).map((label, i) => {
            const value = score.axes[i] ?? 0
            return (
              <div key={label} className={value >= 8 ? 'high' : ''} style={{ '--v': value } as CSSProperties}>
                <strong>{score.axes[i] ?? '–'}</strong>
                <i className="bar" />
                <span>{label}</span>
              </div>
            )
          })}
          <p>{score.verdict || 'Homer is silent on this one.'}</p>
          {score.bestLine && <blockquote className="best-line">{score.bestLine}</blockquote>}
        </div>
      )}

      {!discus && room.phase === 'finale' && view.song.length > 0 && (
        <blockquote className="live-verse song">
          {view.song.map((line, i) => (
            <span key={i}>{line}</span>
          ))}
        </blockquote>
      )}

      {!discus && champion && room.phase === 'finished' && (
        <div className="crown">
          <span className="label">Champion of the Agon</span>
          <strong className="name">{champion.name}</strong>
          {champion.epithet && <em className="epithet">{champion.epithet}</em>}
          <small className="points">{champion.total} points</small>
        </div>
      )}

      {!discus && ['round_end', 'finished'].includes(room.phase) && view.round?.bestLine && (
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
          <button className="primary-action" disabled={view.poets.length < 2} onClick={() => arena.current?.startBattle()}>
            {view.poets.length < 2 ? 'Waiting for two poets' : 'Begin'}
          </button>
        )}
        {room.phase === 'finished' && (
          <button className="primary-action" onClick={() => arena.current?.rematch()}>
            Rematch
          </button>
        )}
        {!['lobby', 'finished', 'speaking'].includes(room.phase) && (
          <button className="secondary-action operator" onClick={() => arena.current?.advanceOnce()}>
            Next
          </button>
        )}
      </div>

      <p className="host-guard">
        This screen hosts room {room.code}. Don’t open {room.code} on another arena, or every turn is judged twice.
        {view.status === 'offline' && ' Reconnecting…'}
        {!view.sound && ' Sound is off: reload and use Open the hall or Resume to start it.'}
      </p>
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
