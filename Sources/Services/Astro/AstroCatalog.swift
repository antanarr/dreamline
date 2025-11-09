import SwiftUI

enum Planet: String, CaseIterable {
    case sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto
}

enum Zodiac: String, CaseIterable {
    case aries, taurus, gemini, cancer, leo, virgo, libra, scorpio, sagittarius, capricorn, aquarius, pisces
}

enum Aspect: String, CaseIterable {
    case conjunction, sextile, square, trine, opposition
}

enum AstroKind: Equatable {
    case planet(Planet, variant: Variant = .fill)
    case zodiac(Zodiac)
    case aspect(Aspect)
    
    enum Variant {
        case fill, line
    }
}

extension AstroKind {
    var assetName: String {
        switch self {
        case .planet(let p, let v):
            return "planet_\(p.rawValue)_\(v == .line ? "line" : "fill")"
        case .zodiac(let z):
            return "zodiac_\(z.rawValue)"
        case .aspect(let a):
            return "aspect_\(a.rawValue)"
        }
    }
    
    var title: String {
        switch self {
        case .planet(let p, _):
            return p.rawValue.prefix(1).uppercased() + p.rawValue.dropFirst()
        case .zodiac(let z):
            return z.rawValue.prefix(1).uppercased() + z.rawValue.dropFirst()
        case .aspect(let a):
            return a.rawValue.prefix(1).uppercased() + a.rawValue.dropFirst()
        }
    }
}

