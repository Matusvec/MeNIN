import XCTest
@testable import Homer

final class AgentClientTests: XCTestCase {
    func testDecodesScorecardFromAPIDoc() throws {
        let json = """
        {"scores": {"beat": 9, "craft": 6, "image": 7, "answer": 5, "range": 6}, "total": 33,
         "verdict": "Strong bones, thin blood.", "bestLine": "the sea kept time and so did I", "coined": "",
         "declined": false, "silent": false,
         "scan": {"beat": 9, "linesExpected": 4, "timed": true, "bestLine": 0, "formulas": ["wine-dark-sea"],
                  "lines": [{"text": "the wine dark sea took my brother's ship", "pattern": "the WINE dark SEA / took my BROTHER'S SHIP",
                             "hits": 4, "breakAfter": 3, "breakSource": "pause", "weakBeats": [], "extras": [], "onBeat": 3,
                             "offsetMs": -40.5, "score": 0.85,
                             "words": [{"text": "wine", "syllables": 1, "known": true, "beat": true, "hit": true, "weakBeat": false,
                                        "extra": false, "t": 0, "onBeat": true, "formulaId": "wine-dark-sea", "joined": false}]}],
                  "beatLane": {"bpm": 80, "beatsPerLine": 4, "lines": 2, "startedAt": 1761300000000,
                               "words": [{"text": "wind", "t": 0, "stressed": true, "onBeat": true, "formulaId": null}]}},
         "timing": {"scan": 9}, "model": "claude-opus-5-5"}
        """
        let r = try JSONDecoder().decode(JudgeResult.self, from: Data(json.utf8))
        XCTAssertEqual(r.scorecard.scores.total, 33)
        XCTAssertFalse(r.isSilent)
        XCTAssertEqual(r.scan?.lines.first?.offsetMs, -40.5)
        XCTAssertEqual(r.scan?.beatLane?.words.first?.text, "wind")
    }

    func testDecodesVoiceToken() throws {
        let json = #"{"token": "t", "expiresAt": 1761300300000, "cartesiaVersion": "2026-08-14", "stt": {"model": "ink-2", "encoding": "pcm_s16le", "sampleRate": 16000}}"#
        let t = try JSONDecoder().decode(VoiceToken.self, from: Data(json.utf8))
        XCTAssertEqual(t.stt?.sampleRate, 16000)
        XCTAssertNil(t.tts)
    }

    func testSSEParserSplitsVerdictThenScorecard() throws {
        var parser = SSEParser()
        var events: [SSEParser.Event] = []
        // URLSession's `lines` drops blank lines, so events also end when the next `event:` begins.
        for line in ["event: verdict", #"data: {"verdict": "Iron."}"#, "event: scorecard", #"data: {"scores": {"beat": 8, "craft": 7, "image": 6, "answer": 5, "range": 4}, "verdict": "Iron.", "bestLine": "x"}"#] {
            events += parser.feed(line)
        }
        events += parser.finish()
        XCTAssertEqual(events.map(\.name), ["verdict", "scorecard"])
        XCTAssertEqual(try AgentClient.judgeEvent(events[0]), .verdict("Iron."))
        guard case .scorecard(let card) = try AgentClient.judgeEvent(events[1]) else { return XCTFail() }
        XCTAssertEqual(card.scores.beat, 8)
    }
}
