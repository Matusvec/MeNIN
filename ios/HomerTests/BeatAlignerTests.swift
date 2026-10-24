import XCTest
@testable import Homer

final class BeatAlignerTests: XCTestCase {
    let sr = 1_000.0  // 1 sample per ms keeps the arithmetic readable

    /// "the WINE-dark SEA" spoken naturally: stresses at 0.25 s and 0.95 s (0.7 s apart);
    /// at 80 bpm (0.75 s a beat) the second must move 50 ms later.
    func testStressesLandOnPulses() {
        let spoken = [CartesiaTTS.Word(text: "the", start: 0.05, end: 0.18),
                      CartesiaTTS.Word(text: "wine-dark", start: 0.2, end: 0.6),
                      CartesiaTTS.Word(text: "sea", start: 0.9, end: 1.3)]
        let scanned = [VerseScan.Word(text: "the", beat: false), VerseScan.Word(text: "wine", beat: true),
                       VerseScan.Word(text: "dark", beat: false), VerseScan.Word(text: "sea", beat: true)]
        let stresses = BeatAligner.stresses(scanned: scanned, spoken: spoken)
        XCTAssertEqual(stresses.map(\.word), [1, 2])
        XCTAssertEqual(stresses[0].at, 0.27, accuracy: 0.001)  // just into "wine"
        XCTAssertEqual(stresses[1].at, 0.97, accuracy: 0.001)

        let audio = [Float](repeating: 0.5, count: Int(1.4 * sr))
        let placed = BeatAligner.place(audio, sampleRate: sr, words: spoken, stresses: stresses, beatSeconds: 0.75)!
        XCTAssertEqual(placed.worstLate, 0, accuracy: 0.001)
        // The pickup ("the") sits before pulse 1: the file starts that far ahead of the beat.
        XCTAssertEqual(placed.leadSeconds, 0.27 - 0.02, accuracy: 0.002)
        XCTAssertGreaterThan(placed.samples.count, Int(1.0 * sr))
    }

    func testNoStressesMeansNothingToPlace() {
        let spoken = [CartesiaTTS.Word(text: "oh", start: 0, end: 0.3)]
        XCTAssertTrue(BeatAligner.stresses(scanned: [VerseScan.Word(text: "oh", beat: false)], spoken: spoken).isEmpty)
        XCTAssertNil(BeatAligner.place([0.1, 0.2], sampleRate: sr, words: spoken, stresses: [], beatSeconds: 0.75))
    }
}
