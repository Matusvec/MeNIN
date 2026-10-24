import SwiftUI

/// The discus throw on the arena: a matte paper discus flies its arc over a
/// field marked every 10 m, lands, and the distance stamps in.
///
/// `progress` (0...1) is the flight; the iOS lead drives it from the measured
/// throw. `record` draws the best mark so far as a gold flag.
struct DiscusThrowView: View {
    let distance: Double // metres
    var progress: Double = 1
    var record: Double? = nil
    var poet: String? = nil
    var fieldLength: Double = 80

    @Environment(\.stage) private var stage

    var body: some View {
        let k = stage.scale
        VStack(spacing: Metrics.s4 * k) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let ground = h * 0.78
                let start = CGPoint(x: w * 0.06, y: ground - 4 * k)
                let land = CGPoint(x: x(for: distance, w), y: ground - 4 * k)
                let apex = min(ground * 0.85, (land.x - start.x) * 0.75)
                let p = min(1, max(0, progress))

                ZStack(alignment: .topLeading) {
                    // The field: a band of ink with distance marks.
                    Rectangle().fill(Palette.ink)
                        .frame(width: w, height: h - ground)
                        .offset(y: ground)
                    ForEach(Array(stride(from: 10, through: Int(fieldLength), by: 10)), id: \.self) { m in
                        let mx = x(for: Double(m), w)
                        Rectangle().fill(Palette.paper.opacity(0.35)).frame(width: 1.5 * k, height: 14 * k)
                            .position(x: mx, y: ground + 10 * k)
                        Text("\(m)").font(Typeface.numeral(11 * k, weight: 600)).foregroundStyle(Palette.paper.opacity(0.6))
                            .position(x: mx, y: ground + 28 * k)
                    }
                    if let record {
                        Flag(label: String(format: "%.1f", record), color: Palette.gold, k: k)
                            .position(x: x(for: record, w), y: ground - 22 * k)
                    }

                    // The arc so far, dashed like a thrown line drawn in chalk.
                    ArcPath(start: start, end: land, apex: apex)
                        .trim(from: 0, to: p)
                        .stroke(Palette.paper.opacity(0.75), style: StrokeStyle(lineWidth: 3 * k, lineCap: .round, dash: [2 * k, 9 * k]))

                    let at = ArcPath.point(start: start, end: land, apex: apex, t: p)
                    DiscusShape(ink: Palette.paper, accent: Palette.gold)
                        .frame(width: 54 * k, height: 54 * k)
                        .rotationEffect(.degrees(-18 + 30 * p))
                        .position(at)

                    if p >= 1 {
                        Rectangle().fill(Palette.vermilion).frame(width: 3 * k, height: 26 * k)
                            .position(x: land.x, y: ground + 4 * k)
                            .transition(.scale(scale: 0.2, anchor: .bottom))
                    }
                }
            }
            .frame(height: 300 * k)

            HStack(alignment: .lastTextBaseline, spacing: Metrics.s2 * k) {
                if let poet { Text(poet).tracked(12 * k, color: Palette.ink2) }
                Spacer()
                Text(progress >= 1 ? String(format: "%.1f", distance) : "—")
                    .font(Typeface.display(64 * k, weight: 900))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText(value: progress >= 1 ? distance : 0))
                Text("m").font(Typeface.display(26 * k, weight: 700)).foregroundStyle(Palette.ink2)
            }
            .padding(.horizontal, Metrics.s5 * k)
            .padding(.vertical, Metrics.s3 * k)
            .paper(radius: Metrics.radiusL * k)
        }
        .animation(Motion.stamp, value: progress >= 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progress >= 1 ? String(format: "%.1f metres", distance) : "Discus in flight")
    }

    private func x(for metres: Double, _ width: CGFloat) -> CGFloat {
        width * 0.06 + width * 0.9 * CGFloat(min(metres, fieldLength) / fieldLength)
    }
}

private struct ArcPath: Shape {
    let start: CGPoint
    let end: CGPoint
    let apex: CGFloat

    static func point(start: CGPoint, end: CGPoint, apex: CGFloat, t: CGFloat) -> CGPoint {
        let control = CGPoint(x: (start.x + end.x) / 2, y: min(start.y, end.y) - apex * 2)
        let a = (1 - t) * (1 - t)
        let b = 2 * (1 - t) * t
        let c = t * t
        return CGPoint(x: a * start.x + b * control.x + c * end.x, y: a * start.y + b * control.y + c * end.y)
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: start)
        p.addQuadCurve(to: end, control: CGPoint(x: (start.x + end.x) / 2, y: min(start.y, end.y) - apex * 2))
        return p
    }
}

private struct Flag: View {
    let label: String
    let color: Color
    let k: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(Typeface.numeral(10 * k, weight: 700)).foregroundStyle(Palette.ink)
                .padding(.horizontal, 5 * k).padding(.vertical, 2 * k)
                .background(color)
            Rectangle().fill(color).frame(width: 2 * k, height: 24 * k)
        }
    }
}

#Preview {
    DiscusThrowView(distance: 47.3, progress: 1, record: 52.1, poet: "Matus")
        .padding()
        .background(Palette.vermilion.opacity(0.5))
}
