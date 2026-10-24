import Foundation

/// One Core Motion reading, in the device's frame. `t` is seconds of system uptime, the clock
/// that `UITouch.timestamp` uses too, so a release can be placed between two samples.
struct SwingSample: Equatable, Sendable {
    var t: TimeInterval
    /// Rotation rate, rad/s (gyro, bias removed).
    var rotation: SIMD3<Double>
    /// Gravity, in g.
    var gravity: SIMD3<Double>

    var spin: Double { (rotation * rotation).sum().squareRoot() }
}

/// What a hold measured. Pure: the phone feeds it samples, the tests feed it numbers.
struct SwingReading: Equatable, Sendable {
    var held: TimeInterval
    /// Total rotation over the hold, radians.
    var turned: Double
    var speed: Double
    var timing: Double
    /// How far the swing plane tilts from horizontal, degrees: 0 for a flat sidearm swing,
    /// 90 for an underarm or overarm one.
    var tilt: Double
    var angle: Double

    /// Under half a second, or under half a turn: a drop, not a throw (UX D2).
    var isDrop: Bool { held < DiscusSwing.minHold || turned < DiscusSwing.minTurn }
}

enum DiscusSwing {
    static let minHold: TimeInterval = 0.5
    static let minTurn = Double.pi
    /// Speed is the peak over this window before release.
    static let speedWindow: TimeInterval = 0.3
    /// Timing compares the release with the peak over this window.
    static let timingWindow: TimeInterval = 0.6
    /// A real discus leaves the hand rising out of a mostly flat swing. The release angle is
    /// this base plus a share of the swing plane's tilt, so a flat sidearm swing that lifts a
    /// little flies best, and a vertical swing (not a discus throw) flies short.
    static let baseAngle = 25.0
    static let tiltGain = 0.6

    static func read(_ samples: [SwingSample], heldFrom start: TimeInterval, releasedAt release: TimeInterval) -> SwingReading {
        let hold = samples.filter { $0.t >= start && $0.t <= release }
        var turned = 0.0
        for (a, b) in zip(hold, hold.dropFirst()) {
            turned += (a.spin + b.spin) / 2 * (b.t - a.t)
        }
        let recent = hold.filter { $0.t >= release - speedWindow }
        let around = hold.filter { $0.t >= release - timingWindow }
        let speed = recent.map(\.spin).max() ?? 0
        let peak = around.map(\.spin).max() ?? 0
        let atRelease = hold.last?.spin ?? 0
        let timing = peak > 0 ? min(1, atRelease / peak) : 0
        let tilt = swingTilt(recent)
        return SwingReading(held: release - start, turned: turned, speed: speed, timing: timing,
                            tilt: tilt, angle: min(90, baseAngle + tiltGain * tilt))
    }

    /// The angle between the rotation axis and vertical, weighted by spin so the fast part of
    /// the swing decides it. Independent of how the phone sits in the hand.
    static func swingTilt(_ samples: [SwingSample]) -> Double {
        var sum = 0.0
        var weight = 0.0
        for s in samples {
            let g = (s.gravity * s.gravity).sum().squareRoot()
            let w = s.spin
            guard g > 0.1, w > 0.5 else { continue }
            let cosine = min(1, abs((s.rotation * s.gravity).sum()) / (w * g))
            sum += acos(cosine) * 180 / .pi * w
            weight += w
        }
        return weight > 0 ? sum / weight : 0
    }

    static func measure(_ reading: SwingReading, tuning: DiscusPhysics.Tuning = .standard) -> DiscusThrow {
        let flight = DiscusPhysics.distance(speed: reading.speed, angle: reading.angle, timing: reading.timing, tuning: tuning)
        return DiscusThrow(speed: reading.speed, angle: reading.angle, timing: reading.timing,
                           distance: flight.metres, foul: flight.foul)
    }
}
