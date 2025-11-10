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
            HStack(spacing: 16) {
                DLAssetImage.zodiac(sign.rawValue)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                    .frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("It's \(sign.rawValue.capitalized) season.")
                        .font(DLFont.title(24))
                    
                    Text(sign.dateRange)
                        .font(DLFont.body(12))
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
            HStack(spacing: 14) {
                DLAssetImage.oracleIcon
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.dlIndigo)
                
                Text("Your Dream Patterns")
                    .font(DLFont.title(20))
                
                Spacer()
                
                if !isPro {
                    Text("PRO")
                        .font(DLFont.body(10))
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
                        DLAssetImage.symbol(patterns.first?.symbol ?? "ocean")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.dlIndigo.opacity(0.2), radius: 8, x: 0, y: 6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(patterns.first?.symbol.capitalized ?? "Symbols")
                                .font(DLFont.body(16))
                                .fontWeight(.semibold)
                            
                            Text("appearing in your dreams...")
                                .font(DLFont.body(14))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        DLAssetImage.oracleIcon
                            .renderingMode(.template)
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: 20)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.palette.cardFillSecondary.opacity(theme.isLight ? 0.55 : 0.4))
                    )
                }
                
                Button(action: onUnlock) {
                    HStack {
                        DLAssetImage.oracleIcon
                            .renderingMode(.template)
                            .foregroundStyle(.white.opacity(0.88))
                            .frame(width: 16, height: 16)
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
            leadingArtwork
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.symbol.capitalized)
                    .font(DLFont.body(16))
                    .fontWeight(.semibold)
                
                Text(pattern.description)
                    .font(DLFont.body(14))
                    .foregroundStyle(.secondary)
                
                if pattern.daySpan > 7 {
                    Text("Recurring over \(pattern.daySpan) days suggests a deepening theme")
                        .font(DLFont.body(12))
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
    
    @ViewBuilder
    private var leadingArtwork: some View {
        DLAssetImage.symbol(pattern.symbol)
            .resizable()
            .scaledToFit()
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
    }
}

