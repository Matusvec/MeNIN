import Foundation
import Observation
import os

/// Toxeia on a phone: it's either the archer's BOW (streams aim, calls up each archer) or the
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
    /// The bow's arrow is up but it hasn't been held still yet, so the aim isn't zeroed.
    private(set) var steadying = false

    private static let log = Logger(subsystem: "com.matusvec.homer", category: "toxeia")

    @ObservationIgnored private let battle: BattleClient
    @ObservationIgnored private let bow = BowMotion()
    @ObservationIgnored private let arrow = ArrowMotion()
    @ObservationIgnored private let haptics = BeatHaptics()
    @ObservationIgnored private var follower: Task<Void, Never>?
    @ObservationIgnored private var claimed = false
    @ObservationIgnored private var seenShot: UInt64 = 0
    @ObservationIgnored private var ended = false
    /// "archer-arrow" of the arrow up, nil between arrows.
    @ObservationIgnored private var arrowKey: String?
    @ObservationIgnored private var arrowSince = Date.distantPast
    /// A loose not yet answered: resent while the same arrow is up, for at most 2 s (loose carries
    /// no arrow id, so a resend must never outlive its arrow and loose the next one).
    @ObservationIgnored private var pendingLoose: (key: String, draw: Float, first: Date, at: Date)?
    @ObservationIgnored private var lastTick: Date?

    init(battle: BattleClient) {
        self.battle = battle
    }

    var range: RangeRow? { ToxeiaTables.range.rows.first { $0.roomId == battle.roomId } }
    var archer: ArcherRow? { range.flatMap { r in ToxeiaTables.archer.rows.first { $0.id == r.archerId } } }
    var archers: [ArcherRow] { ToxeiaTables.archer.rows.filter { $0.roomId == battle.roomId } }
    var needsName: Bool { station == .bow && battle.room?.phaseValue == .ready && (range?.archerId ?? 0) == 0 }
    var arrowUp: Bool { battle.room?.phaseValue == .speaking && (range?.archerId ?? 0) != 0 }
    /// Camera archery: the webcam aims and draws; whoever's up looses with their own phone.
    var camera: Bool { range?.camera ?? false }
    /// My own archer row (camera mode shows each phone its own total).
    var mine: ArcherRow? {
        guard let me = battle.me?.name.lowercased() else { return nil }
        return archers.first { $0.name.lowercased() == me }
    }

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
            // 20 Hz on a fixed grid: the sleep is to the next 50 ms mark, not 50 ms after a busy tick.
            let clock = ContinuousClock()
            var next = clock.now
            while !Task.isCancelled {
                self?.tick()
                next += .milliseconds(50)
                if next < clock.now { next = clock.now }  // fell behind: carry on, don't burst
                try? await Task.sleep(until: next, clock: clock)
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

    /// The bow's "Ready": the next player in join order is the archer. Each arrow zeroes the aim
    /// itself once the bow is held still.
    func ready() {
        if needsName, let next = nextArcher { name(next.name) }
    }

    /// The arrow phone's pad: thumb down nocks, thumb up looses.
    func setNocked(_ on: Bool) {
        guard station == .arrow, on != nocked else { return }
        nocked = on
        if on {
            // No haptic here: the buzz is the first strong movement ArrowMotion sees, so it would
            // set the pull axis and the real pull back would barely count (MYWH: draws of 0.37).
            arrow.nock()
            Self.log.info("nock \(self.arrowKey ?? "-", privacy: .public)")
        } else {
            let shot = arrow.loose()
            draw = 0
            Self.log.info("loose \(self.arrowKey ?? "-", privacy: .public) draw \(shot)")
            if arrowUp, let room = battle.room, let key = arrowKey {
                // The module counts a loose only once this arrow's draw is above 0, so the lift
                // sends its draw first (in order, one socket) even if no stream got through. The
                // resends below are loose alone: a late pair must never arm the next arrow. With
                // the camera, the draw is the camera's and the loose's own is ignored.
                if !camera {
                    battle.call(Reducer.SetDraw.name, Reducer.SetDraw(roomId: room.id, draw: Float(max(shot, 0.01))))
                }
                battle.call(Reducer.Loose.name, Reducer.Loose(roomId: room.id, draw: Float(shot)))
                pendingLoose = (key, Float(shot), Date(), Date())
                haptics.hit()  // the string snaps
            }
        }
    }

    // MARK: loop

    private func tick() {
        guard let room = battle.room, room.event == "toxeia", let me = battle.me else { return }
        if !claimed, let r = range, !r.camera { claim("") }  // first come gets the bow (no stations with the camera)
        let next: Station = range?.bowId == me.id ? .bow : range?.arrowId == me.id ? .arrow : .unknown
        if next != station {
            station = next
            bow.stop()
            arrow.stop()
            if next == .bow { bow.start() }
            if next == .arrow { arrow.start() }
        }
        trackShots()
        let now = Date()
        if let lastTick, now.timeIntervalSince(lastTick) > 0.25 {
            Self.log.info("tick gap \(Int(now.timeIntervalSince(lastTick) * 1000)) ms")
        }
        lastTick = now
        let key = arrowUp ? range.map { "\($0.archerId)-\($0.arrowNo)" } : nil
        if key != arrowKey {
            arrowKey = key
            pendingLoose = nil
            // A lift we never heard (a cancelled touch) never carries into the next arrow.
            if nocked { nocked = false; draw = 0; _ = arrow.loose() }
            if key != nil, station == .bow {
                bow.zeroWhenSteady()
                steadying = true
                arrowSince = now
            }
        }
        if steadying {
            // Held still, or 3 s on: zero where it points.
            if bow.zeroed { steadying = false }
            else if now.timeIntervalSince(arrowSince) > 3 { bow.zero(); steadying = false }
        }
        if let p = pendingLoose, now.timeIntervalSince(p.first) > 2 { pendingLoose = nil }
        if let p = pendingLoose, p.key == arrowKey, now.timeIntervalSince(p.at) >= 0.5, let room = battle.room {
            battle.call(Reducer.Loose.name, Reducer.Loose(roomId: room.id, draw: p.draw))
            pendingLoose = (p.key, p.draw, p.first, now)
            Self.log.info("loose resent \(p.key, privacy: .public)")
        }
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
            guard nocked, !camera else { return }  // the camera's draw needs no stream
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
