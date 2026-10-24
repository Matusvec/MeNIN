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
    /// The event's own total when it isn't a plain sum (poetry is weighted, out of 100).
    var weightedTotal: Int? = nil
    /// What the total is out of; nil means a plain sum, out of 10 per axis.
    var outOf: Int? = nil

    var total: Int { weightedTotal ?? axes.reduce(0) { $0 + $1.value } }
    var maxTotal: Int { outOf ?? axes.count * 10 }

    /// From the server's ordered axes for an event. Poetry's total is weighted
    /// (the server's ScoreRow.total); pass it when you have it, else it's computed the same way.
    init(event: EventKind, values: [Int], verdict: String, bestLine: String, weightedTotal: Int? = nil, outOf: Int? = nil) {
        axes = Self.shown(zip(event.axes, values).map { AxisScore(name: $0, value: $1) })
        self.verdict = verdict
        self.bestLine = bestLine
        if event == .poetry {
            self.weightedTotal = weightedTotal ?? Self.poetryTotal(axes)
            self.outOf = outOf ?? 100
        } else {
            self.weightedTotal = weightedTotal
            self.outOf = outOf
        }
    }

    init(axes: [AxisScore], verdict: String, bestLine: String, weightedTotal: Int? = nil, outOf: Int? = nil) {
        self.axes = axes
        self.verdict = verdict
        self.bestLine = bestLine
        self.weightedTotal = weightedTotal
        self.outOf = outOf
    }

    /// Poetry's contract scorecard, weighted out of 100 like the server's total.
    init(_ card: Scorecard, weightedTotal: Int? = nil) {
        axes = Self.shown(Axis.allCases.map { AxisScore(name: $0.rawValue.capitalized, value: card.scores[$0]) })
        verdict = card.verdict
        bestLine = card.bestLine
        self.weightedTotal = weightedTotal ?? Self.poetryTotal(axes)
        outOf = 100
    }

    /// Poetry's total (SPEC): Image ×4, Answer ×4, Craft ×2, out of 100, the same
    /// as the server's ScoreRow.total, used when that isn't passed.
    static func poetryTotal(_ axes: [AxisScore]) -> Int {
        let weights = ["Image": 4, "Answer": 4, "Craft": 2]
        return axes.reduce(0) { $0 + (weights[$1.name] ?? 0) * $1.value }
    }

    /// Poetry is judged on content (Matus): the card shows three bars, Image,
    /// Answer, Craft. Beat and Range still arrive from the server but aren't
    /// scored in a battle (the scene still reads the emotion). Debate is unchanged.
    private static func shown(_ axes: [AxisScore]) -> [AxisScore] {
        let order = ["Image", "Answer", "Craft"]
        guard axes.contains(where: { $0.name == "Beat" }) else { return axes }
        return axes
            .filter { order.contains($0.name) }
            .sorted { (order.firstIndex(of: $0.name) ?? 9) < (order.firstIndex(of: $1.name) ?? 9) }
    }
}
