import SwiftUI

// The Stadion: the footrace. Everyone pumps their arms with the phone in hand
// and races live on the big screen. The phone is the runner's own view, painted
// like black-figure pottery: terracotta ground, black figures, meander bands.

/// The runner's phone. Props in; the iOS lead's race session fills it.
struct RunModel: Equatable {
    enum Phase: Equatable {
        /// Before the start: an optional line ("Waiting for 2 more runners").
        case waiting(String?)
        /// 3, 2, 1, then 0 for GO.
        case countdown(Int)
        case running
        case finished(place: Int, of: Int, seconds: Double?)
    }

    var phase: Phase = .waiting(nil)
    var me: PoetPlate?
    /// How hard you're pumping right now, 0...1.
    var speed: Double = 0
    /// How far along the track, 0...1.
    var progress: Double = 0
    /// Your place right now, while running.
    var place: Int?
    var runners: Int = 0
}

struct RunView: View {
    let model: RunModel
    var onBack: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            StadionPalette.clay.ignoresSafeArea()
            VStack(spacing: 0) {
                MeanderBand().stroke(StadionPalette.figure, lineWidth: 2.5).frame(height: 14).padding(.horizontal, 6)
                header
                Spacer(minLength: 0)
                stage
                Spacer(minLength: 0)
                MeanderBand().stroke(StadionPalette.figure, lineWidth: 2.5).frame(height: 14).padding(.horizontal, 6)
            }
            .padding(.vertical, Metrics.s2)
        }
        .animation(Motion.stamp, value: phaseKey)
    }

    private var phaseKey: String {
        switch model.phase {
        case .waiting: "wait"
        case .countdown(let n): "count\(n)"
        case .running: "run"
        case .finished: "done"
        }
    }

    private var header: some View {
        HStack(spacing: Metrics.s3) {
            if let onBack { BackButton(action: onBack) }
            VStack(alignment: .leading, spacing: 2) {
                Text("Stadion").tracked(10, color: StadionPalette.figure.opacity(0.75))
                Text(model.me.map { "\($0.name)'s race" } ?? "The footrace")
                    .font(Typeface.display(22, weight: 600))
                    .foregroundStyle(StadionPalette.figure)
            }
            Spacer(minLength: 0)
            if case .running = model.phase, let place = model.place, model.runners > 0 {
                Text("\(roman(place)) of \(roman(model.runners))")
                    .font(Typeface.display(20, weight: 700))
                    .foregroundStyle(StadionPalette.figure)
                    .padding(.horizontal, Metrics.s3)
                    .padding(.vertical, Metrics.s1)
                    .background(StadionPalette.slip, in: Capsule())
                    .overlay(Capsule().strokeBorder(StadionPalette.figure, lineWidth: 2))
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, Metrics.s4)
        .padding(.vertical, Metrics.s3)
    }

    @ViewBuilder
    private var stage: some View {
        switch model.phase {
        case .waiting(let line):
            VStack(spacing: Metrics.s4) {
                BlackFigureRunner(stride: 0).frame(width: 150, height: 180)
                Text("Get set")
                    .font(Typeface.display(44, weight: 800))
                    .foregroundStyle(StadionPalette.figure)
                Text(line ?? "Hold your phone tight. When it says GO, pump your arms like you're sprinting.")
                    .font(Typeface.text(16, weight: 600))
                    .foregroundStyle(StadionPalette.figure.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.s6)
            }

        case .countdown(let n):
            // Cream numerals with a black offset, like a painted inscription.
            Text(n > 0 ? "\(n)" : "GO")
                .font(Typeface.display(n > 0 ? 220 : 160, weight: 900))
                .foregroundStyle(StadionPalette.slip)
                .shadow(color: StadionPalette.figure, radius: 0, x: 8, y: 8)
                .id(n)
                .transition(.scale(scale: 1.6).combined(with: .opacity))

        case .running:
            VStack(spacing: Metrics.s5) {
                Text("Pump your arms!")
                    .font(Typeface.display(40, weight: 900))
                    .foregroundStyle(StadionPalette.figure)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, Metrics.s4)
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
                    // The stride steps faster the harder you pump.
                    let t = context.date.timeIntervalSinceReferenceDate
                    let period = 0.62 - 0.42 * model.speed
                    let frame = Int(t / max(period / 2, 0.05)) % 2
                    BlackFigureRunner(stride: model.speed > 0.05 ? frame : 0)
                        .frame(width: 170, height: 204)
                }
                SpeedMeter(speed: model.speed)
                    .frame(height: 30)
                    .padding(.horizontal, Metrics.s6)
                TrackLine(progress: model.progress)
                    .frame(height: 34)
                    .padding(.horizontal, Metrics.s6)
            }

        case .finished(let place, let of, let seconds):
            VStack(spacing: Metrics.s3) {
                Text("You placed").tracked(12, color: StadionPalette.figure.opacity(0.8))
                Text(roman(place))
                    .font(Typeface.display(140, weight: 900))
                    .foregroundStyle(place == 1 ? StadionPalette.gold : StadionPalette.slip)
                    .shadow(color: StadionPalette.figure, radius: 0, x: 7, y: 7)
                Text("of \(of)\(seconds.map { String(format: " · %.2f s", $0) } ?? "")")
                    .font(Typeface.text(18, weight: 600))
                    .foregroundStyle(StadionPalette.figure)
            }
            .transition(.scale(scale: 1.3).combined(with: .opacity))
        }
    }
}

