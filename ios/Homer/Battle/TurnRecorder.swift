import Foundation
import Observation
import os

/// The phone's side of a battle turn: push-to-talk mic -> Cartesia STT -> live transcript,
/// on-device beat hits with haptics, prosody to the arena at 20 Hz, card reveal (play_card),
/// and the freeze rescue. Views show its state and bind the talk button to `setTalking`.
///
/// Lines: each press of the talk button is one line. Releasing it flushes STT, and the
/// line break lands once that press's text is final.
@Observable
@MainActor
final class TurnRecorder {
    enum Phase: Equatable {
        case idle
        case preparing
        case ready  // socket open, mic on and muted, waiting for the turn to go live
        case live
        case finishing
        case done
        case unavailable(String)  // no agent or no Cartesia: the screen falls back to typing
    }

    private(set) var phase = Phase.idle {
        didSet { if phase != oldValue { Self.log.info("voice phase \(String(describing: self.phase), privacy: .public)"); print("VOICE phase \(phase)") } }
    }
    private static let log = Logger(subsystem: "com.matusvec.homer", category: "voice")
    private(set) var talking = false
    private(set) var hits: UInt32 = 0
    /// Each on-beat hit as a lane word (ms from beat 1), so the beat lane lights up live.
    private(set) var hitMarks: [BeatWord] = []
    private(set) var rescueCard: String?
    /// Final text so far plus the live partial: what the arena shows.
    var transcript: String { finals + (partial.isEmpty ? "" : partial) }
    private(set) var clock: BeatClock?

    let mic = MicProsody()
    private let battle: BattleClient
    private let agent: AgentClient?
    private let haptics = BeatHaptics()

    @ObservationIgnored private var stt: CartesiaSTT?
    @ObservationIgnored private var turnId: UInt64 = 0
    /// Observed: the live transcript the screen shows is built from these.
    private var finals = ""
    private var partial = ""
    @ObservationIgnored private var tasks: [Task<Void, Never>] = []
    @ObservationIgnored private var flushWaiters: [CheckedContinuation<Void, Never>] = []
    @ObservationIgnored private var pendingLineBreaks = 0
    @ObservationIgnored private var lastVoiceMs = 0.0
    @ObservationIgnored private var rescuedLines = Set<Int>()

    init(battle: BattleClient, agent: AgentClient?) {
        self.battle = battle
        self.agent = agent
    }

    // MARK: lifecycle

    @ObservationIgnored private var follower: Task<Void, Never>?

    /// Follows the battle on its own: prepares when this poet is up, goes live when the
    /// turn starts speaking, tears down when it's over. Call once from the phone screen.
    func attach() {
        follower?.cancel()
        follower = Task { [weak self] in
            while !Task.isCancelled {
                await self?.sync()
                try? await Task.sleep(for: .milliseconds(150))
            }
        }
    }

    func detach() {
        follower?.cancel()
        cancel()
    }

    private func sync() async {
        guard let turn = battle.currentTurn, battle.isMyTurn, let room = battle.room, room.event != "discus" else {
            if phase == .ready || phase == .preparing { cancel() }
            return
        }
        switch (turn.statusValue, phase) {
        case (.waiting, .idle), (.waiting, .done):
            await prepare(turn: turn)
        case (.speaking, .idle), (.speaking, .done) where turn.id != turnId:
            // Joined late or the app restarted mid-turn: still try to get the mic up.
            await prepare(turn: turn)
            goLive(turn: turn, room: room)
        case (.speaking, .ready):
            goLive(turn: turn, room: room)
        default:
            break
        }
    }

    /// The poet is up next: get a token, open STT and the mic (muted) before the count-in,
    /// so the first word isn't clipped.
    func prepare(turn: TurnRow) async {
        guard phase == .idle || phase == .done else { return }
        reset()
        turnId = turn.id
        phase = .preparing
        guard let agent else {
            phase = .unavailable("No agent service on this server yet")
            return
        }
        let token: VoiceToken
        do {
            token = try await agent.voiceToken(.init(role: .phone, roomCode: battle.room?.code, playerId: battle.me?.id))
        } catch {
            phase = .unavailable("Voice is offline: \(error.localizedDescription)")
            return
        }
        let keyterms = battle.myHand + (battle.me?.hoard ?? []) + [battle.currentRound?.theme].compactMap { $0 }
        let stt = CartesiaSTT(token: token, keyterms: keyterms)
        self.stt = stt
        stt.start()
        tasks.append(Task { [weak self] in
            for await event in stt.events { self?.handle(event) }
        })

        mic.engine.muted = true
        mic.engine.onPCM = { [weak stt] chunk in stt?.send(chunk) }
        mic.engine.onOnset = { [weak self] onset in
            Task { @MainActor in self?.handle(onset) }
        }
        await mic.start(voiceProcessing: false)
        if let error = mic.error {
            phase = .unavailable(error)
            return
        }
        haptics.prepare()
        phase = .ready
    }

