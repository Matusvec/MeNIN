import SwiftUI
import UIKit

/// Per-screen orientation on iPhone: the arena is landscape (backup arena on a phone),
/// player screens are portrait. iPad and Mac ignore it and stay free.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}

@MainActor
enum OrientationLock {
    static var mask: UIInterfaceOrientationMask = UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all

    static func set(_ newMask: UIInterfaceOrientationMask) {
        guard UIDevice.current.userInterfaceIdiom == .phone, !ProcessInfo.processInfo.isiOSAppOnMac else { return }
        mask = newMask
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: newMask))
        }
    }
}

extension View {
    /// Locks the orientation while this view is on screen, then returns to portrait.
    func orientationLock(_ mask: UIInterfaceOrientationMask) -> some View {
        onAppear { OrientationLock.set(mask) }
            .onDisappear { OrientationLock.set(.portrait) }
    }
}
