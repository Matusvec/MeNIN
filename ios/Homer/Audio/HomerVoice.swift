import AVFoundation
import CryptoKit
import Observation
import os

/// Homer speaks one line at a time, with a caption for everything he says (SPEC demo mode).
/// With no voice (no agent, no Cartesia key) he is captioned but silent, and the line holds
/// for its estimated speaking time so flows that wait on him keep their rhythm.
@Observable
@MainActor
final class HomerVoice {
    struct Line: Equatable, Identifiable {
        let id = UUID()
        var text: String
        var whisper = false
        /// What the voice says, when it differs from the caption (pronunciations like "MAY-nin").
        var speech: String?
        /// Pre-rendered audio in the bundle: `Voice/<key>.caf`, 48 kHz mono Float32.
        var key: String?
    }

    /// A fixed line: its caption, what the voice says, and the bundled audio's key.
    struct Script: Sendable {
        var key: String
        var caption: String
        var speech: String
    }

    /// The caption on screen and how much of it has been spoken (0...1), for karaoke captions.
    private(set) var caption: Line?
    private(set) var spoken: Double = 0
    private(set) var voiceError: String?
    var isSpeaking: Bool { caption != nil }

    private static let log = Logger(subsystem: "com.matusvec.homer", category: "homer-voice")
    /// Whose voice: "homer", or "socrates" in debate rooms.
    @ObservationIgnored var host = "homer"
    @ObservationIgnored private let audio: StageAudio
    @ObservationIgnored private let agent: AgentClient?
    @ObservationIgnored private let role: VoiceTokenRequest.Role
    @ObservationIgnored private var tts: CartesiaTTS?
    @ObservationIgnored private var tokenExpiresAt = 0.0
    @ObservationIgnored private var queue: [(Line, CheckedContinuation<Void, Never>?)] = []
    @ObservationIgnored private var running: Task<Void, Never>?

    init(audio: StageAudio, agent: AgentClient?, role: VoiceTokenRequest.Role) {
        self.audio = audio
        self.agent = agent
        self.role = role
        // Token and socket ready before the first line (they cost ~0.5 s, more on cellular).
        if agent != nil { Task { [weak self] in _ = await self?.connectedTTS() } }
    }

    /// Audio held back before Homer starts, and the smallest buffer scheduled after that: Cartesia
    /// sends ~0.15–0.2 s chunks, and scheduling each the moment it lands left no slack for a busy
    /// main thread or a cellular hiccup (Matus: "the voice is super glitchy").
    static let leadSeconds = 0.4
    static let minBufferSeconds = 0.25
    /// Live lines play whole: fetched complete (~10x realtime, so ~0.4 s for a 4 s line), then
    /// scheduled as one buffer, the path the clean baked verse takes. Streaming chunk by chunk
    /// was choppy on Matus's phone (Sat 2:40); kept behind this switch.
    static let streamLive = false
    /// A live line is being fetched: views show "Homer is about to speak".
    private(set) var fetching = false

    /// Queues a line; returns when it has been spoken (or skipped).
    func say(_ text: String, whisper: Bool = false) async {
        await withCheckedContinuation { continuation in
            queue.append((Line(text: text, whisper: whisper), continuation))
            pump()
        }
    }

    func say(_ script: Script) async {
        await withCheckedContinuation { continuation in
            queue.append((Line(text: script.caption, speech: script.speech, key: script.key), continuation))
            pump()
        }
    }

    /// A caption with no audio of its own (the words are in a pre-rendered track), its
    /// karaoke progress running over `seconds`.
    func showLine(_ text: String, seconds: Double) async {
        caption = Line(text: text)
        spoken = 0
        let start = Date()
        while !Task.isCancelled, Date().timeIntervalSince(start) < seconds {
            spoken = min(1, Date().timeIntervalSince(start) / seconds)
            try? await Task.sleep(for: .milliseconds(50))
        }
        spoken = 1
        caption = nil
    }

    /// One line rendered whole with its word timings, to place on the beat; nil when the voice is offline.
    func render(_ text: String) async -> (samples: [Float], words: [CartesiaTTS.Word])? {
        guard let tts = await connectedTTS() else { return nil }
        do {
            return try await tts.render(text, host: host)
        } catch {
            Self.log.info("tts render failed: \(error.localizedDescription, privacy: .public)")
            self.tts = nil
            return nil
        }
    }

    /// Fire and forget.
    func enqueue(_ text: String) {
        queue.append((Line(text: text), nil))
        pump()
    }

    func silence() {
        running?.cancel()
        running = nil
        queue.forEach { $0.1?.resume() }
        queue.removeAll()
        audio.stopVoice()
        caption = nil
    }

    private func pump() {
        guard running == nil, !queue.isEmpty else { return }
        let (line, continuation) = queue.removeFirst()
        running = Task {
            await speak(line)
            continuation?.resume()
            running = nil
            pump()
        }
    }

