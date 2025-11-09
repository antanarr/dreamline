import SwiftUI

#if canImport(StoreKit)
import StoreKit

@available(iOS 15.0, *)
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = DreamlineStore.shared
    @State private var isPurchasing = false
    
    private let plusFeatures = [
        "Unlimited Oracle interpretations",
        "30-day insights & motif analytics",
        "Full Dream-Synced horoscope experience"
    ]
    
    private let proFeatures = [
        "Everything in Plus",
        "Oracle Chat with live guidance",
        "Voice transcription & 90-day analytics"
    ]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 28) {
                    hero
                    
                    planCard(
                        title: "Plus",
                        subtitle: "Everything you need to build your dream practice.",
                        cta: "Start 7-day trial",
                        tint: LinearGradient(
                            colors: [Color.dlIndigo, Color.dlViolet],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        features: plusFeatures
                    ) {
                        Task { await buy(id: store.plusMonthly) }
                    }
                    
                    planCard(
                        title: "Pro",
                        subtitle: "For the dream devotee who wants the Oracle on-call.",
                        cta: "Upgrade to Pro",
                        tint: LinearGradient(
                            colors: [Color.dlLilac, Color.dlMint],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        features: proFeatures,
                        bordered: true
                    ) {
                        Task { await buy(id: store.proMonthly) }
                    }
                    
                    deepReadRow
                    
                    VStack(spacing: 12) {
                        Button("Restore purchases") {
                            Task { await store.restore() }
                        }
                        .font(DLFont.body(14))
                        .foregroundStyle(.secondary)
                        
                        Text("Cancel anytime. Plans renew automatically unless cancelled at least 24 hours before the end of the period.")
                            .font(DLFont.body(11))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 96)
            }
            .background(
                ZStack {
                    Image("bg_nebula_full")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.45)
                        .blur(radius: 20)
                    LinearGradient(
                        colors: [
                            Color.dlSpace,
                            Color.dlSpace.opacity(0.9),
                            Color.dlIndigo.opacity(0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottomTrailing
                    )
                    Image("pattern_stargrid_tile")
                        .resizable(resizingMode: .tile)
                        .opacity(0.12)
                        .blendMode(.screen)
                }
                .ignoresSafeArea()
            )
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
            }
            .padding(.trailing, 24)
            .padding(.top, 24)
        }
        .task { await store.loadProducts() }
        .disabled(isPurchasing)
    }
    
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            heroBackground
            
            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dreamline Membership")
                        .font(DLFont.body(11))
                        .textCase(.uppercase)
                        .tracking(1.1)
                        .foregroundStyle(Color.white.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08), in: Capsule())
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Unlock the Dreamline experience.")
                            .font(DLFont.title(32))
                            .foregroundStyle(.primary)
                        
                        Text("Deepen your nightly practice with unlimited interpretations, live Oracle guidance, and long-arc insights.")
                            .font(DLFont.body(14))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image("oracle_hero_header")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)
                    .shadow(color: .black.opacity(0.35), radius: 22, x: 0, y: 18)
                    .accessibilityHidden(true)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.1))
        )
    }
    
    private var heroBackground: some View {
        ZStack {
            Image("bg_nebula_full")
                .resizable()
                .scaledToFill()
                .opacity(0.65)
                .blur(radius: 16)
            
            LinearGradient(
                colors: [
                    Color.dlSpace.opacity(0.95),
                    Color.dlIndigo.opacity(0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image("pattern_stargrid_tile")
                .resizable(resizingMode: .tile)
                .opacity(0.2)
                .blendMode(.screen)
            
            Image("pattern_gradientnoise_tile")
                .resizable(resizingMode: .tile)
                .opacity(0.14)
                .blendMode(.plusLighter)
        }
    }
    
    private func planCard(
        title: String,
        subtitle: String,
        cta: String,
        tint: LinearGradient,
        features: [String],
        bordered: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(DLFont.title(24))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(DLFont.body(13))
                    .foregroundStyle(.secondary)
            }
            
            planFeatureList(features)
            
            planCTAButton(
                title: cta,
                tint: tint,
                bordered: bordered,
                action: action
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
        )
    }
    
    @ViewBuilder
    private func planFeatureList(_ features: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dlLilac)
                    Text(feature)
                        .font(DLFont.body(13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func planCTAButton(
        title: String,
        tint: LinearGradient,
        bordered: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(DLFont.body(15))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Group {
                        if bordered {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.2)
                        } else {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(tint)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.white)
    }
    
    private var deepReadRow: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Deep Read")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
                Text("One-off PDF insight tailored to a single dream.")
                    .font(DLFont.body(13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                Task { await buy(id: store.deepRead) }
            } label: {
                Text("Buy")
                    .font(DLFont.body(14))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
        )
    }
    
    private func buy(id: String) async {
        guard let p = store.products.first(where: { $0.id == id }) else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        _ = await store.purchase(p)
    }
}

#else

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("StoreKit not available")
            Button("Close") { dismiss() }
        }
        .padding()
    }
}

#endif

