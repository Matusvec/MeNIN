import SwiftUI

/// A phone in a Toxeia room: the art lead's BowView or ArrowView, whichever station this phone holds.
struct ToxeiaPhoneRoot: View {
    let battle: BattleClient
    var onBack: (() -> Void)?
    @State private var session: ToxeiaSession?

    /// The target face's radius (World Archery 122 cm face), for the shot's position on the view's −1...1 face.
    static let faceRadius = 0.61

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            if let session, session.station == .arrow {
                ArrowView(model: arrowModel(session), actions: ArrowActions(nock: { session.setNocked($0) }, back: onBack))
            } else {
                BowView(model: bowModel(session), actions: BowActions(
                    ready: { session?.ready() },
                    back: onBack
                ))
            }
        }
        .task {
            UIApplication.shared.isIdleTimerDisabled = true
            battle.watchEventTables("toxeia")
            let s = ToxeiaSession(battle: battle)
            s.attach()
            session = s
        }
        .onDisappear {
            session?.detach()  // the poet screen keeps the screen awake while in the room
        }
    }

    private func bowModel(_ s: ToxeiaSession?) -> BowModel {
        var m = BowModel()
        guard let s else { return m }
        if let archer = s.archer { m.archer = PoetPlate(id: "\(archer.id)", name: archer.name, epithet: "", seat: 0) }
        m.yaw = s.aim.yaw
        m.pitch = s.aim.pitch
        m.shot = Int(s.range?.arrowNo ?? 0)
        m.total = s.archer.map { Int($0.total) }
        if let wind = s.range?.wind { m.wind = ArcheryWind(speed: Double(abs(wind)), toward: wind >= 0 ? 0 : 180) }
        // flight 0 = the window ran out with no loose: nothing hit the face.
        if let shot = s.lastShot, shot.archerId == s.range?.archerId, shot.flight > 0 {
            m.lastShot = ArcheryShot(x: Double(shot.x) / Self.faceRadius, y: Double(shot.y) / Self.faceRadius, score: Int(shot.ring))
        }
        if s.needsName {
            // No names to type: the next player in join order takes the bow and taps Ready.
            if let next = s.nextArcher {
                m.phase = .role
                m.archer = PoetPlate(id: "\(next.id)", name: next.name, epithet: next.epithet, seat: Int(next.seat))
                m.passOn = !s.archers.isEmpty  // the phones come from the archer before
            } else {
                m.phase = .waiting(s.archers.isEmpty ? "Waiting for the archers" : "That's everyone")
            }
        } else if s.arrowUp {
            // Each arrow zeroes once the bow is held still on the target.
            m.phase = s.steadying ? .zeroing : .aiming
        } else {
            m.phase = .waiting(waitLine(s))
        }
        return m
    }

    private func arrowModel(_ s: ToxeiaSession) -> ArrowModel {
        var m = ArrowModel()
        m.nocked = s.nocked
        m.draw = s.draw
        m.shot = Int(s.range?.arrowNo ?? 0)
        m.total = s.archer.map { Int($0.total) }
        if let shot = s.lastShot, shot.archerId == s.range?.archerId { m.lastScore = Int(shot.ring) }
        let ready = battle.room?.phaseValue == .ready && (s.range?.archerId ?? 0) == 0
        if s.arrowUp {
            m.phase = .drawing
        } else if ready {
            m.phase = s.archers.isEmpty ? .role : .passing
        } else {
            m.phase = .waiting(waitLine(s))
        }
        return m
    }

    private func waitLine(_ s: ToxeiaSession) -> String? {
        switch battle.room?.phaseValue {
        case .lobby: "Waiting for the host to open the range"
        case .scored: "Homer is scoring the arrow…"
        case .finale, .finished: "The range is closed"
        default: s.station == .unknown ? "Finding your station…" : nil
        }
    }
}
