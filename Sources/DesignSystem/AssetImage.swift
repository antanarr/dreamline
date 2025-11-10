import SwiftUI

enum DLAssetImage {
    // Zodiac, e.g. "aries" -> "zodiac_aries"
    static func zodiac(_ sign: String) -> Image {
        Image("zodiac_\(sign.lowercased())")
    }

    enum PlanetStyle: String { case line, fill }

    static func planet(_ name: String, style: PlanetStyle = .line) -> Image {
        Image("planet_\(name.lowercased())_\(style.rawValue)")
    }

    // Oracle / hero / backgrounds
    static var oracleIcon: Image { Image("icon_oracle") }
    static var oracleHeroHeader: Image { Image("oracle_hero_header") }
    static var heroBackground: Image { Image("bg_horoscope_card") }
    static var heroBG: Image { heroBackground }
    static var nebula: Image { Image("bg_nebula_full") }
    static var starGrid: Image { Image("pattern_stargrid_tile") }
    static var grain: Image { Image("pattern_gradientnoise_tile") }

    // Empty states
    static var emptyToday: Image { Image("empty_today") }
    static var emptyJournal: Image { Image("empty_journal") }

    // Dream symbols (if present), e.g. "ocean" -> "symbol_ocean"
    static func symbol(_ key: String) -> Image {
        let slug = key
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
        return Image("symbol_\(slug)")
    }
}
