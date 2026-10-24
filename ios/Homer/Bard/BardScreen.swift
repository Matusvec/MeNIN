import SwiftUI

/// Bard mode: lesson 1 for now (the 6 PM study runs on it). Composed from the art lead's
/// components with bare layout; a dedicated LessonView can replace the body.
struct BardScreen: View {
    let app: AppModel
    var lessonId = "beat"
    @State private var session: BardLessonSession?

    var body: some View {
        ZStack {
            Color.clear
            if let session { content(session) }
        }
        .task {
            let session = BardLessonSession(agent: AgentClient.configured, scene: app.scene, poetName: app.poetName)
            self.session = session
            session.start(lessonId: lessonId)
        }
        .onDisappear { session?.stop() }
    }

    @ViewBuilder
    private func content(_ s: BardLessonSession) -> some View {
        VStack(spacing: Metrics.s4) {
            if let lesson = s.lesson {
                VStack(spacing: Metrics.s1) {
                    Text("Lesson \(lesson.n)").font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
                    Text(lesson.title).font(.title2.weight(.semibold))
                    Text(lesson.move).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            }
            switch s.phase {
            case .loading:
                ProgressView()
            case .failed(let why):
                Text(why).multilineTextAlignment(.center)
                Button("Try again") { s.start(lessonId: lessonId) }.buttonStyle(.borderedProminent)
            case .title, .naming:
                Spacer(minLength: 0)
            case .demo:
                if let lane = s.demoLane { BeatLaneView(lane: lane, barsPerLine: 2) }
                if let demo = s.lesson?.demo { TranscriptView(lines: demo, maxLines: 4) }
            case .trying:
                if let clock = s.turn.clock {
                    BeatLaneView(lane: BeatLane(bpm: clock.bpm, beatsPerLine: 4, lines: clock.lines,
                                                startedAt: clock.beatAtMs, words: s.turn.hitMarks), barsPerLine: clock.barsPerLine)
                }
                if let half = s.helpHalf { AnswerLineView(line: half, poet: "Homer") }
                TranscriptView(lines: BattlePresenter.lines(s.turn.transcript), listening: s.turn.listening)
                MicLevelView(level: s.turn.level)
                if let why = s.turn.voiceNote {
                    Text(why).font(.caption).foregroundStyle(.secondary)
                    TextField("Your lines, one per row", text: Binding(get: { s.turn.typed }, set: { s.turn.typed = $0 }), axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                }
                Button("Done") { s.finishTry() }
            case .weighing:
                TranscriptView(lines: BattlePresenter.lines(s.lastTry))
                ProgressView()
            case .note, .landed:
                TranscriptView(lines: BattlePresenter.lines(s.lastTry))
                HStack(alignment: .firstTextBaseline, spacing: Metrics.s3) {
                    if let note = s.note { Text(note).italic() }
                    if let beat = s.beatScore {
                        // P20: the try's Beat score, small, beside Homer's note.
                        Text("Beat \(beat)").font(.caption.monospacedDigit()).padding(.horizontal, 6).padding(.vertical, 2)
                            .overlay(Capsule().stroke(.secondary.opacity(0.5)))
                    }
                }
                if s.phase == .landed {
                    Text("Landed").font(.headline)
                    HStack {
                        Button("Again") { s.again() }.buttonStyle(.borderedProminent)
                        Button("Spar") { app.route = .practice }
                    }
                }
            }
            Spacer(minLength: 0)
            if let line = s.turn.homer.caption {
                CaptionView(text: line.text, spoken: s.turn.homer.spoken, whisper: line.whisper)
            }
        }
        .padding(Metrics.s4)
    }
}
