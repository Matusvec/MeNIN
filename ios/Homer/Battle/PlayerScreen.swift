import SwiftUI

/// The phone in a battle: the art lead's PlayerView fed by BattlePresenter. The voice turn
/// lives in TurnRecorder; when voice is unavailable (no agent or Cartesia key yet) a small
/// typed field stands in during your turn, as a dev fallback.
struct PlayerScreen: View {
    var initialCode = ""

    @State private var battle = BattleClient(role: .player)
    @State private var autopilot: DevAutopilot?
    @State private var recorder: TurnRecorder?
    @State private var draft = ""
    @AppStorage("poetName") private var savedName = ""

    var body: some View {
        PlayerView(model: model, actions: actions)
            .safeAreaInset(edge: .bottom) { typedFallback }
            .toolbar(battle.me == nil ? .automatic : .hidden, for: .navigationBar)
            .task {
                MusicDirector.shared.stopAll()
                battle.connect(to: ServerConfig.spacetime, database: ServerConfig.database)
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
