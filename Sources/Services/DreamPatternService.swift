import Foundation

@MainActor
final class DreamPatternService: ObservableObject {
    static let shared = DreamPatternService()
    
    private init() {}
    
    /// Analyzes dream entries to find recurring symbols
    /// - Parameters:
    ///   - store: The DreamStore containing dream entries
    ///   - days: Number of days to look back (default: 30)
    /// - Returns: Array of DreamPattern instances for symbols that appear 2+ times
    func analyzePatterns(from store: DreamStore, days: Int = 30) -> [DreamPattern] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentDreams = store.entries.filter { $0.createdAt >= cutoff }
        
        // Group by symbols
        var symbolCounts: [String: [Date]] = [:]
        for dream in recentDreams {
            for symbol in dream.symbols ?? [] {
                symbolCounts[symbol, default: []].append(dream.createdAt)
            }
        }
        
        // Find recurring patterns (2+ occurrences)
        let patterns = symbolCounts.compactMap { symbol, dates -> DreamPattern? in
            guard dates.count >= 2 else { return nil }
            let sorted = dates.sorted()
            let daySpan = Calendar.current.dateComponents([.day], from: sorted.first!, to: sorted.last!).day ?? 0
            
            return DreamPattern(
                id: symbol,
                symbol: symbol,
                occurrences: dates.count,
                daySpan: daySpan,
                firstOccurrence: sorted.first!,
                lastOccurrence: sorted.last!
            )
        }
        
        // Sort by most recent and most frequent
        return patterns.sorted {
            if $0.lastOccurrence != $1.lastOccurrence {
                return $0.lastOccurrence > $1.lastOccurrence
            }
            return $0.occurrences > $1.occurrences
        }
    }
    
    /// Gets the most prominent recurring pattern, if any
    func topPattern(from store: DreamStore, days: Int = 30) -> DreamPattern? {
        analyzePatterns(from: store, days: days).first
    }
}

