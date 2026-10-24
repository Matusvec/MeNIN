import Foundation

// Everything the battle screens show, as plain values. The iOS lead maps
// BattleClient (room, players, turns, scores) into these; the views only render.

/// What Homer is saying right now, for the caption.
struct HomerLine: Equatable {
    var text: String
    /// 0...1: how far his voice has got through the line.
    var spoken: Double = 1
    /// The freeze rescue: a whispered formula.
    var whisper: Bool = false
}

/// The line the poet on the mic is answering (P7). `poet` is nil when it is the round's theme.
struct AnswerPrompt: Equatable {
    var line: String
    var poet: String?
}

// MARK: - Arena

struct ArenaModel: Equatable {
    var code: String
    var joinURL: String
    /// Which game: sets the host in the captions and the rubric's labels.
    var event: EventKind = .poetry
    var round: Int = 0
    var rounds: Int = 3
    var theme: String?
    /// Everyone in the hall, for the lobby and the scoreboard.
    var poets: [PoetPlate] = []
    /// Who is on the mic, marked live on the scoreboard.
    var liveId: String?
    var homer: HomerLine?
    var moment: ArenaMoment = .lobby(entering: nil)
}

enum ArenaMoment: Equatable {
    /// The hall: everyone joined, choosing the next event (SPEC: the hall stays open between events).
    case hall(entering: PoetPlate?, events: [EventTile])
    /// H1 · Poets join; `entering` plays the entrance for a poet who just passed the mic check.
    case lobby(entering: PoetPlate?)
    /// Demo mode: three theme cards; the judges pick one.
    case themePick(themes: [String], picked: Int?)
    /// B2 · The round's title and theme.
    case roundTitle
    /// T1 · The next poet steps up.
    case stepUp(poet: PoetPlate, answer: AnswerPrompt?)
    /// T2–T3 · The verse is live.
    case speaking(poet: PoetPlate, lane: BeatLane, transcript: [String], played: [FormulaCard], answer: AnswerPrompt?)
    /// T4 · Homer is weighing it.
    case judging(poet: PoetPlate, transcript: [String])
    /// T5–T8 · The verdict, the scores counting up (`reveal` 0...1), the best line, a coined formula.
    case verdict(poet: PoetPlate, card: Scorecard, reveal: Double, coined: String?)
    /// B4 · The round's best line carved (`carve` 0...1) over the standings.
    case roundEnd(bestLine: String, by: String, carve: Double)
    /// B6 · The stitched song; `current` is the line being performed.
    case finale(lines: [String], current: Int)
    /// B7 · The crown.
    case champion(PoetPlate)

    // Socratic debate: the turn without the beat.
    /// A speaker argues their side; the clock replaces the beat lane.
    case debating(poet: PoetPlate, side: DebateSide, question: String, transcript: [String], played: [FormulaCard], endsAt: Date?, seconds: Double)
    /// Any event's judged turn, with its own rubric (debate: Claim, Reason, Answer, Craft, Poise).
    case ruling(poet: PoetPlate, ruling: Ruling, reveal: Double)

    // Discus.
    case discus(DiscusArenaModel)
}

/// What the arena's buttons do. Every closure is optional; a missing one hides its button.
struct ArenaActions {
    var begin: (() -> Void)?
    var pickTheme: ((Int) -> Void)?
    var advance: (() -> Void)?
    var rematch: (() -> Void)?
    var newPoets: (() -> Void)?
    /// The hall: start the chosen event with everyone in it (BattleClient.setEvent).
    var pickEvent: ((EventKind) -> Void)?
    /// Champion and round end: go back to the hall instead of a rematch.
    var backToHall: (() -> Void)?
    /// The arena's sound cues, fired once on the frame each thing lands. The conductor plays them.
    var cue: ((ArenaCue) -> Void)?

    init(begin: (() -> Void)? = nil, pickTheme: ((Int) -> Void)? = nil, advance: (() -> Void)? = nil,
         rematch: (() -> Void)? = nil, newPoets: (() -> Void)? = nil,
         pickEvent: ((EventKind) -> Void)? = nil, backToHall: (() -> Void)? = nil, cue: ((ArenaCue) -> Void)? = nil) {
        self.begin = begin
        self.pickTheme = pickTheme
        self.advance = advance
        self.rematch = rematch
        self.newPoets = newPoets
        self.pickEvent = pickEvent
        self.backToHall = backToHall
        self.cue = cue
    }
}

