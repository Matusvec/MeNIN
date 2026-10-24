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
                    .font(Typeface.display(28, on: stage, weight: 500, italic: true))
                    .displayLeading(28 * k, 1.12)
                    .foregroundStyle(Palette.ink)
                    .sturdy(28)
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

/// The arena's side reveal: "For" or "Against" stamped next to the speaker, a
/// tilted slab of the side's ink that slams in with cut-paper shards.
struct SideStamp: View {
    let side: DebateSide
    /// Fired once, on the frame it hits: the slam cue and the screen shake.
    var onImpact: (() -> Void)? = nil

    @State private var hit = false
    @Environment(\.stage) private var stage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let k = stage.scale
        Text(side.title)
            .font(Typeface.display(30, on: stage, weight: 900))
            .foregroundStyle(Palette.cream)
            .sturdy(30)
            .padding(.horizontal, Metrics.s4 * k)
            .padding(.vertical, Metrics.s1 * k)
            .background(alignment: .trailing) {
                ShardBurst(inks: [side == .affirm ? Palette.sea : Palette.vermilion, Palette.cream, Palette.ink], trigger: hit, k: k)
            }
            .paper(side == .affirm ? Palette.sea : Palette.vermilion, radius: 4 * k)
            .rotationEffect(.degrees(hit ? -4 : -14))
            .scaleEffect(hit ? 1 : 2.4)
            .opacity(hit ? 1 : 0)
            .task {
                guard !hit else { return }
                if !reduceMotion { try? await Task.sleep(for: .seconds(0.35)) }
                withAnimation(reduceMotion ? nil : .timingCurve(0.6, 0, 1, 0.6, duration: 0.18)) { hit = true }
                if !reduceMotion { try? await Task.sleep(for: .seconds(0.18)) }
                onImpact?()
            }
            .accessibilityLabel("Arguing \(side.title)")
    }
}

/// The debate's clock: a ring that empties as the turn runs, the seconds in
/// the middle. In the last ten seconds the pressure shows: vermilion floods the
/// face from below and the number knocks on every second; in the last five the
/// whole clock shakes on each one.
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
            let pressing = endsAt != nil && left <= 10
            let urgent = endsAt != nil && left <= 5
            let secs = Int(left.rounded(.up))
            ZStack {
                Circle().fill(Palette.paper)
                // The flood: a flat vermilion tint rising through the last ten seconds.
                if pressing {
                    Rectangle().fill(Palette.vermilion.opacity(0.16))
                        .frame(height: d * CGFloat(min(1, (10 - left) / 10)))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .clipShape(Circle())
                }
                Circle().strokeBorder(Palette.paper2, lineWidth: d * 0.08)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(pressing ? Palette.vermilion : Palette.accent, style: StrokeStyle(lineWidth: d * 0.08, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(d * 0.04)
                VStack(spacing: 0) {
                    Text(endsAt != nil && left <= 0 ? "Time" : "\(secs)")
                        .font(Typeface.display(d * (left <= 0 && endsAt != nil ? 0.26 : (pressing ? 0.44 : 0.36)), weight: pressing ? 800 : 500))
                        .foregroundStyle(pressing ? Palette.vermilion : Palette.ink)
                        .contentTransition(.numericText(countsDown: true))
                        // Each of the last ten seconds lands like a knock.
                        .keyframeAnimator(initialValue: 1.0, trigger: pressing ? secs : 99) { n, s in n.scaleEffect(s) } keyframes: { _ in
                            MoveKeyframe(1.0)
                            SpringKeyframe(1.3, duration: 0.06, spring: .snappy)
                            SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
                        }
                    if !(endsAt != nil && left <= 0) {
                        Text("sec").tracked(d * 0.09, color: pressing ? Palette.vermilion : Palette.ink3)
                    }
                }
            }
            .frame(width: d, height: d)
            // The last five: the clock jolts on every second.
            .keyframeAnimator(initialValue: 0.0, trigger: urgent ? secs : 99) { clock, x in clock.offset(x: x) } keyframes: { _ in
                MoveKeyframe(0.0)
                LinearKeyframe(d * 0.04, duration: 0.04)
                LinearKeyframe(-d * 0.03, duration: 0.05)
                SpringKeyframe(0, duration: 0.2)
            }
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
