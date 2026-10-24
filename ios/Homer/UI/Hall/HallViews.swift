import SwiftUI

// The hall: MeNIN's front door. The wordmark, the first-open moment, the
// event menu (ancient Greek Wii Sports), and the hosts. Props in, no logic.

// MARK: - Wordmark

/// MeNIN, the first word of the Iliad: μῆνιν, rage.
struct WordmarkView: View {
    var size: CGFloat = 31
    var showsGreek: Bool = false
    var color: Color = Palette.brand

    var body: some View {
        VStack(alignment: .leading, spacing: size * 0.06) {
            HStack(spacing: size * 0.29) {
                Image("icon-feather-nav").renderingMode(.template).resizable()
                    .frame(width: size * 0.74, height: size * 0.74)
                Text("MeNIN")
                    .font(Typeface.display(size))
            }
            .foregroundStyle(color)
            if showsGreek {
                Text("μῆνιν · rage")
                    .font(.system(size: size * 0.24, weight: .regular, design: .serif).italic())
                    .foregroundStyle(color.opacity(0.75))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("MeNIN")
    }
}

// MARK: - First open

/// The first launch only: Homer speaks before any menu, you give him one line,
/// the scene answers your voice, and he hands you to the event menu.
struct FirstOpenView: View {
    enum Beat { case homerSpeaks, listening, homerAnswers }

    let beat: Beat
    /// What Homer is saying now, and how far his voice has got through it.
    var caption: String
    var spoken: Double = 1
    /// What Homer heard you say.
    var heard: String = ""
    var level: Double = 0

    var body: some View {
        VStack(spacing: Metrics.s5) {
            Spacer()
            if beat == .listening {
                VStack(spacing: Metrics.s4) {
                    MicLevelView(level: level, tint: Palette.onHero)
                        .padding(.horizontal, Metrics.s5)
                        .padding(.vertical, Metrics.s3)
                        .background(Capsule().fill(Palette.hero))
                    if !heard.isEmpty {
                        TranscriptView(lines: [heard], listening: true, maxLines: 1)
                            .transition(.opacity)
                    } else {
                        Text("Say anything").chip(12)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            CaptionView(text: caption, spoken: spoken)
                .id(caption)
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            Spacer().frame(height: Metrics.s7)
        }
        .padding(.horizontal, Metrics.s4)
        .animation(Motion.slide, value: beat)
        .animation(Motion.slide, value: caption)
    }
}

// MARK: - Hosts

enum EventHost: String, Sendable {
    case homer, socrates

    var name: String { self == .homer ? "Homer" : "Socrates" }
    var greek: String { self == .homer ? "ΟΜΗΡΟΣ" : "ΣΩΚΡΑΤΗΣ" }
    var ink: Color { self == .homer ? Palette.wine : Palette.olive }
}

/// A host's medallion, struck like an ancient coin: name around the rim in
/// Greek capitals, an emblem in the field. Homer's is the lyre; Socrates' is
/// the question.
struct HostMedallion: View {
    let host: EventHost
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle().fill(host.ink)
            Circle().strokeBorder(Palette.cream.opacity(0.9), lineWidth: size * 0.018).padding(size * 0.05)
            Circle().strokeBorder(Palette.cream.opacity(0.35), lineWidth: size * 0.01).padding(size * 0.2)
            RimText(text: host.greek, radius: size * 0.36, fontSize: size * 0.1)
                .foregroundStyle(Palette.cream)
            Group {
                switch host {
                case .homer:
                    LyreShape()
                        .stroke(Palette.gold, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round, lineJoin: .round))
                        .frame(width: size * 0.3, height: size * 0.34)
                case .socrates:
                    Text("?")
                        .font(Typeface.display(size * 0.44, weight: 600))
                        .foregroundStyle(Palette.gold)
                        .offset(y: -size * 0.01)
                }
            }
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: size * 0.015)
        .shadow(color: Color(hex: 0x0E0814).opacity(0.3), radius: size * 0.12, x: 0, y: size * 0.07)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(host.name)
    }
}

/// Letters set around a circle, top-centered, like a coin legend.
private struct RimText: View {
    let text: String
    let radius: CGFloat
    let fontSize: CGFloat

    var body: some View {
        let letters = Array(text)
        let step = Double(fontSize) * 1.05 / Double(radius) // radians per letter
        let start = -step * Double(letters.count - 1) / 2
        ZStack {
            ForEach(Array(letters.enumerated()), id: \.offset) { i, ch in
                let a = start + step * Double(i)
                Text(String(ch))
                    .font(.system(size: fontSize, weight: .semibold, design: .serif))
                    .rotationEffect(.radians(a))
                    .offset(x: radius * sin(a), y: -radius * cos(a))
            }
        }
    }
}

/// A lyre: two horned arms, a crossbar, a sound box and strings.
struct LyreShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width
        let h = r.height
        // Arms.
        p.move(to: CGPoint(x: r.minX + w * 0.28, y: r.maxY - h * 0.12))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.05, y: r.minY + h * 0.05),
                   control1: CGPoint(x: r.minX - w * 0.1, y: r.maxY - h * 0.4),
                   control2: CGPoint(x: r.minX + w * 0.3, y: r.minY + h * 0.3))
        p.move(to: CGPoint(x: r.maxX - w * 0.28, y: r.maxY - h * 0.12))
        p.addCurve(to: CGPoint(x: r.maxX - w * 0.05, y: r.minY + h * 0.05),
                   control1: CGPoint(x: r.maxX + w * 0.1, y: r.maxY - h * 0.4),
                   control2: CGPoint(x: r.maxX - w * 0.3, y: r.minY + h * 0.3))
        // Crossbar.
        p.move(to: CGPoint(x: r.minX + w * 0.12, y: r.minY + h * 0.2))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.12, y: r.minY + h * 0.2))
        // Sound box.
        p.addRoundedRect(in: CGRect(x: r.minX + w * 0.22, y: r.maxY - h * 0.16, width: w * 0.56, height: h * 0.16),
                         cornerSize: CGSize(width: w * 0.08, height: w * 0.08))
        // Strings.
        for i in 0..<4 {
            let x = r.minX + w * (0.36 + 0.093 * Double(i))
            p.move(to: CGPoint(x: x, y: r.minY + h * 0.2))
            p.addLine(to: CGPoint(x: x, y: r.maxY - h * 0.16))
        }
        return p
    }
}

