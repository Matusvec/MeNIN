import Foundation
import simd

// Smoothing and motion for the scene. Takes emotion weights (~every 1.5 s)
// and prosody (15-60 Hz), and produces the uniforms and fleck buffer the
// renderer draws each frame. Everything is integrated over time, so a change
// in speed never makes the shapes jump.

let moodCount = Mood.allCases.count
let rippleCount = 6
let fleckCount = 360

// Mirrors FieldUniforms in Scene.metal. Every member is a SIMD4<Float>, so
// the layout matches the Metal struct exactly.
struct FieldUniforms {
    var a = SIMD4<Float>.zero // res.xy, time, flow
    var b = SIMD4<Float>.zero // drift.xy, turb, jag
    var c = SIMD4<Float>.zero // detail, scale, tremble, lightY
    var d = SIMD4<Float>.zero // lightAmt, soft, lift, wash
    var washInk = SIMD4<Float>.zero
    var washFrom = SIMD4<Float>.zero
    var rip: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) =
        (.zero, .zero, .zero, .zero, .zero, .zero)
    var w: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) = (.zero, .zero, .zero)
    var e = SIMD4<Float>.zero // tilt, amp
}

// Mirrors Fleck in Scene.metal.
struct Fleck {
    var p = SIMD4<Float>.zero // x, y, size (points), alpha
    var c = SIMD4<Float>.zero // rgb, shape
    var r = SIMD4<Float>.zero // angle
}

private let washSeconds: Float = 1.6
private let washCooldown: Float = 2.4

@inline(__always) private func ease(_ from: Float, _ to: Float, _ tau: Float, _ dt: Float) -> Float {
    from + (to - from) * (1 - exp(-dt / tau))
}
@inline(__always) private func rand(_ r: ClosedRange<Float>) -> Float { Float.random(in: r) }
@inline(__always) private func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
    let t = min(1, max(0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)
}
@inline(__always) private func outward(_ p: SIMD2<Float>) -> SIMD2<Float> {
    let r = simd_length(p)
    return r > 0 ? p / r : [0, 1]
}

final class SceneMotion {
    private(set) var uniforms = FieldUniforms()
    private(set) var flecks = [Fleck](repeating: Fleck(), count: fleckCount)

    var aspect: Float = 1
    var reducedMotion = false

    // Mood weights: target from the classifier, current after smoothing. Slot 0 is rest.
    private var target = [Float](repeating: 0, count: moodCount)
    private var w = [Float](repeating: 0, count: moodCount)
    private var dominant = 0
    private var clock: Float = 0
    private var lastWash: Float = -10
    private var washStart: Float = -10

    // Voice.
    private var rawEnergy: Float = 0
    private var rawPitch: Float?
    private var energy: Float = 0
    private var energySlow: Float = 0
    private var energyBase: Float = 0
    private var pitchBase: Float = 160
    private var pitchDev: Float = 0
    private var lastOnset: Float = 0
    private var ripples: [SIMD4<Float>] = [] // x, y, age, strength

    private var flow: Float = 0
    private var drift = SIMD2<Float>.zero

    // Flecks.
    private var pos = [SIMD2<Float>](repeating: .zero, count: fleckCount)
    private var vel = [SIMD2<Float>](repeating: .zero, count: fleckCount)
    private var age = [Float](repeating: 0, count: fleckCount)
    private var life = [Float](repeating: 1, count: fleckCount)
    private var mood = [Int](repeating: 0, count: fleckCount)
    private var baseAlpha = [Float](repeating: 0, count: fleckCount)
    private var phase = [Float](repeating: 0, count: fleckCount)
    private var spin = [Float](repeating: 0, count: fleckCount)

    init() {
        target[0] = 1
        w[0] = 1
        for i in 0..<fleckCount {
            spawn(i)
            age[i] = Float.random(in: 0...1) * life[i] // start mid-life so the first frame isn't empty
        }
    }

