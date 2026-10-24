import SwiftUI

enum HomerMode: String, CaseIterable, Identifiable {
    case bard
    case judge
    case battle

    var id: Self { self }

    var title: String {
        switch self {
        case .bard: "Learn with Homer"
        case .judge: "Judge My Verse"
        case .battle: "Poetry Battle"
        }
    }

    var subtitle: String {
        switch self {
        case .bard: "Master meter, one foot at a time"
        case .judge: "Scan a poem and sharpen its craft"
        case .battle: "Gather your poets and test their skill"
        }
    }

    var symbol: String {
        switch self {
        case .bard: "book.closed.fill"
        case .judge: "text.magnifyingglass"
        case .battle: "laurel.leading"
        }
    }
}

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header

                        VStack(spacing: 14) {
                            ForEach(HomerMode.allCases) { mode in
                                NavigationLink(value: mode) {
                                    ModeCard(mode: mode)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                }
            }
            .tint(.orange)
            .navigationDestination(for: HomerMode.self) { mode in
                ModePlaceholderView(mode: mode)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOMER")
                .font(.caption.weight(.semibold))
                .tracking(3)
                .foregroundStyle(.orange)

            Text("Choose your path,\nswift-fingered poet.")
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(.primary)

            Text("Learn the music of iambic pentameter, refine your verse, or challenge worthy rivals.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ModeCard: View {
    let mode: HomerMode

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: mode.symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.orange)
                .frame(width: 48, height: 48)
                .background(.orange.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(mode.title)")
    }
}

private struct ModePlaceholderView: View {
    let mode: HomerMode

    var body: some View {
        ContentUnavailableView(
            mode.title,
            systemImage: mode.symbol,
            description: Text("This voyage is the next screen to build.")
        )
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainMenuView()
}