enum StadionPalette {
    static let clay = Color(hex: 0xC96B3C)
    static let clayDeep = Color(hex: 0xB65A2F)
    static let figure = Color(hex: 0x1F1612)
    static let slip = Color(hex: 0xF1DFC4)
    static let gold = Color(hex: 0xE2BD6C)
}

/// A runner as black-figure pottery paints him: a wedge torso, heavy thighs,
/// long reaching arms, a hair knot and beard, thin incisions in the clay color.
/// `stride` 0 and 1 are the two frames of the run.
struct BlackFigureRunner: View {
    var stride: Int = 0
    var ink: Color = StadionPalette.figure
    var clay: Color = StadionPalette.clay

    private typealias Seg = (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width / 100, size.height / 120)
            let ox = (size.width - 100 * s) / 2
            let oy = (size.height - 120 * s) / 2
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
            let frames: [[Seg]] = [
                [(66, 30, 80, 40, 8), (80, 40, 89, 30, 6.5), (54, 30, 40, 40, 8), (40, 40, 30, 32, 6.5),
                 (50, 60, 70, 72, 13), (70, 72, 66, 98, 9), (66, 98, 77, 100, 6), (47, 62, 34, 80, 13), (34, 80, 14, 88, 9), (14, 88, 10, 81, 6)],
                [(54, 30, 41, 42, 8), (41, 42, 33, 33, 6.5), (66, 30, 77, 44, 8), (77, 44, 82, 56, 6.5),
                 (50, 60, 60, 82, 13), (60, 82, 54, 106, 9), (54, 106, 65, 108, 6), (47, 62, 42, 80, 13), (42, 80, 30, 100, 9), (30, 100, 24, 95, 6)],
            ]
            for (x1, y1, x2, y2, w) in frames[stride % 2] {
                var line = Path()
                line.move(to: pt(x1, y1))
                line.addLine(to: pt(x2, y2))
                ctx.stroke(line, with: .color(ink), style: StrokeStyle(lineWidth: w * s, lineCap: .round))
            }
            var torso = Path()
            torso.addLines([pt(50, 25), pt(71, 29), pt(59, 57), pt(44, 55)])
            torso.closeSubpath()
            ctx.fill(torso, with: .color(ink))
            ctx.fill(Path(ellipseIn: CGRect(x: ox + 40.5 * s, y: oy + 52 * s, width: 17 * s, height: 14 * s)), with: .color(ink))
            ctx.fill(Path(ellipseIn: CGRect(x: ox + 56.5 * s, y: oy + 7.5 * s, width: 17 * s, height: 17 * s)), with: .color(ink))
            ctx.fill(Path(ellipseIn: CGRect(x: ox + 52.5 * s, y: oy + 9 * s, width: 8 * s, height: 8 * s)), with: .color(ink))
            var beard = Path()
            beard.addLines([pt(69, 21), pt(76, 29), pt(65, 27)])
            beard.closeSubpath()
            ctx.fill(beard, with: .color(ink))
            // The incisions, scratched through to the clay.
            var chest = Path()
            chest.move(to: pt(51, 44))
            chest.addQuadCurve(to: pt(63, 44), control: pt(57, 47))
            ctx.stroke(chest, with: .color(clay), style: StrokeStyle(lineWidth: 1.2 * s, lineCap: .round))
        }
        .accessibilityHidden(true)
    }
}

