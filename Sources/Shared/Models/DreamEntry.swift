import Foundation

struct DreamEntry: Identifiable, Codable, Hashable {
    var id: String
    var createdAt: Date
    var updatedAt: Date?
    var rawText: String
    var transcriptURL: URL?
    var symbols: [String]?
    var sentiment: String?
    var arousal: Double?
    var valence: Double?
    var oracleSummary: String?
    var extractedSymbols: [String]
    var themes: [String]
    var interpretation: DreamInterpretation?
    var embedding: [Float]?

    init(id: String = UUID().uuidString,
         createdAt: Date = .init(),
         updatedAt: Date? = nil,
         rawText: String,
         transcriptURL: URL? = nil,
         symbols: [String]? = nil,
         sentiment: String? = nil,
         arousal: Double? = nil,
         valence: Double? = nil,
         oracleSummary: String? = nil,
         extractedSymbols: [String] = [],
         themes: [String] = [],
         interpretation: DreamInterpretation? = nil,
         embedding: [Float]? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rawText = rawText
        self.transcriptURL = transcriptURL
        self.symbols = symbols
        self.sentiment = sentiment
        self.arousal = arousal
        self.valence = valence
        self.oracleSummary = oracleSummary
        self.extractedSymbols = extractedSymbols
        self.themes = themes
        self.interpretation = interpretation
        self.embedding = embedding
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case updatedAt
        case rawText
        case transcriptURL
        case symbols
        case sentiment
        case arousal
        case valence
        case oracleSummary
        case extractedSymbols
        case themes
        case interpretation
        case embedding
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.rawText = try c.decodeIfPresent(String.self, forKey: .rawText) ?? ""
        self.transcriptURL = try c.decodeIfPresent(URL.self, forKey: .transcriptURL)
        self.symbols = try c.decodeIfPresent([String].self, forKey: .symbols)
        self.sentiment = try c.decodeIfPresent(String.self, forKey: .sentiment)
        self.arousal = try c.decodeIfPresent(Double.self, forKey: .arousal)
        self.valence = try c.decodeIfPresent(Double.self, forKey: .valence)
        self.oracleSummary = try c.decodeIfPresent(String.self, forKey: .oracleSummary)
        self.extractedSymbols = try c.decodeIfPresent([String].self, forKey: .extractedSymbols) ?? []
        self.themes = try c.decodeIfPresent([String].self, forKey: .themes) ?? []
        self.interpretation = try c.decodeIfPresent(DreamInterpretation.self, forKey: .interpretation)

        if let f = try? c.decode([Float].self, forKey: .embedding) {
            self.embedding = f
        } else if let d = try? c.decode([Double].self, forKey: .embedding) {
            self.embedding = d.map { Float($0) }
        } else {
            self.embedding = nil
        }

        if symbols == nil, !extractedSymbols.isEmpty {
            symbols = extractedSymbols
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try c.encode(rawText, forKey: .rawText)
        try c.encodeIfPresent(transcriptURL, forKey: .transcriptURL)
        try c.encodeIfPresent(symbols, forKey: .symbols)
        try c.encodeIfPresent(sentiment, forKey: .sentiment)
        try c.encodeIfPresent(arousal, forKey: .arousal)
        try c.encodeIfPresent(valence, forKey: .valence)
        try c.encodeIfPresent(oracleSummary, forKey: .oracleSummary)
        try c.encode(extractedSymbols, forKey: .extractedSymbols)
        try c.encode(themes, forKey: .themes)
        try c.encodeIfPresent(interpretation, forKey: .interpretation)
        try c.encodeIfPresent(embedding, forKey: .embedding)
    }
}
