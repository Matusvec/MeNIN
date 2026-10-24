import Foundation

/// HTTP client for the agent service (homer/API.md). Stateless; safe from any actor.
struct AgentClient: Sendable {
    enum Failure: Error, LocalizedError {
        case status(Int, String)
        case stream(String)

        var errorDescription: String? {
            switch self {
            case .status(let code, let detail): "Agent \(code): \(detail)"
            case .stream(let message): "Agent stream: \(message)"
            }
        }
    }

    let base: URL
    var session: URLSession = .shared

    static var configured: AgentClient? { ServerConfig.agent.map { AgentClient(base: $0) } }

    // MARK: endpoints

    func voiceToken(_ request: VoiceTokenRequest) async throws -> VoiceToken {
        // Without a token the mic and Homer's voice never start: fail fast and try once more.
        try JSONDecoder().decode(VoiceToken.self, from: try await postRaw("voice/token", request, timeout: 6, retries: 1))
    }

    func scan(_ request: ScanRequest) async throws -> VerseScan {
        try await post("scan", request)
    }

    func judge(_ request: JudgeRequest) async throws -> JudgeResult {
        try await post("judge", request)
    }

    /// Server-sent events: the verdict line first, then the full scorecard.
    func judgeStream(_ request: JudgeRequest) -> AsyncThrowingStream<JudgeEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var req = try makeRequest("judge", request)
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    let (bytes, response) = try await session.bytes(for: req)
                    try check(response, body: nil)
                    var parser = SSEParser()
                    for try await line in bytes.lines {
                        // `lines` drops the blank separator line, so a new `event:` also ends the previous one.
                        for event in parser.feed(line) { try continuation.yield(Self.judgeEvent(event)) }
                    }
                    for event in parser.finish() { try continuation.yield(Self.judgeEvent(event)) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func themes(n: Int = 3, demo: Bool) async throws -> [String] {
        struct Themes: Decodable { var themes: [String] }
        var components = URLComponents(url: base.appending(path: "themes"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "n", value: "\(n)"), URLQueryItem(name: "demo", value: demo ? "true" : "false")]
        var req = URLRequest(url: components.url!)
        if !Self.appKey.isEmpty { req.setValue(Self.appKey, forHTTPHeaderField: "X-Homer-Key") }
        let (data, response) = try await session.data(for: req)
        try check(response, body: data)
        return try JSONDecoder().decode(Themes.self, from: data).themes
    }

    /// The scene's color layer in solo modes. Weights don't sum to 1; the renderer normalizes.
    /// 422 (no words yet) and 503 (no reading in time) mean "skip this tick".
    func emotion(_ request: EmotionRequest) async throws -> EmotionWeights {
        struct Response: Decodable { var weights: EmotionWeights }
        let response: Response = try await post("emotion", request)
        return response.weights
    }

    func lessons(bpm: Int = 80) async throws -> [Lesson] {
        struct Lessons: Decodable { var lessons: [Lesson] }
        var components = URLComponents(url: base.appending(path: "lessons"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "bpm", value: "\(bpm)")]
        var req = URLRequest(url: components.url!)
        if !Self.appKey.isEmpty { req.setValue(Self.appKey, forHTTPHeaderField: "X-Homer-Key") }
        let (data, response) = try await session.data(for: req)
        try check(response, body: data)
        return try JSONDecoder().decode(Lessons.self, from: data).lessons
    }

    func lessonFeedback(_ request: LessonFeedbackRequest) async throws -> LessonFeedback {
        try await post("lesson/feedback", request)
    }

    func debateQuestions() async throws -> [DebateQuestion] {
        struct Debate: Decodable { var questions: [DebateQuestion] }
        var req = URLRequest(url: base.appending(path: "debate"))
        if !Self.appKey.isEmpty { req.setValue(Self.appKey, forHTTPHeaderField: "X-Homer-Key") }
        let (data, response) = try await session.data(for: req)
        try check(response, body: data)
        return try JSONDecoder().decode(Debate.self, from: data).questions
    }

    /// One rescue question per move in the hand, prepared at step-up (about 3 s).
    func debateWhispers(_ request: DebateWhispersRequest) async throws -> [String: String] {
        struct Whispers: Decodable { var whispers: [String: String] }
        let response: Whispers = try await post("debate/whispers", request)
        return response.whispers
    }

    func debateRescue(_ request: DebateRescueRequest) async throws -> DebateRescue {
        try await post("rescue", request)
    }

    func deal(_ request: DealRequest) async throws -> DealResponse {
        try await post("deal", request)
    }

    func rescue(_ request: RescueRequest) async throws -> RescueResponse {
        try await post("rescue", request)
    }

    // The arena ignores battle response bodies; results arrive through SpacetimeDB.

    func battleDeal(_ request: BattleDealRequest) async throws {
        _ = try await postRaw("battle/deal", request)
    }

    func battleJudge(_ request: BattleJudgeRequest) async throws {
        _ = try await postRaw("battle/judge", request)
    }

    func battlePoet(_ request: BattlePoetRequest) async throws {
        _ = try await postRaw("battle/poet", request)
    }

    /// 422 (no words yet) and 503 (no reading in time) just mean "skip this tick".
    func battleEmotion(_ request: BattleEmotionRequest) async throws {
        _ = try await postRaw("battle/emotion", request)
    }

    func battleVerdict(_ request: BattleVerdictRequest) async throws {
        _ = try await postRaw("battle/verdict", request)
    }

    func battleSong(_ request: BattleSongRequest) async throws {
        _ = try await postRaw("battle/song", request)
    }

    // MARK: plumbing

    /// Keeps strangers from spending our credits through the public URL (homer/API.md).
    static let appKey = (Bundle.main.object(forInfoDictionaryKey: "HomerAppKey") as? String) ?? ""

    private func makeRequest<B: Encodable>(_ path: String, _ body: B, timeout: TimeInterval = 20) throws -> URLRequest {
        var req = URLRequest(url: base.appending(path: path))
        if !Self.appKey.isEmpty { req.setValue(Self.appKey, forHTTPHeaderField: "X-Homer-Key") }
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        req.timeoutInterval = timeout
        return req
    }

    /// `timeout` is the longest silence allowed while sending or waiting; a stalled request
    /// (seen on venue Wi-Fi: headers sent, body never arrived) is retried `retries` times.
    private func postRaw<B: Encodable>(_ path: String, _ body: B, timeout: TimeInterval = 20, retries: Int = 0) async throws -> Data {
        var attempt = 0
        while true {
            do {
                let (data, response) = try await session.data(for: makeRequest(path, body, timeout: timeout))
                try check(response, body: data)
                return data
            } catch let error as URLError where attempt < retries
                        && [.timedOut, .networkConnectionLost, .cannotConnectToHost, .secureConnectionFailed].contains(error.code) {
                attempt += 1
            }
        }
    }

    private func post<B: Encodable, R: Decodable>(_ path: String, _ body: B) async throws -> R {
        try JSONDecoder().decode(R.self, from: try await postRaw(path, body))
    }

    private func check(_ response: URLResponse, body: Data?) throws {
        guard let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) else { return }
        struct Detail: Decodable { var detail: String }
        let detail = body.flatMap { try? JSONDecoder().decode(Detail.self, from: $0).detail } ?? ""
        throw Failure.status(http.statusCode, detail)
    }

