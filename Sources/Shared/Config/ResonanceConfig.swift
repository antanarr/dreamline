import Foundation

public enum ResonanceConfig {
    public static let RESONANCE_MIN_BASE: Float = 0.78          // fallback threshold with low history
    public static let RESONANCE_PERCENTILE: Float = 0.90        // dynamic threshold p‑tile
    public static let RESONANCE_LOOKBACK_DAYS: Int = 90
    public static let RESONANCE_RECENT_PENALTY_HOURS: Int = 48  // trigger re‑eval window
    public static let TIME_DECAY_TAU_DAYS: Float = 21
    public static let GRAPH_TOP_K: Int = 5
    public static let GRAPH_EDGE_MIN: Float = 0.65              // after decay
    public static let SYMBOLS_MAX: Int = 10
    public static let OVERLAP_MAX_VISUAL: Int = 2
}

