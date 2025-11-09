import SwiftUI

struct LifeAreaDetailView: View {
    let area: HoroscopeArea
    let transits: [HoroscopeStructured.TransitPill]
    let isPro: Bool
    
    @Environment(ThemeService.self) private var theme: ThemeService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                
                Divider()
                
                bulletsSection
                
                if let actions = area.actions {
                    Divider()
                    actionsSection(actions)
                }
                
                Divider()
                
                AccuracyFeedbackView(areaId: area.id)
                
                if isPro && !transits.isEmpty {
                    Divider()
                    transitSection
                }
            }
            .padding(24)
        }
        .background(Color(theme.palette.background))
        .navigationTitle(lifeArea.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: lifeArea.iconSystemName)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Color.dlIndigo)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(area.title)
                    .font(DLFont.title(24))
                
                if area.score > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(area.score / 20) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(Color.dlMint)
                        }
                    }
                }
            }
        }
    }
    
    private var bulletsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S GUIDANCE")
                .font(DLFont.body(12))
                .foregroundStyle(.secondary)
                .kerning(1.2)
                .textCase(.uppercase)
            
            ForEach(Array(area.bullets.enumerated()), id: \.offset) { index, bullet in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(DLFont.body(16))
                        .foregroundStyle(Color.dlIndigo)
                    
                    Text(bullet)
                        .font(DLFont.body(16))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private func actionsSection(_ actions: HoroscopeArea.Actions) -> some View {
        HStack(alignment: .top, spacing: 16) {
            if let doItems = actions.do_, !doItems.isEmpty {
                ActionColumn(title: "Do", items: doItems, tint: Color.dlMint)
            }
            
            if let dontItems = actions.dont, !dontItems.isEmpty {
                ActionColumn(title: "Don't", items: dontItems, tint: Color.dlAmber)
            }
        }
    }
    
    private var transitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BEHIND THIS FORECAST")
                .font(DLFont.body(12))
                .foregroundStyle(.secondary)
                .kerning(1.2)
                .textCase(.uppercase)
            
            ForEach(transits.prefix(2), id: \.label) { transit in
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(Color.dlViolet)
                    
                    Text(transit.label)
                        .font(DLFont.body(14))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(theme.palette.capsuleFill, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var lifeArea: LifeArea {
        LifeArea(rawID: area.id)
    }
}

private struct ActionColumn: View {
    let title: String
    let items: [String]
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DLFont.body(14))
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .kerning(0.8)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, item in
                    Text(item)
                        .font(DLFont.body(13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(tint.opacity(0.16), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

