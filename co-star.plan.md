# Co-Star-Inspired Today View Redesign

## Overview
Redesign the Today view to match Co-Star's UX patterns while integrating dream analysis. Focus on glanceability, progressive disclosure (free → paid tiers), and keeping users engaged with seasonal content and educational sections.

## Phase 1: Restructure Today View Layout

### 1.1 Update TodayView.swift main structure
**File**: `Sources/Features/Today/TodayView.swift`

Replace current layout with Co-Star-inspired sections:
- **Hero section**: "Your Day" (not "Day at a Glance" - avoid copycat)
  - Astrological headline from horoscope
  - If dreams logged today: append 1-2 sentence dream integration
  - Prominent "Log Dream" button (replace current recordBanner)
  
- **Quick Log Dream CTA**: Single button that opens ComposeDreamView
  - Icon + "Log Dream" text
  - Subtitle: "Enhance today's reading"

- **Areas of Life section**: Display all 6 life areas from `HoroscopeStructured.areas`
  - Show area icon, title, 1-2 line preview
  - Free tier: Show 2 areas fully, rest have "Unlock" badge
  - Each tappable → navigates to detail view

- **Behind This Forecast**: New section explaining current transits
  - Parse `HoroscopeStructured.transits` array
  - Show planetary positions with simple text diagram
  - Explain what each transit means astrologically

- **Seasonal Content**: Two subsections
  - **Astrological Season**: e.g., "It's Scorpio Season" (Nov 9 falls in Scorpio)
    - Calculate from current date
    - Static educational content about the current zodiac season
  - **Your Dream Patterns**: e.g., "Water has been appearing for 3 weeks"
    - Query last 30 days of dreams from DreamStore
    - Identify recurring symbols
    - Free tier: teaser sentence only

- **Best Days This Week**: Calendar preview
  - Fetch from new backend endpoint `bestDaysForWeek`
  - Astrology-based (favorable transits)
  - Dream context if available (Pro feature)

### 1.2 Create new SwiftUI components

**New file**: `Sources/Features/Today/YourDayHeroCard.swift`
```swift
struct YourDayHeroCard: View {
  let headline: String
  let dreamEnhancement: String? // Optional dream sentence
  let onLogDream: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("YOUR DAY")
        .font(DLFont.caption)
        .foregroundStyle(.secondary)
      
      Text(headline)
        .font(DLFont.title(28))
      
      if let enhancement = dreamEnhancement {
        Text(enhancement)
          .font(DLFont.body(16))
          .foregroundStyle(.secondary)
      }
      
      Button(action: onLogDream) {
        HStack {
          Image(systemName: "moon.stars.fill")
          Text("Log Dream")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(/* gradient */)
      }
    }
  }
}
```

**New file**: `Sources/Features/Today/LifeAreaRow.swift`
```swift
struct LifeAreaRow: View {
  let area: HoroscopeArea
  let isLocked: Bool // Based on tier + position
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      HStack {
        Image(systemName: iconFor(area.id))
        VStack(alignment: .leading) {
          Text(area.title)
          Text(area.bullets.first ?? "")
            .lineLimit(2)
        }
        Spacer()
        if isLocked {
          Image(systemName: "lock.fill")
        } else {
          Image(systemName: "chevron.right")
        }
      }
    }
  }
}
```

**New file**: `Sources/Features/Today/LifeAreaDetailView.swift`
```swift
struct LifeAreaDetailView: View {
  let area: HoroscopeArea
  let isPro: Bool
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        // Full area content
        Text(area.title).font(.title)
        
        ForEach(area.bullets, id: \.self) { bullet in
          Text(bullet)
        }
        
        // Do/Don't section
        if let actions = area.actions {
          HStack {
            ActionColumn(title: "Do", items: actions.do_ ?? [])
            ActionColumn(title: "Don't", items: actions.dont ?? [])
          }
        }
        
        // Accuracy feedback
        AccuracyFeedbackView(areaId: area.id)
        
        // Behind This Forecast (per area)
        BehindForecastSection(transitInfo: /* extract */)
      }
    }
  }
}
```

