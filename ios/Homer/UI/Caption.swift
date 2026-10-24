import SwiftUI

/// A caption for everything Homer says, on the arena and the phone.
/// `spoken` (0...1) is how much of the line his voice has reached: spoken
/// words are full ink, the rest wait in faint ink, so the caption reads along.
struct CaptionView: View {
    let text: String
    var spoken: Double = 1
    var speaker: String = "Homer"
    /// The freeze rescue: Homer leans in and whispers one formula.
    var whisper: Bool = false

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(alignment: .firstTextBaseline, spacing: Metrics.s3 * k) {
            Text(speaker)
                .tracked(10 * k, color: Palette.accent)
                .fixedSize()
            Text(attributed)
                .font(Typeface.display((whisper ? 20 : 23) * k, italic: true))
                .displayLeading((whisper ? 20 : 23) * k, 1.18)
                .lineSpacing(2 * k)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.linear(duration: 0.12), value: spoken)
        }
        .padding(.horizontal, Metrics.s5 * k)
        .padding(.vertical, Metrics.s4 * k)
        .frame(maxWidth: 720 * k, alignment: .leading)
        .paper(whisper ? Palette.paper2 : Palette.paper, radius: Metrics.radiusM * k)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(speaker): \(text)")
    }

    /// Splits at a word boundary so a word never lights up half-way.
    private var attributed: AttributedString {
        let chars = Array(text)
        var cut = Int((Double(chars.count) * min(1, max(0, spoken))).rounded())
        while cut > 0, cut < chars.count, chars[cut - 1] != " " { cut += 1 }
        var said = AttributedString(String(chars[..<min(cut, chars.count)]))
        said.foregroundColor = Palette.ink
        var rest = AttributedString(String(chars[min(cut, chars.count)...]))
        rest.foregroundColor = Palette.ink.opacity(0.25)
        return said + rest
    }
}

#Preview {
    VStack(spacing: 24) {
        CaptionView(text: "Strong bones, thin blood. Your third line carried you.", spoken: 0.55)
        CaptionView(text: "The whale-road.", whisper: true)
    }
    .padding()
    .background(Palette.wine)
}
