import Foundation
import Observation

/// First launch (SPEC "First open"): Homer speaks before any menu, you give him one line
/// with the scene answering your voice, and he hands you on. Both lines are fixed; their
/// audio is pre-rendered and bundled when available (`Resources/Voice/<key>.caf`), else
/// spoken live, else captioned. No Claude call. Also replayed by the demo operator.
@Observable
@MainActor
final class FirstOpenFlow {
    enum Beat: Equatable { case homerSpeaks, listening, homerAnswers, done }

    /// Caption text shows mēnin; the TTS text spells it the way Homer should say it.
    static let opening = HomerVoice.Script(
        key: "first-open-1",
        caption: "The first word of Western literature is mēnin. Rage. Give me one line.",
        speech: "The first word of Western literature is MAY-nin. Rage. Give me one line."
    )
    static let answer = HomerVoice.Script(
        key: "first-open-2",
        caption: "Good. Now let me show you how I did it.",
        speech: "Good. Now let me show you how I did it."
    )

    private(set) var beat = Beat.homerSpeaks {
        didSet { print("FIRSTOPEN beat \(beat)") }
    }
    /// What Homer heard (live STT when available).
    private(set) var heard = ""
    var level: Double { mic.prosody.energy }

    let homer: HomerVoice
    private let mic = MicProsody()
    private let audio = StageAudio()
    private let scene: SceneDriver
    @ObservationIgnored private var task: Task<Void, Never>?

    init(scene: SceneDriver, agent: AgentClient?) {
        self.scene = scene
        homer = HomerVoice(audio: audio, agent: agent, role: .solo)
    }

    /// Runs the whole first open; returns when Homer has handed over.
    func run() async {
        print("FIRSTOPEN start")
        do { try audio.start(recording: true) } catch { print("FIRSTOPEN audio \(error)") }
        print("FIRSTOPEN audio up")
        beat = .homerSpeaks
        await homer.say(Self.opening)

        beat = .listening
        mic.onProsody = { [scene] p in scene.prosody = p }
        await mic.start(voiceProcessing: true)
        await listenForOneLine()
        mic.onProsody = nil
        mic.stop()
        scene.prosody = .silent

        beat = .homerAnswers
        await homer.say(Self.answer)
        beat = .done
        audio.stop()
    }

    /// Up to 8 s: wait for the voice to start, then for about 1.2 s of quiet after it.
    private func listenForOneLine() async {
        let start = Date()
        var spoke = false
        var quietSince: Date?
        while Date().timeIntervalSince(start) < 8 {
            let loud = mic.prosody.energy > 0.3
            if loud {
                spoke = true
                quietSince = nil
            } else if spoke {
                quietSince = quietSince ?? Date()
                if Date().timeIntervalSince(quietSince!) > 1.2 { return }
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
}
