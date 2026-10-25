import CoreMotion
import Foundation
import simd

/// Boxing on the phone, held like a fist (after Wii Sports Boxing). Three things come out:
/// - aim: where the fist points, relative to the guard pose captured at the bell (an air mouse),
///   yaw left/right and pitch up/down, -1...1, streamed ~20 Hz so the fist on screen follows;
/// - punches: a user-acceleration spike of about 2.5 g or more. The rotation around it gives the
///   flavour (a yaw-dominant arc is a hook, a pitch-up arc an uppercut, else a jab), and the aim at
///   impact gives the target (low = body, high = head, side = left/right). Any strong punch counts;
///   the type is flavour (single-wrist IMU studies: ~98% detection, ~91% type, person-independent);
/// - guard: the phone upright, near centre, still for 150 ms.
final class BoxingMotion: @unchecked Sendable {
    enum PunchKind: String, Sendable { case jab, hook, uppercut }

    struct Punch: Equatable, Sendable {
        var kind: PunchKind
        var power: Double  // 0...1
        var yaw: Double  // aim at impact, -1 (left)...1 (right)
        var pitch: Double  // aim at impact, -1 (low, body)...1 (high, head)
        var atMs: Double  // epoch ms
    }

    struct Aim: Equatable, Sendable {
        var yaw = 0.0
        var pitch = 0.0
        var guarding = false
    }

    static let rate = 100.0
    static let punchG = 2.5  // spike threshold, in g
    static let refractory = 0.25  // s between punches
    /// Aim gain: the module counts |yaw| > 0.5 as a miss, so ±1 spans ±60° (a miss beyond ±30°) and
    /// pitch ±1 spans ±45°. Gentler than before: a natural punch stays inside the target.
    static let yawRange = Double.pi / 3
    static let pitchRange = Double.pi / 4

    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private let lock = NSLock()
    /// Where the fist pointed at the bell (world frame): the back of the phone (−z), which faces the
    /// rival when the phone is held upright like a fist with the screen toward you.
    private var reference: SIMD3<Double>?
    private var aim = Aim()
    private var lastPunchAt: TimeInterval = 0
    private var lastSampleAt: TimeInterval?
    private var stillSince: TimeInterval?
    /// Recent rotation (in the guard frame) to classify a punch: the last ~150 ms of samples.
    private var recent: [(t: TimeInterval, yawRate: Double, pitchRate: Double, g: Double)] = []
    private var pending: (t: TimeInterval, peakG: Double)?
    private var punches: [Punch] = []

    var available: Bool { manager.isDeviceMotionAvailable }
    var currentAim: Aim { lock.withLock { aim } }

    /// Punches since the last call (oldest first).
    func takePunches() -> [Punch] { lock.withLock { defer { punches.removeAll() }; return punches } }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1 / Self.rate
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.lock.withLock { self.step(motion) }
        }
    }

    /// The bell: whatever pose the fighter holds now is centre (their guard).
    func calibrate() { lock.withLock { reference = nil } }

    func stop() { manager.stopDeviceMotionUpdates() }

    // MARK: per sample (motion queue, under the lock)

    private func step(_ m: CMDeviceMotion) {
        let t = m.timestamp
        // Aim from the pointing direction, not Euler angles: Euler yaw and pitch swing wildly (gimbal
        // lock) with the phone upright, which pinned one phone's aim at −1 and missed 5 of 6 punches.
        let pointing = MotionFrame.deviceToWorld(m) * SIMD3(0, 0, -1)
        if reference == nil { reference = pointing }
        guard let reference else { return }
        let now = MotionFrame.headingElevation(pointing)
        // Re-centre slowly (time constant ~15 s) so gyro drift and a fighter who turns their stance
        // can't pin the aim at one side for the rest of the fight (YLAR rematch: both phones at −0.9).
        let dt = lastSampleAt.map { min(0.05, max(0, t - $0)) } ?? 0.01
        lastSampleAt = t
        var bell = MotionFrame.headingElevation(reference)
        let drift = MotionFrame.wrap(now.heading - bell.heading)
        bell.heading += drift * dt / 15
        bell.elevation += (now.elevation - bell.elevation) * dt / 15
        self.reference = SIMD3(cos(bell.elevation) * cos(bell.heading), cos(bell.elevation) * sin(bell.heading), sin(bell.elevation))
        let yaw = clamp(-MotionFrame.wrap(now.heading - bell.heading) / Self.yawRange)  // turned right = positive
        let pitch = clamp((now.elevation - bell.elevation) / Self.pitchRange)  // up = positive (head)

        let r = m.rotationRate
        let a = m.userAcceleration
        let g = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
        let spin = (r.x * r.x + r.y * r.y + r.z * r.z).squareRoot()
        // In portrait, a yaw arc spins about the device's y axis (up), a pitch arc about its x axis.
        recent.append((t, r.y, r.x, g))
        recent.removeAll { t - $0.t > 0.15 }

        // Guard: upright (gravity down the phone's long axis), near centre, still for 150 ms.
        let upright = m.gravity.y < -0.75
        if upright, spin < 1.0, g < 0.3, abs(yaw) < 0.35, abs(pitch) < 0.35 {
            if stillSince == nil { stillSince = t }
        } else {
            stillSince = nil
        }
        let guarding = stillSince.map { t - $0 >= 0.15 } ?? false
        aim = Aim(yaw: yaw, pitch: pitch, guarding: guarding)

        // A punch: the spike's peak, then classified once it falls back.
        if g >= Self.punchG, t - lastPunchAt >= Self.refractory {
            if let p = pending { pending = (p.t, max(p.peakG, g)) } else { pending = (t, g) }
        } else if let p = pending, g < Self.punchG * 0.6 {
            pending = nil
            lastPunchAt = t
            let yawArc = recent.map { abs($0.yawRate) }.reduce(0, +)
            let pitchUp = recent.map { max(0, -$0.pitchRate) }.reduce(0, +)  // tipping the top back = up
            let kind: PunchKind = yawArc > 1.4 * pitchUp && yawArc > 2 ? .hook : (pitchUp > 1.4 * yawArc && pitchUp > 2 ? .uppercut : .jab)
            let power = min(1, max(0.2, (p.peakG - Self.punchG) / 3.5 + 0.2))
            punches.append(Punch(kind: kind, power: power, yaw: yaw, pitch: pitch, atMs: Date().timeIntervalSince1970 * 1000))
        }
    }

    private func clamp(_ v: Double) -> Double { min(1, max(-1, v)) }
}
