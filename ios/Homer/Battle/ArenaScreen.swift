import CoreImage.CIFilterBuiltins
import SwiftUI

/// The arena: the art lead's ArenaView fed by BattlePresenter once a room exists, and a bare
/// start panel before that. Sound, Homer and auto-advance live in ArenaConductor.
struct ArenaScreen: View {
    var event = "poetry"
    @State private var battle = BattleClient(role: .arena)
    @State private var autopilot: DevAutopilot?
    @State private var conductor: ArenaConductor?
    @State private var inHall = false

    var body: some View {
        Group {
            if battle.room?.event == "discus" {
                // Discus runs its own canvas and reveal (Events/Discus); Homer's lines go through the conductor's voice.
                DiscusArenaRoot(battle: battle, homer: conductor?.homer)
                    .toolbar(.hidden, for: .navigationBar)
            } else if let model = BattlePresenter.arena(battle, conductor: conductor, inHall: inHall) {
                ArenaView(model: model, actions: BattlePresenter.arenaActions(battle, conductor: conductor, inHall: $inHall))
                    .overlay(alignment: .topTrailing) { problems }
                    .toolbar(.hidden, for: .navigationBar)
            } else {
                startPanel
            }
        }
        .navigationTitle("Arena")
        .arenaOperatorShortcuts(battle, themeCards: conductor?.themeCards ?? [], onMuteMusic: { conductor?.toggleMusicMute() })
        .orientationLock(.landscape)
        .task {
            battle.agent = AgentClient.configured
            battle.connect(to: ServerConfig.spacetime, database: ServerConfig.database)
            let conductor = ArenaConductor(battle: battle, agent: AgentClient.configured)
            conductor.start()
            self.conductor = conductor
            autopilot = DevAutopilot(battle: battle)
            autopilot?.start()
        }
        .onDisappear {
            conductor?.stop()
            autopilot?.stop()
            battle.disconnect()
        }
    }

    /// Before a room exists: start one, or resume the last one this arena hosted.
    private var startPanel: some View {
        let latest = battle.latestHostedRoom
        let status: String? = battle.connection == .connected ? nil
            : (battle.lastError ?? (battle.connection == .disconnected ? "Can't reach the hall. Retrying…" : "Connecting…"))
        return ArenaStartView(
            status: status,
            resumeCode: latest?.code,
            onStart: { battle.createRoom(.preset(event: event, demo: false)) },
            onDemo: { battle.createRoom(.preset(event: event, demo: true)) },
            onResume: latest.map { room in { battle.watchRoom(room.id) } }
        )
    }

    /// Small, out of the judges' way: only shows when something is wrong.
    @ViewBuilder
    private var problems: some View {
        let issues = [battle.connection == .connected ? nil : "Connection: \(battle.connection)",
                      battle.lastError, battle.agentError, conductor?.audioError].compactMap { $0 }
        if !issues.isEmpty {
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(issues, id: \.self) { Text($0) }
            }
            .font(.caption2)
            .padding(6)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
            .padding(8)
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
