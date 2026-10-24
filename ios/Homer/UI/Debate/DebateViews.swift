import SwiftUI

// Socratic debate: the poetry battle's turn without the beat. A question to
// argue, a side, a hand of rhetorical moves you tap as you make them, and a
// clock where the beat lane was. Socrates hosts.

enum DebateSide: String, Equatable, Sendable {
    case affirm, deny

    var title: String { self == .affirm ? "For" : "Against" }
}

/// The question on the floor, posed by Socrates.
struct QuestionCard: View {
    let question: String
    var round: Int? = nil

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(alignment: .top, spacing: Metrics.s4 * k) {
            HostMedallion(host: .socrates, size: 58 * k)
            VStack(alignment: .leading, spacing: Metrics.s1 * k) {
                Text(round.map { "Socrates asks · Round \(roman($0))" } ?? "Socrates asks").tracked(10 * k, color: Palette.olive)
                Text(question)
                    .font(Typeface.display(26 * k, italic: true))
                    .displayLeading(26 * k, 1.12)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Metrics.s4 * k)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(radius: Metrics.radiusL * k)
        .accessibilityElement(children: .combine)
    }
}

/// Which side of the question a speaker argues.
struct SideChip: View {
    let side: DebateSide
    @Environment(\.stage) private var stage

    var body: some View {
        Text(side.title)
            .chip(11 * stage.scale, fill: side == .affirm ? Palette.sea : Palette.vermilion, color: Palette.cream)
    }
}

/// The debate's clock: a ring that empties as the turn runs, the seconds in
/// the middle. It turns vermilion for the last five seconds.
struct TurnClockView: View {
    /// When the turn ends; nil holds the clock full (before the turn starts).
    var endsAt: Date?
    /// The turn's full length, for the ring.
    var seconds: Double = 45
    var size: CGFloat = 96

    @Environment(\.stage) private var stage

    var body: some View {
        let d = size * stage.scale
        TimelineView(.animation(minimumInterval: 0.1, paused: endsAt == nil)) { context in
            let left = max(0, endsAt.map { $0.timeIntervalSince(context.date) } ?? seconds)
            let fraction = seconds > 0 ? left / seconds : 0
            let urgent = endsAt != nil && left <= 5
            ZStack {
                Circle().fill(Palette.paper)
                Circle().strokeBorder(Palette.paper2, lineWidth: d * 0.08)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(urgent ? Palette.vermilion : Palette.accent, style: StrokeStyle(lineWidth: d * 0.08, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(d * 0.04)
                VStack(spacing: 0) {
                    Text("\(Int(left.rounded(.up)))")
                        .font(Typeface.display(d * 0.36, weight: 500))
                        .foregroundStyle(urgent ? Palette.vermilion : Palette.ink)
                        .contentTransition(.numericText(countsDown: true))
                    Text("sec").tracked(d * 0.09, color: Palette.ink3)
                }
            }
            .frame(width: d, height: d)
            .animation(.linear(duration: 0.1), value: fraction)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Time left")
    }
}

/// The phone's moves hand: tap a card as you make the move. Played cards are
/// struck through; the move Socrates whispers on a freeze is raised.
struct MovesHandView: View {
    let moves: [FormulaCard]
    var whisperedId: String? = nil
    var onPlay: ((FormulaCard) -> Void)? = nil

    var body: some View {
        FormulaHandView(cards: moves, raisedId: whisperedId, forward: true, style: .compact, whisperer: "Socrates") { card in
            if !card.used { onPlay?(card) }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: moves.filter(\.used).count)
    }
}

#Preview("Debate pieces") {
    VStack(spacing: 20) {
        QuestionCard(question: "Is it better to suffer injustice than to do it?", round: 1)
        HStack { SideChip(side: .affirm); SideChip(side: .deny); Spacer(); TurnClockView(endsAt: .now.addingTimeInterval(30)) }
        MovesHandView(moves: [
            FormulaCard(id: "1", text: "Define your terms", kind: .move, used: true),
            FormulaCard(id: "2", text: "Counterexample", kind: .move, used: false),
            FormulaCard(id: "3", text: "Analogy", kind: .move, used: false),
        ], whisperedId: "2")
    }
    .padding()
    .background(Palette.olive)
}
