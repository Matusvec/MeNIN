import SwiftUI

/// The app icon, drawn in code so it stays reproducible. Render at 1024 x 1024
/// for the asset catalog.
/// - Atelier: the cream page, a wine Bodoni M rising out of a wine sea.
/// - Cut paper: the wine-dark sea at night in cut paper, a cream Fraunces M.
struct AppIconArt: View {
    var direction: Direction = Direction.current

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width
            Group {
                if direction == .atelier { atelier(s) } else { cutPaper(s) }
            }
            .colorEffect(ShaderLibrary.paperGrain(.float(0.04)))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func atelier(_ s: CGFloat) -> some View {
        ZStack {
            Color(hex: 0xF7F3EC)
            WaveLayer(baseline: 0.66, amplitude: 0.03, phase: 0.6, waves: 1.5)
                .fill(Color(hex: 0xE4D7CC))
                .shadow(color: Color(hex: 0x302A29).opacity(0.12), radius: s * 0.012, x: 0, y: -s * 0.005)
            Text("M")
                .font(.custom("BodoniModa-Regular", size: s * 0.7))
                .foregroundStyle(Color(hex: 0x682C3E))
                .offset(y: -s * 0.05)
            WaveLayer(baseline: 0.78, amplitude: 0.028, phase: 2.1, waves: 1.8)
                .fill(Color(hex: 0x682C3E))
                .shadow(color: Color(hex: 0x302A29).opacity(0.25), radius: s * 0.014, x: 0, y: -s * 0.007)
            WaveLayer(baseline: 0.9, amplitude: 0.02, phase: 3.2, waves: 2.3)
                .fill(Color(hex: 0x542232))
        }
    }

    private func cutPaper(_ s: CGFloat) -> some View {
        ZStack {
            Color(hex: 0x1A1325)
            // Layers from the back: wine, then the M rising out of it, then sea and sand in front.
            WaveLayer(baseline: 0.6, amplitude: 0.035, phase: 0.3, waves: 1.6)
                .fill(Color(hex: 0x4B1834))
                .shadow(color: .black.opacity(0.35), radius: s * 0.012, x: 0, y: -s * 0.006)
            Text("M")
                .font(.custom("Fraunces-9ptBlack", size: s * 0.66))
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

#Preview {
    HStack {
        AppIconArt(direction: .atelier).frame(width: 200)
        AppIconArt(direction: .cutPaper).frame(width: 200)
    }
}
