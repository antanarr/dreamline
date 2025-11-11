import Foundation

@MainActor
final class ProfileService: ObservableObject {
    static let shared = ProfileService()
    
    @Published private(set) var birth: BirthProfile
    
    private let defaults: UserDefaults
    private var observer: NSObjectProtocol?
    
    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.birth = BirthProfile.fromDefaults(defaults)
        
        observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncFromDefaults()
            }
        }
    }
    
    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func syncFromDefaults() {
        birth = BirthProfile.fromDefaults(defaults)
    }
    
    func updateBirth(_ profile: BirthProfile) {
        defaults.set(profile.instantUTC.timeIntervalSince1970, forKey: BirthDataKeys.timestamp)
        defaults.set(profile.timeKnown, forKey: BirthDataKeys.timeKnown)
        defaults.set(profile.placeText, forKey: BirthDataKeys.place)
        defaults.set(profile.tzID, forKey: BirthDataKeys.timezone)
        birth = profile
    }
    
    func resetBirth() {
        defaults.removeObject(forKey: BirthDataKeys.timestamp)
        defaults.removeObject(forKey: BirthDataKeys.timeKnown)
        defaults.removeObject(forKey: BirthDataKeys.place)
        defaults.removeObject(forKey: BirthDataKeys.timezone)
        birth = BirthProfile.fromDefaults(defaults)
    }
}

struct BirthProfile: Equatable {
    let instantUTC: Date
    let tzID: String
    let placeText: String
    let timeKnown: Bool
    
    static let empty = BirthProfile(
        instantUTC: Date(timeIntervalSince1970: 0),
        tzID: TimeZone.current.identifier,
        placeText: "",
        timeKnown: false
    )
    
    static func fromDefaults(_ defaults: UserDefaults) -> BirthProfile {
        let timestamp = defaults.double(forKey: BirthDataKeys.timestamp)
        guard timestamp > 0 else {
            return .empty
        }
        
        let tzID = defaults.string(forKey: BirthDataKeys.timezone) ?? TimeZone.current.identifier
        let place = defaults.string(forKey: BirthDataKeys.place) ?? ""
        let timeKnown = defaults.object(forKey: BirthDataKeys.timeKnown) as? Bool ?? true
        let instant = Date(timeIntervalSince1970: timestamp)
        return BirthProfile(
            instantUTC: instant,
            tzID: tzID,
            placeText: place,
            timeKnown: timeKnown
        )
    }
    
    func localDateComponents() -> DateComponents {
        let tz = TimeZone(identifier: tzID) ?? .current
        let calendar = Calendar(identifier: .gregorian)
        return calendar.dateComponents(in: tz, from: instantUTC)
    }
    
    func displayString() -> String {
        let tz = TimeZone(identifier: tzID) ?? .current
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = tz
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = timeKnown ? .short : .none
        
        var components: [String] = [dateFormatter.string(from: instantUTC)]
        if !placeText.isEmpty {
            components.append(placeText)
        }
        return components.joined(separator: " · ")
    }
    
    func isoString() -> String? {
        guard instantUTC.timeIntervalSince1970 > 0 else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: tzID) ?? .current
        return formatter.string(from: instantUTC)
    }
}

