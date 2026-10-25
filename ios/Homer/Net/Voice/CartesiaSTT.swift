import Foundation

/// Streaming speech-to-text over Cartesia's manual WebSocket (docs/voice.md, section 1).
/// The app never holds the API key: it connects with a short-lived token from the agent.
/// Audio goes in as 100 ms pcm_s16le chunks; `finalize` flushes at the end of a turn.
final class CartesiaSTT: @unchecked Sendable {
    struct Word: Equatable, Sendable {
        var text: String
        var start: Double  // seconds from the first audio byte of this session
        var end: Double
    }

    enum Event: Equatable, Sendable {
        /// The live tail since the last final: replace, don't append.
        case partial(String)
        /// Finalized text to append exactly as given, plus its word timings when the model sends them.
        case final(String, [Word])
        /// All audio sent before `finalize()` has been transcribed.
        case flushed
        case closed
        case error(String)
    }

    /// Dev only: `-cartesiaSTTURL ws://…` points at a local protocol stand-in for offline testing.
    static var endpoint: URL {
        UserDefaults.standard.string(forKey: "cartesiaSTTURL").flatMap(URL.init(string:))
            ?? URL(string: "wss://api.cartesia.ai/stt/websocket")!
    }

    let events: AsyncStream<Event>
    private let continuation: AsyncStream<Event>.Continuation
    private let task: URLSessionWebSocketTask
    private let queue = DispatchQueue(label: "com.matusvec.homer.stt")

    /// `keyterms` bias recognition toward the poet's formulas (ink-2 only; up to 100 terms,
    /// 1200 characters). Probe on synthetic fixtures (docs/voice-wer/): word error 3% with them on
    /// every fixture, vs 6–9% without on clean or quieter-drum mixes and 20% with the drum at 0 dB.
    init(token: VoiceToken, keyterms: [String] = [], session: URLSession = .shared, endpoint: URL = CartesiaSTT.endpoint) {
        let stt = token.stt ?? .init(model: "ink-2", encoding: "pcm_s16le", sampleRate: Int(MicEngine.sttSampleRate))
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "model", value: stt.model),
            URLQueryItem(name: "encoding", value: stt.encoding),
            URLQueryItem(name: "sample_rate", value: "\(stt.sampleRate)"),
            URLQueryItem(name: "cartesia_version", value: token.cartesiaVersion),
            URLQueryItem(name: "access_token", value: token.token),
        ]
        if stt.model.hasPrefix("ink-2") {
            var budget = 1200
            for term in keyterms.prefix(100) where term.count <= budget {
                components.queryItems?.append(URLQueryItem(name: "keyterm", value: term))
                budget -= term.count
            }
        }
        task = session.webSocketTask(with: components.url!)
        (events, continuation) = AsyncStream.makeStream(of: Event.self)
    }

    func start() {
        task.resume()
        receive()
    }

    /// Call from any thread; sends are serialized.
    func send(_ pcm: Data) {
        queue.async { [task] in task.send(.data(pcm)) { _ in } }
    }

    func finalize() {
        queue.async { [task] in task.send(.string("finalize")) { _ in } }
    }

    func close() {
        queue.async { [task] in
            task.send(.string("close")) { _ in }
        }
        queue.asyncAfter(deadline: .now() + 2) { [task, continuation] in
            task.cancel(with: .normalClosure, reason: nil)
            continuation.finish()
        }
    }

    private func receive() {
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(.string(let text)):
                if let event = Self.parse(Data(text.utf8)) { continuation.yield(event) }
                receive()
            case .success(.data(let data)):
                if let event = Self.parse(data) { continuation.yield(event) }
                receive()
            case .success:
                receive()
            case .failure(let error):
                continuation.yield(.error(error.localizedDescription))
                continuation.finish()
            }
        }
    }

    static func parse(_ data: Data) -> Event? {
        struct Message: Decodable {
            struct W: Decodable { var word: String; var start: Double; var end: Double }
            var type: String
            var is_final: Bool?
            var text: String?
            var words: [W]?
            var message: String?
            var title: String?
        }
        guard let m = try? JSONDecoder().decode(Message.self, from: data) else { return nil }
        switch m.type {
        case "transcript":
            if m.is_final == true {
                return .final(m.text ?? "", (m.words ?? []).map { Word(text: $0.word, start: $0.start, end: $0.end) })
            }
            return .partial(m.text ?? "")
        case "flush_done": return .flushed
        case "done": return .closed
        case "error": return .error(m.message ?? m.title ?? "speech-to-text error")
        default: return nil
        }
    }
}
