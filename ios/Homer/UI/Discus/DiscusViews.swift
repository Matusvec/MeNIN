import SwiftUI

// Discus: a motion minigame, no voice. On the phone you hold the discus with
// your thumb, swing, and lift your thumb to throw. On the arena the throw flies.
// multiplayer owns the motion capture and the presenter (ios/Homer/Events/Discus/)
// and fills these models; the views only render.

struct DiscusArenaModel: Equatable {
    enum Phase: Equatable {
        /// The thrower is stepping into the ring (or reading the rules).
        case waiting
        /// Thumb down, winding up: `power` 0...1 from the swing so far.
        case winding(power: Double)
        /// Released: the flight, `progress` 0...1.
        case flight(progress: Double)
        /// Down. `distance` is final; a foul went into the crowd and doesn't count.
        case landed(foul: Bool)
    }

    /// What a landing earned, stamped on the arena.
    enum Landing: Equatable {
        case personalBest, hallBest, pastPhayllos

        var title: String {
            switch self {
            case .personalBest: "Personal best"
            case .hallBest: "Best in the hall"
            case .pastPhayllos: "Past Phayllos"
            }
        }
    }

    var thrower: PoetPlate?
    var phase: Phase = .waiting
    /// Metres. Final at release; the flight counts up to it.
    var distance: Double = 0
    var record: Double?
    var recordHolder: String?
    var attempt: Int = 1
    var attempts: Int = 3
    /// Best throw per poet so far.
    var board: [DiscusMark] = []
    var landing: Landing?
    /// What Homer is saying now; everything he says is captioned.
    var caption: String?
    /// The end: "The discus goes to …".
    var champion: PoetPlate?
}

struct DiscusMark: Equatable, Identifiable {
    var poet: PoetPlate
    var best: Double?
    var id: String { poet.id }
}

struct DiscusPhoneModel: Equatable {
    enum Phase: Equatable {
        /// D0: the safety card, once, before the first throw.
        case safety
        /// Someone else is throwing.
        case waiting(thrower: String?)
        /// Your turn: put your thumb on the discus.
        case ready
        /// Thumb down, swinging: `power` 0...1.
        case winding(power: Double)
        /// Thrown; the arena shows the flight. `distance` once known; a foul went into the crowd.
        case thrown(distance: Double?, foul: Bool)
    }

    var phase: Phase = .ready
    var attemptsLeft: Int = 3
    /// Your best throw so far.
    var best: Double?
    /// A short nudge: "That's a drop, not a throw." / "The crowd is getting old. Throw."
    var notice: String?
}

// MARK: - Arena

/// The whole arena screen for discus: top bar, the throw, Homer's caption.
/// Applies `.arenaStage()` itself; put SceneView behind it.
struct DiscusArenaScreen: View {
    let model: DiscusArenaModel
    var code: String? = nil

    var body: some View {
        DiscusArenaCanvas(model: model, code: code).arenaStage().sceneBehind()
    }
}

