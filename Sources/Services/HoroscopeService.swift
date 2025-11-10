import Foundation
@MainActor
final class HoroscopeService: ObservableObject {
    static let shared = HoroscopeService()

    private struct ReadRequest: Encodable {
        let uid: String
        let period: String
        let tz: String
        let birthInstantUTC: TimeInterval
        let tzID: String
        let placeText: String
        let timeKnown: Bool
    }

    private struct ComposeRequest: Encodable {
        let uid: String
        let period: String
        let tz: String
        let force: Bool
        let forceRefresh: Bool
        let birthInstantUTC: TimeInterval
        let tzID: String
        let placeText: String
        let timeKnown: Bool
    }

    private struct BirthSnapshot {
        let instantUTC: TimeInterval
        let tzID: String
        let placeText: String
        let timeKnown: Bool
    }

    private struct HoroscopeEnvelope: Decodable {
        let item: HoroscopeStructured
        let cached: Bool?
        let anchorKey: String?
        let model: String?
        let expiresAt: Date?

        private enum CodingKeys: String, CodingKey {
            case item
            case cached
            case anchorKey
            case model
            case expiresAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            item = try container.decode(HoroscopeStructured.self, forKey: .item)
            cached = try container.decodeIfPresent(Bool.self, forKey: .cached)
            anchorKey = try container.decodeIfPresent(String.self, forKey: .anchorKey)
            if let expiresString = try container.decodeIfPresent(String.self, forKey: .expiresAt) {
                expiresAt = HoroscopeService.isoFormatter.date(from: expiresString)
            } else {
                expiresAt = nil
            }
            model = try container.decodeIfPresent(String.self, forKey: .model)
        }
    }

    nonisolated(unsafe) private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static let decoder: JSONDecoder = {
        JSONDecoder()
    }()