// MARK: - Event menu

/// One event on the menu.
struct EventTile: Identifiable, Equatable {
    enum Art: Equatable { case lyre, debate, discus, chariot, wrestling, torch }

    var id: String
    var title: String
    var host: EventHost?
    var blurb: String
    var art: Art
    var locked: Bool = false
}

extension EventTile {
    /// The playable event this tile starts; nil for a locked tile.
    var kind: EventKind? { locked ? nil : EventKind(rawValue: id) }

    /// The events in the spec, in menu order. Locked tiles are the future.
    static let all: [EventTile] = [
        EventTile(id: "poetry", title: "Poetry Battle", host: .homer, blurb: "Improvise verse over the beat", art: .lyre),
        EventTile(id: "debate", title: "Socratic Debate", host: .socrates, blurb: "Argue it out, one move at a time", art: .debate),
        EventTile(id: "discus", title: "Discus", host: .homer, blurb: "Swing your phone. Let it fly", art: .discus),
        EventTile(id: "chariot", title: "Chariot Race", host: nil, blurb: "", art: .chariot, locked: true),
        EventTile(id: "pankration", title: "Pankration", host: nil, blurb: "", art: .wrestling, locked: true),
        EventTile(id: "torch", title: "Torch Relay", host: nil, blurb: "", art: .torch, locked: true),
    ]
}

