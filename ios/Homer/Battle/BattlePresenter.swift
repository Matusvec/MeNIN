import Foundation
import SwiftUI

/// Maps live battle state onto the art lead's value models (UI/Battle/BattleModels.swift).
/// Pure functions of their inputs: the views only render, the presenters only map.
@MainActor
enum BattlePresenter {
    // MARK: shared

    static func plate(_ p: PlayerRow) -> PoetPlate {
        PoetPlate(id: "\(p.id)", name: p.name, epithet: p.epithet, seat: Int(p.seat), total: Int(p.total))
    }

    static func lines(_ transcript: String) -> [String] {
        transcript.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    /// The hand rows carry only card text; the kind is a best guess for styling.
    static func card(_ text: String, played: Bool = false) -> FormulaCard {
        let words = text.split(separator: " ")
        let kind: FormulaCard.Kind = words.count >= 4 ? .halfLine
            : (words.contains { $0.first?.isUppercase == true } ? .epithet : .kenning)
        return FormulaCard(id: text, text: text, kind: kind, used: played)
    }

    static func homerLine(_ voice: HomerVoice?) -> HomerLine? {
        guard let line = voice?.caption else { return nil }
        return HomerLine(text: line.text, spoken: voice?.spoken ?? 1, whisper: line.whisper)
    }

    /// The line the poet answers (P7): the previous poet's best line this round, else the theme.
    static func answer(to turn: TurnRow, in battle: BattleClient) -> AnswerPrompt? {
        let previous = battle.turns.first { $0.roundId == turn.roundId && $0.turnNo + 1 == turn.turnNo }
        if let previous, let best = battle.score(for: previous.id)?.bestLine, !best.isEmpty {
            return AnswerPrompt(line: best, poet: battle.player(previous.playerId)?.name)
        }
        return battle.currentRound.map { AnswerPrompt(line: $0.theme, poet: nil) }
    }

    static func event(_ room: RoomRow) -> EventKind { EventKind(rawValue: room.event) ?? .poetry }

    /// Sides alternate by turn order: turn 0 argues the first side.
    static func side(_ turn: TurnRow) -> DebateSide { turn.turnNo % 2 == 0 ? .affirm : .deny }

    static func move(_ id: String, played: Bool) -> FormulaCard {
        FormulaCard(id: id, text: id, kind: .move, used: played)
    }

    /// Talk to Homer: a verse attempt's /100 (the 5 poetry axes; a talk-back has none) and the change
    /// from this poet's previous scored attempt.
    static func coachScore(_ battle: BattleClient, before turn: TurnRow, mine: UInt64) -> (score: Int?, change: Int?, axes: [AxisScore]?) {
        guard let row = battle.score(for: turn.id), row.axes.count == Axis.allCases.count else { return (nil, nil, nil) }
        let ruling = ruling(row, event: .poetry)
        let earlier = battle.turns
            .filter { $0.playerId == mine && $0.turnNo < turn.turnNo }
            .sorted { $0.turnNo > $1.turnNo }
            .compactMap { battle.score(for: $0.id) }
            .first { $0.axes.count == Axis.allCases.count }
        return (Int(row.total), earlier.map { Int(row.total) - Int($0.total) }, ruling.axes)
    }

    static func ruling(_ score: ScoreRow, event: EventKind) -> Ruling {
        // Poetry's total is the server's weighted one, out of 100 (post_score); debate sums its axes.
        event == .poetry
            ? Ruling(event: event, values: score.axes.map(Int.init), verdict: score.verdict, bestLine: score.bestLine,
                     weightedTotal: Int(score.total), outOf: 100)
            : Ruling(event: event, values: score.axes.map(Int.init), verdict: score.verdict, bestLine: score.bestLine)
    }

    static func endsAt(_ turn: TurnRow) -> Date? { turn.endsAt.isSet ? turn.endsAt.date : nil }

    static func roman(_ n: Int) -> String {
        ["", "I", "II", "III", "IV", "V", "VI"][min(max(n, 0), 6)]
    }

    static func lane(_ room: RoomRow, startedAt: Double, words: [BeatWord] = []) -> BeatLane {
        BeatLane(bpm: Double(room.bpm), beatsPerLine: 4, lines: Int(room.linesPerTurn), startedAt: startedAt, words: words)
    }

    // MARK: arena

    /// `inHall`: the arena operator went back to the hall after a crown (P16), so the event
    /// tiles show while everyone stays joined.
    static func arena(_ battle: BattleClient, conductor: ArenaConductor?, inHall: Bool = false) -> ArenaModel? {
        guard let room = battle.room else { return nil }
        let homer = conductor?.homer
        var model = ArenaModel(
            code: room.code,
            joinURL: "homer://join/\(room.code)",
            round: Int(room.roundNo),
            rounds: Int(room.rounds),
            theme: battle.currentRound?.theme,
            poets: battle.players.map(plate),
            liveId: nil,
            homer: homerLine(homer)
        )
        model.event = event(room)
        if inHall {
            model.moment = .hall(entering: nil, events: EventTile.all.map { tile in
                var t = tile
                t.locked = tile.locked || !AppModel.liveEvents.contains(tile.id)
                return t
            })
            return model
        }
        let turn = battle.currentTurn
        let poet = turn.flatMap { battle.player($0.playerId) }.map(plate)
        let saying = conductor?.saying
        // A reveal tracks Homer's voice while he says it, and stays complete afterwards.
        func reveal(_ key: String) -> Double { saying == key ? (homer?.spoken ?? 1) : 1 }

        switch room.phaseValue {
        case .lobby, .none:
            let entering = conductor?.entering.flatMap { battle.player($0) }.map(plate)
            model.moment = .lobby(entering: entering)
        case .theme:
            model.moment = .themePick(themes: conductor?.themeCards ?? [], picked: nil)
        case .dealing:
            model.moment = .roundTitle
        case .ready:
            if let turn, let poet {
                model.moment = .stepUp(poet: poet, answer: answer(to: turn, in: battle))
            } else {
                model.moment = .roundTitle
            }
        case .speaking where room.event == "debate":
            guard let turn, let poet else { break }
            model.liveId = poet.id
            model.moment = .debating(poet: poet, side: side(turn), question: battle.currentRound?.theme ?? "",
                                     transcript: lines(turn.transcript), played: turn.played.map { move($0, played: true) },
                                     endsAt: endsAt(turn), seconds: Double(room.turnSeconds))
        case .speaking:
            guard let turn, let poet else { break }
            model.liveId = poet.id
            model.moment = .speaking(
                poet: poet,
                lane: lane(room, startedAt: turn.beatAt.epochMs),
                transcript: lines(turn.transcript),
                played: turn.played.map { card($0, played: true) },
                answer: answer(to: turn, in: battle)
            )
        case .judging:
            guard let turn, let poet else { break }
            model.moment = .judging(poet: poet, transcript: lines(turn.transcript))
        case .scored:
            guard let turn, let poet else { break }
            if room.event == "debate", let score = battle.score(for: turn.id) {
                model.moment = .ruling(poet: poet, ruling: ruling(score, event: .debate), reveal: reveal("verdict \(turn.id)"))
            } else if let score = battle.score(for: turn.id), let card = score.poetryScorecard {
                model.moment = .verdict(poet: poet, card: card, reveal: reveal("verdict \(turn.id)"),
                                        coined: score.coined.isEmpty ? nil : score.coined)
            } else {
                model.moment = .judging(poet: poet, transcript: lines(turn.transcript))
            }
        case .roundEnd:
            let round = battle.currentRound
            let name = round.flatMap { r in battle.turns.first { $0.id == r.bestTurnId } }.flatMap { battle.player($0.playerId)?.name } ?? ""
            let by = name.isEmpty ? "" : "\(name), round \(roman(Int(room.roundNo)))"
            var carve = 0.0
            if let round {
                // Homer's round verdict is "lead-in: the carved line"; the gold carving starts at the colon.
                let colon = round.verdict.firstIndex(of: ":").map { Double(round.verdict.distance(from: round.verdict.startIndex, to: $0)) / Double(max(round.verdict.count, 1)) } ?? 0
                let spoken = reveal("round \(round.id)")
                carve = round.verdict.isEmpty ? 0 : min(1, max(0, (spoken - colon) / max(0.05, (1 - colon) * 0.6)))
            }
            model.moment = .roundEnd(bestLine: round?.bestLine ?? "", by: by, carve: carve)
        case .finale:
            model.moment = .finale(lines: battle.songLines.map(\.text), current: conductor?.songLine ?? 0)
        case .finished:
            if let top = battle.players.max(by: { $0.total < $1.total }) {
                model.moment = .champion(plate(top))
            }
        }
        return model
    }

    static func arenaActions(_ battle: BattleClient, conductor: ArenaConductor?, inHall: Binding<Bool>? = nil) -> ArenaActions {
        guard let room = battle.room else { return ArenaActions() }
        let config = Reducer.CreateRoom(event: room.event, rounds: room.rounds, barsPerLine: room.barsPerLine,
                                        linesPerTurn: room.linesPerTurn, bpm: room.bpm, form: room.form,
                                        autoReady: room.autoReady, themeChoice: room.themeChoice, demo: room.demo)
        let themes = conductor?.themeCards ?? []
        return ArenaActions(
            begin: room.phaseValue == .lobby && battle.players.count >= 2 ? { battle.startBattle() } : nil,
            pickTheme: room.phaseValue == .theme ? { i in if themes.indices.contains(i) { battle.chooseTheme(themes[i]) } } : nil,
            advance: { battle.advanceOnce() },
            rematch: room.phaseValue != .lobby ? { battle.rematch() } : nil,
            newPoets: { battle.createRoom(config) },
            pickEvent: inHall?.wrappedValue == true ? { kind in
                // P16: switch the open hall to the picked event; poets, epithets and seats stay.
                battle.setEvent(kind.rawValue, rounds: Reducer.CreateRoom.preset(event: kind.rawValue, demo: room.demo).rounds)
                inHall?.wrappedValue = false
            } : nil,
            backToHall: room.phaseValue == .finished && inHall != nil ? { inHall?.wrappedValue = true } : nil,
            cue: { conductor?.play($0) }
        )
    }

    // MARK: phone

    static func player(_ battle: BattleClient, recorder: TurnRecorder?, homer: HomerVoice? = nil) -> PlayerModel {
        guard let room = battle.room, let me = battle.me else {
            return PlayerModel(moment: .joining(error: battle.lastError))
        }
        var model = PlayerModel(me: plate(me), code: room.code, round: Int(room.roundNo), rounds: Int(room.rounds),
                                theme: battle.currentRound?.theme, homer: homerLine(homer))
        model.event = event(room)
        model.announced = me.entered && me.named
        model.handsFree = TurnRecorder.handsFree
        if !me.entered {
            model.moment = .micCheck
            return model
        }
        if room.phaseValue == .finished {
            let ranked = battle.players.sorted { $0.total > $1.total }
            let place = (ranked.firstIndex { $0.id == me.id } ?? 0) + 1
            if let top = ranked.first {
                model.moment = .final(place: place, of: ranked.count, champion: plate(top))
                return model
            }
        }
        guard let turn = battle.currentTurn else {
            model.moment = .waiting(watching: nil, transcript: [])
            return model
        }
        // Homer's phrases: optional bonus (Craft). The phone shows the dealer's top 3 of the 5 dealt;
        // speaking any of the 5 still counts (Matus: "why do we even care about the hands").
        let hand = battle.myHand.prefix(3).map { card($0, played: turn.played.contains($0)) }
        guard turn.playerId == me.id else {
            model.moment = .waiting(watching: battle.player(turn.playerId).map(plate), transcript: lines(turn.transcript))
            return model
        }
        switch turn.statusValue {
        case .waiting where room.event == "coach":
            // Talk to Homer: his last answer stays up while the next turn gets ready.
            let previous = battle.turns.filter { $0.playerId == me.id && $0.turnNo < turn.turnNo }.max { $0.turnNo < $1.turnNo }
            if let previous, let reply = battle.score(for: previous.id)?.verdict, !reply.isEmpty {
                let scored = coachScore(battle, before: previous, mine: me.id)
                model.moment = .answering(reply: reply, yourTurnAgain: true, score: scored.score, change: scored.change, axes: scored.axes)
            } else {
                model.moment = .onDeck(hand: [], autoReady: room.autoReady)
            }
        case .judging where room.event == "coach":
            model.moment = .answering(reply: nil, yourTurnAgain: false)
        case .scored where room.event == "coach", .declined where room.event == "coach", .skipped where room.event == "coach":
            let row = battle.score(for: turn.id)
            let reply = row?.verdict
            let scored = coachScore(battle, before: turn, mine: me.id)
            model.moment = .answering(reply: reply?.isEmpty == false ? reply : nil, yourTurnAgain: false,
                                      score: scored.score, change: scored.change, axes: scored.axes)
        case .waiting:
            model.moment = .onDeck(hand: hand, autoReady: room.autoReady)
        case .speaking where recorder?.phase == .closing:
            // Reopened mid-turn: the server's timer closes it with what was already said.
            model.moment = .closing(transcript: lines(turn.transcript))
        case .speaking where room.event == "debate":
            let live = recorder?.phase == .live || recorder?.phase == .finishing
            model.moment = .debating(
                side: side(turn), question: battle.currentRound?.theme ?? "",
                transcript: live ? (recorder?.transcript ?? "") : turn.transcript,
                moves: battle.myHand.map { move($0, played: turn.played.contains($0)) },
                whisperedId: recorder?.rescueCard, talking: recorder?.talking ?? false,
                level: recorder?.mic.prosody.energy ?? 0, endsAt: endsAt(turn), seconds: Double(room.turnSeconds)
            )
        case .speaking:
            // Free verse: one window from SPEAK (beat_at) to ends_at, on this device's clock (NTP).
            if TurnRecorder.freeVerse, room.event != "debate", turn.beatAt.isSet, turn.endsAt.isSet {
                model.verseWindow = VerseWindow(start: turn.beatAt.date, end: turn.endsAt.date)
            }
            let clock = recorder?.clock
            model.moment = .speaking(
                lane: lane(room, startedAt: clock?.beatAtMs ?? turn.beatAt.epochMs, words: recorder?.hitMarks ?? []),
                transcript: recorder?.phase == .live || recorder?.phase == .finishing ? (recorder?.transcript ?? "") : turn.transcript,
                hand: hand,
                rescueId: recorder?.rescueCard,
                talking: recorder?.talking ?? false,
                level: recorder?.mic.prosody.energy ?? 0,
                pushToTalk: !TurnRecorder.handsFree
            )
        case .judging:
            model.moment = .weighing
        case .scored, .declined, .skipped:
            if room.event == "debate", let score = battle.score(for: turn.id) {
                model.moment = .ruling(ruling(score, event: .debate), reveal: 1)
            } else if let score = battle.score(for: turn.id), let card = score.poetryScorecard {
                model.moment = .result(card: card, reveal: 1, coined: score.coined.isEmpty ? nil : score.coined)
            } else {
                model.moment = .weighing
            }
        case .none:
            model.moment = .waiting(watching: nil, transcript: [])
        }
        return model
    }
}
