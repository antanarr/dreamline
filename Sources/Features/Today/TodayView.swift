import SwiftUI

struct TodayView: View {
    @Environment(DreamStore.self) private var store
    @Environment(EntitlementsService.self) private var entitlements
    @Environment(ThemeService.self) private var theme: ThemeService
    @ObservedObject private var constellation = ConstellationStore.shared
    @StateObject private var vm = TodayViewModel()
    @StateObject private var horoscopeVM = TodayRangeViewModel()
    @State private var showRecorder = false
    @State private var startRecordingOnCompose = false
    @State private var selectedLifeArea: HoroscopeArea?
    @State private var bestDays: [BestDayInfo] = []
    @State private var showPaywall = false
    @State private var paywallContext: PaywallService.PaywallContext?
    @State private var presentCalendar = false
    @State private var selectedDate: Date = Date()
    @State private var presentConstellation = false
    @State private var refreshToken = UUID()
    // Announces Alignment once per selected date (a11y + haptics)
    @State private var didAnnounceAlignment = false

    var body: some View {
        NavigationStack {
            scrollContent
                .background(Color.clear.dreamlineScreenBackground())
                .navigationTitle("Today")
                .toolbar { toolbarContent }
                .safeRefresh {
                    await MainActor.run { refreshToken = UUID() }
                }
                .coordinateSpace(name: "scroll")
                .task(id: refreshToken, priority: TaskPriority.userInitiated) { await loadHoroscope() }
                .sheet(isPresented: $showRecorder, onDismiss: { startRecordingOnCompose = false }) {
                    ComposeDreamView(store: store, startRecordingOnAppear: startRecordingOnCompose)
                }
                .sheet(item: $selectedLifeArea) { area in
                    NavigationStack {
                        LifeAreaDetailView(area: area, transits: horoscopeVM.item?.transits ?? [], isPro: isPro)
                    }
                }
                .sheet(isPresented: $showPaywall) { PaywallView() }
                .sheet(isPresented: $presentConstellation) {
                    ConstellationCanvas(entries: store.entries, neighbors: constellation.neighbors, coordinates: constellation.coordinates)
                        .environment(theme)
                }
                .sheet(isPresented: $presentCalendar) {
                    HoroscopeCalendarView(initialDate: selectedDate, onSelect: handleDateSelection)
                        .environment(theme)
                }
                .onReceive(NotificationCenter.default.publisher(for: .dlStartVoiceCapture)) { _ in
                    startRecordingOnCompose = true
                    showRecorder = true
                }
                .task { await ConstellationStore.shared.rebuild(from: store.entries) }
                .onReceive(NotificationCenter.default.publisher(for: .dreamsDidChange)) { _ in
                    Task { await ConstellationStore.shared.rebuild(from: store.entries) }
                }
                // Reset one-shot Alignment announcement when the reference date changes
                .onChange(of: selectedDate) {
                    didAnnounceAlignment = false
                }
        }
    }
    
