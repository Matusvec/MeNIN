// Smoothing and motion for the scene, ported from the iOS app
// (ios/Homer/Scene/SceneMotion.swift). Takes emotion weights (~every 1.5 s) and
// prosody (~20 Hz) and produces the uniforms and fleck buffer the renderer draws
// each frame. Everything is integrated over time, so a change in speed never
// makes the shapes jump.

import { DEBATE_REST, EMOTIONS, MOOD_COUNT, STYLES, THEME_MOTION, ink, type EmotionWeights, type FieldMotion, type SceneTheme } from './moods'

export const RIPPLE_COUNT = 6
export const FLECK_COUNT = 360
/** Floats per fleck in the vertex buffer: x, y, size, alpha, r, g, b, shape, angle. */
export const FLECK_STRIDE = 9

const WASH_SECONDS = 1.6
const WASH_COOLDOWN = 2.4

const ease = (from: number, to: number, tau: number, dt: number) => from + (to - from) * (1 - Math.exp(-dt / tau))
const rand = (a: number, b: number) => a + Math.random() * (b - a)
const smooth = (a: number, b: number, x: number) => {
  const t = Math.min(1, Math.max(0, (x - a) / (b - a)))
  return t * t * (3 - 2 * t)
}

export type Uniforms = {
  a: number[] // res.xy, time, flow
  b: number[] // drift.xy, turb, jag
  c: number[] // detail, scale, tremble, lightY
  d: number[] // lightAmt, soft, lift, wash
  washInk: number[]
  washFrom: number[]
  rip: Float32Array // RIPPLE_COUNT × (x, y, age, strength)
  w: Float32Array // MOOD_COUNT weights
  e: number[] // tilt, amp
}

export class SceneMotion {
  aspect = 1
  reducedMotion = false
  theme: SceneTheme = 'poetry'
  /** Where the words appear on screen (scene units): onsets and word ripples come from here,
   *  so a flash comes out of the poet's mouth. Defaults to the lower middle. */
  private mouth: [number, number] = [0, -0.15]
  readonly flecks = new Float32Array(FLECK_COUNT * FLECK_STRIDE)
  readonly uniforms: Uniforms = {
    a: [0, 0, 0, 0],
    b: [0, 0, 0, 0],
    c: [0, 0, 0, 0],
    d: [0, 0, 0, -1],
    washInk: [0, 0, 0, 0],
    washFrom: [0, 0, 0, 0],
    rip: new Float32Array(RIPPLE_COUNT * 4),
    w: new Float32Array(MOOD_COUNT),
    e: [0, 0, 0, 0],
  }

  private target = new Float32Array(MOOD_COUNT)
  private wts = new Float32Array(MOOD_COUNT)
  private dominant = 0
  private clock = 0
  private lastWash = -10
  private washStart = -10

  private rawEnergy = 0
  private rawPitch: number | null = null
  private energy = 0
  private energySlow = 0
  private energyBase = 0
  private pitchBase = 160
  private pitchDev = 0
  private lastOnset = 0
  private ripples: number[][] = []
  private punch = 0
  private burstCursor = 0

  private flow = 0
  private drift = [0, 0]

  private pos = new Float32Array(FLECK_COUNT * 2)
  private vel = new Float32Array(FLECK_COUNT * 2)
  private age = new Float32Array(FLECK_COUNT)
  private life = new Float32Array(FLECK_COUNT).fill(1)
  private mood = new Uint8Array(FLECK_COUNT)
  private baseAlpha = new Float32Array(FLECK_COUNT)
  private phase = new Float32Array(FLECK_COUNT)
  private spin = new Float32Array(FLECK_COUNT)

  constructor() {
    this.target[0] = 1
    this.wts[0] = 1
    for (let i = 0; i < FLECK_COUNT; i++) {
      this.spawn(i)
      this.age[i] = Math.random() * this.life[i] // start mid-life so the first frame isn't empty
    }
  }

