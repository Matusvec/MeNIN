// The archery range (artist), after GamePigeon's: only the target, big and face on,
// as the archer sees it down the arrow (Greek rings in matte terracotta, cream and
// black to a gold center, a meander rim, on a straw butt). Over it: the bow's live
// aim dot, the arrows stuck in the face, the arrow in flight shrinking from the bow
// to where it strikes, and the thunk. Two small overlays at the sides: the wind
// (top left) and the draw meter (right). Painted white-ground, like a lekythos.
// Multiplayer's Toxeia.tsx drives it; toxeia.css animates it.

import { useEffect, useRef, type CSSProperties } from 'react'

export type ToxShot = {
  id: string
  /** On the target face in face units (1 is the outer rim), y up. */
  x: number
  y: number
  score: number
}

export type ToxWind = { speed: number; toward: number }

export type RangeProps = {
  /** The bow's point of aim in face units (1 = the outer rim; it rides off the face
   *  up to about ±1.64). Not the landing: the archer allows for wind and drop. Null hides it. */
  aim: { x: number; y: number } | null
  /** 0…1, from the arrow phone. */
  draw: number
  /** The thumb is down on the arrow phone. */
  nocked: boolean
  /** Just let go: the draw meter flashes. */
  loosed?: boolean
  wind: ToxWind | null
  /** This archer's arrows in the face, the one in flight included. */
  shots: ToxShot[]
  /** The arrow in the air: keep it set for at least FLIGHT_S + 0.6 s after the loose. */
  flying?: ToxShot | null
  /** The archer's seat color: the fletching. */
  seat?: string
}

/** Seconds from the loose to the thunk. */
export const FLIGHT_S = 0.55

const INK = '#1f1612'
const CLAY = '#c96b3c'
const SLIP = '#f1dfc4'
const GOLD = '#e2bd6c'
const CLAY_DEEP = '#a9532d'

type P = [number, number]

// The frame: 1600 × 760, the target in the middle filling its height.
const FRAME: P = [1600, 760]
const TARGET: P = [800, 380]
const R = 340 // the face's radius
/** Where the archer stands, below the frame: arrows fly from here and stick out toward it. */
const EYE: P = [800, 900]
/** Ten equal rings, scored 10 in the gold to 1 at the rim (the module's ring =
 *  10 − floor(r / 0.1)): outer radius (of R) and fill, outside in, paired like an
 *  archery face in the pots' colors. Ring 1 (0.9–1) is the meander rim, drawn
 *  separately. The phone's target uses the same rings. */
const RINGS: Array<[number, string]> = [
  [0.9, CLAY_DEEP], [0.8, SLIP], [0.7, SLIP], [0.6, INK], [0.5, INK], [0.4, CLAY], [0.3, CLAY], [0.2, GOLD], [0.1, GOLD],
]

const clamp = (v: number, a: number, b: number) => Math.min(b, Math.max(a, v))

/** A point on the target face, in the frame (it may lie off the face, or off the frame). */
const onFace = (x: number, y: number): P => [TARGET[0] + x * R, TARGET[1] - y * R]

/** The meander round the rim: one key per step, between r 0.9 and 1. */
function rimPath(): string {
  const n = 56
  const rIn = R * 0.905
  const rOut = R * 0.99
  const band = rOut - rIn
  const pt = (r: number, a: number) => `${(TARGET[0] + r * Math.cos(a)).toFixed(1)} ${(TARGET[1] + r * Math.sin(a)).toFixed(1)}`
  let d = ''
  for (let i = 0; i < n; i++) {
    const step = (2 * Math.PI) / n
    const a = i * step
    d += `M${pt(rIn, a)} L${pt(rOut, a)} L${pt(rOut, a + step * 0.75)} L${pt(rIn + band * 0.35, a + step * 0.75)} L${pt(rIn + band * 0.35, a + step * 0.35)} L${pt(rIn + band * 0.65, a + step * 0.35)} `
  }
  return d
}
const RIM = rimPath()

/** The aim reaches the screen at 10–20 Hz. Every frame the dot eases toward the
 *  latest (this time constant), so it glides like a held bow instead of jumping. */
const AIM_TAU_MS = 50

/** The aim dot: eased by requestAnimationFrame, written straight to its transform
 *  (no re-render per frame). Off the frame, a chevron points the way to the aim. */
