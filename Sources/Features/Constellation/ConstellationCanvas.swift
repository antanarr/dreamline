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

    @Environment(ThemeService.self) private var theme
    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAutoFit = false

    var body: some View {
        GeometryReader { proxy in
            let dedupedEdges: [Edge] = {
                var seen = Set<String>()
                var result: [Edge] = []
                for edge in edges {
                    let key = edgeKey(edge.a, edge.b)
                    if seen.insert(key).inserted {
                        result.append(edge)
                    }
                }
                return result
            }()
            ZStack {
                ForEach(dedupedEdges) { e in
                    if let pa = pos(e.a, in: proxy.size), let pb = pos(e.b, in: proxy.size) {
                        Path { p in
                            p.move(to: pa)
                            p.addLine(to: pb)
                        }
                        .stroke(edgeStrokeColor(weight: e.weight),
                                lineWidth: 0.5 + CGFloat(e.weight) * 1.5)
                    }
                }

                ForEach(nodes) { n in
                    if let p = pos(n.id, in: proxy.size) {
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
        .onAppear {
            if !didAutoFit {
                zoom = fitScale(for: proxy.size)
                didAutoFit = true
            }
        }
        .onChange(of: nodes.count) { _ in
            zoom = fitScale(for: proxy.size)
        }
    }

    private func pos(_ id: String, in size: CGSize) -> CGPoint? {
        guard let n = nodes.first(where: { $0.id == id }) else { return nil }
        let s = min(size.width, size.height)
        return CGPoint(
            x: size.width * 0.5  + n.point.x * s * 0.42,
            y: size.height * 0.5 + n.point.y * s * 0.42
        )
    }

    private var coordinates: [String: CGPoint] {
        Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.point) })
    }

    private func fitScale(for size: CGSize) -> CGFloat {
        let pts = coordinates.values.map { hypot($0.x, $0.y) }
        guard let rmax = pts.max(), rmax > 0 else { return 1.0 }
        let s = 0.44 / (0.48 * max(0.25, rmax))
        return min(3.0, max(0.6, s))
    }

    private func edgeKey(_ a: String, _ b: String) -> String {
        a < b ? "\(a)|\(b)" : "\(b)|\(a)"
    }

    private func edgeStrokeColor(weight: CGFloat) -> Color {
        let alpha = max(0.08, min(0.35, Double(weight) * 0.35))
        if theme.isLight {
            return Color.black.opacity(alpha * 0.35)
        } else {
            return Color.white.opacity(alpha * 0.35)
        }
    }
}


