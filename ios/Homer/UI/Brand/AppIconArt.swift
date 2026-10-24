import SwiftUI

/// The app icon, drawn in code so it stays reproducible: the wine-dark sea in
/// cut paper (night above, wine, sea and sand in layers), with MeNIN's M
/// standing over it. Render at 1024 x 1024 for the asset catalog.
struct AppIconArt: View {
    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width
            ZStack {
                Color(hex: 0x1A1325)
                // Layers from the back: wine, then the M rising out of it, then sea and sand in front.
                WaveLayer(baseline: 0.6, amplitude: 0.035, phase: 0.3, waves: 1.6)
                    .fill(Color(hex: 0x4B1834))
                    .shadow(color: .black.opacity(0.35), radius: s * 0.012, x: 0, y: -s * 0.006)
                Text("M")
                    .font(Typeface.display(s * 0.66, weight: 900, opticalSize: 36))
                    .foregroundStyle(Color(hex: 0xF3EADB))
                    .shadow(color: .black.opacity(0.4), radius: s * 0.02, x: 0, y: s * 0.01)
                    .offset(y: -s * 0.04)
                WaveLayer(baseline: 0.72, amplitude: 0.03, phase: 1.7, waves: 1.9)
                    .fill(Color(hex: 0x1F5361))
                    .shadow(color: .black.opacity(0.4), radius: s * 0.014, x: 0, y: -s * 0.008)
                WaveLayer(baseline: 0.86, amplitude: 0.022, phase: 2.9, waves: 2.2)
                    .fill(Color(hex: 0xD9C6A5))
                    .shadow(color: .black.opacity(0.3), radius: s * 0.012, x: 0, y: -s * 0.006)
            }
            .colorEffect(ShaderLibrary.paperGrain(.float(0.05)))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct WaveLayer: Shape {
    let baseline: CGFloat
    let amplitude: CGFloat
    let phase: CGFloat
    let waves: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        let steps = 120
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let y = baseline + amplitude * sin(t * .pi * 2 * waves + phase) + amplitude * 0.35 * sin(t * .pi * 5.3 + phase * 2)
            p.addLine(to: CGPoint(x: r.minX + t * r.width, y: r.minY + y * r.height))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview { AppIconArt().frame(width: 300) }
