import CoreMotion
import Foundation
import simd

/// Toxeia (archery): one archer, two phones.
///
/// The BOW phone is held out at arm's length and pointed at the target, like the boxing fist: its
/// aim is where the back of the phone points, against the pose held at "Ready" (gimbal-free, see
/// MotionFrame). A steady hand matters, so the aim is only lightly smoothed.
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

    static let yawRange = Double.pi / 6  // ±30°: aiming is finer than punching
    static let pitchRange = Double.pi / 6
    static let smoothing = 0.35  // one-pole per sample at 100 Hz: steady, not sluggish

    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private let lock = NSLock()
    private var reference: SIMD3<Double>?
    private var aim = Aim()

    var available: Bool { manager.isDeviceMotionAvailable }
    var current: Aim { lock.withLock { aim } }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 0.01
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.lock.withLock { self.step(motion) }
        }
    }

    /// "Ready": wherever the bow points now is the centre of the target.
    func zero() { lock.withLock { reference = nil; aim = Aim() } }

    func stop() { manager.stopDeviceMotionUpdates() }

    private func step(_ m: CMDeviceMotion) {
        let pointing = MotionFrame.deviceToWorld(m) * SIMD3(0, 0, -1)
        if reference == nil { reference = pointing }
        guard let reference else { return }
        let now = MotionFrame.headingElevation(pointing), zero = MotionFrame.headingElevation(reference)
        let yaw = clamp(-MotionFrame.wrap(now.heading - zero.heading) / Self.yawRange)
        let pitch = clamp((now.elevation - zero.elevation) / Self.pitchRange)
        aim.yaw += (yaw - aim.yaw) * Self.smoothing
        aim.pitch += (pitch - aim.pitch) * Self.smoothing
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
