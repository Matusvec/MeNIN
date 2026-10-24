import AVFoundation
import os

/// The one mic pipeline. The audio thread only copies and does cheap per-hop math;
/// consumers are called on `deliveryQueue`.
///   - prosody: latest 2048-sample window, read on demand (scene instant layer, set_prosody)
///   - pcm16:   16 kHz mono s16le in 100 ms chunks (Cartesia STT, docs/voice.md)
///   - onsets:  syllable-like energy rises with epoch-ms timestamps (beat hits, haptics, freeze rescue)
/// `muted` (push-to-talk released) turns PCM into zeros instead of dropping it, so STT word
/// times stay on the same clock as the turn, and suppresses onsets.
final class MicEngine: @unchecked Sendable {
    struct Onset: Sendable, Equatable {
        var epochMs: Double
        var energy: Double  // 0...1, same scale as Prosody.energy
    }

    static let sttSampleRate = 16_000.0
    static let chunkFrames = 1_600  // 100 ms at 16 kHz

    var onPCM: (@Sendable (Data) -> Void)?
    var onOnset: (@Sendable (Onset) -> Void)?
    let deliveryQueue = DispatchQueue(label: "com.matusvec.homer.mic")

    /// Shared with StageAudio in solo modes: the echo canceller only removes what its own
    /// engine plays, so the phone's beat and Homer's voice must come out of this engine.
    let engine: AVAudioEngine
    private let ownsEngine: Bool
    private let state = OSAllocatedUnfairLock(initialState: State())
    private var converter: AVAudioConverter?
    private var inputSampleRate = 48_000.0

    private struct State {
        var ring = Ring(capacity: 2048)
        var muted = false
        var pending = Data()
        var detector = OnsetDetector()
    }

    init(engine: AVAudioEngine? = nil) {
        self.engine = engine ?? AVAudioEngine()
        ownsEngine = engine == nil
    }

    var muted: Bool {
        get { state.withLock { $0.muted } }
        set { state.withLock { $0.muted = newValue } }
    }

    /// `voiceProcessing` turns on the system echo canceller, so the phone's own playback
    /// (the beat, Homer's voice in solo modes) stays out of the mic.
    func start(voiceProcessing: Bool = false) throws {
        let input = engine.inputNode
        if voiceProcessing != input.isVoiceProcessingEnabled {
            try input.setVoiceProcessingEnabled(voiceProcessing)
        }
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw NSError(domain: "Homer.Mic", code: 1, userInfo: [NSLocalizedDescriptionKey: "No microphone input"])
        }
        inputSampleRate = format.sampleRate
        let mono = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: format.sampleRate, channels: 1, interleaved: false)!
        let target = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Self.sttSampleRate, channels: 1, interleaved: true)!
        converter = AVAudioConverter(from: mono, to: target)
        state.withLock { $0.detector = OnsetDetector(sampleRate: format.sampleRate) }

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.process(buffer, time: time, mono: mono, target: target)
        }
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        if ownsEngine { engine.stop() }
        state.withLock { $0 = State() }
    }

    /// Nil until a full window has arrived since the last read.
    func latestProsody() -> Prosody? {
        let (window, muted) = state.withLock { ($0.ring.takeIfFresh(), $0.muted) }
        guard let window else { return nil }
        if muted { return .silent }
        return window.withUnsafeBufferPointer { ProsodyAnalyzer.analyze($0, sampleRate: inputSampleRate) }
    }

    // MARK: audio thread

    private func process(_ buffer: AVAudioPCMBuffer, time: AVAudioTime, mono: AVAudioFormat, target: AVAudioFormat) {
        guard let channel = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)
        let samples = UnsafeBufferPointer(start: channel, count: frames)
        let bufferEpochMs = Self.epochMs(of: time)

        var onsets: [Onset] = []
        let muted = state.withLock { s -> Bool in
            s.ring.append(samples)
            if !s.muted {
                onsets = s.detector.feed(samples, bufferEpochMs: bufferEpochMs)
            } else {
                s.detector.reset()
            }
            return s.muted
        }

        var chunks: [Data] = []
        if onPCM != nil, let pcm = convert(samples, mono: mono, target: target, muted: muted) {
            chunks = state.withLock { s in
                s.pending.append(pcm)
                var out: [Data] = []
                let size = Self.chunkFrames * 2
                while s.pending.count >= size {
                    out.append(s.pending.prefix(size))
                    s.pending.removeFirst(size)
                }
                return out
            }
        }

        guard !chunks.isEmpty || !onsets.isEmpty else { return }
        let onPCM = onPCM, onOnset = onOnset
        deliveryQueue.async {
            chunks.forEach { onPCM?($0) }
            onsets.forEach { onOnset?($0) }
        }
    }

    private func convert(_ samples: UnsafeBufferPointer<Float>, mono: AVAudioFormat, target: AVAudioFormat, muted: Bool) -> Data? {
        guard let converter, let source = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: AVAudioFrameCount(samples.count)) else { return nil }
        source.frameLength = AVAudioFrameCount(samples.count)
        if muted {
            memset(source.floatChannelData![0], 0, samples.count * MemoryLayout<Float>.size)
        } else {
            source.floatChannelData![0].update(from: samples.baseAddress!, count: samples.count)
        }
        let capacity = AVAudioFrameCount(Double(samples.count) * target.sampleRate / mono.sampleRate) + 32
        guard let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return nil }
        var supplied = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if supplied {
                status.pointee = .noDataNow
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return source
        }
        guard error == nil, output.frameLength > 0, let data = output.int16ChannelData?[0] else { return nil }
        return Data(bytes: data, count: Int(output.frameLength) * 2)
    }

    /// Wall-clock time of a buffer's first sample, from its host time.
    static func epochMs(of time: AVAudioTime) -> Double {
        let now = Date().timeIntervalSince1970 * 1000
        guard time.isHostTimeValid else { return now }
        let ageSeconds = AVAudioTime.seconds(forHostTime: mach_absolute_time()) - AVAudioTime.seconds(forHostTime: time.hostTime)
        return now - ageSeconds * 1000
    }
}

