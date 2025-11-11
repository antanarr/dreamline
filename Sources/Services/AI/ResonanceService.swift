import Foundation

public enum ResonanceMath {
    @inlinable
    public static func cosine(_ a: [Float], _ b: [Float]) -> Float {
        let n = min(a.count, b.count)
        if n == 0 { return 0 }
        var dot: Float = 0, na: Float = 0, nb: Float = 0
        for i in 0..<n {
            let x = a[i], y = b[i]
            dot += x * y
            na  += x * x
            nb  += y * y
        }
        let denom = sqrtf(na) * sqrtf(nb)
        return denom > 1e-8 ? dot / denom : 0
    }

    @inlinable
    public static func timeDecayWeight(deltaDays: Float, tauDays: Float = ResonanceConfig.TIME_DECAY_TAU_DAYS) -> Float {
        guard deltaDays.isFinite else { return 0 }
        return expf(-deltaDays / max(tauDays, 1e-3))
    }

    /// p‑tile in [0,1], guards for small samples.
    public static func percentile(_ values: [Float], p: Float) -> Float {
        let c = values.count
        guard c >= 1 else { return 0 }
        let clippedP = min(max(p, 0), 1)
        let sorted = values.sorted()
        if c == 1 { return sorted[0] }
        let idx = Int(floorf(Float(c - 1) * clippedP))
        return sorted[idx]
    }
}

