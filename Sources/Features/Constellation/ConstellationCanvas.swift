import SwiftUI

struct ConstellationCanvas: View {
    struct Node: Identifiable {
        let id: String
        let point: CGPoint   // normalized [-1, 1]
        let label: String
        let recencyWeight: CGFloat
    }

    struct Edge: Identifiable {
        let id: String
        let a: String
        let b: String
        let weight: CGFloat
    }

    let nodes: [Node]
    let edges: [Edge]

    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(edges) { e in
                    if let pa = pos(e.a, in: geo.size), let pb = pos(e.b, in: geo.size) {
                        Path { p in
                            p.move(to: pa)
                            p.addLine(to: pb)
                        }
                        .stroke(.white.opacity(0.18 * Double(e.weight)),
                                lineWidth: max(0.5, 1.2 * CGFloat(e.weight)))
                    }
                }

                ForEach(nodes) { n in
                    if let p = pos(n.id, in: geo.size) {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 8 + 10 * n.recencyWeight,
                                   height: 8 + 10 * n.recencyWeight)
                            .shadow(color: .white.opacity(0.25), radius: 6, x: 0, y: 0)
                            .position(p)
                        Text(n.label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .position(CGPoint(x: p.x + 10, y: p.y - 14))
                            .accessibilityHidden(true)
                    }
                }
            }
            .scaleEffect(zoom)
            .offset(x: offset.width + drag.width, y: offset.height + drag.height)
            .gesture(DragGesture().updating($drag) { value, state, _ in
                state = value.translation
            })
            .simultaneousGesture(MagnificationGesture().onChanged { m in
                zoom = min(max(m, 0.6), 2.0)
            })
            .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: zoom)
        }
        .background(Color.black.opacity(0.85))
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
    }

    private func pos(_ id: String, in size: CGSize) -> CGPoint? {
        guard let n = nodes.first(where: { $0.id == id }) else { return nil }
        let s = min(size.width, size.height)
        return CGPoint(
            x: size.width * 0.5  + n.point.x * s * 0.42,
            y: size.height * 0.5 + n.point.y * s * 0.42
        )
    }
}


