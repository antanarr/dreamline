import Foundation

/// The selectable range for horoscope content across the app.
public enum HoroscopeRange: String, CaseIterable, Codable, Hashable {
    case day, week, month, year
}

public extension HoroscopeRange {
    var displayTitle: String {
        switch self {
        case .day:   return "Day"
        case .week:  return "Week"
        case .month: return "Month"
        case .year:  return "Year"
        }
    }
}

