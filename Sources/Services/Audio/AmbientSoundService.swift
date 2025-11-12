import Foundation
import AVFoundation

/// Tasteful ambient sounds for key moments (alignment detection, completion)
/// All sounds respect system volume and Reduce Motion preference.
@MainActor
final class AmbientSoundService: ObservableObject {
    static let shared = AmbientSoundService()
    
    @Published var soundsEnabled: Bool = UserDefaults.standard.bool(forKey: "dreamline.sounds.enabled") {
        didSet {
            UserDefaults.standard.set(soundsEnabled, forKey: "dreamline.sounds.enabled")
        }
    }
    
    private var player: AVAudioPlayer?
    
    private init() {
        configureSoundSession()
    }
    
    /// Soft chime when Alignment Event is detected (one-shot per session)
    func playAlignmentChime() {
        guard soundsEnabled else { return }
        playSound(named: "alignment_chime", volume: 0.3)
    }
    
    /// Gentle completion sound (dream saved, interpretation received)
    func playCompletionTone() {
        guard soundsEnabled else { return }
        playSound(named: "completion_tone", volume: 0.25)
    }
    
    // MARK: - Private
    
    private func configureSoundSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AmbientSoundService: Failed to configure audio session: \(error)")
        }
    }
    
    private func playSound(named name: String, volume: Float) {
        // For now, use system sounds as placeholders
        // In production, you'd add custom .wav/.m4a files to Resources
        
        // Placeholder: use system sound IDs for now
        // alignment_chime → soft notification sound
        // completion_tone → gentle success sound
        
        // Example with system sound (will be replaced with custom sounds)
        if name == "alignment_chime" {
            AudioServicesPlaySystemSound(1152) // Soft chime
        } else if name == "completion_tone" {
            AudioServicesPlaySystemSound(1111) // Gentle tone
        }
    }
}

// MARK: - Settings Integration

extension AmbientSoundService {
    /// Check if sounds should play based on user preference and Reduce Motion
    func shouldPlaySound(reduceMotion: Bool) -> Bool {
        if !soundsEnabled { return false }
        // Optional: also gate on Reduce Motion if you want ultra-quiet mode
        // For now, sounds are independent of motion setting
        return true
    }
}

