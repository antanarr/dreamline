import SwiftUI

struct YourDayHeroCard: View {
    let headline: String
    let summary: String?
    let dreamEnhancement: String?
    var showLogButton: Bool = false
    var onLogDream: (() -> Void)? = nil
    
    @Environment(ThemeService.self) private var theme: ThemeService
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(headline)
                .font(DLFont.title(34))
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
                .foregroundStyle(.primary)
            
            if let summary, !summary.isEmpty {
                Text(summary)
                    .font(DLFont.body(17))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let enhancement = dreamEnhancement, !enhancement.isEmpty {
                Text(enhancement)
                    .font(DLFont.body(15))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if showLogButton, let onLogDream {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onLogDream()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Log a dream")
                            .font(DLFont.body(15))
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .foregroundStyle(.primary)
                    .scaleEffect(isPressed ? 0.96 : 1.0)
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

