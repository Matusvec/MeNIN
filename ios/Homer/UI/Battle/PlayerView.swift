import SwiftUI

/// The phone in a battle: each poet's mic and private hand. A header with the
/// room and round, a body that changes with the moment, and Homer's caption.
/// The scene shows behind it (the app shell keeps it always on).
struct PlayerView: View {
    let model: PlayerModel
    var actions = PlayerActions()

    var body: some View {
        VStack(spacing: Metrics.s4) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .id(momentKey)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            if let homer = model.homer {
                CaptionView(text: homer.text, spoken: homer.spoken, speaker: model.event.host.name, whisper: homer.whisper)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, Metrics.s4)
        .padding(.bottom, Metrics.s3)
        .animation(Motion.slide, value: momentKey)
        .animation(Motion.slide, value: model.homer?.text)
    }

    private var momentKey: String {
        switch model.moment {
        case .joining: "join"
        case .micCheck: "mic"
        case .waiting(let w, _): "wait\(w?.id ?? "")"
        case .onDeck: "deck"
        case .speaking: "speak"
        case .weighing: "weigh"
        case .result: "result"
        case .final: "final"
        case .debating: "debate"
        case .ruling: "ruling"
        }
    }

    private var header: some View {
        HStack(spacing: Metrics.s2) {
            WordmarkView(size: 22)
            Spacer()
            if model.round > 0 {
                Text("Round \(roman(model.round)) of \(roman(model.rounds))").chip(10)
            }
            if !model.code.isEmpty, model.me != nil {
                Text(model.code).chip(10)
            }
        }
        .padding(.horizontal, Metrics.s3)
        .padding(.vertical, Metrics.s2)
        .paper(Palette.paper, radius: Metrics.radiusM, lifted: false)
    }

