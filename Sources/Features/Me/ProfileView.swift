import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ProfileView: View {
    @Environment(EntitlementsService.self) private var entitlements
    @Environment(DreamStore.self) private var store
    @Environment(ThemeService.self) private var theme: ThemeService
    @StateObject private var usage = UsageService.shared
    @ObservedObject private var rc = RemoteConfigService.shared
    @State private var showPaywall = false
    @State private var showBirthEditor = false
    @State private var selectedThemeMode: ThemeService.Mode = .system
    @State private var weeklyInterpretCount: Int = 0
    @AppStorage("app.lock.enabled") private var lockEnabled = false
    @AppStorage(BirthDataKeys.timestamp) private var birthTimestamp: Double = 0
    @AppStorage(BirthDataKeys.timeKnown) private var birthTimeKnown: Bool = true
    @AppStorage(BirthDataKeys.place) private var birthPlace: String = ""
    @AppStorage(BirthDataKeys.timezone) private var birthTimezone: String = ""
    
    private let featureMap: [Tier: [String]] = [
        .free: [
            "Dream journal & motif logging",
            "3 Oracle interpretations per week",
            "Daily Dream-Synced horoscope preview"
        ],
        .plus: [
            "Unlimited interpretations",
            "30-day insights & symbol seasonality",
            "Dream-Synced horoscope in full"
        ],
        .pro: [
            "Everything in Plus",
            "Oracle Chat & voice transcription",
            "90-day analytics & Deep Read credits"
        ]
    ]
    
    private var dreamEntries: [DreamEntry] { store.entries }
    private var dreamCount: Int { dreamEntries.count }
    private var interpretedEntries: [DreamEntry] {
        dreamEntries.filter { $0.oracleSummary != nil }
    }
    
    private var metrics: [ProfileMetric] {
        [
            ProfileMetric(
                title: "Dreams logged",
                value: "\(dreamCount)",
                caption: dreamCount == 1 ? "Entry on record" : "Entries on record",
                icon: "moon.zzz.fill",
                tint: Color.dlLilac
            ),
            ProfileMetric(
                title: "Active streak",
                value: dreamStreak == 0 ? "—" : "\(dreamStreak)",
                caption: dreamStreakCaption,
                icon: "flame.fill",
                tint: Color.dlAmber
            ),
            ProfileMetric(
                title: "Interpretations",
                value: "\(interpretedEntries.count)",
                caption: interpretedEntries.count == 1 ? "Oracle read" : "Oracle reads",
                icon: "sparkles",
                tint: Color.dlMint
            ),
            ProfileMetric(
                title: "Last interpreted",
                value: lastInterpretedValue,
                caption: "Tap any dream to revisit the insight.",
                icon: "clock.badge.checkmark.fill",
                tint: Color.dlViolet
            )
        ]
    }
    
    private var dreamStreak: Int {
        guard !dreamEntries.isEmpty else { return 0 }
        let calendar = Calendar.current
        let uniqueDays = Set(dreamEntries.map { calendar.startOfDay(for: $0.createdAt) }).sorted(by: >)
        
        var streak = 0
        var previousDay: Date?
        
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
    
    private var dreamStreakCaption: String {
        switch dreamStreak {
        case 0:
            return "Log tonight to start a streak."
        case 1:
            return "Day in a row"
        default:
            return "Days in a row"
        }
    }
    
    private var lastInterpretedValue: String {
        guard let latest = interpretedEntries.max(by: { $0.createdAt < $1.createdAt }) else {
            return "Not yet"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: latest.createdAt, relativeTo: Date())
    }
    
    private var birthSummary: String? {
        guard birthTimestamp > 0 else { return nil }
        let date = Date(timeIntervalSince1970: birthTimestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let datePart = dateFormatter.string(from: date)
        let timePart = birthTimeKnown ? timeFormatter.string(from: date) : "Time unknown"
        let placePart = birthPlace.isEmpty ? "Tap to add place" : birthPlace
        let timezonePart = birthTimezone.isEmpty ? "" : " • \(birthTimezone)"
        return "\(datePart) · \(timePart) · \(placePart)\(timezonePart)"
    }
    
    private func triggerUpgradeImpact() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    heroCard
                    
                    if entitlements.tier == .free {
                        quotaCard
                    }
                    
                    activityCard
                    birthCard
                    membershipCard
                    
                    if entitlements.tier == .pro {
                        oracleCard
                    }
                    
                    securityCard
                appearanceCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
            .background(
            Color.clear
                .dreamlineScreenBackground()
            )
            .navigationTitle("Me")
            .navigationDestination(isPresented: $showBirthEditor) {
                BirthDataEditorView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                selectedThemeMode = theme.mode
            }
            .task {
                weeklyInterpretCount = await usage.weeklyInterpretCount(weekStart: Date())
            }
        }
    }
    
    private var quotaCard: some View {
        let maxInterprets = rc.config.freeInterpretationsPerWeek
        let remaining = max(0, maxInterprets - weeklyInterpretCount)
        let progress = maxInterprets > 0 ? Double(weeklyInterpretCount) / Double(maxInterprets) : 0.0
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(remaining > 0 ? Color.dlMint : Color.dlAmber)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly quota")
                        .font(DLFont.title(20))
                        .foregroundStyle(.primary)
                    
                    if remaining > 0 {
                        Text("\(remaining) of \(maxInterprets) interpretations left this week")
                            .font(DLFont.body(12))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Quota exhausted — upgrade for unlimited")
                            .font(DLFont.body(12))
                            .foregroundStyle(Color.dlAmber)
                    }
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.palette.capsuleFill)
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: remaining > 0 ? [Color.dlMint, Color.dlLilac] : [Color.dlAmber, Color.dlAmber.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(1.0, progress), height: 8)
                }
            }
            .frame(height: 8)
            
            if remaining == 0 {
                Button {
                    triggerUpgradeImpact()
                    showPaywall = true
                } label: {
                    Text("Unlock unlimited interpretations")
                        .font(DLFont.body(14))
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
        .padding(22)
        .background(standardCardBackground(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dlIndigo, Color.dlViolet],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.dlViolet.opacity(0.35), radius: 16, x: 0, y: 12)
                    
                    Image("lock_screen_illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dreamline account")
                        .font(DLFont.title(24))
                        .foregroundStyle(.primary)
                    
                    Label(entitlements.tier.rawValue.capitalized + " tier", systemImage: "crown.fill")
                        .font(DLFont.body(13))
                        .foregroundStyle(Color.dlLilac)
                }
                
                Spacer()
            }
            
            Text("Adjust your membership, explore premium features, and tune your security preferences.")
                .font(DLFont.body(13))
                .foregroundStyle(.secondary)
            
            Button {
                triggerUpgradeImpact()
                showPaywall = true
            } label: {
                Text("Manage subscription")
                    .font(DLFont.body(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.dlIndigo, Color.dlViolet],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .foregroundStyle(Color.white)
            }
        }
        .padding(24)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Activity pulse")
                .font(DLFont.title(20))
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 18) {
                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: metric.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(metric.tint)
                            Text(metric.title)
                                .font(DLFont.body(12))
                                .foregroundStyle(.secondary)
                        }
                        Text(metric.value)
                            .font(DLFont.title(24))
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(theme.palette.cardStroke)
                    )
                }
            }
        }
        .padding(24)
        .background(standardCardBackground(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var birthCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dlMint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Birth profile")
                        .font(DLFont.title(20))
                        .foregroundStyle(.primary)
                    Text("Setting your birth data sharpens the Dream-Synced horoscope.")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                if let summary = birthSummary {
                    Label {
                        Text(summary)
                            .font(DLFont.body(13))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "location.north.line.fill")
                            .foregroundStyle(Color.dlLilac)
                    }
                    .labelStyle(.iconOnly)
                    .overlay(alignment: .leading) {
                        Text(summary)
                            .font(DLFont.body(13))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 24)
                    }
                } else {
                    Text("Add your birth date, time, and place to personalise transits.")
                        .font(DLFont.body(13))
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                triggerUpgradeImpact()
                showBirthEditor = true
            } label: {
                HStack {
                    Text(birthSummary == nil ? "Add birth details" : "Edit birth details")
                        .font(DLFont.body(14))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(16)
                .background(theme.palette.cardFillSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(standardCardBackground(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your benefits")
                .font(DLFont.title(20))
                .foregroundStyle(.primary)
            
            if let perks = featureMap[entitlements.tier] {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(perks, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.dlMint)
                            Text(feature)
                                .font(DLFont.body(13))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            if entitlements.tier != .pro {
                Button {
                    triggerUpgradeImpact()
                    showPaywall = true
                } label: {
                    Text("Unlock Dreamline Pro")
                        .font(DLFont.body(14))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.dlLilac)
                    Text("You're on our most expansive tier.")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background(standardCardBackground(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var oracleCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "ellipsis.bubble.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dlLilac)
                Text("Oracle tools")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
            }
            
            Text("Chat live with the Dreamline Oracle, drop in voice notes, and surface long arc patterns.")
                .font(DLFont.body(13))
                .foregroundStyle(.secondary)
            
            NavigationLink {
                OracleChatView(tier: entitlements.tier)
            } label: {
                HStack {
                    Text("Open Oracle Chat")
                        .font(DLFont.body(14))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(16)
                .background(theme.palette.cardFillSecondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(oracleCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dlMint)
                Text("Security & privacy")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $lockEnabled.animation(), label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Require Face ID on resume")
                            .font(DLFont.body(14))
                            .foregroundStyle(.primary)
                        Text("Adds a biometric prompt whenever you reopen Dreamline.")
                            .font(DLFont.body(12))
                            .foregroundStyle(.secondary)
                    }
                })
                .toggleStyle(SwitchToggleStyle(tint: Color.dlLilac))
                .disabled(!AppLockService.canEvaluate())
                
                if !AppLockService.canEvaluate() {
                    Text("Face ID or Touch ID not available on this device.")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background(standardCardBackground(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(DLFont.title(20))
                .foregroundStyle(.primary)
            
            Text("Choose how Dreamline renders surfaces. Dawn brightens for morning reflections; Dusk dims for low-light journaling.")
                .font(DLFont.body(12))
                .foregroundStyle(.secondary)
            
            Picker("Appearance", selection: $selectedThemeMode) {
                ForEach(ThemeService.Mode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedThemeMode) { _, newValue in
                theme.mode = newValue
            }
        }
        .padding(24)
        .background(standardCardBackground(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var heroBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let topColor = theme.isLight ? Color(hex: 0xF4F4FF, alpha: 0.95) : Color.dlSpace.opacity(0.96)
        let bottomColor = theme.isLight ? Color(hex: 0xE3ECFF, alpha: 0.85) : Color.dlSpace.opacity(0.8)
        return shape
            .fill(
                LinearGradient(
                    colors: [topColor, bottomColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image("pattern_stargrid_tile")
                    .resizable(resizingMode: .tile)
                    .opacity(theme.isLight ? 0.08 : 0.14)
                    .blendMode(.screen)
                    .clipShape(shape)
            )
    }
    
    private func standardCardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(theme.palette.cardFillSecondary)
    }
    
    private var oracleCardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        let topColor = theme.isLight ? Color(hex: 0xF3F3FF, alpha: 0.92) : Color.dlSpace.opacity(0.95)
        let bottomColor = theme.isLight ? Color(hex: 0xE4EDFF, alpha: 0.82) : Color.dlIndigo.opacity(0.45)
        return shape
            .fill(
                LinearGradient(
                    colors: [topColor, bottomColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image("pattern_gradientnoise_tile")
                    .resizable(resizingMode: .tile)
                    .opacity(theme.isLight ? 0.08 : 0.18)
                    .blendMode(.plusLighter)
                    .clipShape(shape)
            )
    }
}

private struct ProfileMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let caption: String
    let icon: String
    let tint: Color
}

