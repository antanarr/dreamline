import Foundation

@MainActor
final class TodayRangeViewModel: ObservableObject {
    @Published var item: HoroscopeStructured?
    @Published var loading = false
    @Published var errorMessage: String?

    private var activeAnchorKey: String?

    func load(period: HoroscopeRange, tz: String, uid: String = "me", force: Bool = false) async {
        let anchorKey = HoroscopeService.makeAnchorKey(uid: uid, period: period, tzIdentifier: tz)
        activeAnchorKey = anchorKey

        let cached = HoroscopeService.shared.cached(period: period, tz: tz, uid: uid)

        if !force, let cached {
            item = cached
            loading = false
            errorMessage = nil
            return
        }

        if item?.anchorKey != anchorKey {
            loading = true
            errorMessage = nil
        }

        do {
            let fresh = try await HoroscopeService.shared.readOrCompose(period: period, tz: tz, uid: uid, force: force)
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
