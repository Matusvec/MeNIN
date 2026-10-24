import XCTest
@testable import Homer

final class ContractsTests: XCTestCase {
    func testDecodesWireShapes() throws {
        let json = """
        {
          "emotion": {"anger": 0.1, "awe": 0.9, "unknownFutureEmotion": 0.5},
          "prosody": {"energy": 0.4, "pitch": null},
          "card": {"id": "f1", "text": "the whale-road", "kind": "half_line", "used": false},
          "lane": {"bpm": 80, "beatsPerLine": 4, "lines": 4, "startedAt": 1761300000000,
                   "words": [{"text": "wine", "t": 12.5, "stressed": true, "onBeat": true, "formulaId": "f1"},
                             {"text": "dark", "t": 300, "stressed": false, "onBeat": false}]},
          "scorecard": {"scores": {"beat": 8, "craft": 6, "image": 9, "answer": 5, "range": 7},
                        "verdict": "Iron.", "bestLine": "The wine-dark sea took my brother's ship"}
        }
        """
        struct Bundle: Decodable {
            var emotion: EmotionWeights
            var prosody: Prosody
            var card: FormulaCard
            var lane: BeatLane
            var scorecard: Scorecard
        }
        let b = try JSONDecoder().decode(Bundle.self, from: Data(json.utf8))
        XCTAssertEqual(b.emotion[.awe], 0.9)
        XCTAssertEqual(b.emotion[.grief], 0)
        XCTAssertNil(b.prosody.pitch)
        XCTAssertEqual(b.card.kind, .halfLine)
        XCTAssertEqual(b.lane.startedAt, 1_761_300_000_000)
        XCTAssertEqual(b.lane.words[0].formulaId, "f1")
        XCTAssertNil(b.lane.words[1].formulaId)
        XCTAssertEqual(b.scorecard.scores[.image], 9)
        XCTAssertEqual(b.scorecard.scores.total, 35)
    }

    func testEncodesNullPitchAndKeyedEmotions() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        XCTAssertEqual(String(decoding: try encoder.encode(Prosody.silent), as: UTF8.self), #"{"energy":0,"pitch":null}"#)
        XCTAssertEqual(String(decoding: try encoder.encode(EmotionWeights([.joy: 1])), as: UTF8.self), #"{"joy":1}"#)
    }
}
