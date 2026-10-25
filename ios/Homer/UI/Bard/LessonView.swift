import SwiftUI

/// One Bard lesson, start to finish (docs/ux-flow.md section 2, L0–L5): the
/// title, Homer showing the move, Homer naming it, your try, his one note, and
/// the landing. Calm and controlled, a pro coaching tool. Props in; the iOS
/// lead's BardLessonSession fills the model.
struct LessonModel: Equatable {
    enum Phase: Equatable {
        case loading
        case failed(String)
        /// L0 · The lesson's number, name and move.
        case title
        /// L1 · Homer performs the move over the beat.
        case demo(lane: BeatLane?, verse: [String])
        /// L2 · Homer names the move; his verse stays as the model.
        case naming(lane: BeatLane?, verse: [String])
        /// L3 · Your try. `model` is Homer's verse, faded beside yours; `helpHalf` is the half he gives you after misses (P10).
        case trying(lane: BeatLane?, transcript: [String], listening: Bool, level: Double,
                    model: [String], helpHalf: String?, hand: [FormulaCard], rescueId: String?)
        /// Homer is weighing the try.
        case weighing(transcript: [String])
        /// L4 · One note, never more. `beatScore` is the try's Beat (P20).
        case note(transcript: [String], note: String?, beatScore: Int?)
        /// L5 · Landed.
        case landed(transcript: [String], note: String?, beatScore: Int?)
    }

    var number: Int
    var title: String
    var move: String
    var phase: Phase = .loading
    var tryNo: Int = 0
    var homer: HomerLine?
    /// When voice is unavailable: the typed fallback's text.
    var typed: String?
    /// A wait over the lesson (Homer warming up, reconnecting).
    var wait: WaitState? = nil
}

struct LessonActions {
    var done: (() -> Void)?
    var again: (() -> Void)?
    var retry: (() -> Void)?
    var next: (() -> Void)?
    var spar: (() -> Void)?
    var type: ((String) -> Void)?
    /// The back chevron: out of the lesson.
    var back: (() -> Void)?

    init(done: (() -> Void)? = nil, again: (() -> Void)? = nil, retry: (() -> Void)? = nil,
         next: (() -> Void)? = nil, spar: (() -> Void)? = nil, type: ((String) -> Void)? = nil,
         back: (() -> Void)? = nil) {
        self.back = back
        self.done = done
        self.again = again
        self.retry = retry
        self.next = next
        self.spar = spar
        self.type = type
    }
}

struct LessonView: View {
    let model: LessonModel
    var actions = LessonActions()

    @Environment(\.stage) private var stage

    var body: some View {
        if stage.isArena { arenaBody } else { phoneBody }
    }

    // MARK: Phone

