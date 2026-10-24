import AVFoundation
import Foundation
import Observation

/// One device that both plays and listens: Bard lessons (and the shape Practice uses).
/// The mic and everything played (the beat, Homer) share one AVAudioEngine with voice
/// processing, so the echo canceller keeps the device's own sound out of the verse.
///
/// `perform` plays the beat with no mic (Homer's demo); `record` counts in, plays the beat and
/// listens for `lines` lines, flushing STT at each line boundary so lines follow the bars.
@Observable
@MainActor
final class SoloVoiceTurn {
    private(set) var clock: BeatClock?
    private(set) var hits: UInt32 = 0
    private(set) var hitMarks: [BeatWord] = []
    /// Every stressed peak of the last try, in ms from beat 1 (on or off the beat).
    private(set) var onsetsMs: [Double] = []
    private(set) var listening = false
    /// Set when voice is unavailable; the screen then offers typing (dev fallback).
    private(set) var voiceNote: String?
    var typed = ""
    /// Observed: the live transcript the screen shows is built from these.
    private var finals = ""
    private var partial = ""
    var transcript: String { voiceNote == nil ? finals + partial : typed }
    var level: Double { micProsody.prosody.energy }

    let homer: HomerVoice
    let bpm: Double
    let barsPerLine: Int

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let mic: MicEngine
    @ObservationIgnored private let micProsody: MicProsody
    @ObservationIgnored private let stage: StageAudio
    @ObservationIgnored private let haptics = BeatHaptics()
    @ObservationIgnored private let agent: AgentClient?
    @ObservationIgnored private let scene: SceneDriver
    @ObservationIgnored private var stt: CartesiaSTT?
    @ObservationIgnored private var sttTask: Task<Void, Never>?
    @ObservationIgnored private var flushWaiters: [CheckedContinuation<Void, Never>] = []
    @ObservationIgnored private var pendingLineBreaks = 0
    @ObservationIgnored private var started = false
    @ObservationIgnored private var gate = StressGate()

    init(agent: AgentClient?, scene: SceneDriver, bpm: Double = 80, barsPerLine: Int = 2) {
        self.agent = agent
        self.scene = scene
        self.bpm = bpm
        self.barsPerLine = barsPerLine
        mic = MicEngine(engine: engine)
        micProsody = MicProsody(engine: mic)
        stage = StageAudio(engine: engine)
        homer = HomerVoice(audio: stage, agent: agent, role: .solo)
    }

    /// Mic (muted), stage and haptics up on the shared engine. Safe to call again.
    func start() async {
        guard !started else { return }
        started = true
        mic.onOnset = { [weak self] onset in Task { @MainActor in self?.handle(onset) } }
        micProsody.onProsody = { [scene] p in scene.prosody = p }
        mic.muted = true
        await micProsody.start(voiceProcessing: MicEngine.echoCancelSolo)
        if let error = micProsody.error { voiceNote = error }
        try? await Task.detached { [stage] in try stage.start(recording: true) }.value
        haptics.prepare()
    }

    func stop() {
        closeSTT()
        stage.stopBeat()
        haptics.stop()
        homer.silence()
        micProsody.onProsody = nil
        micProsody.stop()
        engine.stop()
        scene.prosody = .silent
        started = false
        listening = false
    }

    /// The beat for `lines` lines after a one-bar count-in, mic muted (Homer performs over it).
    /// Returns the grid so the caller can place lines on downbeats.
    func perform(lines: Int) -> BeatClock {
        let clock = makeClock(lines: lines)
        self.clock = clock
        hitMarks = []
        mic.muted = true
        stage.playBeat(clock)
        return clock
    }

    /// Homer's pre-rendered, beat-aligned demo on the same clock as the beat.
    func playVoice(_ samples: [Float], atMs: Double) {
        stage.scheduleVoice(samples, atMs: atMs)
    }

