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
                    .font(DLFont.caption(12))
                    .foregroundStyle(.secondary)
                    .kerning(1.2)
                    .textCase(.uppercase)
                
                Spacer()
                
                if !isPro {
                    Button(action: onUnlock) {
                        Text("PRO")
                            .font(DLFont.caption(10))
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
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(theme.palette.cardFillSecondary)
    }
}

private struct BestDayRow: View {
    let day: BestDayInfo
    let showContext: Bool
    var isLocked: Bool = false
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(DLFont.caption(11))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Text("\(dayNumber)")
                    .font(DLFont.title(20))
                    .fontWeight(.bold)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(day.title)
                    .font(DLFont.body(15))
                    .fontWeight(.semibold)
                
                if showContext && !isLocked {
                    Text(day.reason)
                        .font(DLFont.body(13))
                        .foregroundStyle(.secondary)
                    
                    if let context = day.dreamContext {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption2)
                            Text(context)
                                .font(DLFont.caption(12))
                        }
                        .foregroundStyle(Color.dlMint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
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
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
}

