import SwiftUI

/// Practice: spar with Homer (docs/ux-flow.md section 3). Pick or roll a theme,
/// get dealt a hand, take the turn, get the full breakdown. Calm and
/// controlled like Bard mode. Props in; the iOS lead's PracticeSession fills it.
struct PracticeModel: Equatable {
    enum Phase: Equatable {
        /// R0 · Choose a theme or roll one.
        case idle(themes: [String])
        case dealing
        /// The theme is set and the hand dealt; start when ready.
        case ready
        /// Homer announces the theme.
        case announcing
        /// The turn is live.
        case live
        case judging
        /// R1 · The full breakdown.
        case verdict(card: Scorecard, reveal: Double, coined: String?)
        case failed(String)
    }

    var phase: Phase = .idle(themes: [])
    var theme: String = ""
    var hand: [FormulaCard] = []
    var lane: BeatLane?
    var transcript: [String] = []
    var listening: Bool = false
    var level: Double = 0
    var rescueId: String?
    var homer: HomerLine?
    /// When voice is unavailable: the typed fallback's text.
    var typed: String?
    /// A wait over the screen (Homer warming up, reconnecting).
    var wait: WaitState? = nil
}

struct PracticeActions {
    var pickTheme: ((String) -> Void)?
    var randomTheme: (() -> Void)?
    var start: (() -> Void)?
    var done: (() -> Void)?
    var again: (() -> Void)?
    var retry: (() -> Void)?
    var type: ((String) -> Void)?
    /// The back chevron: out of Practice.
    var back: (() -> Void)?

    init(pickTheme: ((String) -> Void)? = nil, randomTheme: (() -> Void)? = nil, start: (() -> Void)? = nil,
         done: (() -> Void)? = nil, again: (() -> Void)? = nil, retry: (() -> Void)? = nil, type: ((String) -> Void)? = nil,
         back: (() -> Void)? = nil) {
        self.pickTheme = pickTheme
        self.randomTheme = randomTheme
        self.start = start
        self.done = done
        self.again = again
        self.retry = retry
        self.type = type
        self.back = back
    }
}

/// A PhoneScaffold: the theme on top, the work in the middle, the next step in the thumb zone.
struct PracticeView: View {
    let model: PracticeModel
    var actions = PracticeActions()

