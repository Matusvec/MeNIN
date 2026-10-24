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
    /// Fired as each axis finishes counting (0-based), then once more with
    /// `axes.count` when the total lands: the knocks under the host's voice.
    var onKnock: ((Int) -> Void)? = nil

    init(card: Scorecard, reveal: Double = 1, poet: String? = nil, onKnock: ((Int) -> Void)? = nil) {
        self.init(ruling: Ruling(card), reveal: reveal, poet: poet, onKnock: onKnock)
    }

    init(ruling: Ruling, reveal: Double = 1, poet: String? = nil, onKnock: ((Int) -> Void)? = nil) {
        self.ruling = ruling
        self.reveal = reveal
        self.poet = poet
        self.onKnock = onKnock
    }

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        let count = Double(ruling.axes.count)
        let step = min(1, max(0, reveal)) * (count + 1)
        let landed = landedSteps
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
                        .font(Typeface.display(64 * k, weight: 600))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(value: Double(totalShown)))
                        // The total lands heavy.
                        .keyframeAnimator(initialValue: 1.0, trigger: landed > ruling.axes.count) { total, s in
                            total.scaleEffect(s, anchor: .bottomTrailing)
                        } keyframes: { _ in
                            MoveKeyframe(1.0)
                            SpringKeyframe(1.45, duration: 0.07, spring: .snappy)
                            SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
                        }
                    Text("/\(ruling.axes.count * 10)").font(Typeface.numeral(13 * k, weight: 600)).foregroundStyle(Palette.ink3)
                }
                .opacity(step > count ? 1 : 0.15)
                .fixedSize()
            }

            VStack(spacing: Metrics.s2 * k) {
                ForEach(Array(ruling.axes.enumerated()), id: \.element.id) { i, axis in
                    let shown = Int((Double(axis.value) * min(1, max(0, step - Double(i)))).rounded())
                    AxisRow(name: axis.name, value: shown, landed: landed > i, k: k)
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
        .onChange(of: landed) { old, new in
            guard new > old else { return }
            for i in old..<new { onKnock?(i) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    /// Axes finished counting, plus one once the total has landed.
    private var landedSteps: Int {
        let count = ruling.axes.count
        let step = min(1, max(0, reveal)) * Double(count + 1)
        return min(count + 1, Int((step + 1e-6).rounded(.down)))
    }

    private var accessibilitySummary: String {
        let axes = ruling.axes.map { "\($0.name) \($0.value)" }.joined(separator: ", ")
        return "\(ruling.verdict). \(axes). Total \(ruling.total) of \(ruling.axes.count * 10). Best line: \(ruling.bestLine)"
    }
}

private struct AxisRow: View {
    let name: String
    let value: Int
    /// Flips true when the axis finishes counting: the row takes the knock.
    var landed = false
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
                .font(Typeface.display(20 * k, weight: 600))
                .foregroundStyle(Palette.ink)
                .frame(width: 24 * k, alignment: .trailing)
                .contentTransition(.numericText(value: Double(value)))
                .keyframeAnimator(initialValue: 1.0, trigger: landed) { number, s in
                    number.scaleEffect(s, anchor: .trailing)
                } keyframes: { _ in
                    MoveKeyframe(1.0)
                    SpringKeyframe(1.7, duration: 0.06, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.32, spring: .bouncy)
                }
        }
        // The knock: the row jolts down and back, once.
        .keyframeAnimator(initialValue: 0.0, trigger: landed) { row, y in
            row.offset(y: y)
        } keyframes: { _ in
            MoveKeyframe(0.0)
            SpringKeyframe(3 * k, duration: 0.05, spring: .snappy)
            SpringKeyframe(0, duration: 0.25, spring: .bouncy)
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
