import XCTest
@testable import Homer

final class BeatClockTests: XCTestCase {
    // 80 bpm: a beat is 750 ms, a bar 3000 ms; with rests a line is 6000 ms.
    let clock = BeatClock(beatAtMs: 10_000, bpm: 80, barsPerLine: 2, lines: 2)

    func testGridHasSpeakingAndRestBars() {
        XCTAssertEqual(clock.beats.count, 16)
        XCTAssertEqual(clock.beats.filter(\.speaking).count, 8)
        XCTAssertEqual(clock.beats[4].ms, 13_000)  // first rest beat
        XCTAssertFalse(clock.beats[4].speaking)
        XCTAssertEqual(clock.beats[8].ms, 16_000)  // line 2, beat 1
        XCTAssertEqual(clock.endMs, 22_000)
    }

    func testHitsOnlyOnSpeakingBeatsWithinWindow() {
        XCTAssertEqual(clock.hit(atMs: 10_050)?.index, 0)
        XCTAssertEqual(clock.hit(atMs: 9_920)?.index, 0)  // just early on beat 1
        XCTAssertNil(clock.hit(atMs: 9_840))  // outside the ±140 ms window
        XCTAssertEqual(clock.hit(atMs: 12_200)?.index, 3)
        XCTAssertNil(clock.hit(atMs: 10_375))  // between beats
        XCTAssertNil(clock.hit(atMs: 13_000))  // rest bar
        let second = clock.hit(atMs: 16_740)
        XCTAssertEqual(second?.line, 1)
        XCTAssertEqual(second?.index, 1)
        XCTAssertNil(clock.hit(atMs: 23_000))  // after the turn
    }

    func testSpeakingBarAndLine() {
        XCTAssertTrue(clock.isSpeakingBar(atMs: 11_000))
        XCTAssertFalse(clock.isSpeakingBar(atMs: 14_000))
        XCTAssertEqual(clock.line(atMs: 17_000), 1)
    }

    func testOffset() {
        XCTAssertEqual(BeatClock.offset(localReceiveMs: 5_100, serverStartedAtMs: 5_000), 100)
    }
}
