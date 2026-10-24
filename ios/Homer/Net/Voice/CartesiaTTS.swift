import Foundation

/// Homer's voice over Cartesia's TTS WebSocket (docs/voice.md, section 3). The socket is
/// opened once and kept; each line is one context. Audio arrives as raw pcm_f32le chunks
/// at `sampleRate`, ready to schedule back to back.
final class CartesiaTTS: @unchecked Sendable {
    static let endpoint = URL(string: "wss://api.cartesia.ai/tts/websocket")!

    private let task: URLSessionWebSocketTask
    private let token: VoiceToken
    private let sampleRate: Int
    private let lock = NSLock()
    private var streams: [String: AsyncThrowingStream<[Float], Error>.Continuation] = [:]
    private var wordTimes: [String: [Word]] = [:]
    /// Bytes of a float split across two chunks, carried into the next chunk of the same context.
    private var carry: [String: Data] = [:]

    /// A word and where it sits in the rendered audio, in seconds.
    struct Word: Sendable, Equatable {
        var text: String
        var start: Double
        var end: Double
    }

    init(token: VoiceToken, sampleRate: Int = 48_000, session: URLSession = .shared) {
        self.token = token
        self.sampleRate = sampleRate
        var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "cartesia_version", value: token.cartesiaVersion),
            URLQueryItem(name: "access_token", value: token.token),
        ]
        task = session.webSocketTask(with: components.url!)
    }

    func connect() {
        task.resume()
        receive()
    }

    func close() {
        task.cancel(with: .normalClosure, reason: nil)
    }

    /// Streams one line's audio. `speed` is Cartesia's 0.6...1.5 guidance.
    func speak(_ text: String, speed: Double = 1, host: String = "homer") -> AsyncThrowingStream<[Float], Error> {
        start(text, speed: speed, host: host, timestamps: false).stream
    }

    /// One whole line with its word timings, for placing the words on the beat.
    func render(_ text: String, speed: Double = 1, host: String = "homer") async throws -> (samples: [Float], words: [Word]) {
        let (id, stream) = start(text, speed: speed, host: host, timestamps: true)
        var samples: [Float] = []
        for try await chunk in stream { samples += chunk }
        let words = lock.withLock { wordTimes.removeValue(forKey: id) } ?? []
        return (samples, words)
    }

    private func start(_ text: String, speed: Double, host: String, timestamps: Bool) -> (id: String, stream: AsyncThrowingStream<[Float], Error>) {
        let contextId = UUID().uuidString
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: [Float].self)
        lock.withLock { streams[contextId] = continuation }
        let tts = token.tts ?? .init(model: "sonic-3.6", voiceId: "", voices: nil)
        // Socrates speaks in his own voice once one is picked; until then, Homer's.
        let voiceId = tts.voices?[host].flatMap { $0.isEmpty ? nil : $0 } ?? tts.voiceId
        var request: [String: Any] = [
            "model_id": tts.model,
            "transcript": text,
            "voice": ["mode": "id", "id": voiceId],
            "output_format": ["container": "raw", "encoding": "pcm_f32le", "sample_rate": sampleRate],
            "language": "en",
            "context_id": contextId,
            "continue": false,
            "generation_config": ["speed": speed],
        ]
        if timestamps { request["add_timestamps"] = true }
        let data = try! JSONSerialization.data(withJSONObject: request)
        task.send(.string(String(decoding: data, as: UTF8.self))) { [weak self] error in
            if let error { self?.finish(contextId, error: error) }
        }
        continuation.onTermination = { [weak self] _ in self?.lock.withLock { _ = self?.streams.removeValue(forKey: contextId) } }
        return (contextId, stream)
    }

    private func finish(_ contextId: String, error: Error? = nil) {
        let continuation = lock.withLock { () -> AsyncThrowingStream<[Float], Error>.Continuation? in
            carry.removeValue(forKey: contextId)
            return streams.removeValue(forKey: contextId)
        }
        if let error { continuation?.finish(throwing: error) } else { continuation?.finish() }
    }

    private func receive() {
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                let data: Data
                switch message {
                case .string(let s): data = Data(s.utf8)
                case .data(let d): data = d
                @unknown default: data = Data()
                }
                handle(data)
                receive()
            case .failure(let error):
                let all = lock.withLock { () -> [AsyncThrowingStream<[Float], Error>.Continuation] in
                    defer { self.streams.removeAll() }
                    return Array(self.streams.values)
                }
                all.forEach { $0.finish(throwing: error) }
            }
        }
    }

    private func handle(_ data: Data) {
        struct Message: Decodable {
            var type: String?
            var context_id: String?
            var data: String?
            var done: Bool?
            var message: String?
            var word_timestamps: Stamps?
            struct Stamps: Decodable {
                var words: [String]
                var start: [Double]
                var end: [Double]
            }
        }
        guard let m = try? JSONDecoder().decode(Message.self, from: data), let id = m.context_id else { return }
        switch m.type {
        case "chunk":
            if let b64 = m.data, let chunk = Data(base64Encoded: b64) {
                // Decode on 4-byte boundaries: a chunk can end mid-sample, and binding it as-is turns
                // everything after the split into noise.
                let samples: [Float] = lock.withLock {
                    var bytes = carry.removeValue(forKey: id) ?? Data()
                    bytes.append(chunk)
                    let whole = bytes.count / 4 * 4
                    if whole < bytes.count { carry[id] = bytes.suffix(from: bytes.startIndex + whole) }
                    return bytes.prefix(whole).withUnsafeBytes { raw in
                        (0..<whole / 4).map { raw.loadUnaligned(fromByteOffset: $0 * 4, as: Float.self) }
                    }
                }
                _ = lock.withLock { streams[id]?.yield(samples) }
            }
            if m.done == true { finish(id) }
        case "timestamps":
            if let w = m.word_timestamps {
                let words = zip(w.words, zip(w.start, w.end)).map { Word(text: $0, start: $1.0, end: $1.1) }
                lock.withLock { wordTimes[id, default: []] += words }
            }
            if m.done == true { finish(id) }
        case "done":
            finish(id)
        case "error":
            finish(id, error: NSError(domain: "Homer.TTS", code: 1, userInfo: [NSLocalizedDescriptionKey: m.message ?? "TTS error"]))
        default:
            if m.done == true { finish(id) }
        }
    }
}
