import SwiftUI

struct TodayView: View {
    @Environment(DreamStore.self) private var store
    @Environment(EntitlementsService.self) private var entitlements
    @Environment(ThemeService.self) private var theme: ThemeService
    @StateObject private var vm = TodayViewModel()
    @StateObject private var horoscopeVM = TodayRangeViewModel()
    @State private var showRecorder = false
    @State private var startRecordingOnCompose = false
    @State private var selectedLifeArea: HoroscopeArea?
    @State private var bestDays: [BestDayInfo] = []
    @State private var showPaywall = false
    @State private var paywallContext: PaywallService.PaywallContext?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    // Horoscope hero FIRST
                    if let item = horoscopeVM.item {
                        YourDayHeroCard(
                            headline: item.headline,
                            summary: item.summary,
                            dreamEnhancement: dreamEnhancement,
                            showLogButton: false
                        )
                    } else if horoscopeVM.loading {
                        loadingShimmer
                    } else {
                        emptyState
                    }
                    
                    if let item = horoscopeVM.item, !item.dreamLinks.isEmpty {
                        dreamThreadsSection(item: item)
                    }
                    
                    // Areas of Life
                    if let item = horoscopeVM.item {
                        areasOfLifeSection(item: item)
                    }
                    
                    // Behind This Forecast
                    if let item = horoscopeVM.item, !item.transits.isEmpty {
                        BehindThisForecastView(transits: item.transits)
                    }
                    
                    // Seasonal Content
                    SeasonalContentView(
                        currentZodiacSeason: ZodiacSign.current(),
                        dreamPatterns: DreamPatternService.shared.analyzePatterns(from: store, days: 30),
                        isPro: isPro,
                        onUnlock: {
                            paywallContext = .dreamPatterns
                            showPaywall = true
                        }
                    )
                    
                    // Best Days
                    BestDaysView(
                        days: bestDays,
                        isPro: isPro,
                        onViewFull: {
                            // Navigate to full calendar (future)
                        },
                        onUnlock: {
                            paywallContext = .bestDays
                            showPaywall = true
                        }
                    )
                }
                .padding(.top, 8)
            }
            .background(
                Color.clear
                    .dreamlineScreenBackground()
            )
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startRecordingOnCompose = false
                        showRecorder = true
                    } label: {
                        Label("Log", systemImage: "plus")
                    }
                    .accessibilityLabel("Log a dream")
                }
            }
            .refreshable {
                await refreshContent()
            }
            .task {
                await vm.load(dreamStore: store)
                await horoscopeVM.load(period: .day, tz: TimeZone.current.identifier)
                // TODO: Fetch best days from backend
                bestDays = [] // Placeholder
            }
            .sheet(isPresented: $showRecorder, onDismiss: {
                startRecordingOnCompose = false
            }) {
                ComposeDreamView(store: store, startRecordingOnAppear: startRecordingOnCompose)
            }
            .sheet(item: $selectedLifeArea) { area in
                NavigationStack {
                    LifeAreaDetailView(
                        area: area,
                        transits: horoscopeVM.item?.transits ?? [],
                        isPro: isPro
                    )
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .dlStartVoiceCapture)) { _ in
                startRecordingOnCompose = true
                showRecorder = true
            }
        }
    }

    private var isPro: Bool {
        entitlements.tier == .pro || entitlements.tier == .plus
    }
    
    private var currentStreak: Int {
        DreamStreakService.shared.calculateStreak(from: store.entries)
    }
    
    private var dreamEnhancement: String? {
        // Get most recent dream from today
        let today = Calendar.current.startOfDay(for: Date())
        let todayDreams = store.entries.filter {
            Calendar.current.isDate($0.createdAt, inSameDayAs: today)
        }
        
        guard !todayDreams.isEmpty else { return nil }
        
        // Create brief enhancement text
        let symbols = todayDreams.flatMap { $0.symbols }.prefix(2)
        if symbols.isEmpty { return nil }
        
        return "Your dreams this morning featured \(symbols.joined(separator: " and "))."
    }
    
    @ViewBuilder
    private func areasOfLifeSection(item: HoroscopeStructured) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("AREAS OF YOUR LIFE")
                    .font(DLFont.body(12))
                    .foregroundStyle(.secondary)
                    .kerning(1.2)
                    .textCase(.uppercase)
                
                if !isPro {
                    Text("Dive deeper to unlock all six focus areas.")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary.opacity(0.8))
                }
            }
            
            VStack(spacing: 0) {
                ForEach(Array(item.areas.enumerated()), id: \.element.id) { index, area in
                    let isLocked = !isPro && index >= 2
                    
                    LifeAreaRow(
                        area: area,
                        isLocked: isLocked,
                        onTap: {
                            if isLocked {
                                paywallContext = .lockedLifeArea(areaId: area.id)
                                showPaywall = true
                            } else {
                                selectedLifeArea = area
                            }
                        }
                    )
                }
            }
        }
        .padding(24)
        .background(lifeAreaBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var lifeAreaBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
        return shape
            .fill(theme.palette.cardFillSecondary)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.dlIndigo.opacity(theme.isLight ? 0.10 : 0.16),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(shape)
            )
    }
    
    @ViewBuilder
    private func dreamThreadsSection(item: HoroscopeStructured) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Text("Dream threads we’re weaving")
                    .font(DLFont.body(14).weight(.semibold))
                    .foregroundStyle(.primary)
                
                if let transit = item.primaryTransit {
                    Text(transit)
                        .font(DLFont.body(12))
                        .foregroundStyle(Color.dlMint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.dlMint.opacity(0.12), in: Capsule())
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(item.dreamLinks) { link in
                        DreamLinkChip(link: link)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.palette.cardFillPrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private func refreshContent() async {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        await vm.load(dreamStore: store)
        await horoscopeVM.load(period: .day, tz: TimeZone.current.identifier, force: true)
        bestDays = []
        
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
    }
    
    private var loadingShimmer: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 14)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(theme.palette.cardFillSecondary)
        .shimmer()
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.dlIndigo, Color.dlViolet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Your Cosmic Forecast")
                    .font(DLFont.title(24))
                    .fontWeight(.semibold)
                
                Text("Pull down to refresh and see what the stars have aligned for you today.")
                    .font(DLFont.body(16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(theme.palette.cardFillSecondary)
    }
}

private struct DreamLinkChip: View {
    let link: DreamLink
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(link.motif)
                .font(DLFont.body(13).weight(.semibold))
                .foregroundStyle(.primary)
            
            Text(link.line)
                .font(DLFont.body(13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let transit = link.transitRef, !transit.isEmpty {
                Divider()
                    .overlay(theme.palette.separator.opacity(0.6))
                Text(transit)
                    .font(DLFont.body(11))
                    .foregroundStyle(Color.dlMint)
            }
        }
        .padding(18)
        .frame(width: 220, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.palette.cardFillSecondary,
                            theme.palette.cardFillPrimary.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
}
