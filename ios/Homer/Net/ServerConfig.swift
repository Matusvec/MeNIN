import Foundation

/// Where the app finds SpacetimeDB and the agent service. Switchable at runtime from the
/// Dev screen (or with `-server local|maincloud`, `-spacetimeURL`, `-database`, `-agentURL`
/// launch arguments), since both move between the laptop and the cloud.
enum ServerConfig {
    struct Preset: Hashable, Identifiable {
        let id: String
        let url: String
        let database: String
        /// Empty until the service is deployed for this preset.
        let agent: String
    }

    // TODO: the agent's public URL once builder's deploy (Vultr + Cloudflare Tunnel) is up.
    static let maincloud = Preset(id: "maincloud", url: "https://maincloud.spacetimedb.com", database: "homer-calhacks", agent: "")
    /// The laptop that hosts SpacetimeDB and the agent in dev. Simulators and the Mac app
    /// (Designed for iPad) reach it on 127.0.0.1; a phone needs its LAN address.
    static var local: Preset {
        let onThisMac: Bool = {
            #if targetEnvironment(simulator)
            true
            #else
            ProcessInfo.processInfo.isiOSAppOnMac
            #endif
        }()
        let host = onThisMac ? "127.0.0.1" : "10.0.16.91"  // Matus's Mac on the local network (dev)
        return Preset(id: "local", url: "http://\(host):3000", database: "homer", agent: "http://\(host):8000")
    }

    static var presets: [Preset] { [maincloud, local] }

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

    /// Nil when this preset has no agent yet; agent-backed features then say so.
    static var agent: URL? {
        let raw = defaults.string(forKey: "agentURL").flatMap { $0.isEmpty ? nil : $0 } ?? preset.agent
        return raw.isEmpty ? nil : URL(string: raw)
    }

    static var database: String {
        defaults.string(forKey: "database").flatMap { $0.isEmpty ? nil : $0 } ?? preset.database
    }
}