  get time() {
    return this.clock
  }

  /** True while a voice is live: the renderer runs at 60 fps then. */
  get voiced() {
    return this.rawEnergy > 0.03 || this.punch > 0.05 || this.ripples.length > 0
  }

  /** The rest inks for the current room (debate rests on its own sea). */
  restInks(): [number, number, number, number] {
    return this.theme === 'debate' ? DEBATE_REST : STYLES[0].inks
  }

  /** A new word landed on screen at (fx, fy), as fractions of the viewport: a small
   *  ripple from the text, and the place later onsets come from. */
  word(fx: number, fy: number) {
    this.mouth = [(fx - 0.5) * this.aspect, 0.5 - fy]
    const m = THEME_MOTION[this.theme]
    this.ring(this.mouth, 0.55 * m.strike)
  }

  private ring(at: [number, number], strength: number) {
    this.ripples.push([at[0] + rand(-0.02, 0.02), at[1] + rand(-0.02, 0.02), 0, strength * (this.reducedMotion ? 0.4 : 1)])
    if (this.ripples.length > RIPPLE_COUNT) this.ripples.shift()
  }

  setEmotion(weights: EmotionWeights | null) {
    let values = EMOTIONS.map((e) => Math.max(0, weights?.[e] ?? 0))
    const sum = values.reduce((s, v) => s + v, 0)
    if (sum > 1) values = values.map((v) => v / sum)
    // A flat reading (no clear feeling) settles toward the resting sea instead
    // of marbling all eight palettes at once.
    const total = values.reduce((s, v) => s + v, 0)
    let flatness = 0
    if (total > 0) {
      const entropy = values.reduce((acc, v) => {
        const p = v / total
        return p > 0 ? acc - p * Math.log2(p) : acc
      }, 0)
      flatness = smooth(0.72, 0.97, entropy / Math.log2(EMOTIONS.length))
    }
    const keep = 1 - flatness
    values.forEach((v, i) => (this.target[i + 1] = v * keep))
    this.target[0] = Math.max(0, 1 - total * keep)
  }

  setProsody(energy: number, pitch: number | null) {
    this.rawEnergy = Math.min(1, Math.max(0, energy))
    this.rawPitch = pitch
  }

  /** A drum strike: a stressed syllable landed on the beat. The sea takes the
   *  hit: a big ring from the strike point, the layers jump and settle, and a
   *  burst of flecks scatters from it. Matte: motion and paper, never light. */
  strike(strength = 1) {
    const s = Math.min(1.5, Math.max(0.2, strength)) * THEME_MOTION[this.theme].strike
    const origin = [this.mouth[0] + rand(-0.05, 0.05), this.mouth[1] + rand(-0.04, 0.04)]
    this.ripples.push([origin[0], origin[1], 0, (this.reducedMotion ? 0.8 : 2.2) * s])
    if (this.ripples.length > RIPPLE_COUNT) this.ripples.shift()
    this.lastOnset = this.clock
    this.punch = Math.min(1.6, this.punch + s)
    if (!this.reducedMotion) this.burst(origin, Math.floor(40 * s))
  }

