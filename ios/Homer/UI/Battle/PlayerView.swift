import SwiftUI

/// The phone in a battle: each poet's mic and private hand. Every moment is a
/// PhoneScaffold: context on top (back, event, round, theme), the content in
/// the middle, and the one thing to do pinned in the thumb zone. The scene
/// shows behind it (the app shell keeps it always on).
struct PlayerView: View {
    let model: PlayerModel
    var actions = PlayerActions()

    var body: some View {
        ZStack {
            screen
                .id(momentKey)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .animation(Motion.slide, value: momentKey)
        // Your entrance slams on the arena: the phone in your hand takes the hit too.
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: model.announced) { old, new in !old && new }
    }

    private var momentKey: String {
        switch model.moment {
        case .joining: "join"
        case .micCheck: "mic"
        case .waiting(let w, _): "wait\(w?.id ?? "")"
        case .onDeck: "deck"
        case .speaking: "speak"
        case .weighing: "weigh"
        case .closing: "closing"
        case .result: "result"
        case .final: "final"
        case .debating: "debate"
        case .ruling: "ruling"
        }
    }

    // MARK: Context

    private var eventName: String {
        switch model.event {
        case .poetry: "Poetry"
        case .debate: "Debate"
        case .discus: "Discus"
        }
    }

    /// "Your verse · Round II of III", or "Poetry · Round II of III" with no lead.
    /// Short enough for a zoomed 320-pt screen.
    private func eyebrow(_ lead: String? = nil) -> String {
        let round = model.round > 0 ? "Round \(roman(model.round)) of \(roman(model.rounds))" : nil
        return [lead ?? eventName, round].compactMap { $0 }.joined(separator: " · ")
    }

    /// The round's topic as the headline, from the call-up through the verse.
    private var topicTitle: String? { model.theme.map { "Topic: \($0)" } }

    /// Homer's line as a strip, except his whisper (it's on the raised card).
    private var homerStrip: HomerLine? {
        guard let h = model.homer, !h.whisper else { return nil }
        return h
    }

    private var codeChip: some View {
        Group {
            if !model.code.isEmpty, model.me != nil { Text(model.code).chip(10) }
        }
    }

    // MARK: Screens

