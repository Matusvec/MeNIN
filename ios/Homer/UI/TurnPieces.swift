import SwiftUI

// Pieces of the turn that sit around the beat lane: the line to answer (P7),
// a played card turning over onto the arena (P8), and the phone's mic controls.

// MARK: - Answer line (P7)

/// During your turn, the previous poet's best line stays pinned as the thing
/// you answer. For the first poet of a round, pass the theme instead.
struct AnswerLineView: View {
    let line: String
    /// Whose line it is; nil when `line` is the round's theme.
    var poet: String? = nil

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(alignment: .top, spacing: Metrics.s3 * k) {
            Capsule().fill(Palette.accent).frame(width: 3 * k)
            VStack(alignment: .leading, spacing: Metrics.s1 * k) {
                Text(poet.map { "Answer \($0)" } ?? "The theme").tracked(10 * k, color: Palette.accent)
                Text(poet == nil ? line : "“\(line)”")
                    .font(Typeface.display(21, on: stage, italic: poet != nil))
                    .displayLeading(21 * k, 1.15)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Metrics.s4 * k)
        .padding(.vertical, Metrics.s3 * k)
        .paper(Palette.paper, radius: Metrics.radiusM * k)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Card reveal (P8)

/// When a poet speaks a formula from their private hand, the card turns over
/// onto the arena for everyone to see. Appears face down and flips on appear.
struct RevealedCardView: View {
    let card: FormulaCard
    var poet: String? = nil
    /// Fired once, on the frame the card lands face up: the flip cue.
    var onLand: (() -> Void)? = nil

    @State private var thrown = false
    @State private var faceUp = false
    @State private var lit = 0
    @Environment(\.stage) private var stage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s2 * k) {
            if let poet {
                Text("\(poet) plays").chip(10 * k, fill: Palette.gold, color: Palette.ink)
                    .opacity(faceUp ? 1 : 0)
                    .scaleEffect(faceUp ? 1 : 0.6)
            }
            ZStack {
                CardBack()
                    .opacity(faceUp ? 0 : 1)
                FormulaCardView(card: FormulaCard(id: card.id, text: card.text, kind: card.kind, used: false))
                    .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
                    .opacity(faceUp ? 1 : 0)
            }
            .frame(width: 280 * k)
            .rotation3DEffect(.degrees(faceUp ? 180 : 0), axis: (0, 1, 0), perspective: 0.4)
            // It lights up as it lands: a gold rim stamps out from the card and a flat gold flash fades off its face.
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: Metrics.radiusS * k, style: .continuous).fill(Palette.gold)
                        .keyframeAnimator(initialValue: 0.0, trigger: lit) { flash, o in flash.opacity(o) } keyframes: { _ in
                            MoveKeyframe(0.55)
                            CubicKeyframe(0, duration: 0.6)
                        }
                    RoundedRectangle(cornerRadius: Metrics.radiusS * k, style: .continuous)
                        .strokeBorder(Palette.gold, lineWidth: 4 * k)
                        .keyframeAnimator(initialValue: Rim(), trigger: lit) { rim, v in
                            rim.scaleEffect(v.scale).opacity(v.opacity)
                        } keyframes: { _ in
                            KeyframeTrack(\.scale) {
                                MoveKeyframe(1)
                                CubicKeyframe(1.14, duration: 0.55)
                            }
                            KeyframeTrack(\.opacity) {
                                MoveKeyframe(1)
                                LinearKeyframe(1, duration: 0.15)
                                LinearKeyframe(0, duration: 0.4)
                            }
                        }
                }
                .allowsHitTesting(false)
            }
            .scaleEffect(faceUp ? 1 : 0.88)
            .rotationEffect(.degrees(thrown ? 0 : 14))
            .offset(x: thrown ? 0 : 160 * k, y: thrown ? 0 : 90 * k)
            .opacity(thrown ? 1 : 0)
        }
        .task {
            guard !faceUp else { return }
            if reduceMotion {
                thrown = true; faceUp = true
                onLand?()
                return
            }
            // Thrown onto the table, then turned over.
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { thrown = true }
            try? await Task.sleep(for: .seconds(0.22))
            withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) { faceUp = true }
            try? await Task.sleep(for: .seconds(0.24))
            lit += 1
            onLand?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(poet.map { "\($0) plays " } ?? "")\(card.text)")
    }

    private struct Rim {
        var scale = 1.0
        var opacity = 0.0
    }
}