  step(rawDt: number, resX: number, resY: number) {
    const calm = this.reducedMotion ? 0.35 : 1
    const dt = Math.min(rawDt, 0.1)
    this.clock += dt

    // Voice, in real time: 20 Hz prosody eased to the frame rate with no more than
    // ~80 ms of lag either way, plus a slow envelope for overall activity.
    const e = this.rawEnergy
    this.energy = ease(this.energy, e, e > this.energy ? 0.035 : 0.08, dt)
    this.energySlow = ease(this.energySlow, e, 1.4, dt)
    this.energyBase = ease(this.energyBase, this.energy, 0.35, dt)
    const hz = this.rawPitch
    if (hz !== null && hz > 50) {
      this.pitchBase = ease(this.pitchBase, hz, 4, dt)
      const semis = 12 * Math.log2(hz / this.pitchBase)
      this.pitchDev = ease(this.pitchDev, Math.max(-1, Math.min(1, semis / 6)), 0.15, dt)
    } else {
      this.pitchDev = ease(this.pitchDev, 0, 0.6, dt)
    }

    // A sharp rise in loudness is a stressed syllable: a strike ring out of the
    // poet's mouth, its size from how loud, with a few flecks thrown off it.
    const rise = this.energy - this.energyBase
    if (rise > 0.11 && this.energy > 0.18 && this.clock - this.lastOnset > 0.16) {
      this.lastOnset = this.clock
      const m = THEME_MOTION[this.theme]
      const s = Math.min(1.3, Math.max(0.3, this.energy * 1.4)) * m.strike
      this.ring(this.mouth, 1.5 * s)
      this.punch = Math.min(1.6, this.punch + 0.35 * s)
      if (!this.reducedMotion) this.burst(this.mouth, Math.floor(12 * s))
    }
    this.punch = ease(this.punch, 0, 0.32, dt)
    for (const r of this.ripples) r[2] += dt
    this.ripples = this.ripples.filter((r) => r[2] < 3)
    const rip = this.uniforms.rip
    rip.fill(0)
    this.ripples.forEach((r, i) => rip.set([r[0], r[1], r[2], r[3] * calm], i * 4))

    // Mood weights flow toward the classifier's latest reading.
    for (let i = 0; i < MOOD_COUNT; i++) this.wts[i] = ease(this.wts[i], this.target[i], 0.9, dt)

    // Blend every motion parameter by the current weights.
    const F: FieldMotion = { speed: 0, drift: [0, 0], turb: 0, jag: 0, detail: 0, scale: 0, tremble: 0, lightY: 0, lightAmt: 0, soft: 0, lift: 0, tilt: 0, amp: 0 }
    const total = Math.max(this.wts.reduce((s, v) => s + v, 0), 1e-4)
    for (let i = 0; i < MOOD_COUNT; i++) {
      const k = this.wts[i] / total
      const m = STYLES[i].field
      F.speed += k * m.speed
      F.drift[0] += k * m.drift[0]
      F.drift[1] += k * m.drift[1]
      F.turb += k * m.turb
      F.jag += k * m.jag
      F.detail += k * m.detail
      F.scale += k * m.scale
      F.tremble += k * m.tremble
      F.lightY += k * m.lightY
      F.lightAmt += k * m.lightAmt
      F.soft += k * m.soft
      F.lift += k * m.lift
      F.tilt += k * m.tilt
      F.amp += k * m.amp
    }
    // The room's character: debate sharper and quicker, Talk to Homer calmer.
    const T = THEME_MOTION[this.theme]
    F.speed *= T.speed
    F.amp *= T.amp
    F.turb *= T.turb
    F.jag = Math.min(1, F.jag + T.jag)
    F.soft *= T.soft
    const en = this.energy
    // Loudness drives the motion: a full voice runs the sea at more than twice its resting pace.
    this.flow += F.speed * (1 + 1.6 * en + 2.5 * this.punch) * calm * dt
    this.drift[0] += F.drift[0] * (1 + en) * calm * dt
    this.drift[1] += F.drift[1] * (1 + en) * calm * dt

    // When the leading feeling changes, sweep its ink across the frame.
    let lead = 0
    for (let i = 1; i < MOOD_COUNT; i++) if (this.wts[i] > this.wts[lead]) lead = i
    if (lead !== this.dominant && this.wts[lead] > this.wts[this.dominant] + 0.06) {
      this.dominant = lead
      if (this.clock - this.lastWash > WASH_COOLDOWN) {
        this.lastWash = this.clock
        this.washStart = this.clock
        this.uniforms.washInk = [...ink(STYLES[lead].inks[2]), 1]
        this.uniforms.washFrom = [...STYLES[lead].wash, 0]
      }
    }
    const wp = (this.clock - this.washStart) / (WASH_SECONDS / calm)
    const wash = wp >= 0 && wp < 1 ? 1 - Math.pow(1 - wp, 2.2) : -1

    const U = this.uniforms
    U.a = [resX, resY, this.clock, this.flow]
    U.b = [this.drift[0], this.drift[1], F.turb + 0.4 * en, F.jag]
    U.c = [Math.min(1, F.detail + 0.25 * en), F.scale, this.reducedMotion ? 0 : F.tremble * (0.5 + en), F.lightY + 0.12 * this.pitchDev]
    U.d = [F.lightAmt, F.soft, F.lift + 0.12 * en + 0.04 * this.pitchDev + 0.07 * this.punch * calm, wash]
    U.w.set(this.wts)
    U.e = [F.tilt, F.amp + 0.35 * en + 0.1 * this.punch * calm, 0, 0]

    this.stepFlecks(dt * calm)
  }

