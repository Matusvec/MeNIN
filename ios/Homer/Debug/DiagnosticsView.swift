import Metal
import SwiftUI

/// Checks that the mic and Metal work on this device (iPhone, iPad, or a Mac running
/// the app as "Designed for iPad"). Dev only.
struct DiagnosticsView: View {
    @State private var mic = MicProsody()
    private let gpu = MTLCreateSystemDefaultDevice()

    var body: some View {
        List {
            Section("Microphone") {
                Toggle("Mic on", isOn: Binding(
                    get: { mic.isRunning },
                    set: { on in
                        if on { Task { await mic.start() } } else { mic.stop() }
                    }
                ))
                Text(String(format: "Energy %.2f", mic.prosody.energy)).monospacedDigit()
                ProgressView(value: mic.prosody.energy)
                Text(mic.prosody.pitch.map { "Pitch \(Int($0)) Hz" } ?? "Pitch: unvoiced")
                    .monospacedDigit()
                if let error = mic.error {
                    Text(error).foregroundStyle(.red)
                }
            }
            Section("Metal") {
                Text(gpu.map { "GPU: \($0.name)" } ?? "No Metal device")
                MetalCheckView()
                    .frame(height: 120)
                    .listRowInsets(EdgeInsets())
            }
            Section("Device") {
                Text(ProcessInfo.processInfo.isiOSAppOnMac ? "Running on Mac (Designed for iPad)" : UIDevice.current.model)
                Text("iOS \(UIDevice.current.systemVersion)")
            }
        }
        .navigationTitle("Diagnostics")
        .task {
            // Dev: launch with `-autoMic YES` to start the mic without a tap.
            if UserDefaults.standard.bool(forKey: "autoMic") { await mic.start() }
        }
        .onDisappear { mic.stop() }
    }
}
