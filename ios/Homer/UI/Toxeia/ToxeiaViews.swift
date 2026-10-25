import SwiftUI

// Toxeia, the archery: one archer holds two phones. The bow phone is held out at
// arm's length and aims; the arrow phone is nocked, drawn back toward the face,
// and let go. Each phone says what it is in huge type, so they're never mixed
// up: the BOW is black with a gold bow, the ARROW is cream with a black arrow.
// Painted like the Stadion and the fight: black-figure pottery, matte. Props in;
// the iOS lead's archery session fills them.

enum ArcheryRole: Equatable {
    case bow, arrow
}

/// Where an arrow struck the target face, in face units from the center (1 is the
/// outer rim, y up; a miss lies beyond it), and what it scored: 10 in the gold down
/// to 1 at the rim (the module's ring = 10 − floor(r / 0.1)), 0 off the face.
struct ArcheryShot: Equatable {
    var x: Double
    var y: Double
    var score: Int
}

/// The wind on this arrow: its speed, and the way it blows on the target face
/// (degrees, 0 to the right, 90 up). It pushes the arrow sideways.
struct ArcheryWind: Equatable {
    var speed: Double
    var toward: Double
}

// MARK: - The bow

struct BowModel: Equatable {
    enum Phase: Equatable {
        /// Before your first arrow: the big BOW screen, and Ready (the aim is zeroed there).
        case role
        /// Between archers: pass both phones on. The next archer types their name here.
        case passing(next: String?)
        /// Your arrows: aim.
        case aiming
        /// Someone else is shooting, or the room isn't ready; an optional line.
        case waiting(String?)
    }

    var phase: Phase = .role
    var archer: PoetPlate?
    /// Where the phone points, −1…1 each way, as in boxing: ±1 is ±1 m at the
    /// target, ±1.64 face radii (the face is 0.61 m). The point of aim, not the landing.
    var yaw: Double = 0
    var pitch: Double = 0
    /// Arrows loosed this turn, of `arrows`.
    var shot: Int = 0
    var arrows: Int = 3
    var wind: ArcheryWind?
    var lastShot: ArcheryShot?
    /// Your total so far.
    var total: Int?
}

struct BowActions {
    /// "Ready": the archer holds the bow at the target and the aim is zeroed.
    var ready: (() -> Void)?
    /// The next archer's name; "" means that's everyone (the event goes to its finale).
    var setName: ((String) -> Void)?
    var back: (() -> Void)?
}

struct BowView: View {
    let model: BowModel
    var actions = BowActions()

    @State private var name = ""
    @FocusState private var naming: Bool

    var body: some View {
        ZStack {
            StadionPalette.figure.ignoresSafeArea()
            VStack(spacing: Metrics.s4) {
                MeanderBand().stroke(StadionPalette.gold, lineWidth: 2.5).frame(height: 14).padding(.horizontal, 6)
                HStack {
                    if let back = actions.back { BackButton(action: back).tint(StadionPalette.slip) }
                    Text("Toxeia · Archery").tracked(10, color: StadionPalette.slip.opacity(0.7))
                    Spacer()
                    if model.phase == .aiming, let total = model.total {
                        Text("\(total)").font(Typeface.display(26, weight: 800)).foregroundStyle(StadionPalette.gold)
                    }
                }
                .padding(.horizontal, Metrics.s4)
                stage
                    .frame(maxHeight: .infinity)
                MeanderBand().stroke(StadionPalette.gold, lineWidth: 2.5).frame(height: 14).padding(.horizontal, 6)
            }
            .padding(.vertical, Metrics.s2)
        }
        .animation(Motion.slide, value: model.phase)
    }

