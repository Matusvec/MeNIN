import Foundation
import Observation

/// Pygmachia on the phone: a haptic 3-2-1 to the bell (fight.go_at), the guard pose captured at
/// the bell, then the fist's aim and guard streamed ~20 Hz (set_fist_aim) and each detected punch
/// sent (throw_punch) until fight.ends_at or the KO. The module resolves hits; the phone's HUD
/// reads the fighter rows (health) and the punch log (each new hit flashes once).
@Observable
@MainActor
final class BoxingSession {
    enum Phase: Equatable {
        case waiting
        case countdown(bellAt: Date)
        case fighting
        case over
    }

    private(set) var phase: Phase = .waiting
    /// The newest punch involving this fighter: what the screen flashes.
    private(set) var lastHit: PunchRow?

    @ObservationIgnored private let battle: BattleClient
    @ObservationIgnored private let motion = BoxingMotion()
    @ObservationIgnored private let haptics = BeatHaptics()
    @ObservationIgnored private var follower: Task<Void, Never>?
    @ObservationIgnored private var boutKey: String?
    @ObservationIgnored private var calibrated = false
    @ObservationIgnored private var seenPunch: UInt64 = 0

    init(battle: BattleClient) {
        self.battle = battle
    }

    var motionAvailable: Bool { motion.available }
    var fight: FightRow? { BoxingTables.fight.rows.first { $0.roomId == battle.roomId } }
    var fighters: [FighterRow] { BoxingTables.fighter.rows.filter { $0.roomId == battle.roomId } }
    var me: FighterRow? { battle.me.flatMap { me in fighters.first { $0.playerId == me.id } } }
    var opponent: FighterRow? { battle.me.flatMap { me in fighters.first { $0.playerId != me.id } } }

    func attach() {
        haptics.prepare()
        follower?.cancel()
        follower = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: .milliseconds(50))  // 20 Hz: the aim stream's rate
            }
        }
    }

    func detach() {
        follower?.cancel()
        motion.stop()
    }

    private func tick() {
        guard let room = battle.room, room.event == "pygmachia" else { return }
        trackHits()
        let now = Date().timeIntervalSince1970 * 1000
        guard let fight, fight.goAt.isSet, room.phaseValue == .speaking else {
            if phase == .fighting || isCountdown { motion.stop() }
            phase = (room.phaseValue == .scored || room.phaseValue == .finished || (fight?.endedAt.isSet ?? false)) && boutKey != nil ? .over : .waiting
            return
        }
        let key = "\(fight.roomId).\(fight.goAt.micros)"
        if boutKey != key {
            // A new bout: track through the count-in, tick 3, 2, 1 into the bell.
            boutKey = key
            calibrated = false
            motion.start()
            haptics.countIn(toMs: fight.goAt.epochMs)
            phase = .countdown(bellAt: fight.goAt.date)
        }
        if isCountdown, now >= fight.goAt.epochMs {
            motion.calibrate()  // whatever pose they hold at the bell is centre
            calibrated = true
            phase = .fighting
        }
        guard phase == .fighting else { return }
        if fight.endedAt.isSet || now >= fight.endsAt.epochMs {
            motion.stop()
            phase = .over
            return
        }
        let aim = motion.currentAim
        battle.call(Reducer.SetFistAim.name, Reducer.SetFistAim(roomId: room.id, yaw: Float(aim.yaw), pitch: Float(aim.pitch), guard_: aim.guarding))
        for punch in motion.takePunches() {
            battle.call(Reducer.ThrowPunch.name, Reducer.ThrowPunch(roomId: room.id, kind: punch.kind.rawValue, power: Float(punch.power),
                                                                     aimYaw: Float(punch.yaw), aimPitch: Float(punch.pitch)))
        }
    }

    /// The newest landed or blocked punch thrown by or at this fighter, once each.
    private func trackHits() {
        guard let meId = battle.me?.id else { return }
        let mine = BoxingTables.punch.rows.filter {
            $0.roomId == battle.roomId && ($0.playerId == meId || $0.targetId == meId) && $0.result != "missed" && $0.id > seenPunch
        }
        guard let newest = mine.max(by: { $0.id < $1.id }) else { return }
        seenPunch = newest.id
        lastHit = newest
    }

    private var isCountdown: Bool { if case .countdown = phase { true } else { false } }
}