/// Energy-rise onsets over 10 ms hops: a hop counts when it is well above the quietest hop
/// of the last ~150 ms and loud enough to be voice. Refractory 120 ms, roughly one syllable.
struct OnsetDetector {
    private(set) var sampleRate: Double
    private var hop: Int
    private var carry: [Float] = []
    private var recentDB: [Float] = []
    private var lastOnsetMs = -Double.infinity
    private var hopsSeen = 0
    private var anchorEpochMs: Double?

    static let riseDB: Float = 7
    static let floorEnergy = 0.15
    static let refractoryMs = 120.0
    static let historyHops = 15

    init(sampleRate: Double = 48_000) {
        self.sampleRate = sampleRate
        hop = max(1, Int(sampleRate / 100))
    }

    mutating func reset() {
        carry.removeAll()
        recentDB.removeAll()
        anchorEpochMs = nil
        hopsSeen = 0
    }

    mutating func feed(_ samples: UnsafeBufferPointer<Float>, bufferEpochMs: Double) -> [MicEngine.Onset] {
        // Keep one clock: the first buffer anchors hop times, so jitter in buffer timestamps doesn't move onsets.
        if anchorEpochMs == nil { anchorEpochMs = bufferEpochMs - Double(carry.count) / sampleRate * 1000 }
        carry.append(contentsOf: samples)
        var onsets: [MicEngine.Onset] = []
        var start = 0
        while carry.count - start >= hop {
            let energy = carry[start..<(start + hop)].withUnsafeBufferPointer { ProsodyAnalyzer.energy($0) }
            let db = ProsodyAnalyzer.floorDB + Float(energy) * (ProsodyAnalyzer.ceilDB - ProsodyAnalyzer.floorDB)
            let hopMs = anchorEpochMs! + Double(hopsSeen) * 10
            if let quietest = recentDB.min(), db - quietest >= Self.riseDB, energy >= Self.floorEnergy,
               hopMs - lastOnsetMs >= Self.refractoryMs {
                onsets.append(.init(epochMs: hopMs, energy: energy))
                lastOnsetMs = hopMs
            }
            recentDB.append(db)
            if recentDB.count > Self.historyHops { recentDB.removeFirst() }
            hopsSeen += 1
            start += hop
        }
        carry.removeFirst(start)
        return onsets
    }
}

struct Ring {
    private var buffer: [Float]
    private var head = 0
    private var filled = 0
    private var fresh = false

    init(capacity: Int) {
        buffer = Array(repeating: 0, count: capacity)
    }

    mutating func append(_ samples: UnsafeBufferPointer<Float>) {
        for s in samples {
            buffer[head] = s
            head = (head + 1) % buffer.count
        }
        filled = min(buffer.count, filled + samples.count)
        fresh = true
    }

    mutating func takeIfFresh() -> [Float]? {
        guard fresh, filled == buffer.count else { return nil }
        fresh = false
        return Array(buffer[head...] + buffer[..<head])
    }
}
