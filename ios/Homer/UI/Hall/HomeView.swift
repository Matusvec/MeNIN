import SwiftUI

/// The home screen ("Atelier"), built from Matus's concept frame "Homer · Atelier"
/// (Figma node 46:378): a greeting with Homer's portrait, the lesson to resume
/// on a hero card, the three modes, and the hoard. Props in, no logic; the scene
/// rests behind it.
struct HomeView: View {
    struct Lesson: Equatable {
        var path: String       // "Bard / Lesson 02"
        var title: String      // "The formula"
        var meta: String       // "Four-beat line · 4 min"
        var progress: Double   // 0...1
    }

    struct Mode: Identifiable, Equatable {
        var id: String
        var icon: String       // asset name in Art.xcassets
        var name: String
        var purpose: String
    }

    var name: String
    var greeting: String = "A little verse,\na little further."
    var lesson: Lesson?
    var modes: [Mode] = Mode.spec
    var collectionTitle: String = "Your hoard"
    var collectionSummary: String
    var initial: String? = nil
    var onResume: (() -> Void)? = nil
    var onMode: ((Mode) -> Void)? = nil
    var onCollection: (() -> Void)? = nil
    var onProfile: (() -> Void)? = nil
    /// The back chevron: out to the hall.
    var onBack: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                navigation
                welcome
                VStack(alignment: .leading, spacing: 24) {
                    if let lesson { LessonCard(lesson: lesson, onResume: onResume) }
                    modeList
                    collection
                }
                .padding(.horizontal, Metrics.margin)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .scrollIndicators(.hidden)
    }

    // Figma 46:386: wordmark left, avatar right; 58 tall.
    private var navigation: some View {
        HStack(spacing: Metrics.s2) {
            if let onBack { BackButton(action: onBack) }
            // On paper, like every word over the scene.
            WordmarkView(size: 24)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .paper(Palette.paper, radius: 100, lifted: false)
            Spacer()
            Button { onProfile?() } label: {
                Text(initial ?? String(name.prefix(1)))
                    .font(Typeface.display(19))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 35, height: 35)
                    .background(Circle().fill(Palette.paper))
                    .overlay(Circle().strokeBorder(Palette.line, lineWidth: 1))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, Metrics.margin)
        .frame(height: 58)
    }

    // Figma 46:393: greeting and title left, portrait right; 126 tall.
    private var welcome: some View {
        HStack(alignment: .center, spacing: 4) {
            VStack(alignment: .leading, spacing: 9) {
                Text("Welcome back, \(name).")
                    .font(Typeface.text(13))
                    .foregroundStyle(Palette.onPage2)
                LeadedText(text: greeting, font: Typeface.display(31), size: 31, leading: 1.12)
                    .foregroundStyle(Palette.onPage)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image("homer-portrait")
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusS, style: .continuous))
                .accessibilityLabel("Homer")
        }
        .padding(Metrics.s4)
        .paper(radius: Metrics.radiusL)
        .padding(.horizontal, Metrics.margin)
        .padding(.top, 6)
    }

    // Figma 46:412: heading, then rows 68 tall, 8 apart.
    private var modeList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose your mode").chip(11)
            VStack(spacing: 8) {
                ForEach(modes) { mode in
                    Button { onMode?(mode) } label: { ModeRowView(mode: mode) }
                        .buttonStyle(RowPress())
                }
            }
        }
    }

    // Figma 46:438: hairline above, book icon, title and summary, arrow.
    private var collection: some View {
        Button { onCollection?() } label: {
            HStack(spacing: 14) {
                Image("icon-book-open").renderingMode(.template).resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Palette.brand)
                    .frame(width: 36, height: 44)
                VStack(alignment: .leading, spacing: 5) {
                    Text(collectionTitle).font(Typeface.display(22)).foregroundStyle(Palette.onPage)
                    Text(collectionSummary).font(Typeface.text(12)).foregroundStyle(Palette.onPage2)
                }
                Spacer(minLength: 0)
                Image("icon-arrow-up-right").renderingMode(.template).resizable()
                    .frame(width: 19, height: 19)
                    .foregroundStyle(Palette.brand)
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
            .padding(.horizontal, Metrics.s3)
            .padding(.vertical, Metrics.s2)
            .paper(radius: Metrics.radiusM)
        }
        .buttonStyle(RowPress())
    }
}