**New file**: `Sources/Features/Today/AccuracyFeedbackView.swift`
```swift
struct AccuracyFeedbackView: View {
  let areaId: String
  @State private var feedback: FeedbackChoice?
  
  enum FeedbackChoice {
    case accurate, notAccurate
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Divider()
      
      HStack {
        Button("NOT ACCURATE") {
          feedback = .notAccurate
          // Log to analytics/Firestore
        }
        .opacity(feedback == .notAccurate ? 1 : 0.5)
        
        Spacer()
        
        Button("ACCURATE") {
          feedback = .accurate
          // Log to analytics/Firestore
        }
        .opacity(feedback == .accurate ? 1 : 0.5)
      }
      .font(DLFont.caption)
    }
  }
}
```

**New file**: `Sources/Features/Today/BehindThisForecastView.swift`
```swift
struct BehindThisForecastView: View {
  let transits: [HoroscopeStructured.TransitPill]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("BEHIND THIS FORECAST")
        .font(DLFont.caption)
        .foregroundStyle(.secondary)
      
      ForEach(transits, id: \.label) { transit in
        TransitExplanationRow(
          label: transit.label, // e.g., "Venus trine Neptune"
          tone: transit.tone
        )
      }
    }
  }
}

struct TransitExplanationRow: View {
  let label: String
  let tone: String
  
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: planetIcon(from: label))
        .font(.title2)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(label)
          .font(DLFont.body(16))
        Text(toneExplanation)
          .font(DLFont.body(14))
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      Text(durationText)
        .font(DLFont.caption)
    }
  }
  
  private var toneExplanation: String {
    // Hardcoded educational content about each aspect type
    // e.g., "trine" → "harmonious flow of energy"
  }
  
  private var durationText: String {
    // e.g., "Through Saturday" (would come from backend)
    "Through Dec 2025"
  }
}
```

**New file**: `Sources/Features/Today/SeasonalContentView.swift`
```swift
struct SeasonalContentView: View {
  let currentZodiacSeason: ZodiacSign
  let dreamPatterns: [DreamPattern]
  let isPro: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      // Zodiac Season
      ZodiacSeasonCard(sign: currentZodiacSeason)
      
      // Dream Patterns (if any)
      if !dreamPatterns.isEmpty {
        DreamPatternsCard(
          patterns: dreamPatterns,
          isPro: isPro
        )
      }
    }
  }
}

struct ZodiacSeasonCard: View {
  let sign: ZodiacSign
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("It's \(sign.rawValue.capitalized) season.")
        .font(DLFont.title(24))
      
      Text(sign.seasonDescription)
        .font(DLFont.body(16))
      
      // Educational content about traits, themes, etc.
    }
  }
}

struct DreamPatternsCard: View {
  let patterns: [DreamPattern]
  let isPro: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Your Dream Patterns")
        .font(DLFont.title(20))
      
      if isPro {
        ForEach(patterns) { pattern in
          Text("\(pattern.symbol) appeared \(pattern.occurrences) times in \(pattern.daySpan) days")
        }
      } else {
        // Teaser
        Text("Water symbols have been appearing...")
          .foregroundStyle(.secondary)
        
        Button("Unlock Pattern Analysis") {
          // Show paywall
        }
      }
    }
  }
}
```

**New file**: `Sources/Features/Today/BestDaysView.swift`
```swift
struct BestDaysView: View {
  let days: [BestDayInfo]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("YOUR BEST DAYS")
          .font(DLFont.caption)
          .foregroundStyle(.secondary)
        
        Spacer()
        
        Button("PRO") {
          // Paywall
        }
        .font(DLFont.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.dlViolet)
        .foregroundStyle(.white)
        .clipShape(Capsule())
      }
      
      ForEach(days.prefix(2)) { day in
        HStack {
          VStack(alignment: .leading) {
            Text(day.title) // "Best day for risks"
            Text(day.date.formatted(date: .abbreviated, time: .omitted))
              .font(DLFont.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
          Image(systemName: "arrow.right")
        }
      }
      
      Button("VIEW FULL CALENDAR") {
        // Navigate to calendar
      }
    }
  }
}
```

