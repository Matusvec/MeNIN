import AVFoundation
import Foundation
import Observation
import os

/// Practice (SPEC "Practice mode"): a solo turn on one phone, no SpacetimeDB.
/// Deal a theme and hand, Homer announces the theme, the phone plays the beat itself with an
/// open mic, then the judge streams Homer's verdict and the full scorecard.
///
/// The mic and the beat share one AVAudioEngine with voice processing, so the system echo
/// canceller removes the phone's own beat and Homer's voice from what STT hears.
/// Lines follow the beat: STT is flushed at each line boundary (speaking bar + rest bar).
@Observable
@MainActor
final class PracticeSession {
    enum Phase: Equatable {
        case idle, dealing, ready, announcing, live, judging, verdict
        case failed(String)
    }

    static let bpm = 80.0
    static let lines = 4
    static let barsPerLine = 2

    private(set) var phase = Phase.idle {
        didSet {
            guard phase != oldValue else { return }
            Self.log.notice("practice phase \(String(describing: self.phase), privacy: .public)")
            #if DEBUG
            print("PRACTICE phase \(phase) t=\(Int(Date().timeIntervalSince1970 * 1000))")  // dev console (devicectl --console)
            #endif
        }
    }
    private static let log = Logger(subsystem: "com.matusvec.homer", category: "practice")
    private(set) var theme = ""
    private(set) var hand: [FormulaCard] = []
    private(set) var clock: BeatClock?
    private(set) var hits: UInt32 = 0
    private(set) var hitMarks: [BeatWord] = []
    private(set) var rescueCard: String?
    private(set) var verdictText: String?
    private(set) var result: JudgeResult?
    /// Set when voice is unavailable; the screen then offers typing (dev fallback).
    private(set) var voiceNote: String?
    /// Typed verse when voice is unavailable.
    var typed = ""
    var transcript: String { voiceNote == nil ? finals + partial : typed }
    var level: Double { micProsody.prosody.energy }

    let homer: HomerVoice

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let mic: MicEngine
    @ObservationIgnored private let micProsody: MicProsody
    @ObservationIgnored private let stage: StageAudio
    @ObservationIgnored private let haptics = BeatHaptics()
    @ObservationIgnored private let agent: AgentClient?
    @ObservationIgnored private let scene: SceneDriver
    @ObservationIgnored private let hoard: [String]
    @ObservationIgnored private let onCoin: (String) -> Void

    @ObservationIgnored private var stt: CartesiaSTT?
    /// Observed: the live transcript the screen shows is built from these.
    private var finals = ""
    private var partial = ""
    @ObservationIgnored private var played = Set<String>()
    @ObservationIgnored private var emotionHistory: [EmotionWeights] = []
    @ObservationIgnored private var tasks: [Task<Void, Never>] = []
    @ObservationIgnored private var flushWaiters: [CheckedContinuation<Void, Never>] = []
    @ObservationIgnored private var pendingLineBreaks = 0
    /// `finalize`s not yet answered; the verse is judged only after all are in.
    @ObservationIgnored private var pendingFlushes = 0
    @ObservationIgnored private var lastWordsMs = 0.0
    @ObservationIgnored private var lastPauseBreakMs = 0.0
    /// Free verse (SPEC, Sat 3:40): Practice has no beat either. A 3-2-1, then one window.
    static let verseSeconds = 20.0
    /// SPEAK to the window's end, for the countdown ring.
    private(set) var verseWindow: (start: Date, end: Date)?
    @ObservationIgnored private var lastVoiceMs = 0.0
    @ObservationIgnored private var rescuedLines = Set<Int>()
    @ObservationIgnored private var rescues = 0
    @ObservationIgnored private var gate = StressGate()

    init(agent: AgentClient?, scene: SceneDriver, hoard: [String], onCoin: @escaping (String) -> Void) {
        self.agent = agent
        self.scene = scene
        self.hoard = hoard
        self.onCoin = onCoin
        mic = MicEngine(engine: engine)
        micProsody = MicProsody(engine: mic)
        stage = StageAudio(engine: engine)
        homer = HomerVoice(audio: stage, agent: agent, role: .solo)
    }

    // MARK: flow

    /// A theme (random when empty) and a hand of five, leaning on the poet's hoard.
    func deal(theme requested: String = "") async {
        guard let agent else {
            phase = .failed("Practice needs the agent service, which this server doesn't have yet.")
            return
        }
        phase = .dealing
        do {
            let dealt = try await agent.deal(DealRequest(theme: requested, hoard: hoard))
            theme = dealt.theme
            hand = dealt.hand.map(\.card)
            result = nil
            verdictText = nil
            phase = .ready
        } catch {
            phase = .failed("Couldn't deal: \(error.localizedDescription)")
        }
    }

