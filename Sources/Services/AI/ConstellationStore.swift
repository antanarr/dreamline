import Foundation
import SwiftUI
import CoreGraphics

@MainActor
final class ConstellationStore: ObservableObject {
    static let shared = ConstellationStore()

    struct Neighbor: Codable, Hashable {
        let id: String
        let weight: Float
        let lastTouched: Date
    }

    // Graph: node id → neighbors (top‑k with weights)
    @Published private(set) var neighbors: [String: [Neighbor]] = [:]
    // 2D coordinates normalized to [-1, 1]
    @Published private(set) var coordinates: [String: CGPoint] = [:]

    // Persistence keys
    private let neighborsKey = "dreamline.constellation.neighbors.v1"
    private let coordsKey    = "dreamline.constellation.coords.v1"

    private init() { load() }

    // Public surface
    var hasGraph: Bool { neighbors.values.contains { !$0.isEmpty } && coordinates.count >= 2 }
    var nodeCount: Int { neighbors.keys.count }
    var edgeCount: Int { neighbors.values.reduce(0) { $0 + $1.count } / 2 }

    func reset() {
        neighbors = [:]
        coordinates = [:]
        save()
    }

    // Build/refresh graph from dreams (last 90 days, up to 200 entries)
    func rebuild(from dreams: [DreamEntry], topK: Int = 5, threshold: Float = 0.65, tauDays: Float = 21) async {
        let now = Date()
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? .distantPast

        let nodes = dreams
            .filter { $0.createdAt >= cutoff && ($0.embedding?.isEmpty == false) }
            .prefix(200)

        guard !nodes.isEmpty else {
            neighbors = [:]
            coordinates = [:]
            save()
            return
        }

        // Indexable arrays
        let ids   = nodes.map { $0.id }
        let vecs  = nodes.map { $0.embedding! }   // safe due to filter above
        let dates = nodes.map { $0.createdAt }

        // Pairwise scores with time‑decay
        var adj: [String: [Neighbor]] = [:]
        for i in 0..<ids.count {
            var heap: [(String, Float, Date)] = []
            for j in 0..<ids.count where j != i {
                let sim = cosine(vecs[i], vecs[j])
                if sim <= 0 { continue }
                let recent = max(dates[i], dates[j])
                let w = sim * timeDecayWeight(since: recent, tauDays: tauDays)
                if w >= threshold { heap.append((ids[j], w, recent)) }
            }
            heap.sort { $0.1 > $1.1 }
            let top = heap.prefix(topK).map { Neighbor(id: $0.0, weight: $0.1, lastTouched: $0.2) }
            if !top.isEmpty { adj[ids[i]] = top }
        }

        neighbors = adj
        // Seed coordinates for any NEW nodes; preserve existing for stability
        assignInitialLayout(nodeIDs: Set(ids), dates: Dictionary(uniqueKeysWithValues: zip(ids, dates)))
        save()
    }

    // MARK: - Layout (radial by recency, stable angle + jitter by id hash)
    private func assignInitialLayout(nodeIDs: Set<String>, dates: [String: Date]) {
        var coords = coordinates // keep existing
        let sorted = nodeIDs.sorted { (dates[$0] ?? .distantPast) > (dates[$1] ?? .distantPast) }
        let n = max(sorted.count, 1)
        for (idx, id) in sorted.enumerated() {
            if coords[id] != nil { continue } // keep existing
            // recency in [0,1]: 0 newest, 1 oldest → newer closer to center
            let rec = n > 1 ? Float(idx) / Float(n - 1) : 0
            let r = 0.15 + (0.90 - 0.15) * Double(1 - rec) // 0.15..0.90
            let base = stableAngle(for: id)
            let jitter = stableJitter(for: id) * 0.08
            let theta = base + jitter
            coords[id] = CGPoint(x: r * cos(theta), y: r * sin(theta))
        }
        coordinates = coords
    }

    // MARK: - Persistence
    private func load() {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: neighborsKey),
           let decoded = try? JSONDecoder().decode([String: [Neighbor]].self, from: data) {
            neighbors = decoded
        }
        if let data = ud.data(forKey: coordsKey),
           let decoded = try? JSONDecoder().decode([String: [Double]].self, from: data) {
            var map: [String: CGPoint] = [:]
            decoded.forEach { id, xy in if xy.count == 2 { map[id] = CGPoint(x: xy[0], y: xy[1]) } }
            coordinates = map
        }
    }

    private func save() {
        let ud = UserDefaults.standard
        if let data = try? JSONEncoder().encode(neighbors) { ud.set(data, forKey: neighborsKey) }
        let compact: [String: [Double]] = coordinates.mapValues { [Double($0.x), Double($0.y)] }
        if let data = try? JSONEncoder().encode(compact) { ud.set(data, forKey: coordsKey) }
    }

    // MARK: - Math helpers
    private func cosine(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0, na: Float = 0, nb: Float = 0
        for i in 0..<a.count { dot += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i] }
        let denom = (na.squareRoot() * nb.squareRoot())
        return denom > 0 ? (dot/denom) : 0
    }
    private func timeDecayWeight(since date: Date, tauDays: Float = 21) -> Float {
        let days = Float(max(0, Date().timeIntervalSince(date) / 86_400))
        return exp(-days / tauDays)
    }
    private func stableAngle(for id: String) -> Double {
        var h: UInt64 = 1469598103934665603 // FNV offset
        for u in id.utf8 { h = (h ^ UInt64(u)) &* 1099511628211 }
        return Double(h % 6_283) / 1000.0 // ~[0, 2π)
    }
    private func stableJitter(for id: String) -> Double {
        var h: UInt64 = 7809847782465536322
        for u in id.utf8 { h = (h &+ UInt64(u)) &* 6364136223846793005 &+ 1 }
        return Double(h % 1_000) / 1_000.0 // [0,1)
    }
}


