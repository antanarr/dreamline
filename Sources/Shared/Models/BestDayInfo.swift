import Foundation

struct BestDayInfo: Identifiable, Codable, Hashable {
    let id: String
    let date: Date
    let title: String
    let reason: String
    let dreamContext: String?
    
    init(id: String? = nil, date: Date, title: String, reason: String, dreamContext: String? = nil) {
        self.id = id ?? "\(date.timeIntervalSince1970)-\(title)"
        self.date = date
        self.title = title
        self.reason = reason
        self.dreamContext = dreamContext
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, title, reason, dreamContext
    }
}

