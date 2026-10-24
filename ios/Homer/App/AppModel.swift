import Foundation
import Observation

/// App-wide state: where we are, who the poet is, and the scene behind every screen.
/// Views read it and send intents; persistence is small and local (no accounts, SPEC).
@Observable
@MainActor
final class AppModel {
    enum Route: Hashable {
        case firstOpen
        /// E0, the event menu: one tile per event (docs/ux-flow.md section 7).
        case home
        /// E1, a tile opened onto its choices. Poetry opens onto Learn, Train, Fight.
        case event(String)
        case bard
        case practice
        case battle(event: String)  // host the arena or join as a poet
        case arena(event: String)
        case player(code: String)
        /// Discus solo: a throw with no server and no second phone (Events/Discus).
        case discusThrow
        case dev
    }

    /// Events playable on this build (SPEC "The games": a tile that can't run 5 times in a row
    /// stays locked for the demo). A config switch, not code.
    static let liveEvents: Set<String> = ["poetry", "debate", "discus"]

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
        // Back into a live battle after a crash or force-quit: same Keychain identity, so join_room
        // is a reconnect and the poet gets their seat and score back (spacetime/CONTRACT.md).
        if let code = LastBattle.recent()?.code, defaults.bool(forKey: Keys.firstOpenDone) {
            route = .player(code: code)
        }
        // Dev: `-startScreen arena|player|dev|home|first` jumps straight in (smoke tests, the operator).
        switch defaults.string(forKey: "startScreen") {
        case "arena": route = .arena(event: defaults.string(forKey: "event") ?? "poetry")
        case "player": route = .player(code: defaults.string(forKey: "joinCode") ?? "")
        case "dev", "diagnostics": route = .dev
        case "home": route = .home
        case "practice": route = .practice
        case "bard": route = .bard
        case "first": route = .firstOpen
        default: break
        }
    }

    /// F4: the first launch lands on the event menu with the poetry tile already open.
    func finishFirstOpen() {
        defaults.set(true, forKey: Keys.firstOpenDone)
        route = .event("poetry")
    }

    /// Music for the screen we're on (docs/ux-flow.md section 10). The arena's battle music is
    /// ArenaConductor's; a phone in a hall never plays music, since it's a mic.
    func routeChanged() {
        let music = MusicDirector.shared
        switch route {
        case .home, .event, .battle:
            music.play(.hallTheme)
        case .bard, .practice:
            music.play(.trainingAmbience)
        case .player:
            music.stopAll()
        case .arena, .firstOpen, .dev, .discusThrow:
            break
        }
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
