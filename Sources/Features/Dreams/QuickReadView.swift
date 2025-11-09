import SwiftUI

struct QuickReadView: View {
    let entry: DreamEntry
    @State private var transit: TransitSummary?
    @State private var isLoadingTransit = true
    @Environment(ThemeService.self) private var theme: ThemeService
    @Environment(\.dismiss) private var dismiss
    private let astro = AstroService.shared
    
    private var motifs: [String] {
        let symbols = entry.extractedSymbols
        let themes = entry.themes
        let combined = symbols + themes
        return Array(Set(combined)).prefix(3).map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    motivCard
                    dreamTransitCard
                    actionPrompts
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
            .background(
                Color.clear
                    .dreamlineScreenBackground()
            )
            .navigationTitle("Quick Read")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                transit = await astro.transits(for: .now)
                isLoadingTransit = false
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dlLilac, Color.dlViolet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dream saved")
                        .font(DLFont.title(28))
                        .foregroundStyle(.primary)
                    
                    Text("Here's what emerged from your entry.")
                        .font(DLFont.body(14))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var motivCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dlMint)
                Text("Emerging motifs")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
            }
            
            if motifs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No motifs extracted yet")
                        .font(DLFont.body(14))
                        .foregroundStyle(.secondary)
                    
                    Text("Interpret this dream to surface symbols and themes.")
                        .font(DLFont.body(13))
                        .foregroundStyle(.secondary.opacity(0.8))
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(motifs.enumerated()), id: \.offset) { index, motif in
                        HStack(alignment: .center, spacing: 12) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.dlLilac, Color.dlMint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 8, height: 8)
                            
                            Text(motif.capitalized)
                                .font(DLFont.body(15))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(22)
        .background(cardBackground(level: .primary))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var dreamTransitCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "moon.stars.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dlLilac)
                Text("Dream × Transit")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
            }
            
            if isLoadingTransit {
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 16)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 16)
                        .frame(maxWidth: 220, alignment: .leading)
                }
                .shimmer()
            } else if let transit = transit {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.dlLilac)
                        
                        Text(transit.headline)
                            .font(DLFont.body(15))
                            .foregroundStyle(.primary)
                    }
                    
                    if !transit.notes.isEmpty {
                        Text(transit.notes.joined(separator: " · "))
                            .font(DLFont.body(13))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let firstMotif = motifs.first {
                        Divider()
                            .overlay(theme.palette.separator)
                        
                        Text("Your \(firstMotif.lowercased()) theme resonates with today's \(transit.headline.lowercased())—watch for quiet synchronicities.")
                            .font(DLFont.body(14))
                            .foregroundStyle(.primary)
                            .italic()
                    }
                }
            } else {
                Text("Transit data unavailable. Check back soon.")
                    .font(DLFont.body(14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .background(cardBackground(level: .secondary))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var actionPrompts: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next steps")
                .font(DLFont.title(18))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                ActionPrompt(
                    icon: "sparkles",
                    text: "Tap the dream card to run a full Oracle interpretation",
                    tint: Color.dlLilac
                )
                
                ActionPrompt(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Visit Insights to see symbol trends and heatmaps",
                    tint: Color.dlMint
                )
                
                ActionPrompt(
                    icon: "sun.horizon.fill",
                    text: "Check Today for your Dream-Synced horoscope",
                    tint: Color.dlAmber
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.palette.cardFillSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private func cardBackground(level: CardLevel) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        switch level {
        case .primary:
            return AnyView(
                shape
                    .fill(theme.palette.cardFillPrimary)
                    .overlay(
                        Image("pattern_stargrid_tile")
                            .resizable(resizingMode: .tile)
                            .opacity(theme.isLight ? 0.06 : 0.18)
                            .blendMode(.screen)
                            .clipShape(shape)
                    )
                    .overlay(
                        Image("pattern_gradientnoise_tile")
                            .resizable(resizingMode: .tile)
                            .opacity(theme.isLight ? 0.05 : 0.12)
                            .blendMode(.plusLighter)
                            .clipShape(shape)
                    )
            )
        case .secondary:
            return AnyView(
                shape
                    .fill(theme.palette.cardFillSecondary)
            )
        }
    }
    
    private enum CardLevel {
        case primary
        case secondary
    }
}

private struct ActionPrompt: View {
    let icon: String
    let text: String
    let tint: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(DLFont.body(13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

