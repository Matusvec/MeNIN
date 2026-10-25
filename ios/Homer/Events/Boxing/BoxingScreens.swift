import SwiftUI

/// The fighter's phone in a pygmachia room: the art lead's FightView fed by BoxingSession.
struct BoxingPhoneRoot: View {
    let battle: BattleClient
    var onBack: (() -> Void)?
    @State private var session: BoxingSession?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            FightView(model: model(at: context.date), onBack: onBack)
        }
        .task {
            UIApplication.shared.isIdleTimerDisabled = true
            battle.watchEventTables("pygmachia")
            let s = BoxingSession(battle: battle)
            s.attach()
            session = s
        }
        .onDisappear {
            session?.detach()  // the poet screen keeps the screen awake while in the room
        }
    }

    private func model(at now: Date) -> FightModel {
        var m = FightModel()
        m.me = battle.me.map(BattlePresenter.plate)
        guard let session else { return m }
        if let opp = session.opponent, let row = battle.player(opp.playerId) { m.opponent = BattlePresenter.plate(row) }
        m.myHealth = Double(session.me?.health ?? 100) / 100
        m.theirHealth = Double(session.opponent?.health ?? 100) / 100
        m.myStamina = Double(session.me?.stamina ?? 100) / 100
        m.theirStamina = Double(session.opponent?.stamina ?? 100) / 100
        if let fight = session.fight, fight.endsAt.isSet {
            m.seconds = max(0, Int(fight.endsAt.date.timeIntervalSince(now).rounded(.up)))
        }
        switch session.phase {
        case .waiting:
            if !session.motionAvailable {
                m.phase = .waiting("This phone can't track motion.")
            } else if session.me == nil, session.fighters.count == 2 {
                let names = session.fighters.compactMap { battle.player($0.playerId)?.name }
                m.phase = .waiting("Up next: you fight the winner of \(names.joined(separator: " vs "))")
            } else {
                m.phase = .waiting(nil)
            }
        case .countdown(let bellAt):
            let left = bellAt.timeIntervalSince(now)
            m.phase = .countdown(left > 0 ? min(3, Int(left / 0.75) + 1) : 0)
        case .fighting:
            m.phase = .fighting
        case .over:
            let meId = battle.me?.id ?? 0
            m.phase = .ko(won: session.fight?.winnerId == meId && meId != 0)
        }
        if let hit = session.lastHit {
            let landed = hit.playerId == battle.me?.id
            let blocked = hit.result == "blocked"
            let label = blocked ? "BLOCKED!" : (hit.zone == "body" ? "BODY!" : hit.kind.uppercased() + "!")
            m.hit = .init(id: Int(hit.id), landed: landed, label: label, blocked: blocked, counter: hit.counter,
                          combo: hit.combo >= 2 ? Int(hit.combo) : nil)
        }
        return m
    }
}
