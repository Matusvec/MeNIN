import Foundation
import SpacetimeDB

/// The Stadion's rows (spacetime module, multiplayer's contract, Sat 4:40). Codable in column order.
struct HeatRow: Codable, Sendable, Equatable {
    var roomId: UInt64
    var heatNo: UInt32
    var goAt: SpacetimeTimestamp
    var capAt: SpacetimeTimestamp
    var endedAt: SpacetimeTimestamp  // the epoch while running
}

struct RunnerRow: Codable, Sendable, Equatable {
    var playerId: UInt64
    var roomId: UInt64
    var heatNo: UInt32
    var speed: Float  // m/s
    var distance: Float  // m
    var place: UInt32  // 0 = still running
    var time: Float  // s from go_at; 0 = not finished
    var updatedAt: SpacetimeTimestamp
}

@MainActor
enum StadionTables {
    static let heat: TableCache<HeatRow> = {
        SpacetimeClient.clientCache.registerTable(tableName: "heat", rowType: HeatRow.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: "heat")
    }()
    static let runner: TableCache<RunnerRow> = {
        SpacetimeClient.clientCache.registerTable(tableName: "runner", rowType: RunnerRow.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: "runner")
    }()

    static func registerAll() { _ = (heat, runner) }
}

extension Reducer {
    /// The phone's own integrated run, ~10 Hz after go_at. The server ignores it before go_at, after
    /// you've finished or outside `speaking`; distance never goes down and is clamped to 25 m/s × elapsed.
    struct SetStride: Codable, Sendable {
        static let name = "set_stride"
        var roomId: UInt64
        var speed: Float
        var distance: Float
    }
}
