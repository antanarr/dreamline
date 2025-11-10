import Foundation

enum ZodiacSign: String, CaseIterable {
    case aries, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces
    
    static func current(for date: Date = Date()) -> ZodiacSign {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        switch (month, day) {
        case (3, 21...31), (4, 1...19): return .aries
        case (4, 20...30), (5, 1...20): return .taurus
        case (5, 21...31), (6, 1...20): return .gemini
        case (6, 21...30), (7, 1...22): return .cancer
        case (7, 23...31), (8, 1...22): return .leo
        case (8, 23...31), (9, 1...22): return .virgo
        case (9, 23...30), (10, 1...22): return .libra
        case (10, 23...31), (11, 1...21): return .scorpio
        case (11, 22...30), (12, 1...21): return .sagittarius
        case (12, 22...31), (1, 1...19): return .capricorn
        case (1, 20...31), (2, 1...18): return .aquarius
        case (2, 19...29), (3, 1...20): return .pisces
        default: return .aries
        }
    }
    
    var seasonDescription: String {
        switch self {
        case .aries:
            return "Spring's fire ignites. Aries season is about bold beginnings, raw courage, and burning through what holds you back."
        case .taurus:
            return "Ground down into pleasure. Taurus season asks you to slow down, trust your senses, and build something real."
        case .gemini:
            return "Talk, think, move. Gemini season is when your mind opens up and connections multiply. Stay curious."
        case .cancer:
            return "Feel it all. Cancer season pulls you inward to honor what's tender, what's home, what needs protecting."
        case .leo:
            return "Shine without permission. Leo season is your moment to be seen, to create, to claim your fire."
        case .virgo:
            return "Refine the details. Virgo season is about precision, service, and making the messy parts work better."
        case .libra:
            return "Balance the scales. Libra season asks you to negotiate, beautify, and find harmony in the chaos."
        case .scorpio:
            return "Time to burn it down. Scorpio season is when real change starts with destroying what's not working."
        case .sagittarius:
            return "Expand beyond borders. Sagittarius season pushes you to explore, risk, and find meaning in the unknown."
        case .capricorn:
            return "Build the empire. Capricorn season is about structure, ambition, and climbing with intention."
        case .aquarius:
            return "Break the rules. Aquarius season invites rebellion, innovation, and radical connection."
        case .pisces:
            return "Dissolve the boundaries. Pisces season is when dreams bleed into reality and compassion runs deep."
        }
    }
    
    var dateRange: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        
        switch self {
        case .aries: return "March 21 - April 19, \(year)"
        case .taurus: return "April 20 - May 20, \(year)"
        case .gemini: return "May 21 - June 20, \(year)"
        case .cancer: return "June 21 - July 22, \(year)"
        case .leo: return "July 23 - August 22, \(year)"
        case .virgo: return "August 23 - September 22, \(year)"
        case .libra: return "September 23 - October 22, \(year)"
        case .scorpio: return "October 23 - November 21, \(year)"
        case .sagittarius: return "November 22 - December 21, \(year)"
        case .capricorn: return "December 22 - January 19, \(year)"
        case .aquarius: return "January 20 - February 18, \(year)"
        case .pisces: return "February 19 - March 20, \(year)"
        }
    }
    
    var symbol: String {
        switch self {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }
    
    var artworkAssetName: String {
        "zodiac_\(rawValue)"
    }
}