    @ViewBuilder
    private var stage: some View {
        switch model.phase {
        case .role:
            VStack(spacing: Metrics.s5) {
                RoleMark(role: .bow)
                Text("Hold me out at arm's length, point at the target.")
                    .font(Typeface.text(19, weight: 600))
                    .foregroundStyle(StadionPalette.slip)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.s6)
                Spacer(minLength: 0)
                readyButton("Ready")
            }
        case .passing(let next):
            VStack(spacing: Metrics.s5) {
                PassMark(role: .bow)
                VStack(alignment: .leading, spacing: Metrics.s2) {
                    Text("Next archer").tracked(10, color: StadionPalette.slip.opacity(0.7))
                    TextField("", text: $name, prompt: Text("Your name").foregroundStyle(StadionPalette.slip.opacity(0.45)))
                        .font(Typeface.display(28, weight: 700))
                        .foregroundStyle(StadionPalette.slip)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($naming)
                        .padding(.horizontal, Metrics.s4)
                        .padding(.vertical, Metrics.s3)
                        .overlay(RoundedRectangle(cornerRadius: Metrics.radiusM, style: .continuous)
                            .strokeBorder(StadionPalette.gold, lineWidth: 2))
                        .onSubmit(commitName)
                }
                .padding(.horizontal, Metrics.s5)
                Spacer(minLength: 0)
                let typed = name.trimmingCharacters(in: .whitespaces)
                // A name is needed to go on: an empty Ready never ends the event by accident.
                readyButton(typed.isEmpty ? "Type a name" : "I'm up: \(typed)", enabled: !typed.isEmpty)
                if let setName = actions.setName {
                    Button("That's everyone") {
                        naming = false
                        setName("")
                    }
                    .font(Typeface.text(17, weight: 700))
                    .foregroundStyle(StadionPalette.slip.opacity(0.8))
                    .padding(.vertical, Metrics.s2)
                    .accessibilityHint("Ends the archery and goes to the results")
                }
            }
            .onAppear { name = next ?? "" }
        case .aiming:
            VStack(spacing: Metrics.s4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(model.archer?.name ?? "Your arrows")
                        .font(Typeface.display(24, weight: 700))
                        .foregroundStyle(StadionPalette.slip)
                    Spacer()
                    ArrowCount(shot: model.shot, of: model.arrows, ink: StadionPalette.gold)
                }
                .padding(.horizontal, Metrics.s5)
                TargetFace(lastShot: model.lastShot, aim: CGPoint(x: model.yaw, y: model.pitch))
                    .padding(.horizontal, Metrics.s5)
                HStack {
                    if let wind = model.wind { WindChip(wind: wind, ink: StadionPalette.slip) }
                    Spacer()
                    if let shot = model.lastShot {
                        Text("Last: \(shot.score)")
                            .font(Typeface.display(22, weight: 800))
                            .foregroundStyle(StadionPalette.gold)
                    }
                }
                .padding(.horizontal, Metrics.s5)
                Text("Keep the circle on the gold. Your other hand draws the arrow.")
                    .font(Typeface.text(15, weight: 600))
                    .foregroundStyle(StadionPalette.slip.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.s6)
            }
        case .waiting(let line):
            VStack(spacing: Metrics.s4) {
                RoleMark(role: .bow, compact: true)
                Text(line ?? "Wait for your turn.")
                    .font(Typeface.text(18, weight: 600))
                    .foregroundStyle(StadionPalette.slip)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.s6)
                if let total = model.total {
                    Text("Your total · \(total)").chip(12, fill: StadionPalette.gold, color: StadionPalette.figure)
                }
            }
        }
    }

    private func commitName() {
        let n = name.trimmingCharacters(in: .whitespaces)
        if !n.isEmpty { actions.setName?(n) }
    }

    private func readyButton(_ title: String, enabled: Bool = true) -> some View {
        Button {
            commitName()
            naming = false
            actions.ready?()
        } label: {
            Text(title)
                .font(Typeface.display(30, weight: 800))
                .foregroundStyle(StadionPalette.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, minHeight: 76)
                .background(StadionPalette.gold, in: RoundedRectangle(cornerRadius: Metrics.radiusL, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Metrics.s5)
        .disabled(actions.ready == nil || !enabled)
        .opacity(enabled ? 1 : 0.5)
    }
}

// MARK: - The arrow

struct ArrowModel: Equatable {
    enum Phase: Equatable {
        /// Before your first arrow: the big ARROW screen.
        case role
        /// Between archers: pass both phones on.
        case passing
        /// Your arrows: hold to nock, pull back, let go.
        case drawing
        /// Someone else is shooting, or the room isn't ready; an optional line.
        case waiting(String?)
    }

    var phase: Phase = .role
    /// The thumb is down on the pad.
    var nocked = false
    /// 0…1: the iOS lead computes it from the pull back and the hold.
    var draw: Double = 0
    var shot: Int = 0
    var arrows: Int = 3
    var lastScore: Int?
    var total: Int?
}

struct ArrowActions {
    /// true when the thumb goes down on the pad (nock), false when it lifts (loose).
    var nock: ((Bool) -> Void)?
    var back: (() -> Void)?
}

struct ArrowView: View {
    let model: ArrowModel
    var actions = ArrowActions()

    @State private var down = false

    var body: some View {
        ZStack {
            StadionPalette.slip.ignoresSafeArea()
            VStack(spacing: Metrics.s4) {
                MeanderBand().stroke(StadionPalette.figure, lineWidth: 2.5).frame(height: 14).padding(.horizontal, 6)
                HStack {
                    if let back = actions.back { BackButton(action: back) }
                    Text("Toxeia · Archery").tracked(10, color: StadionPalette.figure.opacity(0.7))
                    Spacer()
                    if model.phase == .drawing, let total = model.total {
                        Text("\(total)").font(Typeface.display(26, weight: 800)).foregroundStyle(StadionPalette.clayDeep)
                    }
                }
                .padding(.horizontal, Metrics.s4)
                stage
                    .frame(maxHeight: .infinity)
                MeanderBand().stroke(StadionPalette.figure, lineWidth: 2.5).frame(height: 14).padding(.horizontal, 6)
            }
            .padding(.vertical, Metrics.s2)
        }
        .animation(Motion.slide, value: model.phase)
    }

    @ViewBuilder
    private var stage: some View {
        switch model.phase {
        case .role:
            VStack(spacing: Metrics.s5) {
                RoleMark(role: .arrow)
                Text("Hold the button to nock, pull back toward your face, let go to shoot.")
                    .font(Typeface.text(19, weight: 600))
                    .foregroundStyle(StadionPalette.figure)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.s6)
            }
        case .passing:
            PassMark(role: .arrow)
        case .drawing:
            VStack(spacing: Metrics.s4) {
                HStack {
                    ArrowCount(shot: model.shot, of: model.arrows, ink: StadionPalette.figure)
                    Spacer()
                    if let score = model.lastScore {
                        Text("Last: \(score)")
                            .font(Typeface.display(22, weight: 800))
                            .foregroundStyle(StadionPalette.clayDeep)
                    }
                }
                .padding(.horizontal, Metrics.s5)
                DrawMeter(draw: model.draw, nocked: model.nocked)
                    .padding(.horizontal, Metrics.s5)
                holdPad
                    .padding(.horizontal, Metrics.s4)
            }
        case .waiting(let line):
            VStack(spacing: Metrics.s4) {
                RoleMark(role: .arrow, compact: true)
                Text(line ?? "Wait for your turn.")
                    .font(Typeface.text(18, weight: 600))
                    .foregroundStyle(StadionPalette.figure)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.s6)
                if let total = model.total {
                    Text("Your total · \(total)").chip(12, fill: StadionPalette.figure, color: StadionPalette.slip)
                }
            }
        }
    }

    /// The whole lower screen is the nocking point: thumb down to nock, pull the
    /// phone back toward your face, lift to loose.
    private var holdPad: some View {
        let nocked = model.nocked
        return VStack(spacing: Metrics.s2) {
            ArrowGlyph()
                .fill(nocked ? StadionPalette.slip : StadionPalette.figure)
                .frame(width: 170, height: 44)
                .rotationEffect(.degrees(nocked ? 90 : 0))
                .offset(y: nocked ? CGFloat(model.draw) * 40 : 0)
            Text(nocked ? (model.draw >= 0.85 ? "Full draw. Let go!" : "Pull back…") : "Hold to nock")
                .font(Typeface.display(30, weight: 800))
                .foregroundStyle(nocked ? StadionPalette.slip : StadionPalette.figure)
            Text(nocked ? "Let go to shoot" : "Then pull the phone back toward your face")
                .font(Typeface.text(15, weight: 600))
                .foregroundStyle((nocked ? StadionPalette.slip : StadionPalette.figure).opacity(0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(nocked ? StadionPalette.figure : StadionPalette.clay, in: RoundedRectangle(cornerRadius: Metrics.radiusL, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Metrics.radiusL, style: .continuous).strokeBorder(StadionPalette.figure, lineWidth: 3))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !down { down = true; actions.nock?(true) }
                }
                .onEnded { _ in
                    down = false
                    actions.nock?(false)
                }
        )
        .animation(.easeOut(duration: 0.12), value: nocked)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nocked ? "Drawing, \(Int(model.draw * 100)) percent. Let go to shoot." : "Hold to nock the arrow")
        .accessibilityAddTraits(.isButton)
    }
}

