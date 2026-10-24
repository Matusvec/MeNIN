import CoreImage.CIFilterBuiltins
import SwiftUI

// Battle mode is a title-fight broadcast set in cut paper: big type, solid
// slabs of seat color, entrances that land. Props in, no logic.

/// One poet as the broadcast shows them.
struct PoetPlate: Identifiable, Equatable {
    var id: String
    var name: String
    var epithet: String
    var seat: Int
    var total: Int = 0
}

extension PoetPlate {
    var ink: Color { Palette.seats[seat % Palette.seats.count] }
    var fullName: String { epithet.isEmpty ? name : "\(name), \(epithet)" }
}

// MARK: - Entrance

/// "Enter Matus, Breaker of Deadlines!" A slab of the poet's seat color slams
/// in from the left with their name on it.
struct EntranceView: View {
    let poet: PoetPlate
    @State private var landed = false
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(alignment: .leading, spacing: Metrics.s2 * k) {
            Text("Enter").tracked(13 * k, color: Palette.paper.opacity(0.85))
            Text(poet.name)
                .font(Typeface.display(76 * k, weight: 900))
                .foregroundStyle(Palette.paper)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if !poet.epithet.isEmpty {
                Text(poet.epithet)
                    .font(Typeface.display(28 * k, weight: 600, italic: true))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, Metrics.s3 * k)
                    .padding(.vertical, Metrics.s1 * k)
                    .background(Palette.paper, in: RoundedRectangle(cornerRadius: 4 * k))
                    .offset(x: landed ? 0 : 60 * k)
                    .opacity(landed ? 1 : 0)
                    .animation(Motion.stamp.delay(0.18), value: landed)
            }
        }
        .padding(.vertical, Metrics.s6 * k)
        .padding(.leading, Metrics.s7 * k)
        .padding(.trailing, Metrics.s8 * k)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(poet.ink, radius: 0)
        .offset(x: landed ? 0 : -1400)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: landed)
        .onAppear { landed = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Enter \(poet.fullName)")
    }
}

// MARK: - Round title

struct RoundTitleView: View {
    let round: Int
    let rounds: Int
    let theme: String
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s4 * k) {
            Text("Round \(roman(round)) of \(roman(rounds))").chip(13 * k)
            Text(theme)
                .font(Typeface.display(54 * k, weight: 900))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, Metrics.s6 * k)
                .padding(.vertical, Metrics.s5 * k)
                .paper(radius: Metrics.radiusL * k)
        }
        .padding(.horizontal, Metrics.s5 * k)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Theme cards

/// Demo mode: three theme cards on the arena; the judges tap one.
struct ThemeCardsView: View {
    let themes: [String]
    var selected: Int? = nil
    var onPick: ((Int) -> Void)? = nil
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(spacing: Metrics.s4 * k) {
            ForEach(Array(themes.enumerated()), id: \.offset) { i, theme in
                let isPicked = selected == i
                Button { onPick?(i) } label: {
                    VStack(alignment: .leading, spacing: Metrics.s4 * k) {
                        Text(roman(i + 1))
                            .font(Typeface.display(40 * k, weight: 900))
                            .foregroundStyle(isPicked ? Palette.gold : Palette.ink3)
                        Spacer(minLength: 0)
                        Text(theme)
                            .font(Typeface.display(24 * k, weight: 750))
                            .foregroundStyle(isPicked ? Palette.paper : Palette.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Metrics.s5 * k)
                    .frame(maxWidth: 300 * k, minHeight: 220 * k, alignment: .topLeading)
                    .paper(isPicked ? Palette.ink : Palette.paper, radius: Metrics.radiusL * k)
                }
                .buttonStyle(.plain)
                .scaleEffect(isPicked ? 1.05 : (selected == nil ? 1 : 0.94))
                .opacity(selected == nil || isPicked ? 1 : 0.45)
                .offset(y: isPicked ? -12 * k : 0)
            }
        }
        .animation(Motion.stamp, value: selected)
    }
}

// MARK: - Scoreboard

