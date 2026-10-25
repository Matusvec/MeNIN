// A black-figure boxer (artist), drawn from the rig in rig.ts: the body and head
// as one piece, each arm as an upper arm rotating at the shoulder and a forearm
// rotating at the elbow, the fists wrapped in himantes. Fighter B is A mirrored.
// Builder drives it with the phone's aim and the punch thrown; boxing.css
// animates the hit and the KO.

import { BEARD, FORE, HEAD, HIPS, INCISIONS, KNOT, KO_FISTS, LEAD_SHOULDER, LEGS, REAR_SHOULDER, TORSO, UPPER, armAngles, fists, type Aim, type Hand, type Punch } from './rig'

const INK = '#1f1612'
const CLAY = '#c96b3c'

export type FighterProps = {
  /** a faces right; b faces left (A mirrored). */
  side: 'a' | 'b'
  /** The phone's aim in this fighter's frame. */
  aim: Aim
  /** The hand thrown right now (on the side the phone points to), or null for the guard. */
  hand?: Hand | null
  punch?: Punch
  /** fight (the default), hit (shaken), or ko (tips over). */
  state?: 'fight' | 'hit' | 'ko'
  /** The fighter's seat color, for the name pill. */
  seat?: string
  name?: string
}

export default function Fighter({ side, aim, hand = null, punch = 'straight', state = 'fight', seat, name }: FighterProps) {
  const f = state === 'ko' ? { ...KO_FISTS, leadElbowUp: false, rearElbowUp: false } : fists(aim, hand, punch)
  const lead = armAngles(LEAD_SHOULDER, f.lead, f.leadElbowUp)
  const rear = armAngles(REAR_SHOULDER, f.rear, f.rearElbowUp)
  return (
    <div className={`fighter ${side} ${state}${hand ? ' punching' : ''}`} style={seat ? ({ '--seat': seat } as React.CSSProperties) : undefined}>
      <div className="fall">
        <svg className="figure" viewBox="0 0 200 240" aria-hidden="true">
          <Arm at={REAR_SHOULDER} angles={rear} className="arm rear" />
          <g className="f-body">
            <g stroke={INK} strokeLinecap="round">
              {LEGS.map(([x1, y1, x2, y2, w], i) => (
                <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} strokeWidth={w} />
              ))}
            </g>
            <ellipse {...HIPS} fill={INK} />
            <polygon points={TORSO} fill={INK} />
            <circle {...HEAD} fill={INK} />
            <circle {...KNOT} fill={INK} />
            <polygon points={BEARD} fill={INK} />
            <g stroke={CLAY} strokeWidth={1.4} strokeLinecap="round" fill="none">
              {INCISIONS.map((d) => (
                <path key={d} d={d} />
              ))}
            </g>
          </g>
          <Arm at={LEAD_SHOULDER} angles={lead} className="arm lead" />
        </svg>
      </div>
      {name && <span className="fighter-name">{name}</span>}
    </div>
  )
}

/** One arm: the upper arm turns at the shoulder, the forearm at the elbow, and the
 *  fist is wrapped in himantes (the leather thongs, incised in the clay color). */
function Arm({ at, angles, className }: { at: [number, number]; angles: { shoulder: number; elbow: number }; className: string }) {
  return (
    <g className={className} style={{ transform: `translate(${at[0]}px, ${at[1]}px) rotate(${angles.shoulder}deg)` }}>
      <line x1={0} y1={0} x2={UPPER} y2={0} stroke={INK} strokeWidth={13} strokeLinecap="round" />
      <g className="fore" style={{ transform: `translate(${UPPER}px, 0px) rotate(${angles.elbow}deg)` }}>
        <line x1={0} y1={0} x2={FORE} y2={0} stroke={INK} strokeWidth={10} strokeLinecap="round" />
        <circle cx={FORE + 2} cy={0} r={9} fill={INK} />
        <g stroke={CLAY} strokeWidth={1.3} strokeLinecap="round">
          <line x1={FORE - 12} y1={-4.5} x2={FORE - 9} y2={4.5} />
          <line x1={FORE - 7} y1={-4.5} x2={FORE - 4} y2={4.5} />
          <path d={`M${FORE - 1} -6 Q${FORE + 5} 0 ${FORE - 1} 6`} fill="none" />
        </g>
      </g>
    </g>
  )
}
