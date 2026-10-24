import Foundation

/// Where the app finds SpacetimeDB. Switchable at runtime from the Dev screen (or with
/// `-server local|maincloud`, `-spacetimeURL`, `-database` launch arguments), since the
/// server moves between the laptop and Maincloud.
enum ServerConfig {
    struct Preset: Hashable, Identifiable {
        let id: String
        let url: String
        let database: String
    }

    static let maincloud = Preset(id: "maincloud", url: "https://maincloud.spacetimedb.com", database: "homer-calhacks")
    static let local = Preset(
        id: "local",
        url: {
            #if targetEnvironment(simulator)
            "http://127.0.0.1:3000"
            #else
            "http://10.0.16.91:3000"  // Matus's Mac on the local network (dev)
            #endif
        }(),
        database: "homer"
    )
    static let presets = [maincloud, local]

    /// Simulators default to the laptop; devices (and TestFlight) default to Maincloud.
    static var defaultPreset: Preset {
        #if targetEnvironment(simulator)
        local
        #else
        maincloud
        #endif
    }

    private static let defaults = UserDefaults.standard

    static var preset: Preset {
        get { presets.first { $0.id == defaults.string(forKey: "server") } ?? defaultPreset }
        set { defaults.set(newValue.id, forKey: "server") }
    }

    static var spacetime: URL {
        URL(string: defaults.string(forKey: "spacetimeURL").flatMap { $0.isEmpty ? nil : $0 } ?? preset.url)!
    }

    static var database: String {
        defaults.string(forKey: "database").flatMap { $0.isEmpty ? nil : $0 } ?? preset.database
    }
}
