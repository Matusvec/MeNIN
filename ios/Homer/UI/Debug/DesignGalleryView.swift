import SwiftUI

/// Debug-only gallery: every presentation component composed over the live
/// scene with sample data, one moment of the turn per page. Swipe through.
/// Sample data lives here and only here; the product never shows it.
struct DesignGalleryView: View {
    @State var page: Int = 0

    var body: some View {
        TabView(selection: $page) {
            GalleryTurnPhone().tag(0)
            GalleryVerdict().tag(1)
            GalleryCarved().tag(2)
            GalleryArenaTurn().tag(3)
            GalleryLobby().tag(4)
            GalleryThemes().tag(5)
            GalleryChampion().tag(6)
            GalleryFirstOpen().tag(7)
            GalleryHall().tag(8)
            GalleryHostsDiscus().tag(9)
            GalleryTurnPieces().tag(10)
            GalleryHome().tag(11)
            ForEach(Array(GallerySample.arenaMoments.enumerated()), id: \.offset) { i, m in
                GalleryArena(model: m).tag(12 + i)
            }
            ForEach(Array(GallerySample.phoneMoments.enumerated()), id: \.offset) { i, m in
                GalleryPhone(model: m).tag(30 + i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .ignoresSafeArea()
        .background(Palette.ink)
    }
}

enum GallerySample {
    static let poets = [
        PoetPlate(id: "a", name: "Matus", epithet: "Breaker of Deadlines", seat: 0, total: 74),
        PoetPlate(id: "b", name: "Sunya", epithet: "Storm-Throated", seat: 1, total: 81),
        PoetPlate(id: "c", name: "Ham", epithet: "Keeper of the Lyre", seat: 2, total: 66),
    ]

    static let hand: [FormulaCard] = [
        FormulaCard(id: "1", text: "the whale-road", kind: .kenning, used: true),
        FormulaCard(id: "2", text: "grey-eyed Athena", kind: .epithet, used: false),
        FormulaCard(id: "3", text: "when rose-fingered Dawn came early", kind: .halfLine, used: false),
        FormulaCard(id: "4", text: "storm-throated", kind: .epithet, used: false),
        FormulaCard(id: "5", text: "bone-house", kind: .kenning, used: false),
    ]

    static let card = Scorecard(
        scores: Scores(beat: 8, craft: 7, image: 9, answer: 6, range: 7),
        verdict: "Strong bones, thin blood. Your third line carried you.",
        bestLine: "The whale-road swallowed his sails")

    /// A lane that started `ago` seconds before now, at 80 BPM.
    static func lane(ago: Double) -> BeatLane {
        let beat = 60_000.0 / 80
        let bar = beat * 4
        func w(_ text: String, line: Int, beatPos: Double, stressed: Bool, onBeat: Bool, formula: String? = nil) -> BeatWord {
            BeatWord(text: text, t: Double(line) * bar * 2 + beatPos * beat, stressed: stressed, onBeat: onBeat, formulaId: formula)
        }
        return BeatLane(bpm: 80, beatsPerLine: 4, lines: 4, startedAt: Date().timeIntervalSince1970 * 1000 - ago * 1000, words: [
            w("Wine", line: 0, beatPos: 0.02, stressed: true, onBeat: true),
            w("dark", line: 0, beatPos: 0.5, stressed: false, onBeat: false),
            w("sea", line: 0, beatPos: 1.05, stressed: true, onBeat: true),
            w("took", line: 0, beatPos: 1.7, stressed: false, onBeat: false),
            w("my", line: 0, beatPos: 1.9, stressed: false, onBeat: false),
            w("brother's", line: 0, beatPos: 2.0, stressed: true, onBeat: true),
            w("ship", line: 0, beatPos: 3.1, stressed: true, onBeat: true),
            w("the", line: 1, beatPos: -0.3, stressed: false, onBeat: false, formula: "1"),
            w("whale-road", line: 1, beatPos: 0.05, stressed: true, onBeat: true, formula: "1"),
            w("swallowed", line: 1, beatPos: 1.3, stressed: true, onBeat: false),
            w("his", line: 1, beatPos: 2.1, stressed: false, onBeat: false),
            w("sails", line: 1, beatPos: 2.95, stressed: true, onBeat: true),
        ])
    }
}

private struct GalleryTurnPhone: View {
    @State private var lane = GallerySample.lane(ago: 13.2)

    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.longing: 0.55, .grief: 0.45]), prosody: Prosody(energy: 0.35, pitch: 150))
            VStack(alignment: .leading, spacing: Metrics.s4) {
                HStack {
                    HStack(spacing: Metrics.s2) {
                        LiveDot()
                        Text("Your turn").tracked(11, color: Palette.paper)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Palette.ink))
                    Spacer()
                    Text("A ship that never came home").chip(10)
                }
                BeatLaneView(lane: lane, style: .pulse)
                TranscriptView(lines: ["Wine-dark sea took my brother's ship", "the whale-road swallowed his sails"],
                               formulas: ["the whale-road"], maxLines: 2)
                Spacer(minLength: 0)
                CaptionView(text: "Grey-eyed Athena.", whisper: true)
                FormulaHandView(cards: GallerySample.hand, raisedId: "2")
            }
            .padding(.horizontal, Metrics.s4)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
    }
}

