import Foundation

final class SymbolExtractor {
    static let shared = SymbolExtractor()
    private init() {}

    private let stop: Set<String> = [
        "the","and","a","an","to","of","in","on","at","for","with","from","by","as","is","are","was","were","be","been",
        "it","that","this","these","those","i","you","he","she","we","they","me","my","your","our","their",
        "but","or","if","so","then","than","just","very","really","there","here"
    ]

    func extract(from text: String, max: Int = 10) -> [String] {
        let lower = text.lowercased()
        let words = lower.split { !$0.isLetter && $0 != "'" }
        var freq: [String: Int] = [:]
        for raw in words {
            let w = String(raw).trimmingCharacters(in: .punctuationCharacters)
            if w.count < 3 || stop.contains(w) { continue }
            freq[w, default: 0] += 1
        }
        let sorted = freq.sorted { $0.value > $1.value }.map { $0.key }
        return Array(sorted.prefix(max))
    }
}

