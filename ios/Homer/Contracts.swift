// Shared types between the app, SpacetimeDB, and the agent service.
// The JSON shapes are the wire format; change them only with the leader's sign-off.

import Foundation

enum Emotion: String, CaseIterable, Codable, Sendable {
    case anger, grief, joy, awe, tenderness, fear, defiance, longing
}

/// `{"anger": 0.1, ...}`: each 0...1, summing to about 1.
/// Missing keys read as 0 and unknown keys are ignored, so either side can add emotions safely.
struct EmotionWeights: Codable, Equatable, Sendable {
    var values: [Emotion: Double]

    init(_ values: [Emotion: Double] = [:]) {
        self.values = values
    }

    subscript(emotion: Emotion) -> Double {
        get { values[emotion] ?? 0 }
        set { values[emotion] = newValue }
    }

    static let neutral = EmotionWeights(Dictionary(uniqueKeysWithValues: Emotion.allCases.map { ($0, 1.0 / Double(Emotion.allCases.count)) }))

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: Double].self)
        values = Dictionary(uniqueKeysWithValues: raw.compactMap { key, value in Emotion(rawValue: key).map { ($0, value) } })
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Dictionary(uniqueKeysWithValues: values.map { ($0.key.rawValue, $0.value) }))
    }
}

/// `{"energy": 0..1, "pitch": Hz or null}`
struct Prosody: Codable, Equatable, Sendable {
    var energy: Double
    var pitch: Double?

    static let silent = Prosody(energy: 0, pitch: nil)

    private enum CodingKeys: String, CodingKey { case energy, pitch }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(energy, forKey: .energy)
        try container.encode(pitch, forKey: .pitch)  // explicit null, not a missing key
    }
}

/// `{"id", "text", "kind": "epithet" | "kenning" | "half_line" | "move", "used"}`
struct FormulaCard: Codable, Equatable, Sendable, Identifiable {
    enum Kind: String, Codable, Sendable {
        case epithet, kenning
        case halfLine = "half_line"
        case move  // a rhetorical move card (Socratic debate)
    }

    var id: String
    var text: String
    var kind: Kind
    var used: Bool
}

/// `{"text", "t": ms since startedAt, "stressed", "onBeat", "formulaId"?}`
struct BeatWord: Codable, Equatable, Sendable {
    var text: String
    var t: Double
    var stressed: Bool
    var onBeat: Bool
    var formulaId: String?
}

/// PROVISIONAL until the scanner and STT timing are settled (see docs/voice.md).
/// `{"bpm", "beatsPerLine": 4, "lines", "startedAt": epoch ms of beat 1, "words": [BeatWord]}`
struct BeatLane: Codable, Equatable, Sendable {
    var bpm: Double
    var beatsPerLine: Int
    var lines: Int
    var startedAt: Double
    var words: [BeatWord]
}

enum Axis: String, CaseIterable, Codable, Sendable {
    case beat, craft, image, answer, range
}

/// `{"beat", "craft", "image", "answer", "range"}`, each 1...10.
struct Scores: Codable, Equatable, Sendable {
    var beat: Int
    var craft: Int
    var image: Int
    var answer: Int
    var range: Int

    subscript(axis: Axis) -> Int {
        switch axis {
        case .beat: beat
        case .craft: craft
        case .image: image
        case .answer: answer
        case .range: range
        }
    }

    var total: Int { Axis.allCases.reduce(0) { $0 + self[$1] } }
}

/// `{"scores": {...}, "verdict", "bestLine"}`
struct Scorecard: Codable, Equatable, Sendable {
    var scores: Scores
    var verdict: String
    var bestLine: String
}
