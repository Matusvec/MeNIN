import AVFoundation
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
    }

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
        let start = Date()
        var played = 0.0

        if let key = line.key, let samples = Self.bundled(key) {
            audio.enqueueVoice(samples)
            played = Double(samples.count) / StageAudio.sampleRate
        } else if let tts = await connectedTTS() {
            do {
                var firstMs: Double?
                for try await samples in tts.speak(line.speech ?? line.text, speed: line.whisper ? 0.9 : 1, host: host) {
                    firstMs = firstMs ?? Date().timeIntervalSince(start) * 1000
                    audio.enqueueVoice(samples)
                    played += Double(samples.count) / StageAudio.sampleRate
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

    /// Bundled audio for a fixed line, if it was rendered at the stage's format.
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