/// How hard you're pumping: ten segments filling black, the last ones gold.
private struct SpeedMeter: View {
    let speed: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { i in
                let on = Double(i) < speed * 10
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(on ? (i >= 8 ? StadionPalette.gold : StadionPalette.figure) : StadionPalette.clayDeep)
                    .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).strokeBorder(StadionPalette.figure, lineWidth: 1.5))
            }
        }
        .animation(.easeOut(duration: 0.08), value: speed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Speed \(Int(speed * 100)) percent")
    }
}

/// The track in one line: start to finish, with you on it.
private struct TrackLine: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let x = w * CGFloat(min(1, max(0, progress)))
            ZStack(alignment: .leading) {
                Capsule().fill(StadionPalette.clayDeep).frame(height: 8)
                    .overlay(Capsule().strokeBorder(StadionPalette.figure, lineWidth: 1.5))
                Rectangle().fill(StadionPalette.slip).frame(width: 5, height: 26).offset(x: w - 5)
                Circle().fill(StadionPalette.figure).frame(width: 20, height: 20).offset(x: x - 10)
            }
            .frame(maxHeight: .infinity)
        }
        .animation(.linear(duration: 0.12), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(progress * 100)) percent of the track")
    }
}

// MARK: - Boxing

/// The boxer's phone: your health, theirs, and every hit felt. Props in; the
/// iOS lead's fight session fills it.
struct FightModel: Equatable {
    enum Phase: Equatable {
        case waiting(String?)
        /// 3, 2, 1, then 0 for FIGHT.
        case countdown(Int)
        case fighting
        case ko(won: Bool)
    }

    /// One hit, as the phone shows it: `landed` when you hit them, else you took it.
    struct Hit: Equatable {
        var id: Int
        var landed: Bool
        /// "JAB!", "HOOK!", "UPPERCUT!", "BODY!".
        var label: String
    }

    var phase: Phase = .waiting(nil)
    var me: PoetPlate?
    var opponent: PoetPlate?
    /// 0...1.
    var myHealth: Double = 1
    var theirHealth: Double = 1
    /// Seconds left in the bout.
    var seconds: Int?
    var hit: Hit?
}

struct FightView: View {
    let model: FightModel
    var onBack: (() -> Void)? = nil

    @State private var flashes = 0

    var body: some View {
        ZStack {
            StadionPalette.clay.ignoresSafeArea()
            VStack(spacing: Metrics.s3) {
                MeanderBand().stroke(StadionPalette.figure, lineWidth: 2.5).frame(height: 14).padding(.horizontal, 6)
                HStack(spacing: Metrics.s3) {
                    if let onBack { BackButton(action: onBack) }
                    Text("Boxing").tracked(10, color: StadionPalette.figure.opacity(0.75))
                    Spacer()
                    if let seconds = model.seconds, model.phase == .fighting {
                        Text("\(seconds)")
                            .font(Typeface.display(24, weight: 800))
                            .foregroundStyle(seconds <= 10 ? Color.white : StadionPalette.figure)
                            .frame(width: 52, height: 52)
                            .background(seconds <= 10 ? Palette.vermilion : StadionPalette.slip, in: Circle())
                            .overlay(Circle().strokeBorder(StadionPalette.figure, lineWidth: 3))
                            .contentTransition(.numericText(countsDown: true))
                    }
                }
                .padding(.horizontal, Metrics.s4)
                HStack(spacing: Metrics.s3) {
                    HealthBand(name: model.me?.name ?? "You", health: model.myHealth, seat: model.me?.ink, trailing: false)
                    HealthBand(name: model.opponent?.name ?? "Them", health: model.theirHealth, seat: model.opponent?.ink, trailing: true)
                }
                .padding(.horizontal, Metrics.s4)
                Spacer(minLength: 0)
                stage
                Spacer(minLength: 0)
                MeanderBand().stroke(StadionPalette.figure, lineWidth: 2.5).frame(height: 14).padding(.horizontal, 6)
            }
            .padding(.vertical, Metrics.s2)
            flash
        }
        .animation(Motion.stamp, value: model.phase)
        .onChange(of: model.hit?.id) { _, new in
            if new != nil { flashes += 1 }
        }
        .sensoryFeedback(trigger: model.hit?.id) { _, _ in
            guard let hit = model.hit else { return nil }
            return hit.landed ? .impact(weight: .medium) : .impact(weight: .heavy, intensity: 1)
        }
    }