function AimDot({ at, away }: { at: P; away: number | null }) {
  const g = useRef<SVGGElement>(null)
  const target = useRef(at)
  const pos = useRef<P | null>(null)
  target.current = at
  useEffect(() => {
    let raf = 0
    let last = performance.now()
    const step = (now: number) => {
      const t = target.current
      const p = pos.current ?? t
      const k = 1 - Math.exp(-Math.max(0, now - last) / AIM_TAU_MS)
      last = now
      const next: P = [p[0] + (t[0] - p[0]) * k, p[1] + (t[1] - p[1]) * k]
      pos.current = next
      g.current?.setAttribute('transform', `translate(${next[0].toFixed(1)} ${next[1].toFixed(1)})`)
      raf = requestAnimationFrame(step)
    }
    raf = requestAnimationFrame(step)
    return () => cancelAnimationFrame(raf)
  }, [])
  const p = pos.current ?? at
  return (
    <g ref={g} className="aim" transform={`translate(${p[0].toFixed(1)} ${p[1].toFixed(1)})`}>
      <circle className="aim-pulse" r="36" fill="none" stroke={INK} strokeWidth="5" />
      <circle r="34" fill={SLIP} stroke={INK} strokeWidth="5" />
      <circle r="20" fill={INK} />
      {away !== null && <path d="M44 -18 L66 0 L44 18" fill="none" stroke={INK} strokeWidth="8" strokeLinecap="round" strokeLinejoin="round" transform={`rotate(${away.toFixed(1)})`} />}
    </g>
  )
}

// The draw meter: a tall bar at the right, filling from the bottom.
const METER = { x: 1452, y: 150, w: 64, h: 470 }

