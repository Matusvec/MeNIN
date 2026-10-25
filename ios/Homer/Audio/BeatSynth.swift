import AVFoundation

/// Procedural beat for the Bard (SPEC "The turn": four beats a bar). Rendered once per turn into
/// buffers, so playback costs nothing per frame. Matus, Sat 10:07 PM: "don't make the Bard a
/// beatbox". So no kick, no rim, no backbeat: the rhapsode's staff on a stone floor, one low woody
/// strike on every beat, the downbeat a touch heavier.
///   count-in: four staff strikes and a lyre strum on one
///   speaking bar: the staff on every beat, ducked so the poet sits on top
///   rest bar: full drums, the bar to think in (no lyre phrase: Matus, Sat 9:40 PM, "get rid of
///   the ding dong between lines, keep the beats")
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
            for k in 0..<4 { add(staff(sampleRate, gain: k == 0 ? 0.55 : 0.4), into: &mix, at: k * beatFrames) }
            for (i, note) in [scale[0], scale[2], scale[4]].enumerated() {
                add(pluck(note, sampleRate: sampleRate, seconds: 1.6, gain: 0.25), into: &mix, at: i * Int(0.03 * sampleRate))
            }
        }
    }

    /// One line: a speaking bar, then (with barsPerLine 2) a rest bar of drums. `line` is unused
    /// since the rest bar's lyre phrase went; kept so callers and the timing don't change.
    static func line(bpm: Double, barsPerLine: Int, line: Int, sampleRate: Double) -> AVAudioPCMBuffer {
        render(beats: 4 * barsPerLine, bpm: bpm, sampleRate: sampleRate) { mix, beatFrames in
            for bar in 0..<barsPerLine {
                let speaking = bar == 0
                let g: Float = speaking ? speakingGain : 1
                let start = bar * 4 * beatFrames
                for k in 0..<4 {
                    add(staff(sampleRate, gain: (k == 0 ? 0.55 : 0.4) * g), into: &mix, at: start + k * beatFrames)
                }
            }
        }
    }

    /// The strike when a stressed syllable lands on the beat: the staff, struck harder.
    static func strike(sampleRate: Double) -> AVAudioPCMBuffer {
        buffer(staff(sampleRate, gain: 0.8), sampleRate: sampleRate)
    }

    /// The arena's reveal sounds (ArenaCue), procedural until the composer's files land.
    static func cue(_ cue: ArenaCue, sampleRate sr: Double) -> AVAudioPCMBuffer {
        var mix: [Float]
        switch cue {
        case .slam:  // the entrance slab: a deep thump with a dusty edge
            mix = thump(sr, from: 95, to: 32, seconds: 0.55, decay: 0.22, gain: 1.1)
            add(rim(sr, gain: 0.35), into: &mix, at: 0)
        case .flip:  // a card snapping face up
            mix = noiseTick(sr, seconds: 0.03, decay: 0.006, tone: 2_400, gain: 0.45)
        case .knock(let axis):  // wood, a step higher per axis
            mix = woodKnock(sr, hz: 520 * pow(1.12, Double(axis)), gain: 0.55)
        case .total:  // the heavy knock
            mix = woodKnock(sr, hz: 300, gain: 0.7)
            add(thump(sr, from: 120, to: 50, seconds: 0.3, decay: 0.09, gain: 0.7), into: &mix, at: 0)
        case .carve:  // three chisel taps on stone
            mix = [Float](repeating: 0, count: Int(0.3 * sr))
            for (k, gain) in [Float(0.4), 0.3, 0.35].enumerated() {
                add(noiseTick(sr, seconds: 0.04, decay: 0.008, tone: 3_100 - Double(k) * 250, gain: gain), into: &mix, at: Int(Double(k) * 0.09 * sr))
            }
        case .crown:  // the laurel lands: thump and the drum strike together
            mix = thump(sr, from: 110, to: 38, seconds: 0.7, decay: 0.28, gain: 1)
            add(kick(sr, gain: 0.8), into: &mix, at: 0)
            add(rim(sr, gain: 0.6), into: &mix, at: 0)
        }
        return buffer(mix, sampleRate: sr)
    }

    private static func thump(_ sr: Double, from f0: Double, to f1: Double, seconds: Double, decay: Double, gain: Float) -> [Float] {
        var phase = 0.0
        return (0..<Int(seconds * sr)).map { i in
            let t = Double(i) / sr
            phase += 2 * .pi * (f1 + (f0 - f1) * exp(-t / 0.04)) / sr
            return gain * Float(sin(phase) * exp(-t / decay))
        }
    }

    private static func woodKnock(_ sr: Double, hz: Double, gain: Float) -> [Float] {
        (0..<Int(0.12 * sr)).map { i in
            let t = Double(i) / sr
            let body = sin(2 * .pi * hz * t) + 0.4 * sin(2 * .pi * hz * 2.7 * t) * exp(-t / 0.01)
            return gain * Float(body * exp(-t / 0.028))
        }
    }

    private static func noiseTick(_ sr: Double, seconds: Double, decay: Double, tone: Double, gain: Float) -> [Float] {
        var rng = SplitMix(seed: UInt64(tone))
        var lowpassed: Float = 0
        return (0..<Int(seconds * sr)).map { i in
            let t = Double(i) / sr
            let noise = Float.random(in: -1...1, using: &rng)
            lowpassed += 0.5 * (noise - lowpassed)
            return gain * ((noise - lowpassed) + 0.3 * Float(sin(2 * .pi * tone * t))) * Float(exp(-t / decay))
        }
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

    /// The rhapsode's staff on a stone floor: a low woody thud (a pitch falling 140 → 82 Hz), the
    /// knock of the wood, and a breath of grit where it meets the stone. A recorded
    /// `staff-strike` replaces it when bundled.
    static func staff(_ sr: Double, gain: Float) -> [Float] {
        if let recorded = sample("staff-strike", sampleRate: sr, gain: gain) { return recorded }
        let body = thump(sr, from: 140, to: 82, seconds: 0.32, decay: 0.075, gain: 0.85)
        var mix = [Float](repeating: 0, count: body.count)
        add(body, into: &mix, at: 0)
        add(woodKnock(sr, hz: 310, gain: 0.3), into: &mix, at: 0)
        add(noiseTick(sr, seconds: 0.03, decay: 0.004, tone: 900, gain: 0.1), into: &mix, at: 0)
        return mix.map { $0 * gain }
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
