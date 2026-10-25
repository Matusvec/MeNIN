import SwiftUI

/// The phone in a battle: the art lead's PlayerView fed by BattlePresenter. The voice turn
/// lives in TurnRecorder; when voice is unavailable (no agent or Cartesia key yet) a small
/// typed field stands in during your turn, as a dev fallback.
struct PlayerScreen: View {
    var initialCode = ""
    /// The way out from the art lead's header (a back arrow before the wordmark).
    var onLeave: (() -> Void)? = nil

    @State private var battle = BattleClient(role: .player)
    @State private var autopilot: DevAutopilot?
    @State private var recorder: TurnRecorder?
    @State private var draft = ""
    @State private var confirmLeave = false
    /// A wait the poet can see, set only once it has lasted 300 ms so fast paths never flash.
    @State private var slowWait: WaitState?
    @State private var joiningCode: String?
    @AppStorage("poetName") private var savedName = ""

    var body: some View {
        Group {
            if battle.me != nil, battle.room?.event == "stadion" {
                StadionPhoneRoot(battle: battle, onBack: { if midBattle { confirmLeave = true } else { leave() } })
            } else if battle.me != nil, battle.room?.event == "toxeia" {
                ToxeiaPhoneRoot(battle: battle, onBack: { if midBattle { confirmLeave = true } else { leave() } })
            } else if battle.me != nil, battle.room?.event == "pygmachia" {
                BoxingPhoneRoot(battle: battle, onBack: { if midBattle { confirmLeave = true } else { leave() } })
            } else if battle.me != nil, battle.room?.event == "discus" {
                DiscusPhoneRoot(battle: battle, onBack: { if midBattle { confirmLeave = true } else { leave() } })  // no mic in discus
            } else {
                PlayerView(model: model, actions: actions)
                    .overlay(alignment: .topLeading) {
                        if UserDefaults.standard.bool(forKey: "voiceDiagnostics"), let recorder { VoiceDiagnostics(recorder: recorder) }
                    }
                    .confirmationDialog("Leave the battle?", isPresented: $confirmLeave, titleVisibility: .visible) {
                        Button("Leave", role: .destructive) { leave() }
                    } message: {
                        Text("Your seat stays open for a while; rejoin with the same code.")
                    }
            }
        }
            .toolbar(.hidden, for: .navigationBar)
            .task(id: waitCandidate) {
                // Show a wait only if it's still pending after 300 ms.
                slowWait = nil
                guard let wait = waitCandidate else { return }
                try? await Task.sleep(for: .milliseconds(300))
                if !Task.isCancelled, waitCandidate == wait { slowWait = wait }
            }
            .onChange(of: battle.room?.event) { _, event in
                // The hall switched events (set_event): the sport screens above swap themselves (each
                // tears down its motion and takes its own tables); back in a voice event, drop the
                // last sport's tables.
                if !["stadion", "pygmachia", "toxeia"].contains(event ?? "") { battle.watchEventTables(event ?? "") }
            }
            .onChange(of: recorder?.draftFromVoice) { _, heard in
                // Voice failed mid-verse: the typed field starts with what was already heard.
                if let heard, !heard.isEmpty, draft.isEmpty { draft = heard }
            }
            .onChange(of: battle.room?.phase) { _, _ in
                // The hall stays open after a battle (P16), and join_room takes a same-device reconnect
                // even in `finished`: keep the way back fresh while the room lives. Leave, or "no such
                // room" on a rejoin, clears it.
                if let me = battle.me, let code = battle.room?.code { LastBattle.save(code: code, name: me.name) }
            }
            .task {
                UIApplication.shared.isIdleTimerDisabled = true  // a locked screen drops the poet mid-verse
                MusicDirector.shared.stopAll()
                battle.connect(to: ServerConfig.spacetime, database: ServerConfig.database)
                rejoinIfReturning()
                let recorder = TurnRecorder(battle: battle, agent: AgentClient.configured)
                recorder.attach()
                self.recorder = recorder
                autopilot = DevAutopilot(battle: battle)
                autopilot?.recorder = recorder
                autopilot?.start()
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
                recorder?.detach()
                autopilot?.stop()
                battle.disconnect()
            }
    }

