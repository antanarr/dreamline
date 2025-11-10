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
                    .font(DLFont.body(12))
                    .foregroundStyle(.secondary)
                    .kerning(1.2)
                    .textCase(.uppercase)
                
                Spacer()
                
                if !isPro {
                    Button(action: onUnlock) {
                        Text("PRO")
                            .font(DLFont.body(10))
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
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var emptyState: some View {
        Text("Best days calculation coming soon")
            .font(DLFont.body(14))
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
                        Text("VIEW FULL WEEK")
                            .font(DLFont.body(14))
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(theme.palette.capsuleFill, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
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
                    Image(systemName: "lock.open.fill")
                    Text("Unlock Best Days")
                }
                .font(DLFont.body(14))
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
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return shape
            .fill(theme.palette.cardFillSecondary)
            .overlay(
                Image("bg_horoscope_card")
                    .resizable()
                    .scaledToFill()
                    .opacity(theme.isLight ? 0.35 : 0.18)
                    .clipShape(shape)
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
                    .font(DLFont.body(15))
                    .fontWeight(.semibold)
                
                if showContext && !isLocked {
                    Text(day.reason)
                        .font(DLFont.body(13))
                        .foregroundStyle(.secondary)
                    
                    if let context = day.dreamContext {
                        HStack(spacing: 6) {
                            Image("symbol_ocean")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                            Text(context)
                                .font(DLFont.body(12))
                        }
                        .foregroundStyle(Color.dlMint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.dlMint.opacity(0.1), in: Capsule())
                    }
                } else if isLocked {
                    Text("Unlock to see why")
                        .font(DLFont.body(13))
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            if isLocked {
                Image("icon_oracle")
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
                .font(DLFont.body(11))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text("\(dayNumber)")
                .font(DLFont.title(20))
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