/// The back of a card: MeNIN's meander border on ink.
private struct CardBack: View {
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        ZStack {
            RoundedRectangle(cornerRadius: Metrics.radiusS * k, style: .continuous).fill(Palette.wine)
            MeanderBand()
                .stroke(Palette.gold.opacity(0.8), lineWidth: 2 * k)
                .frame(height: 12 * k)
                .padding(.horizontal, Metrics.s3 * k)
            Text("MeNIN").font(Typeface.display(16, on: stage, weight: 500)).foregroundStyle(Palette.cream)
                .padding(.horizontal, Metrics.s2 * k)
                .background(Palette.wine)
        }
        .frame(height: 76 * k)
        .paper(Palette.wine, radius: Metrics.radiusS * k)
    }
}

/// A Greek key (meander) running left to right, one unit per `height`.
struct MeanderBand: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let h = rect.height
        let u = h / 4
        var x = rect.minX
        p.move(to: CGPoint(x: x, y: rect.maxY))
        while x + 4 * u <= rect.maxX {
            p.addLine(to: CGPoint(x: x, y: rect.minY))
            p.addLine(to: CGPoint(x: x + 3 * u, y: rect.minY))
            p.addLine(to: CGPoint(x: x + 3 * u, y: rect.minY + 2 * u))
            p.addLine(to: CGPoint(x: x + u, y: rect.minY + 2 * u))
            p.addLine(to: CGPoint(x: x + u, y: rect.minY + u))
            p.addLine(to: CGPoint(x: x + 2 * u, y: rect.minY + u))
            p.move(to: CGPoint(x: x + 3 * u, y: rect.minY + 2 * u))
            p.addLine(to: CGPoint(x: x + 3 * u, y: rect.maxY))
            p.addLine(to: CGPoint(x: x + 4 * u, y: rect.maxY))
            x += 4 * u
        }
        return p
    }
}

// MARK: - Mic

/// The phone's mic level: a row of paper bars that rise with your voice.
struct MicLevelView: View {
    /// 0...1, from Prosody.energy.
    let level: Double
    var bars: Int = 18
    var tint: Color = Palette.accent

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(alignment: .center, spacing: 3 * k) {
            ForEach(0..<bars, id: \.self) { i in
                let center = abs(Double(i) - Double(bars - 1) / 2) / (Double(bars) / 2)
                let h = max(0.12, min(1, level * 1.25 - center * 0.55))
                Capsule()
                    .fill(level > 0.05 ? tint : Palette.ink3.opacity(0.35))
                    .frame(width: 5 * k, height: 44 * k * h)
            }
        }
        .frame(height: 44 * k)
        .animation(.easeOut(duration: 0.08), value: level)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mic level")
        .accessibilityValue("\(Int(level * 100)) percent")
    }
}

/// Push-to-talk: the lower half of the phone is one big target. Hold to open
/// the mic, let go to close it. The level meter lives inside it.
struct HoldToTalkView: View {
    @Binding var isHeld: Bool
    var level: Double = 0
    var enabled: Bool = true
    /// The phone's thumb zone: the meter and the one line, no small print.
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? Metrics.s2 : Metrics.s4) {
            MicLevelView(level: isHeld ? level : 0, tint: isHeld ? Palette.onHero : Palette.accent)
            Text(isHeld ? "Speaking" : "Hold to speak")
                .font(Typeface.display(compact ? 28 : 32))
                .foregroundStyle(isHeld ? Palette.onHero : Palette.ink)
            if !compact {
                Text(isHeld ? "Let go when the line is done" : "Homer hears you only while you hold")
                    .font(Typeface.text(14, weight: 500))
                    .foregroundStyle(isHeld ? Palette.onHero2 : Palette.ink2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paper(isHeld ? Palette.hero : Palette.paper, radius: Metrics.radiusL)
        .scaleEffect(isHeld ? 0.98 : 1)
        .opacity(enabled ? 1 : 0.5)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if enabled, !isHeld { isHeld = true } }
                .onEnded { _ in isHeld = false }
        )
        .animation(Motion.stamp, value: isHeld)
        .sensoryFeedback(.impact(weight: .medium), trigger: isHeld)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isHeld ? "Speaking" : "Hold to speak")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    @Previewable @State var held = false
    VStack(spacing: 20) {
        AnswerLineView(line: "The whale-road swallowed his sails", poet: "Sunya")
        RevealedCardView(card: FormulaCard(id: "1", text: "grey-eyed Athena", kind: .epithet, used: true), poet: "Matus")
        HoldToTalkView(isHeld: $held, level: 0.6).frame(height: 260)
    }
    .padding()
    .background(Palette.sea)
}

// MARK: - Waiting

/// What the app is waiting for, in plain words. Every wait longer than about
/// 300 ms shows one of these, so a screen never looks frozen (SPEC).
enum WaitState: Equatable, Sendable {
    case openingHall
    case findingRoom(String)
    /// The connection dropped: shown as a strip over the last screen, which stays put.
    case reconnecting
    case dealing
    case choosingTopic
    /// Someone else's verse is live: their name, with their words as `WaitLine.detail`.
    case speaking(String)
    case weighing
    /// A lesson try going back to Homer.
    case listeningBack
    case settingLesson
    /// Homer's voice is warming up.
    case warmingUp
    case custom(String)

