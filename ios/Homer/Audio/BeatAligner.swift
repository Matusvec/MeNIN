import Foundation

/// Puts a rendered line on the beat: cut between stressed words and re-spaced so stress k lands
/// on pulse k. Only the gaps change; the words keep Homer's delivery. The live twin of the
/// lesson-demo baker (the bundled lesson-*-demo.caf files), used for the stitched song.
enum BeatAligner {
    struct Placed {
        var samples: [Float]
        /// Seconds of audio before pulse 1 (the pickup); schedule the line this early.
        var leadSeconds: Double
        /// How late the latest stress lands, in seconds (0 when every stress fits).
        var worstLate: Double
    }

    static let headFade = 0.015
    static let tailFade = 0.11
    static let tailOverlap = 0.08  // a held vowel may run this far under the next pickup

    /// `stressAt` holds each stress's time in the rendered audio, in order (at most one per pulse).
    /// Chunk k runs from the word after stress k−1 through stress k's word.
    static func place(_ audio: [Float], sampleRate sr: Double, words: [CartesiaTTS.Word],
                      stresses: [(word: Int, at: Double)], beatSeconds beat: Double) -> Placed? {
        guard !stresses.isEmpty, !words.isEmpty, !audio.isEmpty else { return nil }
        let duration = Double(audio.count) / sr
        let n = stresses.count
        var bounds: [(a: Double, b: Double)] = []
        for k in 0..<n {
            let w = stresses[k].word
            let first = k == 0 ? 0 : min(stresses[k - 1].word + 1, w)
            let last = k == n - 1 ? words.count - 1 : w
            bounds.append((max(0, words[first].start - 0.03), min(duration, words[last].end + (k == n - 1 ? 0.08 : 0.04))))
        }
        var chunks: [(start: Double, samples: [Float])] = []
        var end = -Double.infinity
        var worst = 0.0
        for k in 0..<n {
            var (a, b) = bounds[k]
            let stress = stresses[k].at
            let lead = stress - a
            if k < n - 1 {
                let nextLead = stresses[k + 1].at - bounds[k + 1].a
                b = min(b, stress + beat - nextLead + tailOverlap)
            }
            b = max(b, stress + 0.12)
            let lo = max(0, Int(a * sr)), hi = min(audio.count, Int(b * sr))
            guard hi > lo else { continue }
            var seg = Array(audio[lo..<hi])
            fade(&seg, sampleRate: sr)
            let pulse = Double(k) * beat
            let start = max(pulse - lead, end - tailOverlap)
            worst = max(worst, start + lead - pulse)
            chunks.append((start, seg))
            end = start + Double(seg.count) / sr
        }
        guard let origin = chunks.map(\.start).min() else { return nil }
        let total = chunks.map { $0.start - origin + Double($0.samples.count) / sr }.max() ?? 0
        var mix = [Float](repeating: 0, count: Int(total * sr) + 1)
        for chunk in chunks {
            let at = Int((chunk.start - origin) * sr)
            for (i, s) in chunk.samples.enumerated() where at + i < mix.count { mix[at + i] += s }
        }
        return Placed(samples: mix, leadSeconds: -origin, worstLate: worst)
    }

    /// Where each scanned beat word's stress sits in the rendered audio. Scanned and spoken words
    /// are matched letter by letter, so "wine-dark" lines up whether either side splits it.
    static func stresses(scanned: [VerseScan.Word], spoken: [CartesiaTTS.Word], maxPulses: Int = 4) -> [(word: Int, at: Double)] {
        // Every letter of the spoken words, with its time and its spoken word.
        var letters: [(t: Double, word: Int)] = []
        for (i, w) in spoken.enumerated() {
            let chars = normalized(w.text)
            for (j, _) in chars.enumerated() {
                letters.append((w.start + (w.end - w.start) * Double(j) / Double(max(1, chars.count)), i))
            }
        }
        var out: [(word: Int, at: Double)] = []
        var cursor = 0
        for w in scanned {
            let count = normalized(w.text).count
            guard count > 0 else { continue }
            defer { cursor += count }
            guard w.beat == true, cursor < letters.count else { continue }
            let first = letters[cursor]
            let word = spoken[first.word]
            // The stressed syllable's vowel: just into the word (first-syllable stress, the usual case).
            let at = first.t + min(0.07, 0.25 * max(0, word.end - first.t))
            if out.last?.word == first.word { continue }  // one pulse per spoken word
            out.append((first.word, at))
            if out.count == maxPulses { break }
        }
        return out
    }

    private static func normalized(_ s: String) -> [Character] {
        Array(s.lowercased().filter { $0.isLetter || $0.isNumber })
    }

    private static func fade(_ seg: inout [Float], sampleRate sr: Double) {
        let inN = min(Int(headFade * sr), seg.count / 4)
        for i in 0..<inN { let g = Float(i) / Float(inN); seg[i] *= g * g }
        let outN = min(Int(tailFade * sr), seg.count / 3)
        for i in 0..<outN { seg[seg.count - 1 - i] *= Float(i) / Float(outN) }
    }
}
