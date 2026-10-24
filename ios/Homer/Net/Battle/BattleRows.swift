// Hand-written bindings for the `homer` SpacetimeDB module (spacetime/CONTRACT.md).
// BSATN is positional: stored properties must stay in column order.

import Foundation
import SpacetimeDB

/// i64 microseconds since the Unix epoch; 0 means "not set".
struct SpacetimeTimestamp: Codable, Sendable, Hashable {
    var micros: Int64

    var isSet: Bool { micros != 0 }
    var date: Date { Date(timeIntervalSince1970: Double(micros) / 1_000_000) }
    var epochMs: Double { Double(micros) / 1000 }
}

extension Identity {
    /// Canonical hex as SpacetimeDB prints it (`0x…` in SQL): the u256 big-endian.
    /// `rawBytes` is the BSATN wire form, which is little-endian.
    var hex: String { rawBytes.reversed().map { String(format: "%02x", $0) }.joined() }
}

enum RoomPhase: String, Sendable {
    case lobby, theme, dealing, ready, speaking, judging, scored, finale, finished
    case roundEnd = "round_end"
}

enum TurnStatus: String, Sendable {
    case waiting, speaking, judging, scored, skipped, declined
}

struct RoomRow: Codable, Sendable, Identifiable, Equatable {
    var id: UInt64
    var event: String
    var code: String
    var host: Identity
    var phase: String
    var roundNo: UInt32
    var rounds: UInt32
    var turnSeconds: UInt32  // derived, display only; count down to turn.ends_at
    var linesPerTurn: UInt32
    var bpm: UInt32
    var form: String
    var maxPlayers: UInt32
    var autoReady: Bool
    var themeChoice: Bool
    var demo: Bool
    var nextTheme: String
    var currentTurnId: UInt64
    var createdAt: SpacetimeTimestamp
    var barsPerLine: UInt32  // 2 = a speaking bar then a rest bar; 1 = no rests

    var phaseValue: RoomPhase? { RoomPhase(rawValue: phase) }
    /// One bar is four beats.
    var barSeconds: Double { 4 * 60 / Double(max(bpm, 1)) }
}

struct PlayerRow: Codable, Sendable, Identifiable, Equatable {
    var id: UInt64
    var roomId: UInt64
    var identity: Identity
    var name: String
    var epithet: String
    var named: Bool
    var entered: Bool
    var hoard: [String]
    var seat: UInt32
    var total: UInt32
    var connected: Bool
    var joinedAt: SpacetimeTimestamp
}

struct RoundRow: Codable, Sendable, Identifiable, Equatable {
    var id: UInt64
    var roomId: UInt64
    var roundNo: UInt32
    var theme: String
    var verdict: String
    var bestTurnId: UInt64
    var bestLine: String
    var dealtAt: SpacetimeTimestamp
}

struct HandRow: Codable, Sendable, Equatable {
    var playerId: UInt64
    var roomId: UInt64
    var kind: String  // "formula", later "move"
    var cards: [String]
}

struct TurnRow: Codable, Sendable, Identifiable, Equatable {
    var id: UInt64
    var roomId: UInt64
    var roundId: UInt64
    var playerId: UInt64
    var turnNo: UInt32
    var status: String
    var attempt: UInt32
    var transcript: String
    var played: [String]
    var rescue: String
    var rescues: UInt32
    var startedAt: SpacetimeTimestamp
    var beatAt: SpacetimeTimestamp
    var endsAt: SpacetimeTimestamp

    var statusValue: TurnStatus? { TurnStatus(rawValue: status) }
}

struct ScoreRow: Codable, Sendable, Equatable {
    var turnId: UInt64
    var roomId: UInt64
    var roundId: UInt64
    var playerId: UInt64
    var axes: [UInt8]  // ordered by the event's rubric
    var total: UInt32
    var verdict: String
    var bestLine: String
    var coined: String

    /// Poetry's rubric order is [beat, craft, image, answer, range]; nil for other events.
    var poetryScorecard: Scorecard? {
        guard axes.count == Axis.allCases.count else { return nil }
        let a = axes.map(Int.init)
        return Scorecard(scores: Scores(beat: a[0], craft: a[1], image: a[2], answer: a[3], range: a[4]), verdict: verdict, bestLine: bestLine, total: Int(total))
    }
}

struct SceneRow: Codable, Sendable, Equatable {
    var roomId: UInt64
    var turnId: UInt64
    var playerId: UInt64
    var anger: Float
    var grief: Float
    var joy: Float
    var awe: Float
    var tenderness: Float
    var fear: Float
    var defiance: Float
    var longing: Float
    var updatedAt: SpacetimeTimestamp

    var weights: EmotionWeights {
        EmotionWeights([
            .anger: Double(anger), .grief: Double(grief), .joy: Double(joy), .awe: Double(awe),
            .tenderness: Double(tenderness), .fear: Double(fear), .defiance: Double(defiance), .longing: Double(longing),
        ])
    }
}

struct ColorSampleRow: Codable, Sendable, Identifiable, Equatable {
    var id: UInt64
    var roomId: UInt64
    var turnId: UInt64
    var ms: UInt32
    var anger: Float
    var grief: Float
    var joy: Float
    var awe: Float
    var tenderness: Float
    var fear: Float
    var defiance: Float
    var longing: Float
}

struct ProsodyRow: Codable, Sendable, Equatable {
    var roomId: UInt64
    var turnId: UInt64
    var playerId: UInt64
    var loudness: Float
    var pitch: Float
    var hits: UInt32

    var prosody: Prosody { Prosody(energy: Double(loudness), pitch: pitch > 0 ? Double(pitch) : nil) }
}

struct ReactionRow: Codable, Sendable, Identifiable, Equatable {
    var id: UInt64
    var roomId: UInt64
    var kind: String
    var at: SpacetimeTimestamp
}

struct SongLineRow: Codable, Sendable, Identifiable, Equatable {
    var id: UInt64
    var roomId: UInt64
    var lineNo: UInt32
    var turnId: UInt64
    var text: String
}

/// Typed caches for every public table. Registered once per process; the SDK's cache is global.
@MainActor
enum BattleTables {
    static let room: TableCache<RoomRow> = register("room")
    static let player: TableCache<PlayerRow> = register("player")
    static let round: TableCache<RoundRow> = register("round")
    static let hand: TableCache<HandRow> = register("hand")
    static let turn: TableCache<TurnRow> = register("turn")
    static let score: TableCache<ScoreRow> = register("score")
    static let scene: TableCache<SceneRow> = register("scene")
    static let colorSample: TableCache<ColorSampleRow> = register("color_sample")
    static let prosody: TableCache<ProsodyRow> = register("prosody")
    static let reaction: TableCache<ReactionRow> = register("reaction")
    static let songLine: TableCache<SongLineRow> = register("song_line")

    static func registerAll() {
        _ = (room, player, round, hand, turn, score, scene, colorSample, prosody, reaction, songLine)
    }

    private static func register<T: Codable & Sendable>(_ name: String) -> TableCache<T> {
        SpacetimeClient.clientCache.registerTable(tableName: name, rowType: T.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: name)
    }
}
