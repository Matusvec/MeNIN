import SwiftUI

enum Route: Hashable {
    case arena
    case player(code: String)
    case diagnostics
    case devSettings
}

/// Placeholder navigation shell. Styling is deliberately bare; the art lead owns the look.
struct RootView: View {
    // Dev: launch with `-startScreen diagnostics|arena|player` to open a screen directly.
    @State private var path: [Route] = Self.startRoute.map { [$0] } ?? []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Battle") {
                    NavigationLink("Arena", value: Route.arena)
                    NavigationLink("Join as a poet", value: Route.player(code: ""))
                }
                Section("Dev") {
                    NavigationLink("Diagnostics: mic + Metal", value: Route.diagnostics)
                    NavigationLink("Server", value: Route.devSettings)
                }
            }
            .navigationTitle("Homer")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .arena: ArenaScreen()
                case .player(let code): PlayerScreen(initialCode: code)
                case .diagnostics: DiagnosticsView()
                case .devSettings: DevSettingsView()
                }
            }
        }
        .onOpenURL { url in
            // homer://join/ABCD, from the arena's QR code
            if url.host() == "join", let code = url.pathComponents.dropFirst().first {
                path = [.player(code: code.uppercased())]
            }
        }
    }

    private static var startRoute: Route? {
        switch UserDefaults.standard.string(forKey: "startScreen") {
        case "diagnostics": .diagnostics
        case "arena": .arena
        case "player": .player(code: UserDefaults.standard.string(forKey: "joinCode") ?? "")
        default: nil
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
