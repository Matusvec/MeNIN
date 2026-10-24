import SwiftUI

/// Bard mode: lesson 1 for now (the 6 PM study runs on it). The art lead's LessonView,
/// fed from BardLessonSession.
struct BardScreen: View {
    let app: AppModel
    var lessonId = "beat"
    @State private var session: BardLessonSession?

    var body: some View {
        ZStack {
            Color.clear
            if let session { LessonView(model: model(session), actions: actions(session)) }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            let session = BardLessonSession(agent: AgentClient.configured, scene: app.scene, poetName: app.poetName)
            self.session = session
            session.start(lessonId: lessonId)
        }
        .onDisappear { session?.stop() }
    }

    private func model(_ s: BardLessonSession) -> LessonModel {
        let lesson = s.lesson
        let transcript = BattlePresenter.lines(s.phase == .trying ? s.turn.transcript : s.lastTry)
        var m = LessonModel(number: lesson?.n ?? 1, title: lesson?.title ?? "", move: lesson?.move ?? "",
                            tryNo: s.tryNo, homer: BattlePresenter.homerLine(s.turn.homer),
                            typed: s.turn.voiceNote == nil ? nil : s.turn.typed)
        switch s.phase {
        case .loading: m.phase = .loading
        case .failed(let why): m.phase = .failed(why)
        case .title: m.phase = .title
        case .demo: m.phase = .demo(lane: s.demoLane, verse: lesson?.demo ?? [])
        case .naming: m.phase = .naming(lane: s.demoLane, verse: lesson?.demo ?? [])
        case .trying:
            let lane = s.turn.clock.map {
                BeatLane(bpm: $0.bpm, beatsPerLine: 4, lines: $0.lines, startedAt: $0.beatAtMs, words: s.turn.hitMarks)
            }
            m.phase = .trying(lane: lane, transcript: transcript, listening: s.turn.listening, level: s.turn.level,
                              model: lesson?.demo ?? [], helpHalf: s.helpHalf, hand: [], rescueId: nil)
        case .weighing: m.phase = .weighing(transcript: transcript)
        case .note: m.phase = .note(transcript: transcript, note: s.note, beatScore: s.beatScore)
        case .landed: m.phase = .landed(transcript: transcript, note: s.note, beatScore: s.beatScore)
        }
        return m
    }

    private func actions(_ s: BardLessonSession) -> LessonActions {
        LessonActions(
            done: { s.finishTry() },
            again: { s.again() },
            retry: { s.start(lessonId: lessonId) },
            next: nil,  // TODO(spec): lessons 2 and 3 after the study
            spar: { app.route = .practice },
            type: { s.turn.typed = $0 }
        )
    }
}
