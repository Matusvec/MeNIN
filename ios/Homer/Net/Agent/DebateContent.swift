import Foundation

/// The debate questions, fetched once from GET /debate. `round.theme` is the question exactly
/// as Socrates asks it; its sides alternate by turn order (turn 0 argues sides[0]).
@MainActor
final class DebateContent {
    static let shared = DebateContent()
    private var questions: [DebateQuestion] = []
    private var loading: Task<Void, Never>?

    func load(_ agent: AgentClient?) {
        guard questions.isEmpty, loading == nil, let agent else { return }
        loading = Task {
            questions = (try? await agent.debateQuestions()) ?? []
            loading = nil
        }
    }

    /// The side text for a turn ("Yes" or "No"), or nil while the content hasn't loaded.
    func side(for question: String, turnNo: UInt32) -> String? {
        guard let q = questions.first(where: { $0.ask == question || $0.id == question }), q.sides.count >= 2 else { return nil }
        return q.sides[Int(turnNo) % 2]
    }
}
