import SwiftUI

/// The app shell: the scene always on behind, and one screen in front chosen by AppModel.
/// Screens are the art lead's views fed with props; battle screens are still placeholders.
struct RootView: View {
    @State private var app = AppModel()
    @Environment(\.horizontalSizeClass) private var sizeClass

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
        // The palette ignores the system scheme; pin system chrome to match it (dark-mode Mac arena).
        .preferredColorScheme(Direction.current.isLight ? .light : .dark)
        .onOpenURL { app.open($0) }
        .onChange(of: app.route, initial: true) { app.routeChanged() }
    }

    @ViewBuilder
    private var content: some View {
        switch app.route {
        case .firstOpen:
            FirstOpenScreen(app: app)
        case .home where sizeClass == .compact:
            // Phones are join-first: the battle screen is the website (Matus, Sat 2:30); training below.
            PhoneHomeView(
                name: app.poetName.isEmpty ? nil : app.poetName,
                site: "play.206.189.237.157.sslip.io",
                lessonLine: "Lesson 1 · The beat",
                actions: PhoneHomeActions(
                    join: { code in app.route = .player(code: code.uppercased()) },
                    bard: { app.route = .bard },
                    practice: { app.route = .practice },
                    discus: { app.route = .discusThrow }
                )
            )
            .simultaneousGesture(LongPressGesture(minimumDuration: 3).onEnded { _ in app.route = .dev })
        case .home:
            EventMenuView(events: EventTile.all.map { tile in
                var t = tile
                t.locked = tile.locked || !AppModel.liveEvents.contains(tile.id)
                return t
            }, onPick: { tile in
                guard !tile.locked else { return }
                app.route = .event(tile.id)
            })
            .overlay(alignment: .bottomLeading) {
                // Out of the header's way (artist's phone layout).
                if Self.devMenuEnabled {
                    Button("Dev") { app.route = .dev }.font(.caption).padding()
                }
            }
            // Any build: a 3 s press on the hall opens Dev (the in-app arena lives there as a fallback).
            .simultaneousGesture(LongPressGesture(minimumDuration: 3).onEnded { _ in app.route = .dev })
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
                onProfile: { app.route = .home },
                onBack: { app.route = .home }
            )
        case .event(let id):
            Routed(app: app, title: EventTile.all.first { $0.id == id }?.title ?? id) {
                EventEntryView(event: EventKind(rawValue: id) ?? .poetry, actions: EventEntryActions(
                    // TODO(spec): Train = spar with Socrates, best of three (needs the debate brain).
                    solo: id == "discus" ? { app.route = .discusThrow } : nil,
                    fight: { app.route = .battle(event: id) },
                    back: { app.route = .home }
                ))
            }
        case .battle(let event):
            Routed(app: app, title: "Fight") {
                // One big screen: the website hosts battles. The in-app arena is a Dev fallback (Matus, Sat 2:30).
                BattleEntryView(event: EventKind(rawValue: event) ?? .poetry, actions: BattleEntryActions(
                    host: nil,
                    join: { code in app.route = .player(code: code.uppercased()) },
                    back: { app.route = .event(event) }
                ))
            }
        case .arena(let event):
            Routed(app: app, title: "Arena") { ArenaScreen(event: event, scene: app.scene) }
        case .player(let code):
            // A new code is a new screen: no recorder or connection state carries over between rooms.
            Routed(app: app, title: "Poet") { PlayerScreen(initialCode: code, onLeave: { app.route = .home }, scene: app.scene).id(code) }
        case .bard:
            // TODO(spec): the lesson path (2 and 3 next); lesson 1 ships for the 6 PM study.
            Routed(app: app, title: "Bard") { BardScreen(app: app) }
        case .practice:
            Routed(app: app, title: "Practice") { PracticeScreen(app: app) }
        case .discusThrow:
            Routed(app: app, title: "Throw") {
                DiscusSoloRoot()
                    .overlay(alignment: .topLeading) {
                        BackButton { app.route = .home }.padding(.leading, 16).padding(.top, 8)
                    }
            }
        case .dev:
            Routed(app: app, title: "Dev", chrome: true) { DevMenu(app: app) }
        case .gallery(let page):
            DesignGalleryView(page: page)
        }
    }
}

/// A routed screen. On phones the art lead's PhoneScaffold carries the back chevron, so there's
/// no bar; on the Mac and iPad (and in the dev menu) a Home button stays in the bar.
private struct Routed<Content: View>: View {
    let app: AppModel
    let title: String
    var chrome = false
    @ViewBuilder var content: Content
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        NavigationStack {
            if sizeClass == .compact && !chrome {
                content
                    .containerBackground(.clear, for: .navigation)  // the scene shows behind every routed screen
                    .toolbar(.hidden, for: .navigationBar)
            } else {
                content
                    .containerBackground(.clear, for: .navigation)
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .navigationTitle(title)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Home") { app.route = .home }
                        }
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
            Section("Fallback: host the arena on this device") {
                ForEach(["poetry", "debate", "discus"], id: \.self) { event in
                    Button("Arena: \(event)") { app.route = .arena(event: event) }
                }
            }
            Button("Replay first open") { app.route = .firstOpen }
        }
    }
}

struct DevSettingsView: View {
    @State private var preset = ServerConfig.preset
    @State private var echoCancel = MicEngine.echoCancelSolo
    @State private var voiceDiag = UserDefaults.standard.bool(forKey: "voiceDiagnostics")

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
                Toggle("Voice diagnostics on the poet's screen", isOn: $voiceDiag)
                    .onChange(of: voiceDiag) { _, on in UserDefaults.standard.set(on, forKey: "voiceDiagnostics") }
                Toggle("Echo cancel in lessons and practice", isOn: $echoCancel)
                    .onChange(of: echoCancel) { _, on in UserDefaults.standard.set(on, forKey: "echoCancelSolo") }
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
