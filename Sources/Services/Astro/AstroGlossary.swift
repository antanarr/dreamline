import Foundation

struct AstroEntry: Codable, Equatable {
    let title: String
    let oneLiner: String
    let bullets: [String]
}

@MainActor
final class AstroGlossary: ObservableObject {
    static let shared = AstroGlossary()
    private(set) var entries: [String: AstroEntry] = [:]   // key by assetName or canonical id

    init() {
        // Minimal seed; extend later or load from JSON.
        func E(_ t: String, _ o: String, _ b: [String]) -> AstroEntry {
            .init(title: t, oneLiner: o, bullets: b)
        }
        
        entries["planet_sun_fill"] = E("Sun", "Core identity and vitality.", [
            "Shows how you radiate and create.",
            "When activated by transits, creativity and self‑definition themes surge."
        ])
        entries["planet_sun_line"] = entries["planet_sun_fill"]
        
        entries["planet_moon_fill"] = E("Moon", "Emotional climate and needs.", [
            "Tracks the ebb and flow of feeling and safety.",
            "Links to habits, memory, and belonging."
        ])
        entries["planet_moon_line"] = entries["planet_moon_fill"]
        
        entries["planet_mercury_fill"] = E("Mercury", "Communication and thought.", [
            "How you process information and express ideas.",
            "Influences learning, writing, and mental patterns."
        ])
        entries["planet_mercury_line"] = entries["planet_mercury_fill"]
        
        entries["planet_venus_fill"] = E("Venus", "Love, beauty, and values.", [
            "What you find attractive and how you relate.",
            "Shapes aesthetic preferences and relationship style."
        ])
        entries["planet_venus_line"] = entries["planet_venus_fill"]
        
        entries["planet_mars_fill"] = E("Mars", "Energy, action, and desire.", [
            "How you assert yourself and pursue goals.",
            "Drives motivation and physical expression."
        ])
        entries["planet_mars_line"] = entries["planet_mars_fill"]
        
        entries["planet_jupiter_fill"] = E("Jupiter", "Expansion and wisdom.", [
            "Where you seek growth and meaning.",
            "Influences optimism, philosophy, and abundance."
        ])
        entries["planet_jupiter_line"] = entries["planet_jupiter_fill"]
        
        entries["planet_saturn_fill"] = E("Saturn", "Structure and responsibility.", [
            "Where you face limits and build mastery.",
            "Teaches through challenges and discipline."
        ])
        entries["planet_saturn_line"] = entries["planet_saturn_fill"]
        
        entries["planet_uranus_fill"] = E("Uranus", "Innovation and liberation.", [
            "Sudden insights and breaking free from old patterns.",
            "Awakens individuality and progressive thinking."
        ])
        entries["planet_uranus_line"] = entries["planet_uranus_fill"]
        
        entries["planet_neptune_fill"] = E("Neptune", "Intuition and transcendence.", [
            "Dreams, illusions, and spiritual connection.",
            "Dissolves boundaries; links to the collective unconscious."
        ])
        entries["planet_neptune_line"] = entries["planet_neptune_fill"]
        
        entries["planet_pluto_fill"] = E("Pluto", "Transformation and power.", [
            "Deep psychological change and rebirth.",
            "Unveils hidden truths and regenerative forces."
        ])
        entries["planet_pluto_line"] = entries["planet_pluto_fill"]
        
        entries["zodiac_aries"] = E("Aries", "Initiative and assertiveness.", [
            "The first sign; bold beginnings and raw energy."
        ])
        
        entries["zodiac_taurus"] = E("Taurus", "Stability and sensuality.", [
            "Grounded in the physical; values comfort and security."
        ])
        
        entries["zodiac_gemini"] = E("Gemini", "Curiosity and communication.", [
            "The twins; duality and versatile expression."
        ])
        
        entries["zodiac_cancer"] = E("Cancer", "Nurturing and emotional depth.", [
            "The crab; protective shell and inner softness."
        ])
        
        entries["zodiac_leo"] = E("Leo", "Creativity and self-expression.", [
            "The lion; radiant confidence and generous warmth."
        ])
        
        entries["zodiac_virgo"] = E("Virgo", "Analysis and service.", [
            "Attention to detail; refinement through practice."
        ])
        
        entries["zodiac_libra"] = E("Libra", "Balance and harmony.", [
            "The scales; seeking equilibrium in relationships."
        ])
        
        entries["zodiac_scorpio"] = E("Scorpio", "Intensity, depth, transformation.", [
            "Instinct to merge or purge; renewal through truth‑telling."
        ])
        
        entries["zodiac_sagittarius"] = E("Sagittarius", "Exploration and philosophy.", [
            "The archer; aiming for truth and expansion."
        ])
        
        entries["zodiac_capricorn"] = E("Capricorn", "Ambition and structure.", [
            "The sea-goat; climbing toward mastery."
        ])
        
        entries["zodiac_aquarius"] = E("Aquarius", "Innovation and individuality.", [
            "The water-bearer; progressive ideas and uniqueness."
        ])
        
        entries["zodiac_pisces"] = E("Pisces", "Intuition and compassion.", [
            "The fish; fluid boundaries and deep empathy."
        ])
        
        entries["aspect_trine"] = E("Trine", "Natural flow and ease.", [
            "Like a well‑oiled door: less friction, more momentum."
        ])
        
        entries["aspect_conjunction"] = E("Conjunction", "Intensity and focus.", [
            "Forces merge; heightened significance."
        ])
        
        entries["aspect_sextile"] = E("Sextile", "Opportunity and support.", [
            "Harmonious connection with room to grow."
        ])
        
        entries["aspect_square"] = E("Square", "Tension and challenge.", [
            "Friction that demands growth and integration."
        ])
        
        entries["aspect_opposition"] = E("Opposition", "Balance and polarity.", [
            "Two forces in dialogue; awareness of both sides."
        ])
    }

    func entry(for assetName: String) -> AstroEntry? {
        entries[assetName]
    }
}

