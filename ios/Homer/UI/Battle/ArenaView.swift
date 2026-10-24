import SwiftUI

/// The arena: the laptop screen turned toward the judges' table. One landscape
/// canvas: a top bar, a stage that changes with each moment of the battle, and
/// Homer's caption along the bottom. The scene shows through every margin.
/// Applies `.arenaStage()` itself, so type scales to the window.
struct ArenaView: View {
    let model: ArenaModel
    var actions = ArenaActions()

    var body: some View {
        ArenaCanvas(model: model, actions: actions).arenaStage().sceneBehind()
    }
}

private struct ArenaCanvas: View {
    let model: ArenaModel
    let actions: ArenaActions
    @Environment(\.stage) private var stage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Counts entrance hits: each one shakes the whole canvas once.
    @State private var slams = 0

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s4 * k) {
            topBar
            moment
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .id(momentKey)
                .overlay {
                    if case .champion = model.moment {
                        ConfettiFall(inks: model.poets.map(\.ink) + [Palette.gold, Palette.cream])
                            .padding(.horizontal, -Metrics.s6 * k)
                            .padding(.top, -200 * k)
                    }
                }
            if let homer = model.homer {
                CaptionView(text: homer.text, spoken: homer.spoken, speaker: model.event.host.name, whisper: homer.whisper)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, Metrics.s6 * k)
        .padding(.vertical, Metrics.s5 * k)
        .animation(Motion.slide, value: momentKey)
        .animation(Motion.slide, value: model.homer?.text)
        .keyframeAnimator(initialValue: CGSize.zero, trigger: slams) { canvas, shake in
            canvas.offset(shake)
        } keyframes: { _ in
            KeyframeTrack(\.width) {
                MoveKeyframe(0)
                LinearKeyframe(16 * k, duration: 0.04)
                LinearKeyframe(-12 * k, duration: 0.06)
                LinearKeyframe(7 * k, duration: 0.06)
                LinearKeyframe(-3 * k, duration: 0.06)
                SpringKeyframe(0, duration: 0.18)
            }
            KeyframeTrack(\.height) {
                MoveKeyframe(0)
                LinearKeyframe(-7 * k, duration: 0.04)
                LinearKeyframe(6 * k, duration: 0.06)
                LinearKeyframe(-3 * k, duration: 0.06)
                SpringKeyframe(0, duration: 0.24)
            }
        }
    }

    /// The scorecard's knocks as arena cues: one per axis, then the total.
    private func knock(of axes: Int) -> (Int) -> Void {
        { i in actions.cue?(i < axes ? .knock(axis: i) : .total) }
    }

    /// The entrance hit: the slam cue for the conductor, and the canvas shake.
    private func slam() {
        if !reduceMotion { slams += 1 }
        actions.cue?(.slam)
    }

    /// Changes only when the kind of moment changes, so inner updates don't re-run transitions.
    private var momentKey: String {
        switch model.moment {
        case .hall: "hall"
        case .lobby: "lobby"
        case .themePick: "theme"
        case .roundTitle: "title\(model.round)"
        case .stepUp(let p, _): "step\(p.id)"
        case .speaking(let p, _, _, _, _): "speak\(p.id)"
        case .judging(let p, _): "judge\(p.id)"
        case .verdict(let p, _, _, _): "verdict\(p.id)"
        case .roundEnd: "end\(model.round)"
        case .finale: "finale"
        case .champion: "champion"
        case .debating(let p, _, _, _, _, _, _): "debate\(p.id)"
        case .ruling(let p, _, _): "ruling\(p.id)"
        case .discus: "discus"
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        let k = stage.scale
        return HStack(spacing: Metrics.s3 * k) {
            WordmarkView(size: 22 * k)
                .padding(.horizontal, Metrics.s4 * k)
                .padding(.vertical, Metrics.s2 * k)
                .paper(Palette.paper, radius: Metrics.radiusM * k, lifted: false)
            Spacer()
            if model.round > 0 {
                Text(model.theme.map { "Round \(roman(model.round)) of \(roman(model.rounds)) · \($0)" } ?? "Round \(roman(model.round)) of \(roman(model.rounds))")
                    .chip(11 * k)
                    .lineLimit(1)
            }
            Spacer()
            if !isLobby {
                Text("Join · \(model.code)").chip(11 * k)
            }
        }
    }

    private var isLobby: Bool {
        switch model.moment {
        case .lobby, .hall: return true
        default: return false
        }
    }

    // MARK: Moments

    @ViewBuilder
    private var moment: some View {
        let k = stage.scale
        switch model.moment {
        case .hall(let entering, let events):
            VStack(alignment: .leading, spacing: Metrics.s4 * k) {
                EventMenuView(events: events, onPick: actions.pickEvent.map { pick in { tile in
                    if let kind = tile.kind { pick(kind) }
                } }, showsHeader: false)
                hallStrip
                Spacer(minLength: 0)
            }
            .overlay(alignment: .bottom) {
                if let entering {
                    EntranceView(poet: entering, onImpact: slam).id(entering.id)
                        .padding(.horizontal, -Metrics.s6 * k)
                }
            }

        case .lobby(let entering):
            HStack(alignment: .center, spacing: Metrics.s6 * k) {
                JoinCardView(code: model.code, url: model.joinURL)
                hall
            }
            .overlay(alignment: .bottom) {
                if let entering {
                    EntranceView(poet: entering, onImpact: slam).id(entering.id)
                        .padding(.horizontal, -Metrics.s6 * k)
                }
            }

        case .themePick(let themes, let picked):
            VStack(spacing: Metrics.s5 * k) {
                Text("Judges, pick the theme").chip(12 * k)
                ThemeCardsView(themes: themes, selected: picked, onPick: actions.pickTheme)
            }

        case .roundTitle:
            RoundTitleView(round: model.round, rounds: model.rounds, theme: model.theme ?? "")

        case .stepUp(let poet, let answer):
            VStack(spacing: Metrics.s5 * k) {
                EntranceView(poet: poet, label: "Up next", onImpact: slam).id(poet.id)
                    .padding(.horizontal, -Metrics.s6 * k)
                if let answer { AnswerLineView(line: answer.line, poet: answer.poet).frame(maxWidth: 560 * k) }
            }

        case .speaking(let poet, let lane, let transcript, let played, let answer):
            HStack(alignment: .top, spacing: Metrics.s5 * k) {
                VStack(alignment: .leading, spacing: Metrics.s4 * k) {
                    poetTag(poet, live: true)
                    if let answer { AnswerLineView(line: answer.line, poet: answer.poet) }
                    TranscriptView(lines: transcript, listening: true, formulas: played.map(\.text), maxLines: 4)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: Metrics.s4 * k) {
                    BeatLaneView(lane: lane, barsPerLine: 2)
                    if let card = played.last {
                        RevealedCardView(card: card, poet: poet.name, onLand: { actions.cue?(.flip) }).id(card.id)
                    }
                }
                .frame(width: 330 * k)
            }

        case .judging(let poet, let transcript):
            VStack(spacing: Metrics.s4 * k) {
                poetTag(poet, live: false)
                TranscriptView(lines: transcript, maxLines: 4).frame(maxWidth: 620 * k)
                WeighingMark()
            }

        case .verdict(let poet, let card, let reveal, let coined):
            HStack(alignment: .center, spacing: Metrics.s6 * k) {
                ScorecardView(card: card, reveal: reveal, poet: poet.fullName, onKnock: knock(of: Axis.allCases.count))
                VStack(spacing: Metrics.s4 * k) {
                    ScoreboardView(poets: model.poets, round: model.round, rounds: model.rounds)
                    if let coined, reveal >= 1 {
                        Text("Into the hoard · \(coined)").chip(12 * k, fill: Palette.gold, color: Palette.ink)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }

        case .roundEnd(let line, let by, let carve):
            // The line is the moment: the tablet takes the room, the standings step aside.
            HStack(alignment: .center, spacing: Metrics.s5 * k) {
                CarvedLineView(line: line, poet: by, progress: carve, onCarve: { actions.cue?(.carve) })
                    .layoutPriority(1)
                ScoreboardView(poets: model.poets, round: model.round, rounds: model.rounds)
                    .frame(width: 236 * k)
            }

        case .finale(let lines, let current):
            SongView(lines: lines, current: current)

        case .champion(let poet):
            HStack(alignment: .center, spacing: Metrics.s6 * k) {
                VStack(spacing: Metrics.s4 * k) {
                    ChampionView(poet: poet, onRematch: actions.rematch, onNewPoets: actions.newPoets,
                                 onCrown: { actions.cue?(.crown) })
                    if let backToHall = actions.backToHall {
                        Button("Back to the hall", action: backToHall).buttonStyle(.homer(.secondary))
                    }
                }
                ScoreboardView(poets: model.poets, round: model.rounds, rounds: model.rounds)
            }

        case .debating(let poet, let side, let question, let transcript, let played, let endsAt, let seconds):
            VStack(spacing: Metrics.s4 * k) {
                QuestionCard(question: question, round: model.round > 0 ? model.round : nil)
                HStack(alignment: .top, spacing: Metrics.s5 * k) {
                    VStack(alignment: .leading, spacing: Metrics.s4 * k) {
                        HStack(spacing: Metrics.s3 * k) {
                            poetTag(poet, live: true)
                            SideStamp(side: side, onImpact: slam).id("\(poet.id)-\(side.rawValue)")
                        }
                        TranscriptView(lines: transcript, listening: true, maxLines: 4, listener: model.event.host.name)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .trailing, spacing: Metrics.s4 * k) {
                        TurnClockView(endsAt: endsAt, seconds: seconds, size: 140)
                        if let move = played.last {
                            RevealedCardView(card: move, poet: poet.name, onLand: { actions.cue?(.flip) }).id(move.id)
                        }
                    }
                    .frame(width: 300 * k, alignment: .trailing)
                }
            }

        case .ruling(let poet, let ruling, let reveal):
            HStack(alignment: .center, spacing: Metrics.s6 * k) {
                ScorecardView(ruling: ruling, reveal: reveal, poet: poet.fullName, onKnock: knock(of: ruling.axes.count))
                ScoreboardView(poets: model.poets, round: model.round, rounds: model.rounds)
            }

        case .discus(let discus):
            DiscusArenaView(model: discus)
        }
    }

    /// The hall in the lobby: who has joined, and the button to begin.
    private var hall: some View {
        let k = stage.scale
        return VStack(alignment: .leading, spacing: Metrics.s3 * k) {
            Text(model.poets.isEmpty ? "Waiting for poets" : "In the hall").tracked(11 * k, color: Palette.onHero2)
            ForEach(model.poets) { poet in
                HStack(spacing: Metrics.s3 * k) {
                    Capsule().fill(poet.ink).frame(width: 4 * k, height: 28 * k)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(poet.name).font(Typeface.display(22, on: stage, weight: 600)).foregroundStyle(Palette.onHero).sturdy(22)
                        if !poet.epithet.isEmpty {
                            Text(poet.epithet).font(Typeface.display(14, on: stage, italic: true)).foregroundStyle(Palette.onHero2).sturdy(14)
                        }
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            if let begin = actions.begin, !isHall {
                Button(action: begin) { ArrowLabel(title: model.poets.count < 2 ? "Need two poets" : "Begin the Agon") }
                    .buttonStyle(HomerButtonStyle(kind: .cream))
                    .disabled(model.poets.count < 2)
                    .padding(.top, Metrics.s2 * k)
            }
        }
        .padding(Metrics.s5 * k)
        .frame(minWidth: 260 * k, alignment: .leading)
        .paper(Palette.hero, radius: Metrics.radiusL * k)
        .animation(Motion.slide, value: model.poets.map(\.id))
    }

    /// The hall's bottom strip: a small QR and the code, then everyone in the hall as seat-colored chips.
    private var hallStrip: some View {
        let k = stage.scale
        return HStack(spacing: Metrics.s4 * k) {
            HStack(spacing: Metrics.s3 * k) {
                QRImage(text: model.joinURL)
                    .frame(width: 64 * k, height: 64 * k)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Join").tracked(10 * k, color: Palette.ink2)
                    Text(model.code).font(Typeface.display(34, on: stage, weight: 500)).tracking(4 * k).foregroundStyle(Palette.accent)
                }
            }
            .padding(Metrics.s3 * k)
            .paper(Palette.paper, radius: Metrics.radiusM * k)
            // Never cut a plate off on a screen nobody touches: drop the epithets, then shrink, before scrolling.
            ViewThatFits(in: .horizontal) {
                poetPlates(epithets: true, scale: 1)
                poetPlates(epithets: false, scale: 1)
                poetPlates(epithets: false, scale: 0.8)
                ScrollView(.horizontal) { poetPlates(epithets: false, scale: 0.8) }.scrollIndicators(.hidden)
            }
        }
        .animation(Motion.slide, value: model.poets.map(\.id))
    }

    private func poetPlates(epithets: Bool, scale: CGFloat) -> some View {
        let k = stage.scale
        return HStack(spacing: Metrics.s2 * k) {
            ForEach(model.poets) { poet in
                HStack(spacing: Metrics.s2 * k) {
                    Text(poet.name).font(Typeface.display(19 * scale, on: stage, weight: 600)).sturdy(19 * scale)
                    if epithets && !poet.epithet.isEmpty {
                        Text(poet.epithet).font(Typeface.display(14, on: stage, italic: true)).sturdy(14).opacity(0.85)
                    }
                }
                .foregroundStyle(Palette.cream)
                .padding(.horizontal, Metrics.s4 * k * scale)
                .padding(.vertical, Metrics.s2 * k)
                .paper(poet.ink, radius: 100, lifted: false)
                .fixedSize()
                .transition(.scale.combined(with: .opacity))
            }
            if model.poets.isEmpty {
                Text("Waiting for poets").chip(11 * k)
            }
        }
    }

    private var isHall: Bool {
        if case .hall = model.moment { return true }
        return false
    }

    /// The poet on the mic: a seat-colored plate.
    private func poetTag(_ poet: PoetPlate, live: Bool) -> some View {
        let k = stage.scale
        return HStack(spacing: Metrics.s3 * k) {
            if live { LiveDot(size: 9 * k) }
            Text(poet.name).font(Typeface.display(26, on: stage, weight: 700)).foregroundStyle(Palette.cream).sturdy(26)
            if !poet.epithet.isEmpty {
                Text(poet.epithet).font(Typeface.display(17, on: stage, italic: true)).foregroundStyle(Palette.cream.opacity(0.85)).sturdy(17)
            }
        }
        .padding(.horizontal, Metrics.s4 * k)
        .padding(.vertical, Metrics.s2 * k)
        .paper(poet.ink, radius: Metrics.radiusM * k)
    }
}

/// T4: "Homer is weighing it." Three dots that rise and fall like a held breath.
struct WeighingMark: View {
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: Metrics.s3 * k) {
                Text("Homer is weighing it").tracked(12 * k, color: Palette.ink2)
                HStack(spacing: 5 * k) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle().fill(Palette.accent)
                            .frame(width: 7 * k, height: 7 * k)
                            .offset(y: -4 * k * max(0, sin(t * 4 - Double(i) * 0.7)))
                    }
                }
            }
            .padding(.horizontal, Metrics.s5 * k)
            .padding(.vertical, Metrics.s3 * k)
            .paper(Palette.paper, radius: 100)
        }
    }
}

