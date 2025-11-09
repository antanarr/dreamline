import SwiftUI

struct SymbolSeasonalityDetailView: View {
    let days: Int
    let data: [[Int]]
    
    private var totalDreamsTracked: Int {
        data.flatMap { $0 }.reduce(0, +)
    }
    
    private var emptyHeatmap: Bool {
        totalDreamsTracked == 0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Symbol Seasonality")
                        .font(DLFont.title(26))
                        .foregroundStyle(.primary)
                    
                    Text(subheadline)
                        .font(DLFont.body(15))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    if emptyHeatmap {
                        SeasonalityHeatmapPlaceholder()
                    } else {
                        SymbolHeatmapView(days: days, data: data)
                            .frame(height: 140)
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(0..<5) { index in
                            Capsule()
                                .fill(Color.dlViolet.opacity(0.18 + Double(index) * 0.14))
                                .frame(width: 48, height: 12)
                        }
                        
                        Spacer()
                        
                        Text("Light → dense symbol clusters")
                            .font(DLFont.body(12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color.dlSpace.opacity(0.92),
                                Color.dlIndigo.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image("pattern_stargrid_tile")
                            .resizable(resizingMode: .tile)
                            .opacity(0.16)
                            .blendMode(.screen)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    Label {
                        Text("How to use it")
                            .font(DLFont.title(18))
                    } icon: {
                        Image(systemName: "lightbulb.max.fill")
                            .foregroundStyle(Color.dlMint)
                    }
                    
                    Text("Hot clusters often coincide with real-life shifts. Tap back to Journal and skim the highlighted weeks to recall the story arc.")
                        .font(DLFont.body(14))
                        .foregroundStyle(.secondary)
                    
                    if days >= 30 {
                        Text("Pro tip: pair this with the Dream × Transit card in Today to see which motifs echo the current sky.")
                            .font(DLFont.body(13))
                            .foregroundStyle(.secondary.opacity(0.9))
                    }
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.08))
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.dlSpace,
                    Color.dlSpace.opacity(0.9),
                    Color.dlViolet.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Seasonality")
    }
    
    private var subheadline: String {
        "Motifs mapped over the last \(days)-day window. Darker tones = more appearances."
    }
}

private struct SeasonalityHeatmapPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("No clusters to show yet.")
                .font(DLFont.body(14))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 10) {
                ForEach(0..<7) { _ in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        .frame(width: 36, height: 42)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
    }
}

