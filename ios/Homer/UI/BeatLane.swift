import SwiftUI

/// The beat lane. Four beats a bar, one line per speaking bar, then a rest bar
/// (docs/ux-flow.md T3). Every word lands as a tick at the moment it was said;
/// a stressed word on a beat stamps that beat gold, the drum strike made visible.
///
/// The pulses are computed from `lane.startedAt` and `lane.bpm`, the same clock
/// the phone's beat haptics use, so the taps and the pads land together.
///
/// PROVISIONAL with `BeatLane`: `barsPerLine` (speaking bar + rest bar) is not in the contract yet.
struct BeatLaneView: View {
    enum Style {
        /// Every line, with ticks and words. The arena and solo modes.
        case full
        /// Just the current bar: four big pads that pulse with the haptics. The speaker's phone.
        case pulse
    }

    let lane: BeatLane
    var style: Style = .full
    var barsPerLine: Int = 2
    /// False once the turn settles: the lane holds still with its hits marked.
    var running: Bool = true

    @Environment(\.stage) private var stage

    var body: some View {
        // 30 Hz is plenty for the pulse on a phone; at a ProMotion phone's 120 it costs every frame.
        TimelineView(.animation(minimumInterval: stage.isArena ? nil : 1.0 / 30, paused: !running)) { context in
            let clock = LaneClock(lane: lane, barsPerLine: barsPerLine,
                                  now: running ? context.date.timeIntervalSince1970 * 1000 : .infinity)
            switch style {
            case .full: full(clock)
            case .pulse: pulse(clock)
            }
        }
        // Every hit lands with the drum strike: the lane takes a gold wash and a small jolt.
        .modifier(StrikeFlash(trigger: lane.words.filter { $0.stressed && $0.onBeat }.count,
                              radius: Metrics.radiusL * stage.scale))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Beat lane")
    }

    // MARK: - Full

    private func full(_ c: LaneClock) -> some View {
        let k = stage.scale
        return VStack(alignment: .leading, spacing: Metrics.s4 * k) {
            HStack(alignment: .firstTextBaseline) {
                Text(c.elapsed < 0 ? "Count in" : "The beat").tracked(10 * k, color: Palette.ink2)
                Spacer()
                barsLeft(c, size: 10 * k)
            }
            ForEach(0..<lane.lines, id: \.self) { line in
                row(line, c)
                    .opacity(c.elapsed < 0 || line == c.line ? 1 : (line < c.line ? 0.72 : 0.38))
            }
        }
        .padding(Metrics.s5 * k)
        .paper(Palette.paper, radius: Metrics.radiusL * k)
    }

    private func row(_ line: Int, _ c: LaneClock) -> some View {
        let k = stage.scale
        let words = c.words(in: line)
        return VStack(alignment: .leading, spacing: Metrics.s2 * k) {
            GeometryReader { geo in
                let w = geo.size.width
                let cell = w / CGFloat(lane.beatsPerLine)
                let mid = geo.size.height / 2
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Palette.line)
                        .frame(width: w, height: 1)
                        .offset(y: mid)

                    // The pause in the middle of the line.
                    Text("/")
                        .font(Typeface.display(18, on: stage))
                        .foregroundStyle(Palette.ink3)
                        .position(x: cell * CGFloat(lane.beatsPerLine) / 2, y: mid)

                    ForEach(words.indices, id: \.self) { i in
                        let word = words[i]
                        let x = (c.beatPosition(word) + 0.5) * cell
                        if word.stressed && !word.onBeat {
                            // A stress that missed the beat: a hollow vermilion mark, so a miss reads as a miss.
                            Capsule()
                                .strokeBorder(Palette.vermilion, lineWidth: 1.5 * k)
                                .frame(width: 7 * k, height: 22 * k)
                                .position(x: x, y: mid)
                        } else {
                            Capsule()
                                .fill(word.stressed ? Palette.gold : Palette.ink3)
                                .frame(width: 2.5 * k, height: (word.stressed ? 22 : 10) * k)
                                .position(x: x, y: mid)
                        }
                    }

                    ForEach(0..<lane.beatsPerLine, id: \.self) { beat in
                        BeatPad(state: c.padState(line: line, beat: beat), pulse: c.pulse(line: line, beat: beat),
                                size: 16 * k)
                            .position(x: (CGFloat(beat) + 0.5) * cell, y: mid)
                    }

                    if line == c.line, c.inSpeakingBar {
                        Rectangle().fill(Palette.vermilion)
                            .frame(width: 2 * k, height: 34 * k)
                            .position(x: (c.beatInBar + 0.5) * cell, y: mid)
                    }
                }
            }
            .frame(height: 34 * k)

