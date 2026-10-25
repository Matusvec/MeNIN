// The Pygmachia fight on the arena (SPEC "The games", boxing): artist's two black-figure boxers on a vase
// frieze (src/boxing/, boxing.css), driven live from the module's rows. One phone drives both of a fighter's
// fists, mirrored (Matus): the aim's height moves both, a punch throws the hand on the side the phone points
// to. Matus: "more dramatic": every punch winds up, snaps and follows through; the target snaps back and the
// ring shakes with the damage; a counter lands in slow motion with a gold spark and a banner; combos stamp
// over the attacker; a tired fighter sags; the KO falls in slow motion into a burst of dust.
// lib/boxing.ts maps the rows; this only draws.

import { useEffect, useState, type CSSProperties } from 'react'
import Fighter from './boxing/Fighter'
import { Dust, Spark } from './boxing/Effects'
import './boxing.css'
import {
  type Bout,
  type BoutFighter,
  FLASH_MS,
  HIT_MS,
  TIRED,
  recent,
  rigAim,
  rigHand,
  rigPunch,
  rocking,
  secondsLeft,
  slowmo,
  throwPhase,
  throwing,
} from './lib/boxing'

const SEAT_INKS = ['#2D5C66', '#C8452C', '#A8741F', '#5B3F73', '#6E7A2E']

/** Re-renders every frame while the fight is live or the end is playing out. */
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
  const settling = bout.endedAt !== null && Date.now() - bout.endedAt < 3000 // the KO fall and the banner stamp
  const now = useFrame(live || (bout.goAt !== null && !bout.ended) || settling)
  const [a, b] = bout.fighters
  if (!a || !b) return <section className="bout" data-phase="countdown" />
  const left = secondsLeft(bout, now)
  const countdown = bout.goAt !== null && now < bout.goAt ? Math.ceil((bout.goAt - now) / 1000) : null
  const fightCall = bout.goAt !== null && now >= bout.goAt && now - bout.goAt < 800
  const phase = bout.ended ? 'ko' : countdown !== null ? 'countdown' : 'fight'
  const loser = bout.ended && bout.ko ? bout.fighters.find((f) => f.id !== bout.winnerId) : undefined
  const winner = bout.fighters.find((f) => f.id === bout.winnerId)
  // The newest landed or blocked punch: its spark, and (landed) the ring's shake scaled by the damage.
  const struck = recent(bout, now, 450, (p) => p.result === 'landed' || p.result === 'blocked')
  const shaking = recent(bout, now, HIT_MS, (p) => p.result === 'landed')
  const counter = recent(bout, now, FLASH_MS, (p) => p.counter && p.result === 'landed')
  const combo = recent(bout, now, FLASH_MS, (p) => p.result === 'landed' && p.combo >= 2)

  return (
    <section className="bout" data-phase={phase} data-slowmo={slowmo(bout, now) ? 'true' : undefined}>
      {/* artist's order (boxing.css): A's bar, the clock, B's bar. */}
      <div className="bout-top">
        <HealthBar f={a} side="a" />
        <div className={`clock${left !== null && left <= 10 ? ' last' : ''}`}>{left ?? ''}</div>
        <HealthBar f={b} side="b" />
      </div>
      <div
        className={`ring${shaking ? ' shake' : ''}`}
        key={shaking ? `shake-${shaking.id}` : 'ring'} // re-key per landed punch so the shake replays
        style={{ '--shake': shaking ? Math.min(1, shaking.damage / 16) : 0 } as CSSProperties}
      >
        {[a, b].map((f, i) => {
          const side = i ? 'b' : 'a'
          const p = throwing(bout, f.id, now)
          const beat = throwPhase(p, now)
          const hit = rocking(bout, f.id, now)
          const down = loser?.id === f.id
          const tired = f.stamina < TIRED && !down
          return (
            <div
              key={`${side}-${hit?.id ?? ''}`} // re-key per hit so the rock replays
              className={`fighter-slot ${side}${tired ? ' tired' : ''}`}
              data-throw={beat ?? undefined}
              data-hit={hit ? (hit.zone === 'body' ? 'body' : 'head') : undefined}
            >
              <Fighter
                side={side}
                aim={rigAim(f, beat)}
                hand={p && beat ? rigHand(p.yaw) : null}
                punch={p ? rigPunch(p) : 'straight'}
                throwPhase={beat ?? undefined}
                tired={tired}
                state={down ? 'ko' : hit ? 'hit' : 'fight'}
                seat={SEAT_INKS[f.seat % SEAT_INKS.length]}
                name={f.name}
              />
            </div>
          )
        })}
        {struck && (
          <Spark
            key={struck.id}
            x={struck.to === b.id ? 0.7 : 0.3}
            y={struck.zone === 'body' ? 0.55 : 0.32}
            power={struck.damage / 16}
            counter={struck.counter}
          />
        )}
        {combo && (
          <span key={`combo-${combo.id}`} className={`combo ${combo.from === a.id ? 'a' : 'b'}`}>
            {combo.combo}× COMBO
          </span>
        )}
        {loser && <Dust key={`dust-${bout.endedAt}`} side={loser.id === a.id ? 'a' : 'b'} />}
      </div>
      {counter && (
        <div key={`counter-${counter.id}`} className="bout-banner counter">
          COUNTER!
        </div>
      )}
      {(countdown !== null || fightCall) && <div className="bout-count" key={countdown ?? 'fight'}>{countdown ?? 'FIGHT'}</div>}
      {bout.ended && (
        <div className="ko-banner">
          {bout.ko && winner ? (
            <>
              <b>KO</b>
              <span>{winner.name} wins</span>
            </>
          ) : winner ? (
            <>
              <b>{winner.name}</b>
              <span>wins on the cards</span>
            </>
          ) : (
            <>
              <b>Draw</b>
              <span>neither falls</span>
            </>
          )}
        </div>
      )}
    </section>
  )
}

function HealthBar({ f, side }: { f: BoutFighter; side: 'a' | 'b' }) {
  return (
    <div
      className={`hp ${side}${f.hp < 30 ? ' low' : ''}`}
      style={
        {
          '--hp': Math.max(0, Math.min(1, f.hp / 100)),
          '--st': Math.max(0, Math.min(1, f.stamina / 100)),
          '--seat': SEAT_INKS[f.seat % SEAT_INKS.length],
        } as CSSProperties
      }
    >
      <b>{f.name}</b>
      <i />
      <i className="st" />
    </div>
  )
}
