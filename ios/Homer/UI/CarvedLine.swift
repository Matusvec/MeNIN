import SwiftUI

/// The best line of the round, carved in gold across the arena: gold letters
/// cut into a wine tablet (an inner shadow, like letterpress). The carving runs
/// left to right as `progress` goes 0...1.
struct CarvedLineView: View {
    let line: String
    var poet: String? = nil
    var progress: Double = 1
    /// Fired once, when the chisel starts cutting: the carve cue.
    var onCarve: (() -> Void)? = nil

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        let p = min(1, max(0, progress))
        VStack(spacing: Metrics.s4 * k) {
            Text("Carved")
                .tracked(12 * k, color: Palette.gold)
            Text(line)
                .font(Typeface.display(54 * k, weight: 700, italic: true))
                .displayLeading(54 * k, 1.06)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Palette.gold.shadow(.inner(color: .black.opacity(0.85), radius: 1.4 * k, x: 1.4 * k, y: 2.4 * k)))
                .mask(alignment: .leading) { chisel(p) }
                .overlay { if p > 0 && p < 1 { ChiselFront(progress: p, k: k) } }
            if let poet {
                Text("— \(poet)")
                    .font(Typeface.display(19 * k, italic: true))
                    .foregroundStyle(Palette.onHero2)
                    .opacity(p >= 1 ? 1 : 0)
            }
        }
        // The tablet: a slab of wine the line is cut into, so it holds on any scene.
        .padding(.horizontal, Metrics.s6 * k)
        .padding(.vertical, Metrics.s7 * k)
        .frame(maxWidth: 980 * k)
        .paper(Palette.hero, radius: Metrics.radiusL * k)
        .animation(Motion.fade, value: p >= 1)
        .onChange(of: p > 0) { was, now in
            if !was && now { onCarve?() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Best line: \(line)\(poet.map { ", by \($0)" } ?? "")")
    }

    /// The cut so far: a hard edge sweeping across the line.
    private func chisel(_ p: Double) -> some View {
        GeometryReader { geo in
            LinearGradient(stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: max(0, p - 0.01)),
                .init(color: .clear, location: min(1, p + 0.01)),
            ], startPoint: .leading, endPoint: .trailing)
            .frame(width: geo.size.width * 1.02)
        }
    }
}

/// The chisel at work: a gold bar at the cutting edge and chips of gold paper
/// falling off it. Driven by time, so the chips keep falling while Homer reads.
private struct ChiselFront: View {
    let progress: Double
    let k: CGFloat

    var body: some View {
        GeometryReader { geo in
            let x = geo.size.width * progress
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    // The bar.
                    ctx.fill(Path(CGRect(x: x - 1.5 * k, y: -6 * k, width: 3 * k, height: size.height + 12 * k)),
                             with: .color(Palette.gold))
                    // Chips: each one falls for 0.7 s from the edge, then restarts.
                    for i in 0..<9 {
                        let life = 0.7
                        let phase = (t + Double(i) * 0.137).truncatingRemainder(dividingBy: life) / life
                        let seed = Double(i) * 1.91
                        let cx = x + (sin(seed) * 10 + phase * (8 + Double(i % 3) * 6)) * k
                        let cy = size.height * (0.15 + 0.7 * (Double((i * 5) % 9) / 9)) + phase * phase * 70 * k
                        let s = (3 + Double(i % 3)) * k
                        var chip = Path()
                        chip.move(to: CGPoint(x: cx, y: cy))
                        chip.addLine(to: CGPoint(x: cx + s, y: cy + s * 0.4))
                        chip.addLine(to: CGPoint(x: cx + s * 0.3, y: cy + s))
                        chip.closeSubpath()
                        ctx.opacity = 1 - phase
                        ctx.fill(chip, with: .color(i % 4 == 0 ? Palette.cream : Palette.gold))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    CarvedLineView(line: "The whale-road swallowed his sails", poet: "Matus, round two", progress: 0.7)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sea)
}