    /// A PhoneScaffold: the lesson on top, the work in the middle, the next step in the thumb zone.
    private var phoneBody: some View {
        PhoneScaffold(eyebrow: "Bard · Lesson \(model.number)" + (model.tryNo > 0 ? " · Try \(model.tryNo)" : ""),
                      title: model.phase == .title ? nil : model.title, onBack: actions.back,
                      homer: model.homer.flatMap { $0.whisper ? nil : $0 }, wait: model.wait) {
            ZStack {
                phoneMiddle
                    .id(phaseKey)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .animation(Motion.slide, value: phaseKey)
        } action: {
            phoneAction
        }
    }

    @ViewBuilder
    private var phoneMiddle: some View {
        switch model.phase {
        case .loading:
            WaitLine(state: .settingLesson).frame(maxHeight: .infinity)

        case .failed(let why):
            Text(why).font(Typeface.text(16)).foregroundStyle(Palette.ink2).multilineTextAlignment(.center)
                .padding(Metrics.s5).frame(maxWidth: .infinity).paper().frame(maxHeight: .infinity)

        case .title:
            VStack(spacing: Metrics.s3) {
                Text("Lesson").tracked(12, color: Palette.onHero2)
                Text(roman(model.number)).font(Typeface.display(96, weight: 500)).foregroundStyle(Palette.onHero)
                    .minimumScaleFactor(0.6)
                Text(model.title).font(Typeface.display(30)).foregroundStyle(Palette.onHero)
                    .multilineTextAlignment(.center).minimumScaleFactor(0.8)
                Text(model.move).font(Typeface.display(18, italic: true)).foregroundStyle(Palette.onHero2)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Metrics.s6)
            .padding(.horizontal, Metrics.s5)
            .frame(maxWidth: .infinity)
            .paper(Palette.hero, radius: Metrics.radiusL)
            .frame(maxHeight: .infinity)

        case .demo(let lane, let verse), .naming(let lane, let verse):
            let running = { if case .demo = model.phase { return true } else { return false } }()
            let title = running ? "Homer shows it" : "The model"
            // The full lane teaches the move when there's room; else the pulse; else just the verse.
            ViewThatFits(in: .vertical) {
                VStack(spacing: Metrics.s4) {
                    if let lane { BeatLaneView(lane: lane, barsPerLine: 2, running: running) }
                    VerseCard(title: title, lines: verse)
                }
                VStack(spacing: Metrics.s4) {
                    if let lane { BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2, running: running) }
                    VerseCard(title: title, lines: verse)
                }
                VerseCard(title: title, lines: verse)
            }

        case .trying(let lane, let transcript, let listening, _, _, let helpHalf, let hand, let rescueId):
            ViewThatFits(in: .vertical) {
                VStack(spacing: Metrics.s4) {
                    if let lane { BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2) }
                    if let helpHalf { VerseCard(title: "Homer starts it. You finish", lines: [helpHalf + " …"]) }
                    tryWords(transcript, listening: listening, max: 2)
                    if !hand.isEmpty {
                        FormulaHandView(cards: hand, raisedId: rescueId, forward: true, style: .compact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                VStack(spacing: Metrics.s3) {
                    if let lane { BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2) }
                    if let helpHalf { VerseCard(title: "Homer starts it. You finish", lines: [helpHalf + " …"]) }
                    tryWords(transcript, listening: listening, max: 1)
                }
                VStack(spacing: Metrics.s3) {
                    if let lane { BeatLaneView(lane: lane, style: .pulse, barsPerLine: 2) }
                    tryWords(transcript, listening: listening, max: 1)
                }
            }

        case .weighing(let transcript):
            VStack(spacing: Metrics.s4) {
                if !transcript.isEmpty { TranscriptView(lines: transcript, maxLines: 3) }
                WaitLine(state: .listeningBack)
                Spacer(minLength: 0)
            }

        case .note(let transcript, let note, let beatScore):
            ViewThatFits(in: .vertical) {
                VStack(spacing: Metrics.s4) {
                    if !transcript.isEmpty { TranscriptView(lines: transcript, maxLines: 3) }
                    NoteCard(note: note, beatScore: beatScore)
                }
                NoteCard(note: note, beatScore: beatScore)
            }

        case .landed(let transcript, let note, let beatScore):
            ViewThatFits(in: .vertical) {
                VStack(spacing: Metrics.s4) {
                    LandedSeal()
                    if let best = transcript.last, !best.isEmpty { VerseCard(title: "Your landing line", lines: [best]) }
                    if note != nil || beatScore != nil { NoteCard(note: note, beatScore: beatScore) }
                }
                VStack(spacing: Metrics.s4) {
                    LandedSeal()
                    if let best = transcript.last, !best.isEmpty { VerseCard(title: "Your landing line", lines: [best]) }
                }
                LandedSeal()
            }
        }
    }

    @ViewBuilder
    private func tryWords(_ transcript: [String], listening: Bool, max: Int) -> some View {
        if !transcript.isEmpty {
            TranscriptView(lines: Array(transcript.suffix(max)), listening: listening, maxLines: max)
        } else if listening {
            Text("Your turn. Speak on the beat").chip(11, fill: Palette.hero, color: Palette.onHero)
        }
    }

    @ViewBuilder
    private var phoneAction: some View {
        switch model.phase {
        case .failed:
            if let retry = actions.retry {
                Button(action: retry) { ArrowLabel(title: "Call Homer back") }.buttonStyle(.homer(wide: true))
            }
        case .trying(_, _, _, let level, _, _, _, _):
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
                        MicLevelView(level: level)
                    }
                    Spacer(minLength: 0)
                    if let done = actions.done { Button("I'm done", action: done).buttonStyle(.homer) }
                }
                .padding(Metrics.s3)
                .frame(maxWidth: .infinity)
                .paper()
            }
        case .landed:
            VStack(spacing: Metrics.s2) {
                if actions.again != nil || actions.spar != nil {
                    HStack(spacing: Metrics.s2) {
                        if let again = actions.again { Button("Once more", action: again).buttonStyle(.homer(.secondary, wide: true)) }
                        if let spar = actions.spar { Button("Spar with Homer", action: spar).buttonStyle(.homer(.secondary, wide: true)) }
                    }
                }
                if let next = actions.next {
                    Button(action: next) { ArrowLabel(title: "Teach me more") }.buttonStyle(.homer(wide: true))
                }
            }
        default:
            EmptyView()
        }
    }

    // MARK: Arena (a Mac or an iPad seated for a study)

    private var arenaBody: some View {
        let k = stage.scale
        return VStack(spacing: Metrics.s4 * k) {
            if model.phase != .title { header }
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
        case .loading: "loading"
        case .failed: "failed"
        case .title: "title"
        case .demo: "demo"
        case .naming: "naming"
        case .trying: "try\(model.tryNo)"
        case .weighing: "weighing"
        case .note: "note\(model.tryNo)"
        case .landed: "landed"
        }
    }

    /// The lesson, always in view while you work: number, name, the move in one line.
    private var header: some View {
        let k = stage.scale
        return HStack(alignment: .center, spacing: Metrics.s3 * k) {
            VStack(alignment: .leading, spacing: 2 * k) {
                Text("Bard  /  Lesson \(model.number)").tracked(10 * k, color: Palette.accent)
                Text(model.title).font(Typeface.display(26, on: stage)).foregroundStyle(Palette.ink)
                Text(model.move).font(Typeface.text(13 * k)).foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if model.tryNo > 0 { Text("Try \(model.tryNo)").chip(10 * k) }
        }
        .padding(Metrics.s4 * k)
        .paper(radius: Metrics.radiusL * k)
    }

    @ViewBuilder
    private var content: some View {
        let k = stage.scale
        switch model.phase {
        case .loading:
            WeighingMarkLabel(text: "Homer is setting the lesson").padding(.top, Metrics.s8 * k)

        case .failed(let why):
            VStack(spacing: Metrics.s4 * k) {
                Text(why).font(Typeface.text(15 * k)).foregroundStyle(Palette.ink2).multilineTextAlignment(.center)
                if let retry = actions.retry { Button("Call Homer back", action: retry).buttonStyle(.homer) }
            }
            .padding(Metrics.s5 * k)
            .paper()
            .padding(.top, Metrics.s7 * k)

        case .title:
            VStack(spacing: Metrics.s3 * k) {
                Text("Lesson").tracked(12 * k, color: Palette.onHero2)
                Text(roman(model.number)).font(Typeface.display(110, on: stage, weight: 500)).foregroundStyle(Palette.onHero)
                Text(model.title).font(Typeface.display(34, on: stage)).foregroundStyle(Palette.onHero)
                Text(model.move).font(Typeface.display(18, on: stage, italic: true)).foregroundStyle(Palette.onHero2)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Metrics.s7 * k)
            .padding(.horizontal, Metrics.s5 * k)
            .frame(maxWidth: .infinity)
            .paper(Palette.hero, radius: Metrics.radiusL * k)
            .padding(.top, Metrics.s7 * k)

        case .demo(let lane, let verse):
            VStack(spacing: Metrics.s4 * k) {
                if let lane { BeatLaneView(lane: lane, barsPerLine: 2) }
                VerseCard(title: "Homer shows it", lines: verse)
            }

        case .naming(let lane, let verse):
            VStack(spacing: Metrics.s4 * k) {
                if let lane { BeatLaneView(lane: lane, barsPerLine: 2, running: false) }
                VerseCard(title: "The model", lines: verse)
            }

        case .trying(let lane, let transcript, let listening, let level, let modelVerse, let helpHalf, let hand, let rescueId):
            VStack(spacing: Metrics.s3 * k) {
                if let lane { BeatLaneView(lane: lane, barsPerLine: 2) }
                if let helpHalf { VerseCard(title: "Homer starts it. You finish", lines: [helpHalf + " …"]) }
                if !transcript.isEmpty {
                    TranscriptView(lines: transcript, listening: listening, maxLines: 4)
                } else if listening {
                    Text("Your turn. Speak on the beat").chip(11 * k, fill: Palette.hero, color: Palette.onHero)
                }
                if stage.isArena, !modelVerse.isEmpty { VerseCard(title: "The model", lines: modelVerse).opacity(0.7) }
                if !hand.isEmpty {
                    FormulaHandView(cards: hand, raisedId: rescueId, forward: true, style: .compact)
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
                    MicLevelView(level: level)
                    Spacer()
                    if let done = actions.done { Button("I'm done", action: done).buttonStyle(.homer(.secondary)) }
                }
                .padding(Metrics.s3 * k)
                .paper()
            }

        case .weighing(let transcript):
            VStack(spacing: Metrics.s4 * k) {
                if !transcript.isEmpty { TranscriptView(lines: transcript, maxLines: 4) }
                WeighingMark()
            }

        case .note(let transcript, let note, let beatScore):
            VStack(spacing: Metrics.s4 * k) {
                if !transcript.isEmpty { TranscriptView(lines: transcript, maxLines: 4) }
                NoteCard(note: note, beatScore: beatScore)
            }

        case .landed(let transcript, let note, let beatScore):
            VStack(spacing: Metrics.s4 * k) {
                LandedSeal()
                if let best = transcript.last, !best.isEmpty {
                    VerseCard(title: "Your landing line", lines: [best])
                }
                if note != nil || beatScore != nil { NoteCard(note: note, beatScore: beatScore) }
                HStack(spacing: Metrics.s3 * k) {
                    if let again = actions.again { Button("Once more", action: again).buttonStyle(.homer(.secondary)) }
                    if let next = actions.next { Button(action: next) { ArrowLabel(title: "Teach me more") }.buttonStyle(.homer) }
                    if let spar = actions.spar { Button("Spar with Homer", action: spar).buttonStyle(.homer(.secondary)) }
                }
            }
        }
    }
}

