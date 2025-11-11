import Foundation
import SwiftUI

public enum MotionHapticsPreference: String, CaseIterable, Identifiable {
    case followSystem, on, off
    public var id: String { rawValue }
}

@MainActor
public final class SettingsService: ObservableObject {
    public static let shared = SettingsService()
    @AppStorage("motionHapticsPreference") public var motionHaptics: MotionHapticsPreference = .followSystem

    public func shouldHaptic(reduceMotion: Bool) -> Bool {
        switch motionHaptics {
        case .on: return true
        case .off: return false
        case .followSystem: return !reduceMotion
        }
    }
}

