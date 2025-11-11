import Foundation

/// Minimal, swappable analytics shim. Replace with telemetry when ready.
public enum DLAnalytics {
    public enum Event {
        case alignmentShown(topScore: Float, overlapCount: Int)
    }
    
    @inlinable
    public static func log(_ event: Event) {
        #if DEBUG
        switch event {
        case let .alignmentShown(topScore, overlapCount):
            print("[analytics] alignment_shown topScore=\(String(format: "%.3f", topScore)) overlap=\(overlapCount)")
        }
        #endif
    }
}

