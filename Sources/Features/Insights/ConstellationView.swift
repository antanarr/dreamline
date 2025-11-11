import SwiftUI

struct ConstellationView: View {
    let dreams: [DreamEntry]
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, _ in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let r = min(geo.size.width, geo.size.height) * 0.35
                let count = dreams.count
                for (idx, d) in dreams.enumerated() {
                    let angle = Double(idx) / Double(max(1, count)) * .pi * 2
                    let p = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * r,
                        y: center.y + CGFloat(sin(angle)) * r
                    )
                    let nodeRect = CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)
                    ctx.fill(Path(ellipseIn: nodeRect), with: .color(.white.opacity(0.9)))
                    if let nodeNeighbors = ConstellationStore.shared.neighbors[d.id] {
                        for nb in nodeNeighbors {
                            if let j = dreams.firstIndex(where: { $0.id == nb.neighborID }) {
                                let ang2 = Double(j) / Double(max(1, count)) * .pi * 2
                                let p2 = CGPoint(
                                    x: center.x + CGFloat(cos(ang2)) * r,
                                    y: center.y + CGFloat(sin(ang2)) * r
                                )
                                var path = Path()
                                path.move(to: p)
                                path.addLine(to: p2)
                                ctx.stroke(
                                    path,
                                    with: .color(.white.opacity(0.2)),
                                    lineWidth: CGFloat(0.5 + Double(nb.weight) * 0.8)
                                )
                            }
                        }
                    }
                }
            }
        }
        .frame(height: 260)
    }
}

