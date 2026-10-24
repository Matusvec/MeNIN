import SwiftUI

@main
struct HomerApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        Direction.loadSaved()  // design direction (art lead) before the first view reads tokens
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
