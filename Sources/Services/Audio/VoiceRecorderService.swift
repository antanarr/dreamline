import Foundation
import AVFoundation

@MainActor
final class VoiceRecorderService: NSObject, ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case finished(URL)
        case permissionDenied
        case error(String)
    }
    
    private let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 192_000,
        AVNumberOfChannelsKey: 1,
        AVSampleRateKey: 44_100.0
    ]
    
    private var recorder: AVAudioRecorder?
    private var levelTimer: Timer?
    
    @Published var state: State = .idle {
        didSet {
            switch (oldValue, state) {
            case (.recording, .recording):
                break
            case (.recording, _):
                stopMetering()
            case (_, .recording):
                startMetering()
            default:
                break
            }
        }
    }
    
    /// Derived view for convenience; do NOT assign to this directly.
    var isRecording: Bool {
        if case .recording = state { return true }
        return false
    }
    
    @Published private(set) var normalizedPower: Double = 0
    @Published private(set) var elapsed: TimeInterval = 0
    
    func toggleRecording() {
        switch state {
        case .recording:
            stopRecording()
        case .idle, .finished, .permissionDenied, .error:
            Task { await startRecording() }
        }
    }
    
    func startRecording(autoActivate: Bool = true) async {
        do {
            if autoActivate {
                try await beginSession()
            } else {
                let granted = await requestPermission()
                guard granted else {
                    state = .permissionDenied
                    return
                }
            }
            
            let url = makeRecordingURL()
            let audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
            recorder = audioRecorder
            
            elapsed = 0
            normalizedPower = 0
            state = .recording
        } catch {
            if case .permissionDenied = state {
                return
            }
            state = .error(error.localizedDescription)
            endSession()
        }
    }
    
    func stopRecording() {
        guard case .recording = state else { return }
        let url = recorder?.url
        recorder?.stop()
        recorder = nil
        awaitEndSession()
        
        if let url, FileManager.default.fileExists(atPath: url.path) {
            state = .finished(url)
        } else {
            state = .idle
        }
    }
    
    func discardRecording() {
        switch state {
        case .recording:
            recorder?.stop()
            recorder = nil
            awaitEndSession()
        case .finished(let url):
            try? FileManager.default.removeItem(at: url)
        default:
            break
        }
        
        elapsed = 0
        normalizedPower = 0
        state = .idle
    }
    
    private func beginSession() async throws {
        let session = AVAudioSession.sharedInstance()
        let granted = await requestPermission()
        guard granted else {
            state = .permissionDenied
            throw NSError(domain: "MicPermission", code: 1, userInfo: nil)
        }
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }
    
    private func endSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    private func awaitEndSession() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.endSession()
        }
    }
    
    private func startMetering() {
        stopMetering()
        elapsed = 0
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, case .recording = self.state else { return }
                self.recorder?.updateMeters()
                let power = self.recorder?.averagePower(forChannel: 0) ?? -60
                let norm = max(0, min(1, (power + 60) / 60))
                self.normalizedPower = Double(norm)
                self.elapsed += 0.05
            }
        }
        if let levelTimer {
            RunLoop.main.add(levelTimer, forMode: .common)
        }
    }
    
    private func stopMetering() {
        levelTimer?.invalidate()
        levelTimer = nil
        normalizedPower = 0
    }
    
    private func makeRecordingURL() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("DreamlineRecorder", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let filename = UUID().uuidString + ".m4a"
        return directory.appendingPathComponent(filename)
    }
    
    private func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .denied:
                state = .permissionDenied
                return false
            case .granted:
                return true
            case .undetermined:
                let granted = await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                if !granted { state = .permissionDenied }
                return granted
            @unknown default:
                state = .permissionDenied
                return false
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            if session.recordPermission == .denied {
                state = .permissionDenied
                return false
            }
            
            if session.recordPermission == .granted {
                return true
            }
            
            let granted = await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            if !granted { state = .permissionDenied }
            return granted
        }
    }
    
    deinit {
        levelTimer?.invalidate()
        levelTimer = nil
        recorder?.stop()
        recorder = nil
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension VoiceRecorderService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.recorder = nil
            self.awaitEndSession()
            if let error {
                self.state = .error(error.localizedDescription)
            } else {
                self.state = .error("Unknown recording error.")
            }
        }
    }
}

