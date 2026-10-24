import SwiftUI

/// Placeholder phone screen for the typed-turn smoke test. Bare styling; the art lead owns the look.
struct PlayerScreen: View {
    var initialCode = ""

    @State private var battle = BattleClient(role: .player)
    @State private var autopilot: DevAutopilot?
    @State private var code = ""
    @State private var name = ""
    @State private var draft = ""
    @AppStorage("poetName") private var savedName = ""

    var body: some View {
        List {
            Section {
                LabeledContent("Connection", value: "\(battle.connection)")
                if let error = battle.lastError { Text(error).foregroundStyle(.red) }
            }
            if let room = battle.room, battle.me != nil {
                inRoom(room)
            } else {
                Section("Join a battle") {
                    TextField("Room code", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Your name", text: $name)
                    Button("Join") {
                        savedName = name
                        battle.join(code: code, name: name)
                    }
                    .disabled(battle.connection != .connected || code.count != 4 || name.isEmpty)
                }
            }
        }
        .navigationTitle("Poet")
        .task {
            if code.isEmpty { code = initialCode }
            if name.isEmpty { name = savedName }
            battle.connect(to: ServerConfig.spacetime, database: ServerConfig.database)
            autopilot = DevAutopilot(battle: battle)
            autopilot?.start()
        }
        .onDisappear {
            autopilot?.stop()
            battle.disconnect()
        }
    }

    @ViewBuilder
    private func inRoom(_ room: RoomRow) -> some View {
        Section(room.code) {
            LabeledContent("Phase", value: room.phase)
            if let me = battle.me {
                LabeledContent("You", value: me.name + (me.epithet.isEmpty ? "" : ", \(me.epithet)"))
                LabeledContent("Total", value: "\(me.total)")
                if !me.entered { Button("I'm here (mic check)") { battle.enter() } }
            }
            if let round = battle.currentRound { LabeledContent("Theme", value: round.theme) }
        }
        if !battle.myHand.isEmpty {
            Section("Your hand") {
                ForEach(battle.myHand, id: \.self) { Text($0) }
            }
        }
        if let turn = battle.currentTurn {
            if battle.isMyTurn {
                myTurn(turn, room: room)
            } else {
                Section("\(battle.player(turn.playerId)?.name ?? "?") is up") {
                    Text(turn.transcript.isEmpty ? "…" : turn.transcript)
                }
            }
            if let score = battle.score(for: turn.id) {
                Section("Verdict") {
                    Text(score.axes.map(String.init).joined(separator: " · ") + "  = \(score.total)").monospacedDigit()
                    Text(score.verdict).italic()
                }
            }
        }
    }

    @ViewBuilder
    private func myTurn(_ turn: TurnRow, room: RoomRow) -> some View {
        Section("Your turn") {
            switch turn.statusValue {
            case .waiting:
                if room.autoReady {
                    Text("Step up. The arena starts your turn.")
                } else {
                    Button("Ready") { battle.startTurn(turn.id) }
                }
            case .speaking:
                // Typed stand-in for the mic: one line per row, \(room.linesPerTurn) lines.
                TextEditor(text: $draft)
                    .frame(minHeight: 120)
                    .onChange(of: draft) { _, text in battle.updateTranscript(turn.id, text) }
                Button("Done") {
                    battle.endTurn(turn.id, draft)
                    draft = ""
                }
            default:
                Text(turn.status)
            }
        }
    }
}
