import Foundation
import Observation
import SpacetimeDB

/// One device's view of a battle: the SpacetimeDB connection, the subscription for
/// one room, derived state, and typed reducer calls. Views read it and call methods;
/// all battle state lives in SpacetimeDB, so nothing here is authoritative.
@Observable
@MainActor
final class BattleClient: SpacetimeClientDelegate {
    enum Role: String { case arena, player }
    enum Connection: Equatable { case idle, connecting, connected, disconnected }

    let role: Role
    private(set) var connection: Connection = .idle
    private(set) var identity: Identity?
    private(set) var roomId: UInt64 = 0
    /// The last reducer refusal, e.g. "no such room". Cleared by the next call.
    private(set) var lastError: String?

    @ObservationIgnored private var client: SpacetimeClient?
    @ObservationIgnored private var roomSubscription: SubscriptionHandle?
    @ObservationIgnored private var lookupSubscription: SubscriptionHandle?
    @ObservationIgnored private let tokens: KeychainTokenStore
    @ObservationIgnored private var database = ""
    @ObservationIgnored private var transcriptFlush: Task<Void, Never>?
    @ObservationIgnored private var awaitingCreatedRoom = false

    init(role: Role) {
        self.role = role
        tokens = KeychainTokenStore(service: "com.matusvec.homer.spacetimedb.\(role.rawValue)")
        BattleTables.registerAll()
    }

    // MARK: connection

    /// Tokens are kept per database, so local and Maincloud identities don't collide.
    func connect(to server: URL, database: String) {
        guard client == nil else { return }
        self.database = database
        let c = SpacetimeClient(serverUrl: server, moduleName: database)
        c.delegate = self
        client = c
        connection = .connecting
        c.connect(token: tokens.load(forModule: database))
        if role == .arena { startArenaTicker() }
    }

    func disconnect() {
        transcriptFlush?.cancel()
        arenaTicker?.cancel()
        client?.disconnect()
        client = nil
        connection = .idle
    }

    func onConnect() { connection = .connected }
    func onDisconnect(error: Error?) { connection = .disconnected }
    func onConnectError(error: Error) { connection = .disconnected }

    func onIdentityReceived(identity bytes: [UInt8], token: String) {
        identity = Identity(rawBytes: Data(bytes))
        _ = tokens.save(token: token, forModule: database)
        if role == .arena, let identity {
            // Rooms are found by host because reducers can't return values.
            lookup(["SELECT * FROM room WHERE host = 0x\(identity.hex)"])
        }
    }

    func onTransactionUpdate(message: Data?) {
        if awaitingCreatedRoom, let newest = latestHostedRoom, newest.id > roomId {
            awaitingCreatedRoom = false
            watchRoom(newest.id)
        }
    }

    // MARK: arena duties

    @ObservationIgnored private var arenaTicker: Task<Void, Never>?
    @ObservationIgnored private var autoStarted: String?
    @ObservationIgnored private var agentAsked = Set<String>()
    /// Set when the agent service is configured; nil leaves dealing and judging to whatever
    /// else serves the database (multiplayer's dev-agent, behind its own dev flag).
    @ObservationIgnored var agent: AgentClient?
    private(set) var agentError: String?

