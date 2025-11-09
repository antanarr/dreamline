import SwiftUI

struct LifeAreaRow: View {
    let area: HoroscopeArea
    let isLocked: Bool
    let onTap: () -> Void
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: lifeArea.iconSystemName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isLocked ? .secondary : Color.dlIndigo)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(area.title)
                        .font(DLFont.body(16))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if !isLocked, let firstBullet = area.bullets.first {
                        Text(firstBullet)
                            .font(DLFont.body(14))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else if isLocked {
                        Text("Unlock to view guidance")
                            .font(DLFont.body(14))
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                
                Spacer()
                
                Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                    .font(.caption)
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
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    private var lifeArea: LifeArea {
        LifeArea(rawID: area.id)
    }
}

