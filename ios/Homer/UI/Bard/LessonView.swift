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
}

struct LessonActions {
    var done: (() -> Void)?
    var again: (() -> Void)?
    var retry: (() -> Void)?
    var next: (() -> Void)?
    var spar: (() -> Void)?
    var type: ((String) -> Void)?

    init(done: (() -> Void)? = nil, again: (() -> Void)? = nil, retry: (() -> Void)? = nil,
         next: (() -> Void)? = nil, spar: (() -> Void)? = nil, type: ((String) -> Void)? = nil) {
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
        let k = stage.scale
        VStack(spacing: Metrics.s4 * k) {
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
                Text(model.title).font(Typeface.display(26 * k)).foregroundStyle(Palette.ink)
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
                if let retry = actions.retry { Button("Try again", action: retry).buttonStyle(.homer) }
            }
            .padding(Metrics.s5 * k)
            .paper()
            .padding(.top, Metrics.s7 * k)

        case .title:
            VStack(spacing: Metrics.s3 * k) {
                Text("Lesson").tracked(12 * k, color: Palette.onHero2)
                Text(roman(model.number)).font(Typeface.display(110 * k, weight: 500)).foregroundStyle(Palette.onHero)
                Text(model.title).font(Typeface.display(34 * k)).foregroundStyle(Palette.onHero)
                Text(model.move).font(Typeface.display(18 * k, italic: true)).foregroundStyle(Palette.onHero2)
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
                        .font(Typeface.display(20 * k))
                        .lineLimit(2...4)
                        .padding(Metrics.s4 * k)
                        .paper()
                }
                HStack {
                    MicLevelView(level: level)
                    Spacer()
                    if let done = actions.done { Button("Done", action: done).buttonStyle(.homer(.secondary)) }
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
                    if let again = actions.again { Button("Again", action: again).buttonStyle(.homer(.secondary)) }
                    if let next = actions.next { Button(action: next) { ArrowLabel(title: "Next lesson") }.buttonStyle(.homer) }
                    if let spar = actions.spar { Button("Spar", action: spar).buttonStyle(.homer(.secondary)) }
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
                    .font(Typeface.display(21 * k, italic: true))
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
                        .font(Typeface.display(22 * k, italic: true))
                        .displayLeading(22 * k, 1.18)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if let beatScore {
                VStack(spacing: 0) {
                    Text("\(beatScore)").font(Typeface.display(34 * k, weight: 500)).foregroundStyle(beatScore >= 8 ? Palette.goldDeep : Palette.ink)
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
                Text("Landed").font(Typeface.display(26 * k, weight: 600)).foregroundStyle(Palette.ink)
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
