import Foundation

public enum DLAnalytics {
    public enum TapDestination: String { case dreamDetail, interpretation }
    public enum PaywallSource: String {
        case bestDaysTeaser
        case diveDeeperUpsell
        case alignmentExplainer
        case calendarPreview
        case alignmentAheadTeaser
    }

    public enum Event {
        case alignmentShown(topScore: Float, overlapCount: Int)
        case alignmentTapthrough(dest: TapDestination)
        case resonanceComputed(anchorKey: String, nDreams: Int, p90: Float, threshold: Float, nHits: Int, topScore: Float)
        case constellationBuilt(nodes: Int, avgDegree: Float)
        case dreamSaved(hasSymbols: Bool, lenChars: Int, embeddedOK: Bool)
        case calendarVisit(dateOffsetDays: Int)
        case paywallOpen(source: PaywallSource, secondsSinceAppear: TimeInterval)
        case oracleCTAClick(isPro: Bool)
        case deepReadView(wordCount: Int)
        case deepReadFetch(latencyMs: Int, model: String)
        case allAboutYouView
        case reportPurchase(price: String, source: String)
    }

    @inlinable
    public static func log(_ event: Event) {
        #if DEBUG
        switch event {
        case let .alignmentShown(topScore, overlapCount):
            print("[analytics] alignment_shown topScore=\(String(format: "%.3f", topScore)) overlap=\(overlapCount)")
        case let .alignmentTapthrough(dest):
            print("[analytics] alignment_tapthrough dest=\(dest.rawValue)")
        case let .resonanceComputed(anchorKey, nDreams, p90, threshold, nHits, topScore):
            print("[analytics] resonance_computed anchor=\(anchorKey) nDreams=\(nDreams) p90=\(String(format: "%.3f", p90)) threshold=\(String(format: "%.3f", threshold)) nHits=\(nHits) topScore=\(String(format: "%.3f", topScore))")
        case let .constellationBuilt(nodes, avgDegree):
            print("[analytics] constellation_built nodes=\(nodes) avgDegree=\(String(format: "%.2f", avgDegree))")
        case let .dreamSaved(hasSymbols, lenChars, embeddedOK):
            print("[analytics] dream_saved hasSymbols=\(hasSymbols) lenChars=\(lenChars) embeddedOK=\(embeddedOK)")
        case let .calendarVisit(dateOffsetDays):
            print("[analytics] calendar_visit offset_days=\(dateOffsetDays)")
        case let .paywallOpen(source, secondsSinceAppear):
            print("[analytics] paywall_open source=\(source.rawValue) sinceAppear=\(String(format: "%.2f", secondsSinceAppear))")
        case let .oracleCTAClick(isPro):
            print("[analytics] oracle_cta_click isPro=\(isPro)")
        case let .deepReadView(wordCount):
            print("[analytics] deep_read_view wordCount=\(wordCount)")
        case let .deepReadFetch(latencyMs, model):
            print("[analytics] deep_read_fetch latency=\(latencyMs)ms model=\(model)")
        case .allAboutYouView:
            print("[analytics] all_about_you_view")
        case let .reportPurchase(price, source):
            print("[analytics] report_purchase price=\(price) source=\(source)")
        }
        #endif
    }
}
