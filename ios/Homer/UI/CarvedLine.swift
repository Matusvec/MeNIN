import SwiftUI

/// The best line of the round, carved in gold across the arena: gold letters
/// cut into a wine tablet (an inner shadow, like letterpress). The carving runs
/// left to right as `progress` goes 0...1.
struct CarvedLineView: View {
    let line: String
    var poet: String? = nil
    var progress: Double = 1

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s4 * k) {
            Text("Carved")
                .tracked(11 * k, color: Palette.gold)
            Text(line)
                .font(Typeface.display(44 * k, weight: 700, italic: true))
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.gold.shadow(.inner(color: .black.opacity(0.8), radius: 1.2 * k, x: 1.2 * k, y: 2 * k)))
                .mask(alignment: .leading) { chisel }
            if let poet {
                Text("— \(poet)")
                    .font(Typeface.display(17 * k, italic: true))
                    .foregroundStyle(Palette.onHero2)
                    .opacity(progress >= 1 ? 1 : 0)
            }
        }
        // The tablet: a slab of wine the line is cut into, so it holds on any scene.
        .padding(.horizontal, Metrics.s5 * k)
        .padding(.vertical, Metrics.s6 * k)
        .frame(maxWidth: 860 * k)
        .paper(Palette.hero, radius: Metrics.radiusL * k)
        .padding(.horizontal, Metrics.s4 * k)
        .animation(Motion.fade, value: progress >= 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Best line: \(line)\(poet.map { ", by \($0)" } ?? "")")
    }

    /// The carving front: a hard-ish edge sweeping across the line.
    private var chisel: some View {
        GeometryReader { geo in
            let p = min(1, max(0, progress))
            LinearGradient(stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: max(0, p - 0.02)),
                .init(color: .clear, location: min(1, p + 0.02)),
            ], startPoint: .leading, endPoint: .trailing)
            .frame(width: geo.size.width * 1.04)
        }
    }
}

#Preview {
    CarvedLineView(line: "The whale-road swallowed his sails", poet: "Matus, round two", progress: 0.7)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.sea)
}
