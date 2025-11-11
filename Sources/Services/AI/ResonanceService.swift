import Foundation

@MainActor
final class ResonanceService {
    static let shared = ResonanceService()
    private init() {}

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

    private func percentile(_ xs: [Float], p: Float) -> Float {
        guard !xs.isEmpty else { return 0 }
        let s = xs.sorted()
        let idx = min(max(Int(Float(s.count - 1) * p), 0), s.count - 1)
        return s[idx]
    }

    private func ensureEmbeddingsOrdered(_ dreams: [DreamEntry],
                                         updater: @escaping (DreamEntry) -> Void) async {
        let toEmbed = dreams.filter {
            ($0.embedding == nil) && !$0.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !toEmbed.isEmpty else { return }
        let items = toEmbed.map { EmbeddingItem(id: $0.id, text: $0.rawText) }
        do {
            let resultMap = try await EmbeddingService.shared.embed(items: items)
            for dream in toEmbed {
                if let vec = resultMap[dream.id] {
                    var updated = dream
                    updated.embedding = vec
                    updater(updated)
                }
            }
        } catch {
            print("ensureEmbeddings error: \(error)")
        }
    }

    func buildResonance(anchorKey: String,
                        headline: String,
                        summary: String?,
                        dreams: [DreamEntry],
                        horoscopeEmbedding prefetched: [Float]?,
                        updater: @escaping (DreamEntry) -> Void) async -> ResonanceBundle? {
        var hEmbed = prefetched
        if hEmbed == nil {
            let text = [headline, summary ?? ""].joined(separator: "\n")
            do {
                let items = [EmbeddingItem(id: "hero_\(anchorKey)", text: text)]
                let resultMap = try await EmbeddingService.shared.embed(items: items)
                hEmbed = resultMap["hero_\(anchorKey)"]
            } catch {
                print("hero embed failed: \(error)")
            }
        }
        guard let hero = hEmbed, !hero.isEmpty else { return nil }

        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date.distantPast
        let recent = dreams
            .filter { $0.createdAt >= cutoff && !$0.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(200)

        await ensureEmbeddingsOrdered(Array(recent), updater: updater)

        let horoscopeSymbols = SymbolExtractor.shared.extract(from: [headline, summary ?? ""].joined(separator: " "), max: 10)

        var scored: [ResonanceHit] = []
        var allScores: [Float] = []
        for e in recent {
            guard let v = e.embedding else { continue }
            let base = cosine(hero, v)
            let w = timeDecayWeight(since: e.createdAt)
            let s = max(0, min(1, base * w))
            allScores.append(s)
            let overlap = Set(e.symbols ?? []).intersection(horoscopeSymbols).map { String($0) }
            scored.append(ResonanceHit(dreamID: e.id, score: s, overlapSymbols: overlap, createdAt: e.createdAt))
        }
        scored.sort { $0.score > $1.score }
        let top = Array(scored.prefix(3))

        let dyn: Float = (allScores.count >= 10) ? percentile(Array(allScores.prefix(60)), p: 0.90) : 0.78

        return ResonanceBundle(anchorKey: anchorKey,
                               headline: headline,
                               summary: summary,
                               horoscopeEmbedding: hero,
                               topHits: top,
                               dynamicThreshold: dyn)
    }
}

