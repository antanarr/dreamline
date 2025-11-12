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
    public let explanation: OracleExplanation?
    public var maxScore: Float { topHits.first?.score ?? 0 }
    public var isAlignmentEvent: Bool { maxScore >= dynamicThreshold }
    
    public init(anchorKey: String,
                headline: String,
                summary: String?,
                horoscopeEmbedding: [Float],
                topHits: [ResonanceHit],
                dynamicThreshold: Float,
                explanation: OracleExplanation? = nil) {
        self.anchorKey = anchorKey
        self.headline = headline
        self.summary = summary
        self.horoscopeEmbedding = horoscopeEmbedding
        self.topHits = topHits
        self.dynamicThreshold = dynamicThreshold
        self.explanation = explanation
    }
}

public struct OracleExplanation: Codable, Hashable {
    public let lead: String
    public let body: String?
    public let chips: [String]
    public let generatedAt: Date

    public init(lead: String,
                body: String? = nil,
                chips: [String] = [],
                generatedAt: Date = Date()) {
        self.lead = lead
        self.body = body
        self.chips = chips
        self.generatedAt = generatedAt
    }
}

