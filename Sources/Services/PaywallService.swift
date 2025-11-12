import Foundation
import SwiftUI

@MainActor
@Observable final class PaywallService {
    static let shared = PaywallService()
    
    var showPaywall = false
    var paywallContext: PaywallContext?
    
    private init() {}
    
    enum PaywallContext: Equatable {
        case lockedLifeArea(areaId: String)
        case dreamPatterns
        case bestDays
        case diveDeeper(areaId: String)
        case unlimitedInterpretations
        case deeperReading
        
        var title: String {
            switch self {
            case .lockedLifeArea:
                return "Unlock All Life Areas"
            case .dreamPatterns:
                return "Unlock Dream Pattern Analysis"
            case .bestDays:
                return "Unlock Best Days Calendar"
            case .diveDeeper:
                return "Dive Deeper with Pro"
            case .unlimitedInterpretations:
                return "Unlimited Interpretations"
            case .deeperReading:
                return "Deeper Oracle Readings"
            }
        }
        
        var message: String {
            switch self {
            case .lockedLifeArea:
                return "Get full access to all 6 life areas with personalized guidance every day."
            case .dreamPatterns:
                return "Discover recurring symbols and what they mean across your dream history."
            case .bestDays:
                return "See your best days for decisions, creativity, and connection based on astrology + dreams."
            case .diveDeeper:
                return "Get deeper insights with astrological explanations and dream correlations."
            case .unlimitedInterpretations:
                return "Upgrade to Pro for unlimited dream interpretations and full access to all features."
            case .deeperReading:
                return "See how your dreams and today's sky rhyme. Personalized deep dives and daily resonance with Pro."
            }
        }
    }
    
    func trigger(_ context: PaywallContext) {
        paywallContext = context
        showPaywall = true
    }
    
    func dismiss() {
        showPaywall = false
        // Clear context after a delay to allow animations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.paywallContext = nil
        }
    }
}

