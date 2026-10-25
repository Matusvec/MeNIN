import Foundation
import SpacetimeDB

/// Pygmachia (boxing) rows, multiplayer's module (Sat 5:15). Codable in column order.
struct FightRow: Codable, Sendable, Equatable {
    var roomId: UInt64
    var goAt: SpacetimeTimestamp  // the bell: calibrate the guard pose, start streaming
    var endsAt: SpacetimeTimestamp  // go_at + 60 s
    var endedAt: SpacetimeTimestamp  // the epoch while live
    var winnerId: UInt64  // 0 = draw or not over
    var ko: Bool
}

struct FighterRow: Codable, Sendable, Equatable {
    var playerId: UInt64
    var roomId: UInt64
    var seat: UInt32
    var health: Float  // 100 -> 0
    var guard_: Bool
    var aimYaw: Float
    var aimPitch: Float
    var counterUntil: SpacetimeTimestamp
    var updatedAt: SpacetimeTimestamp

    enum CodingKeys: String, CodingKey {
        case playerId, roomId, seat, health, guard_ = "guard", aimYaw, aimPitch, counterUntil, updatedAt
    }
}

struct PunchRow: Codable, Sendable, Equatable, Identifiable {
    var id: UInt64
    var roomId: UInt64
    var playerId: UInt64
    var targetId: UInt64
    var zone: String
    var power: Float
    var aimYaw: Float
    var aimPitch: Float
    var result: String  // landed | blocked | missed
    var damage: Float
    var counter: Bool
    var at: SpacetimeTimestamp
    var t: Float
    var kind: String
}

@MainActor
enum BoxingTables {
    static let fight: TableCache<FightRow> = {
        SpacetimeClient.clientCache.registerTable(tableName: "fight", rowType: FightRow.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: "fight")
    }()
    static let fighter: TableCache<FighterRow> = {
        SpacetimeClient.clientCache.registerTable(tableName: "fighter", rowType: FighterRow.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: "fighter")
    }()
    static let punch: TableCache<PunchRow> = {
        SpacetimeClient.clientCache.registerTable(tableName: "punch", rowType: PunchRow.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: "punch")
    }()

    static func registerAll() { _ = (fight, fighter, punch) }
}

extension Reducer {
    /// ~20 Hz during the bout: the fist's aim (relative to the guard pose at the bell) and guard.
    struct SetFistAim: Codable, Sendable {
        static let name = "set_fist_aim"
        var roomId: UInt64
        var yaw: Float
        var pitch: Float
        var guard_: Bool
        enum CodingKeys: String, CodingKey { case roomId, yaw, pitch, guard_ = "guard" }
    }

    /// One per detected punch; the module resolves landed/blocked/missed and damage.
    struct ThrowPunch: Codable, Sendable {
        static let name = "throw_punch"
        var roomId: UInt64
        var kind: String
        var power: Float
        var aimYaw: Float
        var aimPitch: Float
    }
}