    /// The turn flipped to speaking: lock the beat grid to this device's clock and go live.
    func goLive(turn: TurnRow, room: RoomRow) {
        guard phase == .ready, turn.id == turnId else { return }
        let nowMs = Date().timeIntervalSince1970 * 1000
        let offset = BeatClock.offset(localReceiveMs: nowMs, serverStartedAtMs: turn.startedAt.epochMs)
        let clock = BeatClock(beatAtMs: turn.beatAt.epochMs + offset, bpm: Double(room.bpm),
                              barsPerLine: Int(room.barsPerLine), lines: Int(room.linesPerTurn))
        self.clock = clock
        phase = .live
        haptics.play(clock)
        lastVoiceMs = nowMs

        // Prosody to the arena: about 20 Hz, fire and forget.
        tasks.append(Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.phase == .live else { return }
                let p = self.mic.prosody
                self.battle.setProsody(loudness: Float(p.energy), pitch: Float(p.pitch ?? 0), hits: self.hits)
                try? await Task.sleep(for: .milliseconds(50))
            }
        })
        // Freeze rescue and the end of the turn.
        tasks.append(Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.phase == .live else { return }
                let now = Date().timeIntervalSince1970 * 1000
                if now >= clock.endMs + 250 {
                    await self.finish()
                    return
                }
                self.checkFreeze(now: now, clock: clock)
                try? await Task.sleep(for: .milliseconds(200))
            }
        })
    }

    func setTalking(_ on: Bool) {
        guard phase == .live || phase == .ready, on != talking else { return }
        talking = on
        mic.engine.muted = !on
        if on {
            lastVoiceMs = Date().timeIntervalSince1970 * 1000
        } else {
            // One press is one line: flush it, then break the line once its text is final.
            pendingLineBreaks += 1
            stt?.finalize()
        }
    }

    /// Done tapped, or the turn's time ran out.
    func finish() async {
        guard phase == .live else { return }
        phase = .finishing
        if talking { setTalking(false) }
        haptics.stop()
        stt?.finalize()
        await waitForFlush(timeoutMs: 1500)
        let text = finals.trimmingCharacters(in: .whitespacesAndNewlines)
        battle.endTurn(turnId, text)
        battle.setProsody(loudness: 0, pitch: 0, hits: hits)
        teardown()
        phase = .done
    }

    func cancel() {
        teardown()
        phase = .idle
    }

    // MARK: events

    private func handle(_ event: CartesiaSTT.Event) {
        Self.log.info("stt \(String(describing: event), privacy: .public)")
        switch event {
        case .partial(let text):
            partial = text
        case .final(let text, _):
            finals += text
            partial = ""
            matchCards()
        case .flushed:
            if pendingLineBreaks > 0 {
                pendingLineBreaks -= 1
                if !finals.isEmpty, !finals.hasSuffix("\n") { finals = finals.trimmingCharacters(in: .whitespaces) + "\n" }
            }
            flushWaiters.forEach { $0.resume() }
            flushWaiters.removeAll()
        case .error(let message):
            if phase == .preparing || phase == .ready { phase = .unavailable(message) }
        case .closed:
            break
        }
        if phase == .live { battle.updateTranscript(turnId, transcript) }
    }

    private func handle(_ onset: MicEngine.Onset) {
        guard phase == .live, talking else { return }
        lastVoiceMs = onset.epochMs
        if let clock, clock.hit(atMs: onset.epochMs) != nil {
            hits += 1
            hitMarks.append(BeatWord(text: "", t: onset.epochMs - clock.beatAtMs, stressed: true, onBeat: true))
            haptics.hit()
        }
    }

    /// The formula reveal: a card counts as played when its words appear in the final text.
    private func matchCards() {
        battle.playCards(spokenIn: finals, turnId: turnId)
    }

    private func checkFreeze(now: Double, clock: BeatClock) {
        guard talking, clock.isSpeakingBar(atMs: now), now - lastVoiceMs > 1000 else { return }
        let line = clock.line(atMs: now)
        guard !rescuedLines.contains(line), let agent, let round = battle.currentRound else { return }
        rescuedLines.insert(line)
        let request = RescueRequest(transcript: finals + partial, hand: battle.myHand,
                                    played: battle.currentTurn?.played ?? [], theme: round.theme)
        let turnId = turnId
        Task {
            guard let rescue = try? await agent.rescue(request) else { return }
            rescueCard = rescue.formula
            battle.rescue(turnId, card: rescue.formula)
        }
    }

    // MARK: plumbing

    private func waitForFlush(timeoutMs: Int) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await withCheckedContinuation { self.flushWaiters.append($0) }
            }
            group.addTask { try? await Task.sleep(for: .milliseconds(timeoutMs)) }
            await group.next()
            group.cancelAll()
            self.flushWaiters.forEach { $0.resume() }
            self.flushWaiters.removeAll()
        }
    }

    private func teardown() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        mic.engine.onPCM = nil
        mic.engine.onOnset = nil
        mic.stop()
        haptics.stop()
        stt?.close()
        stt = nil
        talking = false
    }

    private func reset() {
        finals = ""
        partial = ""
        hits = 0
        hitMarks = []
        rescueCard = nil
        rescuedLines.removeAll()
        pendingLineBreaks = 0
        clock = nil
    }
}
