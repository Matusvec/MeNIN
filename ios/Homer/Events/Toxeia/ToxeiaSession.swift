import Foundation
import Observation

/// Toxeia on a phone: it's either the archer's BOW (streams aim, asks each archer's name) or the
/// ARROW (nock, pull, loose). The station comes from the range row once claimed.
@Observable
@MainActor
final class ToxeiaSession {
    enum Station: Equatable { case unknown, bow, arrow }

    private(set) var station: Station = .unknown
    private(set) var nocked = false
    private(set) var draw = 0.0
    private(set) var aim = BowMotion.Aim()
    /// The newest arrow_shot in this room (the bow shows where it hit; the arrow thunks once).
    private(set) var lastShot: ArrowShotRow?

    @ObservationIgnored private let battle: BattleClient
    @ObservationIgnored private let bow = BowMotion()
    @ObservationIgnored private let arrow = ArrowMotion()
    @ObservationIgnored private let haptics = BeatHaptics()
    @ObservationIgnored private var follower: Task<Void, Never>?
    @ObservationIgnored private var claimed = false
    @ObservationIgnored private var seenShot: UInt64 = 0
    @ObservationIgnored private var ended = false

    init(battle: BattleClient) {
        self.battle = battle
    }

    var range: RangeRow? { ToxeiaTables.range.rows.first { $0.roomId == battle.roomId } }
    var archer: ArcherRow? { range.flatMap { r in ToxeiaTables.archer.rows.first { $0.id == r.archerId } } }
    var archers: [ArcherRow] { ToxeiaTables.archer.rows.filter { $0.roomId == battle.roomId } }
    var needsName: Bool { station == .bow && battle.room?.phaseValue == .ready && (range?.archerId ?? 0) == 0 }
    var arrowUp: Bool { battle.room?.phaseValue == .speaking && (range?.archerId ?? 0) != 0 }

    /// No names to type: the archers are the room's players in join order (seat), each once. Whoever
    /// has shot already is skipped by name, counted so two of the same name both get their turn.
    var nextArcher: PlayerRow? {
        var shot = Dictionary(archers.map { ($0.name, 1) }, uniquingKeysWith: +)
        for p in battle.players {
            if let n = shot[p.name], n > 0 { shot[p.name] = n - 1; continue }
            if p.connected { return p }
        }
        return nil
    }

    func attach() {
        haptics.prepare()
        follower?.cancel()
        follower = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: .milliseconds(50))  // 20 Hz: aim and draw
            }
        }
    }

    func detach() {
        follower?.cancel()
        bow.stop()
        arrow.stop()
    }

    // MARK: actions

    func claim(_ role: String) {
        guard let room = battle.room else { return }
        battle.call(Reducer.ClaimStation.name, Reducer.ClaimStation(roomId: room.id, role: role))
        claimed = true
    }

    /// The next archer's name; an empty name is "That's everyone" (the module goes to the finale).
    private func name(_ archer: String) {
        let name = archer.trimmingCharacters(in: .whitespaces)
        guard let room = battle.room else { return }
        battle.call(Reducer.NextArcher.name, Reducer.NextArcher(roomId: room.id, name: name))
    }

    /// The bow's "Ready", tapped by the archer up at arm's length: where it points now is the centre,
    /// and the next player in join order is the archer.
    func ready() {
        bow.zero()
        if needsName, let next = nextArcher { name(next.name) }
    }

    /// The arrow phone's pad: thumb down nocks, thumb up looses.
    func setNocked(_ on: Bool) {
        guard station == .arrow, on != nocked else { return }
        nocked = on
        if on {
            arrow.nock()
        } else {
            let shot = arrow.loose()
            draw = 0
            if arrowUp, let room = battle.room {
                battle.call(Reducer.Loose.name, Reducer.Loose(roomId: room.id, draw: Float(shot)))
                haptics.hit()  // the string snaps
            }
        }
    }

    // MARK: loop

    private func tick() {
        guard let room = battle.room, room.event == "toxeia", let me = battle.me else { return }
        if !claimed, range != nil { claim("") }  // first come gets the bow
        let next: Station = range?.bowId == me.id ? .bow : range?.arrowId == me.id ? .arrow : .unknown
        if next != station {
            station = next
            bow.stop()
            arrow.stop()
            if next == .bow { bow.start() }
            if next == .arrow { arrow.start() }
        }
        trackShots()
        // Everyone has shot: the range closes by itself (no "That's everyone" to tap).
        if archers.isEmpty { ended = false }
        if station == .bow, needsName, !ended, !archers.isEmpty, nextArcher == nil {
            ended = true
            name("")
        }
        guard arrowUp else { return }
        switch station {
        case .bow:
            aim = bow.current
            battle.call(Reducer.SetBowAim.name, Reducer.SetBowAim(roomId: room.id, yaw: Float(aim.yaw), pitch: Float(aim.pitch)))
        case .arrow:
            guard nocked else { return }
            draw = arrow.draw
            battle.call(Reducer.SetDraw.name, Reducer.SetDraw(roomId: room.id, draw: Float(draw)))
        case .unknown:
            break
        }
    }

    private func trackShots() {
        let shots = ToxeiaTables.arrowShot.rows.filter { $0.roomId == battle.roomId && $0.id > seenShot }
        guard let newest = shots.max(by: { $0.id < $1.id }) else { return }
        let first = seenShot == 0
        seenShot = newest.id
        lastShot = newest
        if !first, station == .arrow || station == .bow { haptics.hit() }  // the thunk on the target
    }
}