    /// Homer announces the theme, one bar counts in, and the verse is live for `lines` lines.
    func begin() async {
        guard phase == .ready || phase == .verdict else { return }
        resetTurn()
        phase = .announcing
        MusicDirector.shared.stopLoop(fade: 0.6)
        await openVoice()

        mic.muted = true  // keep Homer's announcement out of the verse
        await homer.say(theme)
        mic.muted = false

        // 3, 2, 1 (haptic ticks 0.75 s apart), then SPEAK and one window; no drum, no grid.
        let goAt = Date().timeIntervalSince1970 * 1000 + 2250 + 250
        let endAt = goAt + Self.verseSeconds * 1000
        clock = nil
        verseWindow = (Date(timeIntervalSince1970: goAt / 1000), Date(timeIntervalSince1970: endAt / 1000))
        MusicDirector.shared.setMicOpen(true)
        haptics.countIn(toMs: goAt)
        lastVoiceMs = goAt
        lastWordsMs = goAt
        phase = .live
        startLiveTasks(goAt: goAt, endAt: endAt)
    }

    /// Done tapped, or the last line's rest bar ended.
    func finish() async {
        guard phase == .live else { return }
        phase = .judging
        pendingFlushes += 1
        stt?.finalize()
        await waitForFlush(timeoutMs: 1500)
        let verse = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        stopListening()  // the engine stays up: Homer speaks the verdict through it
        MusicDirector.shared.setMicOpen(false)
        MusicDirector.shared.play(.trainingAmbience)
        await judge(verse)
    }

    func stop() {
        stopListening()
        homer.silence()
        engine.stop()
        phase = hand.isEmpty ? .idle : .ready
    }

    // MARK: live

    private func openVoice() async {
        voiceNote = nil
        if let agent, let token = try? await agent.voiceToken(.init(role: .solo)), token.stt != nil {
            let stt = CartesiaSTT(token: token, keyterms: hand.map(\.text) + hoard + [theme])
            self.stt = stt
            stt.start()
            tasks.append(Task { [weak self] in
                for await event in stt.events { self?.handle(event) }
            })
            mic.onPCM = { [weak stt] chunk in stt?.send(chunk) }
            Self.log.notice("practice voice: stt \(token.stt?.model ?? "?", privacy: .public)")
        } else {
            Self.log.notice("practice voice: unavailable")
            voiceNote = "Voice is offline here, so type your verse."
        }
        mic.onOnset = { [weak self] onset in Task { @MainActor in self?.handle(onset) } }
        micProsody.onProsody = { [scene] p in scene.prosody = p }
        await micProsody.start(voiceProcessing: MicEngine.echoCancelSolo)
        if let error = micProsody.error, voiceNote == nil { voiceNote = error }
        try? await Task.detached { [stage] in try stage.start(recording: true) }.value
        haptics.prepare()
    }

