import SwiftUI

/// Placeholder phone screen for the typed-turn smoke test. Bare styling; the art lead owns the look.
struct PlayerScreen: View {
    var initialCode = ""

    @State private var battle = BattleClient(role: .player)
    @State private var autopilot: DevAutopilot?
    @State private var recorder: TurnRecorder?
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
            case .speaking where recorder?.phase == .live || recorder?.phase == .finishing:
                if let recorder { talk(recorder) }
            case .speaking:
                // Typed fallback when voice is unavailable: one line per row, \(room.linesPerTurn) lines.
                if case .unavailable(let why) = recorder?.phase {
                    Text(why).font(.footnote).foregroundStyle(.secondary)
                }
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

    /// Placeholder push-to-talk: hold to speak a line, release to end it.
    @ViewBuilder
    private func talk(_ recorder: TurnRecorder) -> some View {
        Text(recorder.transcript.isEmpty ? "Hold to speak a line." : recorder.transcript)
        LabeledContent("On the beat", value: "\(recorder.hits)")
        if let card = recorder.rescueCard { LabeledContent("Homer whispers", value: card) }
        Text(recorder.talking ? "Speaking…" : "Hold to talk")
            .frame(maxWidth: .infinity, minHeight: 88)
            .background(recorder.talking ? Color.accentColor.opacity(0.35) : Color.secondary.opacity(0.15))
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in recorder.setTalking(true) }
                .onEnded { _ in recorder.setTalking(false) })
        Button("Done") { Task { await recorder.finish() } }
    }
}
