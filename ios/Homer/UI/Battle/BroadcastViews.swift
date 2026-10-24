import CoreImage.CIFilterBuiltins
import SwiftUI

// Battle mode is a title-fight broadcast set in cut paper: big type, solid
// slabs of seat color, entrances that land. Props in, no logic.

/// One poet as the broadcast shows them.
struct PoetPlate: Identifiable, Equatable {
    var id: String
    var name: String
    var epithet: String
    var seat: Int
    var total: Int = 0
}

extension PoetPlate {
    var ink: Color { Palette.seats[seat % Palette.seats.count] }
    var fullName: String { epithet.isEmpty ? name : "\(name), \(epithet)" }
}

// MARK: - Entrance

/// "Enter Matus, Breaker of Deadlines!" A title-card slam: the slab of the
/// poet's seat color accelerates in and hits, the name stamps down, the epithet
/// slaps on like tape, and cut-paper shards fly off the impact.
struct EntranceView: View {
    let poet: PoetPlate
    /// "Enter" for the lobby entrance; "Up next" when a poet steps up.
    var label: String = "Enter"
    /// Fired once, on the frame the slab hits: the slam sound, the screen shake.
    var onImpact: (() -> Void)? = nil

    /// Seconds from appearing to the hit.
    static let impact = 0.2

    @State private var slabIn = false
    @State private var hit = false
    @State private var taped = false
    @Environment(\.stage) private var stage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let k = stage.scale
        VStack(alignment: .leading, spacing: Metrics.s3 * k) {
            Text(label).tracked(13 * k, color: Palette.cream.opacity(0.85))
                .opacity(hit ? 1 : 0)
            Text(poet.name)
                .font(Typeface.display(84, on: stage, weight: 800))
                .foregroundStyle(Palette.cream)
                .sturdy(84)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .scaleEffect(hit ? 1 : 1.5, anchor: .leading)
                .opacity(hit ? 1 : 0)
            if !poet.epithet.isEmpty {
                Text(poet.epithet)
                    .font(Typeface.display(32, on: stage, weight: 600, italic: true))
                    .foregroundStyle(Palette.ink)
                    .sturdy(32)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Metrics.s4 * k)
                    .padding(.vertical, Metrics.s2 * k)
                    .background(Palette.cream, in: Rectangle())
                    .rotationEffect(.degrees(taped ? -1.5 : -7), anchor: .leading)
                    .scaleEffect(taped ? 1 : 1.6, anchor: .leading)
                    .opacity(taped ? 1 : 0)
            }
        }
        .padding(.vertical, Metrics.s6 * k)
        .padding(.leading, Metrics.s7 * k)
        .padding(.trailing, Metrics.s8 * k)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .trailing) {
            ShardBurst(inks: [poet.ink, Palette.cream, Palette.gold, Palette.ink], trigger: hit, k: k)
        }
        .paper(poet.ink, radius: 0)
        // A second slab in ink, a step behind: layered cut paper.
        .background(Palette.ink.offset(x: 0, y: 9 * k).opacity(slabIn ? 1 : 0))
        .rotationEffect(.degrees(slabIn ? 0 : -2.5), anchor: .trailing)
        .offset(x: slabIn ? 0 : -1700)
        .task {
            guard !hit else { return }
            if reduceMotion {
                slabIn = true; hit = true; taped = true
                onImpact?()
                return
            }
            // Accelerate into the hit, like a thrown slab, not a slide.
            withAnimation(.timingCurve(0.6, 0, 1, 0.6, duration: Self.impact)) { slabIn = true }
            try? await Task.sleep(for: .seconds(Self.impact))
            onImpact?()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { hit = true }
            try? await Task.sleep(for: .seconds(0.16))
            withAnimation(.spring(response: 0.24, dampingFraction: 0.48)) { taped = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(poet.fullName)")
    }
}

