import SwiftUI

struct ConstellationPreview: View {
    let count: Int
    let onTap: () -> Void
    @Environment(ThemeService.self) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your dream constellation")
                        .font(DLFont.body(16)).fontWeight(.semibold)
                    Text("\(count) related entries are in orbit")
                        .font(DLFont.body(13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption)
            }
            .padding(16)
            .background(theme.palette.capsuleFill,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Your dream constellation. \(count) related entries. Double tap to open.")
    }
}


