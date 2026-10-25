import Foundation

/// What the phone measured at release, and how far it flew. The server stores it as is.
struct DiscusThrow: Equatable, Sendable {
    /// Peak rotation rate in the last 0.3 s before release, rad/s.
    var speed: Double
    /// Release angle, degrees above horizontal.
    var angle: Double
    /// Rotation rate at release over the peak just before it, 0...1. 1 is a release at full speed.
    var timing: Double
    /// Metres, one decimal. 0 for a foul.
    var distance: Double
    /// Released so late the discus went sideways, into the crowd.
    var foul: Bool
    /// The release in detail (DiscusRelease), for the arena's technique call: m/s off the hand,
    /// the disc's tilt off flat (degrees), its spin (rad/s), and the heading off the wind-up
    /// facing (degrees; recorded, not yet a foul). Zero when there was no release reading.
    var releaseSpeed: Double = 0
    var roll: Double = 0
    var spin: Double = 0
    var yawFromFacing: Double = 0
    /// '' or 'late' (into the crowd). 'sector' is reserved until the heading is checked on a phone.
    var foulReason: String = ""
}

/// The throw's distance from the swing. Deterministic: the same swing always flies the same
/// distance. A release from 1.8 m flies as a projectile; the discus's lift moves the best angle
/// down to 37.5°. Every constant is in `Tuning`, set from a real iPhone with the telemetry strip.
///
/// With the defaults: casual 14 m, decent 24 m, good 33 m (past Phayllos), strong 42 m,
/// great 56 m, and 71 m at most (the world record is 74). They're set for a first-time
/// thrower, untuned on a real swing yet: a late thumb still flies (a first-timer lifting as the
/// swing slows lands 13–24 m), and only a clearly late release goes into the crowd.
enum DiscusPhysics {
    struct Tuning: Equatable, Sendable {
        /// Rotation rate that gives no power, and the one that gives full power, rad/s.
        var restSpeed = 4.0
        var fullSpeed = 20.0
        /// Release velocity at no power and at full power, m/s.
        var minRelease = 10.0
        var maxRelease = 26.0
        /// The release angle that flies farthest.
        var bestAngle = 37.5
        var releaseHeight = 1.8
        /// Timing below this is a foul: released long after the peak, the discus goes sideways.
        var foulTiming = 0.35
        /// The field is 80 m; nothing lands past it.
        var longest = 79.9
        /// Above the best angle the flight falls off gently: each degree steeper counts this much.
        var steepGain = 0.6
        /// A disc tilted this far (degrees) off its flight path starts to lose lift, up to
        /// `wobbleLoss` of the distance at 60° off.
        var attackFree = 15.0
        var wobbleLoss = 0.3
        /// Spin steadies the flight: no spin costs `spinLoss`, `fullSpin` rad/s costs nothing.
        var fullSpin = 10.0
        var spinLoss = 0.08

        static let standard = Tuning()
    }

    /// The Phayllos line: the ancient legend's throw, marked on the field.
    static let phayllos = 29.0

    /// How hard the swing is, 0...1: the arena's power gauge and the phone's haptics.
    static func power(speed: Double, tuning: Tuning = .standard) -> Double {
        guard speed.isFinite else { return 0 }
        return min(1, max(0, (speed - tuning.restSpeed) / (tuning.fullSpeed - tuning.restSpeed)))
    }

    /// Metres a second off the hand: the arena shows it ("38° · 24 m/s").
    static func releaseSpeed(speed: Double, tuning: Tuning = .standard) -> Double {
        tuning.minRelease + (tuning.maxRelease - tuning.minRelease) * power(speed: speed, tuning: tuning)
    }

    /// `roll` and `spin` come from DiscusRelease when the phone has a release reading; without
    /// them the flight is exactly the original model.
    static func distance(speed: Double, angle: Double, timing: Double, roll: Double? = nil, spin: Double? = nil,
                         tuning: Tuning = .standard) -> (metres: Double, foul: Bool) {
        guard speed.isFinite, angle.isFinite, timing.isFinite else { return (0, true) }
        if timing < tuning.foulTiming { return (0, true) }
        let g = 9.81
        let v = releaseSpeed(speed: speed, tuning: tuning)
        // Scale the angle so bestAngle flies like 45° does in a vacuum; steeper than that falls
        // off gently, so a 60° release costs about a tenth, not four.
        let a = max(0, angle)
        let degrees = a <= tuning.bestAngle ? a * 45 / tuning.bestAngle : 45 + (a - tuning.bestAngle) * tuning.steepGain
        let effective = min(89, degrees) * .pi / 180
        let up = v * sin(effective)
        let range = v * cos(effective) / g * (up + (up * up + 2 * g * tuning.releaseHeight).squareRoot())
        // A release past the peak loses up to 40%.
        let late = 0.6 + 0.4 * (min(1, timing) - tuning.foulTiming) / (1 - tuning.foulTiming)
        // A disc flying edge-first holds its line; tilted well off its path, it wobbles and drops.
        var wobble = 1.0
        if let roll, roll.isFinite {
            let off = abs(roll - angle)
            wobble = 1 - tuning.wobbleLoss * min(1, max(0, (off - tuning.attackFree) / (60 - tuning.attackFree)))
        }
        var steady = 1.0
        if let spin, spin.isFinite { steady = 1 - tuning.spinLoss * (1 - min(1, max(0, spin) / tuning.fullSpin)) }
        let metres = min(tuning.longest, max(0, range * late * wobble * steady))
        return ((metres * 10).rounded() / 10, false)
    }
}
