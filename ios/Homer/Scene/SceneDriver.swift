import Foundation

/// What the scene reads every frame. Write it from the mic or the network at
/// any rate; no SwiftUI view re-renders. Main thread only: the renderer reads
/// it in `draw(in:)`.
final class SceneDriver: @unchecked Sendable {
    var emotion: EmotionWeights {
        didSet {
            record(emotion)
            wake?()
        }
    }
    var prosody: Prosody {
        didSet { if prosody.energy > 0.03 { wake?() } }
    }

    /// Set by the renderer: resumes drawing after an idle pause. A voice, a new
    /// feeling or a strike wakes the scene.
    var wake: (() -> Void)?

    /// A drum strike: a stressed syllable landed on the beat. Call it with the
    /// strike sound; the scene answers with a ring, a jump and a burst of flecks.
    func strike(_ strength: Double = 1) {
        strikes += 1
        strikeStrength = strength
        wake?()
    }

    /// Read by the renderer: it fires one strike per increment.
    private(set) var strikes = 0
    private(set) var strikeStrength = 1.0

    init(emotion: EmotionWeights = EmotionWeights(), prosody: Prosody = .silent) {
        self.emotion = emotion
        self.prosody = prosody
        record(emotion)
    }

    // MARK: - Color replay (P11)

    /// Replays the colors the scene showed between two wall-clock times (epoch
    /// ms, the same clock as `BeatLane.startedAt`), stretched over `duration`
    /// seconds, then returns to live. Use it while Homer re-reads a best line.
    func replay(fromMs: Double, toMs: Double, over duration: TimeInterval) {
        let window = history.filter { $0.at >= fromMs && $0.at <= toMs }
        // The reading in force when the window opened, so the replay starts on the right color.
        let opening = history.last { $0.at < fromMs }
        let samples = (opening.map { [Sample(at: fromMs, weights: $0.weights)] } ?? []) + window
        guard !samples.isEmpty, toMs > fromMs, duration > 0 else { return }
        replaying = Replay(samples: samples, fromMs: fromMs, toMs: toMs, startedAt: Date(), duration: duration)
    }

    func stopReplay() { replaying = nil }

    /// The emotion to show this frame: the replay if one is running, else live.
    func emotionForFrame(_ now: Date = Date()) -> EmotionWeights {
        guard let r = replaying else { return emotion }
        let t = now.timeIntervalSince(r.startedAt) / r.duration
        if t >= 1 {
            replaying = nil
            return emotion
        }
        let at = r.fromMs + t * (r.toMs - r.fromMs)
        return (r.samples.last { $0.at <= at } ?? r.samples[0]).weights
    }

    private struct Sample {
        let at: Double // epoch ms
        let weights: EmotionWeights
    }

    private struct Replay {
        let samples: [Sample]
        let fromMs: Double
        let toMs: Double
        let startedAt: Date
        let duration: TimeInterval
    }

    private var history: [Sample] = []
    private var replaying: Replay?
    private let historyMs: Double = 15 * 60 * 1000

    private func record(_ weights: EmotionWeights) {
        let now = Date().timeIntervalSince1970 * 1000
        history.append(Sample(at: now, weights: weights))
        if let first = history.first, now - first.at > historyMs {
            history.removeAll { now - $0.at > historyMs }
        }
    }
}
