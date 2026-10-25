import CoreMotion
import Foundation

/// The Stadion's legs: the poet holds the phone and pumps their arms like a sprinter. Each arm
/// swing is a stride. Cadence (strides a second) and force (how hard each swing is) set a target
/// speed; the runner accelerates toward it with some inertia, so a burst carries and a stop
/// slows you down instead of freezing you. Distance integrates speed. One stadion is 192 m.
///
/// A swing is a peak of the phone's rotation rate (the forearm arcs about the elbow) that also
/// moves the phone (user acceleration). Shaking the phone in place makes fast, small, mostly
/// translational peaks; that's flagged and slows the runner, loosely.
final class StadionMotion: @unchecked Sendable {
    static let stadionMeters = 192.0
    /// Full pump (about 4 swings a second, hard) runs the stadion in about 14 s; a lazy runner
    /// hits the 40 s cap (multiplayer's pacing; the server clamps at 20 m/s).
    static let topSpeed = 14.0  // m/s, game speed
    static let rate = 100.0  // Hz

    struct Reading: Equatable, Sendable {
        var speed = 0.0  // m/s
        var distance = 0.0  // m
        var cadence = 0.0  // swings a second
        var force = 0.0  // 0...1
        var shaking = false
    }

    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private let lock = NSLock()
    private var reading = Reading()
    private var running = false
    private var lastSampleAt: TimeInterval?

    // Swing detection on |rotationRate| (rad/s): a peak above `swingFloor`, at least
    // `minSwingGap` after the last one.
    private static let swingFloor = 2.5
    private static let minSwingGap = 0.18  // s: faster than ~5.5 Hz isn't an arm
    private var rising = false
    private var peak = 0.0
    private var peakAccel = 0.0
    private var lastSwingAt: TimeInterval = 0
    private var swingTimes: [TimeInterval] = []
    private var swingForces: [Double] = []
    private var shakeScore = 0.0

    var available: Bool { manager.isDeviceMotionAvailable }

    /// The latest reading; safe from any thread.
    var current: Reading { lock.withLock { reading } }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        lock.withLock {
            reading = Reading()
            running = false
            lastSampleAt = nil
            swingTimes.removeAll()
            swingForces.removeAll()
            shakeScore = 0
        }
        manager.deviceMotionUpdateInterval = 1 / Self.rate
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.lock.withLock { self.step(motion) }
        }
    }

    /// GO: from here, swings move the runner (swings in the count-in only warm up the cadence).
    func go() { lock.withLock { running = true } }

    func stop() {
        manager.stopDeviceMotionUpdates()
        lock.withLock { running = false }
    }

    // MARK: per sample (on the motion queue, under the lock)

    private func step(_ motion: CMDeviceMotion) {
        let t = motion.timestamp
        let dt = lastSampleAt.map { min(0.05, max(0, t - $0)) } ?? 1 / Self.rate
        lastSampleAt = t
        let r = motion.rotationRate
        let a = motion.userAcceleration
        let spin = (r.x * r.x + r.y * r.y + r.z * r.z).squareRoot()
        let accel = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()  // g

        // A swing peaks when the spin stops rising.
        if spin > Self.swingFloor {
            if spin >= peak { peak = spin; peakAccel = max(peakAccel, accel); rising = true }
            else if rising, t - lastSwingAt >= Self.minSwingGap {
                swing(at: t, spin: peak, accel: peakAccel)
                rising = false
            }
        } else {
            if rising, t - lastSwingAt >= Self.minSwingGap { swing(at: t, spin: peak, accel: peakAccel) }
            rising = false
            peak = 0
            peakAccel = 0
        }
        // Shaking: strong translation with little rotation, sustained.
        let shakeNow = accel > 1.2 && spin < 1.5
        shakeScore = max(0, min(1, shakeScore + (shakeNow ? dt * 2.5 : -dt * 1.2)))

        // Cadence and force over the last 1.2 s of swings.
        swingTimes.removeAll { t - $0 > 1.2 }
        if swingForces.count > swingTimes.count { swingForces.removeFirst(swingForces.count - swingTimes.count) }
        let cadence = Double(swingTimes.count) / 1.2
        let force = swingForces.isEmpty ? 0 : swingForces.reduce(0, +) / Double(swingForces.count)

        // Target speed: cadence to ~4 swings/s and force both matter; shaking caps it low.
        var target = Self.topSpeed * min(1, cadence / 4.0) * (0.45 + 0.55 * force)
        let shaking = shakeScore > 0.5
        if shaking { target = min(target, 3) }  // shaking in place: a jog at most
        if !running { target = 0 }
        // Inertia: speed up in ~0.6 s, slow down in ~1 s.
        let tau = target > reading.speed ? 0.6 : 1.0
        reading.speed += (target - reading.speed) * min(1, dt / tau)
        if running { reading.distance = min(Self.stadionMeters, reading.distance + reading.speed * dt) }
        reading.cadence = cadence
        reading.force = force
        reading.shaking = shaking
    }

    private func swing(at t: TimeInterval, spin: Double, accel: Double) {
        lastSwingAt = t
        swingTimes.append(t)
        // Force: a hard swing is ~12 rad/s with ~1.5 g of movement; either half counts.
        let f = 0.6 * min(1, spin / 12) + 0.4 * min(1, accel / 1.5)
        swingForces.append(f)
    }
}
