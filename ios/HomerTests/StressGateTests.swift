import XCTest
@testable import Homer

final class StressGateTests: XCTestCase {
    // 80 bpm with rests: speaking beats at 10_000, 10_750, 11_500, 12_250.
    let clock = BeatClock(beatAtMs: 10_000, bpm: 80, barsPerLine: 2, lines: 1)

    func testOnlyProminentSyllablesOnAPulseCount() {
        var gate = StressGate()
        // A loud stress on beat 1.
        let lag = StressGate.heardLatencyMs  // the gate shifts onsets back by the output latency
        XCTAssertEqual(gate.judge(.init(epochMs: 10_020 + lag, energy: 0.8), on: clock), .hit(clock.hit(atMs: 10_020)!))
        // A quiet syllable right on beat 2 is not a stress, so not a hit.
        XCTAssertEqual(gate.judge(.init(epochMs: 10_750 + lag, energy: 0.3), on: clock), .unstressed)
        // A loud syllable between beats is a stress that missed.
        XCTAssertEqual(gate.judge(.init(epochMs: 11_120 + lag, energy: 0.78), on: clock), .offBeat)
        // A second stress on a pulse already hit doesn't count twice.
        XCTAssertEqual(gate.judge(.init(epochMs: 10_060 + lag, energy: 0.8), on: clock), .offBeat)
        // Below the floor never counts, however quiet the room was.
        var quiet = StressGate()
        XCTAssertEqual(quiet.judge(.init(epochMs: 11_500 + lag, energy: 0.12), on: clock), .unstressed)
    }
}
