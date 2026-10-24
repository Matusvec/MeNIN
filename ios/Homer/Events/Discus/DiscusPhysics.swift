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
}

/// The throw's distance from the swing. Deterministic: the same swing always flies the same
/// distance. A release from 1.8 m flies as a projectile; the discus's lift moves the best angle
/// down to 37.5°. Every constant is in `Tuning`, set from a real iPhone with the telemetry strip.
///
/// With the defaults: casual 14 m, decent 23 m, good 32 m (past Phayllos), strong 41 m,
/// great 56 m, and 71 m at most (the world record is 74).
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
        /// Timing below this is a foul.
        var foulTiming = 0.55
        /// The field is 80 m; nothing lands past it.
        var longest = 79.9

        static let standard = Tuning()
    }

    /// The Phayllos line: the ancient legend's throw, marked on the field.
    static let phayllos = 29.0

    /// How hard the swing is, 0...1: the arena's power gauge and the phone's haptics.
    static func power(speed: Double, tuning: Tuning = .standard) -> Double {
        guard speed.isFinite else { return 0 }
        return min(1, max(0, (speed - tuning.restSpeed) / (tuning.fullSpeed - tuning.restSpeed)))
    }

    static func distance(speed: Double, angle: Double, timing: Double, tuning: Tuning = .standard) -> (metres: Double, foul: Bool) {
        guard speed.isFinite, angle.isFinite, timing.isFinite else { return (0, true) }
        if timing < tuning.foulTiming { return (0, true) }
        let g = 9.81
        let v = tuning.minRelease + (tuning.maxRelease - tuning.minRelease) * power(speed: speed, tuning: tuning)
        // Scale the angle so bestAngle flies like 45° does in a vacuum.
        let effective = min(90, max(0, angle) * 45 / tuning.bestAngle) * .pi / 180
        let up = v * sin(effective)
        let range = v * cos(effective) / g * (up + (up * up + 2 * g * tuning.releaseHeight).squareRoot())
        // A release past the peak loses up to 40%.
        let late = 0.6 + 0.4 * (min(1, timing) - tuning.foulTiming) / (1 - tuning.foulTiming)
        let metres = min(tuning.longest, max(0, range * late))
        return ((metres * 10).rounded() / 10, false)
    }
}