    private func speak(_ line: Line) async {
        MusicDirector.shared.setHostSpeaking(true)
        defer { MusicDirector.shared.setHostSpeaking(false) }
        caption = line
        spoken = 0
        let estimate = max(1.2, Double(line.text.count) * 0.065)
        var start = Date()
        var played = 0.0

        if let key = line.key, let samples = Self.bundled(key) {
            audio.enqueueVoice(samples)
            played = Double(samples.count) / StageAudio.sampleRate
        } else if !line.whisper, let samples = Self.baked(line.speech ?? line.text) {
            // A fixed line baked into the app (lesson scripts, rules, canned feedback): no network at all.
            audio.enqueueVoice(samples)
            played = Double(samples.count) / StageAudio.sampleRate
        } else if !Self.streamLive {
            // "Homer is about to speak" only if the fetch takes over 300 ms, so fast lines never flash it.
            let flag = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                self?.fetching = true
            }
            defer { flag.cancel(); fetching = false }
            let fetchStart = Date()
            if let tts = await connectedTTS(), let whole = try? await tts.render(line.speech ?? line.text, speed: line.whisper ? 0.9 : 1, host: host), !whole.samples.isEmpty {
                flag.cancel()
                fetching = false
                audio.enqueueVoice(whole.samples)
                played = Double(whole.samples.count) / StageAudio.sampleRate
                start = Date()
                Self.log.info("tts whole line in \(Int(Date().timeIntervalSince(fetchStart) * 1000)) ms, \(played, format: .fixed(precision: 2)) s: \(line.text, privacy: .public)")
            } else {
                voiceError = "Homer's voice is offline (captions only)"
                self.tts = nil
            }
        } else if let tts = await connectedTTS() {
            do {
                var firstMs: Double?
                var pending: [Float] = []
                var started = false
                let sr = StageAudio.sampleRate
                for try await samples in tts.speak(line.speech ?? line.text, speed: line.whisper ? 0.9 : 1, host: host) {
                    firstMs = firstMs ?? Date().timeIntervalSince(start) * 1000
                    pending += samples
                    played += Double(samples.count) / sr
                    if Double(pending.count) / sr >= (started ? Self.minBufferSeconds : Self.leadSeconds) {
                        if !started { started = true; start = Date() }  // the caption runs with the audio
                        audio.enqueueVoice(pending)
                        pending.removeAll(keepingCapacity: true)
                    }
                }
                if !pending.isEmpty {
                    if !started { start = Date() }
                    audio.enqueueVoice(pending)
                }
                Self.log.info("tts first audio \(Int(firstMs ?? -1)) ms, \(played, format: .fixed(precision: 2)) s: \(line.text, privacy: .public)")
            } catch {
                voiceError = error.localizedDescription
                self.tts = nil
            }
        }
        // Hold the caption until the audio has played out (or for the estimate, if silent).
        let total = played > 0 ? played : estimate
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(start)
            spoken = min(1, elapsed / total)
            if elapsed >= total + 0.25 { break }
            try? await Task.sleep(for: .milliseconds(50))
        }
        caption = nil
    }

    /// Homer's fixed lines, baked by scratchpad bake_lines.py: Resources/Voice/line-<key>.m4a, where
    /// key = the first 16 hex of SHA-256 over the text lowercased with whitespace collapsed.
    static func bakedKey(_ text: String) -> String {
        let norm = text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return SHA256.hash(data: Data(norm.utf8)).map { String(format: "%02x", $0) }.joined().prefix(16).description
    }

    static func baked(_ text: String) -> [Float]? {
        let key = "line-" + bakedKey(text)
        if let hit = bakedCache[key] { return hit }
        guard let url = Bundle.main.url(forResource: key, withExtension: "m4a"),
              let file = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false),
              file.processingFormat.sampleRate == StageAudio.sampleRate,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil, let data = buffer.floatChannelData?[0] else { return nil }
        let samples = Array(UnsafeBufferPointer(start: data, count: Int(buffer.frameLength)))
        bakedCache[key] = samples
        return samples
    }
    private static var bakedCache: [String: [Float]] = [:]

    /// Bundled audio for a fixed line, if it was rendered at the stage's format.
    /// The text each baked lesson demo speaks, as `bakedKey` of the server's `demoSpoken` when it
    /// was baked. Re-bake a demo and update its hash together.
    static let bakedDemos: [String: String] = [
        "lesson-beat-demo": "a5df37ad490e032b",
        "lesson-formula-demo": "2209aa2989712173",
        "lesson-epithet-demo": "5969ac75645b4629",
    ]

    /// A baked lesson demo, only if it speaks exactly `text`: a rewritten verse falls back to live
    /// voice, so the caption and the audio can never disagree.
    static func bundledDemo(_ key: String, text: String) -> [Float]? {
        guard bakedDemos[key] == bakedKey(text) else { return nil }
        return bundled(key)
    }

    static func bundled(_ key: String) -> [Float]? {
        guard let url = Bundle.main.url(forResource: key, withExtension: "caf", subdirectory: "Voice")
                ?? Bundle.main.url(forResource: key, withExtension: "caf"),
              let file = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false),
              file.processingFormat.sampleRate == StageAudio.sampleRate,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil,
              let data = buffer.floatChannelData?[0] else { return nil }
        return Array(UnsafeBufferPointer(start: data, count: Int(buffer.frameLength)))
    }

    private func connectedTTS() async -> CartesiaTTS? {
        if let tts, tokenExpiresAt - Date().timeIntervalSince1970 * 1000 > 30_000 { return tts }
        guard let agent else { return nil }
        guard let token = try? await agent.voiceToken(.init(role: role)), token.tts != nil else {
            voiceError = "Homer's voice is offline (captions only)"
            return nil
        }
        tts?.close()
        let fresh = CartesiaTTS(token: token)
        fresh.connect()
        tts = fresh
        tokenExpiresAt = token.expiresAt
        voiceError = nil
        return fresh
    }
}
