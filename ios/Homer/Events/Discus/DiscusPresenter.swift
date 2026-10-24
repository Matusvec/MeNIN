import Foundation
import Observation

/// Homer's discus lines (UX section 9), each with the key of its pre-rendered clip in
/// `Resources/Voice/`. Lines with a name are captioned, and spoken live if the arena has a voice.
enum DiscusLines {
    static let rules = HomerVoice.Script(key: "discus-rules", caption: "Grip it. Swing. Let go of the button, not the phone.",
                                         speech: "Grip it. Swing. Let go of the button, not the phone.")
    static let lookAtItGo = HomerVoice.Script(key: "discus-look", caption: "Look at it go.", speech: "Look at it go.")
    static let short = HomerVoice.Script(key: "discus-short", caption: "A gentle toss. The crowd forgives you.",
                                         speech: "A gentle toss. The crowd forgives you.")
    static let good = HomerVoice.Script(key: "discus-good", caption: "Strong arm.", speech: "Strong arm.")
    static let hallBest = HomerVoice.Script(key: "discus-record", caption: "New mark. Remember that name.",
                                            speech: "New mark. Remember that name.")
    static let phayllos = HomerVoice.Script(key: "discus-phayllos", caption: "Past Phayllos. They'll carve that one.",
                                            speech: "Past fay-loss. They'll carve that one.")
    static let foul = HomerVoice.Script(key: "discus-foul", caption: "Into the crowd. They'll live.", speech: "Into the crowd. They'll live.")

    static func stepsIn(_ name: String) -> String { "\(name) steps into the circle." }
    static func champion(_ name: String) -> String { "The discus goes to \(name)." }

    /// "Good" starts here; shorter is a gentle toss.
    static let goodThrow = 20.0
    /// Homer only calls the flight on long throws.
    static let longThrow = 40.0

    static func landing(_ label: DiscusArenaModel.Landing?, distance: Double, isFoul: Bool) -> HomerVoice.Script {
        if isFoul { return foul }
        switch label {
        case .hallBest: return hallBest
        case .pastPhayllos: return phayllos
        default: return distance >= goodThrow ? good : short
        }
    }
}

/// Paces the arena's reveal of each throw (UX D3–D6) and moves the battle on when it's done.
/// The flight starts when this arena first sees the throw, not at the server timestamp, so a
/// clock that's off between devices can't skip the flight.
@Observable
@MainActor
final class DiscusDirector {
    /// Flight, then the landing and Homer's call, then a beat on the board.
    static func flightSeconds(_ metres: Double) -> Double { 1.5 + 1.5 * min(1, max(0, metres) / 80) }
    static let landedSeconds = 3.0
    static let boardSeconds = 2.0
    static let noThrowSeconds = 3.0
    static let championSeconds = 6.0

    private(set) var seen: [String: Date] = [:]
    /// The last line Homer was given, for arenas with no voice; HomerVoice captions its own.
    private(set) var caption: String?
    @ObservationIgnored private var captionUntil = Date.distantPast
    @ObservationIgnored private let battle: BattleClient
    @ObservationIgnored private let homer: HomerVoice?
    @ObservationIgnored private var said = Set<String>()
    @ObservationIgnored private var ticker: Task<Void, Never>?

    init(battle: BattleClient, homer: HomerVoice?) {
        self.battle = battle
        self.homer = homer
    }

    func start() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick(Date())
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
    }

    /// When this arena first saw the reveal for the current turn (or the finale).
    func since(_ key: String) -> Date? { seen[key] }

    private func tick(_ now: Date) {
        if caption != nil, now > captionUntil { caption = nil }
        guard let room = battle.room, room.event == "discus", let key = battle.revealKey else { return }
        let turn = battle.currentTurn
        switch room.phaseValue {
        case .ready, .speaking:
            if let turn, let thrower = battle.player(turn.playerId) {
                say("in \(turn.id)", DiscusLines.stepsIn(thrower.name))
            }
        case .scored:
            guard let turn else { return }
            let start = mark(key, now)
            let t = now.timeIntervalSince(start)
            if let row = battle.discusThrow(for: turn.id) {
                let d = Double(row.distance)
                let flight = Self.flightSeconds(d)
                if !row.foul, d >= DiscusLines.longThrow { say("look \(turn.id)", DiscusLines.lookAtItGo) }
                if t >= flight {
                    let label = DiscusPresenter.landing(for: row, in: battle.discusThrows)
                    say("land \(turn.id)", DiscusLines.landing(label, distance: d, isFoul: row.foul))
                }
                if t >= flight + Self.landedSeconds + Self.boardSeconds { battle.advanceOnce(from: key) }
            } else if turn.statusValue == .skipped, t >= Self.noThrowSeconds {
                battle.advanceOnce(from: key)
            }
        case .finale:
            let start = mark(key, now)
            if let champ = DiscusPresenter.champion(battle) { say("champion \(room.id) \(room.roundNo)", DiscusLines.champion(champ.name)) }
            if now.timeIntervalSince(start) >= Self.championSeconds { battle.advanceOnce(from: key) }
        default:
            break
        }
    }

    private func mark(_ key: String, _ now: Date) -> Date {
        if let at = seen[key] { return at }
        seen[key] = now
        return now
    }

    private func say(_ id: String, _ text: String) {
        guard said.insert(id).inserted else { return }
        show(text)
        homer?.enqueue(text)
    }

    private func say(_ id: String, _ script: HomerVoice.Script) {
        guard said.insert(id).inserted else { return }
        show(script.caption)
        if let homer { Task { await homer.say(script) } }
    }

    private func show(_ text: String) {
        caption = text
        captionUntil = Date().addingTimeInterval(3)
    }
}

