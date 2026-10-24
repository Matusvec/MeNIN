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
    func speak(_ text: String, speed: Double = 1) -> AsyncThrowingStream<[Float], Error> {
        let contextId = UUID().uuidString
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: [Float].self)
        lock.withLock { streams[contextId] = continuation }
        let tts = token.tts ?? .init(model: "sonic-3.6", voiceId: "")
        let request: [String: Any] = [
            "model_id": tts.model,
            "transcript": text,
            "voice": ["mode": "id", "id": tts.voiceId],
            "output_format": ["container": "raw", "encoding": "pcm_f32le", "sample_rate": sampleRate],
            "language": "en",
            "context_id": contextId,
            "continue": false,
            "generation_config": ["speed": speed],
        ]
        let data = try! JSONSerialization.data(withJSONObject: request)
        task.send(.string(String(decoding: data, as: UTF8.self))) { [weak self] error in
            if let error { self?.finish(contextId, error: error) }
        }
        continuation.onTermination = { [weak self] _ in self?.lock.withLock { _ = self?.streams.removeValue(forKey: contextId) } }
        return stream
    }

    private func finish(_ contextId: String, error: Error? = nil) {
        let continuation = lock.withLock { streams.removeValue(forKey: contextId) }
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
        }
        guard let m = try? JSONDecoder().decode(Message.self, from: data), let id = m.context_id else { return }
        switch m.type {
        case "chunk":
            if let b64 = m.data, let bytes = Data(base64Encoded: b64) {
                let samples = bytes.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
                _ = lock.withLock { streams[id]?.yield(samples) }
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
