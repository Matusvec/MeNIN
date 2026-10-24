import XCTest
@testable import Homer

final class ProsodyAnalyzerTests: XCTestCase {
    private let sampleRate = 48_000.0

    private func tone(_ hz: Double, amplitude: Float = 0.3, count: Int = 2048) -> [Float] {
        (0..<count).map { i in
            // Fundamental plus a weaker octave, like a voiced vowel.
            let t = Double(i) / sampleRate
            return amplitude * Float(sin(2 * .pi * hz * t) + 0.4 * sin(2 * .pi * 2 * hz * t))
        }
    }

    func testFindsPitchOfVoicedTone() {
        for hz in [90.0, 140.0, 220.0, 330.0] {
            let p = tone(hz).withUnsafeBufferPointer { ProsodyAnalyzer.analyze($0, sampleRate: sampleRate) }
            let pitch = try? XCTUnwrap(p.pitch)
            XCTAssertEqual(pitch ?? 0, hz, accuracy: hz * 0.03, "pitch for \(hz) Hz")
            XCTAssertGreaterThan(p.energy, 0.5)
        }
    }

    func testSilenceIsQuietAndUnvoiced() {
        let p = [Float](repeating: 0, count: 2048).withUnsafeBufferPointer { ProsodyAnalyzer.analyze($0, sampleRate: sampleRate) }
        XCTAssertEqual(p, .silent)
    }

    func testNoiseHasNoPitch() {
        var rng = SystemRandomNumberGenerator()
        let noise = (0..<2048).map { _ in Float.random(in: -0.3...0.3, using: &rng) }
        let p = noise.withUnsafeBufferPointer { ProsodyAnalyzer.analyze($0, sampleRate: sampleRate) }
        XCTAssertNil(p.pitch)
    }
}
