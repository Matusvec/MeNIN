import SwiftUI

/// Debug screen for tuning the scene: emotion sliders, voice sliders, a mic
/// toggle, presets and a scripted tour. Emotion names appear here as slider
/// labels only; product screens never name a feeling in words.
///
/// The iOS lead wires `isMicOn` to the mic; while it is on, the mic writes
/// `driver.prosody` and the voice sliders show the live values.
struct SceneLabView: View {
    let driver: SceneDriver
    @Binding var isMicOn: Bool

    @State private var weights: [Emotion: Double] = [:]
    @State private var energy: Double = 0
    @State private var pitch: Double = 70
    @State private var touring = false
    @State private var showType = true
    @State private var panelOpen = true

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneView(driver: driver)
                .onTapGesture { withAnimation(Motion.slide) { panelOpen.toggle() } }

            if showType { verseSample.allowsHitTesting(false) }

            if panelOpen {
                panel.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            weights = driver.emotion.values
            energy = driver.prosody.energy
            pitch = driver.prosody.pitch ?? 70
        }
        .onChange(of: weights) { driver.emotion = EmotionWeights(weights) }
        .onChange(of: energy) { pushVoice() }
        .onChange(of: pitch) { pushVoice() }
        .task(id: touring) { await tour() }
    }

    // MARK: - Type sample

    private var verseSample: some View {
        VStack(spacing: Metrics.s3) {
            Text("Round one · A ship that never came home")
                .tracked(12, color: Palette.paper)
                .onScene()
            Text("Wine-dark sea / took my brother’s ship")
                .font(Typeface.display(40, weight: 800))
                .multilineTextAlignment(.center)
                .onScene()
        }
        .padding(.horizontal, Metrics.s5)
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.bottom, panelOpen ? 380 : 0)
    }

    // MARK: - Panel

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Scene lab").font(Typeface.display(26, weight: 750))
                Spacer()
                Text("Tap the scene to hide").tracked(10, color: Palette.ink3)
            }
            .padding(.bottom, Metrics.s4)

            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.s5) {
                    HStack(spacing: Metrics.s2) {
                        Toggle("Mic", isOn: $isMicOn).toggleStyle(ChipToggle(tint: Palette.vermilion))
                        Toggle("Verse tour", isOn: $touring).toggleStyle(ChipToggle(tint: Palette.ink))
                        Toggle("Type", isOn: $showType).toggleStyle(ChipToggle(tint: Palette.ink))
                    }

                    section("Voice") {
                        if isMicOn {
                            TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                                LabSlider(label: "energy", value: .constant(driver.prosody.energy), readout: String(format: "%.2f", driver.prosody.energy))
                                LabSlider(label: "pitch", value: .constant(min(1, (driver.prosody.pitch ?? 70) / 400)),
                                          readout: driver.prosody.pitch.map { "\(Int($0)) Hz" } ?? "unvoiced")
                            }
                            .disabled(true)
                        } else {
                            LabSlider(label: "energy", value: $energy, readout: String(format: "%.2f", energy))
                            LabSlider(label: "pitch", value: $pitch, range: 70...400,
                                      readout: pitch <= 70 ? "unvoiced" : "\(Int(pitch)) Hz")
                        }
                    }

                    section("Weights", trailing: sumLabel) {
                        ForEach(Emotion.allCases, id: \.self) { e in
                            LabSlider(label: e.rawValue, value: binding(e), readout: String(format: "%.2f", weights[e] ?? 0),
                                      inks: Mood(e).style.inks)
                        }
                    }

                    section("Presets") {
                        FlowLayout(spacing: Metrics.s2) {
                            ForEach(LabPreset.all) { preset in
                                Button(preset.label) {
                                    touring = false
                                    withAnimation(Motion.fade) { weights = preset.weights }
                                }
                                .buttonStyle(ChipButton())
                            }
                        }
                    }
                }
                .padding(.bottom, Metrics.s6)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Palette.ink)
        .padding(Metrics.s5)
        .frame(maxHeight: 420)
        .paper(radius: Metrics.radiusL)
        .padding(.horizontal, Metrics.s2)
        .padding(.bottom, Metrics.s2)
    }

    private var sumLabel: String {
        let sum = weights.values.reduce(0, +)
        return sum < 1 ? String(format: "Σ %.2f · rest %.2f", sum, 1 - sum) : String(format: "Σ %.2f", sum)
    }

    private func section(_ title: String, trailing: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Metrics.s3) {
            HStack {
                Text(title).tracked(11, color: Palette.ink2)
                Spacer()
                if let trailing { Text(trailing).font(Typeface.numeral(11, weight: 500)).foregroundStyle(Palette.ink3) }
            }
            content()
        }
    }

    private func binding(_ e: Emotion) -> Binding<Double> {
        Binding(get: { weights[e] ?? 0 }, set: { touring = false; weights[e] = $0 })
    }

    private func pushVoice() {
        guard !isMicOn else { return }
        driver.prosody = Prosody(energy: energy, pitch: pitch <= 70 ? nil : pitch)
    }

    /// A verse that turns: what the classifier might send every 1.5 s.
    private func tour() async {
        guard touring else { return }
        var i = 0
        while !Task.isCancelled {
            weights = LabPreset.tour[i % LabPreset.tour.count]
            i += 1
            try? await Task.sleep(for: .seconds(1.5))
        }
    }
}

