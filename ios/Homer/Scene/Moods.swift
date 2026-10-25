import simd

// The scene's look, per mood. Each mood is four matte inks (dark to light)
// laid down as flat paper-cut layers, plus how the field and the flecks move.
// `rest` is the idle state: Hall's white Aegean, Atelier's cream page, or Cut
// paper's wine-dark sea.

enum Mood: Int, CaseIterable {
    case rest, anger, grief, joy, awe, tenderness, fear, defiance, longing

    init(_ emotion: Emotion) {
        switch emotion {
        case .anger: self = .anger
        case .grief: self = .grief
        case .joy: self = .joy
        case .awe: self = .awe
        case .tenderness: self = .tenderness
        case .fear: self = .fear
        case .defiance: self = .defiance
        case .longing: self = .longing
        }
    }
}

struct FieldMotion {
    var speed: Float      // how fast the shapes evolve
    var drift: SIMD2<Float> // which way the shapes travel (screen heights / s)
    var turb: Float       // domain-warp strength
    var jag: Float        // 0 smooth ... 1 ridged, torn edges
    var detail: Float     // weight of the fine octaves
    var scale: Float      // size of the shapes (higher = smaller)
    var tremble: Float    // high-frequency shake
    var lightY: Float     // where the light sits (-0.5 bottom ... 0.5 top)
    var lightAmt: Float   // how strongly the light lifts the layers
    var soft: Float       // edge softness between layers
    var lift: Float       // pushes every layer lighter (+) or darker (-)
    var tilt: Float       // + lighter layers stack toward the top, - toward the bottom, 0 none
    var amp: Float        // how far the noise bends the layer edges
}

enum FleckShape: Float { case dot = 0, dash = 1, shard = 2 }
enum FleckSpawn { case bottom, top, left, center, edges, anywhere }

struct FleckMotion {
    var spawn: FleckSpawn
    var vel: SIMD2<Float>
    var radial: Float      // outward (+) or inward (-) speed
    var jitter: Float
    var bounce: Float
    var sway: Float
    var drag: Float
    var life: ClosedRange<Float>
    var size: ClosedRange<Float> // points
    var shape: FleckShape
    var alpha: Float
    var ink: Int           // which of the four inks the flecks use
}

enum WashFrom {
    case below, above, left, center, rim

    var vector: SIMD4<Float> {
        switch self {
        case .below: return [0, 1, 0, 0]
        case .above: return [0, -1, 0, 0]
        case .left: return [1, 0, 0, 0]
        case .center: return [0, 0, 1, 0]
        case .rim: return [0, 0, -1, 0]
        }
    }
}

struct MoodStyle {
    var inks: [UInt32] // four sRGB hex inks, dark to light
    var field: FieldMotion
    var flecks: FleckMotion
    var wash: WashFrom

    func ink(_ i: Int) -> SIMD4<Float> {
        let n = inks[i]
        return [Float((n >> 16) & 255) / 255, Float((n >> 8) & 255) / 255, Float(n & 255) / 255, 1]
    }
}

extension Mood {
    var style: MoodStyle { Mood.styles[rawValue] }

    /// The styles for the current design direction. Only `rest` differs: Hall rests
    /// on the website's white Aegean, Atelier on the cream page, Cut paper on the
    /// wine-dark sea.
    static var styles: [MoodStyle] {
        switch Direction.current {
        case .hall: hallStyles
        case .atelier: atelierStyles
        case .cutPaper: cutPaperStyles
        }
    }

    private static let hallStyles = Mood.allCases.map { $0.makeStyle(.hall) }
    private static let atelierStyles = Mood.allCases.map { $0.makeStyle(.atelier) }
    private static let cutPaperStyles = Mood.allCases.map { $0.makeStyle(.cutPaper) }