private struct GalleryVerdict: View {
    @State private var reveal = 0.0

    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.awe: 0.6, .joy: 0.4]))
            VStack(spacing: Metrics.s5) {
                Spacer()
                ScorecardView(card: GallerySample.card, reveal: reveal, poet: "Matus, Breaker of Deadlines")
                CaptionView(text: GallerySample.card.verdict, spoken: reveal)
            }
            .padding(.horizontal, Metrics.s4)
            .padding(.bottom, 48)
        }
        .task {
            reveal = 0
            for i in 1...60 {
                try? await Task.sleep(for: .milliseconds(50))
                reveal = Double(i) / 60
            }
        }
    }
}

private struct GalleryCarved: View {
    @State private var progress = 0.0

    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.defiance: 0.5, .awe: 0.5]))
            CarvedLineView(line: GallerySample.card.bestLine, poet: "Matus, round two", progress: progress)
        }
        .task {
            for i in 1...40 {
                try? await Task.sleep(for: .milliseconds(30))
                progress = Double(i) / 40
            }
        }
    }
}

private struct GalleryArenaTurn: View {
    @State private var lane = GallerySample.lane(ago: 13.2)

    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.anger: 0.6, .defiance: 0.4]), prosody: Prosody(energy: 0.5, pitch: 180))
            VStack(alignment: .leading, spacing: Metrics.s4) {
                TranscriptView(lines: ["Wine-dark sea took my brother's ship", "the whale-road swallowed his sails"],
                               listening: true, formulas: ["the whale-road"])
                BeatLaneView(lane: lane)
                CaptionView(text: "Matus. The sea is yours.", spoken: 1)
            }
            .padding(Metrics.s4)
        }
    }
}

private struct GalleryLobby: View {
    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights())
            VStack(spacing: Metrics.s6) {
                Spacer()
                JoinCardView(code: "WKRD", url: "homer://join/WKRD")
                Spacer()
                EntranceView(poet: GallerySample.poets[0])
                Spacer()
            }
        }
    }
}

private struct GalleryThemes: View {
    @State private var picked: Int?

    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.awe: 0.5, .longing: 0.5]))
            VStack(spacing: Metrics.s6) {
                Text("Judges, pick the theme").chip(13)
                ThemeCardsView(themes: ["A ship that never came home", "The last lamp in the city", "A debt that came due"],
                               selected: picked) { picked = $0 }
            }
            .padding(Metrics.s4)
        }
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            picked = 0
        }
    }
}

private struct GalleryChampion: View {
    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.joy: 0.6, .awe: 0.4]), prosody: Prosody(energy: 0.6, pitch: 200))
            VStack(spacing: Metrics.s6) {
                ChampionView(poet: GallerySample.poets[1], onRematch: {}, onNewPoets: {})
                ScoreboardView(poets: GallerySample.poets, round: 3)
            }
            .padding(Metrics.s4)
        }
    }
}

private struct GalleryFirstOpen: View {
    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.anger: 0.7, .defiance: 0.3]), prosody: Prosody(energy: 0.45, pitch: 160))
            FirstOpenView(beat: .listening,
                          caption: "The first word of Western literature is mēnin. Rage. Give me one line.",
                          heard: "I came here to win and I will not apologize", level: 0.55)
        }
    }
}

private struct GalleryHall: View {
    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights())
            ScrollView {
                EventMenuView(hallNote: "3 poets in the hall")
                    .padding(Metrics.s4)
                    .padding(.top, 40)
            }
        }
    }
}

private struct GalleryHostsDiscus: View {
    @State private var progress = 0.0

    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.joy: 0.5, .defiance: 0.5]), prosody: Prosody(energy: 0.4, pitch: 200))
            VStack(spacing: Metrics.s6) {
                HStack(spacing: Metrics.s5) {
                    HostMedallion(host: .homer, size: 130)
                    HostMedallion(host: .socrates, size: 130)
                }
                DiscusThrowView(distance: 47.3, progress: progress, record: 52.1, poet: "Matus")
            }
            .padding(Metrics.s4)
        }
        .task {
            for i in 1...45 {
                try? await Task.sleep(for: .milliseconds(30))
                progress = Double(i) / 45
            }
        }
    }
}

