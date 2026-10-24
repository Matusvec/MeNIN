import Foundation
import Observation

/// App-wide state: where we are, who the poet is, and the scene behind every screen.
/// Views read it and send intents; persistence is small and local (no accounts, SPEC).
@Observable
@MainActor
final class AppModel {
    enum Route: Hashable {
        case firstOpen
        case home
        case bard
        case practice
        case battle  // pick: host the arena or join as a poet
        case arena
        case player(code: String)
        case dev
    }

    var route: Route
    /// The always-on scene (SPEC "The scene"): whoever is live writes it, no view re-renders.
    let scene = SceneDriver()

    var poetName: String {
        didSet { defaults.set(poetName, forKey: Keys.name) }
    }

    /// Formulas the poet has coined (SPEC "Hoard"); kept on this device.
    private(set) var hoard: [String] {
        didSet { defaults.set(hoard, forKey: Keys.hoard) }
    }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let firstOpenDone = "firstOpenDone"
        static let name = "poetName"
        static let hoard = "hoard"
    }

    init() {
        poetName = defaults.string(forKey: Keys.name) ?? ""
        hoard = defaults.stringArray(forKey: Keys.hoard) ?? []
        route = defaults.bool(forKey: Keys.firstOpenDone) ? .home : .firstOpen
        // Dev: `-startScreen arena|player|dev|home|first` jumps straight in (smoke tests, the operator).
        switch defaults.string(forKey: "startScreen") {
        case "arena": route = .arena
        case "player": route = .player(code: defaults.string(forKey: "joinCode") ?? "")
        case "dev", "diagnostics": route = .dev
        case "home": route = .home
        case "practice": route = .practice
        case "first": route = .firstOpen
        default: break
        }
    }

    func finishFirstOpen() {
        defaults.set(true, forKey: Keys.firstOpenDone)
        route = .home
    }

    func coin(_ formula: String) {
        let f = formula.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty, !hoard.contains(f) else { return }
        hoard.append(f)
    }

    /// `homer://join/ABCD` from the arena's QR code.
    func open(_ url: URL) {
        guard url.scheme == "homer", url.host() == "join", let code = url.pathComponents.dropFirst().first else { return }
        route = .player(code: code.uppercased())
    }
}