## Phase 2: Backend Updates

### 2.1 Update horoscopeCompose function
**File**: `functions/src/index.ts`

Add to the prompt instructions:
- Generate 6 distinct life areas matching Co-Star's structure
- For free users: ensure first 2 areas have full detail
- Add dream pattern teasers in free tier output
- Include transit duration data in response

Update response schema to include:
```typescript
{
  headline: string,
  dreamEnhancement?: string, // Added if recent dreams exist
  areas: [/* 6 areas */],
  transits: [{
    label: string,
    tone: string,
    duration: string, // "Through Saturday"
    explanation: string // Educational content
  }]
}
```

### 2.2 Create new bestDaysForWeek endpoint
**File**: `functions/src/index.ts`

```typescript
export const bestDaysForWeek = onRequest({ cors: true, invoker: "public" }, async (req, res) => {
  const { uid, birthISO } = req.body;
  
  // Calculate favorable transit days for the week
  // Based on user's natal chart + current transits
  
  const days = [
    { date: "2025-11-10", title: "Best day for risks", reason: "Mars trine Sun" },
    { date: "2025-11-12", title: "Great day for therapy", reason: "Moon conjunct Neptune" }
  ];
  
  res.json({ days });
});
```

### 2.3 Add accuracy feedback endpoint
**File**: `functions/src/index.ts`

```typescript
export const submitAccuracyFeedback = onRequest({ cors: true, invoker: "public" }, async (req, res) => {
  const { uid, areaId, horoscopeDate, accurate } = req.body;
  
  await db.collection('feedback').add({
    uid,
    areaId,
    horoscopeDate,
    accurate,
    timestamp: FieldValue.serverTimestamp()
  });
  
  res.json({ success: true });
});
```

## Phase 3: New Swift Models & Services

### 3.1 Add ZodiacSign enum
**File**: `Sources/Shared/Models/ZodiacSign.swift`

```swift
enum ZodiacSign: String, CaseIterable {
  case aries, taurus, gemini, cancer, leo, virgo
  case libra, scorpio, sagittarius, capricorn, aquarius, pisces
  
  static func current(for date: Date = Date()) -> ZodiacSign {
    let calendar = Calendar.current
    let month = calendar.component(.month, from: date)
    let day = calendar.component(.day, from: date)
    
    // Calculate based on month/day
    // ...
  }
  
  var seasonDescription: String {
    switch self {
    case .scorpio:
      return "Time to burn it down. Scorpio season is when real change starts with destroying what's not working."
    // ... other cases
    }
  }
  
  var dateRange: String {
    // e.g., "October 22 - November 21, 2025"
  }
}
```

### 3.2 DreamPattern model
**File**: `Sources/Shared/Models/DreamPattern.swift`

```swift
struct DreamPattern: Identifiable {
  let id: String
  let symbol: String
  let occurrences: Int
  let daySpan: Int
  let firstOccurrence: Date
  let lastOccurrence: Date
}
```

### 3.3 Create DreamPatternService
**File**: `Sources/Services/DreamPatternService.swift`

