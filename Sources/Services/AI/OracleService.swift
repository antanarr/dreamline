import Foundation

struct SymbolOccurrence: Codable, Hashable {
    var name: String
    var count: Int
}

struct OracleExtraction: Codable {
    var symbols: [SymbolOccurrence]
    var tone: String
    var archetypes: [String]
}

struct DreamInterpretSymbol: Codable, Hashable {
    var name: String
    var meaning: String
    var confidence: Double
}

struct DreamInterpretation: Codable, Hashable {
    var headline: String
    var summary: String
    var psychology: String
    var astrology: String?
    var symbols: [DreamInterpretSymbol]
    var actions: [String]
    var disclaimer: String
}

protocol OracleClient {
    func extract(from text: String) async throws -> OracleExtraction
    func interpret(dreamText: String,
                   extraction: OracleExtraction,
                   transit: TransitSummary) async throws -> DreamInterpretation
    func interpret(dreamText: String,
                   extraction: OracleExtraction,
                   transit: TransitSummary,
                   history: MotifHistory) async throws -> DreamInterpretation
}

extension OracleClient {
    func interpret(dreamText: String,
                   extraction: OracleExtraction,
                   transit: TransitSummary,
                   history: MotifHistory) async throws -> DreamInterpretation {
        return try await interpret(dreamText: dreamText, extraction: extraction, transit: transit)
    }
}

final class CloudOracleClient: OracleClient {
    private let baseURL = (Bundle.main.object(forInfoDictionaryKey: "FunctionsBaseURL") as? String) ?? ""
    let model: String = (Bundle.main.object(forInfoDictionaryKey: "OracleModel") as? String) ?? "gpt-4.1-mini"
    
    func extract(from text: String) async throws -> OracleExtraction {
        guard !baseURL.isEmpty else {
            throw URLError(.badURL)
        }
        
        struct Req: Encodable {
            let dream: String
            let model: String
        }
        
        var req = URLRequest(url: URL(string: "\(baseURL)/oracleExtract")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(Req(dream: text, model: model))
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(OracleExtraction.self, from: data)
    }
    
    func interpret(dreamText: String,
                   extraction: OracleExtraction,
                   transit: TransitSummary) async throws -> DreamInterpretation {
        return try await interpret(dreamText: dreamText, extraction: extraction, transit: transit, history: MotifHistory(topSymbols: [], archetypeTrends: [], userPhrases: [], tones7d: [:]))
    }
    
    func interpret(dreamText: String,
                   extraction: OracleExtraction,
                   transit: TransitSummary,
                   history: MotifHistory) async throws -> DreamInterpretation {
        guard !baseURL.isEmpty else {
            throw URLError(.badURL)
        }
        
        struct Req: Encodable {
            let dream: String
            let extraction: OracleExtraction
            let transit: TransitSummary
            let history: MotifHistory
            let model: String
        }
        
        var req = URLRequest(url: URL(string: "\(baseURL)/oracleInterpret")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(Req(dream: dreamText, extraction: extraction, transit: transit, history: history, model: model))
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(DreamInterpretation.self, from: data)
    }
}

final class StubOracleClient: OracleClient {
    func extract(from text: String) async throws -> OracleExtraction {
        // Stupid-simple heuristic stub; replace with LLM later.
        let dictionary = ["water","ocean","river","house","room","door","flight","teeth","death","bird"]
        
        let lower = text.lowercased()
        let counts = dictionary.map { word in
            SymbolOccurrence(name: word, count: lower.components(separatedBy: word).count - 1)
        }.filter { $0.count > 0 }
        
        let tone = lower.contains("fear") || lower.contains("anxious") ? "anxious" : "curious"
        let archetypes = counts.contains(where: { $0.name == "door" }) ? ["threshold"] : ["journey"]
        
        return OracleExtraction(symbols: counts, tone: tone, archetypes: archetypes)
    }
    
    func interpret(dreamText: String,
                   extraction: OracleExtraction,
                   transit: TransitSummary) async throws -> DreamInterpretation {
        return try await interpret(dreamText: dreamText, extraction: extraction, transit: transit, history: MotifHistory(topSymbols: [], archetypeTrends: [], userPhrases: [], tones7d: [:]))
    }
    
    func interpret(dreamText: String,
                   extraction: OracleExtraction,
                   transit: TransitSummary,
                   history: MotifHistory) async throws -> DreamInterpretation {
        let topSymbol = extraction.symbols.sorted(by: { $0.count > $1.count }).first?.name ?? "symbol"
        let archetypes = extraction.archetypes.joined(separator: ", ")
        let headline = "\(topSymbol.capitalized) is knocking"
        let summary = "Your dream surfaces \(archetypes.isEmpty ? "deep feeling" : archetypes) while \(transit.headline.lowercased())."
        let psychology = "Notice how \(topSymbol) appears—what does it want you to acknowledge?"
        let astroDetail = transit.notes.isEmpty ? nil : "\(transit.headline): \(transit.notes.joined(separator: " · "))"
        let symbols = extraction.symbols.prefix(4).map { occ in
            DreamInterpretSymbol(
                name: occ.name,
                meaning: "\((occ.name).capitalized) often signals this emotional current returning for dialogue.",
                confidence: min(1.0, max(0.2, Double(occ.count) / 3.0))
            )
        }
        let actions = [
            "Write one sentence about the feeling that lingers after the dream.",
            "Name a small, compassionate action that honors the message behind \(topSymbol)."
        ]
        return DreamInterpretation(
            headline: headline,
            summary: summary,
            psychology: psychology,
            astrology: astroDetail,
            symbols: Array(symbols),
            actions: actions,
            disclaimer: "Dreamline reflects on symbols; it is not medical advice. Trust your inner sense."
        )
    }
}

// Compatibility adapter for existing code
// Note: This synchronous wrapper is temporary for backward compatibility
// Prefer using StubOracleClient directly with async/await in new code
struct OracleService {
    private let client = StubOracleClient()
    
    func interpret(text: String) -> DreamInterpretation {
        // Synchronous wrapper - blocks until async work completes
        // This is a compatibility layer; new code should use async methods directly
        let group = DispatchGroup()
        var result: DreamInterpretation?
        
        group.enter()
        Task { @MainActor in
            defer { group.leave() }
            do {
                let extraction = try await client.extract(from: text)
                let transit = await AstroService.shared.transits(for: .now)
                let interpretation = try await client.interpret(dreamText: text, extraction: extraction, transit: transit)
                
                result = interpretation
            } catch {
                result = DreamInterpretation(
                    headline: "Reflection in progress",
                    summary: "Dreamline couldn't interpret this entry right now, but the imagery is still important.",
                    psychology: "Revisit one feeling from the dream and note how it shows up in waking life today.",
                    astrology: nil,
                    symbols: [],
                    actions: [
                        "Write one line describing the strongest emotion the dream evoked.",
                        "Take a slow breath, place a hand on your chest, and notice any shifts through the day."
                    ],
                    disclaimer: "Dreamline offers reflective guidance, never a diagnosis. Seek professional support when needed."
                )
            }
        }
        
        group.wait()
        return result!
    }
}
