import SwiftUI
import UIKit
import Observation

@Observable
final class ThemeService {
    enum Mode: String, CaseIterable { case system, light, dark }

    var mode: Mode = .system

    struct Palette {
        var accent: UIColor
        var background: UIColor
        var textPrimary: UIColor
        var tabBackground: UIColor
        var tabSelected: UIColor
        var tabUnselected: UIColor
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
                tabUnselected: UIColor(accent.opacity(0.6))
            )
        case .light:
            return Palette(
                accent: UIColor(accent),
                background: UIColor(.white),
                textPrimary: UIColor(Color.black.opacity(0.9)),
                tabBackground: UIColor(.white),
                tabSelected: UIColor(accent),
                tabUnselected: UIColor(accent.opacity(0.6))
            )
        @unknown default:
            return Palette(
                accent: UIColor(accent),
                background: UIColor(.dlSpace),
                textPrimary: UIColor(.dlMoon),
                tabBackground: UIColor(.dlSpace),
                tabSelected: UIColor(accent),
                tabUnselected: UIColor(accent.opacity(0.6))
            )
        }
    }

    var colorScheme: ColorScheme? {
        switch mode { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }

    private var effectiveColorScheme: ColorScheme {
        switch mode { case .system: return .dark; case .light: return .light; case .dark: return .dark }
    }
}
