import SwiftUI

/// The live transcript: what Homer heard, always visible while a mic is open.
/// The poet's words sit on wine (Homer's captions sit on paper), so they read
/// on any scene. The line being spoken is full strength; earlier lines step
/// back. Formula phrases from the hand are underlined in gold.
struct TranscriptView: View {
    let lines: [String]
    var listening: Bool = false
    var formulas: [String] = []
    var maxLines: Int = 4

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(alignment: .leading, spacing: Metrics.s2 * k) {
            if listening {
                HStack(spacing: Metrics.s2 * k) {
                    LiveDot(size: 8 * k)
                    Text("Homer hears").tracked(10 * k, color: Palette.onHero2)
                }
            }
            let shown = Array(lines.suffix(maxLines))
            ForEach(Array(shown.enumerated()), id: \.offset) { i, line in
                let current = i == shown.count - 1
                Text(marked(line))
                    .font(Typeface.display((current ? 25 : 19) * k))
                    .displayLeading((current ? 25 : 19) * k, 1.15)
                    .foregroundStyle(current ? Palette.onHero : Palette.onHero2)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Metrics.s5 * k)
        .padding(.vertical, Metrics.s4 * k)
        .paper(Palette.hero, radius: Metrics.radiusL * k)
        .animation(Motion.slide, value: lines)
        .accessibilityElement(children: .combine)
    }

    private func marked(_ line: String) -> AttributedString {
        var a = AttributedString(line)
        let lower = line.lowercased()
        for phrase in formulas where !phrase.isEmpty {
            var from = lower.startIndex
            while let r = lower.range(of: phrase.lowercased(), range: from..<lower.endIndex) {
                if let lo = AttributedString.Index(r.lowerBound, within: a), let hi = AttributedString.Index(r.upperBound, within: a) {
                    a[lo..<hi].underlineStyle = .single
                    a[lo..<hi].underlineColor = UIColor(Palette.gold)
                    a[lo..<hi].foregroundColor = Palette.gold
                }
                from = r.upperBound
            }
        }
        return a
    }
}

/// The "live" mark: a vermilion dot that breathes while the mic is open.
struct LiveDot: View {
    var size: CGFloat = 8
    @State private var on = false

    var body: some View {
        Circle()
            .fill(Palette.vermilion)
            .frame(width: size, height: size)
            .scaleEffect(on ? 1 : 0.7)
            .opacity(on ? 1 : 0.6)
            .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever()) { on = true } }
    }
}

#Preview {
    TranscriptView(lines: ["Wine-dark sea took my brother's ship", "the whale-road swallowed his sails"],
                   listening: true, formulas: ["the whale-road", "wine-dark sea"])
        .padding()
        .background(Palette.sea)
}