    /// Reopened mid-battle: rejoin the remembered room as soon as the connection is up.
    private func rejoinIfReturning() {
        guard let last = LastBattle.recent(), last.code == initialCode.uppercased() else { return }
        Task {
            for _ in 0..<100 where battle.connection != .connected { try? await Task.sleep(for: .milliseconds(100)) }
            guard battle.connection == .connected, battle.me == nil else { return }
            joiningCode = last.code
            battle.join(code: last.code, name: last.name)
            try? await Task.sleep(for: .seconds(2))
            if battle.lastError == "no such room" { LastBattle.clear() }  // it finished while we were away
        }
    }

    /// What the poet is waiting on right now, if anything (before the 300 ms rule).
    private var waitCandidate: WaitState? {
        if battle.connection == .disconnected || (battle.connection == .connecting && battle.identity != nil) {
            return .reconnecting
        }
        if battle.me == nil, let code = joiningCode, battle.lastError == nil {
            return .findingRoom(code)
        }
        if recorder?.phase == .preparing { return .warmingUp }
        return nil
    }

    /// Mid-battle: the back chevron asks first.
    private var midBattle: Bool {
        guard battle.me != nil, let phase = battle.room?.phaseValue else { return false }
        return phase != .lobby && phase != .finished
    }

    private func leave() {
        if battle.me != nil { battle.leave() }
        LastBattle.clear()
        onLeave?()
    }

    private var model: PlayerModel {
        var m = BattlePresenter.player(battle, recorder: recorder)
        m.wait = slowWait
        // Voice unavailable on my turn: the typed fallback takes push-to-talk's place in the action band.
        if let turn = battle.currentTurn, battle.isMyTurn, turn.statusValue == .speaking,
           case .unavailable = recorder?.phase {
            m.typed = draft
        }
        if battle.me == nil {
            m.code = initialCode
            if m.me == nil, !savedName.isEmpty { m.me = PoetPlate(id: "", name: savedName, epithet: "", seat: 0) }
        }
        return m
    }

    private var actions: PlayerActions {
        PlayerActions(
            join: { code, name in
                savedName = name
                joiningCode = code.uppercased()
                battle.join(code: code, name: name)
                LastBattle.save(code: code, name: name)
            },
            imHere: { battle.enter() },
            ready: { if let turn = battle.currentTurn { battle.startTurn(turn.id) } },
            setTalking: { recorder?.setTalking($0) },
            done: {
                if let recorder, recorder.phase == .live {
                    Task { await recorder.finish() }
                } else if let turn = battle.currentTurn {
                    battle.endTurn(turn.id, draft)
                    draft = ""
                }
            },
            playMove: { id in
                // P17: a tap is a claim; the judge checks the move was really made.
                if let turn = battle.currentTurn, battle.isMyTurn { battle.playCard(turn.id, card: id) }
            },
            leave: {
                if midBattle { confirmLeave = true } else { leave() }
            },
            type: { text in
                draft = text
                if let turn = battle.currentTurn, battle.isMyTurn { battle.updateTranscript(turn.id, text) }
            }
        )
    }
}

/// The battle this phone is in, so a crash or force-quit drops the poet straight back into it.
enum LastBattle {
    private static let key = "lastBattle"
    static let freshFor: TimeInterval = 30 * 60

    static func save(code: String, name: String) {
        UserDefaults.standard.set(["code": code.uppercased(), "name": name, "at": Date().timeIntervalSince1970], forKey: key)
    }

    static func clear() { UserDefaults.standard.removeObject(forKey: key) }

    static func recent() -> (code: String, name: String)? {
        guard let d = UserDefaults.standard.dictionary(forKey: key), let code = d["code"] as? String,
              let name = d["name"] as? String, let at = d["at"] as? Double,
              Date().timeIntervalSince1970 - at < freshFor else { return nil }
        return (code, name)
    }
}

/// Dev → Server → "Voice diagnostics": where a verse's words stop, on the poet's own screen.
private struct VoiceDiagnostics: View {
    let recorder: TurnRecorder

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            Text("voice \(String(describing: recorder.phase)) · stt \(recorder.sttEvents) · words \(recorder.partialsHeard) · sent \(recorder.updatesSent)\(recorder.lastSTTNote.isEmpty ? "" : " · " + recorder.lastSTTNote)")
                .font(.caption2.monospaced())
                .padding(6)
                .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(.white)
                .padding(.top, 50)
                .padding(.leading, 8)
                .allowsHitTesting(false)
        }
    }
}
