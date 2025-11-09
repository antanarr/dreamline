import Foundation

extension Notification.Name {
    static let dlStartVoiceCapture = Notification.Name("dlStartVoiceCapture")
}

enum QuickCapture {
    static func triggerVoiceCapture() {
        NotificationCenter.default.post(name: .dlStartVoiceCapture, object: nil)
    }
}