/// Cut-paper shards thrown off an impact point (the view's trailing edge),
/// then falling and fading. Flat triangles, no glow.
struct ShardBurst: View {
    let inks: [Color]
    let trigger: Bool
    let k: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<14, id: \.self) { i in
                // Deterministic per shard, so a re-render never reshuffles them.
                let a = Double(i) * 2.39996 + 0.4
                let reach = (90 + Double((i * 37) % 120)) * k
                let dx = cos(a) * reach * 1.3 + 40 * k
                let dy = sin(a) * reach * 0.8
                let size = (10 + Double((i * 13) % 14)) * k
                Shard()
                    .fill(inks[i % inks.count])
                    .frame(width: size, height: size * 0.8)
                    .keyframeAnimator(initialValue: ShardState(), trigger: trigger) { shard, v in
                        shard
                            .rotationEffect(.degrees(v.spin))
                            .offset(x: v.x, y: v.y)
                            .opacity(v.opacity)
                    } keyframes: { _ in
                        KeyframeTrack(\.x) {
                            MoveKeyframe(0)
                            CubicKeyframe(dx, duration: 0.55)
                        }
                        KeyframeTrack(\.y) {
                            MoveKeyframe(0)
                            CubicKeyframe(dy, duration: 0.3)
                            CubicKeyframe(dy + 140 * k, duration: 0.5)
                        }
                        KeyframeTrack(\.spin) {
                            MoveKeyframe(0)
                            LinearKeyframe(Double(i % 2 == 0 ? 280 : -320), duration: 0.8)
                        }
                        KeyframeTrack(\.opacity) {
                            MoveKeyframe(trigger ? 1 : 0)
                            LinearKeyframe(1, duration: 0.45)
                            LinearKeyframe(0, duration: 0.35)
                        }
                    }
            }
        }
        .frame(width: 1, height: 1)
        .allowsHitTesting(false)
    }

    struct ShardState {
        var x = 0.0
        var y = 0.0
        var spin = 0.0
        var opacity = 0.0
    }

    private struct Shard: Shape {
        func path(in r: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: r.minX, y: r.maxY))
                p.addLine(to: CGPoint(x: r.midX * 1.2, y: r.minY))
                p.addLine(to: CGPoint(x: r.maxX, y: r.maxY * 0.85))
                p.closeSubpath()
            }
        }
    }
}

// MARK: - Round title

struct RoundTitleView: View {
    let round: Int
    let rounds: Int
    let theme: String
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s4 * k) {
            Text("Round \(roman(round)) of \(roman(rounds))").chip(13 * k)
            Text(theme.isEmpty ? "Homer is choosing the theme…" : theme)
                .font(Typeface.display(54, on: stage, weight: theme.isEmpty ? 400 : 900, italic: theme.isEmpty))
                .displayLeading(54 * k, 1.05)
                .foregroundStyle(theme.isEmpty ? Palette.ink3 : Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, Metrics.s6 * k)
                .padding(.vertical, Metrics.s5 * k)
                .paper(radius: Metrics.radiusL * k)
        }
        .padding(.horizontal, Metrics.s5 * k)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Theme cards

/// Demo mode: three theme cards on the arena; the judges tap one.
struct ThemeCardsView: View {
    let themes: [String]
    var selected: Int? = nil
    var onPick: ((Int) -> Void)? = nil
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(spacing: Metrics.s4 * k) {
            ForEach(Array(themes.enumerated()), id: \.offset) { i, theme in
                let isPicked = selected == i
                Button { onPick?(i) } label: {
                    VStack(alignment: .leading, spacing: Metrics.s4 * k) {
                        Text(roman(i + 1))
                            .font(Typeface.display(40, on: stage, weight: 500))
                            .foregroundStyle(isPicked ? Palette.onHero2 : Palette.accent)
                        Spacer(minLength: 0)
                        Text(theme)
                            .font(Typeface.display(25, on: stage))
                            .displayLeading(25 * k, 1.12)
                            .foregroundStyle(isPicked ? Palette.onHero : Palette.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Metrics.s5 * k)
                    .frame(maxWidth: 300 * k, minHeight: 220 * k, alignment: .topLeading)
                    .paper(isPicked ? Palette.hero : Palette.paper, radius: Metrics.radiusL * k)
                }
                .buttonStyle(.plain)
                .scaleEffect(isPicked ? 1.05 : (selected == nil ? 1 : 0.94))
                .opacity(selected == nil || isPicked ? 1 : 0.45)
                .offset(y: isPicked ? -12 * k : 0)
            }
        }
        .animation(Motion.stamp, value: selected)
    }
}

