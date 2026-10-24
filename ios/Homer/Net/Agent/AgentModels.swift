// Shapes for the agent service (homer/API.md). Responses decode leniently: optional
// fields are optional so a new server field or a missing extra never breaks a turn.

import Foundation

/// A word from speech-to-text in turn time: ms from beat 1 (negative during the count-in).
struct TimedWord: Codable, Equatable, Sendable {
    var text: String
    var start: Double
    var end: Double
}

struct VoiceTokenRequest: Encodable, Sendable {
    enum Role: String, Encodable, Sendable { case phone, arena, solo }
    var role: Role
    var roomCode: String?
    var playerId: UInt64?
}

struct VoiceToken: Decodable, Equatable, Sendable {
    struct STT: Decodable, Equatable, Sendable { var model: String; var encoding: String; var sampleRate: Int }
    struct TTS: Decodable, Equatable, Sendable { var model: String; var voiceId: String }

    var token: String
    var expiresAt: Double  // epoch ms
    var cartesiaVersion: String
    var stt: STT?
    var tts: TTS?

    var isFresh: Bool { expiresAt - Date().timeIntervalSince1970 * 1000 > 30_000 }
}

struct ScanRequest: Encodable, Sendable {
    var transcript: String?
    var words: [TimedWord]?
    var bpm: Double?
    var linesExpected: Int?
    var hand: [String]?
    var startedAt: Double?
    var event = "poetry"
}

struct VerseScan: Decodable, Equatable, Sendable {
    struct Line: Decodable, Equatable, Sendable {
        var text: String
        var pattern: String
        var hits: Int
        var breakAfter: Int?
        var breakSource: String?
        var weakBeats: [String]?
        var extras: [String]?
        var onBeat: Int?
        var offsetMs: Double?
        var score: Double?
        var words: [Word]?
    }

    struct Word: Decodable, Equatable, Sendable {
        var text: String
        var syllables: Int?
        var beat: Bool?
        var hit: Bool?
        var weakBeat: Bool?
        var extra: Bool?
        var t: Double?
        var onBeat: Bool?
        var formulaId: String?
    }

    var beat: Int
    var linesExpected: Int?
    var timed: Bool?
    var bestLine: Int?
    var formulas: [String]?
    var lines: [Line]
    var beatLane: BeatLane?
}

struct JudgeRequest: Encodable, Sendable {
    enum Mode: String, Encodable, Sendable { case practice, lesson, battle }
    var transcript: String
    var words: [TimedWord]?
    var bpm: Double?
    var linesExpected: Int
    var mode: Mode
    var event = "poetry"
    var theme: String
    var hand: [String]
    var played: [String]
    var rescues: Int
    var previous: String?
    var emotionHistory: [EmotionWeights]?
    var hoard: [String]
    var demo: Bool
}

/// The agent's Scorecard: Contracts.Scorecard plus extras.
struct JudgeResult: Decodable, Equatable, Sendable {
    var scores: Scores
    var total: Int?
    var verdict: String
    var bestLine: String
    var coined: String?
    var declined: Bool?
    var silent: Bool?
    var scan: VerseScan?

    var scorecard: Scorecard { Scorecard(scores: scores, verdict: verdict, bestLine: bestLine) }
    /// Claude timed out: show "Homer is silent on this one."
    var isSilent: Bool { silent ?? false }
    /// Not fit for the hall: "Not in my hall. Give me another."
    var isDeclined: Bool { declined ?? false }
}

enum JudgeEvent: Equatable, Sendable {
    /// Arrives first, so text-to-speech can start before the scores are done.
    case verdict(String)
    case scorecard(JudgeResult)
}

struct DealRequest: Encodable, Sendable {
    var theme = ""
    var hoard: [String] = []
    var exclude: [String] = []
    var n = 5
}

struct DealtCard: Decodable, Equatable, Sendable {
    var id: String
    var text: String
    var kind: FormulaCard.Kind
    var used: Bool
    var beats: Int?
    var hoard: Bool?

    var card: FormulaCard { FormulaCard(id: id, text: text, kind: kind, used: used) }
}

struct DealResponse: Decodable, Equatable, Sendable {
    var theme: String
    var hand: [DealtCard]
}

struct RescueRequest: Encodable, Sendable {
    var transcript: String
    var hand: [String]
    var played: [String]
    var theme: String
}

struct RescueResponse: Decodable, Equatable, Sendable {
    var formula: String
}

struct BattleDealRequest: Encodable, Sendable {
    var roomId: UInt64
    var roundNo: UInt32
    var theme: String
}

struct BattleJudgeRequest: Encodable, Sendable {
    var turnId: UInt64
    var playerId: UInt64
    var transcript: String
    var event = "poetry"
    var form: String
    var theme: String
    var played: [String]
    var rescues: UInt32
    var previous: String
    var linesExpected: UInt32
    var hoard: [String]
    var demo: Bool
}
