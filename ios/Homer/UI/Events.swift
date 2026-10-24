import Foundation

// The games on one engine (SPEC "The games"): each event names its host, its
// rubric and its hand. The server knows only the axis count and card kind;
// the labels and the copy live here.

enum EventKind: String, CaseIterable, Sendable {
    case poetry, debate, discus

    var title: String {
        switch self {
        case .poetry: "Poetry Battle"
        case .debate: "Socratic Debate"
        case .discus: "Discus"
        }
    }

    var host: EventHost { self == .debate ? .socrates : .homer }

    /// Score axes in the server's order (`score.axes`).
    var axes: [String] {
        switch self {
        case .poetry: ["Beat", "Craft", "Image", "Answer", "Range"]
        case .debate: ["Claim", "Reason", "Answer", "Craft", "Poise"]
        case .discus: []
        }
    }

    var hasBeat: Bool { self == .poetry }
}

/// One judged axis, ready to show.
struct AxisScore: Equatable, Identifiable {
    var name: String
    var value: Int // 1...10, 0 when the judge was silent on it
    var id: String { name }
}

/// A judged turn for any event: its axes, the verdict, the quoted line.
struct Ruling: Equatable {
    var axes: [AxisScore]
    var verdict: String
    var bestLine: String

    var total: Int { axes.reduce(0) { $0 + $1.value } }

    /// From the server's ordered axes for an event.
    init(event: EventKind, values: [Int], verdict: String, bestLine: String) {
        axes = Self.shown(zip(event.axes, values).map { AxisScore(name: $0, value: $1) })
        self.verdict = verdict
        self.bestLine = bestLine
    }

    init(axes: [AxisScore], verdict: String, bestLine: String) {
        self.axes = axes
        self.verdict = verdict
        self.bestLine = bestLine
    }

    /// Poetry's contract scorecard.
    init(_ card: Scorecard) {
        axes = Self.shown(Axis.allCases.map { AxisScore(name: $0.rawValue.capitalized, value: card.scores[$0]) })
        verdict = card.verdict
        bestLine = card.bestLine
    }

    /// Poetry as the players read it (the playtest): Beat is called Flow, and the
    /// card leads with the picture: Image, Answer, Craft, Flow, Range. Debate is unchanged.
    private static func shown(_ axes: [AxisScore]) -> [AxisScore] {
        let order = ["Image", "Answer", "Craft", "Flow", "Range"]
        guard axes.contains(where: { $0.name == "Beat" }) else { return axes }
        return axes
            .map { $0.name == "Beat" ? AxisScore(name: "Flow", value: $0.value) : $0 }
            .sorted { (order.firstIndex(of: $0.name) ?? 9) < (order.firstIndex(of: $1.name) ?? 9) }
    }
}