    @ViewBuilder
    private var stage: some View {
        switch model.phase {
        case .waiting(let line):
            VStack(spacing: Metrics.s4) {
                Text("Fists up!")
                    .font(Typeface.display(52, weight: 900))
                    .foregroundStyle(StadionPalette.figure)
                Text(line ?? "Hold the phone like a fist. Point it at your rival and punch: the side you point to throws.")
                    .font(Typeface.text(16, weight: 600))
                    .foregroundStyle(StadionPalette.figure.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.s6)
            }
        case .countdown(let n):
            Text(n > 0 ? "\(n)" : "FIGHT")
                .font(Typeface.display(n > 0 ? 220 : 110, weight: 900))
                .foregroundStyle(StadionPalette.slip)
                .shadow(color: StadionPalette.figure, radius: 0, x: 8, y: 8)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .id(n)
                .transition(.scale(scale: 1.6).combined(with: .opacity))
        case .fighting:
            VStack(spacing: Metrics.s3) {
                Text("Fists up!")
                    .font(Typeface.display(52, weight: 900))
                    .foregroundStyle(StadionPalette.figure)
                if let hit = model.hit {
                    // The last hit, stamped: gold when you landed it, vermilion when you took it.
                    Text(hit.label)
                        .font(Typeface.display(44, weight: 900))
                        .foregroundStyle(hit.landed ? StadionPalette.gold : Palette.vermilion)
                        .shadow(color: StadionPalette.figure, radius: 0, x: 4, y: 4)
                        .id(hit.id)
                        .transition(.scale(scale: 1.8).combined(with: .opacity))
                }
            }
        case .ko(let won):
            VStack(spacing: Metrics.s3) {
                Text("KO")
                    .font(Typeface.display(160, weight: 900))
                    .foregroundStyle(won ? StadionPalette.gold : StadionPalette.slip)
                    .shadow(color: StadionPalette.figure, radius: 0, x: 8, y: 8)
                Text(won ? "You win" : "You're down")
                    .font(Typeface.display(30, weight: 700))
                    .foregroundStyle(StadionPalette.figure)
            }
            .transition(.scale(scale: 1.4).combined(with: .opacity))
        }
    }

    /// The hit flash: the whole screen takes it, gold when you land, vermilion when you're hit.
    private var flash: some View {
        let landed = model.hit?.landed ?? true
        return (landed ? StadionPalette.gold : Palette.vermilion)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .keyframeAnimator(initialValue: 0.0, trigger: flashes) { color, o in color.opacity(o) } keyframes: { _ in
                MoveKeyframe(flashes > 0 ? 0.6 : 0)
                CubicKeyframe(0, duration: 0.35)
            }
    }
}

/// Health as a vase band: a meander-framed strip of slip draining to black.
private struct HealthBand: View {
    let name: String
    let health: Double
    var seat: Color?
    /// The opponent's band drains toward the center, mirroring yours.
    var trailing: Bool

    var body: some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 4) {
            Text(name)
                .font(Typeface.display(15, weight: 700))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(seat ?? StadionPalette.figure, in: Capsule())
            GeometryReader { geo in
                let w = geo.size.width * CGFloat(min(1, max(0, health)))
                ZStack(alignment: trailing ? .trailing : .leading) {
                    Rectangle().fill(StadionPalette.figure)
                    ZStack {
                        Rectangle().fill(health < 0.3 ? Color(hex: 0xE07A4A) : StadionPalette.slip)
                        MeanderBand().stroke(StadionPalette.figure, lineWidth: 1.5).padding(.vertical, 3)
                    }
                    .frame(width: w)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).strokeBorder(StadionPalette.figure, lineWidth: 2.5))
            }
            .frame(height: 22)
            .animation(.easeOut(duration: 0.25), value: health)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) health \(Int(health * 100)) percent")
    }
}
