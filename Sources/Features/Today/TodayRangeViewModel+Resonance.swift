import Foundation

extension TodayRangeViewModel {
    /// Compute resonance for the current `item` using dreams from the store.
    /// Safe to call after `load(...)` finishes.
    @MainActor
    func computeResonance(dreamStore: DreamStore, tz: String, reference: Date, uid: String = "me") async {
        guard let item = self.item else { return }
        let anchorKey = AnchorKey.day(uid: uid, tz: tz, date: reference)

        let summaryText = item.summary.isEmpty ? item.headline : item.summary
        
        let bundle = await ResonanceService.shared.buildBundle(
            anchorKey: anchorKey,
            headline: item.headline,
            summary: summaryText,
            horoscopeEmbedding: item.embedding,
            dreams: dreamStore.entries,
            now: reference
        )

        if var updated = self.item {
            updated.resonance = bundle
            self.item = updated
        }
    }
}

