import AppIntents
import Foundation

struct RecordDreamIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Dream"
    static var description = IntentDescription("Open Dreamline and start voice capture for a new dream entry.")
    static var openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        let url = URL(string: "dreamline://record-dream")!
        return .result(value: url)
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Start recording a dream")
    }
    
    static var shortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: RecordDreamIntent(),
                phrases: [
                    "Record a dream in Dreamline",
                    "Start capturing a dream in Dreamline"
                ],
                shortTitle: "Record Dream",
                systemImageName: "waveform.circle"
            )
        ]
    }
}