    var body: some View {
        PhoneScaffold(eyebrow: "Practice · Spar with Homer", title: model.theme.isEmpty ? "Choose a theme" : model.theme,
                      onBack: actions.back, homer: model.homer.flatMap { $0.whisper ? nil : $0 }, wait: model.wait) {
            ZStack {
                middle
                    .id(phaseKey)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .animation(Motion.slide, value: phaseKey)
        } action: {
            action
        }
    }

    private var phaseKey: String {
        switch model.phase {
        case .idle: "idle"
        case .dealing: "dealing"
        case .ready: "ready"
        case .announcing: "announcing"
        case .live: "live"
        case .judging: "judging"
        case .verdict: "verdict"
        case .failed: "failed"
        }
    }

    @ViewBuilder
    private var middle: some View {
        switch model.phase {
        case .idle(let themes):
            VStack(alignment: .leading, spacing: Metrics.s3) {
                Text("Pick a theme").tracked(10, color: Palette.onPage2)
                ForEach(themes, id: \.self) { theme in
                    EntryRow(title: theme, action: actions.pickTheme.map { pick in { pick(theme) } })
                }
                Spacer(minLength: 0)
            }

        case .dealing:
            WaitLine(state: .dealing).frame(maxHeight: .infinity)

        case .ready:
            VStack(alignment: .leading, spacing: Metrics.s3) {
                if !model.hand.isEmpty {
                    PhrasesHeader()
                    ViewThatFits(in: .vertical) {
                        FormulaHandView(cards: model.hand, forward: true)
                        FormulaHandView(cards: model.hand, forward: true, style: .compact)
                    }
                }
                Spacer(minLength: 0)
            }

        case .announcing:
            VStack(spacing: Metrics.s3) {
                Text("The theme").tracked(12, color: Palette.onHero2)
                Text(model.theme)
                    .font(Typeface.display(32))
                    .displayLeading(32, 1.1)
                    .foregroundStyle(Palette.onHero)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, Metrics.s7)
            .padding(.horizontal, Metrics.s5)
            .frame(maxWidth: .infinity)
            .paper(Palette.hero, radius: Metrics.radiusL)
            .frame(maxHeight: .infinity)

        case .live:
            let used = model.hand.filter(\.used).map(\.text)
            let open = model.hand.filter { $0.id == model.rescueId } + model.hand.filter { !$0.used && $0.id != model.rescueId }
            ViewThatFits(in: .vertical) {
                VStack(spacing: Metrics.s4) {
                    if let lane = model.lane { BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2) }
                    if !model.transcript.isEmpty {
                        TranscriptView(lines: Array(model.transcript.suffix(2)), listening: model.listening, formulas: used, maxLines: 2)
                    }
                    FormulaHandView(cards: model.hand, raisedId: model.rescueId, forward: true, style: .compact)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(spacing: Metrics.s3) {
                    if let lane = model.lane { BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2) }
                    if let last = model.transcript.last {
                        TranscriptView(lines: [last], listening: model.listening, formulas: used, maxLines: 1)
                    }
                    FormulaHandView(cards: open, raisedId: model.rescueId, forward: true, style: .compact)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(spacing: Metrics.s3) {
                    if let lane = model.lane { BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2) }
                    FormulaHandView(cards: Array(open.prefix(2)), raisedId: model.rescueId, forward: true, style: .compact)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

        case .judging:
            VStack(spacing: Metrics.s4) {
                if !model.transcript.isEmpty { TranscriptView(lines: model.transcript, maxLines: 4) }
                WaitLine(state: .weighing)
                Spacer(minLength: 0)
            }

        case .verdict(let card, let reveal, let coined):
            ViewThatFits(in: .vertical) {
                verdict(card, reveal: reveal, coined: coined)
                ScrollView { verdict(card, reveal: reveal, coined: coined) }.scrollIndicators(.hidden)
            }

        case .failed(let why):
            Text(why)
                .font(Typeface.text(16))
                .foregroundStyle(Palette.ink2)
                .multilineTextAlignment(.center)
                .padding(Metrics.s5)
                .frame(maxWidth: .infinity)
                .paper()
                .frame(maxHeight: .infinity)
        }
    }

    private func verdict(_ card: Scorecard, reveal: Double, coined: String?) -> some View {
        VStack(spacing: Metrics.s4) {
            ScorecardView(card: card, reveal: reveal, hints: true)
            if let coined, reveal >= 1 {
                Text("Into your hoard · \(coined)").chip(11, fill: Palette.gold, color: Palette.ink)
            }
        }
    }

    @ViewBuilder
    private var action: some View {
        switch model.phase {
        case .idle:
            if let roll = actions.randomTheme {
                Button(action: roll) { ArrowLabel(title: "Roll a theme") }.buttonStyle(.homer(.secondary, wide: true))
            }
        case .ready:
            if let start = actions.start {
                Button(action: start) { ArrowLabel(title: "Take the turn") }.buttonStyle(.homer(wide: true))
            }
        case .live:
            VStack(spacing: Metrics.s2) {
                if let typed = model.typed, let type = actions.type {
                    TextField("Your lines, one per row", text: Binding(get: { typed }, set: { type($0) }), axis: .vertical)
                        .font(Typeface.display(20))
                        .lineLimit(2...3)
                        .padding(Metrics.s4)
                        .paper()
                }
                HStack(spacing: Metrics.s3) {
                    if model.typed == nil {
                        LiveDot(size: 10)
                        MicLevelView(level: model.level)
                    }
                    Spacer(minLength: 0)
                    if let done = actions.done { Button("I'm done", action: done).buttonStyle(.homer) }
                }
                .padding(Metrics.s3)
                .frame(maxWidth: .infinity)
                .paper()
            }
        case .verdict:
            if let again = actions.again {
                Button(action: again) { ArrowLabel(title: "Again") }.buttonStyle(.homer(wide: true))
            }
        case .failed:
            if let retry = actions.retry {
                Button(action: retry) { ArrowLabel(title: "Try again") }.buttonStyle(.homer(wide: true))
            }
        case .dealing, .announcing, .judging:
            EmptyView()
        }
    }
}
