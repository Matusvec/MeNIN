// Archery from the webcam (SPEC "Toxeia", camera): the bow arm aims and the drawing hand draws. The archer
// faces the screen side-on, bow arm out toward the target (the camera sits by the target), the drawing hand
// pulled back to the jaw. From MediaPipe's 33 pose landmarks:
//   - the bow arm is the straighter arm, chosen at each arrow's zero and kept for the arrow;
//   - AIM is the bow arm's direction in 3D (shoulder to wrist, world landmarks), zeroed per arrow once the arm
//     holds still, like the phone; RIM_DEG of swing from the zero reaches the target's rim;
//   - DRAW is the wrist-to-wrist distance in 3D against the bow arm's length: hands together 0, at the jaw 1.
// Pure apart from the clock it's given, so the numbers can be tuned against a recording.

import type { Landmark, NormalizedLandmark } from '@mediapipe/tasks-vision'
import type { ArcherPose, CameraState, PosePoint } from '../toxeia/CameraView'
import type { PoseFrame } from './camera'

// BlazePose landmark indices.
const NOSE = 0
const L_SHOULDER = 11, R_SHOULDER = 12, L_ELBOW = 13, R_ELBOW = 14, L_WRIST = 15, R_WRIST = 16, L_HIP = 23, R_HIP = 24

const RIM_DEG = 20 // degrees of bow-arm swing from the zero that reach the target's rim (leader)
const RIM_M = 0.61 // the rim in the module's aim units (±1 = ±1 m on the face; the face is 0.61 m)
const NOCK = 0.25 // wrist gap / bow-arm length with the hands together on the string: draw 0
const FULL = 0.9 // ... with the drawing hand back at the jaw: draw 1
const VISIBLE = 0.5 // the arms' landmarks must be at least this visible
const STEADY_DEG = 2 // the bow arm counts as still while it moves less than this…
const STEADY_MS = 400 // …for this long: then the arrow's zero is taken
const LOST_MS = 1000 // no archer this long: the phones take over (the caller decides)
const SMOOTH_MS = 70 // time constant of the aim and draw smoothing (~2 frames at 30 fps)

export type ArcheryReading = {
  state: CameraState // searching (nobody), steadying (zeroing the arrow), tracking (live)
  pose: ArcherPose | null // for the corner view: raw image coordinates
  yaw: number // -1..1, the module's units: ±1 = ±1 m on the face
  pitch: number
  draw: number // 0..1
  lostMs: number // how long nobody has been tracked (0 while tracked)
}

type Arm = { shoulder: number; elbow: number; wrist: number }
const LEFT: Arm = { shoulder: L_SHOULDER, elbow: L_ELBOW, wrist: L_WRIST }
const RIGHT: Arm = { shoulder: R_SHOULDER, elbow: R_ELBOW, wrist: R_WRIST }

const sub = (a: Landmark, b: Landmark) => ({ x: a.x - b.x, y: a.y - b.y, z: a.z - b.z })
const len = (v: { x: number; y: number; z: number }) => Math.hypot(v.x, v.y, v.z)
const dist = (a: Landmark, b: Landmark) => len(sub(a, b))
const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v))
const point = (l: NormalizedLandmark): PosePoint => ({ x: l.x, y: l.y })

/** How straight an arm is: 1 when shoulder, elbow and wrist line up. */
function straightness(w: Landmark[], arm: Arm): number {
  const bones = dist(w[arm.shoulder], w[arm.elbow]) + dist(w[arm.elbow], w[arm.wrist])
  return bones > 0 ? dist(w[arm.shoulder], w[arm.wrist]) / bones : 0
}

/** The bow arm's direction in degrees: yaw (the archer's right +) and pitch (up +), 0/0 pointing straight at
 *  the camera. The camera faces the archer, so the archer's right is the image's left: yaw flips x. */
function direction(w: Landmark[], arm: Arm): { yaw: number; pitch: number } {
  const v = sub(w[arm.wrist], w[arm.shoulder]) // world: x image-right, y down, z away from the camera
  const deg = 180 / Math.PI
  return { yaw: Math.atan2(-v.x, -v.z) * deg, pitch: Math.atan2(-v.y, Math.hypot(v.x, v.z)) * deg }
}

