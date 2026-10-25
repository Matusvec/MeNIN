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
    /// One plain line under each axis saying what it scores (the phone, where you read your own card).
    var hints: Bool = false

    init(card: Scorecard, reveal: Double = 1, poet: String? = nil, hints: Bool = false, onKnock: ((Int) -> Void)? = nil) {
        self.init(ruling: Ruling(card), reveal: reveal, poet: poet, hints: hints, onKnock: onKnock)
    }

    init(ruling: Ruling, reveal: Double = 1, poet: String? = nil, hints: Bool = false, onKnock: ((Int) -> Void)? = nil) {
        self.ruling = ruling
        self.reveal = reveal
        self.poet = poet
        self.hints = hints
        self.onKnock = onKnock
    }

    /// What each axis scores, in plain words: poetry from SPEC's rubric table,
    /// debate from content/debate.md's.
    static func hint(for axis: String, debate: Bool) -> String? {
        switch (axis.lowercased(), debate) {
        case ("beat", _), ("flow", _): "You kept a steady rhythm"
        case ("craft", false): "Homer's phrases and your own turns"
        case ("image", _): "Pictures we can see"
        case ("answer", false): "You hit back at the other poet"
        case ("range", _): "How much feeling the verse covered"
        case ("claim", _): "You took your side, said it plainly, and held it to the end"
        case ("reason", _): "Your reasons and examples actually support your claim"
        case ("answer", true): "You took on the last speaker's strongest point, or the question if you went first"
        case ("craft", true): "You made the moves in your hand, at the right moment, and varied them"
        case ("poise", _): "You kept the floor: steady pace, few fillers, no dead air"
        default: nil
        }
    }

    /// The server's fallback when the judge never answers: a neutral 4/4/4 with this
    /// exact verdict (homer/homer/judge.py SILENT_VERDICT). Older rows have none.
    static let neutralVerdict = "Homer is silent on this one."
    private var isNeutral: Bool { ruling.verdict == Self.neutralVerdict || ruling.verdict.isEmpty }

    private var isDebate: Bool { ruling.axes.contains { ["claim", "poise"].contains($0.name.lowercased()) } }

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
                        .font(Typeface.display(20, on: stage, italic: true))
                        .displayLeading(20 * k, 1.18)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if isNeutral {
                        Text("Neutral score: the judge timed out")
                            .chip(10 * k, fill: Palette.paper2, color: Palette.ink2)
                            .padding(.top, Metrics.s1 * k)
                    }
                }
                Spacer(minLength: Metrics.s4 * k)
                let totalShown = Int((Double(ruling.total) * min(1, max(0, step - count))).rounded())
                HStack(alignment: .lastTextBaseline, spacing: 2 * k) {
                    Text("\(totalShown)")
                        .font(Typeface.display(64, on: stage, weight: 600))
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
                    Text("/\(ruling.maxTotal)").font(Typeface.numeral(13 * k, weight: 600)).foregroundStyle(Palette.ink3)
                }
                .opacity(step > count ? 1 : 0.15)
                .fixedSize()
            }

            VStack(spacing: Metrics.s2 * k) {
                ForEach(Array(ruling.axes.enumerated()), id: \.element.id) { i, axis in
                    let shown = Int((Double(axis.value) * min(1, max(0, step - Double(i)))).rounded())
                    AxisRow(name: axis.name, value: shown, landed: landed > i, k: k,
                            hint: hints ? Self.hint(for: axis.name, debate: isDebate) : nil, muted: isNeutral)
                }
            }

            HStack(alignment: .top, spacing: Metrics.s3 * k) {
                Rectangle().fill(Palette.gold).frame(width: 3 * k)
                Text("“\(ruling.bestLine)”")
                    .font(Typeface.display(22, on: stage))
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
        return "\(ruling.verdict). \(axes). Total \(ruling.total) of \(ruling.maxTotal). Best line: \(ruling.bestLine)"
    }
}

struct AxisRow: View {
    let name: String
    let value: Int
    /// Flips true when the axis finishes counting: the row takes the knock.
    var landed = false
    let k: CGFloat
    var hint: String? = nil
    /// A neutral fallback score: grey bars, so it never reads as a judgment.
    var muted = false
    @Environment(\.stage) private var stage

    var body: some View {
        VStack(alignment: .leading, spacing: 3 * k) {
            bars
            if let hint {
                Text(hint)
                    .font(Typeface.text(12 * k))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var bars: some View {
        HStack(spacing: Metrics.s3 * k) {
            Text(name).tracked(10 * k, color: Palette.ink2)
                .frame(width: 64 * k, alignment: .leading)
            HStack(spacing: 3 * k) {
                ForEach(0..<10, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2 * k, style: .continuous)
                        .fill(i < value ? (muted ? Palette.ink3.opacity(0.55) : (value >= 8 ? Palette.gold : Palette.accent)) : Palette.paper2)
                        .frame(height: 12 * k)
                        .scaleEffect(y: i == value - 1 ? 1.25 : 1)
                }
            }
            Text("\(value)")
                .font(Typeface.display(20, on: stage, weight: 600))
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
