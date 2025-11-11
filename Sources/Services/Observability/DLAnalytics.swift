import Foundation

public enum DLAnalytics {
    public enum TapDestination: String { case dreamDetail, interpretation }

    public enum Event {
        case alignmentShown(topScore: Float, overlapCount: Int)
        case alignmentTapthrough(dest: TapDestination)
        case resonanceComputed(anchorKey: String, nDreams: Int, p90: Float, threshold: Float, nHits: Int, topScore: Float)
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
        }
        #endif
    }
}
