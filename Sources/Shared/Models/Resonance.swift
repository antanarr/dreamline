import Foundation

public struct ResonanceHit: Codable, Hashable, Identifiable {
    public var id: String { dreamID }
    public let dreamID: String
    public let score: Float
    public let overlapSymbols: [String]
    public let createdAt: Date
}

public struct ResonanceBundle: Codable, Hashable {
    public let anchorKey: String
    public let headline: String
    public let summary: String?
    public let horoscopeEmbedding: [Float]
    public let topHits: [ResonanceHit]
    public let dynamicThreshold: Float
    public var maxScore: Float { topHits.first?.score ?? 0 }
    public var isAlignmentEvent: Bool { maxScore >= dynamicThreshold }
}

