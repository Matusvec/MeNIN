import AVFoundation
import Observation

/// Mic -> Prosody at display rate, for the scene's instant layer.
/// Views read `prosody`; nothing here knows about presentation. Owns a MicEngine,
/// which a turn can also tap for STT audio and onsets.
@Observable
@MainActor
final class MicProsody {
    private(set) var prosody = Prosody.silent
    private(set) var isRunning = false
    private(set) var error: String?

    @ObservationIgnored let engine: MicEngine

    init(engine: MicEngine = MicEngine()) {
        self.engine = engine
    }
    @ObservationIgnored private var poll: Task<Void, Never>?
    /// Also receives each new reading, without a SwiftUI update (e.g. a SceneDriver).
    @ObservationIgnored var onProsody: ((Prosody) -> Void)?

    func start(voiceProcessing: Bool = false) async {
        guard !isRunning else { return }
        error = nil
        #if targetEnvironment(simulator)
        // The iOS 27 simulator can deadlock (then abort) opening the mic input; opt in with -simMic YES.
        guard UserDefaults.standard.bool(forKey: "simMic") else {
            error = "No mic on the simulator (launch with -simMic YES to try)"
            return
        }
        #endif
        guard await AVAudioApplication.requestRecordPermission() else {
            error = "Microphone access is off. Turn it on in Settings > Privacy > Microphone."
            return
        }
        do {
            // Session activation and engine start can block for a while; keep them off the main thread.
            try await Task.detached { [engine] in
                try AudioSessionConfig.activateForRecording()
                try engine.start(voiceProcessing: voiceProcessing)
            }.value
        } catch {
            self.error = "Mic failed to start: \(error.localizedDescription)"
            return
        }
        isRunning = true
        poll = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if let p = self.engine.latestProsody() {
                    self.prosody = p
                    self.onProsody?(p)
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    func stop() {
        poll?.cancel()
        poll = nil
        engine.stop()
        isRunning = false
        prosody = .silent
    }
}
