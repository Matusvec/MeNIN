import AVFoundation
import os

/// Everything the app plays: the beat, drum strikes, and Homer's voice, on one engine.
/// Used by the arena in battle, and by the phone in solo modes (where the mic's echo
/// canceller removes the phone's own playback). Times are epoch ms on this device's clock.
final class StageAudio: @unchecked Sendable {
    static let sampleRate = 48_000.0

    private let engine: AVAudioEngine
    private let ownsEngine: Bool
    private let beat = AVAudioPlayerNode()
    private let strike = AVAudioPlayerNode()
    private let voice = AVAudioPlayerNode()
    /// Reveal sounds, round-robin so a knock never waits behind a slam.
    private let sfx = (0..<3).map { _ in AVAudioPlayerNode() }
    private var nextSfx = 0
    private let format = BeatSynth.format(sampleRate: StageAudio.sampleRate)
    private lazy var strikeBuffer = BeatSynth.strike(sampleRate: Self.sampleRate)
    private let voiceLevel = OSAllocatedUnfairLock(initialState: Float(0))

    /// Pass the mic's engine in solo modes so its echo canceller hears what we play.
    init(engine: AVAudioEngine? = nil) {
        self.engine = engine ?? AVAudioEngine()
        ownsEngine = engine == nil
        for node in [beat, strike, voice] + sfx {
            self.engine.attach(node)
            self.engine.connect(node, to: self.engine.mainMixerNode, format: format)
        }
        // Homer's loudness for the scene's instant layer ("the scene reacts to Homer's voice").
        voice.installTap(onBus: 0, bufferSize: 1024, format: format) { [voiceLevel] buffer, _ in
            guard let data = buffer.floatChannelData?[0] else { return }
            let energy = ProsodyAnalyzer.energy(UnsafeBufferPointer(start: data, count: Int(buffer.frameLength)))
            voiceLevel.withLock { $0 = Float(energy) }
        }
    }

    /// The arena only plays; the phone records too. Call before scheduling anything.
    func start(recording: Bool) throws {
        let session = AVAudioSession.sharedInstance()
        if !ownsEngine {
            // The mic owns the session and has started the shared engine.
        } else if recording {
            try AudioSessionConfig.activateForRecording()
        } else {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        }
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
        ([beat, strike, voice] + sfx).forEach { ensurePlaying($0) }
    }

    /// `AVAudioPlayerNode.play()` raises (an uncatchable crash) when the engine isn't running, and
    /// can block the main thread waiting for an IO cycle when it's stopping. Play a node only on a
    /// running engine (restarting it once if an interruption stopped it), and only when it isn't
    /// already playing; stopping never re-plays (field crashes on Matus's phone, Sat 12:12 and 12:55).
    @discardableResult
    private func ensurePlaying(_ node: AVAudioPlayerNode) -> Bool {
        if !engine.isRunning { try? engine.start() }
        guard engine.isRunning else { return false }
        if !node.isPlaying { node.play() }
        return true
    }

    func stop() {
        ([beat, strike, voice] + sfx).forEach { $0.stop() }
        if ownsEngine { engine.stop() }
    }

    // MARK: beat

    /// Schedules the count-in bar and every line of the turn on the beat grid.
    func playBeat(_ clock: BeatClock) {
        beat.stop()
        guard ensurePlaying(beat) else { return }
        let sr = Self.sampleRate
        beat.scheduleBuffer(BeatSynth.countIn(bpm: clock.bpm, sampleRate: sr), at: Self.time(atMs: clock.beatAtMs - clock.barMs))
        for n in 0..<clock.lines {
            let buffer = BeatSynth.line(bpm: clock.bpm, barsPerLine: clock.barsPerLine, line: n, sampleRate: sr)
            beat.scheduleBuffer(buffer, at: Self.time(atMs: clock.beatAtMs + clock.lineMs * Double(n)))
        }
    }

    func stopBeat() {
        beat.stop()
    }

    /// A stressed syllable hit the beat (cosmetic on the arena; may lag 100–200 ms).
    func playStrike() {
        guard ensurePlaying(strike) else { return }
        strike.scheduleBuffer(strikeBuffer, at: nil)
    }

    /// A one-shot reveal sound, now.
    func playSound(_ buffer: AVAudioPCMBuffer) {
        let node = sfx[nextSfx]
        nextSfx = (nextSfx + 1) % sfx.count
        guard ensurePlaying(node) else { return }
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
    }

    // MARK: Homer's voice

    /// Queues TTS audio (mono Float32 at `sampleRate`) right after what's already queued.
    func enqueueVoice(_ samples: [Float]) {
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { buffer.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
        guard ensurePlaying(voice) else { return }
        voice.scheduleBuffer(buffer, at: nil)
    }

    /// Pre-rendered voice placed on the clock (a lesson's beat-aligned demo), sample-accurate.
    func scheduleVoice(_ samples: [Float], atMs epochMs: Double) {
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { buffer.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
        guard ensurePlaying(voice) else { return }
        voice.scheduleBuffer(buffer, at: Self.time(atMs: epochMs))
    }

    func stopVoice() {
        voice.stop()
        voiceLevel.withLock { $0 = 0 }
    }

    /// 0...1, Homer's current loudness.
    var homerLevel: Double { Double(voiceLevel.withLock { $0 }) }

    // MARK: clock

    /// An AVAudioTime for a wall-clock instant, via host time.
    static func time(atMs epochMs: Double) -> AVAudioTime {
        let deltaSeconds = (epochMs - Date().timeIntervalSince1970 * 1000) / 1000
        let now = mach_absolute_time()
        let host = deltaSeconds >= 0
            ? now + AVAudioTime.hostTime(forSeconds: deltaSeconds)
            : now - min(now, AVAudioTime.hostTime(forSeconds: -deltaSeconds))
        return AVAudioTime(hostTime: host)
    }
}
