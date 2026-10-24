import Accelerate

/// Loudness and pitch from one window of mono samples. Pure and thread-safe, so it
/// can run off the audio thread and be unit tested.
/// Port of the web prototype (web/src/audio/micProsody.ts): RMS mapped from dBFS to
/// 0...1, and first-peak autocorrelation pitch over 70...500 Hz.
enum ProsodyAnalyzer {
    static let floorDB: Float = -58
    static let ceilDB: Float = -16
    static let voicedEnergy = 0.15
    static let minPitch: Float = 70
    static let maxPitch: Float = 500

    static func analyze(_ samples: UnsafeBufferPointer<Float>, sampleRate: Double) -> Prosody {
        let e = energy(samples)
        return Prosody(energy: e, pitch: e > voicedEnergy ? pitch(samples, sampleRate: sampleRate) : nil)
    }

    static func energy(_ samples: UnsafeBufferPointer<Float>) -> Double {
        guard !samples.isEmpty else { return 0 }
        let rms = vDSP.rootMeanSquare(samples)
        let db = 20 * log10(rms + 1e-9)
        return Double(min(1, max(0, (db - floorDB) / (ceilDB - floorDB))))
    }

    static func pitch(_ samples: UnsafeBufferPointer<Float>, sampleRate: Double) -> Double? {
        guard let base = samples.baseAddress else { return nil }
        let minLag = Int(Float(sampleRate) / maxPitch)
        let maxLag = min(samples.count / 2, Int(Float(sampleRate) / minPitch))
        let n = samples.count - maxLag
        guard minLag < maxLag, n > 0 else { return nil }
        // Every other sample: half the cost, same answer for voice.
        let stride = 2
        let count = vDSP_Length((n + stride - 1) / stride)

        var energy0: Float = 0
        vDSP_dotpr(base, stride, base, stride, &energy0, count)
        guard energy0 > 0 else { return nil }

        var bestLag = -1
        var best: Float = 0
        var prev: Float = 1
        var rising = false
        for lag in minLag...maxLag {
            var c: Float = 0
            var e1: Float = 0
            vDSP_dotpr(base, stride, base + lag, stride, &c, count)
            vDSP_dotpr(base + lag, stride, base + lag, stride, &e1, count)
            let r = c / (energy0 * e1 + 1e-12).squareRoot()
            // Take the first strong peak, not the global max, to avoid octave errors.
            if r > prev {
                rising = true
            } else if rising && prev > 0.6 {
                bestLag = lag - 1
                best = prev
                break
            }
            if r > best {
                best = r
                bestLag = lag
            }
            prev = r
        }
        guard bestLag > 0, best >= 0.55 else { return nil }
        return sampleRate / Double(bestLag)
    }
}