/// How far the arrow is drawn: weak (it drops low), good, full. A notched bar
/// like a bowstring's serving, gold when it's a full draw.
private struct DrawMeter: View {
    let draw: Double
    let nocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Draw").tracked(10, color: StadionPalette.figure.opacity(0.75))
                Spacer()
                Text(label).tracked(10, color: StadionPalette.figure)
            }
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Rectangle().fill(StadionPalette.figure)
                    Rectangle()
                        .fill(fill)
                        .frame(width: w * CGFloat(min(1, max(0, draw))))
                    // The zones: weak up to half, full from 85%.
                    ForEach([0.5, 0.85], id: \.self) { mark in
                        Rectangle().fill(StadionPalette.slip.opacity(0.9)).frame(width: 2).offset(x: w * mark)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(StadionPalette.figure, lineWidth: 3))
            }
            .frame(height: 34)
            .animation(.linear(duration: 0.08), value: draw)
        }
        .opacity(nocked || draw > 0 ? 1 : 0.55)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Draw \(Int(draw * 100)) percent, \(label)")
    }

    private var label: String { draw >= 0.85 ? "Full" : draw >= 0.5 ? "Good" : draw > 0 ? "Weak" : "" }
    private var fill: Color { draw >= 0.85 ? StadionPalette.gold : draw >= 0.5 ? StadionPalette.clay : StadionPalette.slip.opacity(0.6) }
}