```swift
@MainActor
final class DreamPatternService: ObservableObject {
  static let shared = DreamPatternService()
  
  func analyzePatterns(from store: DreamStore, days: Int = 30) -> [DreamPattern] {
    let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    let recentDreams = store.entries.filter { $0.createdAt >= cutoff }
    
    // Group by symbols
    var symbolCounts: [String: [Date]] = [:]
    for dream in recentDreams {
      for symbol in dream.symbols {
        symbolCounts[symbol, default: []].append(dream.createdAt)
      }
    }
    
    // Find recurring patterns (2+ occurrences)
    return symbolCounts.compactMap { symbol, dates in
      guard dates.count >= 2 else { return nil }
      let sorted = dates.sorted()
      return DreamPattern(
        id: symbol,
        symbol: symbol,
        occurrences: dates.count,
        daySpan: Calendar.current.dateComponents([.day], from: sorted.first!, to: sorted.last!).day ?? 0,
        firstOccurrence: sorted.first!,
        lastOccurrence: sorted.last!
      )
    }
  }
}
```

### 3.4 Update HoroscopeService
**File**: `Sources/Services/HoroscopeService.swift`

Add method to fetch best days:
```swift
func fetchBestDays(uid: String = "me") async throws -> [BestDayInfo] {
  // Call bestDaysForWeek endpoint
}
```

## Phase 4: UI/UX Polish

### 4.1 Update theme colors for locked content
**File**: `Sources/DesignSystem/Theme.swift`

Add:
```swift
var lockOverlay: Color
var proGradient: [Color]
```

### 4.2 Create paywall trigger helper
**File**: `Sources/Services/PaywallService.swift`

```swift
@MainActor
final class PaywallService: ObservableObject {
  @Published var showPaywall = false
  @Published var paywallContext: PaywallContext?
  
  enum PaywallContext {
    case lockedLifeArea(areaId: String)
    case dreamPatterns
    case bestDays
    case diveDeeper(areaId: String)
  }
  
  func trigger(_ context: PaywallContext) {
    paywallContext = context
    showPaywall = true
  }
}
```

### 4.3 Visual diagram component (generic)
**File**: `Sources/Features/Today/TransitDiagramView.swift`

Simple text-based diagram showing planetary relationships:
```
     YOUR SCORPIO MERCURY
            |
        CONJUNCTION (0°)
            |
         VENUS NOW
```

## Implementation Order

1. Create new Swift model files (ZodiacSign, DreamPattern, BestDayInfo)
2. Create DreamPatternService to analyze recurring symbols
3. Build new UI components (YourDayHeroCard, LifeAreaRow, etc.)
4. Update TodayView.swift layout to use new components
5. Implement LifeAreaDetailView with accuracy feedback
6. Add BehindThisForecastView with transit explanations
7. Build SeasonalContentView with zodiac season + dream patterns
8. Create BestDaysView (stub with static data initially)
9. Update backend horoscopeCompose to generate 6 areas + dream enhancement
10. Add bestDaysForWeek and submitAccuracyFeedback endpoints
11. Wire up PaywallService throughout
12. Final polish: animations, gradients, spacing

## Key Files Summary

**New files:**
- `Sources/Features/Today/YourDayHeroCard.swift`
- `Sources/Features/Today/LifeAreaRow.swift`
- `Sources/Features/Today/LifeAreaDetailView.swift`
- `Sources/Features/Today/AccuracyFeedbackView.swift`
- `Sources/Features/Today/BehindThisForecastView.swift`
- `Sources/Features/Today/SeasonalContentView.swift`
- `Sources/Features/Today/BestDaysView.swift`
- `Sources/Features/Today/TransitDiagramView.swift`
- `Sources/Shared/Models/ZodiacSign.swift`
- `Sources/Shared/Models/DreamPattern.swift`
- `Sources/Shared/Models/BestDayInfo.swift`
- `Sources/Services/DreamPatternService.swift`
- `Sources/Services/PaywallService.swift`

**Modified files:**
- `Sources/Features/Today/TodayView.swift` - Complete restructure
- `Sources/Services/HoroscopeService.swift` - Add fetchBestDays
- `functions/src/index.ts` - Update horoscopeCompose, add new endpoints

## Notes
- All free/paid tier logic respects `EntitlementsService.tier`
- Dream integration is automatic (no manual refresh needed after logging)
- Seasonal content updates automatically based on current date
- Accuracy feedback stored in Firestore for future ML improvements

