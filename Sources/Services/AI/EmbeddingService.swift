import Foundation

// MARK: - Types

public typealias DLVector = [Float]

public struct EmbeddingServiceConfig: Sendable {
    public let dimension: Int
    public let chunkCharThreshold: Int
    public let maxRetries: Int
    public let baseJitterMs: UInt64
    public let parallelism: Int

    public init(
        dimension: Int = 1536,
        chunkCharThreshold: Int = 1800,
        maxRetries: Int = 3,
        baseJitterMs: UInt64 = 120,
        parallelism: Int = 4
    ) {
        self.dimension = dimension
        self.chunkCharThreshold = chunkCharThreshold
        self.maxRetries = maxRetries
        self.baseJitterMs = baseJitterMs
        self.parallelism = max(1, parallelism)
    }
}

/// A single item to embed. `id` must be stable so results can be mapped back.
public struct EmbeddingItem: Sendable, Hashable {
    public let id: String
    public let text: String
    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

// MARK: - Backend protocol

public protocol EmbeddingBackend: Sendable {
    /// Produce a Float32 vector for a single chunk of text.
    func embedChunk(_ text: String, dimension: Int) async throws -> DLVector
}

/// Default on-device backend with deterministic, fast hash-based embeddings.
/// This is *not* a semantic model; it is a development placeholder that preserves
/// vector shape/flow and allows end-to-end wiring and scoring locally.
public struct LocalEmbeddingBackend: EmbeddingBackend {
    public init() {}
    public func embedChunk(_ text: String, dimension: Int) async throws -> DLVector {
        var vec = [Float](repeating: 0, count: dimension)
        // Simple frequency-hash projection into `dimension` buckets.
        // Deterministic across runs/platforms.
        var acc: Float = 0
        for scalar in text.unicodeScalars {
            let v = UInt32(truncatingIfNeeded: scalar.value &* 2654435761) // Knuth multiplicative hash
            let idx = Int(v % UInt32(dimension))
            // Lightweight feature value; mix with a small rolling accumulator.
            acc = fmodf(acc + Float((v & 0xFF)) / 255.0, 1.0)
            vec[idx] += 1.0 + acc
        }
        return EmbeddingService.normalize(vec)
    }
}

// MARK: - Service

public actor EmbeddingService {
    public static let shared = EmbeddingService()

    private let backend: EmbeddingBackend
    private let config: EmbeddingServiceConfig

    public init(backend: EmbeddingBackend = LocalEmbeddingBackend(),
                config: EmbeddingServiceConfig = .init()) {
        self.backend = backend
        self.config = config
    }

    /// Embed a batch of items and return a stable id → vector map.
    /// - Behavior:
    ///   - Paragraph-chunks long texts (~1.8k chars threshold).
    ///   - Embeds each chunk, then length-weighted average → L2 normalize.
    ///   - Retries chunk requests with exponential jitter (for remote backends).
    public func embed(items: [EmbeddingItem]) async throws -> [String: DLVector] {
        if items.isEmpty { return [:] }

        var result: [String: DLVector] = [:]
        result.reserveCapacity(items.count)

        // Simple bounded parallelism
        let groups = items.chunked(maxChunkSize: max(1, items.count / config.parallelism))
        for group in groups {
            try await withThrowingTaskGroup(of: (String, DLVector).self) { tg in
                for item in group {
                    tg.addTask { [backend, config] in
                        let chunks = EmbeddingService.chunk(text: item.text, threshold: config.chunkCharThreshold)
                        var weighted = [Float](repeating: 0, count: config.dimension)
                        var totalWeight: Float = 0

                        for c in chunks {
                            let weight = Float(c.count)
                            let vec = try await EmbeddingService.retrying(maxRetries: config.maxRetries, baseJitterMs: config.baseJitterMs) {
                                try await backend.embedChunk(c, dimension: config.dimension)
                            }
                            // Sum (length-weighted)
                            vDSP_add(weighted, vec, weight: weight, into: &weighted)
                            totalWeight += weight
                        }

                        let averaged = totalWeight > 0 ? weighted.map { $0 / totalWeight } : weighted
                        return (item.id, EmbeddingService.normalize(averaged))
                    }
                }

                for try await (id, vector) in tg {
                    result[id] = vector
                }
            }
        }

        return result
    }

    // MARK: - Utilities

    /// Split text by paragraphs, greedily packing until threshold.
    static func chunk(text: String, threshold: Int) -> [String] {
        guard text.count > threshold else { return [text] }
        let parts = text.components(separatedBy: CharacterSet.newlines)
        var chunks: [String] = []
        var buffer = ""
        buffer.reserveCapacity(threshold)

        func flush() {
            if !buffer.isEmpty {
                chunks.append(buffer)
                buffer.removeAll(keepingCapacity: true)
            }
        }

        for line in parts {
            if buffer.count + line.count + 1 > threshold {
                flush()
            }
            if buffer.isEmpty {
                buffer = line
            } else {
                buffer.append("\n")
                buffer.append(line)
            }
        }
        flush()
        return chunks.isEmpty ? [text] : chunks
    }

    /// L2-normalize a vector; returns zero-vector if norm is ~0.
    static func normalize(_ v: DLVector) -> DLVector {
        var sum: Float = 0
        for x in v { sum += x * x }
        let norm = sqrtf(sum)
        guard norm > 1e-8 else { return [Float](repeating: 0, count: v.count) }
        return v.map { $0 / norm }
    }

    /// Retry helper with exponential backoff + jitter (ms).
    static func retrying<T>(maxRetries: Int, baseJitterMs: UInt64, _ op: @escaping () async throws -> T) async throws -> T {
        var attempt = 0
        while true {
            do { return try await op() }
            catch {
                attempt += 1
                if attempt > maxRetries { throw error }
                let exp = UInt64(1 << (attempt - 1))
                let jitter = UInt64.random(in: 0...(baseJitterMs * exp))
                try? await Task.sleep(nanoseconds: (baseJitterMs * exp + jitter) * 1_000_000)
            }
        }
    }
}

// MARK: - vDSP-lite helpers (no Accelerate dependency)

@inline(__always)
private func vDSP_add(_ a: [Float], _ b: [Float], weight: Float, into out: inout [Float]) {
    // out = a + (b * weight); weighted accumulation
    let n = min(a.count, b.count, out.count)
    for i in 0..<n {
        out[i] = a[i] + b[i] * weight
    }
}

// MARK: - Small stdlib helpers

private extension Array {
    func chunked(maxChunkSize: Int) -> [[Element]] {
        guard maxChunkSize > 0, count > maxChunkSize else { return [self] }
        var res: [[Element]] = []
        res.reserveCapacity((count / maxChunkSize) + 1)
        var i = 0
        while i < count {
            let j = Swift.min(i + maxChunkSize, count)
            res.append(Array(self[i..<j]))
            i = j
        }
        return res
    }
}
