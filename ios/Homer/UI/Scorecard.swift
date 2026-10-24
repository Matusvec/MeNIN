import SwiftUI

/// The judge's card: all five axes, the total, the verdict, the quoted line.
/// A bare total never appears alone.
///
/// `reveal` (0...1) drives the count-up while Homer speaks the verdict: the
/// axes fill in order (Beat, Craft, Image, Answer, Range), then the total.
struct ScorecardView: View {
    let card: Scorecard
    var reveal: Double = 1
    var poet: String? = nil

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        let step = min(1, max(0, reveal)) * Double(Axis.allCases.count + 1)
        VStack(alignment: .leading, spacing: Metrics.s4 * k) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2 * k) {
                    Text(poet ?? "The judge").tracked(10 * k, color: Palette.ink3)
                    Text(card.verdict)
                        .font(Typeface.display(20 * k, italic: true))
                        .displayLeading(20 * k, 1.18)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Metrics.s4 * k)
                let totalShown = Int((Double(card.scores.total) * min(1, max(0, step - 5))).rounded())
                HStack(alignment: .lastTextBaseline, spacing: 2 * k) {
                    Text("\(totalShown)")
                        .font(Typeface.display(56 * k, weight: 500))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(value: Double(totalShown)))
                    Text("/50").font(Typeface.numeral(13 * k, weight: 600)).foregroundStyle(Palette.ink3)
                }
                .opacity(step > 5 ? 1 : 0.15)
                .fixedSize()
            }

            VStack(spacing: Metrics.s2 * k) {
                ForEach(Array(Axis.allCases.enumerated()), id: \.element) { i, axis in
                    let shown = Int((Double(card.scores[axis]) * min(1, max(0, step - Double(i)))).rounded())
                    AxisRow(axis: axis, value: shown, k: k)
                }
            }

            HStack(alignment: .top, spacing: Metrics.s3 * k) {
                Rectangle().fill(Palette.gold).frame(width: 3 * k)
                Text("“\(card.bestLine)”")
                    .font(Typeface.display(22 * k))
                    .displayLeading(22 * k, 1.15)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(step >= Double(Axis.allCases.count + 1) - 0.01 ? 1 : 0)
        }
        .padding(Metrics.s5 * k)
        .frame(maxWidth: 520 * k)
        .paper(radius: Metrics.radiusL * k)
        .animation(Motion.stamp, value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let axes = Axis.allCases.map { "\($0.rawValue) \(card.scores[$0])" }.joined(separator: ", ")
        return "\(card.verdict). \(axes). Total \(card.scores.total) of 50. Best line: \(card.bestLine)"
    }
}

private struct AxisRow: View {
    let axis: Axis
    let value: Int
    let k: CGFloat

    var body: some View {
        HStack(spacing: Metrics.s3 * k) {
            Text(axis.rawValue).tracked(10 * k, color: Palette.ink2)
                .frame(width: 64 * k, alignment: .leading)
            HStack(spacing: 3 * k) {
                ForEach(0..<10, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2 * k, style: .continuous)
                        .fill(i < value ? (value >= 8 ? Palette.gold : Palette.accent) : Palette.paper2)
                        .frame(height: 12 * k)
                        .scaleEffect(y: i == value - 1 ? 1.25 : 1)
                }
            }
            Text("\(value)")
                .font(Typeface.display(18 * k, weight: 500))
                .foregroundStyle(Palette.ink)
                .frame(width: 22 * k, alignment: .trailing)
                .contentTransition(.numericText(value: Double(value)))
        }
    }
}

#Preview {
    ScorecardView(card: Scorecard(scores: Scores(beat: 8, craft: 6, image: 9, answer: 5, range: 7),
                                  verdict: "Strong bones, thin blood. Your third line carried you.",
                                  bestLine: "The whale-road swallowed his sails"),
                  reveal: 1, poet: "Matus, Breaker of Deadlines")
        .padding()
        .background(Palette.wine)
}
