import SwiftUI

struct DreamDetailView: View {
    @Binding var entry: DreamEntry
    @Environment(EntitlementsService.self) private var entitlements
    @ObservedObject var rc = RemoteConfigService.shared
    @State private var showPaywall = false
    @State private var deepReadMessage: String? = nil
    @State private var generatedPDFURL: URL? = nil
    @State private var hasShownInterpretation = false
    @State private var isInterpreting: Bool = false
    @State private var draft: String = ""
    @FocusState private var isJournalFocused: Bool
    private let oracle = OracleService()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                editorSection
                interpretationSection
                deepReadSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.dlSpace,
                    Color.dlSpace.opacity(0.9),
                    Color.dlIndigo.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Dream")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isJournalFocused = false }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            draft = entry.rawText
        }
        .onChange(of: draft) { _, newValue in
            entry.rawText = newValue
        }
    }
    
    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.dlLilac)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dream notes")
                        .font(DLFont.title(22))
                        .foregroundStyle(.primary)
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                }
            }
            
            TextEditor(text: $draft)
                .font(DLFont.body(16))
                .frame(minHeight: 180)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
                .textInputAutocapitalization(.sentences)
                .focused($isJournalFocused)
        }
        .padding(24)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color.dlSpace.opacity(0.95),
                        Color.dlSpace.opacity(0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image("pattern_stargrid_tile")
                    .resizable(resizingMode: .tile)
                    .opacity(0.16)
                    .blendMode(.screen)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08))
        )
    }
    
    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dlLilac)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Oracle insight")
                        .font(DLFont.title(20))
                        .foregroundStyle(.primary)
                    Text("Fold this dream into your ongoing motifs and today’s sky.")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                }
            }
            
            interpretationContent
            
            InterpretButtonGate(tier: entitlements.tier) {
                guard !isInterpreting else { return }
                isInterpreting = true
                Task { await interpretCurrentEntry() }
            }
            .disabled(isInterpreting)
            .overlay(alignment: .center) {
                if isInterpreting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.dlLilac)
                }
            }
        }
        .padding(24)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color.dlSpace.opacity(0.95),
                        Color.dlIndigo.opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottomTrailing
                )
                Image("pattern_gradientnoise_tile")
                    .resizable(resizingMode: .tile)
                    .opacity(0.2)
                    .blendMode(.plusLighter)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08))
        )
    }
    
    @ViewBuilder
    private var interpretationContent: some View {
        if isInterpreting {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .frame(height: 16)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 16)
                    .frame(maxWidth: 220, alignment: .leading)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 16)
                    .frame(maxWidth: 180, alignment: .leading)
            }
            .shimmer()
        } else if let summary = entry.oracleSummary {
            VStack(alignment: .leading, spacing: 14) {
                Text(summary)
                    .font(DLFont.body(15))
                    .foregroundStyle(.primary)
                    .onAppear(perform: scheduleUpsellIfNeeded)
                
                if !entry.extractedSymbols.isEmpty {
                    TagList(title: "Symbols", items: entry.extractedSymbols)
                }
                
                if !entry.themes.isEmpty {
                    TagList(title: "Themes", items: entry.themes)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("No interpretation yet.")
                    .font(DLFont.body(14))
                    .foregroundStyle(.secondary)
                Text("Tap Interpret to weave your dream with recent motifs and transits.")
                    .font(DLFont.body(13))
                    .foregroundStyle(.secondary.opacity(0.85))
            }
        }
    }
    
    private var deepReadSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.dlMint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deep Read")
                        .font(DLFont.title(20))
                        .foregroundStyle(.primary)
                    Text("Generate a detailed PDF to annotate or share.")
                        .font(DLFont.body(12))
                        .foregroundStyle(.secondary)
                }
            }
            
            if entitlements.tier != .free {
                Button {
                    if let url = DeepReadGenerator.generate(for: entry) {
                        generatedPDFURL = url
                        deepReadMessage = "Deep Read generated."
                    }
                } label: {
                    Label("Generate Deep Read", systemImage: "sparkles.rectangle.stack")
                        .font(DLFont.body(15))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        showPaywall = true
                    } label: {
                        Label("Unlock Deep Reads", systemImage: "lock.fill")
                            .font(DLFont.body(15))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        deepReadMessage = nil
                        Task {
                            let success = await entitlements.buyDeepRead()
                            await MainActor.run {
                                if success {
                                    deepReadMessage = "Deep Read purchased! Generate your first report below."
                                    if let url = DeepReadGenerator.generate(for: entry) {
                                        generatedPDFURL = url
                                    }
                                } else {
                                    deepReadMessage = "Purchase cancelled or failed."
                                }
                            }
                        }
                    } label: {
                        Label("Buy one-off Deep Read ($4.99)", systemImage: "cart.fill")
                            .font(DLFont.body(14))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if let msg = deepReadMessage {
                Text(msg)
                    .font(DLFont.body(12))
                    .foregroundStyle(.secondary)
            }
            
            if let pdfURL = generatedPDFURL {
                ShareLink(item: pdfURL) {
                    Label("Share latest PDF", systemImage: "square.and.arrow.up")
                        .font(DLFont.body(14))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
        )
    }
    
    private func scheduleUpsellIfNeeded() {
        guard !hasShownInterpretation else { return }
        hasShownInterpretation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(rc.config.upsellDelaySeconds)) {
            if entitlements.tier == .free {
                showPaywall = true
            }
        }
    }
    
    private func interpretCurrentEntry() async {
        let client: OracleClient = {
            let baseURL = (Bundle.main.object(forInfoDictionaryKey: "FunctionsBaseURL") as? String) ?? ""
            return baseURL.isEmpty ? StubOracleClient() : CloudOracleClient()
        }()
        
        let coordinator = InterpretCoordinator(oracle: client)
        if let interpretation = await coordinator.runInterpret(dreamText: entry.rawText) {
            await MainActor.run {
                entry.oracleSummary = interpretation.shortSummary
                entry.extractedSymbols = interpretation.symbolCards.map { $0.name }
                entry.themes = [] // TODO: derive from interpretation
                isInterpreting = false
                hasShownInterpretation = false
            }
        } else {
            let fallback = oracle.interpret(text: entry.rawText)
            await MainActor.run {
                entry.oracleSummary = fallback.summary
                entry.extractedSymbols = fallback.symbols
                entry.themes = fallback.themes
                isInterpreting = false
                hasShownInterpretation = false
            }
        }
    }
}

private struct TagList: View {
    let title: String
    let items: [String]
    
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
                        .background(Color.white.opacity(0.08), in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