// MARK: - Shared pieces

/// The role, unmistakable: a huge word and its glyph. The bow is gold on black,
/// the arrow black and vermilion on cream.
private struct RoleMark: View {
    let role: ArcheryRole
    var compact = false

    var body: some View {
        let bow = role == .bow
        let ink = bow ? StadionPalette.slip : StadionPalette.figure
        VStack(spacing: compact ? Metrics.s2 : Metrics.s4) {
            Group {
                if bow {
                    BowGlyph().stroke(StadionPalette.gold, style: StrokeStyle(lineWidth: compact ? 7 : 12, lineCap: .round, lineJoin: .round))
                } else {
                    ArrowGlyph().fill(Palette.vermilion)
                }
            }
            .frame(width: compact ? 120 : 220, height: compact ? 80 : 150)
            Text(bow ? "BOW" : "ARROW")
                .font(Typeface.display(compact ? 54 : 112, weight: 900))
                .foregroundStyle(ink)
                .shadow(color: bow ? .clear : StadionPalette.clay, radius: 0, x: 5, y: 5)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(bow ? "This phone is the bow" : "This phone is the arrow")
                .tracked(12, color: ink.opacity(0.75))
        }
        .accessibilityElement(children: .combine)
    }
}

/// Between archers: both phones go to the next one.
private struct PassMark: View {
    let role: ArcheryRole

    var body: some View {
        let ink = role == .bow ? StadionPalette.slip : StadionPalette.figure
        VStack(spacing: Metrics.s3) {
            RoleMark(role: role, compact: true)
            Text("Pass both phones to the next archer")
                .font(Typeface.display(30, weight: 800))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Metrics.s5)
        }
    }
}

