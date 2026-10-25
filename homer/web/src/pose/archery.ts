// Archery from the webcam (SPEC "Toxeia", camera): the bow arm aims and the drawing hand draws. The camera sits
// by the target (the laptop on the table, looking up), so the bow arm points straight at it: foreshortened, and
// MediaPipe's depth for it is too rough to aim with. Everything is read in the 2D image instead, in shoulder
// widths (the shoulders are square to the camera), which a recording of Matus showed is steady:
//   - the bow arm is the lower hand (the drawing hand comes up to the jaw), locked per archer once it's clear;
//   - AIM is the bow wrist's offset from its shoulder, zeroed per arrow once it holds still (like the phone);
//     AIM_SW shoulder widths from the zero reach the target's rim;
//   - DRAW blends the drawing wrist's height against its shoulder (below at the nock, at the jaw at full draw)
//     with the gap between the wrists (together at the nock, a shoulder and a half apart at full draw).
// Pure apart from the clock it's given, so the numbers can be tuned against a recording.

import type { NormalizedLandmark } from '@mediapipe/tasks-vision'
import type { ArcherPose, CameraState, PosePoint } from '../toxeia/CameraView'
import type { PoseFrame } from './camera'

// BlazePose landmark indices (the person's left and right: facing the camera, their left is the image's right).
const NOSE = 0
const L_SHOULDER = 11, R_SHOULDER = 12, L_ELBOW = 13, R_ELBOW = 14, L_WRIST = 15, R_WRIST = 16, L_HIP = 23, R_HIP = 24

const AIM_SW = 0.8 // bow-wrist travel from the zero, in shoulder widths, that reaches the rim (~20° of swing)
const RIM_M = 0.61 // the rim in the module's aim units (±1 = ±1 m on the face; the face is 0.61 m)
const NOCK_Y = 0.35 // the drawing wrist this far below its shoulder (shoulder widths): draw 0
const FULL_Y = -0.1 // …at about shoulder height (the jaw, seen from below): draw 1
const NOCK_GAP = 0.75 // the wrists this far apart (shoulder widths): draw 0
const FULL_GAP = 1.3 // …this far: draw 1
const HAND_SPLIT = 0.35 // one wrist this much lower than the other (shoulder widths) says which arm is the bow
const VISIBLE = 0.5 // the shoulders and wrists must be at least this visible
const STEADY_SW = 0.1 // the bow wrist counts as still while it moves less than this…
const STEADY_MS = 300 // …for this long: then the arrow's zero is taken
const ZERO_CAP_MS = 1200 // …or at most this long into the arrow, still or not (DWUX: a hold of 9.7 s froze the aim)
const LOST_MS = 1000 // no archer this long: the phones take over (the caller decides)
const AIM_SMOOTH_MS = 120 // aim smoothing: the pose jitters ~5-10x the phone's (DWUX)
const DRAW_SMOOTH_MS = 70 // draw smoothing
const DRAW_HOLD_MS = 800 // the draw sent is the peak of this long: the hand moves forward as the thumb looses

export type ArcheryReading = {
  state: CameraState // searching (nobody), steadying (zeroing the arrow), tracking (live)
  pose: ArcherPose | null // for the corner view: raw image coordinates
  yaw: number // -1..1, the module's units: ±1 = ±1 m on the face; + is the archer's right
  pitch: number // + is up
  draw: number // 0..1
  lostMs: number // how long nobody has been tracked (0 while tracked)
}

type Arm = { shoulder: number; elbow: number; wrist: number }
const LEFT: Arm = { shoulder: L_SHOULDER, elbow: L_ELBOW, wrist: L_WRIST }
const RIGHT: Arm = { shoulder: R_SHOULDER, elbow: R_ELBOW, wrist: R_WRIST }

const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v))
const point = (l: NormalizedLandmark): PosePoint => ({ x: l.x, y: l.y })
const unit = (v: number, from: number, to: number) => clamp((v - from) / (to - from), 0, 1)

export class ArcheryMapper {
  private archer = '' // the archer up: a new one re-picks the bow arm
  private arrow = '' // the arrow being aimed: a new one re-zeroes
  private bow: Arm | null = null
  private split: { arm: 'left' | 'right' | null; frames: number } = { arm: null, frames: 0 } // the lower hand, frames in a row
  private zero: { x: number; y: number } | null = null
  private still: { at: number; x: number; y: number } | null = null
  private smooth: { x: number; y: number; draw: number; at: number } | null = null
  private arrowAt: number | null = null // the first frame of this arrow (its zero is due by ZERO_CAP_MS)
  private draws: { at: number; draw: number }[] = [] // the last DRAW_HOLD_MS of draws, for the peak
  private seenAt = -Infinity
  private last: ArcheryReading = { state: 'searching', pose: null, yaw: 0, pitch: 0, draw: 0, lostMs: 0 }
  /** Test halls: the raw signals of the last frame, for tuning against a recording. */
  probe: Record<string, number> = {}

