import Foundation

public enum FeatureFlags {
    /// UI surfacing of alignment pill/chips in Today.
    public static var resonanceUIEnabled: Bool = true

    /// Constellation canvas rendering (off by default; graph still maintained).
    public static var constellationCanvasEnabled: Bool = false

    /// Alignment Ahead (forward resonance windows) UI.
    public static var alignmentAheadEnabled: Bool = true
}