    static func judgeEvent(_ event: SSEParser.Event) throws -> JudgeEvent {
        let data = Data(event.data.utf8)
        switch event.name {
        case "verdict":
            struct Verdict: Decodable { var verdict: String }
            return .verdict(try JSONDecoder().decode(Verdict.self, from: data).verdict)
        case "scorecard":
            return .scorecard(try JSONDecoder().decode(JudgeResult.self, from: data))
        default:
            throw Failure.stream(event.data)
        }
    }
}

/// Minimal server-sent-events parser: `event:` and `data:` fields, events ended by a blank line.
struct SSEParser {
    struct Event: Equatable { var name: String; var data: String }

    private var name: String?
    private var data: [String] = []

    mutating func feed(_ line: String) -> [Event] {
        if line.isEmpty { return flush() }
        if line.hasPrefix(":") { return [] }
        let (field, value) = Self.split(line)
        switch field {
        case "event":
            let finished = flush()
            name = value
            return finished
        case "data":
            data.append(value)
        default:
            break
        }
        return []
    }

    mutating func finish() -> [Event] { flush() }

    private mutating func flush() -> [Event] {
        defer {
            name = nil
            data = []
        }
        guard !data.isEmpty else { return [] }
        return [Event(name: name ?? "message", data: data.joined(separator: "\n"))]
    }

    private static func split(_ line: String) -> (String, String) {
        guard let colon = line.firstIndex(of: ":") else { return (line, "") }
        var value = line[line.index(after: colon)...]
        if value.first == " " { value = value.dropFirst() }
        return (String(line[..<colon]), String(value))
    }
}