/// Three arrows a turn: filled once loosed.
private struct ArrowCount: View {
    let shot: Int
    let of: Int
    let ink: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(1, of), id: \.self) { i in
                ArrowGlyph()
                    .fill(ink.opacity(i < shot ? 0.3 : 1))
                    .frame(width: 34, height: 10)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 12, height: 34)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(max(0, of - shot)) of \(of) arrows left")
    }
}

/// The target face, as on the big screen: ten rings scored 10 to 1, gold, terracotta,
/// black, cream, deep terracotta, and the meander rim as ring 1. The face takes 60%
/// of the frame, so the aim ring can ride off it as far as the bow can point
/// (±1.64 face radii). The last arrow is a black hole in the face.
private struct TargetFace: View {
    var lastShot: ArcheryShot?
    /// yaw, pitch −1…1 (±1 m at the target).
    var aim: CGPoint

    /// Metres per face radius.
    static let faceRadius = 0.61

    var body: some View {
        GeometryReader { geo in
            let frame = min(geo.size.width, geo.size.height)
            let d = frame * 0.6
            let r = d / 2
            ZStack {
                Circle().fill(StadionPalette.figure).frame(width: d, height: d)
                MeanderRing().stroke(StadionPalette.gold, lineWidth: 1.4).padding(d * 0.012).frame(width: d, height: d)
                ForEach(Array(Self.rings.enumerated()), id: \.offset) { _, ring in
                    Circle().fill(ring.1).frame(width: d * ring.0, height: d * ring.0)
                    Circle().strokeBorder(ring.1 == StadionPalette.figure ? StadionPalette.slip : StadionPalette.figure, lineWidth: 1)
                        .frame(width: d * ring.0, height: d * ring.0)
                }
                if let s = lastShot {
                    Circle().fill(StadionPalette.figure).frame(width: d * 0.05, height: d * 0.05)
                        .overlay(Circle().strokeBorder(StadionPalette.slip, lineWidth: 1.5))
                        .offset(x: face(s.x) * r, y: -face(s.y) * r)
                }
                // The aim: a thin ring with four ticks, white-hot cream on a black keyline.
                ZStack {
                    Circle().stroke(StadionPalette.figure, lineWidth: 6)
                    Circle().stroke(StadionPalette.slip, lineWidth: 3)
                    ForEach(0..<4, id: \.self) { i in
                        Rectangle().fill(StadionPalette.slip).frame(width: 3, height: d * 0.05)
                            .offset(y: -d * 0.1)
                            .rotationEffect(.degrees(Double(i) * 90))
                    }
                }
                .frame(width: d * 0.16, height: d * 0.16)
                .offset(x: face(Double(aim.x) / Self.faceRadius) * r, y: -face(Double(aim.y) / Self.faceRadius) * r)
                .animation(.linear(duration: 0.06), value: aim)
            }
            .frame(width: frame, height: frame)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    /// Face units, kept inside the frame (±1.66 radii).
    private func face(_ v: Double) -> CGFloat { CGFloat(min(1.62, max(-1.62, v))) }

    /// Outer diameter (of the face) and fill, outside in: rings 2 to 10; ring 1 is the rim.
    static let rings: [(CGFloat, Color)] = [
        (0.9, Color(hex: 0xA9532D)), (0.8, StadionPalette.slip), (0.7, StadionPalette.slip),
        (0.6, StadionPalette.figure), (0.5, StadionPalette.figure), (0.4, StadionPalette.clay),
        (0.3, StadionPalette.clay), (0.2, StadionPalette.gold), (0.1, StadionPalette.gold),
    ]
}

/// The wind for this arrow, as GamePigeon shows it: an arrow pointing the way it
/// blows, and the speed.
private struct WindChip: View {
    let wind: ArcheryWind
    let ink: Color

    var body: some View {
        HStack(spacing: Metrics.s2) {
            ArrowGlyph().fill(ink)
                .frame(width: 34, height: 12)
                .rotationEffect(.degrees(-wind.toward))
                .frame(width: 36, height: 36)
            Text(String(format: "%.1f m/s", wind.speed))
                .font(Typeface.display(22, weight: 800))
                .foregroundStyle(ink)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: "Wind %.1f metres a second", wind.speed))
    }
}

/// A Scythian bow, the shape on the pots: two curves meeting at the grip, and the string.
private struct BowGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let top = CGPoint(x: rect.minX + w * 0.5, y: rect.minY)
        let bottom = CGPoint(x: rect.minX + w * 0.5, y: rect.maxY)
        let grip = CGPoint(x: rect.minX + w * 0.66, y: rect.midY)
        p.move(to: top)
        p.addCurve(to: grip, control1: CGPoint(x: rect.minX + w * 0.95, y: rect.minY + h * 0.05), control2: CGPoint(x: rect.minX + w * 0.55, y: rect.minY + h * 0.38))
        p.addCurve(to: bottom, control1: CGPoint(x: rect.minX + w * 0.55, y: rect.minY + h * 0.62), control2: CGPoint(x: rect.minX + w * 0.95, y: rect.maxY - h * 0.05))
        // The string, and an arrow across it.
        p.move(to: top)
        p.addLine(to: CGPoint(x: rect.minX + w * 0.42, y: rect.midY))
        p.addLine(to: bottom)
        p.move(to: CGPoint(x: rect.minX + w * 0.1, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

/// An arrow, pointing right: a leaf head, the shaft, two fletchings.
private struct ArrowGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, mid = rect.midY
        let shaft = max(2, h * 0.16)
        // Shaft.
        p.addRect(CGRect(x: rect.minX + w * 0.12, y: mid - shaft / 2, width: w * 0.68, height: shaft))
        // Head.
        p.move(to: CGPoint(x: rect.maxX, y: mid))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.76, y: rect.minY + h * 0.12))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.8, y: mid))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.76, y: rect.maxY - h * 0.12))
        p.closeSubpath()
        // Fletching.
        for up in [true, false] {
            let y = up ? rect.minY : rect.maxY
            p.move(to: CGPoint(x: rect.minX + w * 0.12, y: mid))
            p.addLine(to: CGPoint(x: rect.minX, y: y))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.1, y: y))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.26, y: mid))
            p.closeSubpath()
        }
        return p
    }
}