            Text(lineText(words))
                .font(Typeface.display(19, on: stage))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: 22 * k, alignment: .leading)
        }
    }

    private func lineText(_ words: [BeatWord]) -> AttributedString {
        var out = AttributedString()
        for (i, word) in words.enumerated() {
            if i > 0 { out += AttributedString(" ") }
            var a = AttributedString(word.text)
            // Hits are gold; a stress that missed the beat is vermilion and underlined.
            a.foregroundColor = word.stressed ? (word.onBeat ? Palette.goldDeep : Palette.vermilion) : Palette.ink2
            if word.stressed && !word.onBeat { a.underlineStyle = .single }
            out += a
        }
        return out
    }

    // MARK: - Pulse

    private func pulse(_ c: LaneClock) -> some View {
        let k = stage.scale
        // In a rest bar the pads already show the next line, so the poet sees what's coming.
        let line = max(0, min(lane.lines - 1, c.inSpeakingBar || c.elapsed < 0 ? c.line : c.line + 1))
        return VStack(spacing: Metrics.s4 * k) {
            HStack(alignment: .firstTextBaseline) {
                Text(c.elapsed < 0 ? "Count in" : (c.inSpeakingBar ? "Line \(line + 1) of \(lane.lines)" : "Breathe"))
                    .tracked(10 * k, color: Palette.ink2)
                Spacer()
                barsLeft(c, size: 11 * k)
            }
            HStack(spacing: 0) {
                ForEach(0..<lane.beatsPerLine, id: \.self) { beat in
                    BeatPad(state: c.padState(line: line, beat: beat), pulse: c.pulse(line: line, beat: beat), size: 44 * k)
                        .frame(maxWidth: .infinity)
                    if beat == lane.beatsPerLine / 2 - 1 {
                        Text("/").font(Typeface.display(30, on: stage)).foregroundStyle(Palette.ink3)
                    }
                }
            }
            .opacity(c.inSpeakingBar || c.elapsed < 0 ? 1 : 0.6)
        }
        .padding(Metrics.s5 * k)
        .paper(Palette.paper, radius: Metrics.radiusL * k)
    }

    private func barsLeft(_ c: LaneClock, size: CGFloat) -> some View {
        let left = c.barsLeft
        return Text(left == 1 ? "1 bar left" : "\(left) bars left")
            .font(Typeface.numeral(size + 1, weight: 650))
            .foregroundStyle(left <= 2 && c.elapsed >= 0 ? Palette.vermilion : Palette.ink2)
            .contentTransition(.numericText(countsDown: true))
    }
}

// MARK: - Pad

private struct BeatPad: View {
    enum State { case ahead, now, hit, passed }

    let state: State
    /// 0...1, peaks at the beat's onset and decays: the visual twin of the haptic tap.
    let pulse: Double
    let size: CGFloat

    @State private var strikes = 0

    var body: some View {
        ZStack {
            switch state {
            case .ahead:
                Circle().strokeBorder(Palette.ink3.opacity(0.6), lineWidth: max(1.2, size * 0.07))
            case .now:
                Circle().fill(Palette.accent)
            case .hit:
                Circle().fill(Palette.gold)
            case .passed:
                Circle().fill(Palette.paper3).padding(size * 0.28)
            }
        }
        .frame(width: size, height: size)
        // The strike: a gold ring thrown off the pad as it turns gold.
        .overlay {
            Circle().strokeBorder(Palette.gold, lineWidth: max(1.5, size * 0.1))
                .keyframeAnimator(initialValue: Ring(), trigger: strikes) { ring, v in
                    ring.scaleEffect(v.scale).opacity(v.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        MoveKeyframe(1)
                        CubicKeyframe(2.9, duration: 0.5)
                    }
                    KeyframeTrack(\.opacity) {
                        MoveKeyframe(0.95)
                        LinearKeyframe(0, duration: 0.5)
                    }
                }
        }
        .scaleEffect(1 + 0.45 * pulse)
        .keyframeAnimator(initialValue: 1.0, trigger: strikes) { pad, s in
            pad.scaleEffect(s)
        } keyframes: { _ in
            MoveKeyframe(1.0)
            SpringKeyframe(1.55, duration: 0.08, spring: .snappy)
            SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
        }
        .animation(Motion.stamp, value: state)
        .onChange(of: state) { _, new in
            if new == .hit { strikes += 1 }
        }
    }

