import Foundation

/// Lightweight, local keyword extractor for single‑word tokens.
/// Normalizes to lowercase snake_case, strips stopwords, caps to SYMBOLS_MAX.
public enum SymbolExtractor {
    private static let stopwords: Set<String> = [
        "the","a","an","and","or","but","if","then","than","when","while","for","to","of","in","on","at","by",
        "with","without","from","into","over","under","you","your","yours","is","are","was","were","be","being",
        "been","it","its","as","that","this","these","those","we","our","ours","i","me","my","mine","they","them",
        "their","theirs","he","she","his","her","hers","not","no","yes","do","does","did","done"
    ]

    public static func extract(from text: String, max: Int = ResonanceConfig.SYMBOLS_MAX) -> [String] {
        guard !text.isEmpty else { return [] }
        let lower = text.lowercased()
        var tokens: [String] = []
        var current = ""
        for ch in lower.unicodeScalars {
            if CharacterSet.alphanumerics.contains(ch) {
                current.unicodeScalars.append(ch)
            } else {
                flush(&current, into: &tokens)
            }
        }
        flush(&current, into: &tokens)

        var seen = Set<String>()
        var out: [String] = []
        out.reserveCapacity(max)
        for raw in tokens {
            if raw.count < 2 { continue }
            if stopwords.contains(raw) { continue }
            let norm = raw.replacingOccurrences(of: " ", with: "_")
            if !seen.contains(norm) {
                seen.insert(norm)
                out.append(norm)
                if out.count >= max { break }
            }
        }
        return out
    }

    private static func flush(_ current: inout String, into tokens: inout [String]) {
        if !current.isEmpty {
            tokens.append(current)
            current.removeAll(keepingCapacity: true)
        }
    }
}
