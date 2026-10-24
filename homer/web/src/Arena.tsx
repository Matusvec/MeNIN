// The arena screen (SPEC "The website"): the room code and QR, the lobby and
// entrances, the live verse, the verdict and scores, the carved line, the champion.
// The battle itself runs in lib/arena.ts; this only shows it.

import { useEffect, useMemo, useRef, useState } from 'react'
import QRCode from 'qrcode'
import { Arena, STDB_DB, type ArenaView } from './lib/arena'
import './wired.css'

const AXES = ['Beat', 'Craft', 'Image', 'Answer', 'Range'] // poetry's rubric, in score.axes order

const PHASES: Record<string, string> = {
  lobby: 'Scan the code with the MeNIN app, or type it in',
  theme: 'The judges pick a theme',
  dealing: 'Homer deals the hands',
  ready: 'Step up',
  speaking: 'The floor is theirs',
  judging: 'Homer weighs the verse',
  scored: 'The verdict',
  round_end: 'The round is called',
  finale: 'The song, then the crown',
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

export default function ArenaPanel({
  onLine,
  onSpeaking,
}: {
  onLine: (line: string) => void
  onSpeaking: (speaking: boolean) => void
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

  const room = view?.room ?? null
  const qr = useQr(room ? `homer://join/${room.code}` : '')
  const score = useMemo(
    () => (view?.turn ? view.scores.find((s) => s.turnId === view.turn!.id) ?? null : null),
    [view?.turn, view?.scores],
  )

  if (!view || view.status === 'connecting') {
    return <Heading kicker="The hall" title="Opening the doors…" note="" />
  }

  if (!room) {
    return (
      <>
        <Heading kicker="Host a battle" title="Open the hall" note="This screen is the arena. Phones join with the MeNIN app." />
        {view.status === 'offline' && <p className="wired-note">{view.error || 'Lost the hall. Reload to reconnect.'}</p>}
        <div className="wired-actions">
          <button className="primary-action" disabled={view.status !== 'connected'} onClick={() => arena.current?.createRoom()}>
            Open the hall
          </button>
          {view.resumable && (
            <button className="secondary-action" onClick={() => arena.current?.resume(view.resumable!)}>
              Resume {view.resumable.code}
            </button>
          )}
        </div>
        {STDB_DB !== 'homer-calhacks' && <p className="wired-note">Test hall: {STDB_DB}</p>}
      </>
    )
  }

  const champion = room.phase === 'finale' || room.phase === 'finished' ? [...view.poets].sort((a, b) => b.total - a.total)[0] : null
  const speaker = view.turn ? view.poets.find((p) => p.id === view.turn!.playerId) : undefined
  const showVerse = view.turn?.transcript && ['speaking', 'judging', 'scored'].includes(room.phase)

  return (
    <>
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
            <small>Open MeNIN on your phone, tap Join, scan or type the code.</small>
          </div>
        </div>
      )}

      <div className="scoreboard">
        {view.poets.map((poet) => (
          <div key={poet.id.toString()} className={speaker?.id === poet.id ? 'up' : ''}>
            <span>
              {poet.name}
              {poet.epithet ? `, ${poet.epithet}` : ''}
            </span>
            <strong>{room.phase === 'lobby' ? (poet.entered ? '✓' : '…') : poet.total}</strong>
            <small>{champion?.id === poet.id ? 'Champion' : poet.connected ? ' ' : 'Reconnecting'}</small>
          </div>
        ))}
      </div>

      {showVerse && (
        <blockquote className="live-verse">
          {view.turn!.transcript.split('\n').map((line, i) => (
            <span key={i}>{line}</span>
          ))}
        </blockquote>
      )}

      {room.phase === 'scored' && score && (
        <div className="score-panel five">
          {AXES.map((label, i) => (
            <div key={label}>
              <strong>{score.axes[i] ?? '–'}</strong>
              <span>{label}</span>
            </div>
          ))}
          <p>
            {score.verdict || 'Homer is silent on this one.'}
            {score.bestLine && (
              <>
                <br />
                <b>Best line:</b> {score.bestLine}
              </>
            )}
          </p>
        </div>
      )}

      {['round_end', 'finale', 'finished'].includes(room.phase) && view.round?.bestLine && (
        <p className="carved-line">“{view.round.bestLine}”</p>
      )}

      {room.phase === 'finale' && view.song.length > 0 && (
        <blockquote className="live-verse song">
          {view.song.map((line, i) => (
            <span key={i}>{line}</span>
          ))}
        </blockquote>
      )}

      {champion && room.phase === 'finished' && (
        <p className="carved-line">
          {champion.name}
          {champion.epithet ? `, ${champion.epithet}` : ''} takes the crown.
        </p>
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
          <button className="secondary-action" onClick={() => arena.current?.advanceOnce()}>
            Next
          </button>
        )}
      </div>
    </>
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
