import SwiftUI

struct YourDayHeroCard: View {
    let headline: String
    let summary: String
    let dreamEnhancement: String?
    let doItems: [String]
    let dontItems: [String]
    var resonance: ResonanceBundle?
    var onAlignmentTap: (() -> Void)?
    var onDiveDeeper: (() -> Void)?
    var onExplainResonance: (() -> Void)?

    @Environment(ThemeService.self) private var theme: ThemeService

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your day at a glance")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)

            if FeatureFlags.resonanceUIEnabled, let rb = resonance, rb.isAlignmentEvent {
                alignmentRow(bundle: rb)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Today’s Alignment")
                    .accessibilityValue(alignmentValue(rb))
                    .accessibilityAddTraits(.updatesFrequently)

                Button {
                    onExplainResonance?()
                } label: {
                    Text("Why this resonates")
                        .font(.footnote.weight(.semibold))
                        .underline()
                }
                .buttonStyle(.plain)
            }

            Text(headline)
                .dlType(.titleM)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(summary)
                .dlType(.body)
                .foregroundStyle(.primary)

            if let s = dreamEnhancement {
                Text(s)
                    .dlType(.bodyS)
                    .foregroundStyle(.secondary)
            }

            ActionChips(doItems: doItems, dontItems: dontItems)

            Button {
                onDiveDeeper?()
            } label: {
                Text("Dive deeper")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.palette.cardFillPrimary)
        )
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func alignmentRow(bundle rb: ResonanceBundle) -> some View {
        HStack(spacing: 10) {
            Button {
                DLAnalytics.log(.alignmentTapthrough(dest: .dreamDetail))
                onAlignmentTap?()
            } label: {
                Text("Today’s Alignment")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.dlMint.opacity(0.16), in: Capsule())
            }
            .buttonStyle(.plain)

            if let hit = rb.topHits.first {
                ForEach(Array(hit.overlapSymbols.prefix(ResonanceConfig.OVERLAP_MAX_VISUAL)), id: \.self) { sym in
                    Text(sym.replacingOccurrences(of: "_", with: " "))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.dlMint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.dlMint.opacity(0.12), in: Capsule())
                        .accessibilityLabel("Symbol \(sym)")
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func alignmentValue(_ rb: ResonanceBundle) -> String {
        if let hit = rb.topHits.first, let first = hit.overlapSymbols.first {
            return first.replacingOccurrences(of: "_", with: " ")
        }
        return "Active"
    }
}

