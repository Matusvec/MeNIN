// The discus field on the arena screen (UX D3–D6): the thrower in the circle, the wind-up,
// the arc of the throw, the landing, and the board of best throws. lib/discus.ts paces the
// reveal; this only draws it. Bests come from discus_throw (player.total, the best in tenths
// of a metre, is the same number but already counts a throw still in the air).

import { useEffect, useState } from 'react'
import type { ArenaView } from './lib/arena'
import { FIELD, PHAYLLOS, best, champion, flightOf, landing, type Landing } from './lib/discus'
import './discus.css'

// The field in SVG units: the circle on the left, 80 m of ground to the right.
const W = 400
const H = 170
const X0 = 24
const GROUND = 148
const RUN = 360
const at = (m: number) => X0 + (Math.min(FIELD, Math.max(0, m)) / FIELD) * RUN
const FOUL_M = 12 // a foul's arc veers off short, into the crowd

const EARNED: Record<Exclude<Landing, null>, string> = {
  hall: 'New mark. Remember that name.',
  phayllos: 'Past Phayllos.',
  personal: 'A personal best.',
}

/** Re-renders every frame while a throw is in the air, four times a second otherwise. */
function useNow(fast: boolean): number {
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    if (fast) {
      let id = requestAnimationFrame(function loop() {
        setNow(Date.now())
        id = requestAnimationFrame(loop)
      })
      return () => cancelAnimationFrame(id)
    }
    const id = window.setInterval(() => setNow(Date.now()), 250)
    return () => window.clearInterval(id)
  }, [fast])
  return now
}

/** The arc from the circle to `metres`, drawn up to `progress`, as an SVG path and its head. */
function arc(metres: number, progress: number): { d: string; head: [number, number] } {
  const end = at(metres)
  const height = 25 + 85 * Math.min(1, metres / FIELD)
  const point = (p: number): [number, number] => [X0 + (end - X0) * p, GROUND - 4 * height * p * (1 - p)]
  const steps = Math.max(1, Math.round(progress * 40))
  const pts = Array.from({ length: steps + 1 }, (_, i) => point((progress * i) / steps))
  return { d: pts.map(([x, y], i) => `${i ? 'L' : 'M'}${x.toFixed(1)} ${y.toFixed(1)}`).join(' '), head: pts[pts.length - 1] }
}


