import MetalKit
import SwiftUI

/// The full-screen scene. Put it behind everything; it ignores the safe area.
/// Emotion arrives about every 1.5 s and prosody at 15-60 Hz; the scene does
/// its own smoothing and transitions.
///
/// Live use: `SceneView(driver:)`, and write to the driver. Nothing re-renders.
/// Previews and the lab: `SceneView(emotion:prosody:)`.
struct SceneView: View {
    private let driver: SceneDriver?
    private let emotion: EmotionWeights
    private let prosody: Prosody
    @State private var ownDriver = SceneDriver()

    init(driver: SceneDriver) {
        self.driver = driver
        emotion = EmotionWeights()
        prosody = .silent
    }

    init(emotion: EmotionWeights, prosody: Prosody = .silent) {
        driver = nil
        self.emotion = emotion
        self.prosody = prosody
    }

    var body: some View {
        SceneMetalView(driver: driver ?? ownDriver)
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .onChange(of: emotion, initial: true) { if driver == nil { ownDriver.emotion = emotion } }
            .onChange(of: prosody, initial: true) { if driver == nil { ownDriver.prosody = prosody } }
    }
}

private struct SceneMetalView: UIViewRepresentable {
    let driver: SceneDriver

    final class Coordinator {
        var renderer: SceneRenderer?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        // The page color, shown for the instant before the first frame.
        view.backgroundColor = UIColor(Palette.page)
        view.isOpaque = true
        if let renderer = SceneRenderer(view: view, driver: driver) {
            view.delegate = renderer
            context.coordinator.renderer = renderer
        }
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.driver = driver
    }
}

#Preview("Rest") {
    SceneView(emotion: EmotionWeights())
}

#Preview("Grief and awe") {
    SceneView(emotion: EmotionWeights([.grief: 0.55, .awe: 0.45]), prosody: Prosody(energy: 0.4, pitch: 180))
}
