import CoreMotion
import Foundation
import simd

/// What the release did, from the device-motion samples around the thumb lift. Pure and
/// frame-independent: directions come from gravity and the swing itself, never a fixed hold.
/// DiscusSwing calls it at the lift; DiscusPhysics turns it into a distance (multiplayer's files).
///
/// - speed: the swing's angular speed, rad/s: the peak of a 3-sample median of |ω| over the last
///   0.5 s, so one jittery sample can't spike or sink a throw.
/// - angle: the launch angle, degrees above horizontal. The disc flies along the hand's velocity,
///   v ∝ ω × r, with r pointing from the swing's centre to the phone (opposite the centripetal
///   acceleration). Best is about 33–38° (35° in still air).
/// - roll: the disc's inclination, degrees: the angle between the phone's face (the disc plane)
///   and the horizontal. The angle of attack is roll − angle; a disc tilted well above its flight
///   path stalls, one well below it plows.
/// - spin: rad/s about the disc's own axis (the phone's normal) at release; it steadies the flight.
/// - yawFromFacing: degrees between the release heading and the facing at wind-up (the heading of
///   the phone's long axis at the thumb-down); outside ±17.46° (the 34.92° sector) is a foul.
enum DiscusRelease {
    struct Sample: Sendable {
        var t: TimeInterval
        var rotationRate: SIMD3<Double>  // rad/s, device frame
        var userAcceleration: SIMD3<Double>  // g, device frame
        var gravity: SIMD3<Double>  // unit-ish, device frame, pointing down
        /// Device → reference (world, z vertical) for directions: the transpose of CMAttitude's matrix.
        var toWorld: simd_double3x3

        init(t: TimeInterval, rotationRate: SIMD3<Double>, userAcceleration: SIMD3<Double>,
             gravity: SIMD3<Double>, toWorld: simd_double3x3) {
            self.t = t
            self.rotationRate = rotationRate
            self.userAcceleration = userAcceleration
            self.gravity = gravity
            self.toWorld = toWorld
        }

        init(_ m: CMDeviceMotion) {
            // The orientation is checked against the sample's own gravity (MotionFrame), so the matrix
            // convention can't be backwards.
            let deviceToWorld = MotionFrame.deviceToWorld(m)
            self.init(t: m.timestamp,
                      rotationRate: SIMD3(m.rotationRate.x, m.rotationRate.y, m.rotationRate.z),
                      userAcceleration: SIMD3(m.userAcceleration.x, m.userAcceleration.y, m.userAcceleration.z),
                      gravity: SIMD3(m.gravity.x, m.gravity.y, m.gravity.z),
                      toWorld: deviceToWorld)
        }
    }

    enum Foul: String, Sendable { case sector, noSwing = "no_swing" }

    struct Result: Equatable, Sendable {
        var speed: Double  // rad/s
        var angle: Double  // degrees
        var roll: Double  // degrees
        var spin: Double  // rad/s
        var yawFromFacing: Double  // degrees
        var foul: Foul?
    }

    static let sectorHalfAngle = 34.92 / 2
    static let minSwing = 4.0  // rad/s: slower isn't a throw

    /// `samples`: the swing up to the release, oldest first (the last one is at the lift).
    /// `facing`: the sample at the thumb-down (wind-up).
    static func analyze(_ samples: [Sample], facing: Sample) -> Result? {
        guard let last = samples.last else { return nil }
        let window = samples.filter { last.t - $0.t <= 0.5 }
        let mags = window.map { simd_length($0.rotationRate) }
        let smoothed = mags.indices.map { i -> Double in
            let lo = max(0, i - 1), hi = min(mags.count - 1, i + 1)
            return Array(mags[lo...hi]).sorted()[(hi - lo) / 2]  // 3-sample median (2 at the ends)
        }
        let speed = smoothed.max() ?? 0

        // Release geometry at the last sample.
        let up = -simd_normalize(last.gravity)
        let omega = last.rotationRate
        let accel = last.userAcceleration
        var velocity = SIMD3<Double>(repeating: 0)
        if simd_length(accel) > 0.05, simd_length(omega) > 0.5 {
            let r = -simd_normalize(accel)  // from the swing's centre out to the phone
            velocity = simd_cross(omega, r)
        }
        let vHat = simd_length(velocity) > 1e-6 ? simd_normalize(velocity) : SIMD3(0, 1, 0)
        let angle = asin(max(-1, min(1, simd_dot(vHat, up)))) * 180 / .pi
        let normal = SIMD3<Double>(0, 0, 1)  // the phone's face is the disc
        let roll = acos(max(-1, min(1, abs(simd_dot(normal, up))))) * 180 / .pi
        let spin = abs(simd_dot(omega, normal))

        // Heading of the release against the facing at wind-up, in the world's horizontal plane.
        let releaseWorld = last.toWorld * vHat
        let facingWorld = facing.toWorld * SIMD3(0, 1, 0)  // the phone's long axis at the thumb-down
        let yaw = headingDegrees(releaseWorld) - headingDegrees(facingWorld)
        let yawFromFacing = wrap(yaw)

        var foul: Foul?
        if speed < minSwing { foul = .noSwing }
        else if abs(yawFromFacing) > sectorHalfAngle { foul = .sector }
        return Result(speed: speed, angle: angle, roll: roll, spin: spin, yawFromFacing: yawFromFacing, foul: foul)
    }

    private static func headingDegrees(_ v: SIMD3<Double>) -> Double { atan2(v.y, v.x) * 180 / .pi }

    private static func wrap(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }
}
