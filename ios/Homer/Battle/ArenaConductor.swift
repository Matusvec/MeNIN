import AVFoundation
import Observation
import os

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

    private static let log = Logger(subsystem: "com.matusvec.homer", category: "arena")
    @ObservationIgnored private let battle: BattleClient
    @ObservationIgnored private let audio = StageAudio()
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var beatFor: String?
    @ObservationIgnored private var lastHits: (turn: UInt64, hits: UInt32) = (0, 0)
    @ObservationIgnored private var said = Set<String>()
    @ObservationIgnored private var lastPhase: String?
    @ObservationIgnored private let music = MusicDirector.shared
    @ObservationIgnored private let agent: AgentClient?
    @ObservationIgnored private let scene: SceneDriver?
    @ObservationIgnored private var lastWeights: EmotionWeights?
    @ObservationIgnored private var cueBuffers: [String: AVAudioPCMBuffer] = [:]
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

    init(battle: BattleClient, agent: AgentClient?, scene: SceneDriver? = nil) {
        self.battle = battle
        self.agent = agent
        self.scene = scene
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
        music.setMicOpen(false)
        homer.silence()
        audio.stop()
        restScene()
    }

    /// A reveal landed on screen (ArenaView fires each cue once, on its frame): play its sound now.
    /// SPEC: no sound effects beyond the beat and a soft strike. The cues stay visual (the scene answers
    /// the crown); the procedural sounds are kept behind `cueSounds` in case a design wants them back.
    static let cueSounds = false

    func play(_ cue: ArenaCue) {
        if Self.cueSounds {
            let key = "\(cue)"
            let buffer = cueBuffers[key] ?? BeatSynth.cue(cue, sampleRate: StageAudio.sampleRate)
            cueBuffers[key] = buffer
            audio.playSound(buffer)
        }
        if cue == .crown { scene?.strike(1.4) }
    }

    /// Back to the resting scene (lobby, the hall, leaving the arena).
    func restScene() {
        guard let scene else { return }
        scene.emotion = EmotionWeights()
        scene.prosody = .silent
        lastWeights = nil
    }

    /// "The room paints your voice": the poem's feeling while it lasts (kept through judging and
    /// the verdict; the next turn's scene row replaces it), the speaker's voice while their verse
    /// is live, Homer's while he talks. SceneMotion does the smoothing.
    private func paintScene(_ room: RoomRow) {
        guard let scene else { return }
        if room.phaseValue == .lobby {
            if lastWeights != nil { restScene() }
            return
        }
        // Emotion only when it changes: every set is recorded for the P11 color replay.
        if let w = battle.scene?.weights, w != lastWeights {
            scene.emotion = w
            lastWeights = w
        }
        if room.phaseValue == .speaking, let turn = battle.currentTurn, let p = battle.prosody, p.turnId == turn.id {
            scene.prosody = p.prosody
        } else if homerLevel > 0.02 {
            scene.prosody = Prosody(energy: min(1, homerLevel * 0.7), pitch: nil)
        } else {
            scene.prosody = .silent
        }
    }

    private func tick() {
        // Discus runs its own reveal (Events/Discus); checked per tick since set_event can switch a live hall.
        guard let room = battle.room, room.event != "discus" else {
            stopBeatIfPlaying()
            return
        }
        cueMusic(room)
        speakIfDue(room)
        paintScene(room)
        guard let turn = battle.currentTurn else {
            stopBeatIfPlaying()
            return
        }
        let key = "\(turn.id)-\(turn.attempt)"
        homer.host = room.event == "debate" ? "socrates" : "homer"
        if turn.statusValue == .speaking, room.event == "debate" {
            // No beat in debate. Socrates is silent but for the ten-second call.
            // Device and server clocks are NTP-close; plenty for a ten-second call.
            if !said.contains("ten \(key)"), turn.endsAt.isSet, Date().timeIntervalSince1970 * 1000 >= turn.endsAt.epochMs - 10_000 {
                said.insert("ten \(key)")
                homer.enqueue("Ten seconds.")
            }
        } else if turn.statusValue == .speaking {
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
                    scene?.strike()
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
                try? await Task.sleep(for: .milliseconds(500))
                self?.battle.advanceOnce(from: from)
            }
        } : nil

        let battleKey = "\(room.id).\(battle.generation)"
        if room.phaseValue == .theme, themeCards.isEmpty, let agent, !said.contains("themes \(battleKey) \(room.roundNo)") {
            said.insert("themes \(battleKey) \(room.roundNo)")
            Task {
                let cards = (try? await agent.themesWithCalls(n: 3, demo: room.demo)) ?? []
                for card in cards where !card.call.isEmpty { battle.calls[card.theme] = card.call }
                themeCards = cards.map(\.theme)
            }
        }
        if room.phaseValue != .theme, !themeCards.isEmpty { themeCards = [] }
        for poet in battle.players where poet.entered && poet.named {
            once("enter \(poet.id)", poet.epithet.isEmpty ? "Enter \(poet.name)!" : "Enter \(poet.name), \(poet.epithet)!")
        }
        switch room.phaseValue {
        case .ready:
            callUp(room)
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
            let key = "song \(battleKey) \(room.roundNo)"
            guard !said.contains(key) else { return }
            said.insert(key)
            Task {
                if await !singOnBeat(song, bpm: Double(room.bpm)) {
                    // Line by line, so the arena can show which line is being performed.
                    for (i, line) in song.enumerated() {
                        songLine = i
                        await speak("song \(i)", line)
                    }
                }
                await speak("crown", crown)
                advance?()
            }
        default:
            break
        }
    }

    /// docs/ux-flow.md section 10: where each cue plays on the arena.
    private func cueMusic(_ room: RoomRow) {
        music.demoDucked = room.demo
        music.setMicOpen(room.phaseValue == .speaking)
        guard room.phase != lastPhase else { return }
        let previous = lastPhase
        lastPhase = room.phase
        switch room.phaseValue {
        case .lobby, .theme:
            music.play(.hallTheme)
        case .dealing where previous == RoomPhase.finished.rawValue:
            music.play(.rematch)
        case .dealing, .ready:
            // The event's intro once, as the battle leaves the lobby.
            let fromLobby = previous == nil || previous == RoomPhase.lobby.rawValue || previous == RoomPhase.theme.rawValue
            if room.roundNo == 1 && fromLobby {
                music.stopLoop(fade: 0.5)
                music.play(room.event == "debate" ? .debateIntro : room.event == "discus" ? .discusIntro : .poetryIntro)
            }
        case .roundEnd:
            music.play(.roundEnd)
        case .finished:
            music.play(.champion)
        default:
            break
        }
    }

    func toggleMusicMute() {
        music.muted.toggle()
    }

    /// T1 step-up (P21): the theme once per round, then Homer calls the poet up by name, the
    /// round's first poet with the theme's call ("Salt-Tongued Priya. The sea is yours."), the
    /// rest with "Answer that." Socrates says which side the debater takes. Auto-ready holds the
    /// count-in until the call ends.
    private func callUp(_ room: RoomRow) {
        guard let round = battle.currentRound else { return }
        guard let turn = battle.currentTurn, turn.statusValue == .waiting, let poet = battle.player(turn.playerId) else {
            if !said.contains("theme \(round.id)") {
                said.insert("theme \(round.id)")
                Task { await speak("theme \(round.id)", round.theme) }
            }
            return
        }
        let key = "callup \(turn.id)-\(turn.attempt)"
        guard !said.contains(key) else { return }
        said.insert(key)
        if turn.attempt > 1 {
            // A silent first attempt: no second call-up, just send them again.
            battle.holdStart = true
            Task {
                await speak(key, "Again.")
                battle.holdStart = false
            }
            return
        }
        let themeKey = "theme \(round.id)"
        let sayTheme = !said.contains(themeKey)
        said.insert(themeKey)
        let named = poet.epithet.isEmpty ? poet.name : "\(poet.name), \(poet.epithet)"
        let line: String
        if room.event == "debate" {
            let side = DebateContent.shared.side(for: round.theme, turnNo: turn.turnNo)
            let template = DebateContent.shared.battleLines["Step up"] ?? "{name}, {title}. You say {side}. The floor is yours."
            line = side.map { side in
                template.replacingOccurrences(of: "{name}, {title}", with: named)
                    .replacingOccurrences(of: "{name}", with: poet.name)
                    .replacingOccurrences(of: "{title}", with: poet.epithet)
                    .replacingOccurrences(of: "{side}", with: side)
            } ?? "\(named). The floor is yours."
        } else {
            let first = battle.turns.filter { $0.roundId == turn.roundId }.map(\.turnNo).min() == turn.turnNo
            let call = battle.calls[round.theme] ?? ""
            line = first ? "\(named). \(call.isEmpty ? "The floor is yours." : call)" : "\(poet.name). Answer that."
        }
        // The rules once per hall, before the first call-up (first-timers didn't know what to do or
        // how they're scored); a rematch goes straight to the call-up.
        let rulesKey = "rules \(room.id)"
        let rules: String? = said.contains(rulesKey) ? nil : room.event == "debate"
            ? (DebateContent.shared.battleLines["Opening"] ?? "Every debater speaks. Make a claim, give a reason, answer your rival. I judge.")
            : "Two lines each, on my drum. Land four strong beats a line, paint me a picture, answer your rival, and work your cards in."
        said.insert(rulesKey)
        battle.holdStart = true
        Task {
            if let rules { await speak(rulesKey, rules) }
            if sayTheme { await speak(themeKey, round.theme) }
            await speak(key, line)
            battle.holdStart = false
        }
    }

    /// The stitched song on the drum: every line scanned and rendered first, then the beat starts
    /// and each line is placed so its stresses land on the pulses (a speaking bar, then a rest
    /// bar, like a turn). False, with nothing played, if the lines can't be placed.
    private func singOnBeat(_ song: [String], bpm: Double) async -> Bool {
        guard let agent, bpm > 0 else {
            Self.log.info("song: no agent, plain reading")
            return false
        }
        let started = Date()
        let beat = 60 / bpm
        async let scan = try? agent.scan(.init(transcript: song.joined(separator: "\n"), bpm: bpm, linesExpected: song.count))
        // One line at a time: the Cartesia plan allows 2 concurrent generations, and Homer may need the other.
        var renders: [(samples: [Float], words: [CartesiaTTS.Word])?] = []
        for line in song { renders.append(await homer.render(line)) }
        let scanned = await scan
        guard let lines = scanned?.lines, lines.count == song.count else {
            let got = scanned?.lines.count ?? -1
            Self.log.info("song: scan unusable (\(got) lines for \(song.count)), plain reading")
            return false
        }
        var placed: [BeatAligner.Placed] = []
        for (i, r) in renders.enumerated() {
            guard let r, !r.words.isEmpty else {
                Self.log.info("song: line \(i) rendered \(r?.samples.count ?? -1) samples, \(r?.words.count ?? -1) words; plain reading")
                return false
            }
            let stresses = BeatAligner.stresses(scanned: lines[i].words ?? [], spoken: r.words)
            guard stresses.count >= 2,
                  let p = BeatAligner.place(r.samples, sampleRate: StageAudio.sampleRate, words: r.words, stresses: stresses, beatSeconds: beat)
            else {
                Self.log.info("song: line \(i) has \(stresses.count) placeable stresses (scan words \(lines[i].words?.count ?? 0), spoken \(r.words.map(\.text).joined(separator: " "), privacy: .public)); plain reading")
                return false
            }
            placed.append(p)
        }
        Self.log.info("song: \(song.count) lines ready in \(Date().timeIntervalSince(started), format: .fixed(precision: 2)) s, worst stress +\(Int((placed.map(\.worstLate).max() ?? 0) * 1000)) ms")
        // Count-in bar, then line n on bar 2n.
        let lead = (placed.map(\.leadSeconds).max() ?? 0) * 1000
        let barMs = beat * 4 * 1000
        let clock = BeatClock(beatAtMs: Date().timeIntervalSince1970 * 1000 + 300 + max(barMs, lead), bpm: bpm, barsPerLine: 2, lines: song.count)
        music.setHostSpeaking(true)
        defer { music.setHostSpeaking(false) }
        audio.playBeat(clock)
        for (n, p) in placed.enumerated() {
            audio.scheduleVoice(p.samples, atMs: clock.beatAtMs + clock.lineMs * Double(n) - p.leadSeconds * 1000)
        }
        for n in placed.indices {
            await sleep(until: clock.beatAtMs + clock.lineMs * Double(n) - 300)
            guard !Task.isCancelled else { return true }
            songLine = n
            saying = "song \(n)"
        }
        await sleep(until: clock.endMs - clock.barMs + 400)  // the last rest bar isn't needed
        saying = nil
        audio.stopBeat()
        return true
    }

    #if DEBUG
    /// Dev: `-songTest YES` sings two fixed lines on the beat when the arena opens.
    func rehearseSong() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            let ok = await singOnBeat(["The wine-dark sea took my brother's ship", "and grey-eyed Athena would not hear his cry"], bpm: 80)
            Self.log.info("song: rehearsal \(ok ? "on the beat" : "fell back", privacy: .public)")
        }
    }
    #endif

    private func sleep(until epochMs: Double) async {
        let wait = epochMs - Date().timeIntervalSince1970 * 1000
        if wait > 0 { try? await Task.sleep(for: .milliseconds(Int(wait))) }
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
