import SwiftUI

struct YourDayHeroCard: View {
    let headline: String
    let summary: String
    let dreamEnhancement: String?
    let doItems: [String]
    let dontItems: [String]
    var resonance: ResonanceBundle?
    var onAlignmentTap: (() -> Void)?
    var onExplainResonance: (() -> Void)?
    var onDiveDeeper: (() -> Void)?
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        // CONTENT drives layout height. Background art is clipped to the card and doesn't use GeometryReader.
        VStack(alignment: .leading, spacing: 18) {
            // Header badge
            Text("Your day at a glance")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            
            // Alignment pill (optional, subtle)
            if FeatureFlags.resonanceUIEnabled, let rb = resonance, rb.isAlignmentEvent {
                Button {
                    DLAnalytics.log(.alignmentTapthrough(dest: .dreamDetail))
                    onAlignmentTap?()
                } label: {
                    Text("Today's Alignment")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.dlMint.opacity(0.16), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open today's alignment")
            }
            
            // Headline & summary (readable on dark)
            Text(headline)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(summary)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Optional overlap chips (trim to 2)
            if let first = resonance?.topHits.first, !first.overlapSymbols.isEmpty {
                let chips = first.overlapSymbols.prefix(ResonanceConfig.OVERLAP_MAX_VISUAL)
                HStack(spacing: 8) {
                    ForEach(Array(chips), id: \.self) { sym in
                        Text(sym.replacingOccurrences(of: "_", with: " "))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.dlMint.opacity(0.12), in: Capsule())
                            .foregroundStyle(Color.dlMint)
                    }
                }
                .accessibilityLabel("Overlapping symbols")
            }
            
            // Do/Don't chips (quiet)
            if !doItems.isEmpty || !dontItems.isEmpty {
                ActionChips(doItems: Array(doItems.prefix(2)),
                           dontItems: Array(dontItems.prefix(2)))
            }
            
            // Optional dream enhancement line
            if let tip = dreamEnhancement, !tip.isEmpty {
                Text(tip)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            
            // Explain link (free quick read)
            Button {
                onExplainResonance?()
            } label: {
                Text("Why this resonates")
                    .font(.footnote.weight(.semibold))
                    .underline()
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.palette.cardFillPrimary)
        )
        .overlay(alignment: .center) {
            // Decorative art that never affects layout. No GeometryReader; clipped by mask.
            ZStack {
                DLAssetImage.nebula
                    .resizable()
                    .scaledToFill()
                    .opacity(0.12)
                    .allowsHitTesting(false)
                
                DLAssetImage.starGrid
                    .resizable(resizingMode: .tile)
                    .scaleEffect(0.6)
                    .opacity(0.08)
                    .allowsHitTesting(false)
            }
            .clipped()
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
    }
}
