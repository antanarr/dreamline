import Foundation
import CoreGraphics
import CryptoKit

struct Neighbor: Codable, Hashable {
    let id: String
    let weight: Float
    let lastTouched: Date
}

@MainActor
final class ConstellationStore {
    static let shared = ConstellationStore()
    private init() {
        load()
        loadCoords()
    }

    private(set) var neighbors: [String: [Neighbor]] = [:]
    // Normalized node coordinates: [-1, 1] in both axes
    private(set) var coordinates: [String: CGPoint] = [:]
    private let coordsKey = "dreamline.constellation.coords.v1"
    private let k = 5
    private let threshold: Float = 0.65

    private func cosine(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0
        var na: Float = 0
        var nb: Float = 0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            na += a[i] * a[i]
            nb += b[i] * b[i]
        }
        let denom = (na.squareRoot() * nb.squareRoot())
        return denom > 0 ? (dot / denom) : 0
    }

    private func timeDecayWeight(since date: Date, tauDays: Float = 21) -> Float {
        let days = Float(max(0, Date().timeIntervalSince(date) / 86_400))
        return exp(-days / tauDays)
    }

    func rebuild(from dreams: [DreamEntry]) async {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date.distantPast
        let nodes = dreams.filter { $0.createdAt >= cutoff && ($0.embedding?.isEmpty == false) }
        var map: [String: [Neighbor]] = [:]
        for i in 0..<nodes.count {
            let a = nodes[i]
            guard let va = a.embedding else { continue }
            var nbs: [Neighbor] = []
            for j in 0..<nodes.count where j != i {
                let b = nodes[j]
                guard let vb = b.embedding else { continue }
                let sim = cosine(va, vb) * max(timeDecayWeight(since: a.createdAt), timeDecayWeight(since: b.createdAt))
                if sim >= threshold {
                    nbs.append(Neighbor(id: b.id, weight: sim, lastTouched: Date()))
                }
            }
            nbs.sort { $0.weight > $1.weight }
            map[a.id] = Array(nbs.prefix(k))
        }
        neighbors = map
        save()

        let nodeMeta: [(id: String, createdAt: Date)] = dreams.map { ($0.id, $0.createdAt) }
        let current = Set(coordinates.keys)
        let target  = Set(nodeMeta.map { $0.id })
        if coordinates.isEmpty || current != target {
            coordinates = radialLayout(nodes: nodeMeta)
        }
        saveCoords()
    }

    func topNeighbors(of id: String) -> [Neighbor] {
        neighbors[id] ?? []
    }

    private func jitterForID(_ id: String, amplitude: CGFloat) -> CGPoint {
        let digest = SHA256.hash(data: Data(id.utf8))
        let bytes = Array(digest)
        func unit(_ b: UInt8) -> CGFloat { CGFloat(b) / 255.0 }
        let jx = (unit(bytes[0]) * 2 - 1) * amplitude
        let jy = (unit(bytes[1]) * 2 - 1) * amplitude
        return CGPoint(x: jx, y: jy)
    }

    private func radialLayout(nodes: [(id: String, createdAt: Date)],
                              jitter amplitude: CGFloat = 0.05) -> [String: CGPoint] {
        guard !nodes.isEmpty else { return [:] }
        let sorted = nodes.sorted { $0.createdAt > $1.createdAt }
        let n = sorted.count
        var result: [String: CGPoint] = [:]
        for (i, node) in sorted.enumerated() {
            let t = CGFloat(i) / max(1, CGFloat(n - 1))
            let r = 0.15 + 0.85 * t
            let angle = CGFloat(i) * (2 * .pi / max(1, CGFloat(n)))
            var x = cos(angle) * r
            var y = sin(angle) * r
            let jit = jitterForID(node.id, amplitude: amplitude)
            x += jit.x
            y += jit.y
            result[node.id] = CGPoint(x: x, y: y)
        }
        return result
    }

    private func url() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("ConstellationStore.json")
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(neighbors)
            try data.write(to: url())
        } catch {
            print("Constellation save error: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: url())
            neighbors = try JSONDecoder().decode([String: [Neighbor]].self, from: data)
        } catch {
            neighbors = [:]
        }
    }

    private func loadCoords() {
        guard let data = UserDefaults.standard.data(forKey: coordsKey),
              let decoded = try? JSONDecoder().decode([String: [Double]].self, from: data) else { return }
        var map: [String: CGPoint] = [:]
        for (id, xy) in decoded where xy.count == 2 {
            map[id] = CGPoint(x: xy[0], y: xy[1])
        }
        coordinates = map
    }

    private func saveCoords() {
        let enc = coordinates.mapValues { [Double($0.x), Double($0.y)] }
        if let data = try? JSONEncoder().encode(enc) {
            UserDefaults.standard.set(data, forKey: coordsKey)
        }
    }
}

