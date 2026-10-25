// The archery range (artist), one SVG so every piece shares a frame: a black-figure
// Scythian archer at the left who draws as the arrow phone is pulled back, the
// target at the right (Greek rings in matte terracotta, cream and black to a gold
// center, a meander rim, on a straw butt), pennants on poles that blow with the
// wind, the bow's live aim ring, the arrow's flight to where it struck and the
// thunk, and the draw meter in the ground band. Painted white-ground, like a
// lekythos: figures on cream, so the terracotta rings read. Multiplayer's
// Toxeia.tsx drives it; toxeia.css animates it.

import type { CSSProperties } from 'react'

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
  /** Just let go: the string snaps forward and the drawing hand flies back. */
  loosed?: boolean
  wind: ToxWind | null
  /** This archer's arrows in the face, the one in flight included. */
  shots: ToxShot[]
  /** The arrow in the air: keep it set for at least FLIGHT_S + 0.6 s after the loose. */
  flying?: ToxShot | null
  /** The archer's seat color: the quiver band and the pennant at the line. */
  seat?: string
}

/** Seconds from the loose to the thunk. */
export const FLIGHT_S = 0.55

const INK = '#1f1612'
const CLAY = '#c96b3c'
const SLIP = '#f1dfc4'
const GOLD = '#e2bd6c'

type P = [number, number]

// The frame: 1600 × 700. Ground line at 600.
const GROUND = 600
const TARGET: P = [1090, 330]
const R = 200 // the face's radius
const CLAY_DEEP = '#a9532d'
/** Ten equal rings, scored 10 in the gold to 1 at the rim (the module's ring =
 *  10 − floor(r / 0.1)): outer radius (of R) and fill, outside in, paired like an
 *  archery face in the pots' colors. Ring 1 (0.9–1) is the meander rim, drawn
 *  separately. The phone's target uses the same rings. */
const RINGS: Array<[number, string]> = [
  [0.9, CLAY_DEEP], [0.8, SLIP], [0.7, SLIP], [0.6, INK], [0.5, INK], [0.4, CLAY], [0.3, CLAY], [0.2, GOLD], [0.1, GOLD],
]

// The archer, in his own 220 × 240 frame facing right, placed at ARCHER.
const ARCHER = { x: 40, y: GROUND - 232 * 1.65, k: 1.65 }
const BOW_HAND: P = [176, 64]
const BOW_SHOULDER: P = [112, 80]
const DRAW_SHOULDER: P = [92, 78]
const NOCK_REST: P = [169, 64]
const NOCK_FULL: P = [124, 60]
const UPPER = 34
const FORE = 50

const toWorld = ([x, y]: P): P => [ARCHER.x + x * ARCHER.k, ARCHER.y + y * ARCHER.k]
const lerp = (a: P, b: P, t: number): P => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]
const clamp = (v: number, a: number, b: number) => Math.min(b, Math.max(a, v))

/** The elbow that puts the hand at `t`, riding up and back (an archer's draw). */
function elbow(s: P, t: P): P {
  const dx = t[0] - s[0]
  const dy = t[1] - s[1]
  const d = clamp(Math.hypot(dx, dy), Math.abs(UPPER - FORE) + 1, UPPER + FORE - 0.5)
  const a = Math.atan2(dy, dx)
  const phi = Math.acos(clamp((UPPER * UPPER + d * d - FORE * FORE) / (2 * UPPER * d), -1, 1))
  return [s[0] + UPPER * Math.cos(a - phi), s[1] + UPPER * Math.sin(a - phi)]
}

/** A point on the target face, in the frame (it may lie off the face). */
const onFace = (x: number, y: number): P => [TARGET[0] + clamp(x, -1.7, 1.7) * R, TARGET[1] - clamp(y, -1.6, 1.6) * R]