/// Homer's verse (or a line of it) on paper, set in the bard's serif.
struct VerseCard: View {
    let title: String
    let lines: [String]
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(alignment: .leading, spacing: Metrics.s2 * k) {
            Text(title).tracked(10 * k, color: Palette.accent)
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(Typeface.display(21, on: stage, italic: true))
                    .displayLeading(21 * k, 1.18)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Metrics.s4 * k)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(radius: Metrics.radiusL * k)
    }
}

/// L4: Homer's single note, with the try's Beat score small beside it (P20).
private struct NoteCard: View {
    let note: String?
    let beatScore: Int?
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(alignment: .top, spacing: Metrics.s3 * k) {
            Capsule().fill(Palette.accent).frame(width: 3 * k)
            VStack(alignment: .leading, spacing: Metrics.s1 * k) {
                Text("Homer's note").tracked(10 * k, color: Palette.accent)
                if let note {
                    Text(note)
                        .font(Typeface.display(22, on: stage, italic: true))
                        .displayLeading(22 * k, 1.18)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if let beatScore {
                VStack(spacing: 0) {
                    Text("\(beatScore)").font(Typeface.display(34, on: stage, weight: 500)).foregroundStyle(beatScore >= 8 ? Palette.goldDeep : Palette.ink)
                    Text("Beat").tracked(9 * k, color: Palette.ink3)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(Metrics.s4 * k)
        .paper(radius: Metrics.radiusL * k)
    }
}

/// L5: the lesson lands. A gold seal stamped on the page.
private struct LandedSeal: View {
    @State private var stamped = false
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        ZStack {
            Circle().fill(Palette.gold)
            Circle().strokeBorder(Palette.cream.opacity(0.85), lineWidth: 2 * k).padding(6 * k)
            VStack(spacing: 0) {
                Text("Landed").font(Typeface.display(26, on: stage, weight: 600)).foregroundStyle(Palette.ink)
                Text("It's yours now").tracked(8 * k, color: Palette.ink2)
            }
        }
        .frame(width: 140 * k, height: 140 * k)
        .rotationEffect(.degrees(stamped ? -6 : -20))
        .scaleEffect(stamped ? 1 : 1.6)
        .opacity(stamped ? 1 : 0)
        .shadow(color: Palette.ink.opacity(0.2), radius: 12 * k, y: 6 * k)
        .onAppear { withAnimation(Motion.stamp) { stamped = true } }
        .sensoryFeedback(.success, trigger: stamped)
        .accessibilityLabel("Landed")
    }
}

/// A short status with the weighing dots, for loading moments.
private struct WeighingMarkLabel: View {
    let text: String
    var body: some View {
        VStack(spacing: Metrics.s3) {
            WeighingMark()
            Text(text).font(Typeface.text(13)).foregroundStyle(Palette.ink2)
        }
    }
}