/// A meander running round a circle: the target's rim.
private struct MeanderRing: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOut = min(rect.width, rect.height) / 2
        let band = rOut * 0.07
        let rIn = rOut - band
        let n = 36
        func pt(_ r: CGFloat, _ a: Double) -> CGPoint { CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)) }
        for i in 0..<n {
            let a0 = Double(i) / Double(n) * 2 * .pi
            let step = 2 * Double.pi / Double(n)
            // One key: up the outer edge, across, down, and a hook back.
            p.move(to: pt(rIn, a0))
            p.addLine(to: pt(rOut, a0))
            p.addLine(to: pt(rOut, a0 + step * 0.75))
            p.addLine(to: pt(rIn + band * 0.35, a0 + step * 0.75))
            p.addLine(to: pt(rIn + band * 0.35, a0 + step * 0.35))
            p.addLine(to: pt(rIn + band * 0.65, a0 + step * 0.35))
            p.move(to: pt(rIn, a0))
            p.addLine(to: pt(rIn, a0 + step))
        }
        return p
    }
}

#Preview("Bow · role") {
    BowView(model: BowModel(phase: .role), actions: BowActions(ready: {}))
}

#Preview("Bow · aiming") {
    BowView(model: BowModel(phase: .aiming, archer: PoetPlate(id: "1", name: "Ada", epithet: "", seat: 0), yaw: 0.18, pitch: -0.1, shot: 1,
                            wind: ArcheryWind(speed: 3.2, toward: 20), lastShot: ArcheryShot(x: -0.2, y: 0.12, score: 8), total: 8))
}

#Preview("Arrow · drawing") {
    ArrowView(model: ArrowModel(phase: .drawing, nocked: true, draw: 0.7, shot: 1, lastScore: 8, total: 8))
}