private struct DiscusArenaCanvas: View {
    let model: DiscusArenaModel
    let code: String?
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s4 * k) {
            HStack(spacing: Metrics.s3 * k) {
                WordmarkView(size: 22 * k)
                    .padding(.horizontal, Metrics.s4 * k)
                    .padding(.vertical, Metrics.s2 * k)
                    .paper(Palette.paper, radius: Metrics.radiusM * k, lifted: false)
                Spacer()
                Text("Discus").chip(11 * k)
                Spacer()
                if let code { Text("Join · \(code)").chip(11 * k) }
            }
            Group {
                if let champion = model.champion {
                    HStack(spacing: Metrics.s6 * k) {
                        DiscusChampion(poet: champion, best: model.board.first { $0.id == champion.id }?.best)
                        DiscusArenaView(model: model, showsThrow: false)
                    }
                } else {
                    DiscusArenaView(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let caption = model.caption {
                CaptionView(text: caption).transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, Metrics.s6 * k)
        .padding(.vertical, Metrics.s5 * k)
        .animation(Motion.slide, value: model.caption)
        .animation(Motion.slide, value: model.champion?.id)
    }
}

/// The throw and the field board, for use inside the arena canvas.
struct DiscusArenaView: View {
    let model: DiscusArenaModel
    var showsThrow: Bool = true
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(alignment: .center, spacing: Metrics.s6 * k) {
            if showsThrow {
                VStack(alignment: .leading, spacing: Metrics.s4 * k) {
                    HStack(spacing: Metrics.s3 * k) {
                        if let thrower = model.thrower {
                            Text(thrower.name).font(Typeface.display(26, on: stage, weight: 700)).foregroundStyle(Palette.cream)
                                .padding(.horizontal, Metrics.s4 * k).padding(.vertical, Metrics.s2 * k)
                                .paper(thrower.ink, radius: Metrics.radiusM * k)
                        }
                        Text("Throw \(model.attempt) of \(model.attempts)").chip(11 * k)
                        if let landing = model.landing, case .landed(false) = model.phase {
                            Text(landing.title).chip(11 * k, fill: Palette.gold, color: Palette.ink)
                                .transition(.scale(scale: 1.6).combined(with: .opacity))
                        }
                        Spacer()
                        if case .winding(let power) = model.phase { PowerGauge(power: power) }
                    }
                    DiscusThrowView(distance: model.distance, progress: progress, record: model.record,
                                    poet: model.thrower?.name, foul: isFoul, fieldHeight: 190)
                }
                .frame(maxWidth: .infinity)
                .animation(Motion.stamp, value: model.landing)
            }
            board.frame(width: 260 * k)
        }
    }

    private var progress: Double {
        switch model.phase {
        case .waiting, .winding: 0
        case .flight(let p): p
        case .landed: 1
        }
    }

    private var isFoul: Bool {
        if case .landed(let foul) = model.phase { return foul }
        return false
    }

    private var board: some View {
        let k = stage.scale
        let ranked = model.board.sorted { ($0.best ?? -1) > ($1.best ?? -1) }
        return VStack(alignment: .leading, spacing: Metrics.s3 * k) {
            Text("The field").tracked(10 * k, color: Palette.onHero2)
            ForEach(Array(ranked.enumerated()), id: \.element.id) { place, mark in
                HStack(spacing: Metrics.s3 * k) {
                    Capsule().fill(mark.poet.ink).frame(width: 4 * k, height: 22 * k)
                    Text(mark.poet.name).font(Typeface.display(19, on: stage, weight: 600)).foregroundStyle(Palette.onHero)
                    Spacer()
                    Text(mark.best.map { String(format: "%.1f m", $0) } ?? "—")
                        .font(Typeface.numeral(15 * k))
                        .foregroundStyle(place == 0 && mark.best != nil ? Palette.gold : Palette.onHero)
                }
            }
            if let record = model.record {
                Text("Record \(String(format: "%.1f", record)) m\(model.recordHolder.map { " · \($0)" } ?? "")")
                    .chip(10 * k, fill: Palette.gold, color: Palette.ink)
                    .padding(.top, Metrics.s2 * k)
            }
        }
        .padding(Metrics.s5 * k)
        .paper(Palette.hero, radius: Metrics.radiusL * k)
        .animation(Motion.slide, value: ranked.map(\.id))
    }
}

private struct DiscusChampion: View {
    let poet: PoetPlate
    var best: Double?
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s2 * k) {
            Text("The discus goes to").chip(12 * k, fill: Palette.cream, color: Palette.ink)
            Text(poet.name)
                .font(Typeface.display(80, on: stage, weight: 900))
                .foregroundStyle(Palette.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let best {
                Text(String(format: "%.1f metres", best)).font(Typeface.numeral(17 * k)).foregroundStyle(Palette.cream.opacity(0.85))
            }
        }
        .padding(.vertical, Metrics.s6 * k)
        .padding(.horizontal, Metrics.s5 * k)
        .frame(maxWidth: .infinity)
        .paper(poet.ink, radius: Metrics.radiusL * k)
    }
}

/// The wind-up: a half-moon gauge that fills as the swing builds.
private struct PowerGauge: View {
    let power: Double
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        ZStack(alignment: .bottom) {
            Circle().trim(from: 0.5, to: 1).stroke(Palette.paper2, style: StrokeStyle(lineWidth: 10 * k, lineCap: .round))
            Circle().trim(from: 0.5, to: 0.5 + 0.5 * min(1, max(0, power)))
                .stroke(power > 0.85 ? Palette.vermilion : Palette.gold, style: StrokeStyle(lineWidth: 10 * k, lineCap: .round))
            Text("\(Int(power * 100))").font(Typeface.numeral(16 * k)).foregroundStyle(Palette.ink)
        }
        .frame(width: 90 * k, height: 90 * k)
        .padding(.bottom, -40 * k)
        .animation(.easeOut(duration: 0.08), value: power)
        .accessibilityLabel("Power \(Int(power * 100)) percent")
    }
}

// MARK: - Phone