/// Maps discus state onto the art lead's value models (UI/Discus/DiscusViews.swift).
/// Pure functions of their inputs: the views only render.
@MainActor
enum DiscusPresenter {
    static func best(_ rows: [DiscusThrowRow]) -> Double? {
        rows.filter { !$0.foul }.map { Double($0.distance) }.max()
    }

    /// Highest best throw; a tie goes to whoever threw it first.
    static func champion(_ b: BattleClient) -> PlayerRow? {
        let landed = b.discusThrows.filter { !$0.foul && $0.distance > 0 }
        guard let top = landed.max(by: { ($0.distance, -Double($0.id)) < ($1.distance, -Double($1.id)) }) else { return nil }
        return b.player(top.playerId)
    }

    /// What a landing earned: the hall's best beats passing Phayllos, which beats a personal best.
    static func landing(for row: DiscusThrowRow, in all: [DiscusThrowRow]) -> DiscusArenaModel.Landing? {
        guard !row.foul else { return nil }
        let before = all.filter { $0.id < row.id }
        let d = Double(row.distance)
        if let hall = best(before), d > hall { return .hallBest }
        if d > DiscusPhysics.phayllos { return .pastPhayllos }
        // A personal best needs an earlier throw to beat (a foul counts as nothing).
        let mine = before.filter { $0.playerId == row.playerId }
        if !mine.isEmpty, d > (best(mine) ?? 0) { return .personalBest }
        return nil
    }

    // MARK: arena

    static func arena(_ b: BattleClient, director: DiscusDirector, caption: String?, now: Date) -> DiscusArenaModel {
        var m = DiscusArenaModel()
        guard let room = b.room else { return m }
        m.attempts = Int(room.rounds)
        m.attempt = max(1, min(Int(room.rounds), Int(room.roundNo)))
        m.caption = caption

        let turn = b.currentTurn
        let current = turn.flatMap { b.discusThrow(for: $0.id) }
        var landed = true
        switch room.phaseValue {
        case .ready, .speaking:
            m.thrower = turn.flatMap { b.player($0.playerId) }.map(BattlePresenter.plate)
            if room.phaseValue == .speaking, let p = b.prosody, p.turnId == turn?.id, p.hits > 0 {
                m.phase = .winding(power: Double(p.loudness))
            }
        case .scored:
            m.thrower = turn.flatMap { b.player($0.playerId) }.map(BattlePresenter.plate)
            if let row = current, let key = b.revealKey {
                let t = now.timeIntervalSince(director.since(key) ?? now)
                let flight = DiscusDirector.flightSeconds(Double(row.distance))
                m.distance = Double(row.distance)
                if t < flight {
                    m.phase = .flight(progress: t / flight)
                    landed = false
                } else {
                    m.phase = .landed(foul: row.foul)
                    m.landing = landing(for: row, in: b.discusThrows)
                }
            }
        case .finale, .finished:
            m.champion = champion(b).map(BattlePresenter.plate)
        default:
            break
        }

        // The throw in the air isn't on the board or the record until it lands.
        let counted = b.discusThrows.filter { landed || $0.id != current?.id }
        m.board = b.players.map { p in DiscusMark(poet: BattlePresenter.plate(p), best: best(counted.filter { $0.playerId == p.id })) }
        if let top = counted.filter({ !$0.foul }).max(by: { $0.distance < $1.distance }), top.distance > 0 {
            m.record = Double(top.distance)
            m.recordHolder = b.player(top.playerId)?.name
        }
        return m
    }

    // MARK: phone

    static func phone(_ b: BattleClient, thrower: DiscusThrower, safetyAcked: Bool, now: Date) -> DiscusPhoneModel {
        var m = DiscusPhoneModel(phase: .waiting(thrower: nil))
        guard let room = b.room, let me = b.me else { return m }
        let mine = b.discusThrows.filter { $0.playerId == me.id }
        let done = b.turns.filter { $0.playerId == me.id && ($0.statusValue == .scored || $0.statusValue == .skipped) }.count
        m.attemptsLeft = max(0, Int(room.rounds) - done)
        m.best = best(mine)
        m.notice = thrower.notice

        let turn = b.currentTurn
        let up = turn.flatMap { b.player($0.playerId) }
        switch room.phaseValue {
        case .speaking where b.isMyTurn:
            if !safetyAcked {
                m.phase = .safety
                m.notice = nil
            } else {
                switch thrower.stage {
                case .ready: m.phase = .ready
                case .winding: m.phase = .winding(power: thrower.power)
                case .thrown(let t, let at): m.phase = thrownPhase(t.distance, foul: t.foul, since: at, now: now)
                }
            }
        case .scored where b.isMyTurn:
            if let row = turn.flatMap({ b.discusThrow(for: $0.id) }) {
                m.phase = thrownPhase(Double(row.distance), foul: row.foul, since: thrower.thrownAt ?? .distantPast, now: now)
            } else {
                m.notice = "Out of time. No throw this round."
            }
        case .finale, .finished:
            m.notice = champion(b).map { DiscusLines.champion($0.name) }
        default:
            // Someone else is up, or it's my turn in the step-up beat before the circle opens.
            if let up, up.id != me.id { m.phase = .waiting(thrower: up.name) }
        }
        return m
    }

    /// "Look up" until the arena's flight has landed, then the distance (UX D3–D5).
    private static func thrownPhase(_ metres: Double, foul: Bool, since: Date, now: Date) -> DiscusPhoneModel.Phase {
        let flying = now.timeIntervalSince(since) < DiscusDirector.flightSeconds(metres)
        return .thrown(distance: flying || foul ? nil : metres, foul: foul && !flying)
    }
}
