import Foundation
import AVFoundation

final class VoiceRecorderService: NSObject, ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case finished(URL)
        case permissionDenied
        case error(String)
    }
    
    private let session = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var startDate: Date?
    
    private let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 192_000,
        AVNumberOfChannelsKey: 1,
        AVSampleRateKey: 44_100.0
    ]
    
    @Published var isRecording = false
    @Published var currentTime: TimeInterval = 0
    @Published var state: State = .idle
    @Published var normalizedPower: Double = 0
    
    var elapsed: TimeInterval = 0
    
    func toggleRecording() {
        switch state {
        case .recording:
            stopRecording()
        case .idle, .finished, .permissionDenied, .error:
            Task { await startRecording() }
        }
    }
    
    func startRecording(autoActivate: Bool = true) async {
        guard await requestPermission() else {
            state = .permissionDenied
            return
        }
        
        do {
            if autoActivate {
                try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            }
            
            let url = makeRecordingURL()
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            recorder?.record()
            
            startDate = Date()
            elapsed = 0
            normalizedPower = 0
            state = .recording
            isRecording = true
            currentTime = 0
            startMeterUpdates()
        } catch {
            state = .error(error.localizedDescription)
            isRecording = false
        }
    }
    
    func stopRecording() {
        guard let recorder else { return }
        recorder.stop()
        recorder.updateMeters()
        meterTimer?.invalidate()
        meterTimer = nil
        self.recorder = nil
        sessionCleanup()
        state = .finished(recorder.url)
        isRecording = false
    }
    
    func discardRecording() {
        if case .finished(let url) = state {
            try? FileManager.default.removeItem(at: url)
        }
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        recorder = nil
        sessionCleanup()
        startDate = nil
        elapsed = 0
        currentTime = 0
        normalizedPower = 0
        state = .idle
        isRecording = false
    }
    
    private func startMeterUpdates() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateMeters()
        }
        RunLoop.main.add(meterTimer!, forMode: .common)
    }
    
    private func updateMeters() {
        guard let recorder else { return }
        recorder.updateMeters()
        if let startDate {
            elapsed = Date().timeIntervalSince(startDate)
        }
        let power = recorder.averagePower(forChannel: 0)
        let minDb: Float = -80
        let clamped = max(minDb, power)
        let range = minDb * -1
        let normalized = (clamped + range) / range
        normalizedPower = Double(normalized)
        currentTime = elapsed
    }
    
    private func sessionCleanup() {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
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
                return false
            case .granted:
                return true
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        } else {
            if session.recordPermission == .denied {
                return false
            }
            
            if session.recordPermission == .granted {
                return true
            }
            
            return await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}

extension VoiceRecorderService: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        meterTimer?.invalidate()
        meterTimer = nil
        self.recorder = nil
        sessionCleanup()
        if let error {
            state = .error(error.localizedDescription)
        } else {
            state = .error("Unknown recording error.")
        }
    }
}