// MARK: - Scoreboard

/// The standings, broadcast style. The poet on the mic is marked live.
struct ScoreboardView: View {
    let poets: [PoetPlate]
    var round: Int = 1
    var rounds: Int = 3
    var liveId: String? = nil
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        let ranked = poets.sorted { $0.total > $1.total || ($0.total == $1.total && $0.seat < $1.seat) }
        VStack(alignment: .leading, spacing: Metrics.s3 * k) {
            Text("The Agon · Round \(roman(round)) of \(roman(rounds))").tracked(10 * k, color: Palette.cream.opacity(0.7))
            ForEach(Array(ranked.enumerated()), id: \.element.id) { place, poet in
                HStack(spacing: Metrics.s3 * k) {
                    Rectangle().fill(poet.ink).frame(width: 6 * k)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: Metrics.s2 * k) {
                            Text(poet.name).font(Typeface.display(23, on: stage, weight: 700)).foregroundStyle(Palette.cream).sturdy(23)
                            if poet.id == liveId { LiveDot(size: 8 * k) }
                        }
                        if !poet.epithet.isEmpty {
                            Text(poet.epithet)
                                .font(Typeface.display(14, on: stage, weight: 500, italic: true))
                                .sturdy(14)
                                .foregroundStyle(Palette.cream.opacity(0.65))
                        }
                    }
                    Spacer(minLength: Metrics.s4 * k)
                    Text("\(poet.total)")
                        .font(Typeface.display(34, on: stage, weight: 900))
                        .foregroundStyle(place == 0 && poet.total > 0 ? Palette.gold : Palette.paper)
                        .contentTransition(.numericText(value: Double(poet.total)))
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Metrics.s5 * k)
        .frame(maxWidth: 420 * k)
        .paper(Palette.ink, radius: Metrics.radiusL * k)
        .animation(Motion.slide, value: ranked.map(\.id))
        .animation(Motion.stamp, value: poets.map(\.total))
    }
}

// MARK: - Join

/// The lobby card: scan the QR code or type the room code.
struct JoinCardView: View {
    let code: String
    let url: String
    /// Smaller, for a side column (the hall).
    var compact: Bool = false
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale * (compact ? 0.62 : 1)
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Metrics.s6 * k) { qr(k); words(k) }
            VStack(alignment: .leading, spacing: Metrics.s5 * k) { qr(k); words(k) }
        }
        .padding(Metrics.s6 * k)
        .paper(radius: Metrics.radiusL * k)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Join with code \(code.map(String.init).joined(separator: " "))")
    }
}

extension JoinCardView {
    fileprivate func qr(_ k: CGFloat) -> some View {
        QRImage(text: url).frame(width: 168 * k, height: 168 * k)
    }

    fileprivate func words(_ k: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Metrics.s2 * k) {
            Text("Join the Agon").tracked(12 * k, color: Palette.ink2)
            Text(code)
                // Scaled by `k` (smaller when compact), with the arena's distance optical size.
                .font(Typeface.display(72 * k, weight: 500, opticalSize: stage.isArena ? 72 * k / stage.scale * 0.45 : nil))
                .tracking(8 * k)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
                .fixedSize()
            Text("Scan, or type the code in Homer.")
                .font(Typeface.text(15 * k, weight: 500))
                .foregroundStyle(Palette.ink2)
        }
    }
}

