import SwiftUI

struct YourDayHeroCard: View {
    let headline: String
    let dreamEnhancement: String?
    let onLogDream: () -> Void
    
    @Environment(ThemeService.self) private var theme: ThemeService
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR DAY")
                .font(DLFont.body(12))
                .foregroundStyle(.secondary)
                .kerning(1.2)
                .textCase(.uppercase)
            
            Text(headline)
                .font(DLFont.title(34))
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
            
            if let enhancement = dreamEnhancement {
                Text(enhancement)
                    .font(DLFont.body(16))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button(action: {
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onLogDream()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.body.weight(.semibold))
                    Text("Capture Your Night")
                        .font(DLFont.body(16))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.dlIndigo, Color.dlViolet],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .foregroundStyle(Color.white)
                .scaleEffect(isPressed ? 0.95 : 1.0)
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
        .padding(24)
        .background(
            theme.palette.cardFillPrimary
                .overlay(
                    Image("pattern_stargrid_tile")
                        .resizable(resizingMode: .tile)
                        .opacity(theme.mode == .dawn ? 0.08 : 0.2)
                        .blendMode(.screen)
                )
        )
        .overlay(
            Rectangle()
                .fill(theme.palette.separator)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

