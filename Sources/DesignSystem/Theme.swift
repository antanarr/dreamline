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
        
        // Gradients + overlays
        let screenBackgroundGradient: [Color]
        let heroCardGradient: [Color]
        let starOpacity: Double
        let noiseOpacity: Double
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
                textPrimary: UIColor(Color(hex: 0xF5F7FF)),
                tabBackground: UIColor(.dlSpace),
                tabSelected: UIColor(accent),
                tabUnselected: UIColor(accent.opacity(0.6)),
                cardFillPrimary: Color.white.opacity(0.08),
                cardFillSecondary: Color.white.opacity(0.05),
                cardStroke: Color.white.opacity(0.12),
                capsuleFill: Color.white.opacity(0.1),
                separator: Color.white.opacity(0.14),
                screenBackgroundGradient: [
                    Color(hex: 0x0E1224),
                    Color(hex: 0x121836, alpha: 0.94),
                    Color(hex: 0x4C4FD6, alpha: 0.18)
                ],
                heroCardGradient: [
                    Color(hex: 0x161932),
                    Color(hex: 0x1E2254)
                ],
                starOpacity: 0.10,
                noiseOpacity: 0.06
            )
        case .light:
            return Palette(
                accent: UIColor(accent),
                background: UIColor(.white),
                textPrimary: UIColor(Color(hex: 0x0A0D18)),
                tabBackground: UIColor(.white),
                tabSelected: UIColor(accent),
                tabUnselected: UIColor(accent.opacity(0.6)),
                cardFillPrimary: Color.white.opacity(0.9),
                cardFillSecondary: Color.white.opacity(0.75),
                cardStroke: Color.black.opacity(0.08),
                capsuleFill: Color.gray.opacity(0.18),
                separator: Color.black.opacity(0.09),
                screenBackgroundGradient: [
                    Color(hex: 0xF7F4FF),
                    Color(hex: 0xECEBFF)
                ],
                heroCardGradient: [
                    Color(hex: 0xF7F4FF, alpha: 0.95),
                    Color(hex: 0xECEBFF, alpha: 0.90)
                ],
                starOpacity: 0.06,
                noiseOpacity: 0.04
            )
        @unknown default:
            return Palette(
                accent: UIColor(accent),
                background: UIColor(.dlSpace),
                textPrimary: UIColor(Color(hex: 0xF5F7FF)),
                tabBackground: UIColor(.dlSpace),
                tabSelected: UIColor(accent),
                tabUnselected: UIColor(accent.opacity(0.6)),
                cardFillPrimary: Color.white.opacity(0.08),
                cardFillSecondary: Color.white.opacity(0.05),
                cardStroke: Color.white.opacity(0.12),
                capsuleFill: Color.white.opacity(0.1),
                separator: Color.white.opacity(0.14),
                screenBackgroundGradient: [
                    Color(hex: 0x0E1224),
                    Color(hex: 0x121836, alpha: 0.94),
                    Color(hex: 0x4C4FD6, alpha: 0.18)
                ],
                heroCardGradient: [
                    Color(hex: 0x161932),
                    Color(hex: 0x1E2254)
                ],
                starOpacity: 0.10,
                noiseOpacity: 0.06
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

extension ThemeService.Palette {
    var horoscopeCardBackground: [Color] {
        heroCardGradient
    }
}
