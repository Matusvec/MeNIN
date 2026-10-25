import MetalKit
import QuartzCore
import UIKit

// Draws the scene into an MTKView. The field renders below screen resolution
// (it is soft by design), the flecks draw over it, and the finish pass adds
// grain at full resolution.

@MainActor
final class SceneRenderer: NSObject, MTKViewDelegate {
    var driver: SceneDriver {
        didSet {
            guard driver !== oldValue else { return }
            oldValue.wake = nil
            hookWake()
        }
    }
    private let motion = SceneMotion()
    private var lastEmotion: EmotionWeights?
    private var seenStrikes = 0

    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let fieldPipeline: MTLRenderPipelineState
    private let fleckPipeline: MTLRenderPipelineState
    private let finishPipeline: MTLRenderPipelineState
    private let inks: MTLBuffer
    private var fleckBuffers: [MTLBuffer] = []
    private var frame = 0
    private let inFlight = DispatchSemaphore(value: 3)
    private var fieldTexture: MTLTexture?
    private var fieldPxPerPoint: Float = 1
    private var last: CFTimeInterval = 0
    /// Seconds to stay paused after a stalled drawable; doubles while stalls continue.
    private var backoff: TimeInterval = 0
    private var backgrounded = false
    private weak var view: MTKView?
    nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    /// Field pixels per point. 1.5 is crisp enough for paper-cut edges at a third of the cost of 3x.
    private let fieldScale: CGFloat
    /// Phones pace the scene to what's happening (see `pace`); the arena runs a steady 60.
    private let paced: Bool
    private var lastLively: CFTimeInterval = 0
    #if DEBUG
    /// For the scene lab: GPU milliseconds per frame (smoothed) and frames drawn per second.
    static var debugStats = (gpuMs: 0.0, fps: 0.0, lastFrame: 0.0)
    private var statFrames = 0
    private var statStart: CFTimeInterval = 0
    #endif
    private let maxFieldPixels: CGFloat = 2_400_000

