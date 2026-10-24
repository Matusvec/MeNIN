import AVFoundation
import os

/// The soundtrack (SPEC "Music", docs/ux-flow.md section 10, cue list in docs/audio.md).
/// One per device, on its own engine. Cue files live in the bundle as `<cue>.caf|m4a|wav`
/// (any folder); until the composer delivers them every cue is silence, so the files just drop in.
///
/// Rules it enforces: music fades out over about 0.3 s before any mic opens and stays out while it's
/// open; it ducks about 12 dB under a host's voice and comes back about 0.5 s after (except the
/// first-open bed, written to sit under Homer); demo mode keeps the hall theme ducked; the operator
/// can mute everything. Stings start immediately and play once; loops fade out over about 1 s.
@MainActor
final class MusicDirector {
    static let shared = MusicDirector()

    enum Cue: String, CaseIterable, Sendable {
        case hallTheme = "hall-theme"
        case firstOpenBed = "first-open-bed"
        case poetryIntro = "poetry-intro"
        case debateIntro = "debate-intro"
        case discusIntro = "discus-intro"
        case discusWhoosh = "discus-whoosh"
        case discusFanfare = "discus-fanfare"
        case roundEnd = "round-end"
        case champion
        case trainingAmbience = "training-ambience"
        case rematch

        var loops: Bool { self == .hallTheme || self == .trainingAmbience }
        /// Written to sit under Homer at full level, so it doesn't duck.
        var ignoresHostDuck: Bool { self == .firstOpenBed }
    }

    /// Operator mute (⌘M on the arena). Persisted, so a demo restart keeps it.
    var muted: Bool {
        get { UserDefaults.standard.bool(forKey: "musicMuted") }
        set { UserDefaults.standard.set(newValue, forKey: "musicMuted"); retarget() }
    }

    /// Demo mode keeps the hall theme at its ducked level.
    var demoDucked = false { didSet { retarget() } }

    private(set) var loop: Cue?
    private static let duckGain: Float = 0.25  // about −12 dB
    private static let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!

    private let engine = AVAudioEngine()
    private let loopNode = AVAudioPlayerNode()
    private let stingNode = AVAudioPlayerNode()
    private let bus = AVAudioMixerNode()
    private var buffers: [Cue: AVAudioPCMBuffer] = [:]
    private var missing = Set<Cue>()
    private var micOpen = false
    private var hostSpeaking = false
    private var hostRelease: Task<Void, Never>?
    private var ramp: Task<Void, Never>?
    private var lastSting: Cue?
    private let log = Logger(subsystem: "com.matusvec.homer", category: "music")

    private init() {
        engine.attach(bus)
        for node in [loopNode, stingNode] {
            engine.attach(node)
            engine.connect(node, to: bus, format: Self.format)
        }
        engine.connect(bus, to: engine.mainMixerNode, format: Self.format)
        bus.outputVolume = 0
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            // A session change (the mic opening elsewhere) stops the engine; bring the loop back.
            Task { @MainActor in self?.recover() }
        }
    }

    // MARK: cues

    func play(_ cue: Cue) {
        guard let buffer = buffer(for: cue), startEngine() else { return }
        if cue.loops {
            guard loop != cue else { return }
            loop = cue
            loopNode.stop()
            loopNode.scheduleBuffer(buffer, at: nil, options: .loops)
            loopNode.play()
        } else {
            lastSting = cue
            stingNode.stop()
            stingNode.scheduleBuffer(buffer, at: nil) { [weak self] in
                Task { @MainActor in if self?.lastSting == cue { self?.lastSting = nil; self?.retarget() } }
            }
            stingNode.play()
        }
        retarget()
    }

    /// Ends the current loop with a fade (about 1 s).
    func stopLoop(fade seconds: Double = 1) {
        guard loop != nil else { return }
        loop = nil
        let node = loopNode
        rampTo(0, over: seconds) { [weak self] in
            node.stop()
            self?.retarget()
        }
    }

    func stopAll() {
        loop = nil
        lastSting = nil
        loopNode.stop()
        stingNode.stop()
        bus.outputVolume = 0
    }

    // MARK: rules

    /// Any mic in the room opening or closing (a poet's turn, a lesson try, first open's line).
    func setMicOpen(_ open: Bool) {
        guard open != micOpen else { return }
        micOpen = open
        retarget(over: open ? 0.3 : 0.6)
    }

    /// Homer or Socrates speaking. Music comes back about 0.5 s after he stops.
    func setHostSpeaking(_ speaking: Bool) {
        hostRelease?.cancel()
        if speaking {
            hostSpeaking = true
            retarget(over: 0.15)
        } else if hostSpeaking {
            hostRelease = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                self?.hostSpeaking = false
                self?.retarget(over: 0.5)
            }
        }
    }

    private var targetGain: Float {
        if muted || micOpen { return 0 }
        let playing = lastSting ?? loop
        guard let playing else { return 0 }
        if hostSpeaking && !playing.ignoresHostDuck { return Self.duckGain }
        if demoDucked && playing == .hallTheme { return Self.duckGain }
        return 1
    }

    private func retarget(over seconds: Double = 0.3) {
        rampTo(targetGain, over: seconds)
    }

    // MARK: plumbing

    private func rampTo(_ gain: Float, over seconds: Double, then done: (() -> Void)? = nil) {
        ramp?.cancel()
        let start = bus.outputVolume
        let steps = max(1, Int(seconds / 0.03))
        ramp = Task { [weak self] in
            for i in 1...steps {
                guard !Task.isCancelled, let self else { return }
                self.bus.outputVolume = start + (gain - start) * Float(i) / Float(steps)
                try? await Task.sleep(for: .milliseconds(30))
            }
            done?()
        }
    }

    @discardableResult
    private func startEngine() -> Bool {
        if engine.isRunning { return true }
        do {
            engine.prepare()
            try engine.start()
            return true
        } catch {
            log.error("music engine failed to start: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func recover() {
        guard let cue = loop else { return }
        loop = nil
        play(cue)
    }

    private func buffer(for cue: Cue) -> AVAudioPCMBuffer? {
        if let cached = buffers[cue] { return cached }
        if missing.contains(cue) { return nil }
        let url = ["caf", "m4a", "wav"].lazy.compactMap { Bundle.main.url(forResource: cue.rawValue, withExtension: $0) }.first
        guard let url, let file = try? AVAudioFile(forReading: url) else {
            missing.insert(cue)  // placeholder silence until the composer's file lands
            log.info("music cue \(cue.rawValue, privacy: .public) has no file yet")
            return nil
        }
        guard let converted = Self.read(file) else { return nil }
        buffers[cue] = converted
        return converted
    }

    /// Reads a whole file into the bus format (48 kHz stereo float), converting if needed.
    private static func read(_ file: AVAudioFile) -> AVAudioPCMBuffer? {
        let source = file.processingFormat
        guard let input = AVAudioPCMBuffer(pcmFormat: source, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: input)) != nil else { return nil }
        if source == format { return input }
        guard let converter = AVAudioConverter(from: source, to: format) else { return nil }
        let capacity = AVAudioFrameCount(Double(input.frameLength) * format.sampleRate / source.sampleRate) + 1024
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        var fed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if fed {
                status.pointee = .endOfStream
                return nil
            }
            fed = true
            status.pointee = .haveData
            return input
        }
        return error == nil ? output : nil
    }
}
