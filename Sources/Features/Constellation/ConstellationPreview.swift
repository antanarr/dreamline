import SwiftUI

struct ConstellationPreview: View {
    @Environment(ThemeService.self) private var theme

    let entries: [DreamEntry]
    let neighbors: [String: [ConstellationStore.Neighbor]]
    let coordinates: [String: CGPoint]
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your dream constellation")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Button(action: onOpen) {
                    Text("Open")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.plain)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: theme.palette.horoscopeCardBackground,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        DLAssetImage.heroBackground
                            .resizable()
                            .scaledToFill()
                            .opacity(theme.isLight ? 0.22 : 0.14)
                    )
                ConstellationMiniCanvas(entries: entries,
                                        neighbors: neighbors,
                                        coordinates: coordinates)
                    .padding(8)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your dream constellation preview.")
    }
}

private struct ConstellationMiniCanvas: View {
    @Environment(ThemeService.self) private var theme
    let entries: [DreamEntry]
    let neighbors: [String: [ConstellationStore.Neighbor]]
    let coordinates: [String: CGPoint]

    var body: some View {
        GeometryReader { proxy in
            let base = min(proxy.size.width, proxy.size.height) * 0.46
            let center = CGPoint(x: proxy.size.width/2, y: proxy.size.height/2)
            Canvas { ctx, _ in
                var drawn = Set<String>()
                for (a, neighs) in neighbors {
                    guard let p1n = coordinates[a] else { continue }
                    let p1 = CGPoint(x: center.x + CGFloat(p1n.x) * base,
                                     y: center.y + CGFloat(p1n.y) * base)
                    for n in neighs {
                        let key = a < n.id ? "\(a)|\(n.id)" : "\(n.id)|\(a)"
                        if !drawn.insert(key).inserted { continue }
                        guard let p2n = coordinates[n.id] else { continue }
                        let p2 = CGPoint(x: center.x + CGFloat(p2n.x) * base,
                                         y: center.y + CGFloat(p2n.y) * base)
                        let alpha = max(0.06, min(0.22, Double(n.weight) * 0.25))
                        var path = Path(); path.move(to: p1); path.addLine(to: p2)
                        let stroke = theme.isLight
                            ? Color.black.opacity(alpha * 0.35)
                            : Color.white.opacity(alpha * 0.35)
                        ctx.stroke(path, with: .color(stroke),
                                   lineWidth: 0.5 + CGFloat(n.weight) * 1.2)
                    }
                }
                let dateByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0.createdAt) })
                for (id, p) in coordinates {
                    guard dateByID[id] != nil else { continue }
                    let pt = CGPoint(x: center.x + CGFloat(p.x) * base,
                                     y: center.y + CGFloat(p.y) * base)
                    let r: CGFloat = 4.5
                    let fill = theme.isLight ? Color.black.opacity(0.85) : Color.white.opacity(0.9)
                    ctx.fill(Path(ellipseIn: CGRect(x: pt.x - r/2, y: pt.y - r/2, width: r, height: r)),
                             with: .color(fill))
                }
            }
        }
    }
}


