import SwiftUI

struct InterpretButtonGate: View {
    let tier: Tier
    @ObservedObject var rc = RemoteConfigService.shared
    @StateObject var usage = UsageService.shared
    @State private var showPaywall = false
    @State private var weeklyCount: Int = 0
    
    var onInterpret: () -> Void
    
    private var remainingQuota: Int? {
        guard tier == .free else { return nil }
        let maxQuota = rc.config.freeInterpretationsPerWeek
        return max(0, maxQuota - weeklyCount)
    }
    
    private var buttonLabel: String {
        if let remaining = remainingQuota {
            return remaining > 0 ? "Interpret (\(remaining) left)" : "Interpret"
        }
        return "Interpret"
    }
    
    var body: some View {
        Button(buttonLabel) {
            Task {
                let count = await usage.weeklyInterpretCount(weekStart: Date())
                weeklyCount = count
                let gate = OracleGate.canInterpret(tier: tier, weeklyCount: count, rc: rc.config)
                
                switch gate {
                case .ok:
                    onInterpret()
                    await usage.incrementWeeklyInterpret(weekStart: Date())
                    weeklyCount = count + 1
                case .quotaDepleted, .needsPlus, .needsPro:
                    showPaywall = true
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            weeklyCount = await usage.weeklyInterpretCount(weekStart: Date())
        }
    }
}

