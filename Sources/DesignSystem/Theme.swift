import SwiftUI
import UIKit
import Observation

@Observable
final class ThemeService {
    enum Mode: String, CaseIterable, Identifiable {
        case system, light, dark
        
        var id: String { rawValue }
        
        static var auto: Mode { .system }
        
        var displayName: String {
            switch self {
            case .system: return "Auto"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        
        var preferredColorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    var mode: Mode = .system

    struct Palette {
        var accent: UIColor
        var background: UIColor
        var textPrimary: UIColor
        var tabBackground: UIColor
        var tabSelected: UIColor
        var tabUnselected: UIColor
        
        // Additional properties for cards and UI elements
        let cardFillPrimary: Color
        let cardFillSecondary: Color
        let cardStroke: Color
        let capsuleFill: Color
        let separator: Color
    }

    var accent: Color = .dlIndigo
    var background: Color = .dlSpace
    var textPrimary: Color = .dlMoon

    var palette: Palette {
        switch effectiveColorScheme {
        case .dark:
            return Palette(
                accent: UIColor(accent),
                background: UIColor(.dlSpace),
                textPrimary: UIColor(.dlMoon),
                tabBackground: UIColor(.dlSpace),
                tabSelected: UIColor(accent),
                tabUnselected: UIColor(accent.opacity(0.6)),
                cardFillPrimary: Color.white.opacity(0.08),
                cardFillSecondary: Color.white.opacity(0.05),
                cardStroke: Color.white.opacity(0.1),
                capsuleFill: Color.white.opacity(0.1),
                separator: Color.white.opacity(0.15)
            )
        case .light:
            return Palette(
                accent: UIColor(accent),
                background: UIColor(.white),
                textPrimary: UIColor(Color.black.opacity(0.9)),
                tabBackground: UIColor(.white),
                tabSelected: UIColor(accent),
                tabUnselected: UIColor(accent.opacity(0.6)),
                cardFillPrimary: Color.white.opacity(0.9),
                cardFillSecondary: Color.white.opacity(0.7),
                cardStroke: Color.black.opacity(0.1),
                capsuleFill: Color.gray.opacity(0.2),
                separator: Color.gray.opacity(0.3)
            )
        @unknown default:
            return Palette(
                accent: UIColor(accent),
                background: UIColor(.dlSpace),
                textPrimary: UIColor(.dlMoon),
                tabBackground: UIColor(.dlSpace),
                tabSelected: UIColor(accent),
                tabUnselected: UIColor(accent.opacity(0.6)),
                cardFillPrimary: Color.white.opacity(0.08),
                cardFillSecondary: Color.white.opacity(0.05),
                cardStroke: Color.white.opacity(0.1),
                capsuleFill: Color.white.opacity(0.1),
                separator: Color.white.opacity(0.15)
            )
        }
    }

    var colorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var effectiveColorScheme: ColorScheme {
        switch mode {
        case .system: return .dark
        case .light: return .light
        case .dark: return .dark
        }
    }

    // Expose convenience flags so views don't need to know about custom modes
    var isLight: Bool { effectiveColorScheme == .light }
    var isDark: Bool { effectiveColorScheme == .dark }
}
