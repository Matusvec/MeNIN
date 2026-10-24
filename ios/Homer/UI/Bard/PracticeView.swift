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
}

struct PracticeActions {
    var pickTheme: ((String) -> Void)?
    var randomTheme: (() -> Void)?
    var start: (() -> Void)?
    var done: (() -> Void)?
    var again: (() -> Void)?
    var retry: (() -> Void)?
    var type: ((String) -> Void)?

    init(pickTheme: ((String) -> Void)? = nil, randomTheme: (() -> Void)? = nil, start: (() -> Void)? = nil,
         done: (() -> Void)? = nil, again: (() -> Void)? = nil, retry: (() -> Void)? = nil, type: ((String) -> Void)? = nil) {
        self.pickTheme = pickTheme
        self.randomTheme = randomTheme
        self.start = start
        self.done = done
        self.again = again
        self.retry = retry
        self.type = type
    }
}

struct PracticeView: View {
    let model: PracticeModel
    var actions = PracticeActions()

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s4 * k) {
            header
            ScrollView {
                content
                    .frame(maxWidth: 760 * k)
                    .frame(maxWidth: .infinity)
                    .id(phaseKey)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            if let homer = model.homer {
                CaptionView(text: homer.text, spoken: homer.spoken, whisper: homer.whisper)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, Metrics.s4 * k)
        .padding(.bottom, Metrics.s3 * k)
        .animation(Motion.slide, value: phaseKey)
        .animation(Motion.slide, value: model.homer?.text)
        .sceneBehind()
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

    private var header: some View {
        let k = stage.scale
        return HStack(alignment: .center, spacing: Metrics.s3 * k) {
            VStack(alignment: .leading, spacing: 2 * k) {
                Text("Practice  /  Spar with Homer").tracked(10 * k, color: Palette.accent)
                Text(model.theme.isEmpty ? "Choose a theme" : model.theme)
                    .font(Typeface.display(24, on: stage))
                    .displayLeading(24 * k, 1.12)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Metrics.s4 * k)
        .paper(radius: Metrics.radiusL * k)
    }

    @ViewBuilder
    private var content: some View {
        let k = stage.scale
        switch model.phase {
        case .idle(let themes):
            VStack(alignment: .leading, spacing: Metrics.s3 * k) {
                Text("Pick a theme").tracked(10 * k)
                ForEach(themes, id: \.self) { theme in
                    Button { actions.pickTheme?(theme) } label: {
                        HStack {
                            Text(theme).font(Typeface.display(21, on: stage)).foregroundStyle(Palette.ink)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image("icon-chevron-right").renderingMode(.template).resizable()
                                .frame(width: 17 * k, height: 17 * k).foregroundStyle(Palette.ink2)
                        }
                        .padding(.horizontal, Metrics.s4 * k)
                        .frame(minHeight: 60 * k)
                        .paper(radius: Metrics.radiusM * k, lifted: false)
                    }
                    .buttonStyle(.plain)
                    .disabled(actions.pickTheme == nil)
                }
                if let roll = actions.randomTheme {
                    Button("Roll a theme", action: roll).buttonStyle(.homer(.secondary)).padding(.top, Metrics.s2 * k)
                }
            }

        case .dealing:
            WeighingMark().padding(.top, Metrics.s7 * k)

        case .ready:
            VStack(spacing: Metrics.s4 * k) {
                if !model.hand.isEmpty {
                    VStack(alignment: .leading, spacing: Metrics.s2 * k) {
                        Text("Your hand").tracked(10 * k)
                        FormulaHandView(cards: model.hand, forward: true)
                    }
                }
                if let start = actions.start {
                    Button(action: start) { ArrowLabel(title: "Take the turn") }.buttonStyle(.homer)
                }
            }

        case .announcing:
            VStack(spacing: Metrics.s3 * k) {
                Text("The theme").tracked(12 * k, color: Palette.onHero2)
                Text(model.theme)
                    .font(Typeface.display(34, on: stage))
                    .displayLeading(34 * k, 1.1)
                    .foregroundStyle(Palette.onHero)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Metrics.s7 * k)
            .padding(.horizontal, Metrics.s5 * k)
            .frame(maxWidth: .infinity)
            .paper(Palette.hero, radius: Metrics.radiusL * k)
            .padding(.top, Metrics.s6 * k)

        case .live:
            VStack(spacing: Metrics.s3 * k) {
                if let lane = model.lane { BeatLaneView(lane: lane, barsPerLine: 2) }
                if !model.transcript.isEmpty {
                    TranscriptView(lines: model.transcript, listening: model.listening, formulas: model.hand.filter(\.used).map(\.text), maxLines: 4)
                } else if model.listening {
                    Text("Your turn. Speak on the beat").chip(11 * k, fill: Palette.hero, color: Palette.onHero)
                }
                if !model.hand.isEmpty {
                    FormulaHandView(cards: model.hand, raisedId: model.rescueId, forward: true, style: .compact)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let typed = model.typed, let type = actions.type {
                    TextField("Your lines, one per row", text: Binding(get: { typed }, set: { type($0) }), axis: .vertical)
                        .font(Typeface.display(20, on: stage))
                        .lineLimit(2...4)
                        .padding(Metrics.s4 * k)
                        .paper()
                }
                HStack {
                    MicLevelView(level: model.level)
                    Spacer()
                    if let done = actions.done { Button("Done", action: done).buttonStyle(.homer(.secondary)) }
                }
                .padding(Metrics.s3 * k)
                .paper()
            }

        case .judging:
            VStack(spacing: Metrics.s4 * k) {
                if !model.transcript.isEmpty { TranscriptView(lines: model.transcript, maxLines: 4) }
                WeighingMark()
            }

        case .verdict(let card, let reveal, let coined):
            VStack(spacing: Metrics.s4 * k) {
                ScorecardView(card: card, reveal: reveal)
                if let coined, reveal >= 1 {
                    Text("Into your hoard · \(coined)").chip(11 * k, fill: Palette.gold, color: Palette.ink)
                }
                if let again = actions.again {
                    Button(action: again) { ArrowLabel(title: "Again") }.buttonStyle(.homer)
                }
            }

        case .failed(let why):
            VStack(spacing: Metrics.s4 * k) {
                Text(why).font(Typeface.text(15 * k)).foregroundStyle(Palette.ink2).multilineTextAlignment(.center)
                if let retry = actions.retry { Button("Try again", action: retry).buttonStyle(.homer) }
            }
            .padding(Metrics.s5 * k)
            .paper()
            .padding(.top, Metrics.s7 * k)
        }
    }
}
