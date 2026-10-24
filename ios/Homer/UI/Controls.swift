import SwiftUI

/// Buttons. Flat ink on paper, or paper on ink; they press down like a stamp.
struct HomerButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, quiet }

    var kind: Kind = .primary
    @Environment(\.stage) private var stage

    func makeBody(configuration: Configuration) -> some View {
        let k = stage.scale
        configuration.label
            .font(Typeface.text(17 * k, weight: 700))
            .foregroundStyle(foreground)
            .padding(.horizontal, Metrics.s6 * k)
            .padding(.vertical, Metrics.s4 * k)
            .frame(minHeight: 52 * k)
            .background {
                if kind != .quiet {
                    Capsule(style: .continuous)
                        .fill(fill)
                        .shadow(color: .black.opacity(configuration.isPressed ? 0 : 0.25), radius: 0, x: 0, y: configuration.isPressed ? 0 : 2 * k)
                }
            }
            .offset(y: configuration.isPressed ? 2 * k : 0)
            .animation(Motion.stamp, value: configuration.isPressed)
    }

    private var fill: Color {
        switch kind {
        case .primary: Palette.vermilion
        case .secondary: Palette.paper
        case .quiet: .clear
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary: Palette.paper
        case .secondary: Palette.ink
        case .quiet: Palette.paper
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
