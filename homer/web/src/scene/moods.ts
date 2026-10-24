// The scene's look per mood, ported from the iOS app (ios/Homer/Scene/Moods.swift).
// Each mood is four matte inks (dark to light) laid down as flat paper-cut
// layers, plus how the field and the flecks move. `rest` is the idle state:
// on the website, a light Aegean sea under HohHamNap's sky.

export const EMOTIONS = ['anger', 'grief', 'joy', 'awe', 'tenderness', 'fear', 'defiance', 'longing'] as const
export type Emotion = (typeof EMOTIONS)[number]
export type EmotionWeights = Partial<Record<Emotion, number>>

/** Mood order: rest, then the emotions in EMOTIONS order. */
export const MOOD_COUNT = 9

export type FieldMotion = {
  speed: number
  drift: [number, number]
  turb: number
  jag: number
  detail: number
  scale: number
  tremble: number
  lightY: number
  lightAmt: number
  soft: number
  lift: number
  tilt: number
  amp: number
}

export type FleckShape = 0 | 1 | 2 // dot, dash, shard
export type FleckSpawn = 'bottom' | 'top' | 'left' | 'center' | 'edges' | 'anywhere'

export type FleckMotion = {
  spawn: FleckSpawn
  vel: [number, number]
  radial: number
  jitter: number
  bounce: number
  sway: number
  drag: number
  life: [number, number]
  size: [number, number] // CSS px
  shape: FleckShape
  alpha: number
  ink: number
}

/** Where a new mood's ink sweeps in from: xy direction, z 1 from the center, -1 from the rim. */
export type WashFrom = [number, number, number]
const BELOW: WashFrom = [0, 1, 0]
const ABOVE: WashFrom = [0, -1, 0]
const LEFT: WashFrom = [1, 0, 0]
const CENTER: WashFrom = [0, 0, 1]
const RIM: WashFrom = [0, 0, -1]

export type MoodStyle = { inks: [number, number, number, number]; field: FieldMotion; flecks: FleckMotion; wash: WashFrom }

const f = (o: Omit<FieldMotion, 'drift'> & { drift: [number, number] }): FieldMotion => o
const k = (o: FleckMotion): FleckMotion => o

