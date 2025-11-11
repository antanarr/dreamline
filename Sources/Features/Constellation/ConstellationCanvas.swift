import SwiftUI

struct ConstellationCanvas: View {
    @Environment(ThemeService.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let entries: [DreamEntry]
    let neighbors: [String: [(neighborID: String, weight: Float, lastTouched: Date)]]
    let coordinates: [String: CGPoint]

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastDrag: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var didAutoFit = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Canvas { ctx, canvasSize in
                let base = min(canvasSize.width, canvasSize.height) * 0.48
                let center = CGPoint(x: canvasSize.width/2 + offset.width,
                                     y: canvasSize.height/2 + offset.height)

                // Edges (deduped undirected)
                var drawn = Set<String>()
                for (a, neighs) in neighbors {
                    guard let p1n = coordinates[a] else { continue }
                    let p1 = CGPoint(x: center.x + CGFloat(p1n.x) * base * scale,
                                     y: center.y + CGFloat(p1n.y) * base * scale)
                    for n in neighs {
                        let key = a < n.neighborID ? "\(a)|\(n.neighborID)" : "\(n.neighborID)|\(a)"
                        if !drawn.insert(key).inserted { continue }
                        guard let p2n = coordinates[n.neighborID] else { continue }
                        let p2 = CGPoint(x: center.x + CGFloat(p2n.x) * base * scale,
                                         y: center.y + CGFloat(p2n.y) * base * scale)
                        let alpha = max(0.08, min(0.35, Double(n.weight) * 0.35))
                        var path = Path(); path.move(to: p1); path.addLine(to: p2)
                        let stroke = theme.isLight
                            ? Color.black.opacity(alpha * 0.35)
                            : Color.white.opacity(alpha * 0.35)
                        ctx.stroke(path, with: .color(stroke),
                                   lineWidth: 0.5 + CGFloat(n.weight) * 1.5)
                    }
                }

                // Nodes (recency → size)
                let dateByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0.createdAt) })
                for (id, p) in coordinates {
                    guard dateByID[id] != nil else { continue }
                    let pt = CGPoint(x: center.x + CGFloat(p.x) * base * scale,
                                     y: center.y + CGFloat(p.y) * base * scale)
                    let days = max(0, Date().timeIntervalSince(dateByID[id] ?? Date()) / 86_400)
                    let r = CGFloat(4.0 + max(0.0, 10.0 - days)) // newer slightly larger
                    let fill = theme.isLight ? Color.black.opacity(0.8) : Color.white.opacity(0.9)
                    let nodeRect = CGRect(x: pt.x - r/2, y: pt.y - r/2, width: r, height: r)
                    ctx.fill(Path(ellipseIn: nodeRect), with: .color(fill))
                    if !theme.isLight {
                        ctx.stroke(Path(ellipseIn: nodeRect.insetBy(dx: -1.0, dy: -1.0)),
                                   with: .color(Color.white.opacity(0.15)))
                    }
                }
            }
            // Gestures
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(width: lastDrag.width + value.translation.width,
                                        height: lastDrag.height + value.translation.height)
                    }
                    .onEnded { _ in lastDrag = offset }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in scale = max(0.5, min(3.0, lastScale * value)) }
                    .onEnded { _ in lastScale = scale }
            )
            // Auto-fit first open & when node set changes
            .onAppear {
                if !didAutoFit {
                    scale = fitScale(for: size)
                    didAutoFit = true
                }
            }
            .onChange(of: coordinates.count) {
                scale = fitScale(for: size)
            }
        }
        .background(
            ZStack {
                LinearGradient(colors: theme.palette.horoscopeCardBackground,
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                DLAssetImage.heroBackground.resizable().scaledToFill()
                    .opacity(theme.isLight ? 0.18 : 0.12)
            }.ignoresSafeArea()
        )
        .overlay(alignment: .topTrailing) {
            Button {
                let reset = {
                    scale = 1.0
                    offset = .zero
                    lastDrag = .zero
                    lastScale = 1.0
                }
                if reduceMotion {
                    reset()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { reset() }
                }
            } label: {
                Text("Reset")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(theme.palette.capsuleFill, in: Capsule())
            }
            .padding(12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dream constellation. Use two fingers to zoom and one finger to pan.")
    }

    private func fitScale(for size: CGSize) -> CGFloat {
        let rmax = coordinates.values.map { hypot($0.x, $0.y) }.max() ?? 0
        guard rmax > 0 else { return 1.0 }
        // base = 0.48 * min(size); target radius ≈ 0.44 * min(size)
        let s = 0.44 / (0.48 * max(0.25, rmax))
        return min(3.0, max(0.6, s))
    }
}


