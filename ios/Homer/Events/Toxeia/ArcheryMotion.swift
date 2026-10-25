import CoreMotion
import Foundation
import simd

/// Toxeia (archery): one archer, two phones.
///
/// The BOW phone is held out and pointed at the target. Its aim is how far the phone as a whole
/// has turned since the zero, whatever the grip (Matus: "the center of the iPhone is all that
/// matters"): the world-frame rotation since the zero, as a rotation vector, read about gravity
/// (left/right) and about the horizontal axis across the archer's facing (up/down). Portrait,
/// landscape, upright or flat all aim the same, and nothing breaks with the back pointing down.
/// Each arrow zeroes itself once the bow is held still (see `zeroWhenSteady`).
///
/// The ARROW phone is the string: the thumb holds the pad to nock, the hand pulls back toward the
/// face, and the thumb lifts to loose. The draw (0...1) comes mostly from how far it was pulled
/// back (user acceleration integrated twice, with a leak against drift) and a little from how long
/// it was held, clamped.
final class BowMotion: @unchecked Sendable {
    struct Aim: Equatable, Sendable {
        var yaw = 0.0  // -1 (left) ... 1 (right)
        var pitch = 0.0  // -1 (low) ... 1 (high)
    }

    /// ±33° of turn = ±1, which the module maps to ±1 m on the face (radius 0.61 m): the rim is
    /// about ±20° and the gold (6.1 cm) about ±2°, so tremor and the other hand's pull stay on it.
    static let yawRange = 33 * Double.pi / 180
    static let pitchRange = 33 * Double.pi / 180
    static let smoothing = 0.07  // one-pole per sample at 100 Hz: ~140 ms, tremor settles
    /// The per-arrow zero waits for the bow held this still (rotation rate, rad/s) this long (s).
    static let stillRate = 0.35
    static let stillFor = 0.4

    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private let lock = NSLock()
    private var reference: simd_double3x3?  // device → world at the zero
    private var right = SIMD3<Double>(1, 0, 0)  // world, horizontal, across the facing at the zero
    private var aim = Aim()
    private var waitingForStill = false
    private var stillSince: TimeInterval?

    var available: Bool { manager.isDeviceMotionAvailable }
    var current: Aim { lock.withLock { aim } }
    /// False while a per-arrow zero is still waiting for the bow to be held still.
    var zeroed: Bool { lock.withLock { !waitingForStill } }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 0.01
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.lock.withLock { self.step(motion) }
        }
    }

    /// Zero now: wherever the bow points at the next sample is the centre of the target.
    func zero() { lock.withLock { reference = nil; waitingForStill = false; aim = Aim() } }

    /// Zero once the bow is held still (each arrow, so a re-grip or the gyro's drift never carries
    /// over). The aim stays centred until then.
    func zeroWhenSteady() { lock.withLock { waitingForStill = true; stillSince = nil; aim = Aim() } }

    func stop() { manager.stopDeviceMotionUpdates() }

    private func step(_ m: CMDeviceMotion) {
        let now = MotionFrame.deviceToWorld(m)
        if waitingForStill {
            let rate = simd_length(SIMD3(m.rotationRate.x, m.rotationRate.y, m.rotationRate.z))
            if rate > Self.stillRate { stillSince = nil; return }
            let since = stillSince ?? m.timestamp
            stillSince = since
            guard m.timestamp - since >= Self.stillFor else { return }
            waitingForStill = false
            reference = nil
        }
        if reference == nil { setReference(now) }
        guard let reference else { return }
        let w = Self.rotationVector(now * reference.transpose)
        let yaw = clamp(-w.z / Self.yawRange)  // turning right is clockwise seen from above
        let pitch = clamp(simd_dot(w, right) / Self.pitchRange)
        aim.yaw += (yaw - aim.yaw) * Self.smoothing
        aim.pitch += (pitch - aim.pitch) * Self.smoothing
    }

    /// The facing only says which horizontal axis is "across": the flatter of the back (−Z) and
    /// the top edge (+Y), so a bow held upright or flat both tip up about the right axis.
    private func setReference(_ r: simd_double3x3) {
        reference = r
        let flat = { (v: SIMD3<Double>) in SIMD3(v.x, v.y, 0) }
        let back = flat(r * SIMD3(0, 0, -1)), top = flat(r * SIMD3(0, 1, 0))
        let facing = simd_length(back) >= simd_length(top) ? back : top
        let f = simd_length(facing) > 1e-6 ? simd_normalize(facing) : SIMD3(0, 1, 0)
        right = simd_cross(f, SIMD3(0, 0, 1))
        aim = Aim()
    }

    /// Axis × angle (radians) of a rotation matrix, the short way round.
    static func rotationVector(_ m: simd_double3x3) -> SIMD3<Double> {
        var q = simd_quatd(m)
        if q.real < 0 { q = simd_quatd(real: -q.real, imag: -q.imag) }
        let s = simd_length(q.imag)
        guard s > 1e-9 else { return .zero }
        return q.imag / s * (2 * atan2(s, q.real))
    }

    private func clamp(_ v: Double) -> Double { min(1, max(-1, v)) }
}

final class ArrowMotion: @unchecked Sendable {
    static let fullPull = 0.45  // m back toward the face for a full draw
    static let fullHold = 1.2  // s held for the hold half of the draw

    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private let lock = NSLock()
    private var nockedAt: TimeInterval?
    private var velocity = 0.0  // m/s along the pull
    private var pulled = 0.0  // m
    private var lastT: TimeInterval?
    private var pullAxis: SIMD3<Double>?  // world frame, set by the first strong movement after nocking

    var available: Bool { manager.isDeviceMotionAvailable }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 0.01
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.lock.withLock { self.step(motion) }
        }
    }

    func stop() { manager.stopDeviceMotionUpdates() }

    /// Thumb down: the arrow is on the string; the pull starts from here.
    func nock() {
        lock.withLock {
            nockedAt = Date().timeIntervalSinceReferenceDate
            velocity = 0
            pulled = 0
            pullAxis = nil
        }
    }

    /// The draw so far, 0...1 (also what `loose()` returns).
    var draw: Double {
        lock.withLock {
            guard let nockedAt else { return 0 }
            let held = Date().timeIntervalSinceReferenceDate - nockedAt
            return min(1, 0.75 * min(1, pulled / Self.fullPull) + 0.25 * min(1, held / Self.fullHold))
        }
    }

    /// Thumb up: the shot's draw; the string is empty again.
    func loose() -> Double {
        let d = draw
        lock.withLock { nockedAt = nil }
        return d
    }

    private func step(_ m: CMDeviceMotion) {
        let dt = lastT.map { min(0.05, max(0, m.timestamp - $0)) } ?? 0.01
        lastT = m.timestamp
        guard nockedAt != nil else { return }
        let a = MotionFrame.deviceToWorld(m) * SIMD3(m.userAcceleration.x, m.userAcceleration.y, m.userAcceleration.z) * 9.81
        // The pull's direction is whatever way the first real movement goes; only motion along it
        // counts, so a wobble sideways doesn't add draw.
        if pullAxis == nil, simd_length(a) > 1.5 { pullAxis = simd_normalize(a) }
        guard let axis = pullAxis else { return }
        let along = simd_dot(a, axis)
        velocity = (velocity + along * dt) * 0.97  // a leak, so drift can't run away
        if velocity > 0 { pulled = min(Self.fullPull * 1.5, pulled + velocity * dt) }
    }
}
