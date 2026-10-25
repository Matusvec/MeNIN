// A black-figure boxer's rig (artist). Pure geometry: poses, a two-bone arm IK
// with the elbow kept down, and the shapes of the figure, in a 200 × 240 frame
// facing right (feet at the bottom, the opponent to the right). Boxer.tsx draws it.

/** Which hand: the lead (near the opponent) or the rear. */
export type Hand = 'lead' | 'rear'
/** The punch thrown: straight (jab/cross), hook (around, elbow up), uppercut (up), body (low). */
export type Punch = 'straight' | 'hook' | 'uppercut' | 'body'

/** Where the phone aims, in the fighter's own frame: x 0 (pulled back) … 1 (full
 *  reach toward the opponent), y 0 (head height) … 1 (belly height). */
export type Aim = { x: number; y: number }

type P = [number, number]

export const UPPER = 30
export const FORE = 30
export const LEAD_SHOULDER: P = [114, 80]
export const REAR_SHOULDER: P = [88, 78]

const clamp = (v: number, a: number, b: number) => Math.min(b, Math.max(a, v))
const deg = (r: number) => (r * 180) / Math.PI

/** Shoulder and elbow angles (degrees, clockwise, y down) that put the fist at `t`,
 *  the reach clamped. The elbow hangs below the line from shoulder to fist, or
 *  rides above it for a hook (`elbowUp`). */
export function armAngles(shoulder: P, t: P, elbowUp = false): { shoulder: number; elbow: number } {
  const dx = t[0] - shoulder[0]
  const dy = t[1] - shoulder[1]
  const d = clamp(Math.hypot(dx, dy), Math.abs(UPPER - FORE) + 1, UPPER + FORE - 0.5)
  const a = Math.atan2(dy, dx)
  const cosE = clamp((d * d - UPPER * UPPER - FORE * FORE) / (2 * UPPER * FORE), -1, 1)
  const e = Math.acos(cosE)
  const phi = Math.atan2(FORE * Math.sin(e), UPPER + FORE * Math.cos(e))
  return elbowUp ? { shoulder: deg(a - phi), elbow: deg(e) } : { shoulder: deg(a + phi), elbow: deg(-e) }
}

/** Both fists from the one phone (Matus): they mirror each other at the same
 *  height, raised in guard; a punch throws the hand on the side the phone points
 *  to. `punch` null is the guard. */
export function fists(aim: Aim, hand: Hand | null = null, punch: Punch = 'straight'): {
  lead: P
  rear: P
  leadElbowUp: boolean
  rearElbowUp: boolean
} {
  const ax = clamp(aim.x, 0, 1)
  const ay = clamp(aim.y, 0, 1)
  // Both fists ride at the aim's height, before the face down to the chest.
  const h = 58 + 32 * ay
  const guard = { lead: [148 + 4 * ax, h] as P, rear: [130 + 4 * ax, h + 3] as P }
  if (!hand) return { ...guard, leadElbowUp: false, rearElbowUp: false }
  let fist: P
  let up = false
  switch (punch) {
    case 'hook':
      fist = [158 + 10 * ax, h - 4]
      up = true
      break
    case 'uppercut':
      fist = [148 + 8 * ax, Math.max(38, h - 26)]
      break
    case 'body':
      fist = [150 + 20 * ax, 112 + 16 * ay]
      break
    default:
      fist = [150 + 26 * ax, h - 2]
  }
  return hand === 'lead'
    ? { lead: fist, rear: guard.rear, leadElbowUp: up, rearElbowUp: false }
    : { lead: guard.lead, rear: fist, leadElbowUp: false, rearElbowUp: up }
}

/** A knocked-out fighter's arms, hanging. */
export const KO_FISTS: { lead: P; rear: P } = { lead: [126, 140], rear: [100, 150] }

/** One limb segment: from, to, width. */
export type Seg = [number, number, number, number, number]

/** The figure without its arms: legs, hips, torso, head (drawn as segments and shapes). */
export const LEGS: Seg[] = [
  [88, 140, 78, 182, 18],
  [78, 182, 64, 226, 12],
  [64, 226, 81, 229, 8],
  [100, 140, 122, 180, 18],
  [122, 180, 116, 226, 12],
  [116, 226, 134, 229, 8],
]
export const TORSO = '82,70 119,74 105,136 84,134'
export const HIPS = { cx: 94, cy: 138, rx: 17, ry: 12 }
export const HEAD = { cx: 117, cy: 52, r: 13 }
export const KNOT = { cx: 103, cy: 46, r: 6 }
export const BEARD = '122,60 133,72 116,70'
/** The incisions, scratched through to the clay: chest, belt, thighs. */
export const INCISIONS = ['M92 98 Q104 105 115 98', 'M86 128 L104 130', 'M110 162 Q116 166 118 172', 'M82 160 Q80 166 80 172']
