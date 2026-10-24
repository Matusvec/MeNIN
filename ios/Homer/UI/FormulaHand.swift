import SwiftUI

/// Your hand: up to five formula cards, cut like paper slips. Private on the
/// phone (stacked); on the arena's guest seat, laid out in a row.
///
/// - `raisedId`: the freeze rescue. That card lifts, edged in gold, while Homer whispers it.
/// - `forward`: the whole hand comes forward (on deck, or a freeze).
struct FormulaHandView: View {
    let cards: [FormulaCard]
    var raisedId: String? = nil
    var forward: Bool = true
    var onTap: ((FormulaCard) -> Void)? = nil

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        let layout = stage.isArena
            ? AnyLayout(HStackLayout(alignment: .bottom, spacing: Metrics.s3 * k))
            : AnyLayout(VStackLayout(spacing: Metrics.s2 * k))
        layout {
            ForEach(cards) { card in
                FormulaCardView(card: card, raised: card.id == raisedId)
                    .onTapGesture { onTap?(card) }
            }
        }
        .scaleEffect(forward ? 1 : 0.96, anchor: .bottom)
        .opacity(forward ? 1 : 0.82)
        .animation(Motion.slide, value: forward)
        .animation(Motion.stamp, value: raisedId)
    }
}

struct FormulaCardView: View {
    let card: FormulaCard
    var raised: Bool = false

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(spacing: 0) {
            // A colored tab cut into the slip's edge says what kind of formula it is.
            Rectangle().fill(card.used ? Palette.ink3 : tab).frame(width: 5 * k)
            VStack(alignment: .leading, spacing: 3 * k) {
                HStack(spacing: Metrics.s2 * k) {
                    Text(kind).tracked(9 * k, color: card.used ? Palette.paper.opacity(0.5) : Palette.ink3)
                    if raised {
                        Text("Homer whispers").tracked(9 * k, color: Palette.goldDeep)
                            .transition(.opacity)
                    }
                    Spacer(minLength: 0)
                    if card.used {
                        Text("Played").tracked(9 * k, color: Palette.gold)
                            .transition(.scale(scale: 1.6).combined(with: .opacity))
                    }
                }
                Text(card.text)
                    // Verse formulas are set in the bard's serif; debate moves are argument, set plain.
                    .font(card.kind == .move ? Typeface.text(17 * k, weight: 650) : Typeface.display(20 * k, weight: 700))
                    .foregroundStyle(card.used ? Palette.paper.opacity(0.75) : Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, Metrics.s4 * k)
            .padding(.vertical, Metrics.s3 * k)
            .frame(maxWidth: stage.isArena ? 260 * k : .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .paper(card.used ? Palette.ink : Palette.paper, radius: Metrics.radiusS * k)
        .overlay {
            RoundedRectangle(cornerRadius: Metrics.radiusS * k, style: .continuous)
                .strokeBorder(Palette.gold, lineWidth: raised ? 2.5 * k : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusS * k, style: .continuous).inset(by: -40))
        // Raised: in the arena's row the card lifts; in the phone's stack it steps forward.
        .offset(y: raised && stage.isArena ? -14 * k : 0)
        .scaleEffect(raised ? (stage.isArena ? 1.04 : 1.025) : 1)
        .zIndex(raised ? 1 : 0)
        .animation(Motion.stamp, value: card.used)
        .accessibilityElement(children: .combine)
        .accessibilityValue(card.used ? "played" : "")
    }

    private var kind: String {
        switch card.kind {
        case .epithet: "Epithet"
        case .kenning: "Kenning"
        case .halfLine: "Half-line"
        case .move: "Move"
        }
    }

    private var tab: Color {
        switch card.kind {
        case .epithet: Palette.gold
        case .kenning: Palette.sea
        case .halfLine: Palette.wine
        case .move: Palette.lilac
        }
    }
}

#Preview {
    FormulaHandView(cards: [
        FormulaCard(id: "1", text: "the whale-road", kind: .kenning, used: true),
        FormulaCard(id: "2", text: "grey-eyed Athena", kind: .epithet, used: false),
        FormulaCard(id: "3", text: "when rose-fingered Dawn came early", kind: .halfLine, used: false),
    ], raisedId: "2")
    .padding()
    .background(Palette.sea)
}
