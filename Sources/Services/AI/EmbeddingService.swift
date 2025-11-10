import Foundation

struct EmbeddingRequest: Codable { let texts: [String] }
struct EmbeddingResponse: Codable { let vectors: [[Double]] }

@MainActor
final class EmbeddingService {
    static let shared = EmbeddingService()
    private init() {}

    private func chunk(_ text: String, maxChars: Int = 800, maxChunks: Int = 4) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= maxChars { return [trimmed] }
        let seps = CharacterSet(charactersIn: "\n.?!")
        var parts: [String] = []
        var current = ""
        for token in trimmed.split(whereSeparator: {
            guard let scalar = $0.unicodeScalars.first else { return false }
            return seps.contains(scalar)
        }) {
            let piece = (String(token) + ".").trimmingCharacters(in: .whitespacesAndNewlines)
            if current.count + piece.count + 1 <= maxChars {
                current += (current.isEmpty ? "" : " ") + piece
            } else {
                if !current.isEmpty { parts.append(current) }
                current = piece
            }
            if parts.count >= maxChunks { break }
        }
        if parts.count < maxChunks && !current.isEmpty { parts.append(current) }
        if parts.isEmpty { parts = [String(trimmed.prefix(maxChars))] }
        return Array(parts.prefix(maxChunks))
    }

    private func withRetry<T>(_ op: @escaping () async throws -> T) async throws -> T {
        var delay: UInt64 = 300_000_000
        for attempt in 0..<5 {
            do { return try await op() } catch {
                if attempt == 4 { throw error }
                let jitter = UInt64(Int.random(in: -100_000_000...100_000_000))
                try? await Task.sleep(nanoseconds: delay &+ jitter)
                delay = min(delay * 2, 5_000_000_000)
            }
        }
        throw URLError(.cannotLoadFromNetwork)
    }

    func embed(_ texts: [String]) async throws -> [[Float]] {
        guard let url = HoroscopeService.shared.apiEndpoint(path: "embedText") else { throw URLError(.badURL) }
        return try await withRetry {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(EmbeddingRequest(texts: texts))
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
            let decoded = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
            return decoded.vectors.map { $0.map { Float($0) } }
        }
    }

    func embedChunked(_ text: String) async throws -> [Float] {
        let chunks = chunk(text)
        if chunks.count == 1 { return try await embed([chunks[0]]).first ?? [] }
        let vecs = try await embed(chunks)
        guard !vecs.isEmpty else { return [] }
        var acc = Array(repeating: Float(0), count: vecs[0].count)
        var total: Float = 0
        for (i, v) in vecs.enumerated() {
            let w = Float(chunks[i].count)
            total += w
            for j in 0..<v.count { acc[j] += v[j] * w }
        }
        if total > 0 {
            for j in 0..<acc.count { acc[j] /= total }
        }
        return acc
    }
}

