import SwiftUI

struct BestDaysView: View {
    let days: [BestDayInfo]
    let isPro: Bool
    let onViewFull: () -> Void
    let onUnlock: () -> Void
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("YOUR BEST DAYS")
                    .dlType(.caption)
                    .foregroundStyle(.secondary)
                    .kerning(1.2)
                    .textCase(.uppercase)
                
                Spacer()
                
                if !isPro {
                    Button(action: onUnlock) {
                        Text("PRO")
                            .font(.caption.weight(.semibold))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.dlViolet)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if days.isEmpty {
                emptyState
            } else if isPro {
                proContent
            } else {
                freeContent
            }
        }
        .padding(24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var emptyState: some View {
        Text("Best days calculation coming soon")
            .dlType(.bodyS)
            .foregroundStyle(.secondary)
            .italic()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }
    
    private var proContent: some View {
        VStack(spacing: 12) {
            ForEach(days.prefix(2)) { day in
                BestDayRow(day: day, showContext: true)
            }
            
            if days.count > 2 {
                Button(action: onViewFull) {
                    HStack {
                        Text("View full calendar")
                            .dlType(.body)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        DLAssetImage.oracleIcon
                            .renderingMode(.template)
                            .foregroundStyle(.primary.opacity(0.6))
                            .frame(width: 16, height: 16)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(theme.palette.capsuleFill, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .contentTransition(.opacity)
            }
        }
    }
    
    private var freeContent: some View {
        VStack(spacing: 12) {
            ForEach(days.prefix(2)) { day in
                BestDayRow(day: day, showContext: false, isLocked: true)
            }
            
            Button(action: onUnlock) {
                HStack {
                    DLAssetImage.oracleIcon
                        .renderingMode(.template)
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 16, height: 16)
                    Text("Unlock Best Days")
                }
                .dlType(.body)
                .fontWeight(.semibold)
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
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
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
                    .opacity(theme.isLight ? 0.22 : 0.14)
            )
    }
}

private struct BestDayRow: View {
    let day: BestDayInfo
    let showContext: Bool
    var isLocked: Bool = false
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            leadingBadge
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(day.title)
                    .dlType(.body)
                    .fontWeight(.semibold)
                
                if showContext && !isLocked {
                    Text(day.reason)
                        .dlType(.bodyS)
                        .foregroundStyle(.secondary)
                    
                    if let context = day.dreamContext {
                        HStack(spacing: 6) {
                            DLAssetImage.symbol("ocean")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                            Text(context)
                                .dlType(.caption)
                        }
                        .foregroundStyle(Color.dlMint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.dlMint.opacity(0.1), in: Capsule())
                    }
                } else if isLocked {
                    Text("Unlock to see why")
                        .dlType(.bodyS)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            if isLocked {
                DLAssetImage.oracleIcon
                    .renderingMode(.template)
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.palette.capsuleFill)
        )
        .opacity(isLocked ? 0.6 : 1.0)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date).uppercased()
    }
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: day.date)
    }
    
    private var leadingBadge: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .dlType(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text("\(dayNumber)")
                .dlType(.titleM)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.dlIndigo.opacity(0.18), Color.dlViolet.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