/// A QR code in ink on paper, not black on white.
struct QRImage: View {
    let text: String

    var body: some View {
        if let image = Self.make(text) {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
        } else {
            Rectangle().fill(Palette.paper2)
        }
    }

    private static func make(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        // Ink modules on paper, not black on white.
        let colored = output.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(red: 0x30 / 255, green: 0x2A / 255, blue: 0x29 / 255),
            "inputColor1": CIColor(red: 0xFF / 255, green: 0xFC / 255, blue: 0xF7 / 255),
        ])
        guard let cg = CIContext().createCGImage(colored, from: colored.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Champion and rematch

struct ChampionView: View {
    let poet: PoetPlate
    var onRematch: (() -> Void)? = nil
    var onNewPoets: (() -> Void)? = nil
    /// Fired once, on the frame the crown lands: the crown cue.
    var onCrown: (() -> Void)? = nil

    @State private var crowned = false
    @State private var named = false
    @Environment(\.stage) private var stage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s5 * k) {
            // The crown plate: the champion's seat color, a gold laurel landing on the name.
            VStack(spacing: Metrics.s2 * k) {
                LaurelCrown()
                    .fill(crownInk)
                    .frame(width: 250 * k, height: 104 * k)
                    .scaleEffect(crowned ? 1 : 1.9)
                    .offset(y: crowned ? 0 : -260 * k)
                    .rotationEffect(.degrees(crowned ? 0 : -8))
                    .opacity(crowned ? 1 : 0)
                    .background { ShardBurst(inks: [Palette.gold, Palette.cream, poet.ink], trigger: crowned, k: k) }
                Text("Champion of the Agon").chip(12 * k, fill: Palette.cream, color: Palette.ink)
                Text(poet.name)
                    .font(Typeface.display(96, on: stage, weight: 800))
                    .foregroundStyle(Palette.cream)
                    .sturdy(96)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .scaleEffect(named ? 1 : 1.35)
                    .opacity(named ? 1 : 0)
                if !poet.epithet.isEmpty {
                    Text(poet.epithet)
                        .font(Typeface.display(30, on: stage, weight: 600, italic: true))
                        .foregroundStyle(Palette.cream)
                        .sturdy(30)
                        .opacity(named ? 1 : 0)
                }
                Text("\(poet.total) points")
                    .font(Typeface.numeral(17 * k, weight: 650))
                    .foregroundStyle(Palette.cream.opacity(0.8))
            }
            .padding(.vertical, Metrics.s6 * k)
            .padding(.horizontal, Metrics.s5 * k)
            .frame(maxWidth: .infinity)
            .paper(poet.ink, radius: Metrics.radiusL * k)
            if onRematch != nil || onNewPoets != nil {
                HStack(spacing: Metrics.s3 * k) {
                    if let onRematch { Button("Rematch", action: onRematch).buttonStyle(.homer) }
                    if let onNewPoets { Button("New poets", action: onNewPoets).buttonStyle(.homer(.secondary)) }
                }
            }
        }
        .padding(.horizontal, Metrics.s4 * k)
        .task {
            guard !crowned else { return }
            if reduceMotion {
                named = true; crowned = true
                onCrown?()
                return
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { named = true }
            try? await Task.sleep(for: .seconds(0.45))
            // The crown drops and hits.
            withAnimation(.timingCurve(0.55, 0, 1, 0.5, duration: 0.24)) { crowned = true }
            try? await Task.sleep(for: .seconds(0.24))
            onCrown?()
        }
    }

    /// Gold, unless the plate is already gold-ish (a mustard seat): then cream, so the crown never vanishes.
    private var crownInk: Color {
        func luma(_ c: Color) -> CGFloat {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            UIColor(c).getRed(&r, green: &g, blue: &b, alpha: nil)
            return 0.2126 * r + 0.7152 * g + 0.0722 * b
        }
        return abs(luma(Palette.gold) - luma(poet.ink)) < 0.18 ? Palette.cream : Palette.gold
    }
}

