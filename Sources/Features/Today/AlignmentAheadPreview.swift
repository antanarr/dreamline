import SwiftUI

/// One free preview for Alignment Ahead: show weekday; blur motif to build desire.
/// We intentionally do not depend on remote future data in this pass.
struct AlignmentAheadPreview: View {
    var anchorDate: Date = Date()
    /// Optional motif to show (we blur/redact on free tier; still helpful for a11y).
    var blurredMotifLabel: String = "•••• ••••••"

    private var weekdayName: String {
        let cal = Calendar.current
        // Heuristic “next window”: +3 days (tunable)
        let date = cal.date(byAdding: .day, value: 3, to: cal.startOfDay(for: anchorDate)) ?? anchorDate
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Alignment Ahead")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                ProBadge()
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(weekdayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(blurredMotifLabel)
                    .font(.body)
                    .redacted(reason: .privacy)
                    .accessibilityLabel("Motif preview is redacted")
            }

            Text("Peek what’s ahead")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.05))
        )
        .accessibilityElement(children: .contain)
    }
}