    private func makeStyle(_ direction: Direction) -> MoodStyle {
        switch self {
        case .rest where direction == .hall:
            // The website's light Aegean (homer/web/src/scene/moods.ts), whiter and
            // moving more: mostly white paper, the sea blue flowing through it in
            // slow bands, a few blue flecks drifting.
            return MoodStyle(
                inks: [0x8CC4D9, 0xC4E3EE, 0xE6F3F8, 0xF7FBFC],
                field: FieldMotion(speed: 0.07, drift: [0.03, 0.005], turb: 1.2, jag: 0, detail: 0.2, scale: 0.8, tremble: 0, lightY: -0.45, lightAmt: 0.1, soft: 0.004, lift: 0.1, tilt: -0.35, amp: 0.45),
                flecks: FleckMotion(spawn: .anywhere, vel: [0.01, 0.018], radial: 0, jitter: 0.02, bounce: 0, sway: 0.012, drag: 0.2, life: 8...12, size: 2...4, shape: .dot, alpha: 0.55, ink: 0),
                wash: .below)
        case .rest where direction == .atelier:
            // The page from the concept (#F7F3EC), with faint paper layers in it.
            return MoodStyle(
                inks: [0xE4D7CC, 0xEBE3D8, 0xF1EBE2, 0xF7F3EC],
                field: FieldMotion(speed: 0.05, drift: [0.02, 0], turb: 1.1, jag: 0, detail: 0.2, scale: 0.85, tremble: 0, lightY: -0.45, lightAmt: 0.1, soft: 0.004, lift: 0.08, tilt: -0.45, amp: 0.38),
                flecks: FleckMotion(spawn: .anywhere, vel: [0.008, 0.016], radial: 0, jitter: 0.02, bounce: 0, sway: 0.01, drag: 0.2, life: 8...12, size: 2...4, shape: .dot, alpha: 0.5, ink: 0),
                wash: .below)
        case .rest:
            return MoodStyle(
                inks: [0x1A1325, 0x4B1834, 0x1F5361, 0xD9C6A5],
                field: FieldMotion(speed: 0.06, drift: [0.03, 0], turb: 1.2, jag: 0, detail: 0.25, scale: 0.9, tremble: 0, lightY: -0.45, lightAmt: 0.12, soft: 0.004, lift: 0, tilt: -0.62, amp: 0.42),
                flecks: FleckMotion(spawn: .anywhere, vel: [0.008, 0.016], radial: 0, jitter: 0.02, bounce: 0, sway: 0.01, drag: 0.2, life: 8...12, size: 2...4, shape: .dot, alpha: 0.4, ink: 3),
                wash: .below)
        case .anger:
            return MoodStyle(
                inks: [0x3D0B10, 0xB3161F, 0xEC4A1C, 0xFF9B52],
                field: FieldMotion(speed: 0.4, drift: [0, 0.05], turb: 0.95, jag: 0.6, detail: 0.2, scale: 0.8, tremble: 0.25, lightY: -0.2, lightAmt: 0.15, soft: 0.002, lift: -0.05, tilt: -0.2, amp: 0.5),
                flecks: FleckMotion(spawn: .center, vel: [0, 0.04], radial: 0.38, jitter: 1.1, bounce: 0, sway: 0, drag: 0.6, life: 0.9...1.8, size: 9...16, shape: .shard, alpha: 0.95, ink: 3),
                wash: .center)
        case .grief:
            return MoodStyle(
                inks: [0x070B1D, 0x12245A, 0x294C98, 0x7F97CB],
                field: FieldMotion(speed: 0.04, drift: [0, -0.02], turb: 0.9, jag: 0, detail: 0.15, scale: 0.8, tremble: 0, lightY: -0.7, lightAmt: 0.1, soft: 0.006, lift: -0.06, tilt: 0.7, amp: 0.35),
                flecks: FleckMotion(spawn: .top, vel: [0, -0.06], radial: 0, jitter: 0.01, bounce: 0, sway: 0.015, drag: 0.1, life: 7...11, size: 3...5, shape: .dot, alpha: 0.6, ink: 1),
                wash: .above)
        case .joy:
            return MoodStyle(
                inks: [0xE23F7C, 0xFF7A59, 0xFFC23A, 0xFFF0B0],
                field: FieldMotion(speed: 0.2, drift: [0.02, 0.05], turb: 1.3, jag: 0.1, detail: 0.25, scale: 0.95, tremble: 0, lightY: -0.1, lightAmt: 0.15, soft: 0.003, lift: 0.02, tilt: 0.3, amp: 0.55),
                flecks: FleckMotion(spawn: .bottom, vel: [0, 0.22], radial: 0, jitter: 0.05, bounce: 0.14, sway: 0.03, drag: 0.15, life: 2.5...4.5, size: 6...11, shape: .dot, alpha: 0.95, ink: 0),
                wash: .below)
        case .awe:
            return MoodStyle(
                inks: [0x2E2108, 0xA8720F, 0xE8B73A, 0xFFF3D2],
                field: FieldMotion(speed: 0.09, drift: [0, 0.04], turb: 1.2, jag: 0, detail: 0.25, scale: 0.85, tremble: 0, lightY: -0.35, lightAmt: 0.3, soft: 0.004, lift: 0.02, tilt: -0.55, amp: 0.45),
                flecks: FleckMotion(spawn: .bottom, vel: [0, 0.07], radial: 0, jitter: 0.01, bounce: 0, sway: 0.01, drag: 0.05, life: 7...10, size: 3...8, shape: .dot, alpha: 0.85, ink: 1),
                wash: .below)
        case .tenderness:
            return MoodStyle(
                inks: [0x47294D, 0xC27596, 0xB6A2E0, 0xF4E4EE],
                field: FieldMotion(speed: 0.06, drift: [0.015, 0.01], turb: 1.0, jag: 0, detail: 0.05, scale: 0.8, tremble: 0, lightY: -0.3, lightAmt: 0.12, soft: 0.03, lift: 0.02, tilt: 0.4, amp: 0.4),
                flecks: FleckMotion(spawn: .anywhere, vel: [0.01, 0.015], radial: 0, jitter: 0.01, bounce: 0, sway: 0.02, drag: 0.2, life: 6...9, size: 14...28, shape: .dot, alpha: 0.28, ink: 2),
                wash: .below)
        case .fear:
            return MoodStyle(
                inks: [0x0B1712, 0x2C5243, 0x6F8F7F, 0xB3BCB6],
                field: FieldMotion(speed: 0.18, drift: [0, 0], turb: 1.6, jag: 0.3, detail: 0.45, scale: 1.1, tremble: 1, lightY: -0.5, lightAmt: 0.1, soft: 0.002, lift: -0.06, tilt: 0.1, amp: 0.6),
                flecks: FleckMotion(spawn: .edges, vel: [0, 0], radial: -0.09, jitter: 0.5, bounce: 0, sway: 0, drag: 0.3, life: 2.5...4, size: 2...4, shape: .dot, alpha: 0.85, ink: 3),
                wash: .rim)
        case .defiance:
            return MoodStyle(
                inks: [0x1B0838, 0x5A1FD0, 0xAE84FF, 0xFBF3FF],
                field: FieldMotion(speed: 0.3, drift: [0, 0.03], turb: 1.4, jag: 0.6, detail: 0.3, scale: 0.95, tremble: 0, lightY: -0.15, lightAmt: 0.2, soft: 0.002, lift: -0.04, tilt: -0.3, amp: 0.65),
                flecks: FleckMotion(spawn: .center, vel: [0, 0], radial: 0.75, jitter: 0.05, bounce: 0, sway: 0, drag: 1.6, life: 0.8...1.4, size: 14...24, shape: .dash, alpha: 0.95, ink: 3),
                wash: .center)
        case .longing:
            return MoodStyle(
                inks: [0x1F1033, 0x593877, 0xC0694A, 0xF2A65A],
                field: FieldMotion(speed: 0.06, drift: [0.05, 0], turb: 1.0, jag: 0, detail: 0.2, scale: 0.85, tremble: 0, lightY: -0.35, lightAmt: 0.12, soft: 0.006, lift: 0, tilt: 0.55, amp: 0.4),
                flecks: FleckMotion(spawn: .left, vel: [0.06, 0], radial: 0, jitter: 0.01, bounce: 0, sway: 0.01, drag: 0.05, life: 10...14, size: 10...18, shape: .dash, alpha: 0.6, ink: 3),
                wash: .left)
        }
    }
}