private struct GalleryTurnPieces: View {
    @State private var held = true

    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.longing: 0.6, .tenderness: 0.4]), prosody: Prosody(energy: 0.5, pitch: 170))
            VStack(spacing: Metrics.s4) {
                AnswerLineView(line: "The whale-road swallowed his sails", poet: "Sunya")
                RevealedCardView(card: GallerySample.hand[1], poet: "Matus")
                Spacer()
                HoldToTalkView(isHeld: $held, level: 0.6).frame(height: 300)
            }
            .padding(Metrics.s4)
            .padding(.top, 50)
        }
    }
}

private struct GalleryHome: View {
    @State private var tab = "atelier"

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneView(emotion: EmotionWeights())
            HomeView(name: "Alex",
                     lesson: .init(path: "Bard / Lesson 02", title: "The formula,\nhalf a line for free",
                                   meta: "Four-beat line · 4 min", progress: 0.6),
                     collectionSummary: "12 formulas · 2 battles · Herald")
                .safeAreaPadding(.top, 50)
            HomeTabBar(selection: $tab)
        }
    }
}

extension GallerySample {
    static var plates: [PoetPlate] { poets }

    static var arenaMoments: [ArenaModel] {
        let p = poets
        var base = ArenaModel(code: "WKRD", joinURL: "homer://join/WKRD", round: 2, rounds: 3,
                              theme: "A ship that never came home", poets: p)
        var lobby = base
        lobby.round = 0
        lobby.theme = nil
        lobby.moment = .lobby(entering: p[1])
        lobby.homer = HomerLine(text: "Enter Sunya, Storm-Throated!", spoken: 0.7)
        var speaking = base
        speaking.liveId = "a"
        speaking.moment = .speaking(poet: p[0], lane: lane(ago: 13.2),
                                    transcript: ["Wine-dark sea took my brother's ship", "the whale-road swallowed his sails"],
                                    played: [hand[0]], answer: AnswerPrompt(line: "The lamp burned out before the dawn", poet: "Sunya"))
        var verdict = base
        verdict.moment = .verdict(poet: p[0], card: card, reveal: 1, coined: "storm-throated")
        verdict.homer = HomerLine(text: card.verdict, spoken: 1)
        var end = base
        end.moment = .roundEnd(bestLine: card.bestLine, by: "Matus, round two", carve: 1)
        var finale = base
        finale.round = 3
        finale.moment = .finale(lines: ["Wine-dark sea took my brother's ship", "the whale-road swallowed his sails",
                                        "The lamp burned out before the dawn", "and still the oars kept time"], current: 1)
        var champ = base
        champ.round = 3
        champ.moment = .champion(p[1])
        base.moment = .roundTitle
        return [lobby, speaking, verdict, end, finale, champ, base]
    }

    static var phoneMoments: [PlayerModel] {
        let me = poets[0]
        var join = PlayerModel()
        join.moment = .joining(error: nil)
        var speak = PlayerModel(me: me, code: "WKRD", round: 2, rounds: 3, theme: "A ship that never came home")
        speak.moment = .speaking(lane: lane(ago: 13.2), transcript: "Wine-dark sea took my brother's ship\nthe whale-road swallowed his sails",
                                 hand: hand, rescueId: "2", talking: true, level: 0.6, pushToTalk: true)
        speak.homer = HomerLine(text: "Grey-eyed Athena.", whisper: true)
        var result = PlayerModel(me: me, code: "WKRD", round: 2, rounds: 3)
        result.moment = .result(card: card, reveal: 1, coined: "storm-throated")
        var final = PlayerModel(me: me, code: "WKRD", round: 3, rounds: 3)
        final.moment = .final(place: 2, of: 3, champion: poets[1])
        return [join, speak, result, final]
    }
}

private struct GalleryArena: View {
    let model: ArenaModel
    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.longing: 0.5, .awe: 0.5]), prosody: Prosody(energy: 0.4, pitch: 170))
            ArenaView(model: model, actions: ArenaActions(begin: {}, pickTheme: { _ in }, advance: {}, rematch: {}, newPoets: {}))
        }
    }
}

private struct GalleryPhone: View {
    let model: PlayerModel
    var body: some View {
        ZStack {
            SceneView(emotion: EmotionWeights([.grief: 0.5, .longing: 0.5]), prosody: Prosody(energy: 0.4, pitch: 150))
            PlayerView(model: model, actions: PlayerActions(join: { _, _ in }, imHere: {}, ready: {}, setTalking: { _ in }, done: {}))
                .safeAreaPadding(.top, 54)
        }
    }
}

#Preview { DesignGalleryView() }
