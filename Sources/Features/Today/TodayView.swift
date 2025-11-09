import SwiftUI

struct TodayView: View {
    @Environment(DreamStore.self) private var store
    @Environment(EntitlementsService.self) private var entitlements
    @Environment(ThemeService.self) private var theme: ThemeService
    @StateObject private var vm = TodayViewModel()
    @StateObject private var horoscopeVM = HoroscopeViewModel()
    @StateObject private var paywall = PaywallService.shared
    @StateObject private var patternService = DreamPatternService.shared
    @State private var showRecorder = false
    @State private var startRecordingOnCompose = false
    @State private var selectedLifeArea: HoroscopeArea?
    @State private var bestDays: [BestDayInfo] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero: Your Day + Log Dream
                    YourDayHeroCard(
                        headline: horoscopeVM.structuredItem?.headline ?? "Loading your day...",
                        dreamEnhancement: dreamEnhancement,
                        onLogDream: {
                            startRecordingOnCompose = true
                            showRecorder = true
                        }
                    )
                    
                    // Areas of Life
                    if let item = horoscopeVM.structuredItem {
                        areasOfLifeSection(item: item)
                    }
                    
                    // Behind This Forecast
                    if let item = horoscopeVM.structuredItem, !item.transits.isEmpty {
                        BehindThisForecastView(transits: item.transits)
                    }
                    
                    // Seasonal Content
                    SeasonalContentView(
                        currentZodiacSeason: ZodiacSign.current(),
                        dreamPatterns: patternService.analyzePatterns(from: store, days: 30),
                        isPro: isPro,
                        onUnlock: {
                            paywall.trigger(.dreamPatterns)
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
                            paywall.trigger(.bestDays)
                        }
                    )
                }
                .padding()
            }
            .background(
                Color.clear
                    .dreamlineScreenBackground()
            )
            .navigationTitle("Today")
            .task {
                await vm.load(dreamStore: store)
                await horoscopeVM.fetchStructured(range: .day)
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
                        transits: horoscopeVM.structuredItem?.transits ?? [],
                        isPro: isPro
                    )
                }
            }
            .sheet(isPresented: $paywall.showPaywall) {
                if let context = paywall.paywallContext {
                    PaywallView(context: context, onDismiss: {
                        paywall.dismiss()
                    })
                }
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
        VStack(alignment: .leading, spacing: 16) {
            Text("AREAS OF YOUR LIFE")
                .font(DLFont.caption(12))
                .foregroundStyle(.secondary)
                .kerning(1.2)
                .textCase(.uppercase)
            
            VStack(spacing: 12) {
                ForEach(Array(item.areas.enumerated()), id: \.element.id) { index, area in
                    let isLocked = !isPro && index >= 2
                    
                    LifeAreaRow(
                        area: area,
                        isLocked: isLocked,
                        onTap: {
                            if isLocked {
                                paywall.trigger(.lockedLifeArea(areaId: area.id))
                            } else {
                                selectedLifeArea = area
                            }
                        }
                    )
                }
            }
        }
    }
}