    private func startLiveTasks(goAt: Double, endAt: Double) {
        // The window ends the verse (Done can end it sooner).
        tasks.append(Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(max(0, Int(endAt - Date().timeIntervalSince1970 * 1000))))
            guard let self, self.phase == .live else { return }
            await self.finish()
        })
        // The scene's color, and the samples Range is scored from: about every 1.5 s.
        tasks.append(Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1500))
                guard let self, self.phase == .live, let agent = self.agent else { return }
                let text = self.transcript
                guard !text.isEmpty else { continue }
                let p = self.micProsody.prosody
                if let weights = try? await agent.emotion(.init(text: text, loudness: p.energy, pitch: p.pitch)) {
                    self.scene.emotion = weights
                    self.emotionHistory.append(weights)
                }
            }
        })
        // Freeze rescue (P22) and lines broken on pauses.
        tasks.append(Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, self.phase == .live else { return }
                let now = Date().timeIntervalSince1970 * 1000
                self.checkFreeze(now: now, goAt: goAt)
                self.breakLineOnPause(now: now)
            }
        })
    }

    private func handle(_ event: CartesiaSTT.Event) {
        Self.log.notice("practice stt \(String(describing: event), privacy: .public)")
        switch event {
        case .partial(let text):
            if text != partial { lastWordsMs = Date().timeIntervalSince1970 * 1000 }
            partial = text
        case .final(let text, _):
            if !text.trimmingCharacters(in: .whitespaces).isEmpty { lastWordsMs = Date().timeIntervalSince1970 * 1000 }
            finals += text
            partial = ""
            matchCards()
        case .flushed:
            if pendingLineBreaks > 0 {
                pendingLineBreaks -= 1
                if !finals.isEmpty, !finals.hasSuffix("\n") { finals = finals.trimmingCharacters(in: .whitespaces) + "\n" }
            }
            pendingFlushes = max(0, pendingFlushes - 1)
            if pendingFlushes == 0 {
                flushWaiters.forEach { $0.resume() }
                flushWaiters.removeAll()
            }
        case .error(let message):
            if phase == .announcing || phase == .live { voiceNote = "Voice dropped (\(message)), so type the rest." }
        case .closed:
            break
        }
    }

    private func handle(_ onset: MicEngine.Onset) {
        guard phase == .live else { return }
        lastVoiceMs = onset.epochMs
        guard let clock else { return }  // free verse: no beat lane
        let t = onset.epochMs - StressGate.heardLatencyMs - clock.beatAtMs  // as heard, on the beat's timeline
        switch gate.judge(onset, on: clock) {
        case .unstressed:
            break
        case .hit:
            hits += 1
            hitMarks.append(BeatWord(text: "", t: t, stressed: true, onBeat: true))
            haptics.hit()
        case .offBeat:
            hitMarks.append(BeatWord(text: "", t: t, stressed: true, onBeat: false))
        }
    }

    private func matchCards() {
        let spoken = BattleClient.normalize(finals)
        for card in hand where !played.contains(card.text) && spoken.contains(BattleClient.normalize(card.text)) {
            played.insert(card.text)
            if let i = hand.firstIndex(where: { $0.id == card.id }) { hand[i].used = true }
        }
    }

    /// P22: ~1.5 s of silence after SPEAK (onset or words), at most once per 6 s and two per verse.
    private func checkFreeze(now: Double, goAt: Double) {
        guard now > goAt + 1200, now - lastVoiceMs > 1500 || now - lastWordsMs > 1800 else { return }
        let slot = Int((now - goAt) / 6000)
        guard rescuedLines.count < 2, !rescuedLines.contains(slot), let agent else { return }
        rescuedLines.insert(slot)
        let request = RescueRequest(transcript: transcript, hand: hand.map(\.text), played: Array(played), theme: theme)
        Task {
            guard let rescue = try? await agent.rescue(request) else { return }
            rescueCard = rescue.formula
            rescues += 1
            // Whispered from the phone itself; the echo canceller keeps it out of the verse.
            await homer.say(rescue.formula, whisper: true)
        }
    }

    // MARK: judge

    private func judge(_ verse: String) async {
        #if DEBUG
        print("PRACTICE transcript \(verse.replacingOccurrences(of: "\n", with: " | ")) | hits \(hits) | played \(played.sorted()) | emotion samples \(emotionHistory.count)")
        #endif
        guard let agent, !verse.isEmpty else {
            verdictText = "No verse came. Again."
            phase = .verdict
            return
        }
        let request = JudgeRequest(
            transcript: verse, words: nil, bpm: Self.bpm, linesExpected: Self.lines, mode: .practice, theme: theme,
            hand: hand.map(\.text), played: Array(played), rescues: rescues, previous: nil,
            emotionHistory: emotionHistory.isEmpty ? nil : emotionHistory, hoard: hoard, demo: false
        )
        do {
            // The verdict line arrives first, so Homer starts speaking before the scores land.
            for try await event in agent.judgeStream(request) {
                switch event {
                case .verdict(let text):
                    verdictText = text
                    Task { await homer.say(text) }
                case .scorecard(let r):
                    accept(r)
                }
            }
        } catch {
            if result == nil, let r = try? await agent.judge(request) { accept(r) }
        }
        if result == nil, verdictText == nil { verdictText = "Homer is silent on this one." }
        phase = .verdict
    }

    private func accept(_ r: JudgeResult) {
        #if DEBUG
        print("PRACTICE scores \(r.scorecard.scores) total \(r.total ?? r.scorecard.scores.total) silent \(r.isSilent) declined \(r.isDeclined)")
        print("PRACTICE verdict \(r.verdict) | best \(r.bestLine)")
        #endif
        result = r
        if verdictText == nil {
            verdictText = r.isDeclined ? "Not in my hall. Give me another." : (r.isSilent ? "Homer is silent on this one." : r.verdict)
            if let text = verdictText { Task { await homer.say(text) } }
        }
        if let coined = r.coined, !coined.isEmpty { onCoin(coined) }
        phase = .verdict
    }

    // MARK: plumbing

    private func waitForFlush(timeoutMs: Int) async {
        guard stt != nil else { return }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in await withCheckedContinuation { self.flushWaiters.append($0) } }
            group.addTask { try? await Task.sleep(for: .milliseconds(timeoutMs)) }
            await group.next()
            group.cancelAll()
            self.flushWaiters.forEach { $0.resume() }
            self.flushWaiters.removeAll()
        }
    }

    private func stopListening() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        mic.onPCM = nil
        mic.onOnset = nil
        micProsody.onProsody = nil
        micProsody.stop()
        stage.stopBeat()
        haptics.stop()
        stt?.close()
        stt = nil
        scene.prosody = .silent
    }

    /// A pause of ~0.7 s with words pending ends a line, so the judge sees lines.
    private func breakLineOnPause(now: Double) {
        guard !partial.trimmingCharacters(in: .whitespaces).isEmpty, now - lastWordsMs > 700,
              now - lastPauseBreakMs > 900 else { return }
        lastPauseBreakMs = now
        pendingLineBreaks += 1
        pendingFlushes += 1
        stt?.finalize()
    }

    private func resetTurn() {
        finals = ""
        partial = ""
        typed = ""
        hits = 0
        hitMarks = []
        rescueCard = nil
        verdictText = nil
        result = nil
        played.removeAll()
        emotionHistory.removeAll()
        rescuedLines.removeAll()
        rescues = 0
        gate.reset()
        pendingLineBreaks = 0
        pendingFlushes = 0
        lastPauseBreakMs = 0
        verseWindow = nil
        for i in hand.indices { hand[i].used = false }
    }
}