export class ArcheryMapper {
  private arrow = '' // the arrow being aimed (archer.arrow_no): a new one re-zeroes
  private bow: Arm | null = null
  private zero: { yaw: number; pitch: number } | null = null
  private still: { at: number; yaw: number; pitch: number } | null = null
  private smooth: { yaw: number; pitch: number; draw: number; at: number } | null = null
  private seenAt = -Infinity
  private last: ArcheryReading = { state: 'searching', pose: null, yaw: 0, pitch: 0, draw: 0, lostMs: 0 }

  /** A new arrow is up (or none): re-zero and re-pick the bow arm at the next steady hold. */
  newArrow(key: string): void {
    if (key === this.arrow) return
    this.arrow = key
    this.bow = null
    this.zero = null
    this.still = null
  }

  update(frame: PoseFrame): ArcheryReading {
    const { image, world, at } = frame
    const seen = image && world && [L_SHOULDER, R_SHOULDER, L_ELBOW, R_ELBOW, L_WRIST, R_WRIST].every((i) => (image[i]?.visibility ?? 0) >= VISIBLE)
    if (!seen) {
      const lostMs = Number.isFinite(this.seenAt) ? at - this.seenAt : Infinity
      this.last = { ...this.last, state: 'searching', pose: null, lostMs }
      if (lostMs > LOST_MS) this.zero = this.still = this.smooth = null // back in view: zero again
      return this.last
    }
    this.seenAt = at
    // The bow arm: the straighter one, kept once the arrow's zero is taken.
    const bow = this.bow ?? (straightness(world, LEFT) >= straightness(world, RIGHT) ? LEFT : RIGHT)
    const drawArm = bow === LEFT ? RIGHT : LEFT
    const dir = direction(world, bow)
    const armLength = dist(world[bow.shoulder], world[bow.wrist])
    const gap = dist(world[bow.wrist], world[drawArm.wrist])
    const rawDraw = armLength > 0 ? clamp((gap / armLength - NOCK) / (FULL - NOCK), 0, 1) : 0

    // Smooth (an exponential filter on the frame clock), so a jittery landmark doesn't shake the aim.
    const s = this.smooth
    const k = s ? 1 - Math.exp(-(at - s.at) / SMOOTH_MS) : 1
    const next = {
      yaw: s ? s.yaw + (dir.yaw - s.yaw) * k : dir.yaw,
      pitch: s ? s.pitch + (dir.pitch - s.pitch) * k : dir.pitch,
      draw: s ? s.draw + (rawDraw - s.draw) * k : rawDraw,
      at,
    }
    this.smooth = next

    // The arrow's zero: the arm held still for STEADY_MS, as the phone zeroes at each arrow.
    if (!this.zero) {
      const st = this.still
      if (!st || Math.hypot(next.yaw - st.yaw, next.pitch - st.pitch) > STEADY_DEG) this.still = { at, yaw: next.yaw, pitch: next.pitch }
      else if (at - st.at >= STEADY_MS) {
        this.zero = { yaw: next.yaw, pitch: next.pitch }
        this.bow = bow
      }
    }

    const pose: ArcherPose = {
      bowShoulder: point(image[bow.shoulder]),
      bowElbow: point(image[bow.elbow]),
      bowWrist: point(image[bow.wrist]),
      drawShoulder: point(image[drawArm.shoulder]),
      drawElbow: point(image[drawArm.elbow]),
      drawWrist: point(image[drawArm.wrist]),
      nose: point(image[NOSE]),
      hips: [point(image[L_HIP]), point(image[R_HIP])],
    }
    const toFace = (deg: number) => clamp((deg / RIM_DEG) * RIM_M, -1, 1)
    this.last = {
      state: this.zero ? 'tracking' : 'steadying',
      pose,
      yaw: this.zero ? toFace(next.yaw - this.zero.yaw) : 0,
      pitch: this.zero ? toFace(next.pitch - this.zero.pitch) : 0,
      draw: next.draw,
      lostMs: 0,
    }
    return this.last
  }

  get reading(): ArcheryReading {
    return this.last
  }
}

export { LOST_MS }
