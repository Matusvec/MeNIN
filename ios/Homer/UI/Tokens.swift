import CoreText
import SwiftUI
import UIKit

// MeNIN's design tokens, from Matus's concept art (Figma: "MeNIN user
// interface concept art", frame "Homer · Atelier"). A cream page, Bodoni Moda
// display, Inter for the interface, wine as the one strong accent. Matte:
// flat fills and hairlines, never gloss. The scene brings the color.

// MARK: - Color

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255,
                  opacity: opacity)
    }
}

enum Palette {
    // The page and its paper (Figma: #F7F3EC page, #FFFCF7 cards, #E4DCD2 hairlines).
    static let page = Color(hex: 0xF7F3EC)
    static let paper = Color(hex: 0xFFFCF7)
    static let paper2 = Color(hex: 0xF2ECE2)
    static let paper3 = Color(hex: 0xE4DCD2)
    static let line = Color(hex: 0xE4DCD2)
    /// Text and buttons laid on wine (Figma: #FFF8ED).
    static let cream = Color(hex: 0xFFF8ED)

    // Ink (Figma: #302A29 text, #82756E secondary).
    static let ink = Color(hex: 0x302A29)
    static let ink2 = Color(hex: 0x82756E)
    static let ink3 = Color(hex: 0xA69A92)

    // Wine: the accent (Figma: #682C3E, #542232 track, #DDC3C5 labels on wine).
    static let wine = Color(hex: 0x682C3E)
    static let wineDeep = Color(hex: 0x542232)
    static let wineTint = Color(hex: 0xDDC3C5)

    // Supporting inks, each with one job. Matte, pulled toward the page's warmth.
    static let gold = Color(hex: 0xC99A3E)      // hits, best lines, the hoard
    static let goldDeep = Color(hex: 0x9A7128)  // gold on the page
    static let vermilion = Color(hex: 0xC8452C) // live: the mic, the clock
    static let sea = Color(hex: 0x2D5C66)       // Homer's voice
    static let olive = Color(hex: 0x6E7A2E)     // Socrates
    static let lilac = Color(hex: 0x8A72C4)     // debate moves

    /// One ink per poet seat, so a poet keeps their color all battle.
    static let seats: [Color] = [Color(hex: 0x682C3E), Color(hex: 0x2D5C66), Color(hex: 0xC99A3E), Color(hex: 0x6E7A2E), Color(hex: 0xC8452C)]
}

// MARK: - Type

/// Bodoni Moda (variable: wght 400–900, opsz 6–96) is the voice of the legend:
/// verse, names, titles. Regular for the calm of Bard and Practice, heavy for
/// the Agon. Inter (variable: wght, opsz) for everything that works.
@MainActor
enum Typeface {
    private static var cache: [String: Font] = [:]

    /// `opticalSize` defaults to the point size (as Figma does); lower it for sturdier hairlines.
    static func display(_ size: CGFloat, weight: CGFloat = 400, italic: Bool = false, opticalSize: CGFloat? = nil) -> Font {
        let key = "d\(size)-\(weight)-\(italic)-\(opticalSize ?? 0)"
        if let f = cache[key] { return f }
        let f = variable(name: italic ? "BodoniModa-Italic" : "BodoniModa-Regular", size: size, axes: [
            "opsz": min(96, max(6, opticalSize ?? size)), "wght": min(900, max(400, weight)),
        ], fallback: UIFont(descriptor: UIFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif)!, size: size))
        cache[key] = f
        return f
    }

    /// Body and interface text.
    static func text(_ size: CGFloat, weight: CGFloat = 400) -> Font {
        let key = "t\(size)-\(weight)"
        if let f = cache[key] { return f }
        let f = variable(name: "Inter-Regular", size: size, axes: [
            "opsz": min(32, max(14, size)), "wght": weight,
        ], fallback: .systemFont(ofSize: size))
        cache[key] = f
        return f
    }

    /// Small uppercase labels ("BARD / LESSON 04"). Track them with `Metrics.labelTracking`.
    static func label(_ size: CGFloat = 10, weight: CGFloat = 600) -> Font { text(size, weight: weight) }

    /// Scores and counters: tabular.
    static func numeral(_ size: CGFloat, weight: CGFloat = 600) -> Font { text(size, weight: weight).monospacedDigit() }

    private static func variable(name: String, size: CGFloat, axes: [String: CGFloat], fallback: UIFont) -> Font {
        var variations: [NSNumber: NSNumber] = [:]
        for (tag, value) in axes { variations[NSNumber(value: fourCC(tag))] = NSNumber(value: Double(value)) }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: name,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variations,
        ])
        let font = UIFont(descriptor: descriptor, size: size)
        // An unregistered name silently resolves to a system font; use our fallback instead.
        let family = name.prefix { $0 != "-" }
        return Font(font.familyName.replacingOccurrences(of: " ", with: "").hasPrefix(family) ? font : fallback)
    }

    private static func fourCC(_ s: String) -> UInt32 {
        s.utf8.reduce(0) { ($0 << 8) | UInt32($1) }
    }
}

