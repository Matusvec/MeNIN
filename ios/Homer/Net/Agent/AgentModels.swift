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
    struct TTS: Decodable, Equatable, Sendable {
        var model: String
        var voiceId: String
        /// Per host: {"homer": id, "socrates": id}; empty until a voice is picked.
        var voices: [String: String]?
    }

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

    var scorecard: Scorecard { Scorecard(scores: scores, verdict: verdict, bestLine: bestLine, total: total) }
    /// Claude timed out: show "Homer is silent on this one."
    var isSilent: Bool { silent ?? false }
    /// Not fit for the hall: "Not in my hall. Give me another."
    var isDeclined: Bool { declined ?? false }
}

enum JudgeEvent: Equatable, Sendable {
    /// Arrives first, so text-to-speech can start before the scores are done.
    case verdict(String)
    case scorecard(JudgeResult)
    /// The server couldn't judge it (`event: error`, e.g. "nothing to judge": a transcript with no
    /// scannable words). Not a silent judge: there was no verse to hear.
    case failed(String)
}

/// One Bard lesson from GET /lessons (parsed live from content/lessons.md).
struct Lesson: Decodable, Equatable, Sendable, Identifiable {
    var id: String
    var n: Int
    var title: String
    var move: String
    var exercise: [String]?
    var exerciseSpoken: String?
    var demo: [String]
    var demoSpoken: String
    var demoLane: BeatLane?
    var success: String
    var feedback: Bool?

    /// Lines the poet speaks per try (docs/ux-flow.md section 2, "You try").
    var tryLines: Int {
        switch id {
        case "beat", "answer": 2
        case "turn": 4
        default: 1
        }
    }
}

struct LessonFeedbackRequest: Encodable, Sendable {
    var lesson: String
    var transcript: String
    var bpm: Double
    /// 1-based try number within the lesson: P10 help comes back on 3, a walkthrough from 5.
    var tryNo: Int
    /// Stressed peaks in ms from beat 1 (on-device onsets), so "rushing the drum" works without word timings.
    var onsetsMs: [Double]?
    var hand: [String]?
    var rescue: String?
    var name: String?
}

struct LessonFeedback: Decodable, Equatable, Sendable {
    struct Help: Decodable, Equatable, Sendable {
        var kind: String  // "half" after the 3rd miss, "walkthrough" from the 5th (and the lesson lands)
        var say: String
        var half: String?
        var line: String?
    }

    var landed: Bool
    var line: String
    var miss: String?
    var title: String?
    var scan: VerseScan?
    var help: Help?
}

struct EmotionRequest: Encodable, Sendable {
    var text: String
    var loudness: Double?
    var pitch: Double?
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

struct BattleDealResult: Decodable, Sendable {
    var theme: String?
    var call: String?
}

struct BattlePoetRequest: Encodable, Sendable { var playerId: UInt64 }
struct BattleVerdictRequest: Encodable, Sendable { var roundId: UInt64 }
struct BattleSongRequest: Encodable, Sendable { var roomId: UInt64 }

struct BattleEmotionRequest: Encodable, Sendable {
    var turnId: UInt64
    var transcript: String
    var loudness: Double?
    var pitch: Double?
}

/// Socratic debate content from GET /debate (content/debate.md, read live).
struct DebateQuestion: Decodable, Equatable, Sendable {
    var id: String
    var ask: String
    var sides: [String]
}

struct DebateWhispersRequest: Encodable, Sendable {
    var question: String
    var side: String
    var hand: [String]
    var previous: String?
}

struct DebateRescueRequest: Encodable, Sendable {
    var event = "debate"
    var transcript: String
    var hand: [String]
    var played: [String]
    var previous: String?
    var elapsedS: Double
    var turnSeconds: Double
    var whispers: [String: String]
}

struct DebateRescue: Decodable, Equatable, Sendable {
    struct Card: Decodable, Equatable, Sendable { var id: String; var text: String }
    var whisper: String
    var card: Card
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
    // Debate only: the side dealt, the turn's length, and Go to the end of the turn.
    var side: String? = nil
    var turnSeconds: Double? = nil
    var spokenSeconds: Double? = nil
}
