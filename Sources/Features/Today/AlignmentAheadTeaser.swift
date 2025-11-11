import SwiftUI

/// Gentle inline CTA inviting the user to see upcoming in-phase windows.
struct AlignmentAheadTeaser: View {
    var title: String = "Alignment Ahead"
    var subtitle: String = "When the sky is likely to echo your current thread."
    var actionTitle: String = "See Alignment Ahead"
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
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
                    .background(Color.purple.opacity(0.16), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("See Alignment Ahead (Pro)")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.05), Color.purple.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .accessibilityElement(children: .contain)
    }
}

