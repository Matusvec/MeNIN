import SwiftUI

/// Buttons, after the concept's "Resume": a 12-radius slab, Inter semibold,
/// an optional arrow. Primary is wine on the page; `.cream` sits on wine
/// cards; secondary is paper with a hairline. They press down, never glow.
struct HomerButtonStyle: ButtonStyle {
    enum Kind { case primary, cream, secondary, quiet }

    var kind: Kind = .primary
    @Environment(\.stage) private var stage

    func makeBody(configuration: Configuration) -> some View {
        let k = stage.scale
        configuration.label
            .font(Typeface.text(15 * k, weight: 600))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(foreground)
            .padding(.horizontal, 18 * k)
            .frame(minHeight: 44 * k)
            .background {
                if kind != .quiet {
                    RoundedRectangle(cornerRadius: Metrics.radiusS * k, style: .continuous)
                        .fill(fill)
                        .overlay {
                            if kind == .secondary {
                                RoundedRectangle(cornerRadius: Metrics.radiusS * k, style: .continuous)
                                    .strokeBorder(Palette.line, lineWidth: 1)
                            }
                        }
                }
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.stamp, value: configuration.isPressed)
    }

    private var fill: Color {
        switch kind {
        case .primary: Palette.hero
        case .cream: Palette.onHero
        case .secondary: Palette.paper
        case .quiet: .clear
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary: Palette.onHero
        case .cream, .quiet: Palette.hero
        case .secondary: Palette.ink
        }
    }
}

/// A button label with the concept's trailing arrow.
struct ArrowLabel: View {
    let title: String
    @Environment(\.stage) private var stage

    var body: some View {
        HStack(spacing: 9 * stage.scale) {
            Text(title)
            Image("icon-arrow-right").renderingMode(.template).resizable()
                .frame(width: 16 * stage.scale, height: 16 * stage.scale)
        }
    }
}

extension ButtonStyle where Self == HomerButtonStyle {
    static var homer: HomerButtonStyle { HomerButtonStyle() }
    static func homer(_ kind: HomerButtonStyle.Kind) -> HomerButtonStyle { HomerButtonStyle(kind: kind) }
}

/// Roman numerals for rounds, themes and ranks: I, II, III.
func roman(_ n: Int) -> String {
    let table: [(Int, String)] = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    var n = n
    var out = ""
    for (value, glyph) in table {
        while n >= value {
            out += glyph
            n -= value
        }
    }
    return out
}
