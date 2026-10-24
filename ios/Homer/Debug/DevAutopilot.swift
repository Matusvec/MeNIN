import Foundation
import os

/// Dev only: drives a battle through the real BattleClient so a multi-device smoke test
/// runs without taps. Off unless the app is launched with `-autopilot arena|player`.
///   arena:  creates a demo room, begins at 2 poets, advances each reveal after a pause
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
        log.info("autopilot: \(key, privacy: .public)")
        print("AUTOPILOT \(key)")
        action()
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
        switch room.phaseValue {
        case .lobby where battle.players.count >= 2:
            once("begin \(room.id)") { battle.startBattle() }
        case .scored, .roundEnd, .finale:
            let key = "advance \(room.phase) \(room.currentTurnId) \(room.roundNo)"
            guard !done.contains(key) else { return }
            done.insert(key)
            print("AUTOPILOT \(key)")
            let from = battle.revealKey
            Task {
                // The conductor advances auto-ready rooms itself once Homer's line ends.
                try? await Task.sleep(for: .seconds(room.autoReady ? 12 : 2))
                battle.advanceOnce(from: from)
            }
        case .finished:
            once("finished \(room.id)") {
                let standings = battle.players.sorted { $0.total > $1.total }.map { "\($0.name)=\($0.total)" }
                print("AUTOPILOT standings \(standings.joined(separator: " "))")
            }
        default:
            break
        }
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
                    print("AUTOPILOT transcript \(recorder.transcript.replacingOccurrences(of: "\n", with: " | "))")
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