    func text(host: String = "Homer") -> String {
        switch self {
        case .openingHall: "Opening the hall…"
        case .findingRoom(let code): "Finding room \(code)…"
        case .reconnecting: "Reconnecting…"
        case .dealing: "\(host) is dealing your hand…"
        case .choosingTopic: "\(host) is choosing the topic…"
        case .speaking(let name): "\(name) is speaking"
        case .weighing: host == "Socrates" ? "Socrates is weighing your argument…" : "\(host) is weighing your verse…"
        case .listeningBack: "\(host) is listening back…"
        case .settingLesson: "\(host) is setting the lesson…"
        case .warmingUp: "\(host) is about to speak"
        case .custom(let text): text
        }
    }

    /// A live turn, not a load: the mark is the live dot.
    var isLive: Bool {
        if case .speaking = self { return true }
        return false
    }
}

/// The wait made visible, matte: three beats lighting in turn on the drum's
/// tempo (the beat pads' language), or the lyre breathing on it. Never a
/// system spinner. Holds still under Reduce Motion.
struct LoadingMark: View {
    enum Style { case beat, lyre }

    var style: Style = .beat
    var bpm: Double = 80
    var tint: Color = Palette.accent
    /// The dot (or a tenth of the lyre's height), before stage scaling.
    var size: CGFloat = 9

    @Environment(\.stage) private var stage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let s = size * stage.scale
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
            let beats = context.date.timeIntervalSinceReferenceDate * bpm / 60
            let into = beats - beats.rounded(.down)   // 0...1 through the current beat
            let strike = exp(-into * 5)                // the drum's attack and decay
            switch style {
            case .beat:
                HStack(spacing: s * 0.7) {
                    ForEach(0..<3, id: \.self) { i in
                        let lit = Int(beats) % 3 == i
                        Circle()
                            .fill(lit ? tint : Palette.ink3.opacity(0.35))
                            .frame(width: s, height: s)
                            .scaleEffect(lit && !reduceMotion ? 1 + 0.35 * strike : 1)
                    }
                }
            case .lyre:
                LyreShape()
                    .stroke(tint, style: StrokeStyle(lineWidth: s * 0.7, lineCap: .round, lineJoin: .round))
                    .frame(width: s * 8.4, height: s * 10)
                    .scaleEffect(reduceMotion ? 1 : 1 + 0.06 * strike)
                    .opacity(reduceMotion ? 1 : 0.7 + 0.3 * strike)
            }
        }
        .accessibilityHidden(true)
    }
}

/// One wait in plain words with its mark: a card in the middle of a screen,
/// or a slim strip (`compact`) over a screen that stays as it was.
struct WaitLine: View {
    let state: WaitState
    var host: String = "Homer"
    /// A second line: the live words for `.speaking`, or "Still trying" on a long reconnect.
    var detail: String? = nil
    var compact: Bool = false

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(alignment: .center, spacing: Metrics.s3 * k) {
            if state.isLive {
                LiveDot(size: 10 * k)
            } else {
                LoadingMark(size: compact ? 7 : 9)
            }
            VStack(alignment: .leading, spacing: 2 * k) {
                Text(state.text(host: host))
                    .font(compact ? Typeface.text(14 * k, weight: 600) : Typeface.display(20, on: stage))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(Typeface.display(compact ? 15 : 18, on: stage, italic: true))
                        .foregroundStyle(Palette.ink2)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: compact ? nil : .infinity, alignment: .leading)
        }
        .padding(.horizontal, (compact ? Metrics.s4 : Metrics.s5) * k)
        .padding(.vertical, (compact ? Metrics.s2 : Metrics.s4) * k)
        .paper(Palette.paper, radius: (compact ? 100 : Metrics.radiusL) * k, lifted: !compact)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(state.text(host: host) + (detail.map { ". \($0)" } ?? ""))
    }
}

/// Launch, and any wait with nothing else to show: the wordmark, the lyre on
/// the beat, and what's happening.
struct LoadingScreen: View {
    var state: WaitState = .openingHall
    var host: String = "Homer"

    var body: some View {
        VStack(spacing: Metrics.s5) {
            WordmarkView(size: 30)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .paper(Palette.paper, radius: 100, lifted: false)
            LoadingMark(style: .lyre, size: 7)
                .padding(Metrics.s5)
                .background(Palette.paper, in: Circle())
            Text(state.text(host: host))
                .font(Typeface.display(22))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, Metrics.s4)
                .padding(.vertical, Metrics.s2)
                .paper(Palette.paper, radius: 100, lifted: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sceneBehind()
        .accessibilityElement(children: .combine)
    }
}