/// B6: the stitched song. The line being performed is large and centered;
/// sung lines step back above it, the next one waits below.
struct SongView: View {
    let lines: [String]
    let current: Int
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s4 * k) {
            Text("The song").chip(12 * k)
            VStack(spacing: Metrics.s3 * k) {
                ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                    let d = i - current
                    if abs(d) <= 2 {
                        Text(line)
                            .font(Typeface.display((d == 0 ? 40 : 24), on: stage, weight: d == 0 ? 600 : 400, italic: d != 0))
                            .displayLeading((d == 0 ? 40 : 24) * k, 1.1)
                            .foregroundStyle(d == 0 ? Palette.onHero : Palette.onHero2)
                            .opacity(d == 0 ? 1 : (abs(d) == 1 ? 0.7 : 0.35))
                            .multilineTextAlignment(.center)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, Metrics.s7 * k)
            .padding(.vertical, Metrics.s6 * k)
            .frame(maxWidth: 900 * k)
            .paper(Palette.hero, radius: Metrics.radiusL * k)
            .animation(Motion.slide, value: current)
        }
    }
}

/// H0: the arena before a room exists. The hall's front door: the wordmark,
/// the two hosts, and the ways in.
struct ArenaStartView: View {
    /// e.g. "Connecting…" or a server error; nil when ready.
    var status: String?
    /// A room this arena hosted before, offered for a resume.
    var resumeCode: String?
    var onStart: (() -> Void)?
    var onDemo: (() -> Void)?
    var onResume: (() -> Void)?