/** The meander round the rim: one key per step, between r 0.9 and 1. */
function rimPath(): string {
  const n = 40
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

/** A pennant's angle: it streams the way the wind blows, and hangs when it's still. */
function pennantAngle(wind: ToxWind | null): number {
  const s = wind ? clamp(wind.speed / 5, 0, 1) : 0
  const target = wind ? -wind.toward : 90
  const diff = ((target - 90 + 540) % 360) - 180
  return 90 + diff * Math.max(0.15, s)
}

export default function Range({ aim, draw, nocked, loosed = false, wind, shots, flying, seat }: RangeProps) {
  const d = nocked ? clamp(draw, 0, 1) : 0
  const nock = nocked ? lerp(NOCK_REST, NOCK_FULL, d) : NOCK_REST
  const hand: P = nocked ? nock : loosed ? [98, 50] : [132, 100]
  const el = elbow(DRAW_SHOULDER, hand)
  const tipY = 3 * d
  const tipX = 170 - 6 * d
  const bowPath = `M${tipX} ${10 + tipY} C198 26 192 50 ${BOW_HAND[0]} ${BOW_HAND[1]} C192 78 198 102 ${tipX} ${118 - tipY}`
  const stringPath = `M${tipX} ${10 + tipY} L${nock[0]} ${nock[1]} L${tipX} ${118 - tipY}`
  // The nocked arrow points from the string through the bow hand.
  const dir = (() => {
    const vx = BOW_HAND[0] - nock[0]
    const vy = BOW_HAND[1] - nock[1]
    const l = Math.hypot(vx, vy) || 1
    return [vx / l, vy / l] as P
  })()
  const arrowTip: P = [nock[0] + dir[0] * 82, nock[1] + dir[1] * 82]

  const angle = pennantAngle(wind)
  const flutter = wind ? `${clamp(1.5 - wind.speed * 0.18, 0.35, 1.5).toFixed(2)}s` : '2s'
  const launch = toWorld([BOW_HAND[0] + 10, BOW_HAND[1]])
  const ringAim = aim ? onFace(aim.x, aim.y) : null

  return (
    <svg className="range-art" viewBox="0 0 1600 700" role="img" aria-label="The archery range">
      <defs>
        <pattern id="tox-straw" width="14" height="14" patternUnits="userSpaceOnUse" patternTransform="rotate(28)">
          <rect width="14" height="14" fill="#d8b36a" />
          <path d="M0 3 H14 M0 10 H14" stroke="#b8914a" strokeWidth="2" />
        </pattern>
      </defs>

      {/* The ground band, terracotta, with a meander along its top. */}
      <rect className="ground" x="0" y={GROUND} width="1600" height="100" fill={CLAY} />
      <line x1="0" y1={GROUND} x2="1600" y2={GROUND} stroke={INK} strokeWidth="5" />

      {/* Pennants: one by the target, one down the range. */}
      {[760, 1420].map((x, i) => (
        <g key={x} className="pennant">
          <line x1={x} y1={GROUND} x2={x} y2={150} stroke={INK} strokeWidth="7" strokeLinecap="round" />
          <circle cx={x} cy={146} r="8" fill={INK} />
          <g transform={`translate(${x} 156) rotate(${angle.toFixed(1)})`}>
            <g className="flag" style={{ '--flutter': flutter, animationDelay: `${-i * 0.3}s` } as CSSProperties}>
              <path d="M0 -26 L150 0 L0 26 Z" fill={i ? GOLD : seat ?? '#c8452c'} stroke={INK} strokeWidth="4" strokeLinejoin="round" />
              <path d="M0 -12 L58 0 L0 12" fill="none" stroke={INK} strokeWidth="3" />
            </g>
            <path className="ribbon" style={{ '--flutter': flutter } as CSSProperties} d="M0 34 C40 50 80 18 120 34 S190 44 220 30" fill="none" stroke={INK} strokeWidth="6" strokeLinecap="round" />
          </g>
        </g>
      ))}

      {/* The target on its straw butt and stand. */}
      <g className="stand" stroke={INK} strokeWidth="12" strokeLinecap="round">
        <line x1={TARGET[0] - 110} y1={TARGET[1] + 170} x2={TARGET[0] - 165} y2={GROUND} />
        <line x1={TARGET[0] + 110} y1={TARGET[1] + 170} x2={TARGET[0] + 165} y2={GROUND} />
        <line x1={TARGET[0] - 140} y1={GROUND - 60} x2={TARGET[0] + 140} y2={GROUND - 60} strokeWidth="9" />
      </g>
      <g key={flying?.id ?? 'still'} className={`target${flying ? ' thunk' : ''}`} style={{ '--flight': `${FLIGHT_S}s` } as CSSProperties}>
        <circle cx={TARGET[0]} cy={TARGET[1]} r={R * 1.14} fill="url(#tox-straw)" stroke={INK} strokeWidth="5" />
        <circle cx={TARGET[0]} cy={TARGET[1]} r={R} fill={INK} />
        <path d={RIM} fill="none" stroke={GOLD} strokeWidth="3.5" />
        {RINGS.map(([f, fill]) => (
          <circle key={f} cx={TARGET[0]} cy={TARGET[1]} r={R * f} fill={fill} stroke={fill === INK ? SLIP : INK} strokeWidth={fill === INK ? 1.5 : 2.5} />
        ))}
        {shots.map((s) => {
          const [x, y] = onFace(s.x, s.y)
          return (
            <g key={s.id} className={`stuck${flying?.id === s.id ? ' fresh' : ''}`}>
              <circle cx={x} cy={y} r="9" fill={INK} stroke={SLIP} strokeWidth="2.5" />
              <line x1={x} y1={y} x2={x - 34} y2={y + 22} stroke={INK} strokeWidth="6" strokeLinecap="round" />
              <path d={`M${x - 34} ${y + 22} l-16 -4 l6 -10 Z M${x - 34} ${y + 22} l-6 14 l12 -2 Z`} fill={seat ?? CLAY} stroke={INK} strokeWidth="2" />
            </g>
          )
        })}
      </g>

      {/* The thunk: a cut-paper star where it struck, after the flight. */}
      {flying && (() => {
        const [x, y] = onFace(flying.x, flying.y)
        return (
          <g key={`thunk-${flying.id}`} transform={`translate(${x} ${y})`}>
            <g className="thunk-spark" style={{ '--flight': `${FLIGHT_S}s` } as CSSProperties}>
              <polygon points="0,-46 9,-14 44,-26 16,2 40,34 4,16 -14,46 -10,10 -46,6 -14,-8" fill={SLIP} stroke={INK} strokeWidth="3" strokeLinejoin="round" />
              <circle r="26" fill="none" stroke={INK} strokeWidth="4" className="shock" />
            </g>
          </g>
        )
      })()}

      {/* The arrow in flight: an arc from the bow to where it struck. */}
      {flying && (() => {
        const [x, y] = onFace(flying.x, flying.y)
        const midX = (launch[0] + x) / 2
        const midY = Math.min(launch[1], y) - 70
        return (
          <g key={`flight-${flying.id}`} className="flight">
            <g>
              <line x1="-70" y1="0" x2="0" y2="0" stroke={INK} strokeWidth="6" strokeLinecap="round" />
              <polygon points="0,-9 22,0 0,9" fill={INK} />
              <path d="M-70 0 l-14 -12 l20 0 Z M-70 0 l-14 12 l20 0 Z" fill={seat ?? CLAY} stroke={INK} strokeWidth="2" />
              <animateMotion dur={`${FLIGHT_S}s`} fill="freeze" rotate="auto" calcMode="spline" keyTimes="0;1" keyPoints="0;1" keySplines="0.2 0 0.6 1"
                path={`M${launch[0].toFixed(0)} ${launch[1].toFixed(0)} Q${midX.toFixed(0)} ${midY.toFixed(0)} ${x.toFixed(0)} ${y.toFixed(0)}`} />
              <animate attributeName="opacity" begin={`${FLIGHT_S}s`} dur="0.01s" to="0" fill="freeze" />
            </g>
          </g>
        )
      })()}

      {/* The live aim: a thin ring with four ticks, cream on a black keyline. */}
      {ringAim && (
        <g className="aim" style={{ transform: `translate(${ringAim[0]}px, ${ringAim[1]}px)` }}>
          <circle r="30" fill="none" stroke={INK} strokeWidth="10" />
          <circle r="30" fill="none" stroke={SLIP} strokeWidth="5" />
          {[0, 90, 180, 270].map((a) => (
            <line key={a} x1="0" y1="-38" x2="0" y2="-54" stroke={SLIP} strokeWidth="5" strokeLinecap="round" transform={`rotate(${a})`} />
          ))}
        </g>
      )}

      {/* The archer: a Scythian, pointed cap and quiver, as on the pots. */}
      <g className={`archer${nocked ? ' drawing' : ''}${loosed ? ' loosed' : ''}`} transform={`translate(${ARCHER.x} ${ARCHER.y}) scale(${ARCHER.k})`}>
        <g stroke={INK} strokeLinecap="round">
          <line x1="86" y1="140" x2="72" y2="186" strokeWidth="16" />
          <line x1="72" y1="186" x2="60" y2="228" strokeWidth="11" />
          <line x1="60" y1="228" x2="76" y2="231" strokeWidth="8" />
          <line x1="100" y1="140" x2="124" y2="184" strokeWidth="16" />
          <line x1="124" y1="184" x2="130" y2="228" strokeWidth="11" />
          <line x1="130" y1="228" x2="148" y2="231" strokeWidth="8" />
        </g>
        <ellipse cx="94" cy="138" rx="16" ry="11" fill={INK} />
        {/* The quiver on his back, its band in his seat color. */}
        <polygon points="70,92 82,88 92,138 80,142" fill={INK} />
        <line x1="73" y1="104" x2="85" y2="100" stroke={seat ?? CLAY} strokeWidth="4" />
        <path d="M70 92 l-6 -12 M76 90 l-2 -14 M82 88 l3 -12" stroke={INK} strokeWidth="3" strokeLinecap="round" />
        <polygon points="80,74 114,76 104,136 84,134" fill={INK} />
        <path d="M90 100 Q102 106 112 99 M86 126 L104 128" stroke={CLAY} strokeWidth="1.4" fill="none" strokeLinecap="round" />
        <circle cx="113" cy="54" r="12" fill={INK} />
        <polygon points="100,56 127,50 118,38 95,20" fill={INK} />
        <path d="M100 52 L120 47" stroke={CLAY} strokeWidth="1.3" strokeLinecap="round" />
        <polygon points="118,62 129,72 112,70" fill={INK} />
        {/* The bow arm, out straight; the bow; the string; the arrow on it. */}
        <line x1={BOW_SHOULDER[0]} y1={BOW_SHOULDER[1]} x2={BOW_HAND[0]} y2={BOW_HAND[1]} stroke={INK} strokeWidth="11" strokeLinecap="round" />
        <path className="bow" d={bowPath} fill="none" stroke={INK} strokeWidth="6" strokeLinecap="round" />
        <path className="string" d={stringPath} fill="none" stroke={INK} strokeWidth="1.6" />
        {nocked && (
          <g className="nocked">
            <line x1={nock[0]} y1={nock[1]} x2={arrowTip[0]} y2={arrowTip[1]} stroke={INK} strokeWidth="2.6" strokeLinecap="round" />
            <polygon points={`${arrowTip[0] + dir[0] * 9},${arrowTip[1] + dir[1] * 9} ${arrowTip[0] - dir[1] * 4},${arrowTip[1] + dir[0] * 4} ${arrowTip[0] + dir[1] * 4},${arrowTip[1] - dir[0] * 4}`} fill={INK} />
          </g>
        )}
        <circle cx={BOW_HAND[0]} cy={BOW_HAND[1]} r="6.5" fill={INK} />
        {/* The drawing arm: shoulder, elbow up and back, the hand on the string. */}
        <path className="draw-arm" d={`M${DRAW_SHOULDER[0]} ${DRAW_SHOULDER[1]} L${el[0].toFixed(1)} ${el[1].toFixed(1)} L${hand[0].toFixed(1)} ${hand[1].toFixed(1)}`} fill="none" stroke={INK} strokeWidth="10" strokeLinecap="round" strokeLinejoin="round" />
        <circle cx={hand[0]} cy={hand[1]} r="6" fill={INK} />
      </g>

      {/* The draw meter, in the ground band under the archer. */}
      <g className={`draw-meter${d >= 0.85 ? ' full' : d >= 0.5 ? ' good' : ''}`} transform="translate(60 626)">
        <text x="0" y="36" className="draw-label">DRAW</text>
        <rect x="150" y="8" width="360" height="40" rx="6" fill={INK} />
        <rect className="draw-fill" x="154" y="12" width={(352 * d).toFixed(1)} height="32" rx="3" />
        <line x1={154 + 352 * 0.5} y1="8" x2={154 + 352 * 0.5} y2="48" stroke={SLIP} strokeWidth="3" />
        <line x1={154 + 352 * 0.85} y1="8" x2={154 + 352 * 0.85} y2="48" stroke={SLIP} strokeWidth="3" />
      </g>
    </svg>
  )
}
