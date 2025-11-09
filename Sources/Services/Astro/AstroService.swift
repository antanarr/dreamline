import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#if canImport(FirebaseFirestoreSwift)
import FirebaseFirestoreSwift
#endif
#endif

struct BirthData: Codable, Equatable {
    var date: Date
    var time: Date
    var placeText: String
    var tzID: String
    var timeKnown: Bool
    
    init(date: Date, time: Date, placeText: String, tzID: String = TimeZone.current.identifier, timeKnown: Bool = true) {
        self.date = date
        self.time = time
        self.placeText = placeText
        self.tzID = tzID
        self.timeKnown = timeKnown
    }
}

extension BirthData {
    private func combinedDate() -> Date {
        let tz = TimeZone(identifier: tzID) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        var day = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        day.hour = timeComponents.hour
        day.minute = timeComponents.minute
        day.second = timeComponents.second
        return calendar.date(from: day) ?? date
    }
    
    func isoTimestamp() -> String {
        ISO8601DateFormatter().string(from: combinedDate())
    }
    
    func toBirthProfile() -> BirthProfile {
        BirthProfile(
            instantUTC: combinedDate(),
            tzID: tzID,
            placeText: placeText,
            timeKnown: timeKnown
        )
    }
}

struct TransitSummary: Codable, Equatable {
    var headline: String      // e.g., "Neptune trine Mercury"
    var notes: [String]       // short bullets
}

@MainActor
final class AstroService: ObservableObject {
    static let shared = AstroService()
    
    @Published private(set) var birth: BirthData?
    
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif
    private var uid: String { "me" } // replace with Auth later
    
    private init() {
        Task {
            await loadBirth()
        }
    }
    
    func saveBirth(_ data: BirthData) async throws {
        birth = data
        ProfileService.shared.updateBirth(data.toBirthProfile())
        
        #if canImport(FirebaseFirestore)
        #if canImport(FirebaseFirestoreSwift)
        try db.collection("users").document(uid)
            .collection("astro").document("birth")
            .setData(from: data, merge: true)
        #else
        // Fallback: manual encoding if FirebaseFirestoreSwift not available
        let encoder = Firestore.Encoder()
        let encoded = try encoder.encode(data)
        try await db.collection("users").document(uid)
            .collection("astro").document("birth")
            .setData(encoded, merge: true)
        #endif
        #endif
    }
    
    func loadBirth() async {
        #if canImport(FirebaseFirestore)
        do {
            let snap = try await db.collection("users").document(uid)
                .collection("astro").document("birth").getDocument()
            if let data = try? snap.data(as: BirthData.self) {
                self.birth = data
            }
        } catch { }
        #endif
    }
    
    func transits(for date: Date) async -> TransitSummary {
        // Stub: deterministic, replace with Swiss Ephemeris-backed server later.
        let weekday = Calendar.current.component(.weekday, from: date)
        let headline = (weekday % 2 == 0) ? "Neptune trine Mercury" : "Venus sextile Moon"
        let notes = [
            "Heightened intuition; trust soft signals.",
            "Light social ease; emotional articulation improves."
        ]
        return TransitSummary(headline: headline, notes: notes)
    }
}
