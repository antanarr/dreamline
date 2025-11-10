import SwiftUI

struct BehindThisForecastView: View {
    let transits: [HoroscopeStructured.TransitPill]
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BEHIND THIS FORECAST")
                .font(DLFont.body(12))
                .foregroundStyle(.secondary)
                .kerning(1.2)
                .textCase(.uppercase)
            
            VStack(spacing: 12) {
                ForEach(Array(transits.prefix(3).enumerated()), id: \.element.label) { index, transit in
                    TransitExplanationRow(
                        label: transit.label,
                        tone: transit.tone
                    )
                }
            }
        }
        .padding(24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(theme.palette.cardFillSecondary)
    }
}

struct TransitExplanationRow: View {
    let label: String
    let tone: String
    
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: planetIcon)
                .font(.title2)
                .foregroundStyle(tintColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(DLFont.body(16))
                    .fontWeight(.semibold)
                
                Text(toneExplanation)
                    .font(DLFont.body(14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(theme.palette.capsuleFill, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var planetIcon: String {
        let lowercased = label.lowercased()
        if lowercased.contains("sun") { return "sun.max.fill" }
        if lowercased.contains("moon") { return "moon.fill" }
        if lowercased.contains("mercury") { return "circle.fill" }
        if lowercased.contains("venus") { return "heart.fill" }
        if lowercased.contains("mars") { return "flame.fill" }
        if lowercased.contains("jupiter") { return "sparkles" }
        if lowercased.contains("saturn") { return "square.stack.3d.up.fill" }
        if lowercased.contains("uranus") { return "bolt.fill" }
        if lowercased.contains("neptune") { return "water.waves" }
        if lowercased.contains("pluto") { return "arrow.triangle.2.circlepath" }
        return "sparkles"
    }
    
    private var tintColor: Color {
        switch tone.lowercased() {
        case "supportive", "harmonious":
            return Color.dlMint
        case "challenging", "tense":
            return Color.dlAmber
        default:
            return Color.dlIndigo
        }
    }
    
    private var toneExplanation: String {
        let lowercased = label.lowercased()
        
        // Extract aspect type from label
        if lowercased.contains("trine") {
            return "A harmonious flow of energy. Things align naturally without force."
        } else if lowercased.contains("sextile") {
            return "Opportunities arise with gentle effort. Stay open to connections."
        } else if lowercased.contains("square") {
            return "Tension creates growth. Push through resistance to find clarity."
        } else if lowercased.contains("opposition") {
            return "Pull between extremes. Balance is the work, integration the reward."
        } else if lowercased.contains("conjunction") {
            return "Energies merge and amplify. What you focus on intensifies now."
        } else {
            // Generic fallback based on tone
            switch tone.lowercased() {
            case "supportive", "harmonious":
                return "Supportive planetary energy helps things flow more easily."
            case "challenging", "tense":
                return "Challenging aspect that asks for awareness and adjustment."
            default:
                return "Active planetary influence shaping today's energy."
            }
        }
    }
}

