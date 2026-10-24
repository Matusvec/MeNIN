import SwiftUI

/// The judge's card: every axis, the total, the verdict, the quoted line.
/// A bare total never appears alone. Works for any event's rubric (poetry:
/// Beat, Craft, Image, Answer, Range; debate: Claim, Reason, Answer, Craft, Poise).
///
/// `reveal` (0...1) drives the count-up while the host speaks the verdict: the
/// axes fill in order, then the total.
struct ScorecardView: View {
    let ruling: Ruling
    var reveal: Double = 1
    var poet: String? = nil

    init(card: Scorecard, reveal: Double = 1, poet: String? = nil) {
        self.init(ruling: Ruling(card), reveal: reveal, poet: poet)
    }

    init(ruling: Ruling, reveal: Double = 1, poet: String? = nil) {
        self.ruling = ruling
        self.reveal = reveal
        self.poet = poet
    }

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        let count = Double(ruling.axes.count)
        let step = min(1, max(0, reveal)) * (count + 1)
        VStack(alignment: .leading, spacing: Metrics.s4 * k) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2 * k) {
                    Text(poet ?? "The judge").tracked(10 * k, color: Palette.ink3)
                    Text(ruling.verdict)
                        .font(Typeface.display(20 * k, italic: true))
                        .displayLeading(20 * k, 1.18)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Metrics.s4 * k)
                let totalShown = Int((Double(ruling.total) * min(1, max(0, step - count))).rounded())
                HStack(alignment: .lastTextBaseline, spacing: 2 * k) {
                    Text("\(totalShown)")
                        .font(Typeface.display(56 * k, weight: 500))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(value: Double(totalShown)))
                    Text("/\(ruling.axes.count * 10)").font(Typeface.numeral(13 * k, weight: 600)).foregroundStyle(Palette.ink3)
                }
                .opacity(step > count ? 1 : 0.15)
                .fixedSize()
            }

            VStack(spacing: Metrics.s2 * k) {
                ForEach(Array(ruling.axes.enumerated()), id: \.element.id) { i, axis in
                    let shown = Int((Double(axis.value) * min(1, max(0, step - Double(i)))).rounded())
                    AxisRow(name: axis.name, value: shown, k: k)
                }
            }

            HStack(alignment: .top, spacing: Metrics.s3 * k) {
                Rectangle().fill(Palette.gold).frame(width: 3 * k)
                Text("“\(ruling.bestLine)”")
                    .font(Typeface.display(22 * k))
                    .displayLeading(22 * k, 1.15)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(step >= count + 1 - 0.01 && !ruling.bestLine.isEmpty ? 1 : 0)
        }
        .padding(Metrics.s5 * k)
        .frame(maxWidth: 520 * k)
        .paper(radius: Metrics.radiusL * k)
        .animation(Motion.stamp, value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let axes = ruling.axes.map { "\($0.name) \($0.value)" }.joined(separator: ", ")
        return "\(ruling.verdict). \(axes). Total \(ruling.total) of \(ruling.axes.count * 10). Best line: \(ruling.bestLine)"
    }
}

private struct AxisRow: View {
    let name: String
    let value: Int
    let k: CGFloat

    var body: some View {
        HStack(spacing: Metrics.s3 * k) {
            Text(name).tracked(10 * k, color: Palette.ink2)
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
