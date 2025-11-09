import XCTest
@testable import Dreamline

@MainActor
final class RemoteConfigDefaultsTests: XCTestCase {
    
    func test_defaultSnapshot_matchesCodeDefaults() {
        let expected = RemoteConfigService.defaultSnapshot()
        // Sanity invariants
        XCTAssertGreaterThanOrEqual(expected.insightsBlurThresholdDays, 1)
        XCTAssertGreaterThan(expected.upsellDelaySeconds, 0)
        XCTAssertGreaterThan(expected.trialDaysPlus, 0)
        // Deterministic defaults from DLRemoteConfig.default
        XCTAssertTrue(expected.horoscopeEnabled)
        XCTAssertEqual(expected.freeInterpretationsPerWeek, 3)
        XCTAssertEqual(expected.trialDaysPlus, 7)
        XCTAssertEqual(expected.upsellDelaySeconds, 6)
        XCTAssertEqual(expected.insightsBlurThresholdDays, 7)
        XCTAssertEqual(expected.paywallVariant, "A")
        XCTAssertEqual(expected.freeChatTrialCount, 2)
    }
    
    func test_makeSnapshot_isAvailableOnMainActor() {
        let live = RemoteConfigService.shared.makeSnapshot()
        // Shape checks (live may differ if remote overrides)
        XCTAssertGreaterThanOrEqual(live.insightsBlurThresholdDays, 1)
        XCTAssertGreaterThan(live.upsellDelaySeconds, 0)
    }
}


