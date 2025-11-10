import SwiftUI
import UIKit

struct YourDayHeroCard: View {
    let headline: String
    let summary: String?
    let dreamEnhancement: String?
    var showLogButton: Bool = false
    var onLogDream: (() -> Void)? = nil
    
    @Environment(ThemeService.self) private var theme: ThemeService
    @State private var isPressed = false
    @State private var animateHalo = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundCard
                .overlay(heroHalo)
            
            VStack(alignment: .leading, spacing: 18) {
                Label("Day at a Glance", systemImage: "sparkles")
                    .font(DLFont.body(13))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15), in: Capsule())
                
                VStack(alignment: .leading, spacing: 14) {
                    Text(headline)
                        .font(DLFont.title(36))
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                        .foregroundStyle(Color.white)
                    
                    if let summary, !summary.isEmpty {
                        Text(summary)
                            .font(DLFont.body(18))
                            .foregroundStyle(Color.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if let enhancement = dreamEnhancement, !enhancement.isEmpty {
                        dreamEnhancementPill(enhancement)
                    }
                }
                
                if showLogButton, let onLogDream {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            onLogDream()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Log a dream")
                                .font(DLFont.body(16))
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.18), in: Capsule())
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
            }
            .padding(28)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .task {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                animateHalo = true
            }
        }
    }
    
    private var backgroundCard: some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)
        
        return shape
            .fill(
                LinearGradient(
                    colors: theme.isLight
                        ? [Color.dlIndigo.opacity(0.9), Color.dlViolet.opacity(0.85)]
                        : [Color.dlIndigo.opacity(0.95), Color.black.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image("bg_nebula_full")
                    .resizable()
                    .scaledToFill()
                    .opacity(theme.isLight ? 0.45 : 0.55)
                    .blendMode(.screen)
                    .clipShape(shape)
            )
            .overlay(
                Image("pattern_stargrid_tile")
                    .resizable(resizingMode: .tile)
                    .scaleEffect(0.6)
                    .opacity(theme.isLight ? 0.16 : 0.22)
                    .blendMode(.screen)
                    .clipShape(shape)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(theme.isLight ? 0.18 : 0.12))
            )
    }
    
    private var heroHalo: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.32),
                        Color.white.opacity(0.0)
                    ],
                    center: .topTrailing,
                    startRadius: animateHalo ? 140 : 120,
                    endRadius: animateHalo ? 320 : 260
                )
            )
            .frame(width: 420, height: 420)
            .offset(x: 120, y: -140)
            .allowsHitTesting(false)
    }
    
    private func dreamEnhancementPill(_ enhancement: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.9))
                .padding(10)
                .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Dream weaving")
                    .font(DLFont.body(13).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
                Text(enhancement)
                    .font(DLFont.body(15))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

