import Foundation
import AVFoundation
import Speech

@MainActor
final class TranscriptionService: ObservableObject {
    @Published private(set) var isTranscribing = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func transcribe(url: URL) async throws -> String {
        isTranscribing = true
        defer { isTranscribing = false }
        
        // Request authorization if needed
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus == .notDetermined {
            let granted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
            if !granted {
                throw TranscriptionError.authorizationDenied
            }
        } else if authStatus != .authorized {
            throw TranscriptionError.authorizationDenied
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }
        
        // Perform transcription
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = false // Use cloud for better accuracy
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: TranscriptionError.recognitionFailed(error))
                    return
                }
                
                if let result = result, result.isFinal {
                    let transcript = result.bestTranscription.formattedString
                    if transcript.isEmpty {
                        continuation.resume(throwing: TranscriptionError.emptyTranscript)
                    } else {
                        continuation.resume(returning: transcript)
                    }
                }
            }
        }
    }
}

enum TranscriptionError: LocalizedError {
    case authorizationDenied
    case recognizerUnavailable
    case recognitionFailed(Error)
    case emptyTranscript
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Speech recognition permission denied. Enable it in Settings to transcribe voice notes."
        case .recognizerUnavailable:
            return "Speech recognizer is unavailable. Check your network connection and try again."
        case .recognitionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        case .emptyTranscript:
            return "No speech detected in the recording. Try speaking louder or recording in a quieter environment."
        }
    }
}