    private let baseURL: URL?
    private let defaults: UserDefaults
    private let cacheKey = "horoscope.lastShown.v2"
    private var cacheStoreBacking: [String: HoroscopeStructured]?

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let base = Bundle.main.object(forInfoDictionaryKey: "FunctionsBaseURL") as? String,
           let url = URL(string: base), !base.isEmpty {
            self.baseURL = url
        } else {
            self.baseURL = nil
        }
    }

    // MARK: - Public API

    func cached(period: HoroscopeRange,
                tz: String,
                uid: String = "me",
                reference: Date = Date()) -> HoroscopeStructured? {
        let anchorKey = Self.makeAnchorKey(uid: uid, period: period, tzIdentifier: tz, reference: reference)
        return cached(anchorKey: anchorKey, asOf: reference)
    }
    
    func cached(period: HoroscopeRange,
                tz: String,
                uid: String = "me",
                referenceDate: Date) -> HoroscopeStructured? {
        cached(period: period, tz: tz, uid: uid, reference: referenceDate)
    }
    
    func fetchBestDays(uid: String = "me") async throws -> [BestDayInfo] {
        guard let baseURL = baseURL else { throw URLError(.badURL) }
        
        let endpoint = baseURL.appendingPathComponent("bestDaysForWeek")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "uid": uid,
            "birthISO": "" // TODO: Get from user profile
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct BestDaysResponse: Decodable {
            let days: [BestDayResponseItem]
            
            struct BestDayResponseItem: Decodable {
                let date: String
                let title: String
                let reason: String
                let dreamContext: String?
            }
        }
        
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(BestDaysResponse.self, from: data)
        
        let dateFormatter = ISO8601DateFormatter()
        
        return envelope.days.compactMap { day in
            guard let date = dateFormatter.date(from: day.date) else { return nil }
            return BestDayInfo(
                date: date,
                title: day.title,
                reason: day.reason,
                dreamContext: day.dreamContext
            )
        }
    }

    func readOrCompose(period: HoroscopeRange,
                       tz: String,
                       uid: String = "me",
                       force: Bool = false,
                       reference: Date = Date()) async throws -> HoroscopeStructured {
        guard baseURL != nil else { throw URLError(.badURL) }

        let anchorKey = Self.makeAnchorKey(uid: uid, period: period, tzIdentifier: tz, reference: reference)

        var fallback: HoroscopeStructured?
        if !force, let cached = cached(anchorKey: anchorKey, asOf: reference), !cached.isExpired(asOf: reference) {
            fallback = cached
        }

        let birthSnapshot = makeBirthSnapshot()

        let fresh = try await fetchRemote(
            period: period,
            tz: tz,
            uid: uid,
            force: force,
            fallback: fallback,
            birth: birthSnapshot,
            reference: reference
        )
        store(fresh)
        return fresh
    }
    
    func readOrCompose(period: HoroscopeRange,
                       tz: String,
                       uid: String = "me",
                       force: Bool = false,
                       referenceDate: Date) async throws -> HoroscopeStructured {
        try await readOrCompose(period: period,
                                tz: tz,
                                uid: uid,
                                force: force,
                                reference: referenceDate)
    }

    func anchorKey(for period: HoroscopeRange,
                   tz: String,
                   uid: String = "me",
                   reference: Date = Date()) -> String {
        Self.makeAnchorKey(uid: uid, period: period, tzIdentifier: tz, reference: reference)
    }

    // MARK: - Cache

    private var cacheStore: [String: HoroscopeStructured] {
        get {
            if cacheStoreBacking == nil {
                cacheStoreBacking = Self.loadCache(from: defaults, key: cacheKey)
            }
            return cacheStoreBacking ?? [:]
        }
        set {
            cacheStoreBacking = newValue
            Self.saveCache(newValue, to: defaults, key: cacheKey)
        }
    }

    private func cached(anchorKey: String, asOf reference: Date = Date()) -> HoroscopeStructured? {
        var store = cacheStore
        if let value = store[anchorKey] {
            if value.isExpired(asOf: reference) {
                store.removeValue(forKey: anchorKey)
                cacheStore = store
                return nil
            }
            return value
        }
        return nil
    }

    private func store(_ item: HoroscopeStructured) {
        var store = cacheStore
        store[item.anchorKey] = item
        pruneExpired(in: &store)
        cacheStore = store
    }

    private func pruneExpired(in store: inout [String: HoroscopeStructured], asOf date: Date = Date()) {
        for (key, value) in store where value.isExpired(asOf: date) {
            store.removeValue(forKey: key)
        }
    }

    private static func loadCache(from defaults: UserDefaults, key: String) -> [String: HoroscopeStructured] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        if var decoded = try? decoder.decode([String: HoroscopeStructured].self, from: data) {
            let now = Date()
            decoded = decoded.filter { !$0.value.isExpired(asOf: now) }
            return decoded
        }
        return [:]
    }

    private static func saveCache(_ cache: [String: HoroscopeStructured], to defaults: UserDefaults, key: String) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(cache) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }

    // MARK: - Networking

    private func fetchRemote(period: HoroscopeRange,
                             tz: String,
                             uid: String,
                             force: Bool,
                             fallback: HoroscopeStructured?,
                             birth: BirthSnapshot,
                             reference: Date) async throws -> HoroscopeStructured {
        if !force, let readHit = await attemptRead(period: period, tz: tz, uid: uid, birth: birth) {
            return readHit
        }

        do {
            let request = try makeRequest(
                path: "horoscopeCompose",
                body: ComposeRequest(
                    uid: uid,
                    period: period.rawValue,
                    tz: tz,
                    force: force,
                    forceRefresh: force,
                    birthInstantUTC: birth.instantUTC,
                    tzID: birth.tzID,
                    placeText: birth.placeText,
                    timeKnown: birth.timeKnown
                )
            )
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                if let fallback { return fallback }
                throw URLError(.badServerResponse)
            }

            let envelope = try Self.decoder.decode(HoroscopeEnvelope.self, from: data)
            return envelope.item
        } catch {
            if let fallback { return fallback }
            throw error
        }
    }

    private func attemptRead(period: HoroscopeRange, tz: String, uid: String, birth: BirthSnapshot) async -> HoroscopeStructured? {
        do {
            let request = try makeRequest(
                path: "horoscopeRead",
                body: ReadRequest(
                    uid: uid,
                    period: period.rawValue,
                    tz: tz,
                    birthInstantUTC: birth.instantUTC,
                    tzID: birth.tzID,
                    placeText: birth.placeText,
                    timeKnown: birth.timeKnown
                )
            )
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }

            switch http.statusCode {
            case 200:
                let envelope = try Self.decoder.decode(HoroscopeEnvelope.self, from: data)
                return envelope.item
            case 404:
                return nil
            default:
                return nil
            }
        } catch {
            return nil
        }
    }

    private func makeBirthSnapshot() -> BirthSnapshot {
        let profile = ProfileService.shared.birth
        return BirthSnapshot(
            instantUTC: profile.instantUTC.timeIntervalSince1970,
            tzID: profile.tzID,
            placeText: profile.placeText,
            timeKnown: profile.timeKnown
        )
    }

    private func makeRequest<T: Encodable>(path: String, body: T) throws -> URLRequest {
        guard let baseURL else { throw URLError(.badURL) }
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        return request
    }

    // MARK: - Anchor helper

    static func makeAnchorKey(uid: String, period: HoroscopeRange, tzIdentifier: String, reference: Date = Date()) -> String {
        let timeZone = TimeZone(identifier: tzIdentifier) ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let startOfDay = calendar.startOfDay(for: reference)
        let start: Date

        switch period {
        case .day:
            start = startOfDay
        case .week:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startOfDay)
            start = calendar.date(from: components) ?? startOfDay
        case .month:
            var components = calendar.dateComponents([.year, .month], from: startOfDay)
            components.day = 1
            start = calendar.date(from: components) ?? startOfDay
        case .year:
            let year = calendar.component(.year, from: startOfDay)
            start = calendar.date(from: DateComponents(calendar: calendar, year: year, month: 1, day: 1)) ?? startOfDay
        }

        let startUTCString = isoFormatter.string(from: start)

        struct AnchorPayload: Encodable {
            let uid: String
            let period: String
            let tz: String
            let startUTC: String
        }

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(AnchorPayload(uid: uid, period: period.rawValue, tz: tzIdentifier, startUTC: startUTCString)), !data.isEmpty else {
            return UUID().uuidString
        }

        let base64 = data.base64EncodedString()
        let urlSafe = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return urlSafe
    }
}
