import SwiftUI

// Subtle gradient overlay to improve text contrast over imagery.
struct ReadableScrim: ViewModifier {
    let opacity: Double
    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(colors: [Color.black.opacity(opacity), .clear],
                           startPoint: .top, endPoint: .bottom)
        )
    }
}

extension View {
    func readableScrim(_ opacity: Double = 0.40) -> some View {
        modifier(ReadableScrim(opacity: opacity))
    }
}

// Pull-to-refresh that avoids re-entrancy crashes.
struct SafeRefresh: ViewModifier {
    let action: () async -> Void
    @State private var isRefreshing = false

    func body(content: Content) -> some View {
        content.refreshable {
            if isRefreshing { return }
            isRefreshing = true
            defer { isRefreshing = false }
            await action()
        }
    }
}

extension View {
    func safeRefresh(_ action: @escaping () async -> Void) -> some View {
        modifier(SafeRefresh(action: action))
    }
}