    /// Count-in, the beat, and the open mic for `lines` lines. Returns the transcript (one line
    /// per row) once the last rest bar ends or `finishNow()` is called.
    func record(lines: Int, keyterms: [String]) async -> String {
        finals = ""
        partial = ""
        typed = ""
        hits = 0
        hitMarks = []
        onsetsMs = []
        gate.reset()
        pendingLineBreaks = 0
        await openSTT(keyterms: keyterms)

        let clock = makeClock(lines: lines)
        self.clock = clock
        stage.playBeat(clock)
        haptics.play(clock)
        MusicDirector.shared.setMicOpen(true)
        mic.muted = false
        listening = true

        for n in 0..<lines {
            let boundary = clock.beatAtMs + clock.lineMs * Double(n + 1)
            while listening, Date().timeIntervalSince1970 * 1000 < boundary {
                try? await Task.sleep(for: .milliseconds(50))
            }
            guard listening else { break }
            pendingLineBreaks += 1
            stt?.finalize()
        }
        listening = false
        mic.muted = true
        MusicDirector.shared.setMicOpen(false)
        stt?.finalize()
        await waitForFlush(timeoutMs: 1500)
        closeSTT()
        haptics.stop()
        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Done tapped: end the try at once.
    func finishNow() {
        listening = false
        stage.stopBeat()
    }

    // MARK: plumbing

    private func makeClock(lines: Int) -> BeatClock {
        let bar = BeatClock(beatAtMs: 0, bpm: bpm, barsPerLine: barsPerLine, lines: lines).barMs
        return BeatClock(beatAtMs: Date().timeIntervalSince1970 * 1000 + bar + 250, bpm: bpm, barsPerLine: barsPerLine, lines: lines)
    }

    private func openSTT(keyterms: [String]) async {
        guard stt == nil else { return }
        guard voiceNote == nil || voiceNote?.hasPrefix("Voice") == true else { return }
        if let agent, let token = try? await agent.voiceToken(.init(role: .solo)), token.stt != nil {
            voiceNote = nil
            let stt = CartesiaSTT(token: token, keyterms: keyterms)
            self.stt = stt
            stt.start()
            sttTask = Task { [weak self] in
                for await event in stt.events { self?.handle(event) }
            }
            mic.onPCM = { [weak stt] chunk in stt?.send(chunk) }
        } else {
            voiceNote = "Voice is offline here, so type your lines."
        }
    }

    private func closeSTT() {
        mic.onPCM = nil
        sttTask?.cancel()
        sttTask = nil
        stt?.close()
        stt = nil
    }

    private func handle(_ event: CartesiaSTT.Event) {
        switch event {
        case .partial(let text):
            partial = text
        case .final(let text, _):
            finals += text
            partial = ""
        case .flushed:
            if pendingLineBreaks > 0 {
                pendingLineBreaks -= 1
                if !finals.isEmpty, !finals.hasSuffix("\n") { finals = finals.trimmingCharacters(in: .whitespaces) + "\n" }
            }
            flushWaiters.forEach { $0.resume() }
            flushWaiters.removeAll()
        case .error(let message):
            if listening { voiceNote = "Voice dropped (\(message)), so type the rest." }
        case .closed:
            break
        }
    }

    private func handle(_ onset: MicEngine.Onset) {
        guard listening, let clock else { return }
        let t = onset.epochMs - StressGate.heardLatencyMs - clock.beatAtMs  // as heard, on the beat's timeline
        switch gate.judge(onset, on: clock) {
        case .unstressed:
            break
        case .hit:
            onsetsMs.append(t)
            hits += 1
            hitMarks.append(BeatWord(text: "", t: t, stressed: true, onBeat: true))
            haptics.hit()
        case .offBeat:
            onsetsMs.append(t)
            hitMarks.append(BeatWord(text: "", t: t, stressed: true, onBeat: false))
        }
    }

    private func waitForFlush(timeoutMs: Int) async {
        guard stt != nil else { return }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in await withCheckedContinuation { self.flushWaiters.append($0) } }
            group.addTask { try? await Task.sleep(for: .milliseconds(timeoutMs)) }
            await group.next()
            group.cancelAll()
            self.flushWaiters.forEach { $0.resume() }
            self.flushWaiters.removeAll()
        }
    }
}
