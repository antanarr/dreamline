import SwiftUI

/// Small PRO badge used inline; avoids heavy chips.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.dlViolet.opacity(0.18), in: Capsule())
            .foregroundStyle(Color.dlViolet)
            .accessibilityLabel("Pro")
    }
}

