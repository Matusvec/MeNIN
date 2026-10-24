import MetalKit
import SwiftUI

/// A full-screen-quad shader animating over time: proves the .metal toolchain,
/// the render pipeline, and MTKView all work on this device. Dev only.
struct MetalCheckView: UIViewRepresentable {
    func makeCoordinator() -> Renderer { Renderer() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.device)
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    final class Renderer: NSObject, MTKViewDelegate {
        let device = MTLCreateSystemDefaultDevice()
        private var queue: MTLCommandQueue?
        private var pipeline: MTLRenderPipelineState?
        private let start = CACurrentMediaTime()

        override init() {
            super.init()
            guard let device, let library = device.makeDefaultLibrary() else { return }
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = library.makeFunction(name: "metalCheckVertex")
            desc.fragmentFunction = library.makeFunction(name: "metalCheckFragment")
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            queue = device.makeCommandQueue()
            pipeline = try? device.makeRenderPipelineState(descriptor: desc)
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let pipeline, let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
                  let buffer = queue?.makeCommandBuffer(),
                  let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
            var time = Float(CACurrentMediaTime() - start)
            encoder.setRenderPipelineState(pipeline)
            encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
            buffer.present(drawable)
            buffer.commit()
        }
    }
}