  /** The arrow up, as "archer.arrow" (or '' for none): a new arrow re-zeroes, a new archer re-picks the bow arm. */
  newArrow(key: string): void {
    if (key === this.arrow) return
    this.arrow = key
    this.zero = null
    this.still = null
    this.arrowAt = null
    const archer = key.split('.')[0]
    if (archer !== this.archer) {
      this.archer = archer
      this.bow = null
      this.split = { arm: null, frames: 0 }
    }
  }

  update(frame: PoseFrame): ArcheryReading {
    const { image, at } = frame
    const seen = image && [L_SHOULDER, R_SHOULDER, L_WRIST, R_WRIST].every((i) => (image[i]?.visibility ?? 0) >= VISIBLE)
    if (!seen) {
      const lostMs = Number.isFinite(this.seenAt) ? at - this.seenAt : Infinity
      this.last = { ...this.last, state: 'searching', pose: null, lostMs }
      if (lostMs > LOST_MS) this.smooth = null // back in view: the arrow resumes on its zero, unsmoothed from there
      return this.last
    }
    this.seenAt = at

    // Image coordinates in shoulder widths, each wrist against its own shoulder (y down).
    const sw = Math.hypot(image[L_SHOULDER].x - image[R_SHOULDER].x, image[L_SHOULDER].y - image[R_SHOULDER].y) || 1
    const off = (arm: Arm) => ({ x: (image[arm.wrist].x - image[arm.shoulder].x) / sw, y: (image[arm.wrist].y - image[arm.shoulder].y) / sw })
    const left = off(LEFT), right = off(RIGHT)

    // The bow arm: the lower hand, once the hands split clearly for a few frames; kept for the archer.
    if (!this.bow) {
      const lower = left.y - right.y > HAND_SPLIT ? 'left' : right.y - left.y > HAND_SPLIT ? 'right' : null
      this.split = lower && lower === this.split.arm ? { arm: lower, frames: this.split.frames + 1 } : { arm: lower, frames: lower ? 1 : 0 }
      if (lower && this.split.frames >= 5) this.bow = lower === 'left' ? LEFT : RIGHT
    }
    const bow = this.bow ?? (left.y > right.y ? LEFT : RIGHT) // until then, the lower hand frame by frame
    const drawArm = bow === LEFT ? RIGHT : LEFT
    const aim = bow === LEFT ? left : right
    const hand = drawArm === LEFT ? left : right
    const gap = Math.hypot(image[L_WRIST].x - image[R_WRIST].x, image[L_WRIST].y - image[R_WRIST].y) / sw
    const rawDraw = (unit(hand.y, NOCK_Y, FULL_Y) + unit(gap, NOCK_GAP, FULL_GAP)) / 2
    this.probe = { sw, lwx: left.x, lwy: left.y, rwx: right.x, rwy: right.y, gap, bowLeft: bow === LEFT ? 1 : 0, rawDraw }

    // Smooth (an exponential filter on the frame clock), so a jittery landmark doesn't shake the aim.
    const s = this.smooth
    const ease = (ms: number) => (s ? 1 - Math.exp(-(at - s.at) / ms) : 1)
    const ka = ease(AIM_SMOOTH_MS), kd = ease(DRAW_SMOOTH_MS)
    const next = {
      x: s ? s.x + (aim.x - s.x) * ka : aim.x,
      y: s ? s.y + (aim.y - s.y) * ka : aim.y,
      draw: s ? s.draw + (rawDraw - s.draw) * kd : rawDraw,
      at,
    }
    this.smooth = next
    this.draws = this.draws.filter((d) => at - d.at <= DRAW_HOLD_MS)
    this.draws.push({ at, draw: next.draw })
    const heldDraw = Math.max(...this.draws.map((d) => d.draw))

    // The arrow's zero: the bow wrist held still for STEADY_MS (as the phone zeroes at each arrow), and taken
    // anyway ZERO_CAP_MS into the arrow, so the aim never sits frozen at the centre.
    if (!this.zero) {
      this.arrowAt ??= at
      const st = this.still
      if (!st || Math.hypot(next.x - st.x, next.y - st.y) > STEADY_SW) this.still = { at, x: next.x, y: next.y }
      if ((this.still && at - this.still.at >= STEADY_MS) || at - this.arrowAt >= ZERO_CAP_MS) this.zero = { x: next.x, y: next.y }
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
    // The archer faces the camera, so their right is the image's left: yaw flips x; up is -y.
    const toFace = (sws: number) => clamp((sws / AIM_SW) * RIM_M, -1, 1)
    this.last = {
      state: this.zero ? 'tracking' : 'steadying',
      pose,
      yaw: this.zero ? toFace(-(next.x - this.zero.x)) : 0,
      pitch: this.zero ? toFace(-(next.y - this.zero.y)) : 0,
      draw: heldDraw,
      lostMs: 0,
    }
    return this.last
  }

  get reading(): ArcheryReading {
    return this.last
  }
}

export { LOST_MS }
