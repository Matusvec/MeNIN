import Foundation
import Observation

/// One Bard lesson, start to finish (docs/ux-flow.md section 2):
///   L0 title → L1 Homer performs the demo over the beat → L2 he names the move and sets the
///   exercise → L3 you try over the beat → L4 one note (the Beat score beside it, P20) → back
///   to L3, or L5 landed. P10: the agent sends help on the 3rd try (finish his half) and lands
///   the lesson with a walkthrough from the 5th. Everything Homer says comes from the agent.
@Observable
@MainActor
final class BardLessonSession {
    enum Phase: Equatable {
        case loading, title, demo, naming, trying, weighing, note, landed
        case failed(String)
    }

    static let bpm = 80

    private(set) var phase = Phase.loading
    private(set) var lesson: Lesson?
    private(set) var tryNo = 0
    /// Homer's one note after a try, and the try's Beat score (P20), shown small beside it.
    private(set) var note: String?
    private(set) var beatScore: Int?
    /// P10: the half line Homer gave you to finish.
    private(set) var helpHalf: String?
    /// The poet's last try, one line per row.
    private(set) var lastTry = ""
    /// The demo verse's lane, placed on the beat grid Homer performed it on.
    private(set) var demoLane: BeatLane?

    let turn: SoloVoiceTurn
    private let agent: AgentClient?
    private let poetName: String
    @ObservationIgnored private var running: Task<Void, Never>?

    static func landedLessons() -> Set<String> { Set(UserDefaults.standard.stringArray(forKey: "lessonsLanded") ?? []) }

    init(agent: AgentClient?, scene: SceneDriver, poetName: String) {
        self.agent = agent
        self.poetName = poetName
        turn = SoloVoiceTurn(agent: agent, scene: scene, bpm: Double(Self.bpm), barsPerLine: 2)
    }

    /// Loads the lesson and runs L0 to the first try.
    func start(lessonId: String) {
        running?.cancel()
        running = Task { await run(lessonId) }
    }

    func stop() {
        running?.cancel()
        turn.stop()
    }

    /// L5 → again from the top of the try loop.
    func again() {
        guard phase == .landed || phase == .note else { return }
        running?.cancel()
        tryNo = 0
        helpHalf = nil
        running = Task { await tryLoop() }
    }

    /// Done tapped during a try.
    func finishTry() { turn.finishNow() }

    // MARK: flow

    private func run(_ lessonId: String) async {
        guard let agent else {
            phase = .failed("Lessons need the agent service, which this server doesn't have yet.")
            return
        }
        do {
            let lessons = try await agent.lessons(bpm: Self.bpm)
            guard let found = lessons.first(where: { $0.id == lessonId }) else {
                phase = .failed("Lesson \(lessonId) isn't in the path.")
                return
            }
            lesson = found
        } catch {
            phase = .failed("Couldn't load the lesson: \(error.localizedDescription)")
            return
        }
        guard let lesson else { return }
        await turn.start()
        let music = MusicDirector.shared

        // L0: the title.
        phase = .title
        await turn.homer.say(lesson.title)
        guard !Task.isCancelled else { return }

        // L1: Homer performs the move over the beat, each line on its bar's downbeat.
        phase = .demo
        music.stopLoop(fade: 0.6)
        let lines = lesson.demoSpoken.split(separator: "\n").map(String.init)
        let clock = turn.perform(lines: max(1, lines.count))
        if var lane = lesson.demoLane {
            lane.startedAt = clock.beatAtMs
            demoLane = lane
        }
        for (n, line) in lines.enumerated() {
            await waitUntil(clock.beatAtMs + clock.lineMs * Double(n))
            guard !Task.isCancelled else { return }
            turn.homer.enqueue(line)
        }
        await waitUntil(clock.endMs)

        // L2: name the move, then set the exercise.
        phase = .naming
        await turn.homer.say(lesson.move)
        if let prompt = lesson.exerciseSpoken, !prompt.isEmpty { await turn.homer.say(prompt) }
        guard !Task.isCancelled else { return }

        await tryLoop()
    }

    /// L3 → L4, until it lands.
    private func tryLoop() async {
        guard let lesson, let agent else { return }
        while !Task.isCancelled {
            tryNo += 1
            note = nil
            beatScore = nil
            phase = .trying
            lastTry = await turn.record(lines: lesson.tryLines, keyterms: [])
            guard !Task.isCancelled else { return }

            phase = .weighing
            let request = LessonFeedbackRequest(
                lesson: lesson.id, transcript: lastTry, bpm: Double(Self.bpm), tryNo: tryNo,
                onsetsMs: turn.onsetsMs.isEmpty ? nil : turn.onsetsMs,
                name: poetName.isEmpty ? nil : poetName
            )
            let feedback: LessonFeedback
            do {
                feedback = try await agent.lessonFeedback(request)
            } catch {
                note = "Homer is silent on this one."
                phase = .note
                try? await Task.sleep(for: .seconds(2))
                continue
            }
            beatScore = feedback.scan?.beat
            note = feedback.line.isEmpty ? (feedback.miss == "Homer is silent" ? "Homer is silent on this one." : nil) : feedback.line
            phase = .note
            if let line = note { await turn.homer.say(line) }

            if let help = feedback.help {
                if help.kind == "half" { helpHalf = help.half ?? help.say }
                await turn.homer.say(help.say)
            }
            if feedback.landed {
                land(lesson)
                if note != lesson.success { await turn.homer.say(lesson.success) }
                MusicDirector.shared.play(.trainingAmbience)
                return
            }
            try? await Task.sleep(for: .milliseconds(600))  // a breath, then the next count-in
        }
    }

    private func land(_ lesson: Lesson) {
        phase = .landed
        var landed = Self.landedLessons()
        landed.insert(lesson.id)
        UserDefaults.standard.set(Array(landed), forKey: "lessonsLanded")
    }

    private func waitUntil(_ epochMs: Double) async {
        let delay = epochMs - Date().timeIntervalSince1970 * 1000
        if delay > 0 { try? await Task.sleep(for: .milliseconds(Int(delay))) }
    }
}