/// Ancient Greek Wii Sports: chunky tiles, one color field each, cut-paper art.
struct EventMenuView: View {
    var events: [EventTile] = EventTile.all
    var onPick: ((EventTile) -> Void)? = nil
    /// Shown on the arena while phones are joined: "4 poets in the hall".
    var hallNote: String? = nil
    /// The wordmark row; off when the screen already has a top bar (the arena hall).
    var showsHeader: Bool = true

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(alignment: .leading, spacing: Metrics.s5 * k) {
            if showsHeader {
                HStack(alignment: .bottom) {
                    WordmarkView(size: 31 * k)
                    Spacer()
                    if let hallNote { Text(hallNote).chip(11 * k) }
                }
            }
            Text("Choose your event").chip(11 * k)
            if stage.isArena { arenaLayout } else { phoneLayout }
        }
    }

    /// Phone: a two-column grid of every tile.
    private var phoneLayout: some View {
        let k = stage.scale
        let columns = [GridItem(.adaptive(minimum: 150 * k, maximum: 300 * k), spacing: Metrics.s4 * k)]
        return LazyVGrid(columns: columns, spacing: Metrics.s4 * k) {
            ForEach(events) { tile($0) }
        }
    }

    /// Arena: the live events as big equal tiles, the future as a quiet row of "soon".
    private var arenaLayout: some View {
        let k = stage.scale
        let live = events.filter { !$0.locked }
        let soon = events.filter(\.locked)
        return VStack(alignment: .leading, spacing: Metrics.s4 * k) {
            HStack(alignment: .top, spacing: Metrics.s4 * k) {
                ForEach(live) { tile($0).frame(maxWidth: .infinity) }
            }
            if !soon.isEmpty {
                HStack(spacing: Metrics.s2 * k) {
                    Text("Soon").tracked(10 * k, color: Palette.ink2)
                    ForEach(soon) { Text($0.title).chip(10 * k, fill: Palette.paper2, color: Palette.ink3) }
                }
                .padding(.horizontal, Metrics.s3 * k)
                .padding(.vertical, Metrics.s2 * k)
                .paper(Palette.paper, radius: 100, lifted: false)
            }
        }
    }

    private func tile(_ event: EventTile) -> some View {
        Button { onPick?(event) } label: { EventTileView(event: event) }
            .buttonStyle(TilePress())
            .disabled(event.locked || onPick == nil)
    }
}

private struct TilePress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Motion.stamp, value: configuration.isPressed)
    }
}

struct EventTileView: View {
    let event: EventTile
    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Rectangle().fill(field)
                EventArtView(art: event.art, ink: artInk, accent: accent)
                    .padding(Metrics.s5 * k)
                    .opacity(event.locked ? 0.35 : 1)
                if event.locked {
                    Text("Soon").chip(10 * k)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(Metrics.s3 * k)
                }
            }
            // Arena tiles: full-width art at a set height; phone tiles nearly square.
            .modifier(TileArtSize(arenaHeight: stage.isArena ? 118 * k : nil))
            .clipped()
            VStack(alignment: .leading, spacing: 2 * k) {
                Text(event.title)
                    .font(Typeface.display(22 * k))
                    .foregroundStyle(event.locked ? Palette.ink3 : Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(event.host.map { "Hosted by \($0.name)" } ?? "Locked")
                    .font(Typeface.text(12 * k))
                    .foregroundStyle(Palette.ink2)
            }
            .padding(.horizontal, Metrics.s4 * k)
            .padding(.vertical, Metrics.s3 * k)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(event.locked ? Palette.paper2 : Palette.paper, radius: Metrics.radiusL * k)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusL * k, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint(event.locked ? "Coming soon" : event.blurb)
    }

    private var field: Color {
        if event.locked { return Palette.paper3 }
        switch event.art {
        case .lyre: return Palette.wine
        case .debate: return Palette.olive
        case .discus: return Palette.vermilion
        default: return Palette.paper3
        }
    }

    private var artInk: Color { event.locked ? Palette.ink2 : Palette.cream }
    private var accent: Color { event.locked ? Palette.ink3 : Palette.gold }
}

