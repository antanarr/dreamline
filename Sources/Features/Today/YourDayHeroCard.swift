import SwiftUI
import UIKit

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateHalo = false
    @State private var pulse = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundCard
                .overlay(heroHalo)
            
            VStack(alignment: .leading, spacing: 18) {
                // Header badge
                HStack(spacing: 8) {
                    DLAssetImage.oracleIcon
                        .renderingMode(.template)
                        .foregroundStyle(Color.white.opacity(0.9))
                        .frame(width: 18, height: 18)
                    Text("Day at a Glance")
                }
                .font(DLFont.body(13))
                .foregroundStyle(Color.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15), in: Capsule())

                // Alignment pill (if resonance detected)
                if FeatureFlags.resonanceUIEnabled, let rb = resonance, rb.isAlignmentEvent {
                    Button {
                        DLAnalytics.log(.alignmentTapthrough(dest: .dreamDetail))
                        onAlignmentTap?()
                    } label: {
                        ZStack {
                            Label("Today's Alignment", systemImage: "sparkles")
                                .font(DLFont.body(13))
                                .foregroundStyle(Color.white.opacity(0.95))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.18), in: Capsule())
                                .mysticalGlow(color: .dlMint, radius: 8)
                            Circle()
                                .strokeBorder(Color.white.opacity(0.22), lineWidth: 2.0)
                                .scaleEffect(pulse ? 1.18 : 0.95)
                                .opacity(pulse ? 0.0 : 0.6)
                                .animation(reduceMotion ? nil : .easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
                                .allowsHitTesting(false)
                        }
                        .goosebumpsMoment()
                    }
                    .buttonStyle(.plain)
                    .onAppear { pulse = true }
                    .accessibilityLabel("Today's Alignment")
                    .accessibilityValue(alignmentValue(rb))
                    .accessibilityAddTraits(.updatesFrequently)
                }
                
                // Main content container - FIX: Add proper spacing and containment
                VStack(alignment: .leading, spacing: 14) {
                    Text(headline)
                        .dlType(.titleXL)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                        .foregroundStyle(Color.white)
                    
                    if !summary.isEmpty {
                        Text(summary)
                            .dlType(.body)
                            .foregroundStyle(Color.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Overlap symbol chips (under main content)
                    if let r = resonance,
                       let first = r.topHits.first,
                       !first.overlapSymbols.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(Array(first.overlapSymbols.prefix(ResonanceConfig.OVERLAP_MAX_VISUAL)), id: \.self) { sym in
                                Text(sym.replacingOccurrences(of: "_", with: " "))
                                    .font(DLFont.body(13))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.16), in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }
                        .accessibilityLabel("Overlapping symbols: \(first.overlapSymbols.prefix(ResonanceConfig.OVERLAP_MAX_VISUAL).joined(separator: ", "))")
                    }
                    
                    // Action chips
                    if !doItems.isEmpty || !dontItems.isEmpty {
                        ActionChips(doItems: Array(doItems.prefix(2)),
                                    dontItems: Array(dontItems.prefix(2)))
                    }
                    
                    // Dream enhancement pill
                    if let enhancement = dreamEnhancement, !enhancement.isEmpty {
                        dreamEnhancementPill(enhancement)
                    }
                }
            }
            .padding(28)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .task {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                animateHalo = true
            }
        }
    }
    
    // MARK: - Background Components
    
    private var backgroundCard: some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)
        
        return GeometryReader { geo in
            shape
                .fill(
                    LinearGradient(
                        colors: theme.palette.horoscopeCardBackground,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    DLAssetImage.nebula
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .opacity(theme.isLight ? 0.38 : 0.5)
                        .blendMode(.screen)
                        .parallaxDrift(6)
                        .clipShape(shape)
                )
                .overlay(
                    DLAssetImage.starGrid
                        .resizable(resizingMode: .tile)
                        .scaleEffect(0.6)
                        .opacity(theme.isLight ? 0.12 : 0.2)
                        .blendMode(.screen)
                        .clipShape(shape)
                )
                .overlay(
                    DLAssetImage.grain
                        .resizable(resizingMode: .tile)
                        .opacity(theme.isLight ? 0.05 : 0.08)
                        .blendMode(.plusLighter)
                        .clipShape(shape)
                )
        }
    }
    
    private var heroHalo: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.32),
                        Color.white.opacity(0.0)
                    ],
                    center: .topTrailing,
                    startRadius: animateHalo ? 140 : 120,
                    endRadius: animateHalo ? 320 : 260
                )
            )
            .frame(width: 420, height: 420)
            .offset(x: 120, y: -140)
            .allowsHitTesting(false)
    }
    
    // MARK: - Enhancement Pill
    
    private func dreamEnhancementPill(_ enhancement: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            DLAssetImage.symbol("ocean")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(10)
                .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Dream weaving")
                    .dlType(.caption)
                    .foregroundStyle(Color.white.opacity(0.85))
                Text(enhancement)
                    .dlType(.body)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Dream weaving. \(enhancement)")
    }
    
    // MARK: - Helpers
    
    private func alignmentValue(_ rb: ResonanceBundle) -> String {
        if let hit = rb.topHits.first, let first = hit.overlapSymbols.first {
            return first.replacingOccurrences(of: "_", with: " ")
        }
        return "Active"
    }
}
