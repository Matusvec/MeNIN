import SwiftUI

/// The app shell: the scene always on behind, and one screen in front chosen by AppModel.
/// Screens are the art lead's views fed with props; battle screens are still placeholders.
struct RootView: View {
    @State private var app = AppModel()

    /// The dev menu (server switch, diagnostics, scene lab) is for the team, not reviewers.
    static var devMenuEnabled: Bool {
        #if DEBUG
        true
        #else
        UserDefaults.standard.bool(forKey: "devMenu")
        #endif
    }

    var body: some View {
        ZStack {
            SceneView(driver: app.scene)
                .ignoresSafeArea()
            content
        }
        .onOpenURL { app.open($0) }
        .onChange(of: app.route, initial: true) { app.routeChanged() }
    }

    @ViewBuilder
    private var content: some View {
        switch app.route {
        case .firstOpen:
            FirstOpenScreen(app: app)
        case .home:
            EventMenuView(events: EventTile.all.map { tile in
                var t = tile
                t.locked = tile.locked || !AppModel.liveEvents.contains(tile.id)
                return t
            }, onPick: { tile in
                guard !tile.locked else { return }
                app.route = .event(tile.id)
            })
            .overlay(alignment: .topTrailing) {
                if Self.devMenuEnabled {
                    Button("Dev") { app.route = .dev }.padding()
                }
            }
        case .event("poetry"):
            HomeView(
                name: app.poetName.isEmpty ? "poet" : app.poetName,
                collectionSummary: app.hoard.isEmpty ? "Coin a formula and it lands here" : "\(app.hoard.count) formulas",
                initial: app.poetName.first.map { String($0).uppercased() },
                onMode: { mode in
                    switch mode.id {
                    case "bard": app.route = .bard
                    case "practice": app.route = .practice
                    default: app.route = .battle(event: "poetry")
                    }
                },
                onProfile: { app.route = .home }
            )
        case .event(let id):
            Routed(app: app, title: EventTile.all.first { $0.id == id }?.title ?? id) {
                EventChoicesView(app: app, event: id)
            }
        case .battle(let event):
            Routed(app: app, title: "Fight") { BattleChoiceView(app: app, event: event) }
        case .arena(let event):
            Routed(app: app, title: "Arena") { ArenaScreen(event: event) }
        case .player(let code):
            Routed(app: app, title: "Poet") { PlayerScreen(initialCode: code) }
        case .bard:
            // TODO: Bard lessons 1–3 (/lessons, /lesson/feedback).
            Routed(app: app, title: "Bard") { Text("Lessons are coming.") }
        case .practice:
            Routed(app: app, title: "Practice") { PracticeScreen(app: app) }
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
        // A ZStack with a clear layer always exists, so `.task` fires before the flow does.
        ZStack {
            Color.clear
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

/// E1 for events whose choices aren't a designed screen yet (debate, discus). Placeholder
/// chrome; the art lead owns the look. The host's one line comes with the tile.
private struct EventChoicesView: View {
    let app: AppModel
    let event: String

    var body: some View {
        List {
            switch event {
            case "debate":
                // TODO(spec): Train = spar with Socrates, best of three (needs the debate brain).
                Button("Train with Socrates") {}.disabled(true)
                Button("Fight") { app.route = .battle(event: "debate") }
            case "discus":
                // TODO: Throw = multiplayer's DiscusSoloScreen (ios/Homer/Events/Discus/) once it lands.
                Button("Throw") {}.disabled(true)
                Button("Fight") { app.route = .battle(event: "discus") }
            default:
                Button("Fight") { app.route = .battle(event: event) }
            }
        }
    }
}

private struct BattleChoiceView: View {
    let app: AppModel
    let event: String
    @State private var code = ""

    var body: some View {
        List {
            Section {
                Button("Host the arena on this screen") { app.route = .arena(event: event) }
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
