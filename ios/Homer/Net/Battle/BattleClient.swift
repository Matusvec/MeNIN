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
    @ObservationIgnored private var pendingTranscript: (turnId: UInt64, text: String)?
    @ObservationIgnored private var lastTranscriptSent = Date.distantPast
    @ObservationIgnored private var awaitingCreatedRoom = false

    init(role: Role) {
        self.role = role
        tokens = KeychainTokenStore(service: "com.matusvec.homer.spacetimedb.\(role.rawValue)")
        BattleTables.registerAll()
        DiscusTables.registerAll()  // Events/Discus (multiplayer)
        StadionTables.registerAll()
        BoxingTables.registerAll()
        ToxeiaTables.registerAll()
    }

    // MARK: connection

    /// Tokens are kept per database, so local and Maincloud identities don't collide.
    func connect(to server: URL, database: String) {
        guard client == nil else { return }
        self.database = database
        // Venue Wi-Fi drops are the common failure: retry fast (0.5 s, capped at 3 s) so a phone is
        // back within ~3 s of the network, with jitter so four phones don't retry in lockstep.
        let c = SpacetimeClient(serverUrl: server, moduleName: database,
                                reconnectPolicy: ReconnectPolicy(initialDelaySeconds: 0.5, maxDelaySeconds: 3, jitterRatio: 0.3))
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
        // The table cache is app-wide: leaving must not hand the next room this one's rows.
        SpacetimeClient.clientCache.clear()
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
        // Only a room made since the create call: the host lookup can deliver an older open room first,
        // and an arena that grabbed it would sit in someone's stale battle.
        if awaitingCreatedRoom, let newest = latestHostedRoom, newest.id > roomId,
           newest.createdAt.epochMs >= createRequestedMs - 10_000 {
            awaitingCreatedRoom = false
            watchRoom(newest.id)
        }
    }

    // MARK: arena duties

    @ObservationIgnored private var arenaTicker: Task<Void, Never>?
    @ObservationIgnored private var autoStarted: String?
    @ObservationIgnored private var agentAsked = Set<String>()
    @ObservationIgnored private var createRequestedMs = 0.0
    /// Bumped each time this room starts over (Rematch, a new event, or a finished battle
    /// restarting from elsewhere), so per-round work like dealing and the song is asked again.
    @ObservationIgnored private(set) var generation = 0
    /// Homer's step-up call per theme ("The sea is yours."), from the deal or the theme cards.
    @ObservationIgnored var calls: [String: String] = [:]
    /// Set while the arena's host is calling the next poet up: auto-ready waits for the line to end.
    @ObservationIgnored var holdStart = false
    @ObservationIgnored private var lastPhaseSeen: RoomPhase?
    /// Set when the agent service is configured; nil leaves dealing and judging to whatever
    /// else serves the database (multiplayer's dev-agent, behind its own dev flag).
    @ObservationIgnored var agent: AgentClient?
    private(set) var agentError: String?

    /// Polls rather than reacting to transaction callbacks, which can fire before `rows` sync.
    private func startArenaTicker() {
        arenaTicker?.cancel()
        arenaTicker = Task { [weak self] in
            while !Task.isCancelled {
                self?.trackGeneration()
                self?.autoStartIfNeeded()
                self?.askAgentIfNeeded()
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    private func trackGeneration() {
        let phase = room?.phaseValue
        if lastPhaseSeen == .finished, let phase, phase != .finished { generation += 1 }
        lastPhaseSeen = phase
    }

    /// The arena asks the agent for battle work when the phase calls for it, once per step.
    /// Results come back through the subscription; every call is safe to retry.
    private func askAgentIfNeeded() {
        guard let agent, let room, room.event != "discus" else { return }  // discus has no Claude
        /// Fire and forget, for calls whose failure only means "try again next tick".
        func quietly(_ key: String, _ work: @escaping @Sendable () async throws -> Void) {
            guard !agentAsked.contains(key) else { return }
            agentAsked.insert(key)
            Task { try? await work() }
        }
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
        // Names and epithets for anyone the agent hasn't approved yet, in any phase.
        for poet in players where !poet.named {
            once("poet \(poet.id)") { try await agent.battlePoet(.init(playerId: poet.id)) }
        }
        switch room.phaseValue {
        case .speaking:
            // The scene's color layer: about every 1.5 s while a verse is live.
            guard let turn = currentTurn, !turn.transcript.isEmpty else { return }
            let tick = Int(Date().timeIntervalSince1970 * 1000 / 1500)
            let p = prosody.map { $0.turnId == turn.id ? $0 : nil } ?? nil
            let req = BattleEmotionRequest(turnId: turn.id, transcript: turn.transcript,
                                           loudness: p.map { Double($0.loudness) }, pitch: p.flatMap { $0.pitch > 0 ? Double($0.pitch) : nil })
            quietly("emotion \(turn.id) \(tick)") { try await agent.battleEmotion(req) }
        case .dealing:
            let req = BattleDealRequest(roomId: room.id, roundNo: room.roundNo, theme: room.nextTheme)
            once("deal \(room.id).\(generation) \(room.roundNo)") { [weak self] in
                let dealt = try await agent.battleDeal(req)
                await self?.remember(call: dealt)
            }
        case .scored:
            // The round's last turn is scored: ask for the round verdict now, so it's ready when the
            // reveal reaches round end. Quietly; the round-end ask below is the guaranteed one.
            if let round = currentRound {
                let inRound = turns.filter { $0.roundId == round.id }
                let open = inRound.contains { $0.statusValue == .waiting || $0.statusValue == .speaking || $0.statusValue == .judging }
                if !inRound.isEmpty, !open {
                    quietly("verdict-early \(round.id)") { try await agent.battleVerdict(.init(roundId: round.id)) }
                }
            }
        case .roundEnd:
            if let round = currentRound {
                once("verdict \(round.id)") { try await agent.battleVerdict(.init(roundId: round.id)) }
            }
            // The song: pre-stitched after round 1, final after the last round.
            if room.roundNo == 1 || room.roundNo == room.rounds {
                once("song \(room.id).\(generation) \(room.roundNo)") { try await agent.battleSong(.init(roomId: room.id)) }
            }
            // Deal the next round ahead so the next turn is ready the moment the verdict ends.
            if room.roundNo < room.rounds && !room.themeChoice {
                let req = BattleDealRequest(roomId: room.id, roundNo: room.roundNo + 1, theme: "")
                once("deal \(room.id).\(generation) \(room.roundNo + 1)") { [weak self] in
                    let dealt = try await agent.battleDeal(req)
                    await self?.remember(call: dealt)
                }
            }
        case .judging:
            guard let turn = currentTurn, turn.statusValue == .judging, let poet = player(turn.playerId) else { return }
            let previous = turns.filter { $0.roundId == turn.roundId && $0.turnNo + 1 == turn.turnNo }.first?.transcript ?? ""
            var req = BattleJudgeRequest(
                turnId: turn.id, playerId: poet.id, transcript: turn.transcript, event: room.event, form: room.form,
                theme: currentRound?.theme ?? "", played: turn.played, rescues: turn.rescues, previous: previous,
                linesExpected: room.linesPerTurn, hoard: poet.hoard, demo: room.demo
            )
            if room.event == "debate" {
                DebateContent.shared.load(agent)
                req.side = DebateContent.shared.side(for: currentRound?.theme ?? "", turnNo: turn.turnNo)
                req.turnSeconds = Double(room.turnSeconds)
                // Go (beat_at) to now, the moment the turn reached judging, capped at the turn.
                let spoken = (Date().timeIntervalSince1970 * 1000 - turn.beatAt.epochMs) / 1000
                req.spokenSeconds = min(Double(room.turnSeconds), max(0, spoken))
            }
            once("judge \(turn.id) \(turn.attempt)") { try await agent.battleJudge(req) }
        default:
            break
        }
    }

    private func remember(call dealt: BattleDealResult) {
        guard let theme = dealt.theme, let call = dealt.call, !call.isEmpty else { return }
        calls[theme] = call
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
            // A poet reopening the app gets up to 20 s to come back (capped: a stale
            // `connected = false` from an old socket can't stall the battle).
            for _ in 0..<40 where player(turn.playerId)?.connected == false {
                try? await Task.sleep(for: .milliseconds(500))
            }
            // Homer calls the poet up first (rules, topic, name); the count-in never starts over him.
            // Capped at 30 s in case his voice hangs.
            for _ in 0..<60 where holdStart {
                try? await Task.sleep(for: .milliseconds(500))
            }
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
    @ObservationIgnored private var eventSubscription: SubscriptionHandle?

    /// The live-sport tables, in their own subscription and only inside that event's room, so a
    /// battle room (or a server without these tables) never subscribes to them.
    func watchEventTables(_ event: String) {
        let tables: [String] = event == "stadion" ? ["heat", "runner"]
            : event == "pygmachia" ? ["fight", "fighter", "punch"]
            : event == "toxeia" ? ["range", "archer", "arrow_shot"] : []
        // A hall switching events (set_event) drops the last sport's tables before taking the next.
        eventSubscription?.unsubscribe(sendDroppedRows: true)
        eventSubscription = nil
        guard !tables.isEmpty, roomId != 0 else { return }
        eventSubscription = client?.subscribe(queries: tables.map { "SELECT * FROM \($0) WHERE room_id = \(roomId)" })
    }

    func watchRoom(_ id: UInt64) {
        guard id != roomId || roomSubscription == nil else { return }
        roomSubscription?.unsubscribe(sendDroppedRows: true)
        roomId = id
        var queries = ["room WHERE id = \(id)"] + ["player", "round", "hand", "turn", "score", "scene", "song_line", "discus_throw"].map { "\($0) WHERE room_id = \(id)" }
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

    /// Internal so event modules (Events/Discus) can add their own reducers in extensions.
    func call<A: Encodable>(_ reducer: String, _ args: A) {
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
        createRequestedMs = Date().timeIntervalSince1970 * 1000
        call(Reducer.CreateRoom.name, config)
    }

    func startBattle() { call("start_battle", Reducer.RoomId(roomId: roomId)) }
    func chooseTheme(_ theme: String) { call("choose_theme", Reducer.ChooseTheme(roomId: roomId, theme: theme)) }
    func advance() { call("advance", Reducer.RoomId(roomId: roomId)) }

    @ObservationIgnored private var advancedFrom = Set<String>()

    /// Identifies the reveal on screen now; an advance is only valid from the reveal it was meant for.
    /// Includes the generation: after a Rematch, round 1's round end is a new reveal.
    var revealKey: String? { room.map { "\($0.id).\(generation) \($0.phase) \($0.roundNo) \($0.currentTurnId)" } }

    /// Advances once per reveal, however many callers (conductor, operator key, dev autopilot) ask.
    /// Pass `from` when the advance was scheduled earlier, so a late one can't skip the next reveal.
    func advanceOnce(from expected: String? = nil) {
        guard let key = revealKey, expected == nil || expected == key, !advancedFrom.contains(key),
              room?.phaseValue != .finished, room?.phaseValue != .lobby else { return }
        advancedFrom.insert(key)
        advance()
    }
    func skipTurn(_ turnId: UInt64) { call("skip_turn", Reducer.TurnId(turnId: turnId)) }
    func rematch() {
        generation += 1
        lastPhaseSeen = nil  // already counted; don't count the finished → dealing step again
        call("rematch", Reducer.RoomId(roomId: roomId))
    }
    /// The hall stays open (P16): switch events without a new room; poets and seats stay.
    func setEvent(_ event: String, rounds: UInt32) {
        generation += 1
        lastPhaseSeen = nil
        call("set_event", Reducer.SetEvent(roomId: roomId, event: event, rounds: rounds))
    }

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

    @ObservationIgnored private var cardsPlayed = Set<String>()

    /// Card reveal (P8): play every card from the hand whose words appear in `text`. Safe to call
    /// on every transcript update; each card goes out once.
    func playCards(spokenIn text: String, turnId: UInt64) {
        let spoken = Self.normalize(text)
        let alreadyPlayed = Set(turns.first { $0.id == turnId }?.played ?? [])
        for card in myHand where !alreadyPlayed.contains(card) && !cardsPlayed.contains("\(turnId) \(card)") {
            if spoken.contains(Self.normalize(card)) {
                cardsPlayed.insert("\(turnId) \(card)")
                playCard(turnId, card: card)
            }
        }
    }

    static func normalize(_ s: String) -> String {
        String(s.lowercased().map { $0.isLetter ? $0 : " " }).split(separator: " ").joined(separator: " ")
    }

    func leave() { call("leave_room", Reducer.RoomId(roomId: roomId)) }
    func enter() { call("enter", Reducer.RoomId(roomId: roomId)) }
    func playCard(_ turnId: UInt64, card: String) { call("play_card", Reducer.TurnText(turnId: turnId, text: card)) }
    func rescue(_ turnId: UInt64, card: String) { call("rescue", Reducer.TurnText(turnId: turnId, text: card)) }
    func react(_ kind: String) { call("react", Reducer.React(roomId: roomId, kind: kind)) }

    /// Live transcript, at most about 4 writes a second, always ending on the latest text. A
    /// throttle, not a debounce: the old debounce restarted its 250 ms wait on every change, so a
    /// phone whose words changed faster than that sent nothing until the poet paused (Matus's
    /// phone, Sat afternoon: words landed only at pauses, beside the rescue, and turns ended empty).
    func updateTranscript(_ turnId: UInt64, _ text: String) {
        pendingTranscript = (turnId, text)
        let now = Date()
        if now.timeIntervalSince(lastTranscriptSent) >= 0.25 {
            sendPendingTranscript()
        } else if transcriptFlush == nil {
            let wait = 0.25 - now.timeIntervalSince(lastTranscriptSent)
            transcriptFlush = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(Int(wait * 1000)))
                self?.transcriptFlush = nil
                guard !Task.isCancelled else { return }
                self?.sendPendingTranscript()
            }
        }
    }

    private func sendPendingTranscript() {
        guard let (turnId, text) = pendingTranscript else { return }
        pendingTranscript = nil
        lastTranscriptSent = Date()
        call("update_transcript", Reducer.TurnText(turnId: turnId, text: text))
    }

    func endTurn(_ turnId: UInt64, _ text: String) {
        transcriptFlush?.cancel()
        transcriptFlush = nil
        pendingTranscript = nil
        playCards(spokenIn: text, turnId: turnId)
        call("end_turn", Reducer.TurnText(turnId: turnId, text: text))
    }

    func setProsody(loudness: Float, pitch: Float, hits: UInt32) {
        call(Reducer.SetProsody.name, Reducer.SetProsody(roomId: roomId, loudness: loudness, pitch: pitch, hits: hits))
    }
}
