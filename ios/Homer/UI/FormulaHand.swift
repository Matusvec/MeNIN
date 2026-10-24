import SwiftUI

/// Your hand: up to five formula cards, cut like paper slips. Private on the
/// phone (stacked); on the arena's guest seat, laid out in a row.
///
/// - `raisedId`: the freeze rescue. That card lifts, edged in gold, while Homer whispers it.
/// - `forward`: the whole hand comes forward (on deck, or a freeze).
struct FormulaHandView: View {
    enum Style {
        /// Full slips: the hand on deck, the arena's guest seat.
        case slips
        /// Chips that wrap, for a phone mid-verse; the whispered card becomes a hero chip.
        case compact
    }

    let cards: [FormulaCard]
    var raisedId: String? = nil
    var forward: Bool = true
    var style: Style = .slips
    /// Who whispers the raised card on a freeze: the event's host.
    var whisperer: String = "Homer"
    var onTap: ((FormulaCard) -> Void)? = nil

    @Environment(\.stage) private var stage

    var body: some View {
        if style == .compact { compact } else { slips }
    }

    private var compact: some View {
        let k = stage.scale
        return FlowLayout(spacing: Metrics.s2 * k) {
            ForEach(cards) { card in
                let raised = card.id == raisedId
                VStack(alignment: .leading, spacing: 2 * k) {
                    if raised { Text("\(whisperer) whispers").tracked(8 * k, color: Palette.onHero2) }
                    Text(card.text)
                        .font(card.kind == .move ? Typeface.text(14 * k, weight: 600) : Typeface.display((raised ? 21 : 16), on: stage))
                        .strikethrough(card.used, color: Palette.ink3)
                        .foregroundStyle(raised ? Palette.onHero : (card.used ? Palette.ink3 : Palette.ink))
                }
                .padding(.horizontal, Metrics.s3 * k)
                .padding(.vertical, (raised ? Metrics.s2 : 6) * k)
                .paper(raised ? Palette.hero : (card.used ? Palette.paper2 : Palette.paper), radius: Metrics.radiusS * k, lifted: raised)
                .scaleEffect(raised ? 1.04 : 1)
                .onTapGesture { onTap?(card) }
            }
        }
        .animation(Motion.stamp, value: raisedId)
        .animation(Motion.stamp, value: cards.map(\.used))
    }

    @ViewBuilder
    private var slips: some View {
        let k = stage.scale
        let layout = stage.isArena
            ? AnyLayout(HStackLayout(alignment: .bottom, spacing: Metrics.s3 * k))
            : AnyLayout(VStackLayout(spacing: Metrics.s2 * k))
        layout {
            ForEach(cards) { card in
                FormulaCardView(card: card, raised: card.id == raisedId, whisperer: whisperer)
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
    var whisperer: String = "Homer"

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        HStack(spacing: Metrics.s3 * k) {
            // A colored mark says what kind of formula it is.
            Capsule().fill(card.used ? Palette.ink3.opacity(0.5) : tab)
                .frame(width: 3 * k)
                .padding(.vertical, 2 * k)
            VStack(alignment: .leading, spacing: 3 * k) {
                HStack(spacing: Metrics.s2 * k) {
                    Text(kind).tracked(9 * k, color: Palette.ink2)
                    if raised {
                        Text("\(whisperer) whispers").tracked(9 * k, color: Palette.accent)
                            .transition(.opacity)
                    }
                    Spacer(minLength: 0)
                    if card.used {
                        Text("Played").tracked(9 * k, color: Palette.goldDeep)
                            .transition(.scale(scale: 1.6).combined(with: .opacity))
                    }
                }
                Text(card.text)
                    // Verse formulas are set in the bard's serif; debate moves are argument, set plain.
                    .font(card.kind == .move ? Typeface.text(16 * k, weight: 600) : Typeface.display(22, on: stage))
                    .displayLeading(22 * k, 1.12)
                    .foregroundStyle(card.used ? Palette.ink3 : Palette.ink)
                    .strikethrough(card.used, color: Palette.ink3)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: stage.isArena ? 240 * k : .infinity, alignment: .leading)
        }
        .padding(.leading, 14 * k)
        .padding(.trailing, Metrics.s4 * k)
        .padding(.vertical, Metrics.s3 * k)
        .fixedSize(horizontal: false, vertical: true)
        .paper(card.used ? Palette.paper2 : Palette.paper, radius: Metrics.radiusM * k, lifted: raised)
        .overlay {
            RoundedRectangle(cornerRadius: Metrics.radiusM * k, style: .continuous)
                .strokeBorder(Palette.accent, lineWidth: raised ? 1.5 * k : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusM * k, style: .continuous).inset(by: -40))
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
        case .epithet: Palette.wine
        case .kenning: Palette.sea
        case .halfLine: Palette.gold
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
