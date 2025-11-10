import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct JournalView: View {
    @Environment(DreamStore.self) private var store
    @Environment(EntitlementsService.self) private var entitlements
    @State private var isComposing = false
    @State private var interpretingEntryID: String?
    @State private var startRecordingOnCompose = false
    private let oracle = OracleService()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        
                        if store.entries.isEmpty {
                            JournalEmptyState()
                        } else {
                            LazyVStack(spacing: 20, pinnedViews: []) {
                                ForEach(Array(store.entries.enumerated()), id: \.element.id) { index, entry in
                                    let binding = Binding(
                                        get: { store.entries[index] },
                                        set: { store.entries[index] = $0 }
                                    )
                                    
                                    NavigationLink {
                                        DreamDetailView(entry: binding)
                                    } label: {
                                        JournalEntryCard(
                                            entry: binding.wrappedValue,
                                            isInterpreting: interpretingEntryID == entry.id,
                                            onInterpret: {
                                                interpret(entryAt: index)
                                            },
                                            tier: entitlements.tier
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 120)
                }
                
                addButton
            }
            .dreamlineScreenBackground()
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isComposing, onDismiss: {
                startRecordingOnCompose = false
            }) {
                ComposeDreamView(store: store, startRecordingOnAppear: startRecordingOnCompose)
            }
            .onReceive(NotificationCenter.default.publisher(for: .dlStartVoiceCapture)) { _ in
                startRecordingOnCompose = true
                isComposing = true
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dream Journal")
                .font(DLFont.title(30))
                .foregroundStyle(.primary)
            
            Text("Capture every dream, track your motifs, and tap for deeper readings.")
                .font(DLFont.body(14))
                .foregroundStyle(.secondary)
        }
    }
    
    private var recordBanner: some View {
        Button {
            startRecordingOnCompose = true
            isComposing = true
        } label: {
            HStack(alignment: .center, spacing: 18) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 6)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick capture")
                        .font(DLFont.body(12))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Text("Record a dream")
                        .font(DLFont.title(24))
                        .foregroundStyle(Color.white)
                    Text("Start a voice note instantly; we’ll transcribe and merge it with your entry.")
                        .font(DLFont.body(12))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.dlIndigo, Color.dlViolet],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.18))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var addButton: some View {
        Button {
            Feedback.impact(.light)
            isComposing = true
        } label: {
            Label("New Dream", systemImage: "plus")
                .font(DLFont.body(15))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.dlIndigo, Color.dlViolet],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .foregroundStyle(Color.white)
                .shadow(color: Color.dlViolet.opacity(0.4), radius: 16, x: 0, y: 12)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 28)
        .buttonStyle(.plain)
        .accessibilityIdentifier("ComposeDreamButton")
    }
    
    private func interpret(entryAt index: Int) {
        guard store.entries.indices.contains(index) else { return }
        let entryID = store.entries[index].id
        interpretingEntryID = entryID
        
        Task {
            let client: OracleClient = {
                let baseURL = (Bundle.main.object(forInfoDictionaryKey: "FunctionsBaseURL") as? String) ?? ""
                return baseURL.isEmpty ? StubOracleClient() : CloudOracleClient()
            }()
            
            let coordinator = InterpretCoordinator(oracle: client)
            if let result = await coordinator.runInterpret(dreamText: store.entries[index].rawText) {
                await MainActor.run {
                    store.entries[index].interpretation = result.interpretation
                    store.entries[index].oracleSummary = result.interpretation.summary
                    store.entries[index].extractedSymbols = result.extraction.symbols.map { $0.name }
                    store.entries[index].themes = result.extraction.archetypes
                    interpretingEntryID = nil
                    Feedback.success()
                }
            } else {
                let fallback = oracle.interpret(text: store.entries[index].rawText)
                await MainActor.run {
                    store.entries[index].interpretation = fallback
                    store.entries[index].oracleSummary = fallback.summary
                    interpretingEntryID = nil
                    Feedback.success()
                }
            }
        }
    }
}

private struct JournalEntryCard: View {
    let entry: DreamEntry
    let isInterpreting: Bool
    let onInterpret: () -> Void
    let tier: Tier
    @Environment(ThemeService.self) private var theme: ThemeService
    
    private var headlineSymbols: [String] {
        let preferred = entry.extractedSymbols.isEmpty ? entry.themes : entry.extractedSymbols
        return Array(preferred.prefix(4))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(DLFont.body(12))
                    .foregroundStyle(.secondary)
                
                if entry.oracleSummary != nil {
                    Label("Interpreted", systemImage: "sparkles")
                        .font(DLFont.body(11))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.dlLilac.opacity(0.18), in: Capsule())
                        .foregroundStyle(Color.dlLilac)
                }
                
