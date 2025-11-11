import Foundation

@MainActor
public struct RemoteConfigSnapshot: Equatable, Codable {
    public let horoscopeEnabled: Bool
    public let freeInterpretationsPerWeek: Int
    public let trialDaysPlus: Int
    public let upsellDelaySeconds: Int
    public let insightsBlurThresholdDays: Int
    public let paywallVariant: String
    public let freeChatTrialCount: Int
}

@MainActor
extension RemoteConfigService {
    func makeSnapshot() -> RemoteConfigSnapshot {
        RemoteConfigSnapshot(
            horoscopeEnabled: config.horoscopeEnabled,
            freeInterpretationsPerWeek: config.freeInterpretationsPerWeek,
            trialDaysPlus: config.trialDaysPlus,
            upsellDelaySeconds: config.upsellDelaySeconds,
            insightsBlurThresholdDays: config.insightsBlurThresholdDays,
            paywallVariant: config.paywallVariant,
            freeChatTrialCount: config.freeChatTrialCount
        )
    }
    
    static func defaultSnapshot() -> RemoteConfigSnapshot {
        let d = DLRemoteConfig.default
        return RemoteConfigSnapshot(
            horoscopeEnabled: d.horoscopeEnabled,
            freeInterpretationsPerWeek: d.freeInterpretationsPerWeek,
            trialDaysPlus: d.trialDaysPlus,
            upsellDelaySeconds: d.upsellDelaySeconds,
            insightsBlurThresholdDays: d.insightsBlurThresholdDays,
            paywallVariant: d.paywallVariant,
            freeChatTrialCount: d.freeChatTrialCount
        )
    }
}

