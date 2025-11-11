import Foundation

/// Anchor key builder to avoid hand-rolled strings across the app.
/// Format: uid|period|tz|yyyy-MM-dd
enum AnchorKey {
    static func day(uid: String, tz: String, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: tz)
        formatter.dateFormat = "yyyy-MM-dd"
        let day = formatter.string(from: date)
        return "\(uid)|day|\(tz)|\(day)"
    }
}