// MARK: - Presets

private struct LabPreset: Identifiable {
    let label: String
    let weights: [Emotion: Double]
    var id: String { label }

    static let all: [LabPreset] =
        [LabPreset(label: "rest", weights: [:])]
        + Emotion.allCases.map { LabPreset(label: $0.rawValue, weights: [$0: 1]) }
        + [
            LabPreset(label: "grief + awe", weights: [.grief: 0.55, .awe: 0.45]),
            LabPreset(label: "anger + defiance", weights: [.anger: 0.5, .defiance: 0.5]),
            LabPreset(label: "longing + tenderness", weights: [.longing: 0.6, .tenderness: 0.4]),
            LabPreset(label: "joy + awe + defiance", weights: [.joy: 0.4, .awe: 0.35, .defiance: 0.25]),
        ]

    static let tour: [[Emotion: Double]] = [
        [.longing: 0.7, .grief: 0.3],
        [.grief: 0.75, .longing: 0.25],
        [.grief: 0.6, .fear: 0.4],
        [.fear: 0.3, .anger: 0.7],
        [.anger: 0.55, .defiance: 0.45],
        [.defiance: 0.8, .anger: 0.2],
        [.defiance: 0.4, .awe: 0.6],
        [.awe: 0.85, .joy: 0.15],
        [.awe: 0.4, .joy: 0.6],
        [.joy: 0.3, .tenderness: 0.7],
        [.tenderness: 0.5, .longing: 0.5],
    ]
}

// MARK: - Controls

private struct LabSlider: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    let readout: String
    var inks: [UInt32] = []

    var body: some View {
        VStack(spacing: Metrics.s1) {
            HStack(spacing: Metrics.s2) {
                if !inks.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(inks, id: \.self) { Rectangle().fill(Color(hex: $0)).frame(width: 7, height: 12) }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                Text(label).font(Typeface.text(14, weight: 550))
                Spacer()
                Text(readout).font(Typeface.numeral(13, weight: 500)).foregroundStyle(Palette.ink3)
            }
            Slider(value: $value, in: range).tint(Palette.ink)
        }
    }
}

private struct ChipToggle: ToggleStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            configuration.label
                .font(Typeface.text(14, weight: 600))
                .foregroundStyle(configuration.isOn ? Palette.paper : Palette.ink)
                .padding(.horizontal, Metrics.s4)
                .padding(.vertical, Metrics.s2)
                .background(Capsule().fill(configuration.isOn ? tint : Palette.paper2))
        }
        .buttonStyle(.plain)
        .animation(Motion.stamp, value: configuration.isOn)
    }
}

private struct ChipButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typeface.text(13, weight: 550))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Metrics.s3)
            .padding(.vertical, 6)
            .background(Capsule().fill(configuration.isPressed ? Palette.paper3 : Palette.paper2))
    }
}

/// Wraps chips onto as many rows as they need.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal.width ?? .infinity, subviews)
        return CGSize(width: proposal.width ?? rows.width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(bounds.width, subviews)
        for (i, origin) in rows.origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(_ width: CGFloat, _ subviews: Subviews) -> (origins: [CGPoint], width: CGFloat, height: CGFloat) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return (origins, maxX, y + rowHeight)
    }
}

#Preview {
    @Previewable @State var mic = false
    SceneLabView(driver: SceneDriver(), isMicOn: $mic)
}
