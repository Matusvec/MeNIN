import CoreHaptics
import Foundation

/// The speaker's phone carries the beat as taps you feel (SPEC: the arena ducks its drum
/// while a poet speaks). One pattern is scheduled for the whole turn from the BeatClock, so
/// taps don't drift with timer jitter. A hit adds a sharp strike at once. No-op on devices
/// without haptics (Mac, iPad).
@MainActor
final class BeatHaptics {
    private var engine: CHHapticEngine?
    private var player: CHHapticPatternPlayer?

    func prepare() {
        guard engine == nil, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.isAutoShutdownEnabled = false
        engine?.resetHandler = { [weak self] in
            Task { @MainActor in try? self?.engine?.start() }
        }
        try? engine?.start()
    }

    /// Schedules every remaining beat: strong downbeats, medium speaking beats, faint rest beats.
    func play(_ clock: BeatClock, nowMs: Double = Date().timeIntervalSince1970 * 1000) {
        guard let engine else { return }
        let events: [CHHapticEvent] = clock.beats.compactMap { beat in
            let relative = (beat.ms - nowMs) / 1000
            guard relative >= 0 else { return nil }
            let intensity: Float = !beat.speaking ? 0.25 : (beat.index == 0 ? 0.9 : 0.6)
            return CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: beat.speaking ? 0.4 : 0.2),
            ], relativeTime: relative)
        }
        guard !events.isEmpty, let pattern = try? CHHapticPattern(events: events, parameters: []) else { return }
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = try? engine.makePlayer(with: pattern)
        try? player?.start(atTime: CHHapticTimeImmediate)
    }

    /// A stressed syllable landed on the beat.
    func hit() {
        guard let engine,
              let pattern = try? CHHapticPattern(events: [
                  CHHapticEvent(eventType: .hapticTransient, parameters: [
                      CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                      CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
                  ], relativeTime: 0),
              ], parameters: []) else { return }
        try? engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }
}