    private struct Ring {
        var scale = 1.0
        var opacity = 0.0
    }
}

/// A flat gold wash over a card and a small jolt, once per `trigger` increase.
/// The beat lane's half of the drum strike. Matte: a flat tint, no glow.
private struct StrikeFlash: ViewModifier {
    let trigger: Int
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Palette.gold)
                    .allowsHitTesting(false)
                    .keyframeAnimator(initialValue: 0.0, trigger: trigger) { wash, o in
                        wash.opacity(o)
                    } keyframes: { _ in
                        MoveKeyframe(0.0)
                        LinearKeyframe(0.24, duration: 0.04)
                        CubicKeyframe(0, duration: 0.38)
                    }
            }
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { card, y in
                card.offset(y: y)
            } keyframes: { _ in
                MoveKeyframe(0.0)
                SpringKeyframe(4, duration: 0.05, spring: .snappy)
                SpringKeyframe(0, duration: 0.3, spring: .bouncy)
            }
    }
}

// MARK: - Clock

/// Turns the lane's wall-clock timing into lines, bars and beats.
private struct LaneClock {
    let lane: BeatLane
    let barsPerLine: Int
    let elapsed: Double // ms since beat 1; negative during the count-in

    init(lane: BeatLane, barsPerLine: Int, now: Double) {
        self.lane = lane
        self.barsPerLine = barsPerLine
        // A settled lane (now = .infinity) sits just past its last bar.
        let end = 60_000 / max(lane.bpm, 1) * Double(lane.beatsPerLine * barsPerLine * lane.lines)
        elapsed = now.isFinite ? now - lane.startedAt : end + 1
    }

    var beatMs: Double { 60_000 / max(lane.bpm, 1) }
    var barMs: Double { beatMs * Double(lane.beatsPerLine) }
    var lineMs: Double { barMs * Double(barsPerLine) }
    var totalBars: Int { lane.lines * barsPerLine }

    var bar: Int { elapsed < 0 ? -1 : Int(min(elapsed, lineMs * Double(lane.lines)) / barMs) }
    var line: Int { elapsed < 0 ? 0 : min(lane.lines, Int(elapsed / lineMs)) }
    var inSpeakingBar: Bool { elapsed >= 0 && line < lane.lines && bar % barsPerLine == 0 }
    var beatInBar: CGFloat { CGFloat((elapsed - Double(bar) * barMs) / beatMs) }
    var barsLeft: Int { elapsed < 0 ? totalBars : max(0, totalBars - bar) }

    /// A word said in the last beat before a line starts is a pickup into that
    /// line ("the | WHALE-road"), not the tail of the previous one.
    func lineOf(_ w: BeatWord) -> Int { Int(max(0, w.t + beatMs) / lineMs) }

    func words(in line: Int) -> [BeatWord] {
        lane.words.filter { lineOf($0) == line }.sorted { $0.t < $1.t }
    }

    /// Where a word sits in its line's speaking bar, in beats (0 = beat 1, -1...0 = pickup).
    func beatPosition(_ w: BeatWord) -> CGFloat {
        let within = w.t - Double(lineOf(w)) * lineMs
        return CGFloat(max(-0.45 * beatMs, min(within, barMs * 0.999)) / beatMs)
    }

    func isHit(line: Int, beat: Int) -> Bool {
        words(in: line).contains { $0.stressed && $0.onBeat && Int(beatPosition($0).rounded()) == beat }
    }

    func padState(line l: Int, beat: Int) -> BeatPad.State {
        if isHit(line: l, beat: beat) { return .hit }
        if elapsed < 0 || l > line { return .ahead }
        if l < line { return .passed }
        if !inSpeakingBar { return .passed }
        let current = Int(beatInBar)
        return beat < current ? .passed : (beat == current ? .now : .ahead)
    }

    func pulse(line l: Int, beat: Int) -> Double {
        if elapsed < 0 {
            // The count-in bar ticks through all four pads.
            let into = (elapsed + barMs) / beatMs
            guard into >= 0, Int(into) == beat else { return 0 }
            return exp(-(into - Double(beat)) * 7)
        }
        guard l == line, inSpeakingBar, Int(beatInBar) == beat else { return 0 }
        return exp(-Double(beatInBar - CGFloat(beat)) * 7)
    }
}
