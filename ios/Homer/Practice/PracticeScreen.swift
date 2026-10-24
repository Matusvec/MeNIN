import os
import SwiftUI

/// Practice: the art lead's PracticeView fed from PracticeSession. Pick one of three themes
/// (or a random one), take the turn, get the full judge breakdown.
struct PracticeScreen: View {
    let app: AppModel
    @State private var session: PracticeSession?
    @State private var themes: [String] = []

    var body: some View {
        ZStack {
            Color.clear
            if let session { PracticeView(model: model(session), actions: actions(session)) }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            let session = PracticeSession(agent: AgentClient.configured, scene: app.scene, hoard: app.hoard) { app.coin($0) }
            self.session = session
            themes = (try? await AgentClient.configured?.themes(n: 3, demo: false)) ?? []
            // Dev: `-autopilot practice` deals a random theme and begins without a tap.
            if DevAutopilot.mode == "practice" {
                await session.deal()
                if session.phase == .ready { await session.begin() }
            }
        }
        .onDisappear { session?.stop() }
    }

    private func model(_ s: PracticeSession) -> PracticeModel {
        var m = PracticeModel(theme: s.theme, hand: s.hand,
                              transcript: BattlePresenter.lines(s.transcript), listening: s.phase == .live,
                              level: s.level, rescueId: s.rescueCard, homer: BattlePresenter.homerLine(s.homer),
                              typed: s.voiceNote == nil ? nil : s.typed)
        m.lane = s.clock.map { BeatLane(bpm: $0.bpm, beatsPerLine: 4, lines: $0.lines, startedAt: $0.beatAtMs, words: s.hitMarks) }
        switch s.phase {
        case .idle: m.phase = .idle(themes: themes)
        case .dealing: m.phase = .dealing
        case .ready: m.phase = .ready
        case .announcing: m.phase = .announcing
        case .live: m.phase = .live
        case .judging: m.phase = .judging
        case .verdict:
            if let r = s.result {
                m.phase = .verdict(card: r.scorecard, reveal: s.homer.isSpeaking ? s.homer.spoken : 1,
                                   coined: r.coined.flatMap { $0.isEmpty ? nil : $0 })
            } else {
                m.phase = .failed(s.verdictText ?? "Homer is silent on this one.")
            }
        case .failed(let why): m.phase = .failed(why)
        }
        return m
    }

    private func actions(_ s: PracticeSession) -> PracticeActions {
        PracticeActions(
            pickTheme: { theme in Task { await s.deal(theme: theme) } },
            randomTheme: { Task { await s.deal() } },
            start: { Task { await s.begin() } },
            done: { Task { await s.finish() } },
            again: { Task { await s.begin() } },
            retry: { Task { await s.deal(theme: s.theme) } },
            type: { s.typed = $0 }
        )
    }
}