export const STYLES: MoodStyle[] = [
  // rest: a light Aegean sea, faint paper layers, a few slow flecks.
  {
    inks: [0xa9d3e2, 0xc4e3ee, 0xd9eef5, 0xeaf7fb],
    field: f({ speed: 0.05, drift: [0.02, 0], turb: 1.1, jag: 0, detail: 0.2, scale: 0.85, tremble: 0, lightY: -0.45, lightAmt: 0.1, soft: 0.004, lift: 0.06, tilt: -0.45, amp: 0.38 }),
    flecks: k({ spawn: 'anywhere', vel: [0.008, 0.016], radial: 0, jitter: 0.02, bounce: 0, sway: 0.01, drag: 0.2, life: [8, 12], size: [2, 4], shape: 0, alpha: 0.5, ink: 0 }),
    wash: BELOW,
  },
  // anger
  {
    inks: [0x3d0b10, 0xb3161f, 0xec4a1c, 0xff9b52],
    field: f({ speed: 0.4, drift: [0, 0.05], turb: 0.95, jag: 0.6, detail: 0.2, scale: 0.8, tremble: 0.25, lightY: -0.2, lightAmt: 0.15, soft: 0.002, lift: -0.05, tilt: -0.2, amp: 0.5 }),
    flecks: k({ spawn: 'center', vel: [0, 0.04], radial: 0.38, jitter: 1.1, bounce: 0, sway: 0, drag: 0.6, life: [0.9, 1.8], size: [9, 16], shape: 2, alpha: 0.95, ink: 3 }),
    wash: CENTER,
  },
  // grief
  {
    inks: [0x070b1d, 0x12245a, 0x294c98, 0x7f97cb],
    field: f({ speed: 0.04, drift: [0, -0.02], turb: 0.9, jag: 0, detail: 0.15, scale: 0.8, tremble: 0, lightY: -0.7, lightAmt: 0.1, soft: 0.006, lift: -0.06, tilt: 0.7, amp: 0.35 }),
    flecks: k({ spawn: 'top', vel: [0, -0.06], radial: 0, jitter: 0.01, bounce: 0, sway: 0.015, drag: 0.1, life: [7, 11], size: [3, 5], shape: 0, alpha: 0.6, ink: 1 }),
    wash: ABOVE,
  },
  // joy
  {
    inks: [0xe23f7c, 0xff7a59, 0xffc23a, 0xfff0b0],
    field: f({ speed: 0.2, drift: [0.02, 0.05], turb: 1.3, jag: 0.1, detail: 0.25, scale: 0.95, tremble: 0, lightY: -0.1, lightAmt: 0.15, soft: 0.003, lift: 0.02, tilt: 0.3, amp: 0.55 }),
    flecks: k({ spawn: 'bottom', vel: [0, 0.22], radial: 0, jitter: 0.05, bounce: 0.14, sway: 0.03, drag: 0.15, life: [2.5, 4.5], size: [6, 11], shape: 0, alpha: 0.95, ink: 0 }),
    wash: BELOW,
  },
  // awe
  {
    inks: [0x2e2108, 0xa8720f, 0xe8b73a, 0xfff3d2],
    field: f({ speed: 0.09, drift: [0, 0.04], turb: 1.2, jag: 0, detail: 0.25, scale: 0.85, tremble: 0, lightY: -0.35, lightAmt: 0.3, soft: 0.004, lift: 0.02, tilt: -0.55, amp: 0.45 }),
    flecks: k({ spawn: 'bottom', vel: [0, 0.07], radial: 0, jitter: 0.01, bounce: 0, sway: 0.01, drag: 0.05, life: [7, 10], size: [3, 8], shape: 0, alpha: 0.85, ink: 1 }),
    wash: BELOW,
  },
  // tenderness
  {
    inks: [0x47294d, 0xc27596, 0xb6a2e0, 0xf4e4ee],
    field: f({ speed: 0.06, drift: [0.015, 0.01], turb: 1.0, jag: 0, detail: 0.05, scale: 0.8, tremble: 0, lightY: -0.3, lightAmt: 0.12, soft: 0.03, lift: 0.02, tilt: 0.4, amp: 0.4 }),
    flecks: k({ spawn: 'anywhere', vel: [0.01, 0.015], radial: 0, jitter: 0.01, bounce: 0, sway: 0.02, drag: 0.2, life: [6, 9], size: [14, 28], shape: 0, alpha: 0.28, ink: 2 }),
    wash: BELOW,
  },
  // fear
  {
    inks: [0x0b1712, 0x2c5243, 0x6f8f7f, 0xb3bcb6],
    field: f({ speed: 0.18, drift: [0, 0], turb: 1.6, jag: 0.3, detail: 0.45, scale: 1.1, tremble: 1, lightY: -0.5, lightAmt: 0.1, soft: 0.002, lift: -0.06, tilt: 0.1, amp: 0.6 }),
    flecks: k({ spawn: 'edges', vel: [0, 0], radial: -0.09, jitter: 0.5, bounce: 0, sway: 0, drag: 0.3, life: [2.5, 4], size: [2, 4], shape: 0, alpha: 0.85, ink: 3 }),
    wash: RIM,
  },
  // defiance
  {
    inks: [0x1b0838, 0x5a1fd0, 0xae84ff, 0xfbf3ff],
    field: f({ speed: 0.3, drift: [0, 0.03], turb: 1.4, jag: 0.6, detail: 0.3, scale: 0.95, tremble: 0, lightY: -0.15, lightAmt: 0.2, soft: 0.002, lift: -0.04, tilt: -0.3, amp: 0.65 }),
    flecks: k({ spawn: 'center', vel: [0, 0], radial: 0.75, jitter: 0.05, bounce: 0, sway: 0, drag: 1.6, life: [0.8, 1.4], size: [14, 24], shape: 1, alpha: 0.95, ink: 3 }),
    wash: CENTER,
  },
  // longing
  {
    inks: [0x1f1033, 0x593877, 0xc0694a, 0xf2a65a],
    field: f({ speed: 0.06, drift: [0.05, 0], turb: 1.0, jag: 0, detail: 0.2, scale: 0.85, tremble: 0, lightY: -0.35, lightAmt: 0.12, soft: 0.006, lift: 0, tilt: 0.55, amp: 0.4 }),
    flecks: k({ spawn: 'left', vel: [0.06, 0], radial: 0, jitter: 0.01, bounce: 0, sway: 0.01, drag: 0.05, life: [10, 14], size: [10, 18], shape: 1, alpha: 0.6, ink: 3 }),
    wash: LEFT,
  },
]

/** One ink as linear-ish 0...1 RGB (the inks are authored in sRGB and passed through untouched, as on iOS). */
export function ink(hex: number): [number, number, number] {
  return [((hex >> 16) & 255) / 255, ((hex >> 8) & 255) / 255, (hex & 255) / 255]
}
