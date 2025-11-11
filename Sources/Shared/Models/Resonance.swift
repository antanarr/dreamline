import Foundation

public struct ResonanceHit: Codable, Hashable, Identifiable {
    public var id: String { dreamID }
    public let dreamID: String
    public let score: Float
    public let overlapSymbols: [String]
    public let createdAt: Date
    
    public init(dreamID: String, score: Float, overlapSymbols: [String], createdAt: Date) {
        self.dreamID = dreamID
        self.score = score
        self.overlapSymbols = overlapSymbols
        self.createdAt = createdAt
    }
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
    
    public init(anchorKey: String,
                headline: String,
                summary: String?,
                horoscopeEmbedding: [Float],
                topHits: [ResonanceHit],
                dynamicThreshold: Float) {
        self.anchorKey = anchorKey
        self.headline = headline
        self.summary = summary
        self.horoscopeEmbedding = horoscopeEmbedding
        self.topHits = topHits
        self.dynamicThreshold = dynamicThreshold
    }
}

