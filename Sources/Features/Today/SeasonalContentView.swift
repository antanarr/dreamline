import SwiftUI

struct SeasonalContentView: View {
    let currentZodiacSeason: ZodiacSign
    let dreamPatterns: [DreamPattern]
    let isPro: Bool
    let onUnlock: () -> Void
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ZodiacSeasonCard(sign: currentZodiacSeason)
            
            if !dreamPatterns.isEmpty {
                DreamPatternsCard(
                    patterns: dreamPatterns,
                    isPro: isPro,
                    onUnlock: onUnlock
                )
            }
        }
    }
}

struct ZodiacSeasonCard: View {
    let sign: ZodiacSign
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(sign.symbol)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("It's \(sign.rawValue.capitalized) season.")
                        .font(DLFont.title(24))
                    
                    Text(sign.dateRange)
                        .font(DLFont.caption(12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(sign.seasonDescription)
                .font(DLFont.body(16))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return shape
            .fill(theme.palette.cardFillPrimary)
            .overlay(
                LinearGradient(
                    colors: [Color.dlViolet.opacity(0.1), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(shape)
            )
    }
}

struct DreamPatternsCard: View {
    let patterns: [DreamPattern]
    let isPro: Bool
    let onUnlock: () -> Void
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundStyle(Color.dlIndigo)
                
                Text("Your Dream Patterns")
                    .font(DLFont.title(20))
                
                Spacer()
                
                if !isPro {
                    Text("PRO")
                        .font(DLFont.caption(10))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.dlViolet)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            
            if isPro {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(patterns.prefix(3)) { pattern in
                        PatternRow(pattern: pattern)
                    }
                }
            } else {
                // Teaser for free users
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.title3)
                            .foregroundStyle(Color.dlMint.opacity(0.6))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(patterns.first?.symbol.capitalized ?? "Symbols")
                                .font(DLFont.body(16))
                                .fontWeight(.semibold)
                            
                            Text("appearing in your dreams...")
                                .font(DLFont.body(14))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.palette.cardFillSecondary.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(.secondary.opacity(0.3))
                    )
                }
                
                Button(action: onUnlock) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text("Unlock Pattern Analysis")
                    }
                    .font(DLFont.body(14))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.dlIndigo, Color.dlViolet],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(theme.palette.cardFillSecondary)
    }
}

private struct PatternRow: View {
    let pattern: DreamPattern
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolIcon)
                .font(.title3)
                .foregroundStyle(Color.dlMint)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.symbol.capitalized)
                    .font(DLFont.body(16))
                    .fontWeight(.semibold)
                
                Text(pattern.description)
                    .font(DLFont.body(14))
                    .foregroundStyle(.secondary)
                
                if pattern.daySpan > 7 {
                    Text("Recurring over \(pattern.daySpan) days suggests a deepening theme")
                        .font(DLFont.caption(12))
                        .foregroundStyle(Color.dlIndigo)
                        .italic()
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.palette.capsuleFill)
        )
    }
    
    private var symbolIcon: String {
        let lowercased = pattern.symbol.lowercased()
        if lowercased.contains("water") { return "drop.fill" }
        if lowercased.contains("fire") { return "flame.fill" }
        if lowercased.contains("air") { return "wind" }
        if lowercased.contains("earth") { return "mountain.2.fill" }
        if lowercased.contains("animal") { return "pawprint.fill" }
        if lowercased.contains("death") { return "leaf.fill" }
        if lowercased.contains("birth") { return "sunrise.fill" }
        return "sparkles"
    }
}

