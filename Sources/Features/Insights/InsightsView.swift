import SwiftUI

struct InsightsView: View {
    @Environment(DreamStore.self) private var store
    @Environment(EntitlementsService.self) private var entitlements
    @Environment(ThemeService.self) private var theme: ThemeService
    
    private var entries: [DreamEntry] { store.entries }
    private var hasDreams: Bool { !entries.isEmpty }
    
    private var metrics: [InsightMetric] {
        [
            InsightMetric(
                title: "Dreams logged",
                value: "\(entries.count)",
                caption: entries.count == 1 ? "Entry on record" : "Entries on record",
                icon: "moon.zzz.fill"
            ),
            InsightMetric(
                title: "Active streak",
                value: streakValue,
                caption: streakCaption,
                icon: "flame.fill"
            ),
            InsightMetric(
                title: "Interpretations",
                value: "\(interpretedCount)",
                caption: interpretedCount == 1 ? "Oracle read" : "Oracle reads",
                icon: "sparkles"
            )
        ]
    }
    
    private var topSymbols: [SymbolStat] {
        let counts = entries
            .flatMap { $0.extractedSymbols.map { $0.lowercased() } }
            .reduce(into: [String: Int]()) { partial, symbol in
                partial[symbol, default: 0] += 1
            }
        return counts
            .map { SymbolStat(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(4)
            .map { $0 }
    }
    
    private var heatmapMatrix: [[Int]] {
        let lookbackWeeks = weeksForCurrentTier
        guard lookbackWeeks > 0 else { return [] }
        var matrix = Array(
            repeating: Array(repeating: 0, count: 7),
            count: lookbackWeeks
        )
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for entry in entries {
            let day = calendar.startOfDay(for: entry.createdAt)
            guard let diff = calendar.dateComponents([.day], from: day, to: today).day else { continue }
            guard diff >= 0, diff < lookbackWeeks * 7 else { continue }
            
            let column = lookbackWeeks - 1 - diff / 7
            let weekday = calendar.component(.weekday, from: day)
            let normalizedRow = (weekday + 5) % 7 // Monday-first
            matrix[column][normalizedRow] += 1
        }
        
        return matrix
    }
    
    private var interpretedCount: Int {
        entries.filter { $0.interpretation != nil }.count
    }
    
    private var streakValue: String {
        let streak = activeStreak
        return streak == 0 ? "—" : "\(streak)"
    }
    
    private var streakCaption: String {
        let streak = activeStreak
        guard streak > 0 else { return "Log tonight to start a streak." }
        return streak == 1 ? "Day in a row" : "Days in a row"
    }
    
    private var activeStreak: Int {
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
            .sorted(by: >)
        
        var streak = 0
        var previousDay: Date? = nil
        
        for day in uniqueDays {
            if previousDay == nil {
                streak = 1
                previousDay = day
            } else if let previous = previousDay,
                      let expected = calendar.date(byAdding: .day, value: -1, to: previous),
                      calendar.isDate(day, inSameDayAs: expected) {
                streak += 1
                previousDay = day
            } else if let previous = previousDay,
                      calendar.isDate(day, inSameDayAs: previous) {
                continue
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var weeksForCurrentTier: Int {
        switch entitlements.tier {
        case .free: return 1
        case .plus: return 4
        case .pro: return 13
        }
    }
    
    private var lookbackDays: Int {
        weeksForCurrentTier * 7
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if hasDreams {
                    VStack(alignment: .leading, spacing: 24) {
                        InsightsHeroCard(metrics: metrics)
                            .revealOnScroll()
                        
                        if !topSymbols.isEmpty {
                            InsightsTopSymbolsCard(symbols: topSymbols)
                                .revealOnScroll()
                        }
                        
                        InsightsHeatmapSection(
                            tier: entitlements.tier,
                            isFreeUser: entitlements.tier == .free,
                            lookbackDays: lookbackDays,
                            matrix: heatmapMatrix
                        )
                        .revealOnScroll()
                }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                } else {
                    InsightsEmptyState()
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
            }
            }
            .background(
                Color.clear
                    .dreamlineScreenBackground()
            )
            .coordinateSpace(name: "scroll")
            .navigationTitle("Insights")
        }
    }
}

private struct InsightMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let caption: String
    let icon: String
}

private struct SymbolStat: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

private struct InsightsHeroCard: View {
    let metrics: [InsightMetric]
    @Environment(ThemeService.self) private var theme: ThemeService
    
    private var grid: [GridItem] = [
        GridItem(.flexible(minimum: 100), spacing: 16),
        GridItem(.flexible(minimum: 100), spacing: 16)
    ]
    
    init(metrics: [InsightMetric]) {
        self.metrics = metrics
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                DLAssetImage.oracleIcon
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.dlLilac)
                    .opacity(0.9)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dreamline Pulse")
                        .font(DLFont.title(22))
                        .foregroundStyle(.primary)
                    Text("Your motif snapshot updates after every new entry.")
                        .font(DLFont.body(13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            LazyVGrid(columns: grid, spacing: 16) {
                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: metric.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.dlLilac)
                            
                            Text(metric.title)
                                .font(DLFont.body(12))
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(metric.value)
                            .font(DLFont.title(28))
                            .foregroundStyle(.primary)
                        
                        Text(metric.caption)
                            .font(DLFont.body(12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(theme.palette.cardFillSecondary)
                    )
                }
            }
        }
        .padding(22)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 20)
    }
    
    private var heroBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
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

private struct InsightsTopSymbolsCard: View {
    let symbols: [SymbolStat]
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.rays")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dlMint)
                Text("Most vivid motifs")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
            }
            
            Text("Based on your interpreted dreams.")
                .font(DLFont.body(13))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(symbols.enumerated()), id: \.element.id) { index, symbol in
                    HStack {
                        Text("\(index + 1). \(symbol.name.capitalized)")
                            .font(DLFont.body(15))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(symbol.count)×")
                            .font(DLFont.body(13))
                            .foregroundStyle(.secondary)
                        InsightsSymbolBar(fill: normalizedValue(for: symbol.count))
                    }
                }
            }
        }
        .padding(22)
        .background(symbolsBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private func normalizedValue(for count: Int) -> Double {
        guard let maxCount = symbols.map(\.count).max(), maxCount > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }
    
    private var symbolsBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return shape
            .fill(
                LinearGradient(
                    colors: theme.palette.horoscopeCardBackground,
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                DLAssetImage.heroBackground
                    .resizable()
                    .scaledToFill()
                    .opacity(theme.isLight ? 0.16 : 0.12)
            )
            .clipShape(shape)
    }
}

private struct InsightsSymbolBar: View {
    let fill: Double
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.1))
                .frame(width: 110, height: 8)
            
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.dlMint.opacity(0.7), Color.dlLilac.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(20, 110 * fill), height: 8)
        }
    }
}

private struct InsightsEmptyState: View {
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(spacing: 18) {
            DLAssetImage.emptyInsights
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .opacity(theme.isLight ? 0.95 : 0.9)
            
            VStack(spacing: 10) {
                Text("Patterns emerge with time")
                    .dlType(.titleM)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text("Log a few dreams and we’ll start surfacing motifs and seasonality.")
                    .dlType(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("Tip: interpretations help the Oracle track your recurring symbols.")
                .dlType(.caption)
                .foregroundStyle(.secondary.opacity(0.85))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }
}
