import SwiftUI

struct TodayView: View {
    @Environment(DreamStore.self) private var store
    @StateObject private var vm = TodayViewModel()
    @State private var transit: TransitSummary? = nil
    @State private var isLoadingTransit: Bool = true
    @ObservedObject private var rc = RemoteConfigService.shared
    private let astro = AstroService.shared
    @State private var showRecorder = false
    @State private var startRecordingOnCompose = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    recordBanner
                    
                    DreamSyncedCard(
                        transit: transit,
                        recentThemes: recentThemes(),
                        summary: vm.summary,
                        isLoadingSummary: vm.isLoading,
                        isLoadingTransit: isLoadingTransit
                    )
                    
                    if rc.config.horoscopeEnabled {
                        TodayRangeView()
                    } else {
                        HoroscopeUnavailableCard()
                    }
                }
                .padding()
            }
            .background(
                Color.clear
                    .dreamlineScreenBackground()
            )
            .navigationTitle("Today")
            .task {
                await vm.load()
                isLoadingTransit = true
                transit = await astro.transits(for: .now)
                isLoadingTransit = false
            }
            .sheet(isPresented: $showRecorder, onDismiss: {
                startRecordingOnCompose = false
            }) {
                ComposeDreamView(store: store, startRecordingOnAppear: startRecordingOnCompose)
            }
            .onReceive(NotificationCenter.default.publisher(for: .dlStartVoiceCapture)) { _ in
                startRecordingOnCompose = true
                showRecorder = true
            }
        }
    }

    private func recentThemes() -> [String] {
        // Pull themes from the most recent dream that has an oracle summary,
        // otherwise use a shallow keyword pass on the latest rawText.
        guard let latest = store.entries.first else { return [] }
        if !latest.themes.isEmpty { return latest.themes }
        // naive backfill: pick 2-3 words from text
        let words = latest.rawText
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 4 }
        return Array(Set(words)).prefix(3).map { String($0) }
    }
    
    private var recordBanner: some View {
        Button {
            startRecordingOnCompose = true
            showRecorder = true
        } label: {
            HStack(spacing: 18) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Voice journal")
                        .font(DLFont.body(12))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Text("Record this morning’s dream")
                        .font(DLFont.title(20))
                        .foregroundStyle(Color.white)
                    Text("We’ll transcribe immediately and weave it into today’s insights.")
                        .font(DLFont.body(11))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.dlIndigo, Color.dlViolet],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.18))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DreamSyncedCard: View {
    let transit: TransitSummary?
    let recentThemes: [String]
    let summary: String
    let isLoadingSummary: Bool
    let isLoadingTransit: Bool
    @Environment(ThemeService.self) private var theme: ThemeService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dream-Synced Horoscope")
                .font(DLFont.title(24))
                .foregroundStyle(.primary)
            
            if isLoadingSummary {
                Group {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 20)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 20)
                            .frame(width: 200)
                    }
                }
                .shimmer()
            } else {
                Text(summary)
                    .font(DLFont.body(16))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.primary)
            }
            
            // Transit strip as pill
            if isLoadingTransit {
                Group {
                    HStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 32)
                            .frame(maxWidth: 150)
                    }
                }
                .shimmer()
            } else if let transit {
                HStack(spacing: 8) {
                    Text(transit.headline)
                        .font(DLFont.chip)
                        .foregroundStyle(.primary)
                    
                    if !transit.notes.isEmpty {
                        Text("•")
                            .font(DLFont.chip)
                            .foregroundStyle(.secondary)
                        
                        Text(transit.notes.joined(separator: " • "))
                            .font(DLFont.chip)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(theme.palette.capsuleFill)
                        .overlay(
                            Capsule()
                                .stroke(theme.palette.separator, lineWidth: 1)
                        )
                )
            } else {
                HStack(spacing: 8) {
                    Text("Transit data unavailable")
                        .font(DLFont.chip)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(theme.palette.capsuleFill)
                        .overlay(
                            Capsule()
                                .stroke(theme.palette.separator, lineWidth: 1)
                        )
                )
            }
            
            if !recentThemes.isEmpty {
                Text("Recent themes: " + recentThemes.joined(separator: ", "))
                    .font(DLFont.body(12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.palette.cardStroke, lineWidth: 1)
        )
    }
    
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return shape
            .fill(theme.palette.cardFillPrimary)
            .overlay(
                Image("pattern_stargrid_tile")
                    .resizable(resizingMode: .tile)
                    .opacity(theme.mode == .dawn ? 0.08 : 0.22)
                    .blendMode(.screen)
                    .clipShape(shape)
            )
            .overlay(
                Image("pattern_gradientnoise_tile")
                    .resizable(resizingMode: .tile)
                    .opacity(theme.mode == .dawn ? 0.06 : 0.15)
                    .blendMode(.plusLighter)
                    .clipShape(shape)
            )
    }
}

private struct HoroscopeUnavailableCard: View {
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.slash")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Horoscope Cooling Down")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
            }
            
            Text("We’re refreshing the sky notes. Check back in a little while for a new Dream-Synced read.")
                .font(DLFont.body(15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider().overlay(theme.palette.separator)
            
            Text("Tip: Log a dream while you wait so the next pull can weave in fresh motifs.")
                .font(DLFont.body(13))
                .foregroundStyle(.secondary)
        }
        .padding(20)
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