  // MARK: Flecks

  private pickMood(): number {
    let r = Math.random() * Math.max(this.wts.reduce((s, v) => s + v, 0), 1e-4)
    for (let i = 0; i < MOOD_COUNT; i++) {
      r -= this.wts[i]
      if (r <= 0) return i
    }
    return 0
  }

  private outward(x: number, y: number): [number, number] {
    const r = Math.hypot(x, y)
    return r > 0 ? [x / r, y / r] : [0, 1]
  }

  private spawn(i: number) {
    const m = this.pickMood()
    const style = m === 0 ? { ...STYLES[0], inks: this.restInks() } : STYLES[m]
    const f = style.flecks
    const halfW = this.aspect / 2
    let x = 0
    let y = 0
    switch (f.spawn) {
      case 'bottom':
        x = rand(-halfW, halfW)
        y = -0.54
        break
      case 'top':
        x = rand(-halfW, halfW)
        y = 0.54
        break
      case 'left':
        x = -halfW - 0.04
        y = rand(-0.42, 0.42)
        break
      case 'center': {
        const a = rand(0, Math.PI * 2)
        const r = rand(0, 0.1)
        x = Math.cos(a) * r
        y = Math.sin(a) * r - 0.05
        break
      }
      case 'edges':
        switch (Math.floor(Math.random() * 4)) {
          case 0:
            x = rand(-halfW, halfW)
            y = -0.5
            break
          case 1:
            x = rand(-halfW, halfW)
            y = 0.5
            break
          case 2:
            x = -halfW
            y = rand(-0.5, 0.5)
            break
          default:
            x = halfW
            y = rand(-0.5, 0.5)
        }
        break
      default:
        x = rand(-halfW, halfW)
        y = rand(-0.5, 0.5)
    }
    const [ox, oy] = this.outward(x, y)
    this.pos[i * 2] = x
    this.pos[i * 2 + 1] = y
    this.vel[i * 2] = f.vel[0] + f.radial * 1.6 * ox + rand(-0.01, 0.01)
    this.vel[i * 2 + 1] = f.vel[1] + f.radial * 1.6 * oy + rand(-0.01, 0.01)
    this.age[i] = 0
    this.mood[i] = m
    this.phase[i] = rand(0, Math.PI * 2)
    this.spin[i] = rand(-3, 3)
    // Quiet rooms are sparse: only some flecks wake, more as the voice gets louder.
    const awake = Math.random() < 0.3 + 0.7 * this.energySlow
    this.life[i] = awake ? rand(f.life[0], f.life[1]) : rand(0.4, 1.2)
    this.baseAlpha[i] = awake ? f.alpha : 0
    this.setColor(i, style.inks[f.ink], f.shape, rand(f.size[0], f.size[1]))
  }

