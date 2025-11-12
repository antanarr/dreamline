import SwiftUI

/// Dreamline's signature loading indicator: a constellation of dots that breathe and connect.
/// Inspired by Co-Star but uniquely mystical - dots pulse individually and lines shimmer between them.
struct ConstellationSpinner: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0
    @State private var rotation: Double = 0
    
    var size: CGFloat = 80
    var dotCount: Int = 5
    var color: Color = .white
    
    var body: some View {
        spinnerContent
            .frame(width: size, height: size)
            .rotationEffect(.degrees(reduceMotion ? 0 : rotation))
            .onAppear {
                if !reduceMotion {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                    withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                        phase = 1.0
                    }
                }
            }
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    private var spinnerContent: some View {
        ZStack {
            connectingLines
            breathingDots
        }
    }
    
    private var connectingLines: some View {
        Canvas { ctx, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2.5
            
            for i in 0..<dotCount {
                let angle1 = Double(i) / Double(dotCount) * 2 * .pi + rotation
                let p1 = CGPoint(
                    x: center.x + CGFloat(cos(angle1) * radius),
                    y: center.y + CGFloat(sin(angle1) * radius)
                )
                
                let next = (i + 1) % dotCount
                let angle2 = Double(next) / Double(dotCount) * 2 * .pi + rotation
                let p2 = CGPoint(
                    x: center.x + CGFloat(cos(angle2) * radius),
                    y: center.y + CGFloat(sin(angle2) * radius)
                )
                
                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)
                
                let linePhase = (phase + CGFloat(i) * 0.2).truncatingRemainder(dividingBy: 1.0)
                let opacity = 0.15 + 0.15 * sin(linePhase * .pi * 2)
                
                ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: 1.0)
            }
        }
    }
    
    private var breathingDots: some View {
        ForEach(0..<dotCount, id: \.self) { i in
            Circle()
                .fill(color)
                .frame(width: dotSize(index: i), height: dotSize(index: i))
                .offset(dotOffset(index: i))
                .opacity(dotOpacity(index: i))
        }
    }
    
    private func dotOffset(index: Int) -> CGSize {
        let angle = Double(index) / Double(dotCount) * 2 * .pi
        let radius = Double(size) / 2.5
        return CGSize(
            width: CGFloat(cos(angle) * radius),
            height: CGFloat(sin(angle) * radius)
        )
    }
    
    private func dotSize(index: Int) -> CGFloat {
        let baseSize: CGFloat = 6
        let breathePhase = (phase + CGFloat(index) * 0.15).truncatingRemainder(dividingBy: 1.0)
        let scale = 1.0 + 0.3 * sin(breathePhase * .pi * 2)
        return baseSize * scale
    }
    
    private func dotOpacity(index: Int) -> Double {
        let breathePhase = (phase + CGFloat(index) * 0.15).truncatingRemainder(dividingBy: 1.0)
        return 0.6 + 0.4 * sin(breathePhase * .pi * 2)
    }
}

/// Preset: Full-screen centered constellation spinner with mystical message
struct ConstellationLoadingView: View {
    let message: String
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(spacing: 24) {
            ConstellationSpinner(size: 100, dotCount: 6, color: .white.opacity(0.9))
            
            Text(message)
                .dlType(.body)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: theme.palette.horoscopeCardBackground,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                DLAssetImage.starGrid
                    .resizable(resizingMode: .tile)
                    .scaleEffect(0.8)
                    .opacity(0.15)
                    .blendMode(.screen)
            )
        )
    }
}

// MARK: - Shimmer Loading State (for cards)

/// Breathing shimmer effect for card placeholders
struct BreathingShimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.12),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: -200 + (phase * 400))
                .allowsHitTesting(false)
            )
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                        phase = 1.0
                    }
                }
            }
    }
}

extension View {
    func breathingShimmer() -> some View {
        modifier(BreathingShimmer())
    }
}

