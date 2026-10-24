import Foundation
import Observation
import UIKit

/// The thrower's side of one throw, on the phone: thumb down, wind up, thumb up (UX D1–D3).
/// Shared by the hall (Fight) and solo (Throw). It sends nothing itself: `onThrow` and
/// `onWindUp` do, so the same controller works with or without a server.
///
/// Safety: only a `.lift` of the held touch can throw. A cancel, a hold past 6 s, or the
/// turn going away puts the discus down without throwing.
@Observable
@MainActor
final class DiscusThrower {
    enum Stage: Equatable {
        case ready
        case winding
        case thrown(DiscusThrow, at: Date)
    }

    static let maxHold: TimeInterval = 6
    static let dropNotice = "That's a drop, not a throw."
    static let staleNotice = "The crowd is getting old. Throw."

    private(set) var stage: Stage = .ready
    /// The live swing, 0...1, held at its peak and easing down so the gauge doesn't flicker.
    private(set) var power: Double = 0
    private(set) var notice: String?
    /// The last hold's raw numbers, for the telemetry strip.
    private(set) var lastReading: SwingReading?
    var tuning = DiscusPhysics.Tuning.standard

    /// The throw, once, at the thumb lift.
    @ObservationIgnored var onThrow: ((DiscusThrow) -> Void)?
    /// About 20 Hz while held, then once with held = false: the arena's gauge (set_prosody).
    @ObservationIgnored var onWindUp: ((_ power: Double, _ held: Bool) -> Void)?

    @ObservationIgnored private let motion = DiscusMotion()
    @ObservationIgnored private let haptic = UIImpactFeedbackGenerator(style: .rigid)
    @ObservationIgnored private var heldFrom: TimeInterval = 0
    @ObservationIgnored private var dropsLeft = 1
    @ObservationIgnored private var holdLimit: Task<Void, Never>?
    @ObservationIgnored private var lastShown: TimeInterval = 0
    @ObservationIgnored private var lastSent: TimeInterval = 0
    @ObservationIgnored private var lastBuzz: TimeInterval = 0

    var hasMotion: Bool { motion.isAvailable }

    var thrown: DiscusThrow? {
        if case .thrown(let t, _) = stage { return t }
        return nil
    }

    var thrownAt: Date? {
        if case .thrown(_, let at) = stage { return at }
        return nil
    }

    /// A fresh throw: ready again, with one drop allowed (UX D2).
    func reset() {
        putDown()
        stage = .ready
        notice = nil
        dropsLeft = 1
    }

    func hold(_ event: DiscusHold) {
        switch event {
        case .down(let at):
            guard stage == .ready, motion.isAvailable else { return }
            notice = nil
            heldFrom = at
            stage = .winding
            haptic.prepare()
            motion.onSample = { [weak self] s in self?.sampled(s) }
            motion.start()
            onWindUp?(0, true)
            holdLimit = Task { [weak self] in
                try? await Task.sleep(for: .seconds(Self.maxHold))
                guard !Task.isCancelled, let self, self.stage == .winding else { return }
                self.putDown()
                self.stage = .ready
                self.notice = Self.staleNotice
            }
        case .lift(let at):
            guard stage == .winding else { return }
            let samples = motion.samples
            putDown()
            let reading = DiscusSwing.read(samples, heldFrom: heldFrom, releasedAt: at)
            lastReading = reading
            if reading.isDrop && dropsLeft > 0 {
                dropsLeft -= 1
                stage = .ready
                notice = Self.dropNotice
                return
            }
            let t = DiscusSwing.measure(reading, tuning: tuning)
            stage = .thrown(t, at: Date())
            onThrow?(t)
        case .cancel:
            guard stage == .winding else { return }
            putDown()
            stage = .ready
        }
    }

    /// Stops sampling without throwing. Safe to call in any stage.
    func putDown() {
        holdLimit?.cancel()
        holdLimit = nil
        motion.onSample = nil
        motion.stop()
        if power > 0 || stage == .winding { onWindUp?(0, false) }
        power = 0
    }

    private func sampled(_ s: SwingSample) {
        let p = DiscusPhysics.power(speed: s.spin, tuning: tuning)
        if s.t - lastShown >= 1.0 / 30 {
            power = max(p, power - 0.06)
            lastShown = s.t
        }
        if s.t - lastSent >= 0.05 {
            onWindUp?(power, true)
            lastSent = s.t
        }
        // The haptics rev with the swing: quicker and harder as the power builds.
        if p > 0.05, s.t - lastBuzz >= 0.25 - 0.17 * p {
            haptic.impactOccurred(intensity: 0.3 + 0.7 * p)
            lastBuzz = s.t
        }
    }
}