    @ViewBuilder
    private var content: some View {
        switch model.moment {
        case .joining(let error):
            JoinForm(error: error, join: actions.join)

        case .micCheck:
            VStack(spacing: Metrics.s5) {
                if let me = model.me { MyPlate(poet: me, waitingForEpithet: me.epithet.isEmpty) }
                Text("Homer wants to hear your voice. Tap when you're in the hall.")
                    .font(Typeface.text(15))
                    .foregroundStyle(Palette.ink2)
                    .multilineTextAlignment(.center)
                    .padding(Metrics.s4)
                    .paper(Palette.paper)
                if let imHere = actions.imHere {
                    Button(action: imHere) { ArrowLabel(title: "I'm here") }.buttonStyle(.homer)
                }
            }
            .padding(.top, Metrics.s6)

        case .waiting(let watching, let transcript):
            VStack(spacing: Metrics.s4) {
                if let me = model.me { MyPlate(poet: me, waitingForEpithet: false) }
                if let watching {
                    Text("Watching \(watching.name)").chip(10)
                    if !transcript.isEmpty { TranscriptView(lines: transcript, maxLines: 3) }
                } else {
                    Text("You're in the hall. The battle begins soon.")
                        .font(Typeface.display(22, italic: true))
                        .displayLeading(22, 1.15)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .padding(Metrics.s5)
                        .paper(Palette.paper)
                }
            }

        case .onDeck(let hand, let autoReady):
            VStack(spacing: Metrics.s4) {
                Text("You're next").chip(11, fill: Palette.hero, color: Palette.onHero)
                if let theme = model.theme { AnswerLineView(line: theme) }
                ScrollView { FormulaHandView(cards: hand, forward: true) }.scrollIndicators(.hidden)
                if autoReady {
                    Text("The arena starts your turn").chip(10)
                } else if let ready = actions.ready {
                    Button(action: ready) { ArrowLabel(title: "Ready") }.buttonStyle(.homer)
                }
            }

        case .speaking(let lane, let transcript, let hand, let rescueId, let talking, let level, let pushToTalk):
            VStack(spacing: Metrics.s3) {
                BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2)
                if !transcript.isEmpty {
                    TranscriptView(lines: Array(transcript.split(separator: "\n").map(String.init).suffix(2)),
                                   listening: talking, formulas: hand.filter(\.used).map(\.text), maxLines: 2)
                }
                FormulaHandView(cards: hand, raisedId: rescueId, forward: true, style: .compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                if pushToTalk {
                    HoldToTalkView(isHeld: Binding(get: { talking }, set: { actions.setTalking?($0) }), level: level)
                        .frame(height: 150)
                } else {
                    HStack {
                        MicLevelView(level: level)
                        Spacer()
                    }
                    .padding(Metrics.s3)
                    .paper(Palette.paper)
                }
                if let done = actions.done {
                    Button("Done", action: done).buttonStyle(.homer(.secondary))
                }
            }

        case .weighing:
            WeighingMark().padding(.top, Metrics.s8)

        case .result(let card, let reveal, let coined):
            ScrollView {
                VStack(spacing: Metrics.s4) {
                    ScorecardView(card: card, reveal: reveal, poet: model.me?.fullName)
                    if let coined, reveal >= 1 {
                        Text("Into your hoard · \(coined)").chip(11, fill: Palette.gold, color: Palette.ink)
                    }
                }
            }
            .scrollIndicators(.hidden)

        case .final(let place, let of, let champion):
            VStack(spacing: Metrics.s5) {
                VStack(spacing: Metrics.s2) {
                    Text("You placed").tracked(11, color: Palette.onHero2)
                    Text(roman(place))
                        .font(Typeface.display(96, weight: 600))
                        .foregroundStyle(Palette.onHero)
                    Text("of \(of)").font(Typeface.text(15)).foregroundStyle(Palette.onHero2)
                }
                .padding(.vertical, Metrics.s6)
                .frame(maxWidth: .infinity)
                .paper(Palette.hero, radius: Metrics.radiusL)
                if champion.id != model.me?.id {
                    Text("Champion · \(champion.fullName)").chip(11)
                }
            }
            .padding(.top, Metrics.s5)

        case .debating(let side, let question, let transcript, let moves, let whisperedId, let talking, let level, let endsAt, let seconds):
            VStack(spacing: Metrics.s3) {
                HStack(alignment: .center, spacing: Metrics.s3) {
                    SideChip(side: side)
                    Text(question)
                        .font(Typeface.display(17, italic: true))
                        .displayLeading(17, 1.15)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(3)
                    Spacer(minLength: 0)
                    TurnClockView(endsAt: endsAt, seconds: seconds, size: 64)
                }
                .padding(Metrics.s3)
                .paper()
                if !transcript.isEmpty {
                    TranscriptView(lines: Array(transcript.split(separator: "\n").map(String.init).suffix(2)), listening: talking, maxLines: 2,
                                   listener: model.event.host.name)
                }
                VStack(alignment: .leading, spacing: Metrics.s2) {
                    Text("Tap a move as you make it").tracked(9)
                    MovesHandView(moves: moves, whisperedId: whisperedId) { actions.playMove?($0.id) }
                }
                .padding(Metrics.s3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .paper(Palette.paper2, lifted: false)
                Spacer(minLength: 0)
                HoldToTalkView(isHeld: Binding(get: { talking }, set: { actions.setTalking?($0) }), level: level)
                    .frame(height: 150)
                if let done = actions.done {
                    Button("Done", action: done).buttonStyle(.homer(.secondary))
                }
            }

        case .ruling(let ruling, let reveal):
            ScrollView {
                ScorecardView(ruling: ruling, reveal: reveal, poet: model.me?.fullName)
            }
            .scrollIndicators(.hidden)
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

/// J1: four letters and a name.
private struct JoinForm: View {
    var error: String?
    var join: ((String, String) -> Void)?

    @State private var code = ""
    @State private var name = ""
    @AppStorage("poetName") private var savedName = ""
    @FocusState private var focus: Field?

    private enum Field { case code, name }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s4) {
            VStack(alignment: .leading, spacing: Metrics.s2) {
                Text("Join the Agon").font(Typeface.display(31)).padding(.bottom, Metrics.s3)
                Text("Room code").tracked(10)
                TextField("WKRD", text: $code)
                    .font(Typeface.display(44, weight: 500))
                    .tracking(10)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .code)
                    .onChange(of: code) { code = String(code.uppercased().filter(\.isLetter).prefix(4)) }
                Text("Your name").tracked(10).padding(.top, Metrics.s2)
                TextField("Matus", text: $name)
                    .font(Typeface.display(26))
                    .textContentType(.givenName)
                    .focused($focus, equals: .name)
            }
            .foregroundStyle(Palette.ink)
            .padding(Metrics.s5)
            .paper(Palette.paper)
            if let error {
                Text(error).font(Typeface.text(13, weight: 500)).foregroundStyle(Palette.vermilion)
            }
            Button {
                savedName = name
                join?(code, name)
            } label: { ArrowLabel(title: "Join") }
                .buttonStyle(.homer)
                .disabled(code.count != 4 || name.trimmingCharacters(in: .whitespaces).isEmpty || join == nil)
        }
        .padding(.top, Metrics.s5)
        .onAppear {
            if name.isEmpty { name = savedName }
            focus = .code
        }
    }
}
