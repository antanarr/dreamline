import SwiftUI

struct QuickReadView: View {
    let entry: DreamEntry
    @State private var transit: TransitSummary?
    @State private var isLoadingTransit = true
    @Environment(ThemeService.self) private var theme: ThemeService
    @Environment(\.dismiss) private var dismiss
    private let astro = AstroService.shared
    
    private var interpretation: DreamInterpretation? {
        entry.interpretation
    }
    
    @ViewBuilder
    private var actionsCard: some View {
        if let interpretation {
            VStack(alignment: .leading, spacing: 16) {
                Text("Next steps")
                    .font(DLFont.title(18))
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(interpretation.actions.enumerated()), id: \.offset) { index, action in
                        ActionPrompt(
                            emoji: index == 0 ? "🖊️" : index == 1 ? "🫁" : "✨",
                            title: "Step \(index + 1)",
                            detail: action
                        )
                    }
                }
            }
            .padding(22)
            .background(cardBackground(level: .secondary))
        }
    }
    
    @ViewBuilder
    private var disclaimerCard: some View {
        if let interpretation {
            Text(interpretation.disclaimer)
                .font(DLFont.body(11))
                .foregroundStyle(.secondary)
                .padding(22)
                .background(cardBackground(level: .secondary))
        }
    }
    
    @ViewBuilder
    private var psychologyCard: some View {
        if let interpretation {
            VStack(alignment: .leading, spacing: 18) {
                Text("Psychology")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
                
                Text(interpretation.psychology)
                    .font(DLFont.body(15))
                    .foregroundStyle(.primary)
            }
            .padding(22)
            .background(cardBackground(level: .secondary))
        }
    }
    
    @ViewBuilder
    private var astrologyCard: some View {
        if let interpretation, let astro = interpretation.astrology {
            VStack(alignment: .leading, spacing: 18) {
                Text("Astrology")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
                
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
                } else {
                    Text(astro)
                        .font(DLFont.body(15))
                        .foregroundStyle(.primary)
                }
            }
            .padding(22)
            .background(cardBackground(level: .secondary))
        }
    }
    
    @ViewBuilder
    private var symbolDeck: some View {
        if let interpretation {
            VStack(alignment: .leading, spacing: 18) {
                Text("Symbols in focus")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
                
                if interpretation.symbols.isEmpty {
                    Text("No symbols highlighted yet. Log another dream to surface patterns.")
                        .font(DLFont.body(14))
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(interpretation.symbols, id: \.name) { symbol in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(symbol.name.capitalized)
                                        .font(DLFont.body(15).weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(Int(symbol.confidence * 100))%")
                                        .font(DLFont.body(11))
                                        .foregroundStyle(.secondary)
                                }
                                Text(symbol.meaning)
                                    .font(DLFont.body(14))
                                    .foregroundStyle(.primary.opacity(0.9))
                            }
                            .padding(18)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                }
            }
            .padding(22)
            .background(cardBackground(level: .primary))
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headlineCard
                    summaryCard
                    psychologyCard
                    astrologyCard
                    symbolDeck
                    dreamTransitCard
                    actionsCard
                    disclaimerCard
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
    
    private var headlineCard: some View {
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
                    Text(interpretation?.headline ?? "Dream saved")
                        .font(DLFont.title(28))
                        .foregroundStyle(.primary)
                    
                    Text(interpretation == nil ? "Here's what emerged from your entry." : "Your dream is already interpreting back.")
                        .font(DLFont.body(14))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Summary")
                .font(DLFont.title(20))
                .foregroundStyle(.primary)
            
            if let interpretation {
                Text(interpretation.summary)
                    .font(DLFont.body(15))
                    .foregroundStyle(.primary)
            } else {
                Text("No interpretation yet. Capture a dream to unlock your quick read.")
                    .font(DLFont.body(14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .background(cardBackground(level: .primary))
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
                    
                    if let focus = interpretation?.symbols.first?.name {
                        Divider()
                            .overlay(theme.palette.separator)
                        Text("Notice how \(focus.lowercased()) reacts under today's \(transit.headline.lowercased()). Track any subtle synchronicities.")
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
    let emoji: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DLFont.body(13).weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(DLFont.body(13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

