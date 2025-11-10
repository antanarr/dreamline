import Foundation

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var summary: String = "Loading…"
    @Published var isLoading: Bool = true
    
    func load(dreamStore: DreamStore? = nil, date: Date = Date()) async {
        isLoading = true
        let transit = await AstroService.shared.transits(for: date)
        
        // Pull most recent dream themes/symbols from the store
        let recentMotif = extractRecentMotif(from: dreamStore)
        
        if let motif = recentMotif {
            summary = "\(motif.capitalized) × \(transit.headline): \(generateDreamSyncedMessage(motif: motif, transit: transit))."
        } else {
            summary = "\(transit.headline): \(generateGenericMessage(transit: transit))."
        }
        
        isLoading = false
    }
    
    private func extractRecentMotif(from store: DreamStore?) -> String? {
        guard let store = store, !store.entries.isEmpty else { return nil }
        
        // Try to find the most recent dream with interpreted symbols
        for entry in store.entries.prefix(5) {
            if !entry.extractedSymbols.isEmpty {
                return entry.extractedSymbols.first
            }
            if !entry.themes.isEmpty {
                return entry.themes.first
            }
        }
        
        // Fallback: extract a keyword from the most recent dream text
        if let latest = store.entries.first {
            let words = latest.rawText
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 4 && !stopWords.contains($0) }
            return words.first
        }
        
        return nil
    }
    
    private func generateDreamSyncedMessage(motif: String, transit: TransitSummary) -> String {
        let messages = [
            "today calls for reflection on \(motif.lowercased())",
            "a day to explore the \(motif.lowercased()) within",
            "let \(motif.lowercased()) guide your intentions",
            "gentle awareness of \(motif.lowercased()) emerges",
            "\(motif.lowercased()) resurfaces in new light"
        ]
        return messages.randomElement() ?? "the sky weaves with your inner world"
    }
    
    private func generateGenericMessage(transit: TransitSummary) -> String {
        let messages = [
            "today invites quiet reflection",
            "a moment for inward clarity",
            "the cosmos whispers gently",
            "tune into subtle shifts",
            "embrace what emerges naturally"
        ]
        return messages.randomElement() ?? "a day for gentle awareness"
    }
    
    private let stopWords: Set<String> = [
        "about", "after", "again", "before", "being", "could", "did", "does",
        "doing", "down", "during", "each", "from", "have", "having", "into",
        "more", "most", "other", "should", "such", "than", "that", "their",
        "them", "then", "there", "these", "they", "this", "through", "under",
        "very", "what", "when", "where", "which", "while", "will", "with",
        "would", "your", "dream", "dreamed", "dreaming", "dreams", "remember",
        "remembered", "felt", "feel", "feeling", "think", "thought", "seemed"
    ]
}

