import SwiftUI

struct FadeOnAppear: ViewModifier {
    let delay: Double
    @State private var shown = false
    
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45).delay(delay)) {
                    shown = true
                }
            }
    }
}

extension View {
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeOnAppear(delay: delay))
    }
}

struct Parallax: ViewModifier {
    var magnitude: CGFloat
    
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .global).minY
            content
                .offset(y: offset > 0 ? -offset / magnitude : 0)
        }
        .clipped()
    }
}

extension View {
    func parallax(_ magnitude: CGFloat = 8) -> some View {
        modifier(Parallax(magnitude: magnitude))
    }
}

struct RevealOnScroll: ViewModifier {
    var threshold: CGFloat = 80
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named("scroll")).minY
            let progress = min(1, max(0, (minY + threshold) / threshold))
            content
                .opacity(reduceMotion ? 1 : progress)
                .offset(y: reduceMotion ? 0 : (1 - progress) * 12)
        }
        .frame(maxWidth: .infinity)
    }
}

extension View {
    func revealOnScroll(threshold: CGFloat = 80) -> some View {
        modifier(RevealOnScroll(threshold: threshold))
    }
}
