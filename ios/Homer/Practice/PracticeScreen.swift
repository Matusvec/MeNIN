import os
import SwiftUI

/// Practice: one solo turn at a time with the full judge breakdown. Composed from the art
/// lead's turn components with bare layout; a dedicated PracticeView can replace the body.
struct PracticeScreen: View {
    let app: AppModel
    @State private var session: PracticeSession?

    var body: some View {
        ZStack {
            Color.clear
            if let session { content(session) }
        }
        .task {
            let session = PracticeSession(agent: AgentClient.configured, scene: app.scene, hoard: app.hoard) { app.coin($0) }
            self.session = session
            await session.deal()
            // Dev: `-autopilot practice` begins the turn without a tap and logs the result.
            if DevAutopilot.mode == "practice", session.phase == .ready {
                await session.begin()
                while session.phase != .verdict { try? await Task.sleep(for: .milliseconds(200)) }
                let log = Logger(subsystem: "com.matusvec.homer", category: "autopilot")
                let transcript = session.transcript.replacingOccurrences(of: "\n", with: " | ")
                let scores = session.result.map { "\($0.scorecard.scores)" } ?? "none"
                log.notice("practice transcript: \(transcript, privacy: .public)")
                log.notice("practice scores: \(scores, privacy: .public) verdict: \(session.verdictText ?? "", privacy: .public)")
            }
        }
        .onDisappear { session?.stop() }
    }

    @ViewBuilder
    private func content(_ s: PracticeSession) -> some View {
        VStack(spacing: Metrics.s4) {
            if !s.theme.isEmpty {
                AnswerLineView(line: s.theme)
            }
            switch s.phase {
            case .idle, .dealing:
                ProgressView()
            case .failed(let why):
                Text(why).multilineTextAlignment(.center)
                Button("Try again") { Task { await s.deal() } }.buttonStyle(.borderedProminent)
            case .ready:
                FormulaHandView(cards: s.hand)
                Button("Begin") { Task { await s.begin() } }.buttonStyle(.borderedProminent)
                Button("Another theme") { Task { await s.deal() } }
            case .announcing, .live:
                if let clock = s.clock {
                    BeatLaneView(lane: BeatLane(bpm: clock.bpm, beatsPerLine: 4, lines: clock.lines,
                                                startedAt: clock.beatAtMs, words: s.hitMarks),
                                 barsPerLine: clock.barsPerLine)
                }
                TranscriptView(lines: BattlePresenter.lines(s.transcript), listening: s.phase == .live,
                               formulas: s.hand.map(\.text))
                FormulaHandView(cards: s.hand, raisedId: s.rescueCard)
                MicLevelView(level: s.level)
                if let note = s.voiceNote {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                    TextField("Your verse, one line per row", text: Binding(get: { s.typed }, set: { s.typed = $0 }), axis: .vertical)
                        .lineLimit(2...6)
                        .textFieldStyle(.roundedBorder)
                }
                Button("Done") { Task { await s.finish() } }
            case .judging:
                TranscriptView(lines: BattlePresenter.lines(s.transcript))
                Text("Homer is weighing it.").italic()
            case .verdict:
                if let card = s.result?.scorecard {
                    ScorecardView(card: card, reveal: s.homer.isSpeaking ? s.homer.spoken : 1, poet: app.poetName.isEmpty ? nil : app.poetName)
                }
                if let coined = s.result?.coined, !coined.isEmpty {
                    Text("Into your hoard: \(coined)").italic()
                }
                HStack {
                    Button("Again") { Task { await s.begin() } }.buttonStyle(.borderedProminent)
                    Button("New hand") { Task { await s.deal() } }
                }
            }
            Spacer(minLength: 0)
            if let line = s.homer.caption {
                CaptionView(text: line.text, spoken: s.homer.spoken, whisper: line.whisper)
            }
        }
        .padding(Metrics.s4)
    }
}
