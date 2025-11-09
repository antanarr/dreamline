import SwiftUI

struct TransitDiagramView: View {
    let label: String
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(spacing: 0) {
            Text(planetALabel.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.dlIndigo)
            
            Text("|")
                .font(.system(size: 16, weight: .ultraLight, design: .monospaced))
                .foregroundStyle(.secondary)
            
            Text(aspectLabel.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(theme.palette.capsuleFill, in: Capsule())
            
            Text("|")
                .font(.system(size: 16, weight: .ultraLight, design: .monospaced))
                .foregroundStyle(.secondary)
            
            Text(planetBLabel.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.dlMint)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.palette.cardFillSecondary.opacity(0.5))
        )
    }
    
    private var components: [String] {
        label.split(separator: " ").map { String($0) }
    }
    
    private var planetALabel: String {
        components.first ?? "PLANET"
    }
    
    private var aspectLabel: String {
        if components.count >= 2 {
            let aspect = components[1]
            switch aspect.lowercased() {
            case "trine": return "△ (120°)"
            case "sextile": return "⚹ (60°)"
            case "square": return "□ (90°)"
            case "opposition": return "☍ (180°)"
            case "conjunction": return "☌ (0°)"
            default: return aspect.uppercased()
            }
        }
        return "ASPECT"
    }
    
    private var planetBLabel: String {
        if components.count >= 3 {
            return components[2...].joined(separator: " ")
        }
        return "PLANET"
    }
}

