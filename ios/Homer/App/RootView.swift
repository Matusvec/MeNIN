import SwiftUI

/// The app shell: the scene always on behind, and one screen in front chosen by AppModel.
/// Screens are the art lead's views fed with props; battle screens are still placeholders.
struct RootView: View {
    @State private var app = AppModel()

    var body: some View {
        ZStack {
            SceneView(driver: app.scene)
                .ignoresSafeArea()
            content
        }
        .onOpenURL { app.open($0) }
    }

    @ViewBuilder
    private var content: some View {
        switch app.route {
        case .firstOpen:
            FirstOpenScreen(app: app)
        case .home:
            HomeView(
                name: app.poetName.isEmpty ? "poet" : app.poetName,
                collectionSummary: app.hoard.isEmpty ? "Coin a formula and it lands here" : "\(app.hoard.count) formulas",
                initial: app.poetName.first.map { String($0).uppercased() },
                onMode: { mode in
                    switch mode.id {
                    case "bard": app.route = .bard
                    case "practice": app.route = .practice
                    default: app.route = .battle
                    }
                },
                onProfile: { app.route = .dev }
            )
        case .battle:
            Routed(app: app, title: "Battle") { BattleChoiceView(app: app) }
        case .arena:
            Routed(app: app, title: "Arena") { ArenaScreen() }
        case .player(let code):
            Routed(app: app, title: "Poet") { PlayerScreen(initialCode: code) }
        case .bard:
            // TODO: Bard lessons 1–3 (/lessons, /lesson/feedback).
            Routed(app: app, title: "Bard") { Text("Lessons are coming.") }
        case .practice:
            // TODO: Practice (/deal, /judge over SSE, the phone plays the beat).
            Routed(app: app, title: "Practice") { Text("Sparring is coming.") }
        case .dev:
            Routed(app: app, title: "Dev") { DevMenu(app: app) }
        }
    }
}

/// A routed screen with a way home. Placeholder chrome; the art lead owns the look.
private struct Routed<Content: View>: View {
    let app: AppModel
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Home") { app.route = .home }
                    }
                }
        }
    }
}

private struct FirstOpenScreen: View {
    let app: AppModel
    @State private var flow: FirstOpenFlow?

    var body: some View {
        Group {
            if let flow {
                FirstOpenView(
                    beat: flow.beat == .listening ? .listening : (flow.beat == .homerAnswers ? .homerAnswers : .homerSpeaks),
                    caption: flow.homer.caption?.text ?? "",
                    spoken: flow.homer.spoken,
                    heard: flow.heard,
                    level: flow.level
                )
            }
        }
        .task {
            let flow = FirstOpenFlow(scene: app.scene, agent: AgentClient.configured)
            self.flow = flow
            await flow.run()
            app.finishFirstOpen()
        }
    }
}

private struct BattleChoiceView: View {
    let app: AppModel
    @State private var code = ""

    var body: some View {
        List {
            Section {
                Button("Host the arena on this screen") { app.route = .arena }
            } footer: {
                Text("A Mac or an iPad, or a phone in landscape as a backup.")
            }
            Section("Join a battle") {
                TextField("Room code", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button("Join") { app.route = .player(code: code.uppercased()) }
                    .disabled(code.count != 4)
            }
        }
    }
}

private struct DevMenu: View {
    let app: AppModel
    @State private var mic = MicProsody()
    @State private var labMic = false

    var body: some View {
        List {
            NavigationLink("Diagnostics: mic + Metal") { DiagnosticsView() }
            NavigationLink("Server") { DevSettingsView() }
            NavigationLink("Scene lab") {
                SceneLabView(driver: app.scene, isMicOn: $labMic)
                    .ignoresSafeArea()
                    .onChange(of: labMic) { _, on in
                        if on {
                            mic.onProsody = { [scene = app.scene] p in scene.prosody = p }
                            Task { await mic.start() }
                        } else {
                            mic.stop()
                            app.scene.prosody = .silent
                        }
                    }
                    .onDisappear { mic.stop() }
            }
            NavigationLink("Design gallery") { DesignGalleryView() }
            Button("Replay first open") { app.route = .firstOpen }
        }
    }
}

struct DevSettingsView: View {
    @State private var preset = ServerConfig.preset

    var body: some View {
        Form {
            Section {
                Picker("Server", selection: $preset) {
                    ForEach(ServerConfig.presets) { Text($0.id).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: preset) { _, new in ServerConfig.preset = new }
                LabeledContent("URL", value: ServerConfig.spacetime.absoluteString)
                LabeledContent("Database", value: ServerConfig.database)
                LabeledContent("Agent", value: ServerConfig.agent?.absoluteString ?? "not deployed")
            } footer: {
                Text("Reopen the battle screen after switching. Each server has its own identity.")
            }
        }
        .navigationTitle("Server")
    }
}

#Preview {
    RootView()
}
