import SwiftUI
import UIKit

/// The thumb on the discus. Release is the thumb lifting, never motion alone (SPEC "The games").
enum DiscusHold: Equatable {
    /// `at` is seconds of system uptime (`UITouch.timestamp`), the clock Core Motion stamps too.
    case down(at: TimeInterval)
    case lift(at: TimeInterval)
    /// The system took the touch (a call, Control Center, the view went away). Never a throw.
    case cancel
}

/// A transparent touch surface laid over the art lead's discus (DiscusPhoneView's `holdPad`).
/// UIKit rather than a SwiftUI gesture, because a drag gesture never reports a cancel. It
/// follows one touch only: a second finger can't start or end a throw.
struct DiscusHoldPad: UIViewRepresentable {
    var onEvent: (DiscusHold) -> Void

    func makeUIView(context: Context) -> PadView {
        let view = PadView()
        view.onEvent = onEvent
        return view
    }

    func updateUIView(_ view: PadView, context: Context) {
        view.onEvent = onEvent
    }

    static func dismantleUIView(_ view: PadView, coordinator: ()) {
        view.cancelIfHeld()
    }

    final class PadView: UIView {
        var onEvent: ((DiscusHold) -> Void)?
        private weak var held: UITouch?

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isMultipleTouchEnabled = false
            isExclusiveTouch = true
        }

        required init?(coder: NSCoder) { fatalError("not used") }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard held == nil, let touch = touches.first else { return }
            held = touch
            onEvent?(.down(at: touch.timestamp))
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = held, touches.contains(touch) else { return }
            held = nil
            onEvent?(.lift(at: touch.timestamp))
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = held, touches.contains(touch) else { return }
            held = nil
            onEvent?(.cancel)
        }

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            if newWindow == nil { cancelIfHeld() }
        }

        func cancelIfHeld() {
            guard held != nil else { return }
            held = nil
            onEvent?(.cancel)
        }
    }
}
