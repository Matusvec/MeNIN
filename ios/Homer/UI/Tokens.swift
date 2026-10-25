import CoreText
import SwiftUI
import UIKit

// MeNIN's design tokens. Two directions share one set of semantic tokens, so
// every component renders in either and Matus can compare them side by side
// (Figma: "MeNIN · Directions", one variable collection, one mode each):
//
// - Atelier: from Matus's concept frame "Homer · Atelier". A cream page,
//   Bodoni Moda, wine as the one strong accent, hairline cards.
// - Cut paper: the first art pass. Bold Fraunces, paper and ink slabs with
//   cut-paper shadows over a dark, colorful scene.
// - Hall: the website's palette (Matus, Sat 8:40 PM: "match the color scheme on
//   the website, like the blue"). Atelier's type; the Aegean blues and slate
//   inks of homer/web; frosted paper over the flowing white scene, which shows
//   behind every screen. The default.
//
// Both are matte: flat fills, never gloss or glow. The scene brings the color.

// MARK: - Direction

enum Direction: String, CaseIterable, Sendable {
    case atelier, cutPaper, hall

    /// Chosen at launch (a debug setting until Matus picks). Views read it
    /// through Palette and Typeface; rebuild the view tree after changing it.
    nonisolated(unsafe) static var current: Direction = .hall

    var title: String {
        switch self {
        case .atelier: "Atelier"
        case .cutPaper: "Cut paper"
        case .hall: "Hall"
        }
    }

    /// A light page with Atelier's type and hairlines (Atelier and Hall); Cut paper is the dark one.
    var isLight: Bool { self != .cutPaper }

    /// The saved choice's key. `.v2` since Hall: a phone that saved Atelier earlier starts on Hall.
    private static let key = "menin.direction.v2"

    /// Reads the saved choice. Call once at launch, before any view.
    static func loadSaved() {
        if let raw = UserDefaults.standard.string(forKey: key), let d = Direction(rawValue: raw) {
            current = d
        }
    }

    /// Saves a new choice. Rebuild the view tree (or relaunch) to see it everywhere.
    static func save(_ d: Direction) {
        current = d
        UserDefaults.standard.set(d.rawValue, forKey: key)
    }
}

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
    private static func pick(_ atelier: UInt32, _ cutPaper: UInt32, _ hall: UInt32) -> Color {
        switch Direction.current {
        case .atelier: Color(hex: atelier)
        case .cutPaper: Color(hex: cutPaper)
        case .hall: Color(hex: hall)
        }
    }

    // The page and its paper.
    static var page: Color { pick(0xF7F3EC, 0x1A1325, 0xF7FBFC) }
    /// Hall's paper is frosted: white at 0.92 over the flowing scene, like the website's cards (a
    /// system material under it read grey on the light sea, so it's opacity alone).
    static var paper: Color { Direction.current == .hall ? Color(hex: 0xFFFFFF, opacity: 0.92) : pick(0xFFFCF7, 0xF3EADB, 0xFFFFFF) }
    static var paper2: Color { pick(0xF2ECE2, 0xE9DCC6, 0xEDF7F9) }
    static var paper3: Color { pick(0xE4DCD2, 0xDCCAB0, 0xD4E8EE) }
    /// Hairlines on paper. Cut paper has none: its edges are shadows.
    static var line: Color {
        switch Direction.current {
        case .atelier: Color(hex: 0xE4DCD2)
        case .cutPaper: .clear
        case .hall: Color(hex: 0xC9D8DE)
        }
    }

    // Ink.
    static var ink: Color { pick(0x302A29, 0x1C1524, 0x2C4B5C) }
    static var ink2: Color { pick(0x82756E, 0x4B4153, 0x3F5F72) }
    static var ink3: Color { pick(0xA69A92, 0x8B8090, 0x78909C) }

    // The hero surface: the poet's words, the carved line, a chosen card.
    static var hero: Color { pick(0x682C3E, 0x1C1524, 0x334B5B) }
    static var onHero: Color { pick(0xFFF8ED, 0xF3EADB, 0xFFFFFF) }
    static var onHero2: Color { pick(0xDDC3C5, 0xA79EA3, 0x9FCFE0) }
    /// Light text on any dark or colored slab (seat plates, the scoreboard).
    static var cream: Color { pick(0xFFF8ED, 0xF3EADB, 0xF7FBFC) }

    /// Text set straight on the page (Atelier's cream, Cut paper's dark sea).
    static var onPage: Color { pick(0x302A29, 0xF3EADB, 0x2C4B5C) }
    static var onPage2: Color { pick(0x82756E, 0xB9AFA8, 0x3F5F72) }
    /// The wordmark and other brand marks on the page.
    static var brand: Color { pick(0x682C3E, 0xF3EADB, 0x2E8EB5) }

    /// The primary action's fill (the Join, Ready and Next buttons). The hero slab in Atelier and Cut
    /// paper; the website's action blue in Hall. Text on it is onHero.
    static var action: Color { pick(0x682C3E, 0x1C1524, 0x328EAF) }

    /// The accent on paper: labels, marks, the beat that's playing now.
    static var accent: Color { pick(0x682C3E, 0x1F5361, 0x2F7F9C) }

    // Supporting inks, each with one job.
    static var wine: Color { pick(0x682C3E, 0x6B1F3E, 0x682C3E) }
    static var gold: Color { pick(0xC99A3E, 0xE8B73A, 0xC99A3E) }      // hits, best lines, the hoard
    static var goldDeep: Color { pick(0x9A7128, 0xA8720F, 0x7A5A1E) }  // gold on paper
    static var vermilion: Color { pick(0xC8452C, 0xEC4A1C, 0xC8452C) } // live: the mic, the clock
    static var sea: Color { pick(0x2D5C66, 0x1F5361, 0x328EAF) }       // Homer's voice
    static var olive: Color { pick(0x6E7A2E, 0x6E7A2E, 0x6E7A2E) }     // Socrates
    static var lilac: Color { pick(0x8A72C4, 0xAE84FF, 0x8A72C4) }     // debate moves

    /// One ink per poet seat, so a poet keeps their color all battle.
    static var seats: [Color] {
        Direction.current.isLight
            // Wine is the hero surface in Atelier, so no seat wears it. Hall keeps Atelier's
            // seats: the website's battle SEAT_INKS are these, so a poet's colour matches the big screen. The first four (a
            // full room) are four plainly different hues from 2 m: sea, vermilion, gold, plum.
            ? [0x2D5C66, 0xC8452C, 0xA8741F, 0x5B3F73, 0x6E7A2E].map { Color(hex: $0) }
            : [0xEC4A1C, 0x2C6FD6, 0xE8B73A, 0x2E9C7A, 0xC2569A].map { Color(hex: $0) }
    }
}

