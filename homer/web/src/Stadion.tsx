// The Stadion on the arena screen: the track with every runner live, the 3-2-1, the finish
// line, the places and times. lib/stadion.ts calls the race; this only draws it, in
// artist's black-figure look (stadion.css, artist's file: its class contract is below).

import { useEffect, useState, type CSSProperties } from 'react'
import type { ArenaView } from './lib/arena'
import { SPRINT_SPEED, STADION_METRES, crossed, gunAt, raceOrder, roman } from './lib/stadion'
import './stadion.css'

// Seat colors for the lane pills and the order, in the pottery palette.
const SEATS = ['#a2462b', '#2f5d73', '#b8862b', '#4d6b3a', '#6b3a5d']
const GO_MS = 700 // how long "GO" stays stamped after the gun

/** Re-renders every frame while the race is live, four times a second otherwise. */
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

export default function StadionPanel({ view }: { view: ArenaView }) {
  const room = view.room
  const racing = room?.phase === 'speaking'
  const now = useNow(racing)
  if (!room) return null

  const gun = racing ? gunAt(view.heat) : null
  const untilGun = gun === null ? Infinity : gun - now
  const over = ['scored', 'finale', 'finished'].includes(room.phase)
  const phase = over ? 'finished' : racing && untilGun <= 0 ? 'running' : racing ? 'countdown' : 'waiting'
  const count = racing && untilGun > -GO_MS ? Math.ceil(untilGun / 1000) : null
  const byPlayer = new Map(view.runners.map((r) => [r.playerId, r]))
  const seat = (id: bigint) => SEATS[(view.poets.find((p) => p.id === id)?.seat ?? 0) % SEATS.length]
  const name = (id: bigint) => view.poets.find((p) => p.id === id)?.name ?? ''

  return (
    <div className="stadion" data-phase={phase}>
      {count !== null && (
        <div className="stadion-count" key={count > 0 ? count : 'go'}>
          {count > 0 ? count : 'GO'}
        </div>
      )}
      <ol className="stadion-track">
        {[...view.poets]
          .sort((a, b) => a.seat - b.seat)
          .map((p) => {
            const r = byPlayer.get(p.id)
            const done = r ? crossed(r) : false
            const progress = Math.min(1, (r?.distance ?? 0) / STADION_METRES)
            const speed = phase === 'running' && !done ? Math.min(1, (r?.speed ?? 0) / SPRINT_SPEED) : 0
            return (
              <li key={p.id.toString()} className={`lane${done ? ' finished' : ''}`} style={{ '--seat': seat(p.id) } as CSSProperties}>
                <span className="lane-name">{p.name}</span>
                <i className="runner" style={{ '--x': progress, '--speed': speed } as CSSProperties} />
                {r && r.place > 0 && <b className="place">{roman(r.place)}</b>}
              </li>
            )
          })}
      </ol>
      {(phase === 'running' || over) && (
        <ol className="stadion-order">
          {raceOrder(view.runners).map((r) => (
            <li key={r.playerId.toString()} style={{ '--seat': seat(r.playerId) } as CSSProperties}>
              <b>{r.place > 0 ? roman(r.place) : ''}</b> {name(r.playerId)}{' '}
              <small>{crossed(r) ? `${r.time.toFixed(2)} s` : `${Math.round(r.distance)} m`}</small>
            </li>
          ))}
        </ol>
      )}
    </div>
  )
}
