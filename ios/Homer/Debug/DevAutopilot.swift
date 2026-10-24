import Foundation
import os

/// Dev only: drives a battle through the real BattleClient so a multi-device smoke test
/// runs without taps. Off unless the app is launched with `-autopilot arena|player`.
///   arena:  creates a demo room, begins at 2 poets, advances each reveal after a pause;
///           with `-autopilotRematches N`, presses Rematch N times and times each reset
///   player: joins `-joinCode` as `-poetName`, passes the mic check, types a verse on its turn
@MainActor
final class DevAutopilot {
    static var mode: String? { UserDefaults.standard.string(forKey: "autopilot") }

    private let battle: BattleClient
    /// Set by the phone screen; when voice is live the autopilot holds push-to-talk instead of typing.
    var recorder: TurnRecorder?
    private let log = Logger(subsystem: "com.matusvec.homer", category: "autopilot")
    private var task: Task<Void, Never>?
    private var done = Set<String>()
    /// Battles finished in this room, and when the last Rematch was pressed (epoch s).
    private var battles = 0
    private var rematchAt: Double?
    /// The room is showing final standings (count each battle once, on arrival).
    private var inFinished = false

    init?(battle: BattleClient) {
        guard let mode = Self.mode, mode == battle.role.rawValue else { return nil }
        self.battle = battle
    }

    func start() {
        task = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    func stop() { task?.cancel() }

    /// Runs `action` once per key.
    private func once(_ key: String, _ action: () -> Void) {
        guard !done.contains(key) else { return }
        done.insert(key)
        report(key)
        action()
    }

    /// Stdout for simulator runs, the unified log for the Mac arena (launched with `open`).
    private func report(_ line: String) {
        print("AUTOPILOT \(line)")
        log.info("AUTOPILOT \(line, privacy: .public)")
    }

    private func tick() {
        guard battle.connection == .connected, battle.room?.event != "discus" else { return }
        switch battle.role {
        case .arena: arenaTick()
        case .player: playerTick()
        }
    }

    private func arenaTick() {
        guard let room = battle.room else {
            once("create") { battle.createRoom(.demoMode) }
            return
        }
        once("room \(room.code)") {}
        // The rematch drill: reset means the new battle's hands are dealt and its first turn is up
        // (hands are private to each poet, so the arena sees the turn, not the cards).
        if let t0 = rematchAt, room.phaseValue == .ready || room.phaseValue == .speaking || room.phaseValue == .theme,
           battle.currentTurn != nil || room.phaseValue == .theme {
            rematchAt = nil
            report(String(format: "reset in %.1f s (phase %@)", Date().timeIntervalSince1970 - t0, room.phase))
        }
        switch room.phaseValue {
        case .lobby where battle.players.count >= 2:
            once("begin \(room.id)") { battle.startBattle() }
        case .scored, .roundEnd, .finale:
            let key = "advance \(room.phase) \(room.currentTurnId) \(room.roundNo) g\(battle.generation)"
            guard !done.contains(key) else { return }
            done.insert(key)
            report("\(key)")
            let from = battle.revealKey
            Task {
                // The conductor advances auto-ready rooms itself once Homer's line ends.
                try? await Task.sleep(for: .seconds(room.autoReady ? (room.phaseValue == .finale ? 45 : 12) : 2))  // the song runs long
                battle.advanceOnce(from: from)
            }
        case .finished:
            guard !inFinished else { return }
            inFinished = true
            report("finished \(room.id) battle \(battles + 1)")
            do {
                battles += 1
                let standings = battle.players.sorted { $0.total > $1.total }.map { "\($0.name)=\($0.total)" }
                report("standings \(standings.joined(separator: " "))")
                guard battles <= UserDefaults.standard.integer(forKey: "autopilotRematches") else { return }
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    report("rematch \(battles)")
                    rematchAt = Date().timeIntervalSince1970
                    battle.rematch()
                }
            }
        default:
            break
        }
        if room.phaseValue != .finished { inFinished = false }
    }

    private func playerTick() {
        let defaults = UserDefaults.standard
        guard let code = defaults.string(forKey: "joinCode"), let name = defaults.string(forKey: "poetName") else { return }
        guard let me = battle.me else {
            once("join \(code)") { battle.join(code: code, name: name) }
            return
        }
        if !me.entered { once("enter") { battle.enter() } }
        guard let turn = battle.currentTurn, battle.isMyTurn, let room = battle.room else { return }
        switch turn.statusValue {
        case .waiting where !room.autoReady:
            once("ready \(turn.id)-\(turn.attempt)") { battle.startTurn(turn.id) }
        case .speaking where recorder?.phase == .live:
            once("talk \(turn.id)") {
                guard let recorder else { return }
                let lines = Int(room.linesPerTurn)
                Task {
                    // Hold through each speaking bar, release in the rest bar.
                    let bar = room.barSeconds
                    for _ in 0..<lines {
                        recorder.setTalking(true)
                        try? await Task.sleep(for: .seconds(bar))
                        recorder.setTalking(false)
                        try? await Task.sleep(for: .seconds(bar * Double(max(1, Int(room.barsPerLine)) - 1) + 0.2))
                    }
                    report("transcript \(recorder.transcript.replacingOccurrences(of: "\n", with: " | "))")
                    await recorder.finish()
                }
            }
        case .speaking where recorder?.phase == .preparing || recorder?.phase == .ready:
            break  // voice is still coming up
        case .speaking:
            once("verse \(turn.id)") {
                let verse = ["The wine-dark sea took my brother's ship", "and grey-eyed Athena would not hear his cry"]
                    .prefix(Int(room.linesPerTurn)).joined(separator: "\n")
                battle.updateTranscript(turn.id, verse)
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    battle.endTurn(turn.id, verse)
                }
            }
        default:
            break
        }
    }
}
