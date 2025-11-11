import SwiftUI

/// Drop-in extras for Dream Detail: shows an "Aligned today" pill (if cached alignment exists)
/// and a lightweight "Related dreams" panel from the Constellation graph.
struct DreamDetailExtras: View {
    let dream: DreamEntry

    @Environment(DreamStore.self) private var store
    @ObservedObject private var constellation = ConstellationStore.shared
    @State private var alignedToday: Bool = false

    init(dream: DreamEntry) {
        self.dream = dream
    }

    // Anchor key for "today" (local tz). Uses same shape as Today’s anchor.
    private var todayAnchorKey: String {
        let tz = TimeZone.current.identifier
        return AnchorKey.day(uid: "me", tz: tz, date: Date())
    }

    private var neighborEntries: [(DreamEntry, Float)] {
        let top = constellation.topNeighbors(for: dream.id, k: ResonanceConfig.GRAPH_TOP_K)
        guard !top.isEmpty else { return [] }

        let index = Dictionary(uniqueKeysWithValues: store.entries.map { ($0.id, $0) })
        return top.compactMap { tuple in
            guard let entry = index[tuple.id] else { return nil }
            return (entry, tuple.weight)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if FeatureFlags.resonanceUIEnabled && alignedToday {
                alignedPill
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            if constellation.hasGraph && !neighborEntries.isEmpty {
                relatedSection(neighbors: neighborEntries)
                    .padding(.top, FeatureFlags.resonanceUIEnabled && alignedToday ? 4 : 0)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .task(id: todayAnchorKey) {
            await refreshAlignment()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dreamsDidChange)) { _ in
            Task { await refreshAlignment() }
        }
    }

    private var alignedPill: some View {
        HStack(spacing: 10) {
            Text("Aligned today")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.dlMint.opacity(0.16), in: Capsule())
                .accessibilityLabel("Aligned today")

            Text("Your dream echoes today’s sky.")
                .font(DLFont.body(12))
                .foregroundStyle(.secondary)
        }
        .accessibilityAddTraits(.updatesFrequently)
    }

    @ViewBuilder
    private func relatedSection(neighbors: [(DreamEntry, Float)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Related dreams")
                .font(DLFont.body(13).weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityLabel("Related dreams")

            ForEach(neighbors, id: \.0.id) { pair in
                let entry = pair.0
                let weight = pair.1

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(snippet(entry.rawText))
                        .font(DLFont.body(13))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Text(String(format: "%.0f%%", Double(weight * 100)))
                        .font(DLFont.body(11).monospacedDigit())
                        .foregroundStyle(Color.dlMint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.dlMint.opacity(0.12), in: Capsule())
                        .accessibilityLabel("Resonance \(Int(weight * 100)) percent")
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func snippet(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 80 else { return trimmed }
        let index = trimmed.index(trimmed.startIndex, offsetBy: 80)
        return String(trimmed[..<index]) + "…"
    }

    private func refreshAlignment() async {
        let ok = await ResonanceService.shared.isAligned(dreamID: dream.id, anchorKey: todayAnchorKey)
        await MainActor.run {
            alignedToday = ok
        }
    }
}

