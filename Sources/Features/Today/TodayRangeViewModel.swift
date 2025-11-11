import Foundation

@MainActor
final class TodayRangeViewModel: ObservableObject {
    @Published var item: HoroscopeStructured?
    @Published var loading = false
    @Published var errorMessage: String?

    private var activeAnchorKey: String?
    private weak var dreamStoreRef: DreamStore?
    private var dreamsObserver: NSObjectProtocol?

    init() {}

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
        if dreamsObserver == nil {
            dreamsObserver = NotificationCenter.default.addObserver(
                forName: .dreamsDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let item = self.item else { return }
                    await self.rebuildResonance(for: item)
                }
            }
        }
        
        let cached = HoroscopeService.shared.cached(period: period, tz: tz, uid: uid, reference: reference)

        if !force, let cachedItem = cached {
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
            item = fresh
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

    private func rebuildResonance(for current: HoroscopeStructured) async {
        guard activeAnchorKey == current.anchorKey else { return }
        guard dreamStoreRef != nil else { return }
        // Resonance is now computed via the extension method after load
    }

    private static func humanReadableMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "You're offline. Reconnect to pull the latest horoscope."
            case .timedOut:
                return "The request timed out. Tap refresh to try again."
            case .cannotFindHost, .cannotConnectToHost, .networkConnectionLost:
                return "We couldn't reach Dreamline's servers. Try again shortly."
            default:
                break
            }
        }

        if error is DecodingError {
            return "We hit a formatting issue pulling this range. We're regenerating soon."
        }

        return "Something blocked the horoscope fetch. Try refreshing in a moment."
    }
}
