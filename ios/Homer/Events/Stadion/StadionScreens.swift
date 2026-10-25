import SwiftUI

/// The poet's phone in a Stadion room: the art lead's RunView fed by StadionSession.
struct StadionPhoneRoot: View {
    let battle: BattleClient
    var onBack: (() -> Void)?
    @State private var session: StadionSession?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            RunView(model: model(at: context.date), onBack: onBack)
        }
        .task {
            UIApplication.shared.isIdleTimerDisabled = true
            battle.watchEventTables("stadion")
            let s = StadionSession(battle: battle)
            s.attach()
            session = s
        }
        .onDisappear {
            session?.detach()  // the poet screen keeps the screen awake while in the room
        }
    }

    private func model(at now: Date) -> RunModel {
        var m = RunModel()
        m.me = battle.me.map(BattlePresenter.plate)
        let runners = session?.runners ?? []
        m.runners = max(1, runners.count)
        guard let session else { return m }
        let mine = session.myRunner
        switch session.phase {
        case .waiting:
            m.phase = .waiting(session.motionAvailable ? nil : "This phone can't track motion.")
        case .countdown(let goAt):
            let left = goAt.timeIntervalSince(now)
            m.phase = .countdown(left > 0 ? min(3, Int(left / 0.75) + 1) : 0)
        case .running:
            m.phase = .running
        case .done:
            if let mine, mine.place > 0 {
                m.phase = .finished(place: Int(mine.place), of: max(1, runners.count), seconds: mine.time > 0 ? Double(mine.time) : nil)
            } else {
                m.phase = .waiting("Across the line. Homer is placing the runners…")
            }
        }
        m.speed = min(1, session.reading.speed / StadionMotion.topSpeed)
        m.progress = min(1, session.reading.distance / StadionMotion.stadionMeters)
        // Live place: by distance among those still running, behind anyone already placed.
        if case .running = session.phase {
            let ahead = runners.filter { $0.playerId != mine?.playerId && ($0.place > 0 || Double($0.distance) > session.reading.distance) }.count
            m.place = ahead + 1
        }
        return m
    }
}
