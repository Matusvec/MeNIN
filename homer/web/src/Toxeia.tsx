// Toxeia on the arena screen: who's shooting, the wind, the range (artist's Range: the archer
// drawing with the arrow phone, the target, the bow's live aim, the flight and the thunk), the
// score stamp, and the board. lib/toxeia.ts calls the range; this only draws it, in artist's
// white-ground look (toxeia.css, artist's file: its class contract is at its top).

import { useEffect, useState, type CSSProperties } from 'react'
import type { ArenaView } from './lib/arena'
import { AIM_SPAN, ARROWS, arrowsOf, newest, onFace, order, seenAt, windOf, type ToxeiaFeed } from './lib/toxeia'
import Range, { FLIGHT_S, type ToxShot } from './toxeia/Range'
import WindVane from './toxeia/WindVane'
import './toxeia.css'

// Archer colors in shooting order, in the pottery palette (as the Stadion's lanes).
const SEATS = ['#a2462b', '#2f5d73', '#b8862b', '#4d6b3a', '#6b3a5d']
const LOOSED_MS = 300 // the string's snap after the release
const FLYING_MS = (FLIGHT_S + 0.6) * 1000

/** Re-renders every frame while an arrow is up or in the air, four times a second otherwise. */
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

export default function ToxeiaPanel({ view }: { view: ArenaView & ToxeiaFeed }) {
  const room = view.room
  const live = room?.phase === 'speaking' || room?.phase === 'scored'
  const now = useNow(live)
  if (!room) return null

  const range = view.range
  const archers = order(view.archers)
  const ink = (id: bigint) => SEATS[Math.max(0, archers.findIndex((a) => a.id === id)) % SEATS.length]
  const last = newest(view.arrows)
  // On the line: the archer up, or between arrows the one who just shot.
  const shooter = archers.find((a) => a.id === (range?.archerId || last?.archerId))
  const mine = shooter ? arrowsOf(view.arrows, shooter.id) : []
  const shot = room.phase === 'scored' ? last : null
  const since = shot ? now - seenAt(shot) : Infinity
  const toShot = (s: (typeof mine)[number]): ToxShot => ({ id: s.id.toString(), x: onFace(s.x), y: onFace(s.y), score: s.ring })
  const phase =
    room.phase === 'speaking' ? 'aim'
    : room.phase === 'scored' ? 'flight'
    : room.phase === 'finale' || room.phase === 'finished' ? 'done'
    : 'pass'
  const aiming = room.phase === 'speaking' && range
  const arrowNo = range?.arrowNo || shot?.arrowNo || 0

  return (
    <section className="toxeia" data-phase={phase}>
      <header className="tox-top">
        <div className="tox-archer" style={{ '--seat': shooter ? ink(shooter.id) : SEATS[0] } as CSSProperties}>
          <b>{shooter?.name ?? 'Toxeia'}</b>
          <span>{shooter && arrowNo ? `Arrow ${arrowNo} of ${ARROWS}` : 'The archery'}</span>
        </div>
        <WindVane wind={windOf(range)} />
        <div className="tox-total">
          <strong>{shooter?.total ?? 0}</strong>
          <small>points</small>
        </div>
      </header>
      <div className="range">
        <Range
          aim={aiming ? { x: onFace(AIM_SPAN * range.aimYaw), y: onFace(AIM_SPAN * range.aimPitch) } : null}
          draw={aiming ? range.draw : 0}
          nocked={!!aiming && range.draw > 0.01}
          loosed={since < LOOSED_MS}
          wind={windOf(range)}
          shots={mine.filter((s) => s.flight > 0).map(toShot)}
          flying={shot && shot.flight > 0 && since < FLYING_MS ? toShot(shot) : null}
          seat={shooter ? ink(shooter.id) : undefined}
        />
        {shot && since >= FLIGHT_S * 1000 && (
          <div className={`tox-stamp${shot.ring === 10 ? ' bull' : ''}`} key={shot.id.toString()}>
            {shot.ring}
          </div>
        )}
        {phase === 'pass' && (
          <div className="tox-pass">{archers.length ? 'Pass both phones on' : 'Name the first archer on the bow'}</div>
        )}
      </div>
      <ol className="tox-board">
        {archers.map((a) => {
          const rings = arrowsOf(view.arrows, a.id)
          return (
            <li key={a.id.toString()} className={a.id === range?.archerId ? 'up' : ''} style={{ '--seat': ink(a.id) } as CSSProperties}>
              <b>{a.name}</b>
              <span>
                {Array.from({ length: ARROWS }, (_, i) => (
                  <i key={i}>{rings[i] ? rings[i].ring : ''}</i>
                ))}
              </span>
              <strong>{a.total}</strong>
            </li>
          )
        })}
      </ol>
    </section>
  )
}