  private setColor(i: number, hex: number, shape: number, size: number) {
    const [r, g, b] = ink(hex)
    const j = rand(0.92, 1.06)
    const o = i * FLECK_STRIDE
    this.flecks[o + 2] = size
    this.flecks[o + 4] = Math.min(1, r * j)
    this.flecks[o + 5] = Math.min(1, g * j)
    this.flecks[o + 6] = Math.min(1, b * j)
    this.flecks[o + 7] = shape
  }

  /** Wakes `count` flecks at a point and throws them outward in the leading mood's ink. */
  private burst(origin: number[], count: number) {
    const style = this.dominant === 0 ? { ...STYLES[0], inks: this.restInks() } : STYLES[this.dominant]
    const f = style.flecks
    for (let n = 0; n < count; n++) {
      const i = this.burstCursor
      this.burstCursor = (this.burstCursor + 1) % FLECK_COUNT
      const a = rand(0, Math.PI * 2)
      const dx = Math.cos(a)
      const dy = Math.sin(a) * 0.8 + 0.25
      const r = rand(0, 0.02)
      this.pos[i * 2] = origin[0] + dx * r
      this.pos[i * 2 + 1] = origin[1] + dy * r
      const v = rand(0.28, 0.7)
      this.vel[i * 2] = dx * v
      this.vel[i * 2 + 1] = dy * v
      this.age[i] = 0
      this.life[i] = rand(0.9, 1.7)
      this.mood[i] = this.dominant
      this.phase[i] = rand(0, Math.PI * 2)
      this.spin[i] = rand(-5, 5)
      this.baseAlpha[i] = Math.max(f.alpha, 0.8)
      this.setColor(i, style.inks[f.ink], f.shape, rand(f.size[0], f.size[1]) * 1.2)
    }
  }

  private stepFlecks(dt: number) {
    const pace = 0.55 + 1.3 * this.energy + 0.8 * this.punch
    const halfW = this.aspect / 2
    for (let i = 0; i < FLECK_COUNT; i++) {
      this.age[i] += dt
      const out = Math.abs(this.pos[i * 2]) > halfW + 0.1 || Math.abs(this.pos[i * 2 + 1]) > 0.62
      if (this.age[i] >= this.life[i] || out) this.spawn(i)
      const f = STYLES[this.mood[i]].flecks
      const [ox, oy] = this.outward(this.pos[i * 2], this.pos[i * 2 + 1])
      const gx = f.vel[0] + f.radial * 0.6 * ox
      const gy = f.vel[1] + f.radial * 0.6 * oy
      const kk = 1 - Math.exp(-f.drag * dt)
      const a = this.age[i]
      let vx = this.vel[i * 2] + (gx - this.vel[i * 2]) * kk
      let vy = this.vel[i * 2 + 1] + (gy - this.vel[i * 2 + 1]) * kk
      vx += f.jitter * rand(-0.5, 0.5) * dt * 4 + f.sway * Math.sin(a * 1.3 + this.phase[i]) * dt
      vy += f.jitter * rand(-0.5, 0.5) * dt * 4 + f.bounce * Math.cos(a * 7 + this.phase[i]) * dt * 7
      this.vel[i * 2] = vx
      this.vel[i * 2 + 1] = vy
      this.pos[i * 2] += vx * dt * pace
      this.pos[i * 2 + 1] += vy * dt * pace
      // Fear's flecks vanish as they reach the middle.
      if (f.radial < 0 && Math.hypot(this.pos[i * 2], this.pos[i * 2 + 1]) < 0.06) this.age[i] = this.life[i]

      const t = a / this.life[i]
      const fade = smooth(0, 0.15, t) * (1 - smooth(0.7, 1, t))
      const o = i * FLECK_STRIDE
      this.flecks[o] = this.pos[i * 2]
      this.flecks[o + 1] = this.pos[i * 2 + 1]
      this.flecks[o + 3] = this.baseAlpha[i] * fade
      this.flecks[o + 8] = f.shape === 1 ? Math.atan2(vy, vx) : this.spin[i] * a
    }
  }
}
