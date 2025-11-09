import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#if canImport(FirebaseFirestoreSwift)
import FirebaseFirestoreSwift
#endif
#endif

struct DLRemoteConfig: Codable {
    var horoscopeEnabled: Bool
    var freeInterpretationsPerWeek: Int
    var trialDaysPlus: Int
    var upsellDelaySeconds: Int
    var insightsBlurThresholdDays: Int
    var paywallVariant: String
    var freeChatTrialCount: Int
    
    static let `default` = DLRemoteConfig()
    
    init(
        horoscopeEnabled: Bool = true,
        freeInterpretationsPerWeek: Int = 3,
        trialDaysPlus: Int = 7,
        upsellDelaySeconds: Int = 6,
        insightsBlurThresholdDays: Int = 7,
        paywallVariant: String = "A",
        freeChatTrialCount: Int = 2
    ) {
        self.horoscopeEnabled = horoscopeEnabled
        self.freeInterpretationsPerWeek = freeInterpretationsPerWeek
        self.trialDaysPlus = trialDaysPlus
        self.upsellDelaySeconds = upsellDelaySeconds
        self.insightsBlurThresholdDays = insightsBlurThresholdDays
        self.paywallVariant = paywallVariant
        self.freeChatTrialCount = freeChatTrialCount
    }
    
    enum CodingKeys: String, CodingKey {
        case horoscopeEnabled
        case freeInterpretationsPerWeek
        case trialDaysPlus
        case upsellDelaySeconds
        case insightsBlurThresholdDays
        case paywallVariant
        case freeChatTrialCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        horoscopeEnabled = try container.decodeIfPresent(Bool.self, forKey: .horoscopeEnabled) ?? DLRemoteConfig.default.horoscopeEnabled
        freeInterpretationsPerWeek = try container.decodeIfPresent(Int.self, forKey: .freeInterpretationsPerWeek) ?? DLRemoteConfig.default.freeInterpretationsPerWeek
        trialDaysPlus = try container.decodeIfPresent(Int.self, forKey: .trialDaysPlus) ?? DLRemoteConfig.default.trialDaysPlus
        upsellDelaySeconds = try container.decodeIfPresent(Int.self, forKey: .upsellDelaySeconds) ?? DLRemoteConfig.default.upsellDelaySeconds
        insightsBlurThresholdDays = try container.decodeIfPresent(Int.self, forKey: .insightsBlurThresholdDays) ?? DLRemoteConfig.default.insightsBlurThresholdDays
        paywallVariant = try container.decodeIfPresent(String.self, forKey: .paywallVariant) ?? DLRemoteConfig.default.paywallVariant
        freeChatTrialCount = try container.decodeIfPresent(Int.self, forKey: .freeChatTrialCount) ?? DLRemoteConfig.default.freeChatTrialCount
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(horoscopeEnabled, forKey: .horoscopeEnabled)
        try container.encode(freeInterpretationsPerWeek, forKey: .freeInterpretationsPerWeek)
        try container.encode(trialDaysPlus, forKey: .trialDaysPlus)
        try container.encode(upsellDelaySeconds, forKey: .upsellDelaySeconds)
        try container.encode(insightsBlurThresholdDays, forKey: .insightsBlurThresholdDays)
        try container.encode(paywallVariant, forKey: .paywallVariant)
        try container.encode(freeChatTrialCount, forKey: .freeChatTrialCount)
    }
}

@MainActor
final class RemoteConfigService: ObservableObject {
    static let shared = RemoteConfigService()
    
    @Published private(set) var config: DLRemoteConfig = .default
    @Published private(set) var loading = false
    @Published private(set) var error: Error?
    
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif
    private let path = "config/current"
    private let cacheKey = "dreamline.remoteConfig.cache"
    
    private init() {
        loadCache()
        fetch()
    }
    
    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(DLRemoteConfig.self, from: data) else { return }
        config = cached
    }
    
    private func saveCache(_ rc: DLRemoteConfig) {
        if let data = try? JSONEncoder().encode(rc) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
    
    func fetch() {
        guard !loading else { return }
        loading = true
        error = nil
        
        #if canImport(FirebaseFirestore)
        db.document(path).getDocument(as: DLRemoteConfig.self) { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                self.loading = false
                switch result {
                case .success(let rc):
                    self.config = rc
                    self.saveCache(rc)
                case .failure(let err):
                    self.error = err
                    // keep defaults
                }
            }
        }
        #else
        loading = false
        // Keep defaults when Firestore is not available
        #endif
    }
}

