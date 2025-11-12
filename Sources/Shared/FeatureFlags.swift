import Foundation

public enum FeatureFlags {
    /// UI surfacing of alignment pill/chips in Today.
    public static var resonanceUIEnabled: Bool = true

    /// Constellation canvas rendering (off by default; graph still maintained).
    public static var constellationCanvasEnabled: Bool = false

    /// Alignment Ahead (forward resonance windows) UI.
    public static var alignmentAheadEnabled: Bool = true
    
    /// Extended Oracle explanations (lead + body paragraphs)
    public static var oracleExplanationsEnabled: Bool = true
    
    /// Oracle paywall for deeper readings
    public static var oraclePaywallEnabled: Bool = true
    
    /// "All About You" personalized report
    public static var oracleAllAboutYouEnabled: Bool = true
}