/// Moments the arena wants heard. Each fires once, on the frame it lands on screen,
/// so a sound played on the cue hits with the picture.
enum ArenaCue: Equatable {
    /// An entrance slab hits (a lobby entrance or "Up next"): the slam.
    case slam
    /// A played formula card lands face up.
    case flip
    /// One scorecard axis finished counting up (0-based, in order): a knock.
    case knock(axis: Int)
    /// The total lands after the last axis: the heavy knock.
    case total
    /// The chisel starts cutting the best line.
    case carve
    /// The champion's crown lands.
    case crown
}

// MARK: - Phone

struct PlayerModel: Equatable {
    var event: EventKind = .poetry
    var me: PoetPlate?
    var code: String = ""
    var round: Int = 0
    var rounds: Int = 3
    var theme: String?
    var homer: HomerLine?
    var moment: PlayerMoment = .joining(error: nil)
    /// True once the arena has announced this poet's entrance: the phone thumps with the slam.
    var announced: Bool = false
    /// When voice is unavailable: the typed fallback's text, shown in the action band in place of push-to-talk.
    var typed: String? = nil
}

enum PlayerMoment: Equatable {
    /// J1 · Type the code and a name.
    case joining(error: String?)
    /// J2 · The mic check; Homer gives you your epithet.
    case micCheck
    /// J3 · In the hall, or watching someone else's turn.
    case waiting(watching: PoetPlate?, transcript: [String])
    /// T0–T1 · You're next: your hand comes forward.
    case onDeck(hand: [FormulaCard], autoReady: Bool)
    /// T2–T3 · Your verse. `rescueId` is the card Homer whispers on a freeze.
    case speaking(lane: BeatLane, transcript: String, hand: [FormulaCard], rescueId: String?, talking: Bool, level: Double, pushToTalk: Bool)
    /// T4 · Homer is weighing it.
    case weighing
    /// You reopened the app mid-turn: the mic stays closed and the server's
    /// timer ends the turn with what you already said.
    case closing(transcript: [String])
    /// T5–T8 · Your scores (`reveal` 0...1) and anything coined into your hoard.
    case result(card: Scorecard, reveal: Double, coined: String?)
    /// B7 · Where you placed.
    case final(place: Int, of: Int, champion: PoetPlate)

    // Socratic debate.
    /// Your turn to argue. Tap a move as you make it; `whisperedId` is the move Socrates whispers on a freeze.
    case debating(side: DebateSide, question: String, transcript: String, moves: [FormulaCard], whisperedId: String?,
                  talking: Bool, level: Double, endsAt: Date?, seconds: Double)
    /// Your judged turn in any event.
    case ruling(Ruling, reveal: Double)
    // Discus on the phone is its own screen: DiscusPhoneView, routed by the discus presenter.
}

struct PlayerActions {
    var join: ((_ code: String, _ name: String) -> Void)?
    var imHere: (() -> Void)?
    var ready: (() -> Void)?
    var setTalking: ((Bool) -> Void)?
    var done: (() -> Void)?
    /// Debate: a move card tapped as the speaker makes it (the card's id).
    var playMove: ((String) -> Void)?
    /// Back out (to home). The back chevron on every phone screen.
    var leave: (() -> Void)?
    /// The typed fallback's text changed.
    var type: ((String) -> Void)?

    init(join: ((String, String) -> Void)? = nil, imHere: (() -> Void)? = nil, ready: (() -> Void)? = nil,
         setTalking: ((Bool) -> Void)? = nil, done: (() -> Void)? = nil,
         playMove: ((String) -> Void)? = nil, leave: (() -> Void)? = nil, type: ((String) -> Void)? = nil) {
        self.join = join
        self.imHere = imHere
        self.ready = ready
        self.setTalking = setTalking
        self.done = done
        self.playMove = playMove
        self.leave = leave
        self.type = type
    }
}
