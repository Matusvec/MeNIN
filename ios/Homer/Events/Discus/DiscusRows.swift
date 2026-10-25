// Hand-written bindings for discus (spacetime/CONTRACT.md, "Discus").
// BSATN is positional: stored properties must stay in column order.

import Foundation
import SpacetimeDB

struct DiscusThrowRow: Codable, Sendable, Identifiable, Equatable {
    var id: UInt64
    var roomId: UInt64
    var turnId: UInt64
    var playerId: UInt64
    var throwNo: UInt32
    var speed: Float  // rad/s
    var angle: Float  // degrees
    var timing: Float  // 0...1
    var distance: Float  // metres, 0 for a foul
    var foul: Bool
    var at: SpacetimeTimestamp
    // Appended columns (throw_discus_full); 0 / "" for throws from older phones.
    var releaseSpeed: Float  // m/s
    var roll: Float  // degrees off flat
    var spin: Float  // rad/s
    var foulReason: String  // "" | "late" | "sector"
}

@MainActor
enum DiscusTables {
    static let discusThrow: TableCache<DiscusThrowRow> = {
        SpacetimeClient.clientCache.registerTable(tableName: "discus_throw", rowType: DiscusThrowRow.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: "discus_throw")
    }()

    /// Call once before subscribing (BattleClient.init does), like BattleTables.registerAll().
    static func registerAll() { _ = discusThrow }
}

extension Reducer {
    /// The throw with its release in detail (new phones); the server keeps throw_discus for old ones.
    struct ThrowDiscusFull: Codable, Sendable {
        static let name = "throw_discus_full"
        var turnId: UInt64
        var speed: Float
        var angle: Float
        var timing: Float
        var distance: Float
        var foul: Bool
        var releaseSpeed: Float
        var roll: Float
        var spin: Float
        var foulReason: String
    }

    struct ThrowDiscus: Codable, Sendable {
        static let name = "throw_discus"
        var turnId: UInt64
        var speed: Float
        var angle: Float
        var timing: Float
        var distance: Float
        var foul: Bool
    }
}

extension BattleClient {
    var discusThrows: [DiscusThrowRow] { DiscusTables.discusThrow.rows.filter { $0.roomId == roomId } }

    func discusThrow(for turnId: UInt64) -> DiscusThrowRow? { discusThrows.first { $0.turnId == turnId } }

    /// Once per throw, when the thumb lifts. The server refuses it unless this phone is the
    /// thrower and the turn is live.
    func throwDiscus(_ turnId: UInt64, _ t: DiscusThrow) {
        call(Reducer.ThrowDiscusFull.name, Reducer.ThrowDiscusFull(
            turnId: turnId, speed: Float(t.speed), angle: Float(t.angle), timing: Float(t.timing),
            distance: Float(t.distance), foul: t.foul, releaseSpeed: Float(t.releaseSpeed),
            roll: Float(max(-180, min(180, t.roll))), spin: Float(max(0, min(60, t.spin))), foulReason: t.foulReason))
    }
}