extension HomeView.Mode {
    /// The spec's three modes: learn, train, fight.
    static let spec: [HomeView.Mode] = [
        .init(id: "bard", icon: "icon-feather", name: "Bard", purpose: "Lessons in the four-beat line"),
        .init(id: "practice", icon: "icon-scan-text", name: "Practice", purpose: "Spar with Homer, full judge breakdown"),
        .init(id: "battle", icon: "icon-swords", name: "Battle", purpose: "The Agon: up to five poets, one screen"),
    ]
}

// Figma 46:399: the hero card, 190 tall, 20 padding.
private struct LessonCard: View {
    let lesson: HomeView.Lesson
    var onResume: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(lesson.path.replacingOccurrences(of: " / ", with: "  /  "))
                    .font(Typeface.label(10))
                    .tracking(0.6)
                    .textCase(.uppercase)
                Spacer()
                Text("Continue learning").font(Typeface.text(11))
            }
            .foregroundStyle(Palette.onHero2)
            LeadedText(text: lesson.title, font: Typeface.display(27), size: 27, leading: 1.1)
                .foregroundStyle(Palette.onHero)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(lesson.meta).font(Typeface.text(11)).foregroundStyle(Palette.onHero2)
                    Capsule().fill(Palette.onHero2.opacity(0.25))
                        .frame(width: 126, height: 3)
                        .overlay(alignment: .leading) {
                            Capsule().fill(Palette.onHero2).frame(width: 126 * min(1, max(0, lesson.progress)), height: 3)
                        }
                }
                Spacer()
                Button { onResume?() } label: { ArrowLabel(title: "Resume") }
                    .buttonStyle(HomerButtonStyle(kind: .cream))
                    .font(Typeface.text(13, weight: 600))
            }
        }
        .padding(20)
        .frame(height: 190)
        .paper(Palette.hero, radius: Metrics.radiusL, lifted: false)
    }
}

// Figma 46:417: a mode entry.
private struct ModeRowView: View {
    let mode: HomeView.Mode

    var body: some View {
        HStack(spacing: 14) {
            Image(mode.icon).renderingMode(.template).resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Palette.accent)
                .frame(width: 36, height: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(mode.name).font(Typeface.display(22)).foregroundStyle(Palette.ink)
                Text(mode.purpose).font(Typeface.text(12)).foregroundStyle(Palette.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image("icon-chevron-right").renderingMode(.template).resizable()
                .frame(width: 17, height: 17)
                .foregroundStyle(Palette.ink2)
        }
        .padding(.leading, 14)
        .padding(.trailing, 16)
        .frame(height: 68)
        .paper(Palette.paper, radius: Metrics.radiusM, lifted: false)
        .contentShape(Rectangle())
    }
}

private struct RowPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(Motion.fade, value: configuration.isPressed)
    }
}

/// Figma 46:446: the tab bar. Two tabs; the selected one is set in the accent.
struct HomeTabBar: View {
    struct Tab: Identifiable, Equatable {
        var id: String
        var icon: String
        var title: String
    }

    var tabs: [Tab] = [
        Tab(id: "atelier", icon: "icon-feather-tab", title: "Atelier"),
        Tab(id: "hoard", icon: "icon-library", title: "Hoard"),
    ]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 100) {
            ForEach(tabs) { tab in
                let on = tab.id == selection
                Button { selection = tab.id } label: {
                    VStack(spacing: 4) {
                        Image(tab.icon).renderingMode(.template).resizable().frame(width: 23, height: 23)
                        Text(tab.title).font(Typeface.text(10, weight: on ? 600 : 500))
                    }
                    .foregroundStyle(on ? Palette.accent : Palette.ink2)
                    .frame(width: 72)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        .background {
            Palette.paper
                .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    @Previewable @State var tab = "atelier"
    ZStack(alignment: .bottom) {
        Palette.page.ignoresSafeArea()
        HomeView(name: "Alex",
                 lesson: .init(path: "Bard / Lesson 02", title: "The formula,\nhalf a line for free", meta: "Four-beat line · 4 min", progress: 0.6),
                 collectionSummary: "12 formulas · 2 battles · Herald")
        HomeTabBar(selection: $tab)
    }
}
