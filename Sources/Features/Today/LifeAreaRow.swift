import SwiftUI
import UIKit

struct LifeAreaRow: View {
    let area: HoroscopeArea
    let isLocked: Bool
    let onTap: () -> Void
    
    @Environment(ThemeService.self) private var theme: ThemeService
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onTap()
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                leadingArtwork
                    .frame(width: 36, height: 36)
                
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
                
                Image(isLocked ? "icon_oracle" : "icon_oracle")
                    .renderingMode(.template)
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(theme.palette.cardFillSecondary)
            .overlay(
                Rectangle()
                    .fill(theme.palette.separator)
                    .frame(height: 1),
                alignment: .bottom
            )
            .opacity(isLocked ? 0.7 : 1.0)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
    
    private var lifeArea: LifeArea {
        LifeArea(rawID: area.id)
    }
    
    @ViewBuilder
    private var leadingArtwork: some View {
        if let image = UIImage(named: lifeArea.artworkAssetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
        } else {
            Image(systemName: lifeArea.iconSystemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isLocked ? .secondary : Color.dlIndigo)
        }
    }
}

