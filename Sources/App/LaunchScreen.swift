import SwiftUI

/// Instant feedback on app launch - shows immediately while Firebase initializes
struct LaunchScreen: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Deep space gradient
            LinearGradient(
                colors: [
                    Color(hex: 0x0A0E27),
                    Color(hex: 0x1A1F3A),
                    Color(hex: 0x2A2F4A)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle star field
            DLAssetImage.starGrid
                .resizable(resizingMode: .tile)
                .scaleEffect(0.8)
                .opacity(0.12)
                .blendMode(.screen)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // App icon or logo
                DLAssetImage.oracleIcon
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dlLilac, Color.dlViolet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.6 + 0.4 * sin(Double(phase) * .pi * 2))
                
                Text("Dreamline")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundStyle(.white.opacity(0.9))
                
                // Subtle breathing dots (simpler than full spinner)
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .opacity(0.3 + 0.7 * sin(Double(phase + CGFloat(i) * 0.3) * .pi * 2))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                phase = 1.0
            }
        }
    }
}

