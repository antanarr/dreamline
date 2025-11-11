import CoreGraphics
import Foundation
import SwiftUI

/// Maintains a local dream↔dream graph for last ~90 days.
@MainActor
public final class ConstellationStore: ObservableObject {
    public static let shared = ConstellationStore()

    /// dreamID → list of neighbors (neighborID, weight, lastTouched)
    @Published public private(set) var neighbors: [String: [(neighborID: String, weight: Float, lastTouched: Date)]] = [:]

    /// Optional coordinates for a future canvas; persisted in UserDefaults.
    @Published public private(set) var coordinates: [String: CGPoint] = [:]

    private let coordsKey = "constellation.coordinates.v1"

    /// Convenience for views to gate UI without peeking into internals.
    public var hasGraph: Bool { neighbors.values.contains { !$0.isEmpty } }
    public var nodeCount: Int { neighbors.keys.count }
    public var averageDegree: Float {
        guard !neighbors.isEmpty else { return 0 }
        let sum = neighbors.values.map { $0.count }.reduce(0, +)
        return Float(sum) / Float(neighbors.count)
    }

    public init() {
        loadCoordinates()
    }

    /// Rebuild top‑k neighbors for recent dreams. Weight = cosine × time‑decay.
    func rebuild(from entries: [DreamEntry], now: Date = Date()) async {
        let cutoff = Calendar.current.date(byAdding: .day, value: -ResonanceConfig.RESONANCE_LOOKBACK_DAYS, to: now) ?? now
        let recent = entries.filter { $0.createdAt >= cutoff && (($0.embedding ?? []).isEmpty == false) }

        var map: [String: [(neighborID: String, weight: Float, lastTouched: Date)]] = [:]
        let n = recent.count
        guard n > 1 else {
            neighbors = [:]
            DLAnalytics.log(.constellationBuilt(nodes: n, avgDegree: 0))
            return
        }

        let byID = Dictionary(uniqueKeysWithValues: recent.map { ($0.id, $0) })
        let ids = recent.map { $0.id }

        for i in 0..<n {
            guard let di = byID[ids[i]], let vi = di.embedding, !vi.isEmpty else { continue }
            var heap: [(id: String, w: Float)] = []
            for j in 0..<n where j != i {
                guard let dj = byID[ids[j]], let vj = dj.embedding, !vj.isEmpty else { continue }
                let daysFromNow = Float(Calendar.current.dateComponents([.day],
                                                                         from: Calendar.current.startOfDay(for: max(di.createdAt, dj.createdAt)),
                                                                         to: Calendar.current.startOfDay(for: now)).day ?? 0)
                let cos = ResonanceMath.cosine(vi, vj)
                let w = cos * ResonanceMath.timeDecayWeight(deltaDays: daysFromNow)
                if w >= ResonanceConfig.GRAPH_EDGE_MIN {
                    heap.append((id: dj.id, w: w))
                }
            }
            heap.sort { $0.w > $1.w }
            let top = heap.prefix(ResonanceConfig.GRAPH_TOP_K)
            if !top.isEmpty {
                map[di.id] = top.map { (neighborID: $0.id, weight: $0.w, lastTouched: now) }
            }
        }

        neighbors = map
        let avgDegree = map.isEmpty ? 0 : Float(map.values.map { $0.count }.reduce(0, +)) / Float(map.count)
        DLAnalytics.log(.constellationBuilt(nodes: n, avgDegree: avgDegree))
        seedCoordinatesIfNeeded(ids: ids)
        saveCoordinates()
    }

    public func topNeighbors(for dreamID: String, k: Int = ResonanceConfig.GRAPH_TOP_K) -> [(id: String, weight: Float)] {
        let arr = neighbors[dreamID] ?? []
        return Array(arr.sorted { $0.weight > $1.weight }.prefix(k).map { ($0.neighborID, $0.weight) })
    }

    // MARK: - Coordinates persistence

    private func seedCoordinatesIfNeeded(ids: [String]) {
        guard coordinates.isEmpty else { return }
        let count = max(ids.count, 1)
        for (idx, id) in ids.enumerated() {
            let t = Double(idx) / Double(count)
            let angle = t * 2.0 * Double.pi
            coordinates[id] = CGPoint(x: CGFloat(cos(angle)), y: CGFloat(sin(angle)))
        }
    }

    private func saveCoordinates() {
        let enc = JSONEncoder()
        let dict = coordinates.mapValues { ["x": Double($0.x), "y": Double($0.y)] }
        if let data = try? enc.encode(dict) {
            UserDefaults.standard.set(data, forKey: coordsKey)
        }
    }

    private func loadCoordinates() {
        guard let data = UserDefaults.standard.data(forKey: coordsKey) else { return }
        if let dict = try? JSONDecoder().decode([String:[String:Double]].self, from: data) {
            var out: [String: CGPoint] = [:]
            for (k, v) in dict {
                if let x = v["x"], let y = v["y"] {
                    out[k] = CGPoint(x: x, y: y)
                }
            }
            coordinates = out
        }
    }
}
