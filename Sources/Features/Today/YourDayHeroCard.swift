import SwiftUI

struct YourDayHeroCard: View {
    let headline: String
    let dreamEnhancement: String?
    let onLogDream: () -> Void
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR DAY")
                .font(DLFont.body(12))
                .foregroundStyle(.secondary)
                .kerning(1.2)
                .textCase(.uppercase)
            
            Text(headline)
                .font(DLFont.title(28))
                .fixedSize(horizontal: false, vertical: true)
            
            if let enhancement = dreamEnhancement {
                Text(enhancement)
                    .font(DLFont.body(16))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button(action: onLogDream) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.body.weight(.semibold))
                    Text("Log Dream")
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
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.palette.cardStroke)
        )
    }
    
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return shape
            .fill(theme.palette.cardFillPrimary)
            .overlay(
                Image("pattern_stargrid_tile")
                    .resizable(resizingMode: .tile)
                    .opacity(theme.mode == .dawn ? 0.08 : 0.2)
                    .blendMode(.screen)
                    .clipShape(shape)
            )
    }
}

