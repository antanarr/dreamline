import Foundation

struct HoroscopeArea: Codable, Hashable, Identifiable {
  let id: String
  let title: String
  let score: Double
  let bullets: [String]
  let actions: Actions?
  
  struct Actions: Codable, Hashable { 
    let do_: [String]?
    let dont: [String]?
    
    enum CodingKeys: String, CodingKey { 
      case do_ = "do"
      case dont 
    }
  }
}

struct HoroscopeStructured: Codable, Hashable {
  let range: String
  let anchorKey: String
  let headline: String
  let summary: String
  let areas: [HoroscopeArea]
  let transits: [TransitPill]
  let model: String
  let generatedAt: String
  var resonance: ResonanceBundle?
  
  struct TransitPill: Codable, Hashable { 
    let label: String
    let tone: String 
  }
}

struct DreamLink: Identifiable, Hashable, Codable {
  let id: String
  let motif: String
  let line: String
  let transitRef: String?
}

enum LifeArea: String, CaseIterable, Codable, Identifiable {
  case relationships
  case wellbeing
  case career
  case creativity
  case intuition
  case rest
  case mystery
  
  init(rawID: String) {
    switch rawID.lowercased() {
    case "relationships", "love", "connection":
      self = .relationships
    case "wellbeing", "health", "body":
      self = .wellbeing
    case "career", "work", "ambition":
      self = .career
    case "creativity", "expression", "art":
      self = .creativity
    case "intuition", "spirit", "inner":
      self = .intuition
    case "rest", "recovery", "recharge":
      self = .rest
    default:
      self = .mystery
    }
  }
  
  var id: String { rawValue }
  
  var displayTitle: String {
    switch self {
    case .relationships: return "Relationships"
    case .wellbeing: return "Wellbeing"
    case .career: return "Career"
    case .creativity: return "Creativity"
    case .intuition: return "Intuition"
    case .rest: return "Rest"
    case .mystery: return "Uncharted"
    }
  }
  
  var iconSystemName: String {
    switch self {
    case .relationships: return "heart.fill"
    case .wellbeing: return "figure.cooldown"
    case .career: return "briefcase.fill"
    case .creativity: return "paintpalette.fill"
    case .intuition: return "sparkles"
    case .rest: return "moon.zzz.fill"
    case .mystery: return "questionmark.diamond.fill"
    }
  }
  
  var artworkAssetName: String {
    switch self {
    case .relationships: return "planet_venus_fill"
    case .wellbeing: return "planet_moon_fill"
    case .career: return "planet_saturn_fill"
    case .creativity: return "planet_mercury_fill"
    case .intuition: return "planet_neptune_fill"
    case .rest: return "planet_moon_line"
    case .mystery: return "planet_pluto_fill"
    }
  }
  
  var planetKey: String {
    switch self {
    case .relationships: return "venus"
    case .wellbeing: return "moon"
    case .career: return "saturn"
    case .creativity: return "mercury"
    case .intuition: return "neptune"
    case .rest: return "moon"
    case .mystery: return "pluto"
    }
  }
}

extension HoroscopeStructured {
  struct MapEntry: Identifiable {
    let id: String
    let area: LifeArea
    let headline: String
    let body: String
    let score: Int
    let transitRef: String?
    
    var identifier: String { id }
  }
  
  private struct AnchorPayload: Decodable {
    let uid: String
    let period: String
    let tz: String
    let startUTC: String
  }
  
  private static let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()
  
  func expirationDate() -> Date? {
    guard let payload = decodeAnchorPayload(),
          let start = Self.isoFormatter.date(from: payload.startUTC) else {
      return nil
    }
    
    guard let rangeValue = HoroscopeRange(rawValue: payload.period) ?? HoroscopeRange(rawValue: range) else {
      return nil
    }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: payload.tz) ?? .current
    
    switch rangeValue {
    case .day:
      return calendar.date(byAdding: .day, value: 1, to: start)
    case .week:
      return calendar.date(byAdding: .day, value: 7, to: start)
    case .month:
      return calendar.date(byAdding: .month, value: 1, to: start)
    case .year:
      return calendar.date(byAdding: .year, value: 1, to: start)
    }
  }
  
  func isExpired(asOf date: Date = Date()) -> Bool {
    guard let expiry = expirationDate() else { return false }
    return date >= expiry
  }
  
  var period: HoroscopeRange {
    HoroscopeRange(rawValue: range) ?? .day
  }
  
  var shareSummary: String {
    let headlineLine = headline.trimmingCharacters(in: .whitespacesAndNewlines)
    let summaryLine = summary.trimmingCharacters(in: .whitespacesAndNewlines)
    return [headlineLine, summaryLine]
      .filter { !$0.isEmpty }
      .joined(separator: "\n\n")
  }
  
  var dayAtGlance: String {
    summary.isEmpty ? headline : summary
  }
  
  var primaryTransit: String? {
    transits.first?.label
  }
  
  var mapEntries: [MapEntry] {
    areas.enumerated().map { index, area in
      let normalizedScore = Self.normalizedScore(area.score)
      return MapEntry(
        id: "\(area.id)-\(index)",
        area: LifeArea(rawID: area.id),
        headline: area.title.isEmpty ? headline : area.title,
        body: area.bullets.first ?? summary,
        score: normalizedScore,
        transitRef: transits.first?.label
      )
    }
  }
  
  var pressures: [MapEntry] {
    mapEntries
      .sorted { $0.score < $1.score }
      .prefix(3)
      .map { $0 }
  }
  
  var supports: [MapEntry] {
    mapEntries
      .sorted { $0.score > $1.score }
      .prefix(3)
      .map { $0 }
  }
  
  var doItems: [String] {
    areas.flatMap { $0.actions?.do_ ?? [] }
  }
  
  var dontItems: [String] {
    areas.flatMap { $0.actions?.dont ?? [] }
  }
  
  var dreamLinks: [DreamLink] {
    let links = areas.flatMap { area in
      area.bullets.prefix(1).map { bullet in
        DreamLink(
          id: "\(area.id)-\(bullet.hashValue)",
          motif: area.title.isEmpty ? area.id : area.title,
          line: bullet,
          transitRef: transits.first?.label
        )
      }
    }
    return Array(links.prefix(4))
  }
  
  var primaryDreamLink: DreamLink? {
    dreamLinks.first
  }
  
  var aggregatedActions: (do: [String], dont: [String]) {
    var doItems: [String] = []
    var dontItems: [String] = []
    
    for area in areas {
      if let doList = area.actions?.do_ {
        doItems.append(contentsOf: doList.filter { !$0.isEmpty })
      }
      if let dontList = area.actions?.dont {
        dontItems.append(contentsOf: dontList.filter { !$0.isEmpty })
      }
    }
    
    return (Array(doItems.prefix(4)), Array(dontItems.prefix(4)))
  }
  
  func expiryDescription(reference date: Date = Date()) -> String? {
    guard let expiry = expirationDate() else { return nil }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .spellOut
    return formatter.localizedString(for: expiry, relativeTo: date)
  }
  
  private static func normalizedScore(_ score: Double) -> Int {
    guard score.isFinite else { return 0 }
    if score > 1.0 {
      return Int(score.rounded())
    } else {
      return Int((score * 100).rounded())
    }
  }
  
  private func decodeAnchorPayload() -> AnchorPayload? {
    let normalized = anchorKey
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    let padding = (4 - normalized.count % 4) % 4
    let padded = normalized + String(repeating: "=", count: padding)
    guard let data = Data(base64Encoded: padded) else { return nil }
    return try? JSONDecoder().decode(AnchorPayload.self, from: data)
  }
}