/// The standings, broadcast style. The poet on the mic is marked live.
struct ScoreboardView: View {
    let poets: [PoetPlate]
    var round: Int = 1
    var rounds: Int = 3
    var liveId: String? = nil
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        let ranked = poets.sorted { $0.total > $1.total || ($0.total == $1.total && $0.seat < $1.seat) }
        VStack(alignment: .leading, spacing: Metrics.s3 * k) {
            Text("The Agon · Round \(roman(round)) of \(roman(rounds))").tracked(10 * k, color: Palette.paper.opacity(0.7))
            ForEach(Array(ranked.enumerated()), id: \.element.id) { place, poet in
                HStack(spacing: Metrics.s3 * k) {
                    Rectangle().fill(poet.ink).frame(width: 6 * k)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: Metrics.s2 * k) {
                            Text(poet.name).font(Typeface.display(22 * k, weight: 800)).foregroundStyle(Palette.paper)
                            if poet.id == liveId { LiveDot(size: 8 * k) }
                        }
                        if !poet.epithet.isEmpty {
                            Text(poet.epithet)
                                .font(Typeface.display(14 * k, weight: 500, italic: true))
                                .foregroundStyle(Palette.paper.opacity(0.65))
                        }
                    }
                    Spacer(minLength: Metrics.s4 * k)
                    Text("\(poet.total)")
                        .font(Typeface.display(34 * k, weight: 900))
                        .foregroundStyle(place == 0 && poet.total > 0 ? Palette.gold : Palette.paper)
                        .contentTransition(.numericText(value: Double(poet.total)))
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Metrics.s5 * k)
        .frame(maxWidth: 420 * k)
        .paper(Palette.ink, radius: Metrics.radiusL * k)
        .animation(Motion.slide, value: ranked.map(\.id))
        .animation(Motion.stamp, value: poets.map(\.total))
    }
}

// MARK: - Join

/// The lobby card: scan the QR code or type the room code.
struct JoinCardView: View {
    let code: String
    let url: String
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Metrics.s6 * k) { qr(k); words(k) }
            VStack(alignment: .leading, spacing: Metrics.s5 * k) { qr(k); words(k) }
        }
        .padding(Metrics.s6 * k)
        .paper(radius: Metrics.radiusL * k)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Join with code \(code.map(String.init).joined(separator: " "))")
    }
}

extension JoinCardView {
    fileprivate func qr(_ k: CGFloat) -> some View {
        QRImage(text: url).frame(width: 168 * k, height: 168 * k)
    }

    fileprivate func words(_ k: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Metrics.s2 * k) {
            Text("Join the Agon").tracked(12 * k, color: Palette.ink2)
            Text(code)
                .font(Typeface.display(72 * k, weight: 900))
                .tracking(8 * k)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .fixedSize()
            Text("Scan, or type the code in Homer.")
                .font(Typeface.text(15 * k, weight: 500))
                .foregroundStyle(Palette.ink2)
        }
    }
}

private struct QRImage: View {
    let text: String

    var body: some View {
        if let image = Self.make(text) {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
        } else {
            Rectangle().fill(Palette.paper2)
        }
    }

    private static func make(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        // Ink modules on paper, not black on white.
        let colored = output.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(red: 0x1C / 255, green: 0x15 / 255, blue: 0x24 / 255),
            "inputColor1": CIColor(red: 0xF3 / 255, green: 0xEA / 255, blue: 0xDB / 255),
        ])
        guard let cg = CIContext().createCGImage(colored, from: colored.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Champion and rematch

struct ChampionView: View {
    let poet: PoetPlate
    var onRematch: (() -> Void)? = nil
    var onNewPoets: (() -> Void)? = nil
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s5 * k) {
            // The crown plate: the champion's seat color, gold lettering above the name.
            VStack(spacing: Metrics.s2 * k) {
                Text("Champion of the Agon").chip(13 * k, fill: Palette.gold, color: Palette.ink)
                Text(poet.name)
                    .font(Typeface.display(88 * k, weight: 900))
                    .foregroundStyle(Palette.paper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if !poet.epithet.isEmpty {
                    Text(poet.epithet)
                        .font(Typeface.display(28 * k, weight: 600, italic: true))
                        .foregroundStyle(Palette.paper)
                }
                Text("\(poet.total) points")
                    .font(Typeface.numeral(17 * k, weight: 650))
                    .foregroundStyle(Palette.paper.opacity(0.8))
            }
            .padding(.vertical, Metrics.s6 * k)
            .padding(.horizontal, Metrics.s5 * k)
            .frame(maxWidth: .infinity)
            .paper(poet.ink, radius: Metrics.radiusL * k)
            if onRematch != nil || onNewPoets != nil {
                HStack(spacing: Metrics.s3 * k) {
                    if let onRematch { Button("Rematch", action: onRematch).buttonStyle(.homer) }
                    if let onNewPoets { Button("New poets", action: onNewPoets).buttonStyle(.homer(.secondary)) }
                }
            }
        }
        .padding(.horizontal, Metrics.s4 * k)
    }
}

#Preview("Broadcast") {
    let poets = [
        PoetPlate(id: "a", name: "Matus", epithet: "Breaker of Deadlines", seat: 0, total: 74),
        PoetPlate(id: "b", name: "Sunya", epithet: "Storm-Throated", seat: 1, total: 81),
    ]
    return ZStack {
        Palette.wine.ignoresSafeArea()
        VStack(spacing: 24) {
            EntranceView(poet: poets[0])
            ScoreboardView(poets: poets, round: 2, liveId: "a")
            ThemeCardsView(themes: ["A ship that never came home", "The last lamp in the city", "A debt"], selected: 1)
                .padding(.horizontal)
        }
    }
}