    /// Polls rather than reacting to transaction callbacks, which can fire before `rows` sync.
    private func startArenaTicker() {
        arenaTicker?.cancel()
        arenaTicker = Task { [weak self] in
            while !Task.isCancelled {
                self?.autoStartIfNeeded()
                self?.askAgentIfNeeded()
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    /// The arena asks the agent for battle work when the phase calls for it, once per step.
    /// Results come back through the subscription; every call is safe to retry.
    private func askAgentIfNeeded() {
        guard let agent, let room else { return }
        func once(_ key: String, _ work: @escaping @Sendable () async throws -> Void) {
            guard !agentAsked.contains(key) else { return }
            agentAsked.insert(key)
            Task {
                do {
                    try await work()
                } catch {
                    agentError = error.localizedDescription
                    try? await Task.sleep(for: .seconds(2))
                    agentAsked.remove(key)  // then retry
                }
            }
        }
        switch room.phaseValue {
        case .dealing:
            let req = BattleDealRequest(roomId: room.id, roundNo: room.roundNo, theme: room.nextTheme)
            once("deal \(room.id) \(room.roundNo)") { try await agent.battleDeal(req) }
        case .roundEnd where room.roundNo < room.rounds && !room.themeChoice:
            // Deal the next round ahead so the next turn is ready the moment the verdict ends.
            let req = BattleDealRequest(roomId: room.id, roundNo: room.roundNo + 1, theme: "")
            once("deal \(room.id) \(room.roundNo + 1)") { try await agent.battleDeal(req) }
        case .judging:
            guard let turn = currentTurn, turn.statusValue == .judging, let poet = player(turn.playerId) else { return }
            let previous = turns.filter { $0.roundId == turn.roundId && $0.turnNo + 1 == turn.turnNo }.first?.transcript ?? ""
            let req = BattleJudgeRequest(
                turnId: turn.id, playerId: poet.id, transcript: turn.transcript, event: room.event, form: room.form,
                theme: currentRound?.theme ?? "", played: turn.played, rescues: turn.rescues, previous: previous,
                linesExpected: room.linesPerTurn, hoard: poet.hoard, demo: room.demo
            )
            once("judge \(turn.id) \(turn.attempt)") { try await agent.battleJudge(req) }
        default:
            break
        }
    }

    /// auto_ready rooms (always on in demo): the arena starts each turn after a short step-up beat.
    private func autoStartIfNeeded() {
        guard let room, room.autoReady, room.phaseValue == .ready,
              let turn = currentTurn, turn.statusValue == .waiting else { return }
        let key = "\(turn.id)-\(turn.attempt)"
        guard autoStarted != key else { return }
        autoStarted = key
        Task {
            try? await Task.sleep(for: .seconds(2))
            if currentTurn?.id == turn.id, currentTurn?.statusValue == .waiting { startTurn(turn.id) }
        }
    }

    func onReducerError(reducer: String, message: String, isInternal: Bool) {
        lastError = message
    }

    // MARK: subscriptions

    private func lookup(_ queries: [String]) {
        lookupSubscription?.unsubscribe(sendDroppedRows: true)
        lookupSubscription = client?.subscribe(queries: queries)
    }

    /// Subscribes to everything this device needs for one room, replacing the previous room.
    func watchRoom(_ id: UInt64) {
        guard id != roomId || roomSubscription == nil else { return }
        roomSubscription?.unsubscribe(sendDroppedRows: true)
        roomId = id
        var queries = ["room WHERE id = \(id)"] + ["player", "round", "hand", "turn", "score", "scene", "song_line"].map { "\($0) WHERE room_id = \(id)" }
        if role == .arena {
            queries += ["prosody", "reaction", "color_sample"].map { "\($0) WHERE room_id = \(id)" }
        }
        roomSubscription = client?.subscribe(queries: queries.map { "SELECT * FROM \($0)" })
    }

    // MARK: derived state

    var room: RoomRow? { BattleTables.room.rows.first { $0.id == roomId && roomId != 0 } }
    var phase: RoomPhase? { room?.phaseValue }
    var players: [PlayerRow] { BattleTables.player.rows.filter { $0.roomId == roomId }.sorted { $0.seat < $1.seat } }
    var me: PlayerRow? { players.first { $0.identity == identity } }
    var currentRound: RoundRow? {
        guard let room else { return nil }
        return BattleTables.round.rows.first { $0.roomId == roomId && $0.roundNo == room.roundNo }
    }
    var turns: [TurnRow] { BattleTables.turn.rows.filter { $0.roomId == roomId } }
    var currentTurn: TurnRow? {
        guard let id = room?.currentTurnId, id != 0 else { return nil }
        return turns.first { $0.id == id }
    }
    var isMyTurn: Bool { currentTurn != nil && currentTurn?.playerId == me?.id }
    var myHand: [String] {
        guard let me else { return [] }
        return BattleTables.hand.rows.first { $0.playerId == me.id }?.cards ?? []
    }
    func score(for turnId: UInt64) -> ScoreRow? { BattleTables.score.rows.first { $0.turnId == turnId } }
    func player(_ id: UInt64) -> PlayerRow? { players.first { $0.id == id } }
    var scene: SceneRow? { BattleTables.scene.rows.first { $0.roomId == roomId } }
    var prosody: ProsodyRow? { BattleTables.prosody.rows.first { $0.roomId == roomId } }
    var songLines: [SongLineRow] { BattleTables.songLine.rows.filter { $0.roomId == roomId }.sorted { $0.lineNo < $1.lineNo } }

    /// Arena: the newest room this identity hosts that isn't finished.
    var latestHostedRoom: RoomRow? {
        guard let identity else { return nil }
        return BattleTables.room.rows.filter { $0.host == identity && $0.phase != RoomPhase.finished.rawValue }.max { $0.id < $1.id }
    }

    // MARK: reducers

    private func call<A: Encodable>(_ reducer: String, _ args: A) {
        guard let client else {
            lastError = "Not connected"
            return
        }
        do {
            lastError = nil
            client.send(reducer, try BSATNEncoder().encode(args))
        } catch {
            lastError = "Couldn't encode \(reducer): \(error)"
        }
    }

    // Arena

    func createRoom(_ config: Reducer.CreateRoom) {
        awaitingCreatedRoom = true
        call(Reducer.CreateRoom.name, config)
    }

    func startBattle() { call("start_battle", Reducer.RoomId(roomId: roomId)) }
    func chooseTheme(_ theme: String) { call("choose_theme", Reducer.ChooseTheme(roomId: roomId, theme: theme)) }
    func advance() { call("advance", Reducer.RoomId(roomId: roomId)) }
    func skipTurn(_ turnId: UInt64) { call("skip_turn", Reducer.TurnId(turnId: turnId)) }
    func rematch() { call("rematch", Reducer.RoomId(roomId: roomId)) }

    // Both

    func startTurn(_ turnId: UInt64) { call("start_turn", Reducer.TurnId(turnId: turnId)) }

    // Phone

    /// Joins by code. Calling it again from the same identity is a reconnect.
    func join(code: String, name: String, epithet: String = "", hoard: [String] = []) {
        let code = code.uppercased().filter { $0.isLetter && $0.isASCII }
        guard code.count == 4 else {
            lastError = "Room codes are 4 letters"
            return
        }
        lookup(["SELECT * FROM room WHERE code = '\(code)'"])
        call(Reducer.JoinRoom.name, Reducer.JoinRoom(code: code, name: name, epithet: epithet, hoard: hoard))
        watchRoomWhenFound(code: code)
    }

    private func watchRoomWhenFound(code: String) {
        Task {
            for _ in 0..<50 {
                if let room = BattleTables.room.rows.first(where: { $0.code == code && $0.phase != RoomPhase.finished.rawValue }) {
                    watchRoom(room.id)
                    return
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    func leave() { call("leave_room", Reducer.RoomId(roomId: roomId)) }
    func enter() { call("enter", Reducer.RoomId(roomId: roomId)) }
    func playCard(_ turnId: UInt64, card: String) { call("play_card", Reducer.TurnText(turnId: turnId, text: card)) }
    func rescue(_ turnId: UInt64, card: String) { call("rescue", Reducer.TurnText(turnId: turnId, text: card)) }
    func react(_ kind: String) { call("react", Reducer.React(roomId: roomId, kind: kind)) }

    /// Live transcript, coalesced to at most about 4 writes a second.
    func updateTranscript(_ turnId: UInt64, _ text: String) {
        transcriptFlush?.cancel()
        transcriptFlush = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            call("update_transcript", Reducer.TurnText(turnId: turnId, text: text))
        }
    }

    func endTurn(_ turnId: UInt64, _ text: String) {
        transcriptFlush?.cancel()
        call("end_turn", Reducer.TurnText(turnId: turnId, text: text))
    }

    func setProsody(loudness: Float, pitch: Float, hits: UInt32) {
        call(Reducer.SetProsody.name, Reducer.SetProsody(roomId: roomId, loudness: loudness, pitch: pitch, hits: hits))
    }
}