// MARK: - Space

enum Metrics {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 24
    static let s6: CGFloat = 32
    static let s7: CGFloat = 48
    static let s8: CGFloat = 72

    // Figma: 12 buttons, 14 rows, 18 hero cards.
    static let radiusS: CGFloat = 12
    static let radiusM: CGFloat = 14
    static let radiusL: CGFloat = 18

    /// The page's side margin (Figma: 24).
    static let margin: CGFloat = 24

    static let labelTracking: CGFloat = 0.8
}

// MARK: - Stage

/// Where a view is drawn, and how big. The phone is held; the arena is a
/// laptop screen turned toward a table and read from 1 to 1.5 m. Components
/// scale their type and spacing by `scale`.
struct Stage: Equatable, Sendable {
    enum Kind: Sendable { case phone, arena }

    var kind: Kind
    var scale: CGFloat

    static let phone = Stage(kind: .phone, scale: 1)
    /// A fixed arena scale for previews; live arena screens use `.arenaStage()`.
    static let arena = Stage(kind: .arena, scale: 1.7)

    var isArena: Bool { kind == .arena }
}

private struct StageKey: EnvironmentKey {
    static let defaultValue: Stage = .phone
}

extension EnvironmentValues {
    var stage: Stage {
        get { self[StageKey.self] }
        set { self[StageKey.self] = newValue }
    }
}

extension View {
    /// Root modifier for arena screens. Scales to the window: about 1.8x on a
    /// full-screen 13–15" laptop (type reads across a judging table), and down
    /// to 1x on an iPhone in landscape, the backup arena.
    func arenaStage() -> some View { modifier(ArenaStage()) }
}

private struct ArenaStage: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geo in
            let fit = min(geo.size.width / 760, geo.size.height / 520)
            content
                .frame(width: geo.size.width, height: geo.size.height)
                .environment(\.stage, Stage(kind: .arena, scale: min(2.2, max(1, fit))))
        }
    }
}

// MARK: - Motion

enum Motion {
    /// The stamp: things that land (a hit, a score, a card) land like a rubber stamp.
    static let stamp = Animation.spring(response: 0.28, dampingFraction: 0.55)
    /// The slide: panels and plates arriving.
    static let slide = Animation.spring(response: 0.45, dampingFraction: 0.86)
    static let fade = Animation.easeOut(duration: 0.22)
}

// MARK: - Paper

/// A matte surface, as in the concept: flat fill, a hairline on light paper,
/// and the same grain as the scene. Lifted surfaces float over the scene with
/// a soft, low shadow. Never a glow, never a gradient.
struct PaperSurface: ViewModifier {
    var fill: Color = Palette.paper
    var radius: CGFloat = Metrics.radiusM
    var lifted: Bool = true

    func body(content: Content) -> some View {
        let light = fill == Palette.paper || fill == Palette.page || fill == Palette.paper2 || fill == Palette.cream
        content.background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .colorEffect(ShaderLibrary.paperGrain(.float(0.02)))
                .overlay {
                    if light {
                        RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Palette.line, lineWidth: 1)
                    }
                }
                .shadow(color: Color(hex: 0x302A29).opacity(lifted ? 0.10 : 0), radius: 20, x: 0, y: 10)
        }
    }
}

extension View {
    func paper(_ fill: Color = Palette.paper, radius: CGFloat = Metrics.radiusM, lifted: Bool = true) -> some View {
        modifier(PaperSurface(fill: fill, radius: radius, lifted: lifted))
    }

    /// Uppercase tracked label: "BARD / LESSON 04", axis names, kinds.
    func tracked(_ size: CGFloat = 10, color: Color = Palette.ink2) -> some View {
        font(Typeface.label(size)).tracking(Metrics.labelTracking * size / 10).textCase(.uppercase).foregroundStyle(color)
    }

    /// A small label on a paper chip with a hairline: legible on any scene.
    func chip(_ size: CGFloat = 10, fill: Color = Palette.paper, color: Color = Palette.ink2) -> some View {
        tracked(size, color: color)
            .padding(.horizontal, size * 1.1)
            .padding(.vertical, size * 0.6)
            .background {
                Capsule(style: .continuous).fill(fill)
                    .overlay { Capsule(style: .continuous).strokeBorder(fill == Palette.paper ? Palette.line : .clear, lineWidth: 1) }
            }
    }

    /// Type set straight on the scene, lifted by a soft shadow. Use only for
    /// short labels; anything that must be read sits on paper.
    func onScene(_ color: Color = Palette.paper) -> some View {
        foregroundStyle(color)
            .shadow(color: Color(hex: 0x302A29).opacity(0.35), radius: 0, x: 0, y: 1.5)
            .shadow(color: Color(hex: 0x302A29).opacity(0.3), radius: 14, x: 0, y: 4)
    }
}
