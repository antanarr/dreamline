import SwiftUI

/// Non-intrusive inline CTA for Best Days. Replaces the full-width overlay button.
struct BestDaysTeaser: View {
    var title: String = "Your Best Days"
    var subtitle: String = "Glance ahead to when the cosmos leans your way."
    var actionTitle: String = "See Best Days"
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                ProBadge()
            }
            .accessibilityElement(children: .combine)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(action: onTap) {
                Text(actionTitle)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.dlViolet.opacity(0.16), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("See Best Days (Pro)")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.05), Color.dlViolet.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .accessibilityElement(children: .contain)
    }
}

