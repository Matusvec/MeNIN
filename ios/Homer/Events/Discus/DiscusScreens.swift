import SwiftUI
import UIKit

// The three discus screens the app routes to (spacetime/CONTRACT.md, "Discus"). Each one
// holds the discus state and feeds the art lead's views (UI/Discus/DiscusViews.swift).

/// The first throw on a device starts with the safety card (UX D0).
enum DiscusSafety {
    private static let key = "discus.safetyAcked"
    static var acked: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

/// Dev only: the raw numbers of the last hold, for tuning on a real iPhone. Three-finger
/// tap on any discus phone screen toggles it; it never shows unless someone turns it on.
enum DiscusTelemetry {
    private static let key = "discus.telemetry"
    static var on: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

// MARK: - Arena

/// The arena in a discus room. The arena screen keeps the connection; this reads the battle,
/// paces the reveal and moves the battle on. `homer` is the arena's voice, when it has one.
struct DiscusArenaRoot: View {
    let battle: BattleClient
    var homer: HomerVoice? = nil
    @State private var director: DiscusDirector?

    var body: some View {
        TimelineView(.animation) { context in
            let model = director.map {
                DiscusPresenter.arena(battle, director: $0, caption: homer?.caption?.text ?? $0.caption, now: context.date)
            } ?? DiscusArenaModel()
            ZStack {
                SceneView(emotion: EmotionWeights([.awe: 0.5, .joy: 0.3, .defiance: 0.2]), prosody: swing(model))
                    .ignoresSafeArea()
                DiscusArenaScreen(model: model, code: battle.room?.code)
            }
        }
        .overlay(alignment: .bottom) { controls }
        .task {
            let d = DiscusDirector(battle: battle, homer: homer)
            d.start()
            director = d
        }
        .onDisappear { director?.stop() }
    }

    /// The scene's instant layer follows the swing, as it follows a voice.
    private func swing(_ m: DiscusArenaModel) -> Prosody {
        if case .winding(let power) = m.phase { return Prosody(energy: power, pitch: nil) }
        return .silent
    }

    /// The host's taps: begin once two poets are in, rematch at the end.
    @ViewBuilder
    private var controls: some View {
        switch battle.room?.phaseValue {
        case .lobby:
            let ready = battle.players.count >= 2
            Button { battle.startBattle() } label: { ArrowLabel(title: ready ? "Begin" : "Waiting for throwers") }
                .buttonStyle(.homer)
                .disabled(!ready)
                .padding(.bottom, Metrics.s6)
        case .finished:
            Button { battle.rematch() } label: { ArrowLabel(title: "Throw again") }
                .buttonStyle(.homer)
                .padding(.bottom, Metrics.s6)
        default:
            EmptyView()
        }
    }
}

// MARK: - Phone (Fight)

/// A thrower's phone in a discus room.
struct DiscusPhoneRoot: View {
    let battle: BattleClient
    @State private var thrower = DiscusThrower()
    @State private var safetyAcked = DiscusSafety.acked
    @State private var telemetry = DiscusTelemetry.on

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            DiscusPhoneView(model: DiscusPresenter.phone(battle, thrower: thrower, safetyAcked: safetyAcked, now: context.date),
                            onSafetyAck: acknowledge) {
                DiscusHoldPad { thrower.hold($0) }
            }
        }
        .padding(.horizontal, Metrics.s5)
        .overlay(alignment: .bottom) { if telemetry { DiscusTelemetryStrip(thrower: thrower) } }
        .modifier(DiscusPhoneChrome(telemetry: $telemetry))
        .onAppear(perform: wire)
        .onChange(of: battle.currentTurn?.id) { thrower.reset() }
        .onChange(of: battle.isMyTurn) { _, mine in if !mine { thrower.putDown() } }
        .onDisappear { thrower.putDown() }
    }

    private func acknowledge() {
        DiscusSafety.acked = true
        safetyAcked = true
    }

    private func wire() {
        thrower.onThrow = { [battle] t in
            guard let turn = battle.currentTurn, battle.isMyTurn, turn.statusValue == .speaking else { return }
            battle.throwDiscus(turn.id, t)
        }
        thrower.onWindUp = { [battle] power, held in
            battle.setProsody(loudness: Float(power), pitch: 0, hits: held ? 1 : 0)
        }
    }
}

// MARK: - Solo (Throw)

/// Discus on one phone (UX "Solo"): the phone is both the field and the discus, and it keeps
/// your best on this device.
struct DiscusSoloRoot: View {
    private static let bestKey = "discus.soloBest"

