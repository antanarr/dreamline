import SwiftUI

/// Reframed as Alignment Ahead (value-first, subtle). We keep the name for call-site stability.
struct BestDaysView: View {
    let days: [BestDayInfo]
    let isPro: Bool
    let onViewFull: () -> Void
    let onUnlock: () -> Void

    var body: some View {
        if FeatureFlags.alignmentAheadEnabled {
            VStack(alignment: .leading, spacing: 12) {
                AlignmentAheadPreview()

                AlignmentAheadTeaser(onTap: {
                    onUnlock()
                    NotificationCenter.default.post(
                        name: .presentPaywall,
                        object: nil,
                        userInfo: ["source": DLAnalytics.PaywallSource.alignmentAheadTeaser.rawValue]
                    )
                })
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

