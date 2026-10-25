import Foundation
import SpacetimeDB

/// Toxeia (archery) rows, multiplayer's module (Sat ~6 PM). Codable in column order.
struct RangeRow: Codable, Sendable, Equatable {
    var roomId: UInt64
    var bowId: UInt64  // the player (phone) holding the bow
    var arrowId: UInt64  // the player (phone) holding the arrow
    var archerId: UInt64  // the archer up; 0 = waiting for a name
    var arrowNo: UInt32  // 1...3
    var wind: Float  // m/s crosswind, + blows right as the archer faces the target
    var aimYaw: Float
    var aimPitch: Float
    var draw: Float
    var openedAt: SpacetimeTimestamp
    var endsAt: SpacetimeTimestamp  // the arrow's window
    var updatedAt: SpacetimeTimestamp
    /// Camera archery (SPEC 2256b58): the website's webcam aims and draws, the archer's own phone
    /// looses. Appended last; a row from before it has no such column.
    var camera = false

    enum CodingKeys: String, CodingKey {
        case roomId, bowId, arrowId, archerId, arrowNo, wind, aimYaw, aimPitch, draw, openedAt, endsAt, updatedAt, camera
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        roomId = try c.decode(UInt64.self, forKey: .roomId)
        bowId = try c.decode(UInt64.self, forKey: .bowId)
        arrowId = try c.decode(UInt64.self, forKey: .arrowId)
        archerId = try c.decode(UInt64.self, forKey: .archerId)
        arrowNo = try c.decode(UInt32.self, forKey: .arrowNo)
        wind = try c.decode(Float.self, forKey: .wind)
        aimYaw = try c.decode(Float.self, forKey: .aimYaw)
        aimPitch = try c.decode(Float.self, forKey: .aimPitch)
        draw = try c.decode(Float.self, forKey: .draw)
        openedAt = try c.decode(SpacetimeTimestamp.self, forKey: .openedAt)
        endsAt = try c.decode(SpacetimeTimestamp.self, forKey: .endsAt)
        updatedAt = try c.decode(SpacetimeTimestamp.self, forKey: .updatedAt)
        // BSATN rows are positional: a row from before the camera simply ends here.
        camera = (try? c.decode(Bool.self, forKey: .camera)) ?? false
    }
}

struct ArcherRow: Codable, Sendable, Equatable, Identifiable {
    var id: UInt64
    var roomId: UInt64
    var name: String
    var total: UInt32
    var arrows: UInt32
    var at: SpacetimeTimestamp
}

struct ArrowShotRow: Codable, Sendable, Equatable, Identifiable {
    var id: UInt64
    var roomId: UInt64
    var archerId: UInt64
    var arrowNo: UInt32
    var aimYaw: Float
    var aimPitch: Float
    var draw: Float
    var wind: Float
    var x: Float  // m on the target face, + right
    var y: Float  // m, + up
    var ring: UInt32  // 10 = gold ... 1, 0 = miss
    var flight: Float  // s
    var at: SpacetimeTimestamp
}

@MainActor
enum ToxeiaTables {
    static let range: TableCache<RangeRow> = {
        SpacetimeClient.clientCache.registerTable(tableName: "range", rowType: RangeRow.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: "range")
    }()
    static let archer: TableCache<ArcherRow> = {
        SpacetimeClient.clientCache.registerTable(tableName: "archer", rowType: ArcherRow.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: "archer")
    }()
    static let arrowShot: TableCache<ArrowShotRow> = {
        SpacetimeClient.clientCache.registerTable(tableName: "arrow_shot", rowType: ArrowShotRow.self)
        return SpacetimeClient.clientCache.getTableCache(tableName: "arrow_shot")
    }()

    static func registerAll() { _ = (range, archer, arrowShot) }
}

extension Reducer {
    struct ClaimStation: Codable, Sendable {
        static let name = "claim_station"
        var roomId: UInt64
        var role: String  // "bow" | "arrow" | "" (whatever's free)
    }

    struct NextArcher: Codable, Sendable {
        static let name = "next_archer"
        var roomId: UInt64
        var name: String
    }

    struct SetBowAim: Codable, Sendable {
        static let name = "set_bow_aim"
        var roomId: UInt64
        var yaw: Float
        var pitch: Float
    }

    struct SetDraw: Codable, Sendable {
        static let name = "set_draw"
        var roomId: UInt64
        var draw: Float
    }

    struct Loose: Codable, Sendable {
        static let name = "loose"
        var roomId: UInt64
        var draw: Float
    }
}
