import SwiftUI

enum DLType {
    case titleXL, titleL, titleM, bodyL, body, bodyS, caption
    
    var font: Font {
        switch self {
        case .titleXL:
            return .system(.largeTitle, design: .serif).weight(.bold)
        case .titleL:
            return .system(.title, design: .serif).weight(.bold)
        case .titleM:
            return .system(.title3, design: .serif).weight(.semibold)
        case .bodyL:
            return .system(.title3, design: .rounded)
        case .body:
            return .system(.body, design: .rounded)
        case .bodyS:
            return .system(.callout, design: .rounded)
        case .caption:
            return .system(.caption, design: .rounded).weight(.medium)
        }
    }
}

extension View {
    func dlType(_ style: DLType) -> some View {
        font(style.font)
            .lineSpacing(3)
    }
}
