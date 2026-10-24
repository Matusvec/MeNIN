import CoreImage.CIFilterBuiltins
import SwiftUI

/// Placeholder arena for the typed-turn smoke test. Bare styling; the art lead owns the look.
struct ArenaScreen: View {
    @State private var battle = BattleClient(role: .arena)
    @State private var autopilot: DevAutopilot?

    var body: some View {
        List {
            Section {
                LabeledContent("Server", value: "\(ServerConfig.spacetime.host() ?? "?") / \(ServerConfig.database)")
                LabeledContent("Connection", value: "\(battle.connection)")
                if let error = battle.lastError { Text(error).foregroundStyle(.red) }
            }
            if let room = battle.room {
                roomSection(room)
            } else {
                Section("New battle") {
                    Button("Start a battle") { battle.createRoom(.standard) }
                    Button("Start a demo battle") { battle.createRoom(.demoMode) }
                    if let latest = battle.latestHostedRoom {
                        Button("Resume \(latest.code) (\(latest.phase))") { battle.watchRoom(latest.id) }
                    }
                }
                .disabled(battle.connection != .connected)
            }
        }
        .navigationTitle("Arena")
        .arenaOperatorShortcuts(battle)
        .task {
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
    private func roomSection(_ room: RoomRow) -> some View {
        Section("Room") {
            HStack {
                Text(room.code).font(.system(size: 56, weight: .bold, design: .monospaced))
                Spacer()
                QRCodeView(text: "homer://join/\(room.code)").frame(width: 120, height: 120)
            }
            LabeledContent("Phase", value: room.phase)
            LabeledContent("Round", value: "\(room.roundNo) of \(room.rounds)")
            if room.demo { Text("Demo mode") }
            if let round = battle.currentRound { LabeledContent("Theme", value: round.theme) }
        }
        Section("Poets") {
            ForEach(battle.players) { p in
                HStack {
                    Text(p.name + (p.epithet.isEmpty ? "" : ", \(p.epithet)"))
                    Spacer()
                    Text("\(p.total)").monospacedDigit()
                    Circle().fill(p.connected ? .green : .gray).frame(width: 8, height: 8)
                }
            }
        }
        if let turn = battle.currentTurn {
            Section("Turn: \(battle.player(turn.playerId)?.name ?? "?")") {
                LabeledContent("Status", value: turn.status + (turn.attempt > 1 ? " (attempt \(turn.attempt))" : ""))
                Text(turn.transcript.isEmpty ? "…" : turn.transcript)
                if let score = battle.score(for: turn.id) {
                    Text(score.axes.map(String.init).joined(separator: " · ") + "  = \(score.total)").monospacedDigit()
                    Text(score.verdict).italic()
                }
            }
        }
        Section("Controls") {
            switch room.phaseValue {
            case .lobby:
                Button("Begin (\(battle.players.count) poets)") { battle.startBattle() }
                    .disabled(battle.players.count < 2)
            case .ready:
                if let turn = battle.currentTurn { Button("Start turn") { battle.startTurn(turn.id) } }
            case .speaking, .judging:
                if let turn = battle.currentTurn { Button("Skip turn", role: .destructive) { battle.skipTurn(turn.id) } }
            case .scored, .roundEnd, .finale:
                Button("Advance") { battle.advance() }
            default:
                EmptyView()
            }
            if room.phaseValue != .lobby {
                Button("Rematch") { battle.rematch() }
            }
        }
    }
}

struct QRCodeView: View {
    let text: String

    var body: some View {
        if let image = Self.render(text) {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
        }
    }

    static func render(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
              let cg = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
