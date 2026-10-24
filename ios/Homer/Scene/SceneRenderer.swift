import MetalKit
import QuartzCore
import UIKit

// Draws the scene into an MTKView. The field renders below screen resolution
// (it is soft by design), the flecks draw over it, and the finish pass adds
// grain at full resolution.

@MainActor
final class SceneRenderer: NSObject, MTKViewDelegate {
    var driver: SceneDriver
    private let motion = SceneMotion()
    private var lastEmotion: EmotionWeights?

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

    /// Field pixels per point. 1.5 is crisp enough for paper-cut edges at a third of the cost of 3x.
    private let fieldScale: CGFloat = 1.5
    private let maxFieldPixels: CGFloat = 2_400_000

    init?(view: MTKView, driver: SceneDriver) {
        self.driver = driver
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
        view.preferredFramesPerSecond = 60
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        fieldTexture = nil // rebuilt at the new size on the next frame (the Mac arena window resizes)
    }

    func draw(in view: MTKView) {
        let size = view.drawableSize
        guard size.width > 0, size.height > 0,
              let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable
        else { return }
        guard let fieldTexture = fieldTexture(for: size, scale: view.contentScaleFactor) else { return }

        inFlight.wait()
        let now = CACurrentMediaTime()
        let dt = last == 0 ? 1.0 / 60 : now - last
        last = now

        let emotion = driver.emotionForFrame()
        if emotion != lastEmotion {
            lastEmotion = emotion
            motion.setEmotion(emotion)
        }
        motion.setProsody(driver.prosody)
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
            // Atelier grades up to the concept's page color with a whisper of vignette;
            // Cut paper eases its whites and darkens the corners more.
            let atelier = Direction.current == .atelier
            var finish = [
                SIMD4<Float>(Float(size.width), Float(size.height), motion.time, atelier ? 0.05 : 0.16),
                atelier ? SIMD4<Float>(0.995, 0.99, 0.975, 0) : SIMD4<Float>(0.965, 0.95, 0.925, 0),
            ]
            enc.setRenderPipelineState(finishPipeline)
            enc.setFragmentTexture(fieldTexture, index: 0)
            enc.setFragmentBytes(&finish, length: MemoryLayout<SIMD4<Float>>.stride * 2, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
        }

        let semaphore = inFlight
        commands.addCompletedHandler { _ in semaphore.signal() }
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
