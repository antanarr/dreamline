import SwiftUI

struct ActionChips: View {
    let doItems: [String]
    let dontItems: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !doItems.isEmpty {
                chipRow(title: "Do", items: doItems, icon: "checkmark", tint: .dlMint)
            }
            
            if !dontItems.isEmpty {
                chipRow(title: "Don't", items: dontItems, icon: "xmark", tint: .dlAmber)
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private func chipRow(title: String, items: [String], icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .accessibilityAddTraits(.isHeader)
            
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { text in
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(text)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .background(tint.opacity(0.22), in: Capsule())
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(items.count) \(items.count == 1 ? "item" : "items"): \(items.joined(separator: ", "))")
    }
}