    @State private var thrower = DiscusThrower()
    @State private var safetyAcked = DiscusSafety.acked
    @State private var telemetry = DiscusTelemetry.on
    @State private var best: Double? = UserDefaults.standard.object(forKey: DiscusSoloRoot.bestKey) as? Double
    @State private var previousBest: Double?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30)) { context in
            VStack(spacing: Metrics.s4) {
                if let t = thrower.thrown, let at = thrower.thrownAt {
                    flight(t, at: at, now: context.date)
                } else {
                    DiscusPhoneView(model: phoneModel, onSafetyAck: acknowledge) {
                        DiscusHoldPad { thrower.hold($0) }
                    }
                }
            }
        }
        .padding(.horizontal, Metrics.s5)
        .overlay(alignment: .bottom) { if telemetry { DiscusTelemetryStrip(thrower: thrower) } }
        .modifier(DiscusPhoneChrome(telemetry: $telemetry))
        .onAppear {
            thrower.onThrow = { t in keep(t) }
        }
        .onDisappear { thrower.putDown() }
    }

    private var phoneModel: DiscusPhoneModel {
        DiscusPhoneModel(phase: safetyAcked ? (thrower.stage == .winding ? .winding(power: thrower.power) : .ready) : .safety,
                         attemptsLeft: 1, best: best, notice: thrower.notice)
    }

    private func flight(_ t: DiscusThrow, at: Date, now: Date) -> some View {
        let elapsed = now.timeIntervalSince(at)
        let duration = DiscusDirector.flightSeconds(t.distance)
        var m = DiscusArenaModel(thrower: PoetPlate(id: "solo", name: "You", epithet: "", seat: 0),
                                 distance: t.distance, record: previousBest, recordHolder: nil, attempt: 1, attempts: 1)
        if elapsed < duration {
            m.phase = .flight(progress: elapsed / duration)
        } else {
            m.phase = .landed(foul: t.foul)
            if !t.foul, t.distance > (previousBest ?? 0) { m.landing = previousBest == nil ? nil : .personalBest }
            if !t.foul, m.landing == nil, t.distance > DiscusPhysics.phayllos { m.landing = .pastPhayllos }
        }
        return VStack(spacing: Metrics.s5) {
            DiscusArenaView(model: m)
            if elapsed >= duration {
                Button { thrower.reset() } label: { ArrowLabel(title: "Throw again") }.buttonStyle(.homer)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func acknowledge() {
        DiscusSafety.acked = true
        safetyAcked = true
    }

    private func keep(_ t: DiscusThrow) {
        previousBest = best
        guard !t.foul, t.distance > (best ?? 0) else { return }
        best = t.distance
        UserDefaults.standard.set(t.distance, forKey: Self.bestKey)
    }
}

// MARK: - Shared

/// Keeps system edge gestures from stealing the thumb mid-swing, and the dev telemetry toggle.
private struct DiscusPhoneChrome: ViewModifier {
    @Binding var telemetry: Bool

    func body(content: Content) -> some View {
        content
            .defersSystemGestures(on: .all)
            .persistentSystemOverlays(.hidden)
            .background(ThreeFingerTap(action: toggle))
    }

    private func toggle() {
        telemetry.toggle()
        DiscusTelemetry.on = telemetry
    }
}

/// A three-finger tap anywhere in the window, for the dev telemetry toggle. The recognizer
/// sits on the window and never cancels or delays touches, so the hold pad is unaffected.
private struct ThreeFingerTap: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> Installer {
        let view = Installer()
        view.action = action
        return view
    }

    func updateUIView(_ view: Installer, context: Context) {
        view.action = action
    }

    final class Installer: UIView {
        var action: (() -> Void)?
        private lazy var tap: UITapGestureRecognizer = {
            let tap = UITapGestureRecognizer(target: self, action: #selector(fire))
            tap.numberOfTouchesRequired = 3
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delaysTouchesEnded = false
            return tap
        }()

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            tap.view?.removeGestureRecognizer(tap)
            newWindow?.addGestureRecognizer(tap)
        }

        @objc private func fire() { action?() }
    }
}

/// Dev only (DiscusTelemetry): the last hold's raw numbers.
struct DiscusTelemetryStrip: View {
    let thrower: DiscusThrower

    var body: some View {
        let r = thrower.lastReading
        let t = thrower.thrown
        Text(r.map {
            String(format: "speed %.1f rad/s · tilt %.0f° → angle %.0f° · timing %.2f · held %.2f s · turned %.1f rad%@",
                   $0.speed, $0.tilt, $0.angle, $0.timing, $0.held, $0.turned,
                   t.map { String(format: " · %.1f m%@", $0.distance, $0.foul ? " foul" : "") } ?? ($0.isDrop ? " · drop" : ""))
        } ?? "telemetry: no hold yet\(thrower.hasMotion ? "" : " · no motion sensors")")
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(Palette.ink)
        .padding(Metrics.s2)
        .frame(maxWidth: .infinity)
        .background(Palette.paper.opacity(0.92))
    }
}