    @ViewBuilder
    private var scrollContent: some View {
        ScrollView { mainContent }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
    
    @Sendable
    private func loadHoroscope() async {
        await vm.load(dreamStore: store, date: selectedDate)
        await horoscopeVM.load(period: .day, tz: TimeZone.current.identifier, dreamStore: store, reference: selectedDate)
        do {
            let birthISO = ProfileService.shared.birth.isoString()
            bestDays = try await HoroscopeService.shared.fetchBestDays(uid: "me", birthISO: birthISO)
        } catch {
            bestDays = []
        }
    }
    
    private func handleDateSelection(_ date: Date) {
        selectedDate = date
        Task {
            await horoscopeVM.load(period: .day, tz: TimeZone.current.identifier, dreamStore: store, force: true, reference: date)
            do {
                let birthISO = ProfileService.shared.birth.isoString()
                bestDays = try await HoroscopeService.shared.fetchBestDays(uid: "me", birthISO: birthISO)
            } catch {
                // keep prior bestDays
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
        let today = Calendar.current.startOfDay(for: Date())
        guard Calendar.current.isDate(selectedDate, inSameDayAs: today) else { return nil }
        let todayDreams = store.entries.filter {
            Calendar.current.isDate($0.createdAt, inSameDayAs: today)
        }
        
        guard !todayDreams.isEmpty else { return nil }
        
        // Create brief enhancement text
        let symbols = todayDreams.flatMap { $0.symbols ?? [] }.prefix(2)
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
                Text("Dream threads we're weaving")
                    .dlType(.bodyS)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if let transit = item.primaryTransit {
                    Text(transit)
                        .dlType(.caption)
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
        .padding(.vertical, 12)
        .padding(.bottom, 4)
        .overlay(
            Rectangle()
                .fill(theme.palette.separator.opacity(theme.isLight ? 0.22 : 0.16))
                .frame(height: 0.6),
            alignment: .bottom
        )
    }
    
    private func refreshContent() async {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        await vm.load(dreamStore: store, date: selectedDate)
        await horoscopeVM.load(period: .day,
                               tz: TimeZone.current.identifier,
                               dreamStore: store,
                               uid: "me",
                               force: true,
                               reference: selectedDate)
        do {
            let birthISO = ProfileService.shared.birth.isoString()
            bestDays = try await HoroscopeService.shared.fetchBestDays(uid: "me", birthISO: birthISO)
        } catch {
            // Keep existing bestDays on failure
        }
        
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
    }
    
    /// One-shot a11y + haptic cue when an Alignment Event is present.
    private func announceAlignmentIfNeeded() {
        guard !didAnnounceAlignment else { return }
        didAnnounceAlignment = true
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: "Today's Alignment")
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            heroSection
            
            if let item = horoscopeVM.item, !item.dreamLinks.isEmpty {
                dreamThreadsSection(item: item)
                    .revealOnScroll()
            }

            if constellation.hasGraph {
                ConstellationPreview(
                    entries: store.entries,
                    neighbors: constellation.neighbors,
                    coordinates: constellation.coordinates,
                    onOpen: { presentConstellation = true }
                )
                .padding(.horizontal, 20)
            }
            
            if let item = horoscopeVM.item {
                areasOfLifeSection(item: item)
                    .revealOnScroll()
            }
            
            if let item = horoscopeVM.item, !item.transits.isEmpty {
                BehindThisForecastView(transits: item.transits)
                    .revealOnScroll()
            }
            
            SeasonalContentView(
                currentZodiacSeason: ZodiacSign.current(),
                dreamPatterns: DreamPatternService.shared.analyzePatterns(from: store, days: 30),
                isPro: isPro,
                onUnlock: {
                    paywallContext = .dreamPatterns
                    showPaywall = true
                }
            )
            .revealOnScroll()
            
            BestDaysView(
                days: bestDays,
                isPro: isPro,
                onViewFull: {
                    presentCalendar = true
                },
                onUnlock: {
                    paywallContext = .bestDays
                    showPaywall = true
                }
            )
            .revealOnScroll()
            
            Button {
                presentCalendar = true
            } label: {
                Text("Browse calendar")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.dlViolet)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("browse-calendar-button")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var heroSection: some View {
        if let item = horoscopeVM.item {
            YourDayHeroCard(
                headline: item.headline,
                summary: item.summary,
                dreamEnhancement: dreamEnhancement,
                doItems: heroActions.do,
                dontItems: heroActions.dont,
                resonance: item.resonance,
                showLogButton: false
            )
            .accessibilityElement(children: .contain)
            .fadeIn(delay: 0.05)
            .revealOnScroll()
            // Announce Alignment on first appearance for this date
            .task {
                if let r = item.resonance, !r.topHits.isEmpty {
                    announceAlignmentIfNeeded()
                }
            }
        } else if horoscopeVM.loading {
            loadingShimmer
        } else {
            emptyState
        }
    }
    
    private var loadingShimmer: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.dlViolet.opacity(theme.isLight ? 0.25 : 0.35),
                        Color.dlIndigo.opacity(theme.isLight ? 0.2 : 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 200, height: 18)
                        .shimmer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 260, height: 14)
                        .shimmer()
                }
                .padding(28)
            )
            .padding(.horizontal, 20)
    }
    
    private var emptyState: some View {
        VStack(spacing: 18) {
            DLAssetImage.emptyToday
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .opacity(theme.isLight ? 0.95 : 0.9)
            
            VStack(spacing: 8) {
                Text("Your cosmic forecast")
                    .dlType(.titleM)
                    .fontWeight(.semibold)
                
                Text("We're tuning to your sky. Add your birth details for a reading that feels like it knows you.")
                    .dlType(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Text("Tip: log last night's dream to weave it into today's reading.")
                .dlType(.caption)
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 36)
    }
}

private struct DreamLinkChip: View {
    let link: DreamLink
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(link.motif)
                .dlType(.bodyS)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(link.line)
                .dlType(.bodyS)
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
    }
}

private extension TodayView {
    var heroActions: (do: [String], dont: [String]) {
        guard let item = horoscopeVM.item else { return ([], []) }
        let actions = item.aggregatedActions
        return (Array(actions.do.prefix(2)),
                Array(actions.dont.prefix(2)))
    }
}