    func setEmotion(_ weights: EmotionWeights) {
        var values = Emotion.allCases.map { Float(max(0, weights[$0])) }
        let sum = values.reduce(0, +)
        if sum > 1 { values = values.map { $0 / sum } }
        // A flat reading (no clear feeling, e.g. EmotionWeights.neutral) settles
        // toward the resting sea instead of marbling all eight palettes at once.
        let total = values.reduce(0, +)
        var flatness: Float = 0
        if total > 0 {
            let entropy = values.reduce(Float(0)) { acc, v in
                let p = v / total
                return p > 0 ? acc - p * log2(p) : acc
            }
            flatness = smooth(0.72, 0.97, entropy / log2(Float(Emotion.allCases.count)))
        }
        let keep = 1 - flatness
        for (i, e) in Emotion.allCases.enumerated() {
            target[Mood(e).rawValue] = values[i] * keep
        }
        target[Mood.rest.rawValue] = max(0, 1 - total * keep)
    }

    func setProsody(_ p: Prosody) {
        rawEnergy = Float(min(1, max(0, p.energy)))
        rawPitch = p.pitch.map(Float.init)
    }

    func step(dt rawDt: Float, resolution: SIMD2<Float>) {
        let calm: Float = reducedMotion ? 0.35 : 1
        let dt = min(rawDt, 0.1)
        clock += dt

        // Voice: fast attack, slower release, plus a slow envelope for overall activity.
        let e = rawEnergy
        energy = ease(energy, e, e > energy ? 0.04 : 0.22, dt)
        energySlow = ease(energySlow, e, 1.4, dt)
        energyBase = ease(energyBase, energy, 0.35, dt)
        if let hz = rawPitch, hz > 50 {
            pitchBase = ease(pitchBase, hz, 4, dt)
            let semis = 12 * log2(hz / pitchBase)
            pitchDev = ease(pitchDev, max(-1, min(1, semis / 6)), 0.15, dt)
        } else {
            pitchDev = ease(pitchDev, 0, 0.6, dt)
        }

        // A sharp rise in loudness is a stressed syllable: send a ripple.
        let rise = energy - energyBase
        if rise > 0.11, energy > 0.18, clock - lastOnset > 0.2 {
            lastOnset = clock
            ripples.append([rand(-0.3...0.3) * aspect, rand(-0.3...0.05), 0, min(1, rise * 4)])
            if ripples.count > rippleCount { ripples.removeFirst() }
        }
        for i in ripples.indices { ripples[i].z += dt }
        ripples.removeAll { $0.z >= 3 }
        var rip = [SIMD4<Float>](repeating: .zero, count: rippleCount)
        for (i, r) in ripples.enumerated() { rip[i] = [r.x, r.y, r.z, r.w * calm] }

        // Mood weights flow toward the classifier's latest reading.
        for i in 0..<moodCount { w[i] = ease(w[i], target[i], 0.9, dt) }

        // Blend every motion parameter by the current weights.
        var F = FieldMotion(speed: 0, drift: .zero, turb: 0, jag: 0, detail: 0, scale: 0, tremble: 0, lightY: 0, lightAmt: 0, soft: 0, lift: 0, tilt: 0, amp: 0)
        let total = max(w.reduce(0, +), 1e-4)
        for i in 0..<moodCount {
            let k = w[i] / total
            let f = Mood.styles[i].field
            F.speed += k * f.speed
            F.drift += k * f.drift
            F.turb += k * f.turb
            F.jag += k * f.jag
            F.detail += k * f.detail
            F.scale += k * f.scale
            F.tremble += k * f.tremble
            F.lightY += k * f.lightY
            F.lightAmt += k * f.lightAmt
            F.soft += k * f.soft
            F.lift += k * f.lift
            F.tilt += k * f.tilt
            F.amp += k * f.amp
        }
        let en = energy
        flow += F.speed * (1 + 1.1 * en) * calm * dt
        drift += F.drift * (1 + 0.8 * en) * calm * dt

        // When the leading feeling changes, sweep its ink across the frame.
        var lead = 0
        for i in 1..<moodCount where w[i] > w[lead] { lead = i }
        if lead != dominant, w[lead] > w[dominant] + 0.06 {
            dominant = lead
            if clock - lastWash > washCooldown {
                lastWash = clock
                washStart = clock
                uniforms.washInk = Mood.styles[lead].ink(2)
                uniforms.washFrom = Mood.styles[lead].wash.vector
            }
        }
        let wp = (clock - washStart) / (washSeconds / calm)
        let wash: Float = wp >= 0 && wp < 1 ? 1 - pow(1 - wp, 2.2) : -1

        uniforms.a = [resolution.x, resolution.y, clock, flow]
        uniforms.b = [drift.x, drift.y, F.turb + 0.4 * en, F.jag]
        uniforms.c = [min(1, F.detail + 0.25 * en), F.scale, reducedMotion ? 0 : F.tremble * (0.5 + en), F.lightY + 0.12 * pitchDev]
        uniforms.d = [F.lightAmt, F.soft, F.lift + 0.12 * en + 0.04 * pitchDev, wash]
        uniforms.rip = (rip[0], rip[1], rip[2], rip[3], rip[4], rip[5])
        uniforms.w = ([w[0], w[1], w[2], w[3]], [w[4], w[5], w[6], w[7]], [w[8], 0, 0, 0])
        uniforms.e = [F.tilt, F.amp + 0.2 * en, 0, 0]

        stepFlecks(dt * calm)
    }

