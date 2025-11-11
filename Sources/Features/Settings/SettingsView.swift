import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = SettingsService.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Motion & Haptics") {
                    Picker("Preference", selection: $settings.motionHaptics) {
                        Text("Follow System").tag(MotionHapticsPreference.followSystem)
                        Text("On").tag(MotionHapticsPreference.on)
                        Text("Off").tag(MotionHapticsPreference.off)
                    }
                    Text(footnote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var footnote: String {
        switch settings.motionHaptics {
        case .followSystem: return "Uses your system's Reduce Motion for vibration cues."
        case .on: return "Always uses subtle haptics."
        case .off: return "Disables haptics."
        }
    }
}