                Spacer()
            }
            
            Text(entry.rawText.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(DLFont.body(15))
                .foregroundStyle(.primary)
                .lineLimit(4)
            
            if let summary = entry.oracleSummary {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Oracle summary")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                    
                    Text(summary)
                        .font(DLFont.body(14))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
            }
            
            if !headlineSymbols.isEmpty {
                HStack(spacing: 8) {
                    ForEach(headlineSymbols, id: \.self) { symbol in
                        Text(symbol.capitalized)
                            .font(DLFont.body(11))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Divider().overlay(Color.white.opacity(0.06))
            
            HStack {
                InterpretButtonGate(tier: tier) {
                    if !isInterpreting {
                        onInterpret()
                    }
                }
                .disabled(isInterpreting)
                .overlay {
                    if isInterpreting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.dlLilac)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .background(cardBackground)
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 12)
    }
    
    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(theme.palette.cardFillPrimary)
            
            Image("pattern_stargrid_tile")
                .resizable(resizingMode: .tile)
                .opacity(theme.isLight ? 0.06 : 0.18)
                .blendMode(.screen)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            
            Image("pattern_gradientnoise_tile")
                .resizable(resizingMode: .tile)
                .opacity(theme.isLight ? 0.05 : 0.12)
                .blendMode(.plusLighter)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }
}

private struct JournalEmptyState: View {
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(spacing: 18) {
            DLAssetImage.emptyJournal
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .opacity(0.95)
            
            Text("Begin your dream archive")
                .dlType(.titleM)
                .multilineTextAlignment(.center)
                .fontWeight(.semibold)
            
            Text("Capture a few lines when you wake. Dreamline will learn your symbols and surface patterns over time.")
                .dlType(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }
}

struct ComposeDreamView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeService.self) private var theme: ThemeService
    @StateObject private var recorder = VoiceRecorderService()
    @State private var draft: String = ""
    @State private var audioURL: URL? = nil
    @StateObject private var transcriber = TranscriptionService()
    @State private var showValidation = false
    @FocusState private var editorFocused: Bool
    @State private var isTranscribingAudio = false
    @State private var transcriptionError: String?
    @State private var lastTranscription: String?
    @State private var savedEntry: DreamEntry?
    @State private var showQuickRead = false

    let store: DreamStore
    @State private var shouldAutoStartRecording: Bool

    init(store: DreamStore, startRecordingOnAppear: Bool = false) {
        self.store = store
        _shouldAutoStartRecording = State(initialValue: startRecordingOnAppear)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.clear
                    .dreamlineScreenBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        composeHeader
                        editorCard
                        // Audio capture is intentionally hidden to unify entry UX;
                        // users can use the keyboard microphone to dictate.
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 32)
                    .padding(.bottom, 140)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                
                footer
            }
            .navigationTitle("New Dream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        Feedback.impact(.light)
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        editorFocused = false
                    }
                }
            }
            .onAppear {
                if draft.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        editorFocused = true
                    }
                }
                // Do not auto-start recording; keyboard mic is sufficient for speech input.
                shouldAutoStartRecording = false
            }
            .onDisappear {
                if case .recording = recorder.state {
                    recorder.discardRecording()
                }
            }
            .onChange(of: recorder.state) { _, newState in
                switch newState {
                case .finished(let url):
                    audioURL = url
                    Task { await transcribeRecording(at: url) }
                case .idle:
                    audioURL = nil
                default:
                    break
                }
            }
            .sheet(isPresented: $showQuickRead) {
                if let entry = savedEntry {
                    QuickReadView(entry: entry)
                }
            }
        }
    }
    
    private var composeHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Record what you remember")
                .font(DLFont.title(26))
                .foregroundStyle(.primary)
            Text("Write freely—emotion, setting, fragments. The Oracle can weave it later.")
                .font(DLFont.body(14))
                .foregroundStyle(.secondary)
        }
    }
    
    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dlLilac)
                Text("Dream entry")
                    .font(DLFont.title(20))
                    .foregroundStyle(.primary)
            }
            
            ZStack(alignment: .topLeading) {
                if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Type every detail you recall—dialogue, sensation, unusual symbols.")
                        .font(DLFont.body(15))
                        .foregroundStyle(placeholderColor)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $draft)
                    .font(DLFont.body(16))
                    .padding(16)
                    .frame(minHeight: 220)
                    .background(Color.clear)
                    .focused($editorFocused)
            }
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.palette.cardFillSecondary)
            )
        }
        .padding(24)
        .background(cardBackground(cornerRadius: 28, level: .primary))
    }
    
    private var recordButton: some View {
        Button {
            recorder.toggleRecording()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: recorder.state == .recording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text(recorder.state == .recording ? "Stop recording" : "Record voice note")
                    .font(DLFont.body(14))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(
                LinearGradient(
                    colors: recorder.state == .recording ? [Color.dlViolet, Color.dlIndigo] : [Color.dlIndigo, Color.dlViolet],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .foregroundStyle(Color.white)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var recorderStateView: some View {
        switch recorder.state {
        case .idle:
            Text("Tap record to capture what you remember without typing. You can still add or edit the text afterwards.")
                .font(DLFont.body(12))
                .foregroundStyle(.secondary)
        case .recording:
            VStack(alignment: .leading, spacing: 12) {
                waveformView(level: recorder.normalizedPower)
                Text("Recording… \(formattedElapsed(recorder.elapsed))")
                    .font(DLFont.body(12))
                    .foregroundStyle(.secondary)
            }
            .animation(.easeOut(duration: 0.1), value: recorder.normalizedPower)
        case .finished:
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dlMint)
                    Text("Captured \(formattedElapsed(recorder.elapsed)).")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                }
                
                if isTranscribingAudio {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Transcribing…")
                            .font(DLFont.body(12))
                            .foregroundStyle(.secondary)
                    }
                } else if let lastTranscription {
                    Text("Transcript added: “\(lastTranscription)”")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 12) {
                    Button {
                        removeLastTranscription()
                        recorder.discardRecording()
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }
        case .permissionDenied:
            Text("Microphone access is disabled. Enable it in Settings to capture voice notes.")
                .font(DLFont.body(12))
                .foregroundStyle(Color.dlAmber)
        case .error(let message):
            Text("Recorder error: \(message)")
                .font(DLFont.body(12))
                .foregroundStyle(Color.dlAmber)
        }
    }
    
    private func waveformView(level: Double) -> some View {
        GeometryReader { proxy in
            let maxHeight = proxy.size.height
            let height = max(12, maxHeight * level)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.dlLilac.opacity(0.55))
                .frame(width: proxy.size.width, height: height)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 64)
    }
    
    private func formattedElapsed(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: interval) ?? "0:00"
    }
    
    @MainActor
    private func transcribeRecording(at url: URL) async {
        isTranscribingAudio = true
        transcriptionError = nil
        do {
            let transcript = try await transcriber.transcribe(url: url)
            if draft.isEmpty {
                draft = transcript
            } else {
                let separator = draft.hasSuffix("\n") ? "" : "\n"
                draft.append("\(separator)\(transcript)")
            }
            lastTranscription = transcript
            Feedback.success()
        } catch {
            transcriptionError = error.localizedDescription
            Feedback.warning()
        }
        isTranscribingAudio = false
    }
    
    private func removeLastTranscription() {
        guard let last = lastTranscription else { return }
        if draft == last {
            draft = ""
        } else if draft.hasSuffix("\n\(last)") {
            draft.removeLast(last.count + 1)
        } else if draft.hasSuffix(last) {
            draft.removeLast(last.count)
        }
        lastTranscription = nil
    }
    
    private var audioCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.dlMint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audio memory (optional)")
                        .font(DLFont.title(18))
                        .foregroundStyle(.primary)
                    Text("Capture a voice note; Dreamline will transcribe and merge it into your entry.")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                recordButton
                
                recorderStateView
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.palette.cardFillSecondary)
            )
            
            if let transcriptionError {
                Text(transcriptionError)
                    .font(DLFont.body(12))
                    .foregroundStyle(Color.dlAmber)
            }
        }
        .padding(24)
        .background(cardBackground(cornerRadius: 28, level: .secondary))
    }
    
    private var footer: some View {
        VStack(spacing: 12) {
            if showValidation {
                Text("Add at least a line before you save.")
                    .font(DLFont.body(12))
                    .foregroundStyle(Color.dlAmber)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            Button {
                Feedback.impact(.medium)
                Task { await saveDreamWithInterpretation() }
            } label: {
                Text("Get Interpretation")
                    .font(DLFont.body(16))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.dlIndigo, Color.dlViolet],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.dlViolet.opacity(0.38), radius: 18, x: 0, y: 12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            footerBackground
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private enum CardLevel {
        case primary
        case secondary
    }
    
    @ViewBuilder
    private func cardBackground(cornerRadius: CGFloat, level: CardLevel) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        switch level {
        case .primary:
            shape
                .fill(theme.palette.cardFillPrimary)
                .overlay(
                    Image("pattern_stargrid_tile")
                        .resizable(resizingMode: .tile)
                        .opacity(theme.isLight ? 0.05 : 0.16)
                        .blendMode(.screen)
                        .clipShape(shape)
                )
                .overlay(
                    Image("pattern_gradientnoise_tile")
                        .resizable(resizingMode: .tile)
                        .opacity(theme.isLight ? 0.04 : 0.1)
                        .blendMode(.plusLighter)
                        .clipShape(shape)
                )
        case .secondary:
            shape
                .fill(theme.palette.cardFillSecondary)
        }
    }
    
    private var footerBackground: Color {
        Color(theme.palette.background).opacity(theme.isLight ? 0.92 : 0.9)
    }
    
    private var placeholderColor: Color {
        theme.palette.separator.opacity(theme.isLight ? 0.6 : 0.4)
    }
    
    private func saveDreamWithInterpretation() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            Feedback.error()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                showValidation = true
            }
            return
        }
        
        // Optional audio handling (kept for future) — not surfaced in UI now
        let storedURL = audioURL.flatMap(persistRecording)
        
        // Interpret using cloud client when configured, otherwise stub
        let client: OracleClient = {
            let baseURL = (Bundle.main.object(forInfoDictionaryKey: "FunctionsBaseURL") as? String) ?? ""
            return baseURL.isEmpty ? StubOracleClient() : CloudOracleClient()
        }()
        let coordinator = InterpretCoordinator(oracle: client)
        let interpreted = await coordinator.runInterpret(dreamText: trimmed)
        
        // Create and save entry with interpretation when available
        var entry = DreamEntry(rawText: trimmed, transcriptURL: storedURL)
        if let result = interpreted {
            entry.extractedSymbols = result.extraction.symbols.map { $0.name }
            entry.themes = result.extraction.archetypes
            entry.interpretation = result.interpretation
            entry.oracleSummary = result.interpretation.summary
        } else {
            entry.extractedSymbols = extractQuickMotifs(from: trimmed)
            let fallbackInterpretation = OracleService().interpret(text: trimmed)
            entry.interpretation = fallbackInterpretation
            entry.oracleSummary = fallbackInterpretation.summary
        }
        
        store.entries.insert(entry, at: 0)
        Feedback.success()
        
        // Present Quick Read (uses summary/symbols if present)
        savedEntry = entry
        showQuickRead = true
        
        // Dismiss compose view (Quick Read appears modally)
        dismiss()
    }
    
    private func extractQuickMotifs(from text: String) -> [String] {
        // Simple keyword extraction for Quick Read
        let words = text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 4 }
            .filter { !commonWords.contains($0) }
        
        return Array(Set(words)).prefix(3).map { $0.capitalized }
    }
    
    private let commonWords: Set<String> = [
        "about", "after", "again", "before", "being", "could", "did", "does",
        "doing", "down", "during", "each", "from", "have", "having", "into",
        "more", "most", "other", "should", "such", "than", "that", "their",
        "them", "then", "there", "these", "they", "this", "through", "under",
        "very", "what", "when", "where", "which", "while", "will", "with",
        "would", "your", "dream", "dreamed", "dreaming", "dreams", "remember",
        "remembered", "felt", "feel", "feeling", "think", "thought", "seemed"
    ]
    
    private func persistRecording(_ url: URL) -> URL {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let recordingsDir = documents.appendingPathComponent("DreamRecordings", isDirectory: true)
        if !fileManager.fileExists(atPath: recordingsDir.path) {
            try? fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        }
        let destination = recordingsDir.appendingPathComponent(url.lastPathComponent)
        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }
        do {
            try fileManager.moveItem(at: url, to: destination)
            return destination
        } catch {
            return url
        }
    }
}

private struct TagList: View {
    let title: String
    let items: [String]
    @Environment(ThemeService.self) private var theme: ThemeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DLFont.body(12))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(Array(items.prefix(6)), id: \.self) { item in
                    Text(item.capitalized)
                        .font(DLFont.body(11))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.palette.capsuleFill, in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#if canImport(UIKit)
private enum Feedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
#else
private enum Feedback {
    static func impact(_ style: Int = 0) {}
    static func success() {}
    static func warning() {}
    static func error() {}
}
#endif
