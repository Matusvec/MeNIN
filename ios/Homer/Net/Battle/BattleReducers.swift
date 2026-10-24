// Reducer calls for the `homer` module. Arguments are positional, in contract order;
// a Codable struct encodes to BSATN as its fields in declaration order.

import Foundation

enum Reducer {
    // Arena
    struct CreateRoom: Codable, Sendable {
        static let name = "create_room"
        var event: String
        var rounds: UInt32
        var turnSeconds: UInt32
        var linesPerTurn: UInt32
        var bpm: UInt32
        var form: String
        var autoReady: Bool
        var themeChoice: Bool
        var demo: Bool

        static let standard = CreateRoom(event: "poetry", rounds: 3, turnSeconds: 30, linesPerTurn: 4, bpm: 80, form: "four_beat", autoReady: false, themeChoice: false, demo: false)
        static let demoMode = CreateRoom(event: "poetry", rounds: 1, turnSeconds: 30, linesPerTurn: 2, bpm: 80, form: "four_beat", autoReady: true, themeChoice: false, demo: true)
    }

    struct RoomId: Codable, Sendable { var roomId: UInt64 }
    struct TurnId: Codable, Sendable { var turnId: UInt64 }
    struct ChooseTheme: Codable, Sendable { var roomId: UInt64; var theme: String }

    // Phone
    struct JoinRoom: Codable, Sendable {
        static let name = "join_room"
        var code: String
        var name: String
        var epithet: String
        var hoard: [String]
    }

    struct TurnText: Codable, Sendable { var turnId: UInt64; var text: String }

    struct SetProsody: Codable, Sendable {
        static let name = "set_prosody"
        var roomId: UInt64
        var loudness: Float
        var pitch: Float
        var hits: UInt32
    }

    struct React: Codable, Sendable { var roomId: UInt64; var kind: String }
}
