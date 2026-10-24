import AVFoundation

/// Turns raw syllable onsets into stresses and beat hits, so the lane only lights for real hits.
/// Any syllable can start near a pulse (at 80 bpm a pulse comes every 750 ms and speech runs
/// several syllables in that time), so a hit needs a stress: an onset about as loud as the
/// loudest of the last couple of seconds. Each pulse counts once; a stress off the beat is shown
/// as a miss rather than hidden.
struct StressGate {
    static let window = 2.5  // seconds of recent onsets to compare against
    static let prominence = 0.6  // a stress is at least this share of the recent loudest onset
    static let floor = 0.18

    private var recent: [(ms: Double, energy: Double)] = []
    private var hitPulses = Set<Int>()

    enum Verdict: Equatable {
        case unstressed
        case hit(BeatClock.Beat)  // first stress on this pulse
        case offBeat  // a stress that missed the beat (or landed on a pulse already hit)
    }

    mutating func reset() {
        recent.removeAll()
        hitPulses.removeAll()
    }

    /// What the poet hears lags the scheduled beat by the output latency (much more on Bluetooth),
    /// and they stress on what they hear; shift onsets back by it before judging.
    static var heardLatencyMs: Double {
        let session = AVAudioSession.sharedInstance()
        return (session.outputLatency + session.ioBufferDuration) * 1000
    }

    mutating func judge(_ raw: MicEngine.Onset, on clock: BeatClock) -> Verdict {
        var onset = raw
        onset.epochMs -= Self.heardLatencyMs
        recent.removeAll { onset.epochMs - $0.ms > Self.window * 1000 }
        recent.append((onset.epochMs, onset.energy))
        let loudest = recent.map(\.energy).max() ?? onset.energy
        guard onset.energy >= Self.floor, onset.energy >= Self.prominence * loudest else { return .unstressed }
        guard let beat = clock.hit(atMs: onset.epochMs) else { return .offBeat }
        let pulse = beat.line * 1000 + beat.index
        guard hitPulses.insert(pulse).inserted else { return .offBeat }
        return .hit(beat)
    }
}
