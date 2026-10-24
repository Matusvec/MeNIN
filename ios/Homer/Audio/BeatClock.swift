import Foundation

/// The turn's beat grid in local epoch ms (spacetime/CONTRACT.md, "Timing and rates").
/// Beat k of line n falls at beat_at + (4·barsPerLine·n + k)·60/bpm. With rests
/// (barsPerLine 2), bar 2n is the speaking bar and bar 2n+1 the rest.
struct BeatClock: Equatable, Sendable {
    var beatAtMs: Double  // beat 1 of line 1, already shifted onto this device's clock
    var bpm: Double
    var barsPerLine: Int
    var lines: Int

    static let beatsPerBar = 4
    /// An onset this close to a speaking beat counts as a hit. Generous for first-timers on a
    /// laptop or phone mic; one hit per pulse (StressGate) keeps it from being gamed.
    static let hitWindowMs = 140.0

    var beatMs: Double { 60_000 / bpm }
    var barMs: Double { beatMs * Double(Self.beatsPerBar) }
    var lineMs: Double { barMs * Double(barsPerLine) }
    var endMs: Double { beatAtMs + lineMs * Double(lines) }

    /// The server's clock reads `offsetMs` behind this device's: local = server + offset.
    /// Estimated once when the turn flips to speaking: offset = local receive time − started_at.
    static func offset(localReceiveMs: Double, serverStartedAtMs: Double) -> Double {
        localReceiveMs - serverStartedAtMs
    }

    init(beatAtMs: Double, bpm: Double, barsPerLine: Int, lines: Int) {
        self.beatAtMs = beatAtMs
        self.bpm = max(bpm, 1)
        self.barsPerLine = max(barsPerLine, 1)
        self.lines = max(lines, 1)
    }

    struct Beat: Equatable, Sendable {
        var line: Int
        var index: Int  // 0..<4 within the bar
        var speaking: Bool  // false in the rest bar
        var ms: Double
    }

    /// Every beat of the turn, count-in excluded, speaking and rest bars alike.
    var beats: [Beat] {
        (0..<lines).flatMap { line in
            (0..<(Self.beatsPerBar * barsPerLine)).map { k in
                Beat(line: line, index: k % Self.beatsPerBar, speaking: k < Self.beatsPerBar,
                     ms: beatAtMs + lineMs * Double(line) + beatMs * Double(k))
            }
        }
    }

    /// The speaking beat an onset lands on, if any.
    func hit(atMs t: Double) -> Beat? {
        guard t >= beatAtMs - Self.hitWindowMs, t <= endMs else { return nil }
        let line = Int(((t - beatAtMs) / lineMs).rounded(.down))
        guard line >= -1, line < lines else { return nil }
        let k = ((t - beatAtMs - lineMs * Double(line)) / beatMs).rounded()
        guard k >= 0, k < Double(Self.beatsPerBar) || (line == -1 && k == Double(Self.beatsPerBar * barsPerLine)) else { return nil }
        let (hitLine, hitK) = line == -1 ? (0, 0) : (line, Int(k))
        guard hitK < Self.beatsPerBar else { return nil }
        let ms = beatAtMs + lineMs * Double(hitLine) + beatMs * Double(hitK)
        return abs(t - ms) <= Self.hitWindowMs ? Beat(line: hitLine, index: hitK, speaking: true, ms: ms) : nil
    }

    /// The line being spoken or rested at `t` (0-based), clamped to the turn.
    func line(atMs t: Double) -> Int {
        min(lines - 1, max(0, Int(((t - beatAtMs) / lineMs).rounded(.down))))
    }

    func isSpeakingBar(atMs t: Double) -> Bool {
        guard t >= beatAtMs, t < endMs else { return false }
        return (t - beatAtMs).truncatingRemainder(dividingBy: lineMs) < barMs
    }
}