export default function DiscusPanel({ view }: { view: ArenaView }) {
  const room = view.room
  const turn = view.turn
  const row = turn ? view.throws.find((t) => t.turnId === turn.id) : undefined
  const now = useNow(room?.phase === 'scored' && Boolean(row))
  if (!room) return null

  const thrower = turn ? view.poets.find((p) => p.id === turn.playerId) : undefined
  const flight = turn && row ? flightOf(turn.id) : undefined
  const progress = flight ? Math.min(1, (now - flight.start) / flight.ms) : 0
  const inAir = Boolean(row && flight && progress < 1)
  const landed = Boolean(row && flight && progress >= 1)
  const winding = room.phase === 'speaking' && view.prosody?.turnId === turn?.id && (view.prosody?.hits ?? 0) > 0
  const power = winding ? Math.min(1, Math.max(0, view.prosody!.loudness)) : 0
  const over = room.phase === 'finale' || room.phase === 'finished'
  const winner = over ? champion(view.poets, view.throws) : null
  // The throw in the air stays off the board and the flags until it lands (player.total
  // already counts it), so the arc is the reveal.
  const shown = view.throws.filter((t) => !(row && !landed && t.id === row.id))
  const bestOf = (id: bigint) => best(shown.filter((t) => t.playerId === id)) ?? 0
  const board = [...view.poets].sort((a, b) => bestOf(b.id) - bestOf(a.id) || a.seat - b.seat)
  const hallBest = board.length ? bestOf(board[0].id) : 0
  const name = thrower?.name ?? ''

  let status = ''
  if (room.phase === 'lobby') status = 'Hold the button, swing your phone, let go of the button. Not the phone.'
  else if (room.phase === 'ready') status = `${name} steps into the circle`
  else if (room.phase === 'speaking') status = winding ? `${name} winds up` : `${name}: hold the button and swing`
  else if (room.phase === 'scored') {
    if (!row) status = 'Out of time. No throw this round.'
    else if (!landed) status = 'Look at it go…'
    else status = row.foul ? "Into the crowd. They'll live." : `${name} throws ${row.distance.toFixed(1)} m`
  } else if (over) status = winner ? `The discus goes to ${winner.name}` : 'Nothing landed.'

  const path = row && (inAir || landed) ? arc(row.foul ? FOUL_M : row.distance, progress) : null
  const earned = row && landed ? landing(row, view.throws) : null

  return (
    <section className="discus" aria-live="polite">
      {room.phase !== 'lobby' && !over && (
        <p className="discus-kicker">
          Throw {Math.max(1, room.roundNo)} of {room.rounds}
        </p>
      )}
      <p className="discus-status">{status}</p>

      <svg className="discus-field" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="The discus field">
        <line className="ground" x1={X0 - 12} x2={X0 + RUN + 8} y1={GROUND} y2={GROUND} />
        {Array.from({ length: FIELD / 10 }, (_, i) => (i + 1) * 10).map((m) => (
          <g key={m} className="mark">
            <line x1={at(m)} x2={at(m)} y1={GROUND} y2={GROUND + 5} />
            <text x={at(m)} y={GROUND + 15}>
              {m}
            </text>
          </g>
        ))}
        <g className="phayllos">
          <line x1={at(PHAYLLOS)} x2={at(PHAYLLOS)} y1={GROUND - 70} y2={GROUND} />
          <text x={at(PHAYLLOS)} y={GROUND - 74}>
            Phayllos
          </text>
        </g>
        {board
          .filter((p) => bestOf(p.id) > 0)
          .map((p) => (
            <g key={p.id.toString()} className={`flag${bestOf(p.id) === hallBest ? ' best' : ''}`}>
              <line x1={at(bestOf(p.id))} x2={at(bestOf(p.id))} y1={GROUND} y2={GROUND - 16} />
              <path d={`M${at(bestOf(p.id))} ${GROUND - 16} l9 3.5 l-9 3.5 z`} />
              <text x={at(bestOf(p.id)) + 2} y={GROUND - 20}>
                {p.name.slice(0, 1)}
              </text>
            </g>
          ))}
        <circle className="circle" cx={X0} cy={GROUND - 1} r={7 + 7 * power} />
        {path && <path className={`arc${row?.foul ? ' foul' : ''}`} d={path.d} />}
        {path ? (
          <circle className={`disc${row?.foul ? ' foul' : ''}`} cx={path.head[0]} cy={path.head[1]} r={4} />
        ) : (
          room.phase !== 'lobby' && !over && <circle className="disc" cx={X0} cy={GROUND - 8} r={4} />
        )}
        {landed && row?.foul && (
          <text className="foul-mark" x={at(FOUL_M)} y={GROUND - 8}>
            ✕
          </text>
        )}
      </svg>

      {winding && (
        <div className="discus-power" aria-label={`Power ${Math.round(power * 100)}%`}>
          <span style={{ width: `${power * 100}%` }} />
        </div>
      )}

      {landed && row && (
        <div className={`discus-result${row.foul ? ' foul' : ''}`}>
          {row.foul ? 'Foul' : `${row.distance.toFixed(1)} m`}
          {earned && <small>{EARNED[earned]}</small>}
        </div>
      )}

      <ol className="discus-ranks">
        {board.map((p) => {
          const mine = shown.filter((t) => t.playerId === p.id).sort((a, b) => a.throwNo - b.throwNo)
          return (
            <li key={p.id.toString()} className={[winner?.id === p.id ? 'champion' : '', thrower?.id === p.id && !over ? 'up' : ''].join(' ')}>
              <span className="who">
                {p.name}
                {p.epithet && <small>{p.epithet}</small>}
              </span>
              <span className="tries">
                {mine.map((t) => (
                  <i key={t.id.toString()} className={t.foul ? 'foul' : ''}>
                    {t.foul ? 'F' : t.distance.toFixed(1)}
                  </i>
                ))}
              </span>
              <strong>{bestOf(p.id) > 0 ? `${bestOf(p.id).toFixed(1)} m` : '–'}</strong>
            </li>
          )
        })}
      </ol>
    </section>
  )
}
