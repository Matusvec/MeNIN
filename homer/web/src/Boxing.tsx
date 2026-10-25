// The Pygmachia fight on the arena (SPEC "The games", boxing v1): artist's two black-figure boxers on a
// vase frieze (src/boxing/, boxing.css), driven live from the module's rows. One phone drives both of a
// fighter's fists, mirrored (Matus): the aim's height moves both, a punch throws the hand on the side the
// phone points to, the guard raises both. lib/boxing.ts maps the rows; this only draws.

import { useEffect, useState, type CSSProperties } from 'react'
import Fighter from './boxing/Fighter'
import './boxing.css'
import { type Bout, rigAim, rigHand, rigPunch, rocking, secondsLeft, throwing } from './lib/boxing'

const SEAT_INKS = ['#2D5C66', '#C8452C', '#A8741F', '#5B3F73', '#6E7A2E']

/** Re-renders every frame while the fight is live or a punch is playing out. */
function useFrame(on: boolean): number {
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    if (!on) return
    let id = requestAnimationFrame(function loop() {
      setNow(Date.now())
      id = requestAnimationFrame(loop)
    })
    return () => cancelAnimationFrame(id)
  }, [on])
  return on ? now : Date.now()
}

export default function BoxingPanel({ bout, live }: { bout: Bout; live: boolean }) {
  const now = useFrame(live || bout.goAt !== null && !bout.ended)
  const [a, b] = bout.fighters
  if (!a || !b) return <section className="bout" data-phase="countdown" />
  const left = secondsLeft(bout, now)
  const countdown = bout.goAt !== null && now < bout.goAt ? Math.ceil((bout.goAt - now) / 1000) : null
  const fightCall = bout.goAt !== null && now >= bout.goAt && now - bout.goAt < 800
  const phase = bout.ended ? 'ko' : countdown !== null ? 'countdown' : 'fight'
  const loser = bout.ended && bout.ko ? bout.fighters.find((f) => f.id !== bout.winnerId) : undefined
  const winner = bout.fighters.find((f) => f.id === bout.winnerId)
  const last = bout.punches[bout.punches.length - 1]
  const spark = last && now - last.at < 400 && last.result !== 'missed' ? last : undefined
  const target = spark ? (spark.to === a.id ? 0 : 1) : 0

  return (
    <section className="bout" data-phase={phase}>
      {/* artist's order (boxing.css): A's bar, the clock, B's bar. */}
      <div className="bout-top">
        <HealthBar f={a} side="a" />
        <div className={`clock${left !== null && left <= 10 ? ' last' : ''}`}>{left ?? ''}</div>
        <HealthBar f={b} side="b" />
      </div>
      <div className="ring">
        {[a, b].map((f, i) => {
          const p = throwing(bout, f.id, now)
          const hit = rocking(bout, f.id, now)
          const down = loser?.id === f.id
          return (
            <Fighter
              key={`${i}-${hit?.id ?? ''}`} // re-key per hit so the rock replays
              side={i ? 'b' : 'a'}
              aim={rigAim(f, Boolean(p))}
              hand={p ? rigHand(p.yaw) : f.guard ? null : null}
              punch={p ? rigPunch(p) : 'straight'}
              state={down ? 'ko' : hit ? 'hit' : 'fight'}
              seat={SEAT_INKS[f.seat % SEAT_INKS.length]}
              name={f.name}
            />
          )
        })}
        {spark && (
          <span
            key={spark.id}
            className="spark"
            style={{ '--x': target ? 0.62 : 0.38, '--y': spark.zone === 'body' ? 0.58 : 0.34 } as CSSProperties}
          />
        )}
      </div>
      {(countdown !== null || fightCall) && <div className="bout-count" key={countdown ?? 'fight'}>{countdown ?? 'FIGHT'}</div>}
      {bout.ended && (
        <div className="ko-banner">{bout.ko && winner ? `KO · ${winner.name}` : winner ? `${winner.name} wins` : 'Draw'}</div>
      )}
    </section>
  )
}

function HealthBar({ f, side }: { f: { name: string; hp: number; seat: number }; side: 'a' | 'b' }) {
  return (
    <div
      className={`hp ${side}${f.hp < 30 ? ' low' : ''}`}
      style={{ '--hp': Math.max(0, Math.min(1, f.hp / 100)), '--seat': SEAT_INKS[f.seat % SEAT_INKS.length] } as CSSProperties}
    >
      <b>{f.name}</b>
      <i />
    </div>
  )
}
