import Foundation

struct DreamPattern: Identifiable, Hashable {
    let id: String
    let symbol: String
    let occurrences: Int
    let daySpan: Int
    let firstOccurrence: Date
    let lastOccurrence: Date
    
    var description: String {
        if daySpan == 0 {
            return "\(symbol) appeared \(occurrences) times today"
        } else {
            return "\(symbol) appeared \(occurrences) times over \(daySpan) days"
        }
    }
    
    var teaserText: String {
        "\(symbol.capitalized) symbols have been appearing..."
    }
}