/// A laurel crown in cut paper: two branches of leaves curving up from a tie
/// at the bottom, open at the top.
struct LaurelCrown: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let base = CGPoint(x: r.midX, y: r.maxY - r.height * 0.06)
        for side in [-1.0, 1.0] {
            // Leaves along a quarter-ellipse from the tie up to the tip.
            for i in 0..<7 {
                let t = Double(i) / 6
                let a = .pi / 2 + side * t * .pi * 0.5
                let cx = r.midX + side * (r.width * 0.46) * sin(t * .pi / 2)
                let cy = base.y - (r.height * 0.86) * (1 - cos(t * .pi / 2)) - r.height * 0.04
                let len = r.height * (0.34 - 0.08 * t)
                let wid = len * 0.42
                let tilt = a + side * 0.9
                var leaf = Path(ellipseIn: CGRect(x: -len / 2, y: -wid / 2, width: len, height: wid))
                leaf = leaf.applying(CGAffineTransform(translationX: len * 0.45, y: 0))
                    .applying(CGAffineTransform(rotationAngle: tilt - .pi))
                    .applying(CGAffineTransform(translationX: cx, y: cy))
                p.addPath(leaf)
            }
        }
        // The tie.
        p.addEllipse(in: CGRect(x: base.x - r.height * 0.07, y: base.y - r.height * 0.07, width: r.height * 0.14, height: r.height * 0.14))
        return p
    }
}

/// Cut-paper confetti falling across the whole arena for a few seconds: flat
/// rectangles in the given inks, fluttering as they turn. Matte, never glitter.
struct ConfettiFall: View {
    let inks: [Color]
    var seconds: Double = 6
    @State private var start = Date()
    @Environment(\.stage) private var stage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation(paused: Date().timeIntervalSince(start) > seconds + 3)) { context in
                Canvas { ctx, size in
                    let t = context.date.timeIntervalSince(start)
                    let k = stage.scale
                    for i in 0..<70 {
                        let seed = Double(i)
                        let delay = (seed * 0.6180339).truncatingRemainder(dividingBy: 1) * seconds * 0.6
                        let age = t - delay
                        guard age > 0 else { continue }
                        let fall = size.height * (0.18 + 0.1 * (seed * 0.37).truncatingRemainder(dividingBy: 1))
                        let y = -30 + age * fall
                        guard y < size.height + 30 else { continue }
                        let x = size.width * (seed * 0.7548776).truncatingRemainder(dividingBy: 1) + sin(age * 2.2 + seed) * 26 * k
                        let w = (10.0 + Double(i % 4) * 3) * k
                        let flip = cos(age * (3 + Double(i % 5)) + seed)
                        var piece = ctx
                        piece.translateBy(x: x, y: y)
                        piece.rotate(by: .radians(age * (i % 2 == 0 ? 2.4 : -2.0) + seed))
                        piece.scaleBy(x: max(0.08, abs(flip)), y: 1)
                        piece.opacity = min(1, max(0, (seconds + 2 - age) / 2))
                        piece.fill(Path(CGRect(x: -w / 2, y: -w * 0.32, width: w, height: w * 0.64)),
                                   with: .color(inks[i % inks.count]))
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

#Preview("Broadcast") {
    let poets = [
        PoetPlate(id: "a", name: "Matus", epithet: "Breaker of Deadlines", seat: 0, total: 74),
        PoetPlate(id: "b", name: "Sunya", epithet: "Storm-Throated", seat: 1, total: 81),
    ]
    return ZStack {
        Palette.wine.ignoresSafeArea()
        VStack(spacing: 24) {
            EntranceView(poet: poets[0])
            ScoreboardView(poets: poets, round: 2, liveId: "a")
            ThemeCardsView(themes: ["A ship that never came home", "The last lamp in the city", "A debt"], selected: 1)
                .padding(.horizontal)
        }
    }
}
