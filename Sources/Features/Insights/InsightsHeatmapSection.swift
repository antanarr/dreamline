import SwiftUI

struct InsightsHeatmapSection: View {
    let tier: Tier
    let isFreeUser: Bool
    let lookbackDays: Int
    let matrix: [[Int]]
    @ObservedObject var rc = RemoteConfigService.shared
    @Environment(ThemeService.self) private var theme: ThemeService
    
    private var emptyHeatmap: Bool {
        matrix.flatMap { $0 }.allSatisfy { $0 == 0 }
    }
    
    var body: some View {
        InsightsGate(isFreeUser: isFreeUser, daysShown: lookbackDays) {
            NavigationLink {
                SymbolSeasonalityDetailView(days: lookbackDays, data: matrix)
            } label: {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 6) {
                    Text("Symbol Seasonality")
                                .font(DLFont.title(20))
                                .foregroundStyle(.primary)
                            
                            Text(subheadline)
                                .font(DLFont.body(13))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary.opacity(0.8))
                    }
                    
                    if emptyHeatmap {
                        InsightsHeatmapPlaceholder()
                    } else {
                        SymbolHeatmapView(days: lookbackDays, data: matrix)
                            .frame(height: 84)
                    }
                    
                    HStack(spacing: 10) {
                        ForEach(0..<5) { index in
                            Capsule()
                                .fill(Color.dlViolet.opacity(0.18 + 0.16 * Double(index)))
                                .frame(width: 38, height: 10)
                        }
                        
                        Spacer()
                        
                        Text("Light → dense symbol clusters")
                            .font(DLFont.body(11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(22)
                .background(sectionBackground)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var subheadline: String {
        switch tier {
        case .pro:
            return "Tracking symbols across the last 90 days."
        case .plus:
            return "Highlights motifs across the last 30 days."
        case .free:
            return "A 7-day pulse of your most vivid symbols."
        }
    }
    
    private var sectionBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        return shape
            .fill(
                LinearGradient(
                    colors: theme.palette.horoscopeCardBackground,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                DLAssetImage.heroBackground
                    .resizable()
                    .scaledToFill()
                    .opacity(theme.isLight ? 0.18 : 0.14)
            )
            .clipShape(shape)
    }
}

private struct InsightsHeatmapPlaceholder: View {
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Log more dreams to unlock trends.")
                .font(DLFont.body(14))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(0..<7) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(theme.palette.separator.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: 32, height: 36)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
}

