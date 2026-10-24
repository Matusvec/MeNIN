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
    @AppStorage("poetName") private var savedName = ""

    var body: some View {
        Group {
            if battle.me != nil, battle.room?.event == "discus" {
                DiscusPhoneRoot(battle: battle)  // no mic: TurnRecorder stays off in discus rooms
            } else {
                PlayerView(model: model, actions: actions)
                    .safeAreaInset(edge: .bottom) { typedFallback }
            }
        }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: battle.room?.phase) { _, phase in
                if phase == RoomPhase.finished.rawValue { LastBattle.clear() }  // nothing to come back to
            }
            .task {
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
            battle.join(code: last.code, name: last.name)
            try? await Task.sleep(for: .seconds(2))
            if battle.lastError == "no such room" { LastBattle.clear() }  // it finished while we were away
        }
    }

    private var model: PlayerModel {
        var m = BattlePresenter.player(battle, recorder: recorder)
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
                if battle.me != nil { battle.leave() }
                LastBattle.clear()
                onLeave?()
            }
        )
    }

    /// Typing stands in for the mic only during your own turn, and only when voice is down.
    @ViewBuilder
    private var typedFallback: some View {
        if let turn = battle.currentTurn, battle.isMyTurn, turn.statusValue == .speaking,
           case .unavailable(let why) = recorder?.phase {
            VStack(alignment: .leading, spacing: 8) {
                Text(why).font(.caption).foregroundStyle(.secondary)
                TextField("Type your verse, one line per row", text: $draft, axis: .vertical)
                    .lineLimit(2...6)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: draft) { _, text in battle.updateTranscript(turn.id, text) }
                Button("Done") {
                    battle.endTurn(turn.id, draft)
                    draft = ""
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.thinMaterial)
        }
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
