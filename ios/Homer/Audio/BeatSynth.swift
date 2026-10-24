import AVFoundation

/// Procedural drum-and-lyre beat (SPEC "The turn": a slow drum-and-lyre loop, four beats
/// a bar). Rendered once per turn into buffers, so playback costs nothing per frame.
///   count-in: four rim clicks and a lyre strum on one
///   speaking bar: kick on 1 and 3, soft rim on 2 and 4, ducked so the poet sits on top
///   rest bar: full drums and a four-note lyre phrase, the bar to think in
enum BeatSynth {
    /// Ducking level of the speaking bar relative to the rest bar (SPEC: the arena ducks its drum).
    static let speakingGain: Float = 0.35

    /// Dorian-ish lyre notes (Hz): D3 F3 G3 A3 C4 D4.
    static let scale: [Double] = [146.83, 174.61, 196.00, 220.00, 261.63, 293.66]

    static func format(sampleRate: Double) -> AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }

    /// One bar of four rim clicks plus a strum on one.
    static func countIn(bpm: Double, sampleRate: Double) -> AVAudioPCMBuffer {
        render(beats: 4, bpm: bpm, sampleRate: sampleRate) { mix, beatFrames in
            for k in 0..<4 { add(rim(sampleRate, gain: k == 0 ? 0.9 : 0.6), into: &mix, at: k * beatFrames) }
            for (i, note) in [scale[0], scale[2], scale[4]].enumerated() {
                add(pluck(note, sampleRate: sampleRate, seconds: 1.6, gain: 0.25), into: &mix, at: i * Int(0.03 * sampleRate))
            }
        }
    }

    /// One line: a speaking bar, then (with barsPerLine 2) a rest bar. `line` varies the lyre phrase.
    static func line(bpm: Double, barsPerLine: Int, line: Int, sampleRate: Double) -> AVAudioPCMBuffer {
        render(beats: 4 * barsPerLine, bpm: bpm, sampleRate: sampleRate) { mix, beatFrames in
            for bar in 0..<barsPerLine {
                let speaking = bar == 0
                let g: Float = speaking ? speakingGain : 1
                let start = bar * 4 * beatFrames
                add(kick(sampleRate, gain: 0.9 * g), into: &mix, at: start)
                add(rim(sampleRate, gain: 0.45 * g), into: &mix, at: start + beatFrames)
                add(kick(sampleRate, gain: 0.7 * g), into: &mix, at: start + 2 * beatFrames)
                add(rim(sampleRate, gain: 0.45 * g), into: &mix, at: start + 3 * beatFrames)
                if !speaking {
                    // The lyre answers in the rest bar, never under the voice.
                    let phrases = [[0, 2, 4, 3], [5, 4, 2, 1], [0, 3, 4, 2], [4, 5, 3, 0]]
                    for (k, degree) in phrases[line % phrases.count].enumerated() {
                        add(pluck(scale[degree], sampleRate: sampleRate, seconds: 1.4, gain: 0.32), into: &mix, at: start + k * beatFrames)
                    }
                }
            }
        }
    }

    /// The drum strike when a stressed syllable lands on the beat.
    static func strike(sampleRate: Double) -> AVAudioPCMBuffer {
        let k = kick(sampleRate, gain: 1)
        let r = rim(sampleRate, gain: 0.7)
        var mix = [Float](repeating: 0, count: max(k.count, r.count))
        add(k, into: &mix, at: 0)
        add(r, into: &mix, at: 0)
        return buffer(mix, sampleRate: sampleRate)
    }

    // MARK: voices

    /// The composer's recorded hits (docs/audio.md): dry, mono, 48 kHz. When a file is bundled it
    /// replaces the synthesized voice; the app still schedules every hit, so the beat stays procedural.
    private static let noteNames: [Double: String] = [146.83: "lyre-d3", 174.61: "lyre-f3", 196.00: "lyre-g3",
                                                      220.00: "lyre-a3", 261.63: "lyre-c4", 293.66: "lyre-d4"]
    nonisolated(unsafe) private static var samples: [String: [Float]] = [:]
    nonisolated(unsafe) private static var missing = Set<String>()

    private static func sample(_ name: String, sampleRate: Double, gain: Float) -> [Float]? {
        if missing.contains(name) { return nil }
        if samples[name] == nil {
            let url = ["caf", "wav", "m4a"].lazy.compactMap { Bundle.main.url(forResource: name, withExtension: $0) }.first
            guard let url, let file = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false),
                  file.processingFormat.sampleRate == sampleRate,
                  let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
                  (try? file.read(into: buffer)) != nil, let data = buffer.floatChannelData?[0] else {
                missing.insert(name)
                return nil
            }
            samples[name] = Array(UnsafeBufferPointer(start: data, count: Int(buffer.frameLength)))
        }
        return samples[name].map { $0.map { $0 * gain } }
    }

    static func kick(_ sr: Double, gain: Float) -> [Float] {
        if let recorded = sample("drum-kick", sampleRate: sr, gain: gain) { return recorded }
        let n = Int(0.4 * sr)
        var phase = 0.0
        return (0..<n).map { i in
            let t = Double(i) / sr
            let f = 45 + 75 * exp(-t / 0.035)  // pitch drops from 120 Hz to 45 Hz
            phase += 2 * .pi * f / sr
            return gain * Float(sin(phase) * exp(-t / 0.16))
        }
    }

    static func rim(_ sr: Double, gain: Float) -> [Float] {
        if let recorded = sample("drum-rim", sampleRate: sr, gain: gain) { return recorded }
        let n = Int(0.09 * sr)
        var rng = SplitMix(seed: 7)
        var lowpassed: Float = 0
        return (0..<n).map { i in
            let t = Double(i) / sr
            let noise = Float.random(in: -1...1, using: &rng)
            lowpassed += 0.35 * (noise - lowpassed)
            let body = Float(sin(2 * .pi * 420 * t)) * 0.6
            return gain * (noise - lowpassed + body) * Float(exp(-t / 0.018))
        }
    }

    /// Karplus-Strong plucked string.
    static func pluck(_ hz: Double, sampleRate sr: Double, seconds: Double, gain: Float) -> [Float] {
        if let name = noteNames[hz], let recorded = sample(name, sampleRate: sr, gain: gain) { return recorded }
        let period = max(2, Int(sr / hz))
        var rng = SplitMix(seed: UInt64(hz * 100))
        var line = (0..<period).map { _ in Float.random(in: -1...1, using: &rng) }
        let n = Int(seconds * sr)
        var out = [Float](repeating: 0, count: n)
        var idx = 0
        for i in 0..<n {
            let next = (idx + 1) % period
            let sample = line[idx]
            line[idx] = 0.996 * 0.5 * (sample + line[next])
            out[i] = gain * sample * Float(min(1, Double(n - i) / (0.05 * sr)))  // fade the tail
            idx = next
        }
        return out
    }

    // MARK: plumbing

    private static func render(beats: Int, bpm: Double, sampleRate: Double, fill: (inout [Float], Int) -> Void) -> AVAudioPCMBuffer {
        let beatFrames = Int(60 / bpm * sampleRate)
        var mix = [Float](repeating: 0, count: beats * beatFrames)
        fill(&mix, beatFrames)
        // Soft clip so stacked hits never wrap.
        for i in mix.indices { mix[i] = tanh(mix[i]) }
        return buffer(mix, sampleRate: sampleRate)
    }

    private static func add(_ sound: [Float], into mix: inout [Float], at offset: Int) {
        guard offset < mix.count else { return }
        for i in 0..<min(sound.count, mix.count - offset) { mix[offset + i] += sound[i] }
    }

    private static func buffer(_ samples: [Float], sampleRate: Double) -> AVAudioPCMBuffer {
        let buf = AVAudioPCMBuffer(pcmFormat: format(sampleRate: sampleRate), frameCapacity: AVAudioFrameCount(samples.count))!
        buf.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { buf.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
        return buf
    }
}

/// Deterministic noise, so every render of the beat sounds the same.
struct SplitMix: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