export default function Range({ aim, draw, nocked, loosed = false, wind, shots, flying, seat }: RangeProps) {
  const d = nocked ? clamp(draw, 0, 1) : 0
  const fletch = seat ?? CLAY

  // The aim dot; off the frame it waits at the edge with a chevron pointing to it.
  const raw = aim ? onFace(aim.x, aim.y) : null
  const dot: P | null = raw ? [clamp(raw[0], 72, FRAME[0] - 72), clamp(raw[1], 72, FRAME[1] - 72)] : null
  const away = raw && dot && (raw[0] !== dot[0] || raw[1] !== dot[1]) ? (Math.atan2(raw[1] - dot[1], raw[0] - dot[0]) * 180) / Math.PI : null

  const still = !wind || wind.speed < 0.3
  const inner = METER.h - 10
  const tick = (f: number) => METER.y + 5 + inner * (1 - f)

  return (
    <svg className="range-art" viewBox={`0 0 ${FRAME[0]} ${FRAME[1]}`} role="img" aria-label="The archery target" style={{ '--flight': `${FLIGHT_S}s` } as CSSProperties}>
      <defs>
        <pattern id="tox-straw" width="14" height="14" patternUnits="userSpaceOnUse" patternTransform="rotate(28)">
          <rect width="14" height="14" fill="#d8b36a" />
          <path d="M0 3 H14 M0 10 H14" stroke="#b8914a" strokeWidth="2" />
        </pattern>
      </defs>

      {/* The target on its straw butt. */}
      <g key={flying?.id ?? 'still'} className={`target${flying ? ' thunk' : ''}`}>
        <circle cx={TARGET[0]} cy={TARGET[1]} r={R * 1.08} fill="url(#tox-straw)" stroke={INK} strokeWidth="6" />
        <circle cx={TARGET[0]} cy={TARGET[1]} r={R} fill={INK} />
        <path d={RIM} fill="none" stroke={GOLD} strokeWidth="4.5" />
        {RINGS.map(([f, fill]) => (
          <circle key={f} cx={TARGET[0]} cy={TARGET[1]} r={R * f} fill={fill} stroke={fill === INK ? SLIP : INK} strokeWidth={fill === INK ? 2 : 3} />
        ))}
        {/* The arrows in the face, each sticking out toward the archer. */}
        {shots.map((s) => {
          const [x, y] = onFace(s.x, s.y)
          const a = (Math.atan2(EYE[1] - y, EYE[0] - x) * 180) / Math.PI
          return (
            <g key={s.id} className={`stuck${flying?.id === s.id ? ' fresh' : ''}`}>
              <circle cx={x} cy={y} r="11" fill={INK} stroke={SLIP} strokeWidth="3" />
              <g transform={`translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${a.toFixed(1)})`}>
                <line x1="0" y1="0" x2="72" y2="0" stroke={INK} strokeWidth="9" strokeLinecap="round" />
                <path d="M72 0 l22 -18 l12 5 l-17 13 Z M72 0 l22 18 l12 -5 l-17 -13 Z" fill={fletch} stroke={INK} strokeWidth="2.5" strokeLinejoin="round" />
              </g>
            </g>
          )
        })}
      </g>

      {/* The thunk: a cut-paper star where it struck, after the flight. */}
      {flying && (() => {
        const [x, y] = onFace(flying.x, flying.y)
        return (
          <g key={`thunk-${flying.id}`} transform={`translate(${x.toFixed(1)} ${y.toFixed(1)}) scale(1.3)`}>
            <g className="thunk-spark">
              <polygon points="0,-46 9,-14 44,-26 16,2 40,34 4,16 -14,46 -10,10 -46,6 -14,-8" fill={SLIP} stroke={INK} strokeWidth="3" strokeLinejoin="round" />
              <circle r="26" fill="none" stroke={INK} strokeWidth="4" className="shock" />
            </g>
          </g>
        )
      })()}

      {/* The arrow in flight, seen from behind: it leaves the bow big and shrinks
          into the face where it strikes. */}
      {flying && (() => {
        const [x, y] = onFace(flying.x, flying.y)
        return (
          <g key={`flight-${flying.id}`} transform={`translate(${x.toFixed(1)} ${y.toFixed(1)})`}>
            <g className="flight" style={{ '--fx': `${(EYE[0] - x).toFixed(0)}px`, '--fy': `${(EYE[1] - 120 - y).toFixed(0)}px` } as CSSProperties}>
              {[45, 135, 225, 315].map((a) => (
                <path key={a} d="M6 0 L30 -7 L34 0 L30 7 Z" fill={fletch} stroke={INK} strokeWidth="2.5" strokeLinejoin="round" transform={`rotate(${a})`} />
              ))}
              <circle r="9" fill={INK} stroke={SLIP} strokeWidth="2.5" />
            </g>
          </g>
        )
      })()}

      {/* The live aim: a black dot on a cream ring, pulsing, gliding after the bow. */}
      {dot && <AimDot at={dot} away={away} />}

      {/* The wind, top left: a dial with an arrow the way it blows, and the speed. */}
      {wind && (
        <g className={`wind${still ? ' still' : ''}`} transform="translate(56 60)" role="img" aria-label={still ? 'No wind' : `Wind ${wind.speed.toFixed(1)} metres a second`}>
          <text className="wind-label" x="0" y="0">WIND</text>
          <g transform="translate(56 78)">
            <circle r="54" fill={SLIP} stroke={INK} strokeWidth="5" />
            <g className="wind-arrow" style={{ '--toward': `${-wind.toward}deg` } as CSSProperties}>
              <rect x="-38" y="-7" width="58" height="14" rx="3" />
              <polygon points="16,-21 46,0 16,21" />
              <path d="M-38 -7 l-11 -11 h13 l9 11 Z M-38 7 l-11 11 h13 l9 -11 Z" />
            </g>
          </g>
          <text x="128" y="104">
            <tspan className="wind-speed">{still ? '0' : wind.speed.toFixed(1)}</tspan>
            <tspan className="wind-unit" dx="10">m/s</tspan>
          </text>
        </g>
      )}

      {/* The draw meter, right: slip while weak, terracotta when good, gold when full. */}
      <g className={`draw-meter${d >= 0.85 ? ' full' : d >= 0.5 ? ' good' : ''}${loosed ? ' loosed' : ''}`}>
        <rect className="draw-frame" x={METER.x} y={METER.y} width={METER.w} height={METER.h} rx="8" fill={INK} />
        <rect className="draw-fill" x={METER.x + 5} y={(tick(d)).toFixed(1)} width={METER.w - 10} height={(inner * d).toFixed(1)} rx="4" />
        {[0.5, 0.85].map((f) => (
          <line key={f} x1={METER.x - 8} y1={tick(f)} x2={METER.x + METER.w + 8} y2={tick(f)} stroke={INK} strokeWidth="4" />
        ))}
        {[0.5, 0.85].map((f) => (
          <line key={`in-${f}`} x1={METER.x + 5} y1={tick(f)} x2={METER.x + METER.w - 5} y2={tick(f)} stroke={SLIP} strokeWidth="3" />
        ))}
        <text className="draw-label" x={METER.x + METER.w / 2} y={METER.y + METER.h + 48} textAnchor="middle">DRAW</text>
      </g>
    </svg>
  )
}