    var body: some View {
        ArenaStartCanvas(status: status, resumeCode: resumeCode, onStart: onStart, onDemo: onDemo, onResume: onResume)
            .arenaStage()
            .sceneBehind()
    }
}

private struct ArenaStartCanvas: View {
    var status: String?
    var resumeCode: String?
    var onStart: (() -> Void)?
    var onDemo: (() -> Void)?
    var onResume: (() -> Void)?
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(alignment: .center, spacing: Metrics.s7 * k) {
            VStack(alignment: .leading, spacing: Metrics.s4 * k) {
                WordmarkView(size: 54 * k, showsGreek: true)
                Text("The Agon")
                    .font(Typeface.display(30, on: stage, italic: true))
                    .foregroundStyle(Palette.ink)
                Text("Poets join from their phones. Homer judges. The best line is carved.")
                    .font(Typeface.text(15 * k))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Metrics.s3 * k) {
                    if let onStart { Button(action: onStart) { ArrowLabel(title: "Start a battle") }.buttonStyle(.homer) }
                    if let onDemo { Button("Demo for the judges", action: onDemo).buttonStyle(.homer(.secondary)) }
                }
                .padding(.top, Metrics.s2 * k)
                .disabled(status != nil)
                if let resumeCode, let onResume {
                    Button("Resume \(resumeCode)", action: onResume).buttonStyle(.homer(.quiet))
                        .disabled(status != nil)
                }
                if let status {
                    HStack(spacing: Metrics.s2 * k) {
                        LiveDot(size: 7 * k)
                        Text(status).font(Typeface.text(13 * k, weight: 500)).foregroundStyle(Palette.ink2)
                    }
                }
            }
            .padding(Metrics.s6 * k)
            .frame(maxWidth: 440 * k, alignment: .leading)
            .paper(Palette.paper, radius: Metrics.radiusL * k)
            .layoutPriority(1)
            HStack(spacing: Metrics.s4 * k) {
                HostMedallion(host: .homer, size: 128 * k)
                HostMedallion(host: .socrates, size: 128 * k).opacity(0.85)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metrics.s6 * k)
    }
}
