import SwiftUI

// MARK: - Goosebumps Moment (Alignment Detection)

/// Subtle radial pulse + shimmer when an Alignment Event is detected
/// Inspired by the feeling of recognition - not fireworks, but a knowing.
struct GoosebumpsMoment: ViewModifier {
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale) // Fade as it expands
                    .allowsHitTesting(false)
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(shimmerPhase * 360))
                .opacity(0.5)
                .allowsHitTesting(false)
            )
            .onAppear {
                if !reduceMotion {
                    // Single gentle pulse
                    withAnimation(.easeOut(duration: 1.2)) {
                        pulseScale = 2.0
                    }
                    // Slow shimmer sweep
                    withAnimation(.linear(duration: 2.0)) {
                        shimmerPhase = 1.0
                    }
                }
            }
    }
}

extension View {
    func goosebumpsMoment() -> some View {
        modifier(GoosebumpsMoment())
    }
}

// MARK: - Parallax Drift

/// Gentle parallax effect - VISUAL ONLY, doesn't affect layout
/// Uses overlay + offset so parent's layout size is unchanged
struct ParallaxDrift: ViewModifier {
    let magnitude: CGFloat
    @State private var offset: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .overlay {
                // Visual-only drift layer
                content
                    .offset(offset)
                    .allowsHitTesting(false)
                    .onAppear {
                        if !reduceMotion {
                            withAnimation(
                                .easeInOut(duration: 8.0)
                                .repeatForever(autoreverses: true)
                            ) {
                                offset = CGSize(
                                    width: magnitude * 0.3,
                                    height: magnitude * 0.5
                                )
                            }
                        }
                    }
            }
            .mask(content) // Clip to original bounds
    }
}

extension View {
    /// Subtle drift animation for depth (magnitude in points)
    /// LAYOUT-SAFE: Uses overlay so doesn't affect measured size
    func parallaxDrift(_ magnitude: CGFloat = 8) -> some View {
        modifier(ParallaxDrift(magnitude: magnitude))
    }
}

// MARK: - Constellation Connection Lines

/// Animated lines that connect when resonance is detected
struct ConstellationConnection: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    
    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            
            let trimmed = path.trimmedPath(from: 0, to: progress)
            ctx.stroke(
                trimmed,
                with: .color(color.opacity(0.6)),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    progress = 1.0
                }
            } else {
                progress = 1.0
            }
        }
    }
}

// MARK: - Mystical Glow

/// Soft radial glow for emphasis (horoscope cards, alignment badges)
struct MysticalGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var intensity: Double = 0.3
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity), radius: radius, x: 0, y: 0)
            .onAppear {
                if !reduceMotion {
                    withAnimation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        intensity = 0.6
                    }
                }
            }
    }
}

extension View {
    func mysticalGlow(color: Color = .white, radius: CGFloat = 12) -> some View {
        modifier(MysticalGlow(color: color, radius: radius))
    }
}

// MARK: - Reveal on Scroll (already exists, documenting here)

/// Elements fade in as they scroll into view
/// Implementation in Animations.swift - RevealOnScroll

// MARK: - Star Twinkle

/// Random twinkling effect for individual star/dot elements
struct StarTwinkle: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                if !reduceMotion {
                    withAnimation(
                        .easeInOut(duration: Double.random(in: 1.5...3.0))
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                    ) {
                        opacity = Double.random(in: 0.4...0.8)
                    }
                }
            }
    }
}

extension View {
    func starTwinkle(delay: Double = 0) -> some View {
        modifier(StarTwinkle(delay: delay))
    }
}