public actor ResonanceService {
    public static let shared = ResonanceService()

    private var scoreHistory: [String: [Float]] = [:]               // anchorKey → last ~60 scores
    private var lastBundleByAnchor: [String: ResonanceBundle] = [:] // anchorKey → last shown bundle
    private var cache: [String: (bundle: ResonanceBundle, createdAt: Date)] = [:]

    func buildBundle(anchorKey: String,
                     headline: String,
                     summary: String,
                     horoscopeEmbedding: [Float]?,
                     dreams: [DreamEntry],
                     now: Date = Date()) async -> ResonanceBundle? {
        if let cached = cache[anchorKey],
           now.timeIntervalSince(cached.createdAt) < 24 * 60 * 60 {
            return cached.bundle.isAlignmentEvent ? cached.bundle : nil
        }
        let text = headline + "\n" + summary
        // 1) Ensure horoscope embedding
        let hVec: [Float]
        if let he = horoscopeEmbedding, he.isEmpty == false {
            hVec = he
        } else {
            let map = try? await EmbeddingService.shared.embed(items: [EmbeddingItem(id: "horoscope:\(anchorKey)", text: text)])
            hVec = map?["horoscope:\(anchorKey)"] ?? []
        }
        guard !hVec.isEmpty else { return nil }

        // 2) Gather recent dreams & ensure embeddings
        let cutoff = Calendar.current.date(byAdding: .day, value: -ResonanceConfig.RESONANCE_LOOKBACK_DAYS, to: now) ?? now
        let recent = dreams.filter { $0.createdAt >= cutoff }
        if recent.isEmpty { return nil }

        // Embed any missing
        let missing = recent.filter { ($0.embedding ?? []).isEmpty }
        var idToVec: [String: [Float]] = [:]
        if !missing.isEmpty {
            let items = missing.map { EmbeddingItem(id: $0.id, text: $0.rawText) }
            let map = try? await EmbeddingService.shared.embed(items: items)
            idToVec = map ?? [:]
        }

        // 3) Horoscope symbols for overlap
        let horoscopeSymbols = SymbolExtractor.extract(from: text, max: ResonanceConfig.SYMBOLS_MAX)

        // 4) Score dreams
        var scores: [(dream: DreamEntry, score: Float, overlap: [String])] = []
        scores.reserveCapacity(recent.count)
        let nowStart = Calendar.current.startOfDay(for: now)

        for d in recent {
            let dVec = !(d.embedding ?? []).isEmpty ? (d.embedding ?? []) : (idToVec[d.id] ?? [])
            if dVec.isEmpty { continue }
            let days = Float(Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: d.createdAt), to: nowStart).day ?? 0)
            let cos = ResonanceMath.cosine(hVec, dVec)
            let weight = ResonanceMath.timeDecayWeight(deltaDays: days)
            let score = cos * weight

            let dreamSymbols = (d.symbols ?? SymbolExtractor.extract(from: d.rawText, max: ResonanceConfig.SYMBOLS_MAX))
            let overlap = Array(Set(horoscopeSymbols).intersection(Set(dreamSymbols)))

            scores.append((d, score, overlap))
        }

        if scores.isEmpty { return nil }

        // 5) Thresholding: dynamic p90 if enough history; else fallback
        let key = anchorKey
        let rawScores = scores.map { $0.score }
        let prior = scoreHistory[key] ?? []
        let historySlice = Array((prior + rawScores).suffix(60))
        scoreHistory[key] = historySlice

        let threshold: Float
        if historySlice.count >= 10 {
            threshold = max(ResonanceMath.percentile(historySlice, p: ResonanceConfig.RESONANCE_PERCENTILE), ResonanceConfig.RESONANCE_MIN_BASE)
        } else {
            threshold = ResonanceConfig.RESONANCE_MIN_BASE
        }

        // 6) Select top hits ≥ threshold and with at least one overlap symbol
        let top = scores
            .filter { $0.score >= threshold && !$0.overlap.isEmpty }
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { t in
                ResonanceHit(dreamID: t.dream.id,
                             score: t.score,
                             overlapSymbols: Array(t.overlap.prefix(ResonanceConfig.OVERLAP_MAX_VISUAL)),
                             createdAt: t.dream.createdAt)
            }

        let bundle = ResonanceBundle(anchorKey: key,
                                     headline: headline,
                                     summary: summary.isEmpty ? nil : summary,
                                     horoscopeEmbedding: hVec,
                                     topHits: Array(top),
                                     dynamicThreshold: threshold)

        DLAnalytics.log(.resonanceComputed(anchorKey: key,
                                           nDreams: recent.count,
                                           p90: (historySlice.count >= 10 ? ResonanceMath.percentile(historySlice, p: ResonanceConfig.RESONANCE_PERCENTILE) : ResonanceConfig.RESONANCE_MIN_BASE),
                                           threshold: threshold,
                                           nHits: bundle.topHits.count,
                                           topScore: bundle.topHits.first?.score ?? 0))

        cache[key] = (bundle, now)
        if bundle.isAlignmentEvent {
            lastBundleByAnchor[key] = bundle
            return bundle
        } else {
            lastBundleByAnchor[key] = bundle
            return nil
        }
    }

    /// Query helper for other features (e.g., Dream Detail badge).
    func isAligned(dreamID: String, anchorKey: String) -> Bool {
        guard let b = lastBundleByAnchor[anchorKey] else { return false }
        return b.topHits.contains(where: { $0.dreamID == dreamID })
    }

    func lastBundle(anchorKey: String) -> ResonanceBundle? {
        return lastBundleByAnchor[anchorKey]
    }

    func invalidateRecent(windowHours: Int = ResonanceConfig.RESONANCE_RECENT_PENALTY_HOURS, now: Date = Date()) {
        let cutoff = now.addingTimeInterval(TimeInterval(-windowHours * 3600))
        cache = cache.filter { (key, entry) in
            guard let ref = Self.anchorDate(from: key) else { return false }
            return ref < cutoff
        }
    }

    private static func anchorDate(from anchorKey: String) -> Date? {
        let parts = anchorKey.split(separator: "|")
        guard parts.count >= 4 else { return nil }
        let tzID = String(parts[2])
        let dateStr = String(parts[3])
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.timeZone = TimeZone(identifier: tzID)
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: dateStr)
    }

    #if DEBUG
    nonisolated static func anchorDateTestHook(anchorKey: String) -> Date? {
        return anchorDate(from: anchorKey)
    }
    #endif
}
