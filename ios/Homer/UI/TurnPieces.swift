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
                    .font(Typeface.display(21 * k, italic: poet != nil))
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

    @State private var faceUp = false
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s2 * k) {
            if let poet {
                Text("\(poet) plays").chip(10 * k)
                    .opacity(faceUp ? 1 : 0)
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
            .scaleEffect(faceUp ? 1 : 0.9)
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: faceUp)
        .onAppear { faceUp = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(poet.map { "\($0) plays " } ?? "")\(card.text)")
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
            Text("MeNIN").font(Typeface.display(16 * k, weight: 500)).foregroundStyle(Palette.cream)
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

    var body: some View {
        VStack(spacing: Metrics.s4) {
            MicLevelView(level: isHeld ? level : 0, tint: isHeld ? Palette.onHero : Palette.accent)
            Text(isHeld ? "Speaking" : "Hold to speak")
                .font(Typeface.display(32))
                .foregroundStyle(isHeld ? Palette.onHero : Palette.ink)
            Text(isHeld ? "Let go when the line is done" : "Homer hears you only while you hold")
                .font(Typeface.text(14, weight: 500))
                .foregroundStyle(isHeld ? Palette.onHero2 : Palette.ink2)
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