private struct TileArtSize: ViewModifier {
    let arenaHeight: CGFloat?

    func body(content: Content) -> some View {
        if let arenaHeight {
            content.frame(maxWidth: .infinity).frame(height: arenaHeight)
        } else {
            content.aspectRatio(1.25, contentMode: .fit)
        }
    }
}

/// Cut-paper emblems for the event tiles.
struct EventArtView: View {
    let art: EventTile.Art
    var ink: Color = Palette.paper
    var accent: Color = Palette.gold

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                switch art {
                case .lyre:
                    LyreShape()
                        .stroke(ink, style: StrokeStyle(lineWidth: s * 0.06, lineCap: .round, lineJoin: .round))
                        .frame(width: s * 0.62, height: s * 0.74)
                case .debate:
                    // Two voices: facing speech slips, one paper, one gold.
                    SpeechSlip().fill(ink).frame(width: s * 0.62, height: s * 0.42).offset(x: -s * 0.14, y: -s * 0.14)
                    SpeechSlip().fill(accent).frame(width: s * 0.62, height: s * 0.42)
                        .scaleEffect(x: -1).offset(x: s * 0.16, y: s * 0.16)
                case .discus:
                    Circle().trim(from: 0.55, to: 0.95)
                        .stroke(ink.opacity(0.6), style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round, dash: [s * 0.04, s * 0.05]))
                        .frame(width: s * 1.1, height: s * 0.9)
                        .offset(x: -s * 0.1, y: s * 0.18)
                    DiscusShape(ink: ink, accent: accent).frame(width: s * 0.42, height: s * 0.42).offset(x: s * 0.2, y: -s * 0.12)
                case .chariot:
                    Circle().strokeBorder(ink, lineWidth: s * 0.06).frame(width: s * 0.5)
                    ForEach(0..<4, id: \.self) { i in
                        Rectangle().fill(ink).frame(width: s * 0.04, height: s * 0.46).rotationEffect(.degrees(Double(i) * 45))
                    }
                case .wrestling:
                    Circle().fill(ink).frame(width: s * 0.36).offset(x: -s * 0.13)
                    Circle().fill(accent).frame(width: s * 0.36).offset(x: s * 0.13)
                case .torch:
                    Capsule().fill(ink).frame(width: s * 0.12, height: s * 0.5).offset(y: s * 0.14)
                    Ellipse().fill(accent).frame(width: s * 0.26, height: s * 0.34).offset(y: -s * 0.2)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct SpeechSlip: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(roundedRect: CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height * 0.8),
                     cornerRadius: r.height * 0.22, style: .continuous)
        p.move(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY + r.height * 0.75))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.12, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.38, y: r.minY + r.height * 0.75))
        p.closeSubpath()
        return p
    }
}

/// A discus seen at an angle: a flat disc with a raised hub.
struct DiscusShape: View {
    var ink: Color = Palette.paper
    var accent: Color = Palette.gold

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Ellipse().fill(Palette.ink.opacity(0.25)).frame(width: w, height: w * 0.42).offset(y: w * 0.05)
                Ellipse().fill(ink).frame(width: w, height: w * 0.42)
                Ellipse().strokeBorder(accent, lineWidth: w * 0.035).frame(width: w * 0.62, height: w * 0.26)
                Ellipse().fill(accent).frame(width: w * 0.24, height: w * 0.1)
            }
            .frame(width: w, height: geo.size.height)
        }
    }
}

#Preview("Hall") {
    ZStack {
        Palette.sea.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    HostMedallion(host: .homer)
                    HostMedallion(host: .socrates)
                }
                EventMenuView()
            }
            .padding()
        }
    }
}
