import Foundation

struct Neighbor: Codable, Hashable {
    let id: String
    let weight: Float
    let lastTouched: Date
}

@MainActor
final class ConstellationStore {
    static let shared = ConstellationStore()
    private init() { load() }

    private(set) var neighbors: [String: [Neighbor]] = [:]
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
    }

    func topNeighbors(of id: String) -> [Neighbor] {
        neighbors[id] ?? []
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
}

