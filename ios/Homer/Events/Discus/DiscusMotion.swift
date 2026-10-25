import CoreMotion
import Foundation

/// Device motion at 100 Hz, only while the thumb is down. One CMMotionManager per app, as
/// Apple recommends; it is never shared with anything else in the app.
@MainActor
final class DiscusMotion {
    static let rate: TimeInterval = 1.0 / 100
    /// Plenty for a 6 s hold (the longest before it resets) at 100 Hz.
    private static let capacity = 800

    private let manager = CMMotionManager()
    private(set) var samples: [SwingSample] = []
    /// The same updates in full (attitude, user acceleration), for DiscusRelease at the lift.
    private(set) var releaseSamples: [DiscusRelease.Sample] = []
    var onSample: ((SwingSample) -> Void)?

    /// False on the simulator, which has no gyro.
    var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return true  // the simulator swings a synthetic discus; see start()
        #else
        return manager.isDeviceMotionAvailable
        #endif
    }

    func start() {
        samples.removeAll(keepingCapacity: true)
        releaseSamples.removeAll(keepingCapacity: true)
        #if targetEnvironment(simulator)
        startSimulated()
        #else
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = Self.rate
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            MainActor.assumeIsolated {
                let r = motion.rotationRate
                let g = motion.gravity
                self?.appendRelease(DiscusRelease.Sample(motion))
                self?.append(SwingSample(t: motion.timestamp, rotation: [r.x, r.y, r.z], gravity: [g.x, g.y, g.z]))
            }
        }
        #endif
    }

    func stop() {
        #if targetEnvironment(simulator)
        simulated?.cancel()
        simulated = nil
        #else
        manager.stopDeviceMotionUpdates()
        #endif
    }

    private func appendRelease(_ s: DiscusRelease.Sample) {
        if releaseSamples.count >= Self.capacity { releaseSamples.removeFirst(releaseSamples.count - Self.capacity + 1) }
        releaseSamples.append(s)
    }

    private func append(_ s: SwingSample) {
        if samples.count >= Self.capacity { samples.removeFirst(samples.count - Self.capacity + 1) }
        samples.append(s)
        onSample?(s)
    }

    #if targetEnvironment(simulator)
    // Simulator only, never in a device build: a swing that builds to about 12 rad/s over a
    // second on a slightly tilted plane, so the flow can be driven without a gyro.
    private var simulated: Task<Void, Never>?

    private func startSimulated() {
        simulated?.cancel()
        let start = ProcessInfo.processInfo.systemUptime
        simulated = Task { [weak self] in
            while !Task.isCancelled {
                let t = ProcessInfo.processInfo.systemUptime
                let spin = min(12, 12 * (t - start))
                let tilt = 15.0 * .pi / 180
                self?.append(SwingSample(t: t, rotation: [sin(tilt) * spin, 0, -cos(tilt) * spin], gravity: [0, 0, -1]))
                try? await Task.sleep(for: .milliseconds(10))
            }
        }
    }
    #endif
}