    @ViewBuilder
    private var screen: some View {
        switch model.moment {
        case .joining(let error):
            JoinScreen(prefill: model.code, error: error, join: actions.join, onBack: actions.leave)

        case .micCheck:
            PhoneScaffold(eyebrow: eyebrow("Mic check"), title: "Homer wants to hear you", onBack: actions.leave,
                          homer: homerStrip, host: model.event.host.name) {
                VStack(spacing: Metrics.s5) {
                    if let me = model.me { MyPlate(poet: me, waitingForEpithet: me.epithet.isEmpty) }
                    Text("Say your name out loud. Tap when you're in the hall.")
                        .font(Typeface.text(16))
                        .foregroundStyle(Palette.ink2)
                        .multilineTextAlignment(.center)
                        .padding(Metrics.s4)
                        .frame(maxWidth: .infinity)
                        .paper(Palette.paper)
                }
                .frame(maxHeight: .infinity)
            } action: {
                if let imHere = actions.imHere {
                    Button(action: imHere) { ArrowLabel(title: "I'm here") }.buttonStyle(.homer(wide: true))
                }
            }

        case .waiting(let watching, let transcript):
            PhoneScaffold(eyebrow: eyebrow(), title: watching.map { "\($0.name) has the floor" } ?? "In the hall",
                          onBack: actions.leave, homer: homerStrip, host: model.event.host.name) {
                codeChip
            } middle: {
                VStack(spacing: Metrics.s4) {
                    if let me = model.me { MyPlate(poet: me, waitingForEpithet: false) }
                    if watching != nil {
                        if !transcript.isEmpty { TranscriptView(lines: transcript, maxLines: 3) }
                    } else {
                        Text("The battle begins soon.")
                            .font(Typeface.display(22, italic: true))
                            .foregroundStyle(Palette.ink)
                            .padding(Metrics.s5)
                            .frame(maxWidth: .infinity)
                            .paper(Palette.paper)
                    }
                    Spacer(minLength: 0)
                }
            } action: {
                EmptyView()
            }

        case .onDeck(let hand, let autoReady):
            PhoneScaffold(eyebrow: eyebrow("You're up next"), title: topicTitle, onBack: actions.leave,
                          homer: homerStrip, host: model.event.host.name) {
                codeChip
            } middle: {
                VStack(alignment: .leading, spacing: Metrics.s3) {
                    Text("Your hand").tracked(10, color: Palette.onPage2)
                    // The slips if they fit, else the same hand as chips. Never a scroll.
                    ViewThatFits(in: .vertical) {
                        FormulaHandView(cards: hand, forward: true)
                        FormulaHandView(cards: hand, forward: true, style: .compact)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } action: {
                if autoReady {
                    Text("The arena starts your turn").chip(11)
                } else if let ready = actions.ready {
                    Button(action: ready) { ArrowLabel(title: "Ready") }.buttonStyle(.homer(wide: true))
                }
            }

        case .speaking(let lane, let transcript, let hand, let rescueId, let talking, let level, let pushToTalk):
            let lines = transcript.split(separator: "\n").map(String.init)
            let used = hand.filter(\.used).map(\.text)
            // The rescue card first, then what's still unplayed.
            let open = hand.filter { $0.id == rescueId } + hand.filter { !$0.used && $0.id != rescueId }
            PhoneScaffold(eyebrow: eyebrow("Your verse"), title: topicTitle, onBack: actions.leave,
                          homer: homerStrip, host: model.event.host.name) {
                ViewThatFits(in: .vertical) {
                    VStack(spacing: Metrics.s4) {
                        BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2)
                        if !lines.isEmpty {
                            TranscriptView(lines: Array(lines.suffix(2)), listening: talking, formulas: used, maxLines: 2)
                        }
                        FormulaHandView(cards: hand, raisedId: rescueId, forward: true, style: .compact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(spacing: Metrics.s3) {
                        BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2)
                        if let last = lines.last {
                            TranscriptView(lines: [last], listening: talking, formulas: used, maxLines: 1)
                        }
                        FormulaHandView(cards: open, raisedId: rescueId, forward: true, style: .compact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(spacing: Metrics.s3) {
                        BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2)
                        FormulaHandView(cards: Array(open.prefix(2)), raisedId: rescueId, forward: true, style: .compact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            } action: {
                // Hands-free (the battle default now): nothing to hold, just what to do right now.
                if (model.handsFree || !pushToTalk) && model.typed == nil {
                    HandsFreeBand(lane: lane, level: level, done: actions.done)
                } else {
                    talkBand(talking: talking, level: level, pushToTalk: pushToTalk)
                }
            }

        case .weighing:
            PhoneScaffold(eyebrow: eyebrow(), title: "Homer is weighing it", onBack: actions.leave,
                          homer: homerStrip, host: model.event.host.name) {
                WeighingMark().frame(maxHeight: .infinity)
            } action: {
                EmptyView()
            }

        case .closing(let transcript):
            PhoneScaffold(eyebrow: eyebrow(), title: "The Muse is timing you.", onBack: actions.leave,
                          homer: homerStrip, host: model.event.host.name) {
                VStack(spacing: Metrics.s4) {
                    if !transcript.isEmpty { TranscriptView(lines: transcript, maxLines: 3) }
                    Text("Your turn closes with what you already said.")
                        .font(Typeface.text(15))
                        .foregroundStyle(Palette.ink2)
                        .multilineTextAlignment(.center)
                        .padding(Metrics.s4)
                        .frame(maxWidth: .infinity)
                        .paper()
                    WeighingMark()
                    Spacer(minLength: 0)
                }
            } action: {
                EmptyView()
            }

        case .result(let card, let reveal, let coined):
            PhoneScaffold(eyebrow: eyebrow("Your scores"), onBack: actions.leave,
                          homer: homerStrip, host: model.event.host.name) {
                ViewThatFits(in: .vertical) {
                    scores(ScorecardView(card: card, reveal: reveal, poet: model.me?.fullName, hints: true), coined: reveal >= 1 ? coined : nil)
                    ScrollView { scores(ScorecardView(card: card, reveal: reveal, poet: model.me?.fullName, hints: true), coined: reveal >= 1 ? coined : nil) }
                        .scrollIndicators(.hidden)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            } action: {
                EmptyView()
            }

        case .final(let place, let of, let champion):
            PhoneScaffold(eyebrow: eyebrow("The Agon is over"), onBack: actions.leave,
                          homer: homerStrip, host: model.event.host.name) {
                VStack(spacing: Metrics.s5) {
                    VStack(spacing: Metrics.s2) {
                        Text("You placed").tracked(11, color: Palette.onHero2)
                        Text(roman(place))
                            .font(Typeface.display(96, weight: 600))
                            .foregroundStyle(Palette.onHero)
                            .minimumScaleFactor(0.6)
                        Text("of \(of)").font(Typeface.text(15)).foregroundStyle(Palette.onHero2)
                    }
                    .padding(.vertical, Metrics.s6)
                    .frame(maxWidth: .infinity)
                    .paper(Palette.hero, radius: Metrics.radiusL)
                    if champion.id != model.me?.id {
                        Text("Champion · \(champion.fullName)").chip(11)
                    }
                    Spacer(minLength: 0)
                }
            } action: {
                if let leave = actions.leave {
                    Button(action: leave) { ArrowLabel(title: "Back to the hall") }.buttonStyle(.homer(.secondary, wide: true))
                }
            }

        case .debating(let side, let question, let transcript, let moves, let whisperedId, let talking, let level, let endsAt, let seconds):
            let lines = transcript.split(separator: "\n").map(String.init)
            PhoneScaffold(eyebrow: eyebrow(side.title), title: question, titleLines: 3, onBack: actions.leave,
                          homer: homerStrip, host: model.event.host.name) {
                TurnClockView(endsAt: endsAt, seconds: seconds, size: 56)
            } middle: {
                ViewThatFits(in: .vertical) {
                    VStack(spacing: Metrics.s4) {
                        if !lines.isEmpty {
                            TranscriptView(lines: Array(lines.suffix(2)), listening: talking, maxLines: 2, listener: model.event.host.name)
                        }
                        movesCard(moves, whisperedId: whisperedId)
                    }
                    VStack(spacing: Metrics.s3) {
                        if let last = lines.last {
                            TranscriptView(lines: [last], listening: talking, maxLines: 1, listener: model.event.host.name)
                        }
                        movesCard(moves, whisperedId: whisperedId)
                    }
                    movesCard(moves.filter { !$0.used }, whisperedId: whisperedId)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            } action: {
                // The debate mic is open for the whole turn: no hold pad.
                if model.typed == nil {
                    HandsFreeBand(lane: nil, level: level, done: actions.done)
                } else {
                    talkBand(talking: talking, level: level, pushToTalk: false)
                }
            }

        case .ruling(let ruling, let reveal):
            PhoneScaffold(eyebrow: eyebrow("Socrates rules"), onBack: actions.leave,
                          homer: homerStrip, host: model.event.host.name) {
                ViewThatFits(in: .vertical) {
                    ScorecardView(ruling: ruling, reveal: reveal, poet: model.me?.fullName, hints: true)
                    ScrollView { ScorecardView(ruling: ruling, reveal: reveal, poet: model.me?.fullName, hints: true) }.scrollIndicators(.hidden)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            } action: {
                EmptyView()
            }
        }
    }

    // MARK: Pieces

    private func scores(_ card: ScorecardView, coined: String?) -> some View {
        VStack(spacing: Metrics.s4) {
            card
            if let coined { Text("Into your hoard · \(coined)").chip(11, fill: Palette.gold, color: Palette.ink) }
        }
    }

    private func movesCard(_ moves: [FormulaCard], whisperedId: String?) -> some View {
        VStack(alignment: .leading, spacing: Metrics.s2) {
            Text("Tap a move as you make it").tracked(9)
            MovesHandView(moves: moves, whisperedId: whisperedId) { actions.playMove?($0.id) }
        }
        .padding(Metrics.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Palette.paper2, lifted: false)
    }

    /// The thumb zone while you speak: hold to talk (or the live meter when the
    /// mic is open), with Done as a quiet button above it. Typed verse replaces it when voice is down.
    @ViewBuilder
    private func talkBand(talking: Bool, level: Double, pushToTalk: Bool) -> some View {
        VStack(spacing: Metrics.s2) {
            if let done = actions.done {
                HStack {
                    Spacer()
                    Button("I'm done", action: done).buttonStyle(.homer(.secondary))
                }
            }
            if let typed = model.typed, let type = actions.type {
                TextField("Type your lines", text: Binding(get: { typed }, set: { type($0) }), axis: .vertical)
                    .font(Typeface.display(20))
                    .lineLimit(2...3)
                    .padding(Metrics.s4)
                    .paper()
            } else if pushToTalk {
                HoldToTalkView(isHeld: Binding(get: { talking }, set: { actions.setTalking?($0) }), level: level, compact: true)
                    .frame(height: 124)
            } else {
                HStack(spacing: Metrics.s3) {
                    LiveDot(size: 10)
                    MicLevelView(level: level)
                    Spacer(minLength: 0)
                }
                .padding(Metrics.s4)
                .frame(maxWidth: .infinity)
                .paper()
            }
        }
    }
}

/// Your name plate, in your seat's color.
private struct MyPlate: View {
    let poet: PoetPlate
    var waitingForEpithet: Bool

    var body: some View {
        VStack(spacing: Metrics.s2) {
            Text(poet.name).font(Typeface.display(40, weight: 700)).foregroundStyle(Palette.cream)
            Text(waitingForEpithet ? "Homer is coining your epithet…" : poet.epithet)
                .font(Typeface.display(20, italic: true))
                .foregroundStyle(Palette.cream.opacity(waitingForEpithet ? 0.7 : 1))
        }
        .padding(.vertical, Metrics.s5)
        .frame(maxWidth: .infinity)
        .paper(poet.ink, radius: Metrics.radiusL)
    }
}

/// The thumb zone when the mic is hands-free: nothing to hold, just what to do
/// right now (read off the beat grid) over the live meter, and a big Done.
private struct HandsFreeBand: View {
    /// The verse's grid; nil for a debate (no beat: the mic is simply open).
    let lane: BeatLane?
    let level: Double
    var barsPerLine: Int = 2
    var done: (() -> Void)?

    private enum Now {
        case countIn, live, breathe, finishing

        var title: String {
            switch self {
            case .countIn: "Speak on the drum"
            case .live: "Speak now"
            case .breathe: "Breathe"
            case .finishing: "Last word"
            }
        }

        var subtitle: String {
            switch self {
            case .countIn: "The beat is counting you in"
            case .live: "The mic is open"
            case .breathe: "Next line on the drum"
            case .finishing: "Homer is listening"
            }
        }
    }

    var body: some View {
        VStack(spacing: Metrics.s2) {
            TimelineView(.periodic(from: .now, by: 0.2)) { context in
                let now = state(at: context.date.timeIntervalSince1970 * 1000)
                VStack(spacing: Metrics.s2) {
                    MicLevelView(level: now == .countIn ? 0 : level, tint: Palette.onHero)
                    Text(now.title)
                        .font(Typeface.display(30))
                        .foregroundStyle(Palette.onHero)
                    Text(now.subtitle)
                        .font(Typeface.text(14, weight: 500))
                        .foregroundStyle(Palette.onHero2)
                }
                .padding(.vertical, Metrics.s4)
                .frame(maxWidth: .infinity)
                .paper(now == .live ? Palette.hero : Palette.ink, radius: Metrics.radiusL)
                .animation(Motion.stamp, value: now)
                .accessibilityElement(children: .combine)
            }
            if let done {
                Button(action: done) { ArrowLabel(title: "I'm done") }.buttonStyle(.homer(.secondary, wide: true))
            }
        }
    }

    private func state(at nowMs: Double) -> Now {
        guard let lane else { return .live }
        let beatMs = 60_000 / max(lane.bpm, 1)
        let barMs = beatMs * Double(lane.beatsPerLine)
        let elapsed = nowMs - lane.startedAt
        if elapsed < 0 { return .countIn }
        if elapsed >= barMs * Double(barsPerLine * lane.lines) { return .finishing }
        return Int(elapsed / barMs) % barsPerLine == 0 ? .live : .breathe
    }
}

/// J1: four letters and a name. The Join button rides above the keyboard.
private struct JoinScreen: View {
    /// The room code when it's already known (typed on the Fight screen, or from a link).
    var prefill: String = ""
    var error: String?
    var join: ((String, String) -> Void)?
    var onBack: (() -> Void)?

    @State private var code = ""
    @State private var name = ""
    @AppStorage("poetName") private var savedName = ""
    @FocusState private var focus: Field?

    private enum Field { case code, name }

    var body: some View {
        PhoneScaffold(eyebrow: "Battle", title: "Join the Agon", onBack: onBack) {
            VStack(alignment: .leading, spacing: Metrics.s3) {
                VStack(alignment: .leading, spacing: Metrics.s2) {
                    Text("Room code").tracked(10)
                    TextField("WKRD", text: $code)
                        .font(Typeface.display(40, weight: 500))
                        .tracking(10)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focus, equals: .code)
                        .onChange(of: code) {
                            code = String(code.uppercased().filter(\.isLetter).prefix(4))
                            if code.count == 4, name.isEmpty { focus = .name }
                        }
                        .onSubmit { focus = .name }
                    Text("Your name").tracked(10).padding(.top, Metrics.s2)
                    TextField("Matus", text: $name)
                        .font(Typeface.display(26))
                        .textContentType(.givenName)
                        .submitLabel(.join)
                        .focused($focus, equals: .name)
                        .onSubmit(submit)
                }
                .foregroundStyle(Palette.ink)
                .padding(Metrics.s5)
                .paper(Palette.paper)
                if let error {
                    Text(error).font(Typeface.text(14, weight: 500)).foregroundStyle(Palette.cream)
                        .padding(.horizontal, Metrics.s3).padding(.vertical, Metrics.s2)
                        .paper(Palette.vermilion, radius: Metrics.radiusS, lifted: false)
                }
                Spacer(minLength: 0)
            }
        } action: {
            Button(action: submit) { ArrowLabel(title: "Join") }
                .buttonStyle(.homer(wide: true))
                .disabled(!ready)
        }
        .onAppear {
            if name.isEmpty { name = savedName }
            if code.isEmpty { code = String(prefill.uppercased().prefix(4)) }
            focus = code.count == 4 ? .name : .code
        }
    }

    private var ready: Bool { code.count == 4 && !name.trimmingCharacters(in: .whitespaces).isEmpty && join != nil }

    private func submit() {
        guard ready else { return }
        savedName = name
        join?(code, name)
    }
}
