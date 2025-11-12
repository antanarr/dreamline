import SwiftUI

/// Poetic, lightweight interpretation peek from the Alignment pill.
/// Shows overlap symbols and a subtle score hint; avoids "AI mechanics".
struct QuickReadInterpretationView: View {
    @Binding var entry: DreamEntry
    let resonance: ResonanceBundle?
    let overlapSymbols: [String]
    let score: Float
    let onOpenDream: () -> Void
    var onDeeperReading: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementsService.self) private var entitlements
    @State private var h1: String = "Your dream speaks"
    @State private var sub: String = "Let the pattern name itself."

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(h1)
                .font(DLFont.body(17).weight(.semibold))

            Text(sub)
                .font(DLFont.body(14))
                .foregroundStyle(.secondary)

            if !overlapSymbols.isEmpty {
                HStack(spacing: 8) {
                    ForEach(overlapSymbols.prefix(ResonanceConfig.OVERLAP_MAX_VISUAL), id: \.self) { sym in
                        Text(sym.replacingOccurrences(of: "_", with: " "))
                            .font(DLFont.body(12).weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.dlMint.opacity(0.12), in: Capsule())
                            .accessibilityLabel("Symbol \(sym)")
                    }
                }
            }

            Text("There's a strong echo here.")
                .font(DLFont.body(13))
                .foregroundStyle(.secondary)
                .opacity(score >= 0.82 ? 1.0 : (score >= 0.78 ? 0.9 : 0.7))
            
            // Extended Oracle explanation (if available)
            if FeatureFlags.oracleExplanationsEnabled, let ex = resonance?.explanation {
                VStack(alignment: .leading, spacing: 12) {
                    Text(ex.lead)
                        .font(DLFont.body(15).weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let bodyText = ex.body, !bodyText.isEmpty {
                        Text(bodyText)
                            .font(DLFont.body(14))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if let onDeeper = onDeeperReading {
                        Button {
                            onDeeper()
                        } label: {
                            Text(entitlements.tier == .pro ? "Deeper reading" : "Deeper reading · Pro")
                                .font(.footnote.weight(.semibold))
                                .underline()
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Oracle guidance")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("From your dream")
                    .font(DLFont.body(13).weight(.semibold))
                Text(snippet(entry.rawText))
                    .font(DLFont.body(13))
                    .foregroundStyle(.primary)
                    .lineLimit(5)
            }

            HStack {
                Spacer()
                Button {
                    dismiss()
                    onOpenDream()
                } label: {
                    Label("Open Dream", systemImage: "book")
                        .font(.body.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.dlMint.opacity(0.18), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: 0x1A1F3A))
        )
        .padding()
        .accessibilityElement(children: .contain)
        .task {
            // Async upgrade: ask the model for better h1/sub; fallback is already set.
            let lines = await CopyEngine.shared.quickReadLines(overlap: overlapSymbols, score: score)
            h1 = lines.h1
            sub = lines.sub
        }
    }

    private func snippet(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 160 else { return trimmed }
        let index = trimmed.index(trimmed.startIndex, offsetBy: 160)
        return String(trimmed[..<index]) + "…"
    }
}

