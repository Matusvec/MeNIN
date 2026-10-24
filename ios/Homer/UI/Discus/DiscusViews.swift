import SwiftUI

// Discus: a motion minigame, no voice. On the phone you hold the discus with
// your thumb, swing, and lift your thumb to throw. On the arena the throw flies.
// multiplayer owns the motion capture (ios/Homer/Events/Discus/) and maps it
// into these models.

struct DiscusArenaModel: Equatable {
    enum Phase: Equatable {
        /// The thrower is stepping into the ring.
        case waiting
        /// Thumb down, winding up: `power` 0...1 from the swing so far.
        case winding(power: Double)
        /// Released: the flight, `progress` 0...1.
        case flight(progress: Double)
        /// Down. `distance` is final.
        case landed
    }

    var thrower: PoetPlate?
    var phase: Phase = .waiting
    /// Metres. The predicted landing during flight, final once landed.
    var distance: Double = 0
    var record: Double?
    var recordHolder: String?
    var attempt: Int = 1
    var attempts: Int = 3
    /// Best throw per poet so far.
    var board: [DiscusMark] = []
}

struct DiscusMark: Equatable, Identifiable {
    var poet: PoetPlate
    var best: Double?
    var id: String { poet.id }
}

struct DiscusPhoneModel: Equatable {
    enum Phase: Equatable {
        /// Someone else is throwing.
        case waiting(thrower: String?)
        /// Your turn: put your thumb on the discus.
        case ready
        /// Thumb down, swinging: `power` 0...1.
        case winding(power: Double)
        /// Thrown; the arena shows the flight. `distance` once known.
        case thrown(distance: Double?)
    }

    var phase: Phase = .ready
    var attemptsLeft: Int = 3
}

// MARK: - Arena

struct DiscusArenaView: View {
    let model: DiscusArenaModel
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(alignment: .center, spacing: Metrics.s6 * k) {
            VStack(alignment: .leading, spacing: Metrics.s4 * k) {
                HStack(spacing: Metrics.s3 * k) {
                    if let thrower = model.thrower {
                        Text(thrower.name).font(Typeface.display(26 * k, weight: 700)).foregroundStyle(Palette.cream)
                            .padding(.horizontal, Metrics.s4 * k).padding(.vertical, Metrics.s2 * k)
                            .paper(thrower.ink, radius: Metrics.radiusM * k)
                    }
                    Text("Throw \(model.attempt) of \(model.attempts)").chip(11 * k)
                    Spacer()
                    if case .winding(let power) = model.phase { PowerGauge(power: power) }
                }
                DiscusThrowView(distance: model.distance, progress: progress, record: model.record,
                                poet: model.thrower?.name, fieldHeight: 190)
            }
            .frame(maxWidth: .infinity)
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

    private var board: some View {
        let k = stage.scale
        let ranked = model.board.sorted { ($0.best ?? -1) > ($1.best ?? -1) }
        return VStack(alignment: .leading, spacing: Metrics.s3 * k) {
            Text("The field").tracked(10 * k, color: Palette.onHero2)
            ForEach(Array(ranked.enumerated()), id: \.element.id) { place, mark in
                HStack(spacing: Metrics.s3 * k) {
                    Capsule().fill(mark.poet.ink).frame(width: 4 * k, height: 22 * k)
                    Text(mark.poet.name).font(Typeface.display(19 * k, weight: 600)).foregroundStyle(Palette.onHero)
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
struct DiscusPhoneView: View {
    let model: DiscusPhoneModel
    /// True when the thumb goes down on the discus, false when it lifts (the release).
    var onHold: ((Bool) -> Void)?

    @State private var held = false

    var body: some View {
        VStack(spacing: Metrics.s5) {
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
                    .scaleEffect(held ? 0.94 : 1)
                    .shadow(color: Palette.ink.opacity(0.25), radius: held ? 6 : 18, y: held ? 3 : 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard canThrow, !held else { return }
                        held = true
                        onHold?(true)
                    }
                    .onEnded { _ in
                        guard held else { return }
                        held = false
                        onHold?(false)
                    }
            )
            .sensoryFeedback(.impact(weight: .heavy), trigger: held)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Discus")
            .accessibilityHint("Hold with your thumb, swing your phone, lift your thumb to throw")

            Text(model.attemptsLeft == 1 ? "Last throw" : "\(model.attemptsLeft) throws left").chip(10)
        }
        .animation(Motion.stamp, value: held)
    }

    private var canThrow: Bool {
        switch model.phase {
        case .ready, .winding: true
        default: false
        }
    }

    private var headline: String {
        switch model.phase {
        case .waiting(let thrower): thrower.map { "\($0) is throwing" } ?? "Waiting for the ring"
        case .ready: "Your throw"
        case .winding: "Swing!"
        case .thrown(let d): d.map { String(format: "%.1f metres", $0) } ?? "Watch the arena"
        }
    }

    private var instruction: String {
        switch model.phase {
        case .waiting: "Your turn is coming. Keep the phone in your hand."
        case .ready: "Hold the discus with your thumb, swing your arm, and lift your thumb to let it fly. Never let go of the phone."
        case .winding: "Lift your thumb to release."
        case .thrown: "The arena shows the throw."
        }
    }
}
