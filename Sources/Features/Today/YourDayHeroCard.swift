import SwiftUI
import UIKit

struct YourDayHeroCard: View {
    let headline: String
    let summary: String?
    let dreamEnhancement: String?
    let doItems: [String]
    let dontItems: [String]
    var resonance: ResonanceBundle?
    var showLogButton: Bool
    var onLogDream: (() -> Void)?
    var onAlignmentTap: (() -> Void)?
    
    init(headline: String,
         summary: String?,
         dreamEnhancement: String?,
         doItems: [String] = [],
         dontItems: [String] = [],
         resonance: ResonanceBundle? = nil,
         showLogButton: Bool = false,
         onLogDream: (() -> Void)? = nil,
         onAlignmentTap: (() -> Void)? = nil) {
        self.headline = headline
        self.summary = summary
        self.dreamEnhancement = dreamEnhancement
        self.doItems = doItems
        self.dontItems = dontItems
        self.resonance = resonance
        self.showLogButton = showLogButton
        self.onLogDream = onLogDream
        self.onAlignmentTap = onAlignmentTap
    }
    
    @Environment(ThemeService.self) private var theme: ThemeService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false
    @State private var animateHalo = false
    @State private var pulse = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundCard
                .parallax(12)
                .overlay(heroHalo)
            
            VStack(alignment: .leading, spacing: 18) {
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

                if FeatureFlags.resonanceUIEnabled, let rb = resonance, rb.isAlignmentEvent {
                    Button {
                        DLAnalytics.log(.alignmentTapthrough(dest: .dreamDetail))
                        onAlignmentTap?()
                    } label: {
                        ZStack {
                            Label("Today’s Alignment", systemImage: "sparkles")
                                .font(DLFont.body(13))
                                .foregroundStyle(Color.white.opacity(0.95))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.18), in: Capsule())
                            Circle()
                                .strokeBorder(Color.white.opacity(0.22), lineWidth: 2.0)
                                .scaleEffect(pulse ? 1.18 : 0.95)
                                .opacity(pulse ? 0.0 : 0.6)
                                .animation(reduceMotion ? nil : .easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
                                .allowsHitTesting(false)
                        }
                    }
                    .buttonStyle(.plain)
                    .onAppear { pulse = true }
                    .accessibilityLabel("Today’s Alignment")
                    .accessibilityValue(alignmentValue(rb))
                    .accessibilityAddTraits(.updatesFrequently)
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    Text(headline)
                        .dlType(.titleXL)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                        .foregroundStyle(Color.white)
                    
                    if let summary, !summary.isEmpty {
                        Text(summary)
                            .dlType(.body)
                            .foregroundStyle(Color.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if FeatureFlags.resonanceUIEnabled,
                       let r = resonance,
                       let first = r.topHits.first,
                       !first.overlapSymbols.isEmpty {
                        let chips = first.overlapSymbols.prefix(ResonanceConfig.OVERLAP_MAX_VISUAL)
                        HStack(spacing: 8) {
                            ForEach(Array(chips), id: \.self) { sym in
                                Text(sym.replacingOccurrences(of: "_", with: " "))
                                    .font(DLFont.body(13))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.16), in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }
                        .accessibilityLabel("Overlapping symbols: \(chips.map { $0.replacingOccurrences(of: "_", with: " ") }.joined(separator: ", "))")
                    }
                    
                    if !doItems.isEmpty || !dontItems.isEmpty {
                        ActionChips(doItems: Array(doItems.prefix(2)),
                                    dontItems: Array(dontItems.prefix(2)))
                    }
                    
                    if let enhancement = dreamEnhancement, !enhancement.isEmpty {
                        dreamEnhancementPill(enhancement)
                    }
                }
                
                if showLogButton, let onLogDream {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            onLogDream()
                        }
                    }) {
                        HStack(spacing: 10) {
                            DLAssetImage.oracleIcon
                                .renderingMode(.template)
                                .foregroundStyle(Color.white.opacity(0.92))
                                .frame(width: 16, height: 16)
                            Text("Log a dream")
                                .dlType(.body)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.18), in: Capsule())
                        .foregroundStyle(Color.white)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                    isPressed = true
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                    isPressed = false
                                }
                            }
                    )
                }
            }
            .padding(28)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .readableScrim(0.40)
        .task {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                animateHalo = true
            }
        }
    }
    
    private var backgroundCard: some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)
        
        return shape
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
                    .opacity(theme.isLight ? 0.38 : 0.5)
                    .blendMode(.screen)
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
    
    private func alignmentValue(_ rb: ResonanceBundle) -> String {
        if let hit = rb.topHits.first, let first = hit.overlapSymbols.first {
            return first.replacingOccurrences(of: "_", with: " ")
        }
        return "Active"
    }
}