    init?(view: MTKView, driver: SceneDriver) {
        self.driver = driver
        seenStrikes = driver.strikes
        let phone = UIDevice.current.userInterfaceIdiom == .phone && !UserDefaults.standard.bool(forKey: "sceneFullRes")
        paced = phone
        // A phone's field is soft paint under cards: one pixel per point is plenty.
        fieldScale = phone ? 1.0 : 1.5
        guard let device = view.device ?? MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = try? device.makeDefaultLibrary(bundle: .main)
        else { return nil }
        self.device = device
        self.queue = queue

        func pipeline(_ vertex: String, _ fragment: String, blend: Bool = false) -> MTLRenderPipelineState? {
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = library.makeFunction(name: vertex)
            d.fragmentFunction = library.makeFunction(name: fragment)
            d.colorAttachments[0].pixelFormat = .bgra8Unorm
            if blend {
                // Premultiplied alpha: flat flecks laid over the paper, no additive glow.
                let c = d.colorAttachments[0]!
                c.isBlendingEnabled = true
                c.sourceRGBBlendFactor = .one
                c.sourceAlphaBlendFactor = .one
                c.destinationRGBBlendFactor = .oneMinusSourceAlpha
                c.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            }
            return try? device.makeRenderPipelineState(descriptor: d)
        }
        guard let field = pipeline("fullscreen_vertex", "field_fragment"),
              let flecks = pipeline("fleck_vertex", "fleck_fragment", blend: true),
              let finish = pipeline("fullscreen_vertex", "finish_fragment")
        else { return nil }
        fieldPipeline = field
        fleckPipeline = flecks
        finishPipeline = finish

        let inkValues = Mood.styles.flatMap { style in (0..<4).map { style.ink($0) } }
        guard let inks = device.makeBuffer(bytes: inkValues, length: MemoryLayout<SIMD4<Float>>.stride * inkValues.count)
        else { return nil }
        self.inks = inks
        for _ in 0..<3 {
            guard let b = device.makeBuffer(length: MemoryLayout<Fleck>.stride * fleckCount, options: .storageModeShared)
            else { return nil }
            fleckBuffers.append(b)
        }
        super.init()

        motion.reducedMotion = UIAccessibility.isReduceMotionEnabled
        view.device = device
        view.colorPixelFormat = .bgra8Unorm // inks are authored in sRGB and passed through untouched
        view.framebufferOnly = true
        view.preferredFramesPerSecond = paced ? 30 : 60
        self.view = view
        hookWake()

        // Never draw for a window nobody can see (a minimized Mac arena window, the app in the background):
        // asking for a drawable there blocks the main thread.
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] note in
                let scene = (note.object as AnyObject?).map(ObjectIdentifier.init)
                MainActor.assumeIsolated { self?.sceneChanged(scene, background: true) }
            },
            center.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] note in
                let scene = (note.object as AnyObject?).map(ObjectIdentifier.init)
                MainActor.assumeIsolated { self?.sceneChanged(scene, background: false) }
            },
        ]
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    private func hookWake() {
        driver.wake = { [weak self] in
            guard let self, let view = self.view, view.isPaused, !self.backgrounded, self.backoff == 0 else { return }
            self.lastLively = CACurrentMediaTime()
            view.isPaused = false
        }
    }

    /// A phone's pace: 60 fps while someone speaks, 30 for a moment after any
    /// change (a feeling, a strike), 12 when nothing moves it, and after 8 quiet
    /// seconds a full pause (the last frame stays up) until the driver wakes it.
    private func pace(_ view: MTKView, now: CFTimeInterval, changed: Bool) {
        let voice = driver.prosody.energy > 0.03
        if voice || changed || lastLively == 0 { lastLively = now }
        let quiet = now - lastLively
        if quiet > 8 {
            view.isPaused = true
            return
        }
        let fps = voice ? 60 : (quiet < 2.5 ? 30 : 12)
        if view.preferredFramesPerSecond != fps { view.preferredFramesPerSecond = fps }
    }

    private func sceneChanged(_ scene: ObjectIdentifier?, background: Bool) {
        guard let view, let mine = view.window?.windowScene, scene == ObjectIdentifier(mine) else { return }
        backgrounded = background
        backoff = 0
        view.isPaused = background
    }

    /// Drawables dried up (a headless simulator, an occluded window): each request
    /// blocks the main thread for up to a second, which starves every main-actor
    /// task (Homer's voice, the battle's advance). Pause, retry later, back off.
    private func stalled(_ view: MTKView) {
        backoff = min(8, max(0.5, backoff * 2))
        view.isPaused = true
        let wait = backoff
        Task { @MainActor [weak self, weak view] in
            try? await Task.sleep(for: .seconds(wait))
            guard let self, let view, !self.backgrounded else { return }
            view.isPaused = false
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        fieldTexture = nil // rebuilt at the new size on the next frame (the Mac arena window resizes)
    }

    // Runs on the main thread and must never block it: no waiting on the GPU, and
    // no waiting on drawables that aren't coming.
    func draw(in view: MTKView) {
        let size = view.drawableSize
        guard size.width > 0, size.height > 0, view.window != nil else { return }
        // All three frames still on the GPU: drop this one rather than wait.
        guard inFlight.wait(timeout: .now()) == .success else { return }
        let asked = CACurrentMediaTime()
        guard let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable else {
            inFlight.signal()
            if CACurrentMediaTime() - asked > 0.05 { stalled(view) }
            return
        }
        if CACurrentMediaTime() - asked > 0.05 { stalled(view) } else { backoff = 0 }
        guard let fieldTexture = fieldTexture(for: size, scale: view.contentScaleFactor) else {
            inFlight.signal()
            return
        }

        let now = CACurrentMediaTime()
        let dt = last == 0 ? 1.0 / 60 : now - last
        last = now

        var changed = false
        let emotion = driver.emotionForFrame()
        if emotion != lastEmotion {
            lastEmotion = emotion
            motion.setEmotion(emotion)
            changed = true
        }
        motion.setProsody(driver.prosody)
        if driver.strikes != seenStrikes {
            seenStrikes = driver.strikes
            motion.strike(Float(driver.strikeStrength))
            changed = true
        }
        if paced { pace(view, now: now, changed: changed) }
        motion.aspect = Float(size.width / size.height)
        motion.step(dt: Float(dt), resolution: [Float(fieldTexture.width), Float(fieldTexture.height)])
        var uniforms = motion.uniforms

        frame = (frame + 1) % fleckBuffers.count
        let fleckBuffer = fleckBuffers[frame]
        motion.flecks.withUnsafeBytes { src in
            fleckBuffer.contents().copyMemory(from: src.baseAddress!, byteCount: src.count)
        }

        guard let commands = queue.makeCommandBuffer() else {
            inFlight.signal()
            return
        }

        let fieldPass = MTLRenderPassDescriptor()
        fieldPass.colorAttachments[0].texture = fieldTexture
        fieldPass.colorAttachments[0].loadAction = .dontCare
        fieldPass.colorAttachments[0].storeAction = .store
        if let enc = commands.makeRenderCommandEncoder(descriptor: fieldPass) {
            enc.setRenderPipelineState(fieldPipeline)
            enc.setFragmentBytes(&uniforms, length: MemoryLayout<FieldUniforms>.stride, index: 0)
            enc.setFragmentBuffer(inks, offset: 0, index: 1)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

            var viewInfo = SIMD4<Float>(motion.aspect, fieldPxPerPoint, 0, 0)
            enc.setRenderPipelineState(fleckPipeline)
            enc.setVertexBuffer(fleckBuffer, offset: 0, index: 0)
            enc.setVertexBytes(&viewInfo, length: MemoryLayout<SIMD4<Float>>.stride, index: 1)
            enc.drawPrimitives(type: .point, vertexStart: 0, vertexCount: fleckCount)
            enc.endEncoding()
        }

        pass.colorAttachments[0].loadAction = .dontCare
        if let enc = commands.makeRenderCommandEncoder(descriptor: pass) {
            // Hall grades up to the website's cool white and Atelier to the concept's
            // warm page, each with a whisper of vignette; Cut paper eases its whites
            // and darkens the corners more.
            let light = Direction.current.isLight
            let white: SIMD4<Float> = switch Direction.current {
            case .hall: SIMD4<Float>(0.985, 0.995, 1.0, 0)
            case .atelier: SIMD4<Float>(0.995, 0.99, 0.975, 0)
            case .cutPaper: SIMD4<Float>(0.965, 0.95, 0.925, 0)
            }
            var finish = [
                SIMD4<Float>(Float(size.width), Float(size.height), motion.time, light ? 0.05 : 0.16),
                white,
            ]
            enc.setRenderPipelineState(finishPipeline)
            enc.setFragmentTexture(fieldTexture, index: 0)
            enc.setFragmentBytes(&finish, length: MemoryLayout<SIMD4<Float>>.stride * 2, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
        }

        let semaphore = inFlight
        #if DEBUG
        commands.addCompletedHandler { buffer in
            let ms = (buffer.gpuEndTime - buffer.gpuStartTime) * 1000
            semaphore.signal()
            Task { @MainActor in SceneRenderer.debugStats.gpuMs = SceneRenderer.debugStats.gpuMs * 0.9 + ms * 0.1 }
        }
        statFrames += 1
        Self.debugStats.lastFrame = now
        if now - statStart >= 1 {
            Self.debugStats.fps = Double(statFrames) / (now - statStart)
            statFrames = 0
            statStart = now
        }
        #else
        commands.addCompletedHandler { _ in semaphore.signal() }
        #endif
        commands.present(drawable)
        commands.commit()
    }

    private func fieldTexture(for drawable: CGSize, scale: CGFloat) -> MTLTexture? {
        if let t = fieldTexture { return t }
        let points = CGSize(width: drawable.width / max(scale, 1), height: drawable.height / max(scale, 1))
        var ratio = min(fieldScale, scale)
        let pixels = points.width * points.height * ratio * ratio
        if pixels > maxFieldPixels { ratio *= sqrt(maxFieldPixels / pixels) }
        let d = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: max(1, Int(points.width * ratio)),
            height: max(1, Int(points.height * ratio)),
            mipmapped: false)
        d.usage = [.renderTarget, .shaderRead]
        d.storageMode = .private
        fieldTexture = device.makeTexture(descriptor: d)
        fieldPxPerPoint = Float(ratio)
        return fieldTexture
    }
}