    var time: Float { clock }

    // MARK: - Flecks

    private func pickMood() -> Int {
        var r = Float.random(in: 0..<1) * max(w.reduce(0, +), 1e-4)
        for i in 0..<moodCount {
            r -= w[i]
            if r <= 0 { return i }
        }
        return 0
    }

    private func spawn(_ i: Int) {
        let m = pickMood()
        let style = Mood.styles[m]
        let f = style.flecks
        let halfW = aspect / 2
        var p = SIMD2<Float>.zero
        switch f.spawn {
        case .bottom: p = [rand(-halfW...halfW), -0.54]
        case .top: p = [rand(-halfW...halfW), 0.54]
        case .left: p = [-halfW - 0.04, rand(-0.42...0.42)]
        case .center:
            let a = rand(0...(2 * .pi))
            let r = rand(0...0.1)
            p = [cos(a) * r, sin(a) * r - 0.05]
        case .edges:
            switch Int.random(in: 0..<4) {
            case 0: p = [rand(-halfW...halfW), -0.5]
            case 1: p = [rand(-halfW...halfW), 0.5]
            case 2: p = [-halfW, rand(-0.5...0.5)]
            default: p = [halfW, rand(-0.5...0.5)]
            }
        case .anywhere: p = [rand(-halfW...halfW), rand(-0.5...0.5)]
        }
        pos[i] = p
        vel[i] = f.vel + f.radial * 1.6 * outward(p) + SIMD2(rand(-0.01...0.01), rand(-0.01...0.01))
        age[i] = 0
        mood[i] = m
        phase[i] = rand(0...(2 * .pi))
        spin[i] = rand(-3...3)
        // Quiet rooms are sparse: only some flecks wake, more as the voice gets louder.
        let awake = Float.random(in: 0..<1) < 0.3 + 0.7 * energySlow
        life[i] = awake ? rand(f.life) : rand(0.4...1.2)
        baseAlpha[i] = awake ? f.alpha : 0
        let ink = style.ink(f.ink) * rand(0.92...1.06)
        flecks[i].c = [min(1, ink.x), min(1, ink.y), min(1, ink.z), f.shape.rawValue]
        flecks[i].p.z = rand(f.size)
    }

    private func stepFlecks(_ dt: Float) {
        let pace = 0.55 + 1.3 * energy
        let halfW = aspect / 2
        for i in 0..<fleckCount {
            age[i] += dt
            let out = abs(pos[i].x) > halfW + 0.1 || abs(pos[i].y) > 0.62
            if age[i] >= life[i] || out { spawn(i) }
            let f = Mood.styles[mood[i]].flecks
            let o = outward(pos[i])
            let goal = f.vel + f.radial * 0.6 * o
            let k = 1 - exp(-f.drag * dt)
            let a = age[i]
            var v = vel[i] + (goal - vel[i]) * k
            v.x += f.jitter * Float.random(in: -0.5...0.5) * dt * 4 + f.sway * sin(a * 1.3 + phase[i]) * dt
            v.y += f.jitter * Float.random(in: -0.5...0.5) * dt * 4 + f.bounce * cos(a * 7 + phase[i]) * dt * 7
            vel[i] = v
            pos[i] += v * dt * pace
            // Fear's flecks vanish as they reach the middle.
            if f.radial < 0, simd_length(pos[i]) < 0.06 { age[i] = life[i] }

            let t = a / life[i]
            let fade = smooth(0, 0.15, t) * (1 - smooth(0.7, 1, t))
            let size = flecks[i].p.z
            flecks[i].p = [pos[i].x, pos[i].y, size, baseAlpha[i] * fade]
            flecks[i].r.x = f.shape == .dash ? atan2(v.y, v.x) : spin[i] * a
        }
    }
}
