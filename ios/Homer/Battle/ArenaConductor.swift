import Foundation
import Observation

/// The arena's sound, driven by battle state: the beat on the turn's grid while a verse is
/// live (ducked in speaking bars), a drum strike each time the speaker's hit count goes up,
/// and Homer's lines (entrances, theme, verdicts, the song), never over a poet. In auto-ready
/// rooms (always on in demo) it advances once each reveal has been spoken. Owned by the arena screen.
@Observable
@MainActor
final class ArenaConductor {
    private(set) var audioError: String?
    /// For the scene: Homer's loudness while he speaks.
    var homerLevel: Double { audio.homerLevel }

    @ObservationIgnored private let battle: BattleClient
    @ObservationIgnored private let audio = StageAudio()
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var beatFor: String?
    @ObservationIgnored private var lastHits: (turn: UInt64, hits: UInt32) = (0, 0)
    @ObservationIgnored private var said = Set<String>()
    @ObservationIgnored private let agent: AgentClient?
    let homer: HomerVoice

    /// What Homer is saying now, keyed like "enter 12", "verdict 40", "round 7", "song 2": the
    /// presenter ties reveals (scores counting up, the carved line) to his voice.
    private(set) var saying: String?
    /// The player whose entrance is being announced.
    private(set) var entering: UInt64?
    /// The song line being performed in the finale.
    private(set) var songLine = 0
    /// Three theme cards for rooms with theme choice (from the agent's /themes).
    private(set) var themeCards: [String] = []

    init(battle: BattleClient, agent: AgentClient?) {
        self.battle = battle
        self.agent = agent
        homer = HomerVoice(audio: audio, agent: agent, role: .arena)
    }

    func start() {
        ticker?.cancel()
        ticker = Task { [weak self, audio] in
            do {
                try await Task.detached { try audio.start(recording: false) }.value
            } catch {
                self?.audioError = "Audio failed to start: \(error.localizedDescription)"
                return
            }
            guard !Task.isCancelled else { return }
            self?.runTicker()
        }
    }

    private func runTicker() {
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: .milliseconds(40))
            }
        }
    }

    func stop() {
        ticker?.cancel()
        homer.silence()
        audio.stop()
    }

    private func tick() {
        guard let room = battle.room else { return }
        speakIfDue(room)
        guard let turn = battle.currentTurn else {
            stopBeatIfPlaying()
            return
        }
        let key = "\(turn.id)-\(turn.attempt)"
        if turn.statusValue == .speaking {
            if beatFor != key, turn.beatAt.isSet {
                beatFor = key
                // This device's offset from the server clock, estimated as the turn goes live.
                let offset = BeatClock.offset(localReceiveMs: Date().timeIntervalSince1970 * 1000, serverStartedAtMs: turn.startedAt.epochMs)
                let clock = BeatClock(beatAtMs: turn.beatAt.epochMs + offset, bpm: Double(room.bpm),
                                      barsPerLine: Int(room.barsPerLine), lines: Int(room.linesPerTurn))
                audio.playBeat(clock)
            }
            if let p = battle.prosody, p.turnId == turn.id {
                if lastHits.turn != turn.id { lastHits = (turn.id, 0) }
                if p.hits > lastHits.hits {
                    audio.playStrike()
                    lastHits.hits = p.hits
                }
            }
        } else {
            stopBeatIfPlaying()
        }
    }

    /// Each line once, in phase order. Lines wait while a poet holds the floor.
    private func speakIfDue(_ room: RoomRow) {
        guard room.phaseValue != .speaking else { return }
        func once(_ key: String, _ text: String, then: (() -> Void)? = nil) {
            guard !said.contains(key), !text.isEmpty else { return }
            said.insert(key)
            Task {
                await speak(key, text)
                then?()
            }
        }
        let from = battle.revealKey
        let advance: (() -> Void)? = room.autoReady ? { [weak self] in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                self?.battle.advanceOnce(from: from)
            }
        } : nil

        if room.phaseValue == .theme, themeCards.isEmpty, let agent, !said.contains("themes \(room.id) \(room.roundNo)") {
            said.insert("themes \(room.id) \(room.roundNo)")
            Task { themeCards = (try? await agent.themes(n: 3, demo: room.demo)) ?? [] }
        }
        if room.phaseValue != .theme, !themeCards.isEmpty { themeCards = [] }
        for poet in battle.players where poet.entered && poet.named {
            once("enter \(poet.id)", poet.epithet.isEmpty ? "Enter \(poet.name)!" : "Enter \(poet.name), \(poet.epithet)!")
        }
        switch room.phaseValue {
        case .ready:
            if let round = battle.currentRound { once("theme \(round.id)", round.theme) }
        case .scored:
            guard let turn = battle.currentTurn else { return }
            if let score = battle.score(for: turn.id) {
                once("verdict \(turn.id)", score.verdict.isEmpty ? "Homer is silent on this one." : score.verdict, then: advance)
            } else if turn.statusValue == .declined {
                once("verdict \(turn.id)", "Not in my hall.", then: advance)
            } else if turn.statusValue == .skipped {
                once("verdict \(turn.id)", "The hall waited. No verse came.", then: advance)
            }
        case .roundEnd:
            if let round = battle.currentRound, !round.verdict.isEmpty {
                once("round \(round.id)", round.verdict, then: advance)
            }
        case .finale:
            let song = battle.songLines.map(\.text)
            guard !song.isEmpty else { return }
            let champion = battle.players.max { $0.total < $1.total }
            let crown = champion.map { "\($0.name)\($0.epithet.isEmpty ? "" : ", \($0.epithet)"). The hall is yours." } ?? ""
            let key = "song \(room.id) \(room.roundNo)"
            guard !said.contains(key) else { return }
            said.insert(key)
            Task {
                // Line by line, so the arena can show which line is being performed.
                for (i, line) in song.enumerated() {
                    songLine = i
                    await speak("song \(i)", line)
                }
                await speak("crown", crown)
                advance?()
            }
        default:
            break
        }
    }

    private func speak(_ key: String, _ text: String) async {
        saying = key
        if key.hasPrefix("enter "), let id = UInt64(key.dropFirst(6)) { entering = id }
        await homer.say(text)
        if saying == key { saying = nil }
        if key.hasPrefix("enter ") { entering = nil }
    }

    private func stopBeatIfPlaying() {
        guard beatFor != nil else { return }
        beatFor = nil
        audio.stopBeat()
    }
}
