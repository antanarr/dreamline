import Foundation

@MainActor
final class TodayRangeViewModel: ObservableObject {
    @Published var item: HoroscopeStructured?
    @Published var loading = false
    @Published var errorMessage: String?

    private var activeAnchorKey: String?
    private weak var dreamStoreRef: DreamStore?
    private var dreamsObserver: NSObjectProtocol?

    init() {
        dreamsObserver = NotificationCenter.default.addObserver(
            forName: .dreamsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let store = (notification.object as? DreamStore) ?? self.dreamStoreRef else { return }
                await self.recomputeResonance(using: store)
            }
        }
    }

    deinit {
        if let observer = dreamsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func load(period: HoroscopeRange,
              tz: String,
              dreamStore: DreamStore,
              uid: String = "me",
              force: Bool = false,
              reference: Date = Date()) async {
        let anchorKey = HoroscopeService.makeAnchorKey(uid: uid, period: period, tzIdentifier: tz, reference: reference)
        activeAnchorKey = anchorKey
        dreamStoreRef = dreamStore
        
        let cached = HoroscopeService.shared.cached(period: period, tz: tz, uid: uid, reference: reference)

        if !force, var cachedItem = cached {
            if let bundle = await ResonanceService.shared.buildResonance(
                anchorKey: anchorKey,
                headline: cachedItem.headline,
                summary: cachedItem.summary,
                dreams: dreamStore.entries,
                horoscopeEmbedding: cachedItem.resonance?.horoscopeEmbedding,
                updater: { updated in dreamStore.update(updated) }
            ) {
                cachedItem.resonance = bundle
            }
            item = cachedItem
            loading = false
            errorMessage = nil
            return
        }

        if item?.anchorKey != anchorKey {
            loading = true
            errorMessage = nil
        }

        do {
            let fresh = try await HoroscopeService.shared.readOrCompose(period: period,
                                                                        tz: tz,
                                                                        uid: uid,
                                                                        force: force,
                                                                        reference: reference)
            guard activeAnchorKey == anchorKey else { return }
            let dreams = dreamStore.entries
            let enriched = await ResonanceService.shared.buildResonance(
                anchorKey: anchorKey,
                headline: fresh.headline,
                summary: fresh.summary,
                dreams: dreams,
                horoscopeEmbedding: fresh.resonance?.horoscopeEmbedding,
                updater: { updated in dreamStore.update(updated) }
            ).map { bundle -> HoroscopeStructured in
                var x = fresh
                x.resonance = bundle
                return x
            } ?? fresh
            item = enriched
            errorMessage = nil
        } catch {
            guard activeAnchorKey == anchorKey else { return }
            if let cached {
                item = cached
            }
            errorMessage = Self.humanReadableMessage(for: error)
        }

        if activeAnchorKey == anchorKey {
            loading = false
        }
    }

    private func recomputeResonance(using store: DreamStore) async {
        guard let current = item else { return }
        let anchorKey = current.anchorKey
        guard activeAnchorKey == anchorKey else { return }

        let refreshed = await ResonanceService.shared.buildResonance(
            anchorKey: anchorKey,
            headline: current.headline,
            summary: current.summary,
            dreams: store.entries,
            horoscopeEmbedding: current.resonance?.horoscopeEmbedding,
            updater: { updated in store.update(updated) }
        ).map { bundle -> HoroscopeStructured in
            var x = current
            x.resonance = bundle
            return x
        } ?? current

        if activeAnchorKey == anchorKey {
            item = refreshed
        }
    }

    private static func humanReadableMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "You’re offline. Reconnect to pull the latest horoscope."
            case .timedOut:
                return "The request timed out. Tap refresh to try again."
            case .cannotFindHost, .cannotConnectToHost, .networkConnectionLost:
                return "We couldn’t reach Dreamline’s servers. Try again shortly."
            default:
                break
            }
        }

        if error is DecodingError {
            return "We hit a formatting issue pulling this range. We’re regenerating soon."
        }

        return "Something blocked the horoscope fetch. Try refreshing in a moment."
    }
}
