import Foundation
import Observation

/// The Stadion on the phone: when the arena starts the heat, a haptic 3-2-1 to go_at, then the
/// poet pumps their arms and the phone streams its own speed and distance (set_stride, 10 Hz) until
/// 192 m or the end of the heat. The server places and times runners as they cross.
@Observable
@MainActor
final class StadionSession {
    enum Phase: Equatable {
        case waiting  // the heat isn't started: "hold the phone, pump your arms on GO"
        case countdown(goAt: Date)
        case running
        case done
    }

    private(set) var phase: Phase = .waiting
    private(set) var reading = StadionMotion.Reading()

    @ObservationIgnored private let battle: BattleClient
    @ObservationIgnored private let motion = StadionMotion()
    @ObservationIgnored private let haptics = BeatHaptics()
    @ObservationIgnored private var follower: Task<Void, Never>?
    @ObservationIgnored private var heatStarted: String?

    init(battle: BattleClient) {
        self.battle = battle
    }

    var motionAvailable: Bool { motion.available }

    func attach() {
        haptics.prepare()
        follower?.cancel()
        follower = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: .milliseconds(100))  // 10 Hz: the stride stream's rate
            }
        }
    }

    func detach() {
        follower?.cancel()
        motion.stop()
    }

    var heat: HeatRow? { StadionTables.heat.rows.first { $0.roomId == battle.roomId } }
    var runners: [RunnerRow] { StadionTables.runner.rows.filter { $0.roomId == battle.roomId } }
    var myRunner: RunnerRow? { battle.me.flatMap { me in runners.first { $0.playerId == me.id } } }

    private func tick() {
        guard let room = battle.room, room.event == "stadion" else { return }
        let now = Date().timeIntervalSince1970 * 1000
        guard let heat, room.phaseValue == .speaking, heat.goAt.isSet else {
            if phase == .running || isCountdown { finishRun() }
            if room.phaseValue != .speaking { phase = room.phaseValue == .scored || room.phaseValue == .finished ? .done : .waiting }
            return
        }
        let key = "\(heat.roomId).\(heat.heatNo).\(heat.goAt.micros)"
        if heatStarted != key {
            // A new heat: warm the tracker through the count-in, and tick 3, 2, 1, GO in the hand.
            heatStarted = key
            motion.start()
            haptics.countIn(toMs: heat.goAt.epochMs)
            phase = .countdown(goAt: heat.goAt.date)
        }
        if isCountdown, now >= heat.goAt.epochMs {
            motion.go()
            phase = .running
        }
        guard phase == .running else { return }
        reading = motion.current
        battle.call(Reducer.SetStride.name, Reducer.SetStride(roomId: room.id, speed: Float(reading.speed), distance: Float(reading.distance)))
        if reading.distance >= StadionMotion.stadionMeters || myRunner?.place ?? 0 > 0 || now >= heat.capAt.epochMs {
            finishRun()
        }
    }

    private var isCountdown: Bool { if case .countdown = phase { true } else { false } }

    private func finishRun() {
        motion.stop()
        if phase == .running { haptics.hit() }  // across the line
        phase = .done
    }
}