/// The phone in discus: one big discus to hold. Thumb down to wind up, lift to throw.
///
/// Touch handling is not here: pass `DiscusHoldPad` (multiplayer's UIKit view,
/// which reports down, lift and cancel) as `holdPad`; it is laid over the discus.
/// The view reads held state from the model's phase, so it never decides a throw.
struct DiscusPhoneView<Pad: View>: View {
    let model: DiscusPhoneModel
    var onSafetyAck: (() -> Void)?
    @ViewBuilder var holdPad: () -> Pad

    var body: some View {
        VStack(spacing: Metrics.s4) {
            if model.phase == .safety {
                safety
            } else {
                headlineCard
                if let notice = model.notice {
                    Text(notice)
                        .font(Typeface.text(15, weight: 600))
                        .foregroundStyle(Palette.cream)
                        .padding(.horizontal, Metrics.s4)
                        .padding(.vertical, Metrics.s3)
                        .paper(Palette.vermilion, radius: Metrics.radiusS)
                        .transition(.scale.combined(with: .opacity))
                }
                discus
                HStack(spacing: Metrics.s2) {
                    Text(model.attemptsLeft == 1 ? "Last throw" : "\(model.attemptsLeft) throws left").chip(10)
                    if let best = model.best { Text(String(format: "Your best · %.1f m", best)).chip(10) }
                }
            }
        }
        .animation(Motion.stamp, value: isWinding)
        .animation(Motion.slide, value: model.notice)
        .sensoryFeedback(.impact(weight: .heavy), trigger: isWinding)
    }

    private var safety: some View {
        VStack(alignment: .leading, spacing: Metrics.s4) {
            Text("Before you throw").tracked(10, color: Palette.accent)
            Text("Hold your phone tight.")
                .font(Typeface.display(30))
                .foregroundStyle(Palette.ink)
            Text("Your thumb is the release: lift it to throw. Never let go of the phone. Clear some space.")
                .font(Typeface.text(16))
                .foregroundStyle(Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)
            if let onSafetyAck {
                Button(action: onSafetyAck) { ArrowLabel(title: "Got it") }.buttonStyle(.homer).padding(.top, Metrics.s2)
            }
        }
        .padding(Metrics.s5)
        .paper()
        .padding(.top, Metrics.s6)
    }

    private var headlineCard: some View {
        VStack(spacing: Metrics.s2) {
            Text(headline)
                .font(Typeface.display(30))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(instruction)
                .font(Typeface.text(14))
                .foregroundStyle(Palette.ink2)
                .multilineTextAlignment(.center)
        }
        .padding(Metrics.s5)
        .frame(maxWidth: .infinity)
        .paper()
    }

    private var discus: some View {
        ZStack {
            if case .winding(let power) = model.phase {
                Circle()
                    .trim(from: 0, to: min(1, max(0, power)))
                    .stroke(power > 0.85 ? Palette.vermilion : Palette.gold, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 270, height: 270)
                    .animation(.easeOut(duration: 0.08), value: power)
            }
            DiscusShape(ink: Palette.paper, accent: canThrow ? Palette.accent : Palette.ink3)
                .frame(width: 230, height: 230)
                .scaleEffect(isWinding ? 0.94 : 1)
                .shadow(color: Palette.ink.opacity(0.25), radius: isWinding ? 6 : 18, y: isWinding ? 3 : 10)
            if canThrow {
                holdPad().frame(width: 290, height: 290)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Discus")
        .accessibilityHint("Hold with your thumb, swing your phone, lift your thumb to throw")
    }

    private var isWinding: Bool {
        if case .winding = model.phase { return true }
        return false
    }

    private var canThrow: Bool {
        switch model.phase {
        case .ready, .winding: true
        default: false
        }
    }

    private var headline: String {
        switch model.phase {
        case .safety: ""
        case .waiting(let thrower): thrower.map { "\($0) is throwing" } ?? "Waiting for the ring"
        case .ready: "Your throw"
        case .winding: "Swing!"
        case .thrown(_, true): "Into the crowd"
        case .thrown(let d, false): d.map { String(format: "%.1f metres", $0) } ?? "Watch the arena"
        }
    }

    private var instruction: String {
        switch model.phase {
        case .safety: ""
        case .waiting: "Your turn is coming. Keep the phone in your hand."
        case .ready: "Hold the discus with your thumb, swing your arm, and lift your thumb to let it fly. Never let go of the phone."
        case .winding: "Lift your thumb to release."
        case .thrown(_, true): "A foul. It doesn't count."
        case .thrown: "The arena shows the throw."
        }
    }
}

extension DiscusPhoneView where Pad == EmptyView {
    /// For previews and the gallery: no touch handling.
    init(model: DiscusPhoneModel, onSafetyAck: (() -> Void)? = nil) {
        self.init(model: model, onSafetyAck: onSafetyAck) { EmptyView() }
    }
}
