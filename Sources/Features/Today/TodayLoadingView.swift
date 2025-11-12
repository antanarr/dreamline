import SwiftUI

/// Loading skeleton for Today screen - follows HIG and NNg research
/// Shows skeleton immediately; adds spinner only after 600ms (avoids flicker for fast loads)
struct TodayLoadingView: View {
    let showSpinner: Bool
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hero skeleton
                VStack(alignment: .leading, spacing: 18) {
                    // Header badge skeleton
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 140, height: 12)
                    
                    // Headline skeleton
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 280, height: 24)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 240, height: 24)
                    }
                    
                    // Summary skeleton
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 320, height: 16)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 300, height: 16)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 260, height: 16)
                    }
                    
                    // Chips skeleton
                    HStack(spacing: 8) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.12))
                                .frame(width: 80, height: 28)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(theme.palette.cardFillPrimary)
                )
                .overlay {
                    if showSpinner {
                        // Delayed spinner (only shows if load takes >600ms)
                        VStack(spacing: 16) {
                            ConstellationSpinner(size: 60, dotCount: 6, color: .secondary)
                            Text("Reading the stars...")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(theme.palette.cardFillPrimary.opacity(0.95))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .breathingShimmer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

