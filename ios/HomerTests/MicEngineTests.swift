import XCTest
@testable import Homer

final class MicEngineTests: XCTestCase {
    /// Three 80 ms "syllables" at 300 ms spacing over near-silence: three onsets, ~300 ms apart.
    func testOnsetDetectorFindsSyllables() {
        let sr = 48_000.0
        var signal = [Float](repeating: 0.0005, count: Int(sr))
        for start in [0.1, 0.4, 0.7] {
            let s = Int(start * sr)
            for i in 0..<Int(0.08 * sr) { signal[s + i] = 0.3 * Float(sin(2 * .pi * 180 * Double(i) / sr)) }
        }
        var detector = OnsetDetector(sampleRate: sr)
        var onsets: [MicEngine.Onset] = []
        // Feed in 1024-frame buffers like the tap does.
        var t = 0
        while t < signal.count {
            let n = min(1024, signal.count - t)
            onsets += signal[t..<(t + n)].withUnsafeBufferPointer { detector.feed($0, bufferEpochMs: 1_000_000 + Double(t) / sr * 1000) }
            t += n
        }
        XCTAssertEqual(onsets.count, 3)
        let times = onsets.map { $0.epochMs - 1_000_000 }
        for (got, want) in zip(times, [100.0, 400.0, 700.0]) { XCTAssertEqual(got, want, accuracy: 15) }
    }
}
