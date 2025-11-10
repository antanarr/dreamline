import SwiftUI

struct TodayRangeView: View {
    @StateObject var vm = TodayRangeViewModel()
    @State private var selection: HoroscopeRange = .day
    @Environment(ThemeService.self) private var theme: ThemeService
    private let options: [HoroscopeRange] = HoroscopeRange.allCases
    private let tzIdentifier = TimeZone.current.identifier
    private let rangeNotes: [HoroscopeRange: String] = [
        .day: "Anchored to your local midnight. Pulls the latest transit mix.",
        .week: "Resets every Monday at 00:00. Zooms out for repeating motifs.",
        .month: "Covers the first through last day of the month. Great for planning.",
        .year: "Opens on January 1. Big patterns, slower tides."
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            pickerSection
            
            ZStack(alignment: .topLeading) {
                if let item = vm.item {
                    TodayStructuredView(item: item)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else if vm.loading {
                    OracleShimmer()
                } else {
                    TodayRangeEmptyState(message: vm.errorMessage) {
                        refresh(force: true)
                    }
                }
                
                if vm.loading, vm.item != nil {
                    overlayScrim
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.dlLilac)
                                .scaleEffect(1.1)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        )
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: vm.loading)
        }
        .padding(22)
        .background(cardBackground)
        .task { await vm.load(period: selection, tz: tzIdentifier, force: false) }
        .onChange(of: selection) { _, newValue in refresh(with: newValue, force: false) }
        .refreshable { await vm.load(period: selection, tz: tzIdentifier, force: true) }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sky Window")
                .font(DLFont.title(22))
                .foregroundStyle(.primary)
            
            Text(rangeNotes[selection] ?? "")
                .font(DLFont.body(13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var pickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Range", selection: $selection) {
                ForEach(options, id: \.self) { range in
                    Text(range.displayTitle).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("TodayRangePicker")
            
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dlLilac)
                Text(descriptionLabel)
                    .font(DLFont.body(12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Button {
                    refresh(force: true)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text(vm.loading ? "Refreshing…" : "Refresh")
                    }
                    .font(DLFont.body(12))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(theme.palette.capsuleFill, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(theme.palette.separator, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(vm.loading)
                .opacity(vm.loading ? 0.6 : 1)
            }
        }
    }
    
    private var descriptionLabel: String {
        switch selection {
        case .day: return "Generated once per day."
        case .week: return "Generated once per week."
        case .month: return "Generated once per month."
        case .year: return "Generated once per year."
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(theme.palette.cardFillSecondary)
    }
    
    private var overlayScrim: Color {
        theme.isLight ? Color.black.opacity(0.08) : Color.black.opacity(0.18)
    }
    
    private func refresh(force: Bool = false) {
        refresh(with: selection, force: force)
    }
    
    private func refresh(with range: HoroscopeRange, force: Bool) {
        Task { await vm.load(period: range, tz: tzIdentifier, force: force) }
    }
}

private struct TodayRangeEmptyState: View {
    var message: String?
    var retry: () -> Void
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "cloud.moon.bolt")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color.dlLilac)
                .padding(.bottom, 4)
            
            Text("Sky cache is quiet.")
                .font(DLFont.title(20))
            
            Text(message ?? "We couldn’t reach the horoscope service just now. Try again in a moment.")
                .font(DLFont.body(14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button {
                retry()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(DLFont.body(14))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(theme.palette.capsuleFill, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(theme.palette.separator, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.palette.cardFillSecondary)
        )
    }
}

#if DEBUG
#Preview {
    TodayRangeView()
        .padding()
}
#endif