// MARK: - Type

/// Display type is the voice of the legend: verse, names, titles.
/// Atelier: Bodoni Moda (wght 400–900, opsz 6–96), Regular for the calm of
/// Bard and Practice, heavy for the Agon. Cut paper: Fraunces, set 300 units
/// heavier. Inter (wght, opsz) for everything that works, in both.
@MainActor
enum Typeface {
    private static var cache: [String: Font] = [:]

    /// `weight` is in Atelier's scale (400 regular ... 900 black).
    /// `opticalSize` defaults to the point size, as Figma does.
    static func display(_ size: CGFloat, weight: CGFloat = 400, italic: Bool = false, opticalSize: CGFloat? = nil) -> Font {
        let direction = Direction.current
        let key = "d\(direction)-\(size)-\(weight)-\(italic)-\(opticalSize ?? 0)"
        if let f = cache[key] { return f }
        let serif = UIFont(descriptor: UIFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif)!, size: size)
        let f: Font
        if direction.isLight {
            f = variable(name: italic ? "BodoniModa-Italic" : "BodoniModa-Regular", size: size, axes: [
                "opsz": min(96, max(6, opticalSize ?? size)), "wght": min(900, max(400, weight)),
            ], fallback: serif)
        } else {
            f = variable(name: italic ? "Fraunces-9ptBlackItalic" : "Fraunces-9ptBlack", size: size, axes: [
                "opsz": min(144, max(9, opticalSize ?? size)), "wght": min(900, weight + 300), "SOFT": 0, "WONK": 0,
            ], fallback: serif)
        }
        cache[key] = f
        return f
    }

    /// Display type sized for a stage. On the arena the optical size follows how
    /// big the type looks from the judges' table (about 2 m off a laptop, where a
    /// 22 pt name reads like 10 pt type on a phone), not its point size, so
    /// Bodoni's hairlines (the arm of a "y", the diagonal of an "N") survive the
    /// distance. On a phone it's `display(base)`.
    static func display(_ base: CGFloat, on stage: Stage, weight: CGFloat = 400, italic: Bool = false) -> Font {
        display(base * stage.scale, weight: weight, italic: italic, opticalSize: stage.isArena ? base * 0.45 : nil)
    }

    /// Bodoni leaves a hole after a "y" (and "v", "w") at display sizes, so "Sunya"
    /// reads "Suny a". Closes it with a kern of 6% of the type size after those letters.
    static func kerned(_ text: String, size: CGFloat) -> AttributedString {
        var out = AttributedString()
        for ch in text {
            var piece = AttributedString(String(ch))
            if "yvw".contains(ch) { piece.swiftUI.kern = -0.06 * size }
            out += piece
        }
        return out
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

/// Multi-line display text with a set leading (Figma's line height, e.g.
/// 1.12). SwiftUI can't tighten line height below the font's own, and Bodoni's
/// is loose, so explicit lines are stacked at the right pitch.
struct LeadedText: View {
    let text: String
    let font: Font
    let size: CGFloat
    var leading: CGFloat = 1.12

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                Text(line).font(font).frame(height: size * leading, alignment: .center)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text.replacingOccurrences(of: "\n", with: " "))
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

    static var labelTracking: CGFloat { Direction.current.isLight ? 0.8 : 1.4 }
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

extension View {
    /// Type that holds from 2 m (SPEC "Platform"): on the arena, copies of the
    /// text in a tight ring under it thicken every stroke by about 1% of the
    /// type size, a flat synthetic bold that keeps Bodoni's hairlines (the arm
    /// of a "y", the thin verticals of an "N") from vanishing across the room.
    /// Matte, never a glow. `base` is the unscaled size, as in `display(_:on:)`.
    /// A no-op on phones. Put it right after the font and color.
    func sturdy(_ base: CGFloat) -> some View { modifier(Sturdy(base: base)) }
}

private struct Sturdy: ViewModifier {
    let base: CGFloat
    @Environment(\.stage) private var stage

    func body(content: Content) -> some View {
        if stage.isArena {
            let r = base * stage.scale * 0.009
            content.background {
                ZStack {
                    ForEach(0..<8, id: \.self) { i in
                        let a = Double(i) * .pi / 4
                        content.offset(x: cos(a) * r, y: sin(a) * r)
                    }
                }
                .accessibilityHidden(true)
            }
        } else {
            content
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

/// A matte surface. Atelier: flat fill with a hairline and a soft, low shadow
/// when it floats over the scene. Cut paper: a crisp lip and a cast shadow.
/// Both carry the scene's grain. Never a glow, never a gradient.
struct PaperSurface: ViewModifier {
    var fill: Color = Palette.paper
    var radius: CGFloat = Metrics.radiusM
    var lifted: Bool = true

    func body(content: Content) -> some View {
        let atelier = Direction.current.isLight
        let light = fill == Palette.paper || fill == Palette.page || fill == Palette.paper2 || fill == Palette.cream
        content.background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .colorEffect(ShaderLibrary.paperGrain(.float(atelier ? 0.02 : 0.035)))
                .overlay {
                    if atelier && light {
                        RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Palette.line, lineWidth: 1)
                    }
                }
                .shadow(color: .black.opacity(lifted && !atelier ? 0.22 : 0), radius: 0, x: 0, y: 1.5)
                .shadow(color: Color(hex: atelier ? 0x302A29 : 0x0E0814).opacity(lifted ? (atelier ? 0.10 : 0.32) : 0),
                        radius: atelier ? 20 : 22, x: 0, y: atelier ? 10 : 14)
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

    /// Sets display type at a line height of `factor` × `size` (Figma's
    /// 1.1–1.12 for Bodoni), on iOS 26 and later. Earlier systems keep the
    /// font's own, looser leading.
    @ViewBuilder
    func displayLeading(_ size: CGFloat, _ factor: CGFloat = 1.12) -> some View {
        if #available(iOS 26.0, *) {
            lineHeight(.exact(points: size * factor))
        } else {
            self
        }
    }

    /// For a screen's root: lets the scene show through a NavigationStack (or
    /// any navigation container), whose default background is opaque system
    /// color. That paints charcoal over the scene in dark mode (the Mac arena).
    func sceneBehind() -> some View {
        containerBackground(.clear, for: .navigation)
    }

    /// Type set straight on the scene, lifted by a soft shadow. Use only for
    /// short labels; anything that must be read sits on paper.
    func onScene(_ color: Color = Palette.paper) -> some View {
        foregroundStyle(color)
            .shadow(color: Color(hex: 0x302A29).opacity(0.35), radius: 0, x: 0, y: 1.5)
            .shadow(color: Color(hex: 0x302A29).opacity(0.3), radius: 14, x: 0, y: 4)
    }
}
