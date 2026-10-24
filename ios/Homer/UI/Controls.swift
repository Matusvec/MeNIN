import SwiftUI

/// Buttons, after the concept's "Resume": a 12-radius slab, Inter semibold,
/// an optional arrow. Primary is wine on the page; `.cream` sits on wine
/// cards; secondary is paper with a hairline. They press down, never glow.
struct HomerButtonStyle: ButtonStyle {
    enum Kind { case primary, cream, secondary, quiet }

    var kind: Kind = .primary
    /// Full width: the one primary action in a phone's thumb zone.
    var wide: Bool = false
    @Environment(\.stage) private var stage

    func makeBody(configuration: Configuration) -> some View {
        let k = stage.scale
        configuration.label
            .font(Typeface.text(15 * k, weight: 600))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: wide ? .infinity : nil)
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
    static func homer(_ kind: HomerButtonStyle.Kind = .primary, wide: Bool) -> HomerButtonStyle { HomerButtonStyle(kind: kind, wide: wide) }
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

// MARK: - Phone scaffold

/// Every phone screen has one structure: a context band on top (back, where
/// you are, who's up), the content in the middle, and one primary action
/// pinned at the bottom in the thumb zone. The scene shows between the bands.
/// The middle gets whatever height is left; screens that must never scroll
/// (the verse) pick a leaner variant with ViewThatFits instead of shrinking type.
struct PhoneScaffold<Trailing: View, Middle: View, Action: View>: View {
    /// Small caps context: "Poetry · Round II of III".
    var eyebrow: String
    /// The big line: the theme, the question, who's up. One or two lines.
    var title: String? = nil
    var titleLines: Int = 2
    var onBack: (() -> Void)? = nil
    /// The host's latest line, as a strip under the top band (not while you speak).
    var homer: HomerLine? = nil
    var host: String = "Homer"
    /// A wait over this screen (reconnecting, finding a room, Homer warming up):
    /// a strip under the top band, while the screen stays as it was.
    var wait: WaitState? = nil
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var middle: () -> Middle
    @ViewBuilder var action: () -> Action

    var body: some View {
        VStack(spacing: Metrics.s4) {
            VStack(spacing: Metrics.s2) {
                topBand
                if let wait {
                    WaitLine(state: wait, host: host, compact: true)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if let homer {
                    HomerStrip(line: homer, host: host)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            middle()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            action()
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Metrics.s4)
        .padding(.top, Metrics.s2)
        .padding(.bottom, Metrics.s2)
        // On an iPad or the Mac it stays a phone-width column, centered.
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .animation(Motion.slide, value: homer?.text)
        .animation(Motion.slide, value: wait)
        .sceneBehind()
    }

    private var topBand: some View {
        HStack(alignment: .center, spacing: Metrics.s3) {
            if let onBack { BackButton(action: onBack) }
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow).tracked(10, color: Palette.accent).lineLimit(1)
                if let title {
                    Text(title)
                        .font(Typeface.display(20))
                        .displayLeading(20, 1.12)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(titleLines)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .padding(.leading, onBack == nil ? Metrics.s4 : Metrics.s2)
        .padding(.trailing, Metrics.s3)
        .padding(.vertical, Metrics.s3)
        .paper(radius: Metrics.radiusL)
    }
}

extension PhoneScaffold where Trailing == EmptyView {
    init(eyebrow: String, title: String? = nil, titleLines: Int = 2, onBack: (() -> Void)? = nil, homer: HomerLine? = nil,
         host: String = "Homer", wait: WaitState? = nil,
         @ViewBuilder middle: @escaping () -> Middle, @ViewBuilder action: @escaping () -> Action) {
        self.init(eyebrow: eyebrow, title: title, titleLines: titleLines, onBack: onBack, homer: homer, host: host, wait: wait,
                  trailing: { EmptyView() }, middle: middle, action: action)
    }
}

/// The way back, on every phone screen: a paper disc with a chevron, 44 pt to hit.
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("icon-arrow-right").renderingMode(.template).resizable()
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(180))
                .foregroundStyle(Palette.accent)
                .frame(width: 40, height: 40)
                .background(Palette.paper2, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .accessibilityLabel("Back")
    }
}

/// The host's line under the top band: a slim paper slab, two lines at most.
struct HomerStrip: View {
    let line: HomerLine
    var host: String = "Homer"

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.s3) {
            Text(host).tracked(9, color: line.whisper ? Palette.accent : Palette.ink2)
            Text(line.text)
                .font(Typeface.display(17, italic: true))
                .displayLeading(17, 1.18)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Metrics.s4)
        .padding(.vertical, Metrics.s3)
        .paper(Palette.paper, radius: Metrics.radiusM, lifted: false)
        .accessibilityElement(children: .combine)
    }
}
