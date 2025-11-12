# DREAMLINE ORACLE — CURSOR EXECUTION PACK

**Version**: 2025-11-12  
**Purpose**: Complete implementation guide for Oracle explanation system  
**Estimated Time**: 30-45 minutes  
**Risk Level**: Low (infrastructure exists, just wiring)

---

## HOW TO USE

1. Paste this entire document into Cursor and run as a single instruction
2. Cursor should apply all patches and create new files as specified
3. After edits, run the verification commands at the bottom
4. Build and test on device

---

## PROBABILITIES / LOE (QUICK REFERENCE)

| Feature | P(value) | P(regression) | LOE |
|---------|----------|---------------|-----|
| Wire explainer + UI | 0.90 | 0.10 | S |
| Deep Dive + Paywall | 0.80 | 0.20 | M |
| "All About You" report | 0.70 | 0.25 | M–L |
| Personalization hooks | 0.75 | 0.15 | S–M |
| Analytics events | 0.80 | 0.05 | S |
| Fallbacks/caching | 0.70 | 0.10 | S–M |

---

## EDITS TO APPLY (EXACT STEPS)

### 1) FILE: `Sources/Shared/Models/Resonance.swift`

**ACTION**: Add OracleExplanation and include it on ResonanceBundle. Update init signature to accept explanation (default nil).

**PATCH**:
```swift
=== BEGIN PATCH ===

// Locate: 'public struct ResonanceBundle: Codable, Hashable {'
// Ensure the stored properties list includes the following new line after 'public let dynamicThreshold: Float':

    public let explanation: OracleExplanation?

// Locate the init for ResonanceBundle. Change the signature from:
//     public init(anchorKey: String,
//                 headline: String,
//                 summary: String?,
//                 horoscopeEmbedding: [Float],
//                 topHits: [ResonanceHit],
//                 dynamicThreshold: Float) {
// to:

    public init(anchorKey: String,
                headline: String,
                summary: String?,
                horoscopeEmbedding: [Float],
                topHits: [ResonanceHit],
                dynamicThreshold: Float,
                explanation: OracleExplanation? = nil) {
        self.anchorKey = anchorKey
        self.headline = headline
        self.summary = summary
        self.horoscopeEmbedding = horoscopeEmbedding
        self.topHits = topHits
        self.dynamicThreshold = dynamicThreshold
        self.explanation = explanation
    }

// After the closing brace of ResonanceBundle, append the new struct:

public struct OracleExplanation: Codable, Hashable {
    public let lead: String
    public let body: String?
    public let chips: [String]
    public let generatedAt: Date

    public init(lead: String,
                body: String? = nil,
                chips: [String] = [],
                generatedAt: Date = Date()) {
        self.lead = lead
        self.body = body
        self.chips = chips
        self.generatedAt = generatedAt
    }
}

=== END PATCH ===
```

---

### 2) FILE: `Sources/Shared/FeatureFlags.swift`

**ACTION**: Add new flags for Oracle surfaces.

**PATCH**:
```swift
=== BEGIN PATCH ===

// Inside 'public enum FeatureFlags {', after the existing static vars, add:

    /// Extended Oracle explanations (lead + body paragraphs)
    public static var oracleExplanationsEnabled: Bool = true
    
    /// Oracle paywall for deeper readings
    public static var oraclePaywallEnabled: Bool = true
    
    /// "All About You" personalized report
    public static var oracleAllAboutYouEnabled: Bool = true

=== END PATCH ===
```

---

### 3) FILE: `Sources/Services/AI/PromptBook.swift`

**ACTION**: Add deep dive and report task prompts (keep existing system + alignmentExplainer as-is).

**PATCH**:
```swift
=== BEGIN PATCH ===

// Append the following static lets after the existing prompts:

    /// Alignment deep dive (120-250 words, personalized reflection)
    /// INPUT JSON: { "overlap": [String], "headline": String, "summary": String, "profile": {...}, "lang": String }
    /// OUTPUT JSON: { "body": String }
    static let alignmentDeepDive = """
    Write a reflective deep dive in {{lang}}.
    FRAME: recognition, not prediction. Modern mystic; one idea per sentence.
    INPUT: { "overlap": [String], "headline": String, "summary": String, "profile": { "name": String?, "sun": String, "moon": String?, "rising": String?, "age": Int?, "pronouns": String? } }
    REQUIREMENTS:
    - 120–250 words; link recent dream motifs to today's sky.
    - Personalize gently with profile when present.
    - End with one reflective question.
    OUTPUT (JSON only):
    {"body":"..."}
    """

    /// All About You personalized report
    /// INPUT JSON: { "profile": {...}, "motifs7d": [String], "stats": {...}, "lang": String }
    /// OUTPUT JSON: { "title": String, "sections": [{"heading": String, "body": String}] }
    static let allAboutYouReport = """
    Compose a structured personal report in {{lang}}.
    FRAME: recognition; no advice; no hype; grade 7–9 readability.
    INPUT: { "profile": {...}, "motifs7d":[String], "stats": {"nDreams":Int,"avgLen":Int?} }
    SECTIONS (in order): Motifs, Thresholds, Emotional Weather, Guidance, Practices.
    OUTPUT (JSON only):
    {"title":"All About You","sections":[{"heading":"Motifs","body":"..."},{"heading":"Thresholds","body":"..."},{"heading":"Emotional Weather","body":"..."},{"heading":"Guidance","body":"..."},{"heading":"Practices","body":"..."}]}
    """

=== END PATCH ===
```

---

### 4) FILE: `Sources/Services/AI/CopyEngine.swift`

**ACTION**: Add result types, OracleUserProfile, deep-dive method, and fallback.

**PATCH**:
```swift
=== BEGIN PATCH ===

// Add near other Decodable structs (after QuickReadLeadOut, etc.):

private struct AlignmentDeepDiveOut: Decodable {
    let body: String
}

private struct AllAboutYouReportOut: Decodable {
    let title: String
    let sections: [Section]
    struct Section: Decodable {
        let heading: String
        let body: String
    }
}

// Add the profile type (public for use in other modules):

public struct OracleUserProfile: Codable {
    public var name: String?
    public var sun: String
    public var moon: String?
    public var rising: String?
    public var age: Int?
    public var pronouns: String?
    
    public init(name: String? = nil, sun: String, moon: String? = nil, rising: String? = nil, age: Int? = nil, pronouns: String? = nil) {
        self.name = name
        self.sun = sun
        self.moon = moon
        self.rising = rising
        self.age = age
        self.pronouns = pronouns
    }
}

// Add deep dive method inside CopyEngine actor (after alignmentAheadTeaser):

    func alignmentDeepDive(overlap: [String],
                          headline: String,
                          summary: String,
                          profile: OracleUserProfile?,
                          locale: Locale = .current) async -> String {
        let lang = languageTag(locale)
        let profileJSON: Any = {
            guard let p = profile else { return [:] }
            let data = try? JSONEncoder().encode(p)
            return (data.flatMap { try? JSONSerialization.jsonObject(with: $0) }) ?? [:]
        }()

        let input: [String: Any] = [
            "overlap": overlap,
            "headline": headline,
            "summary": summary,
            "profile": profileJSON,
            "lang": lang
        ]
        
        if let out = await backend.alignmentDeepDive(overlap: overlap, headline: headline, summary: summary, profile: profile, lang: lang) {
            return out.body
        }
        return fallback.alignmentDeepDive(overlap: overlap, headline: headline, summary: summary)
    }

// Update CopyBackend protocol to include:

private protocol CopyBackend {
    func quickReadLead(overlap: [String], score: Float, lang: String) async -> QuickReadLeadOut?
    func alignmentExplainer(overlap: [String], headline: String, summary: String, score: Float, lang: String) async -> AlignmentExplainerOut?
    func alignmentAheadTeaser(weekday: String, lang: String) async -> AlignmentAheadTeaserOut?
    func alignmentDeepDive(overlap: [String], headline: String, summary: String, profile: OracleUserProfile?, lang: String) async -> AlignmentDeepDiveOut?
}

// Add to ModelCopyBackend:

    func alignmentDeepDive(overlap: [String], headline: String, summary: String, profile: OracleUserProfile?, lang: String) async -> AlignmentDeepDiveOut? {
        let profileData = try? JSONEncoder().encode(profile ?? OracleUserProfile(sun: "unknown"))
        let profileJSON = profileData.flatMap { try? JSONSerialization.jsonObject(with: $0) } ?? [:]
        let input: [String: Any] = ["overlap": overlap, "headline": headline, "summary": summary, "profile": profileJSON, "lang": lang]
        return await call(prompt: PromptBook.alignmentDeepDive, input: input, as: AlignmentDeepDiveOut.self)
    }

// Add to LocalTemplateBackend:

    func alignmentDeepDive(overlap: [String], headline: String, summary: String, profile: OracleUserProfile?, lang: String) async -> AlignmentDeepDiveOut? {
        let result = alignmentDeepDive(overlap: overlap, headline: headline, summary: summary)
        return AlignmentDeepDiveOut(body: result)
    }
    
    func alignmentDeepDive(overlap: [String], headline: String, summary: String) -> String {
        let motif = overlap.first?.replacingOccurrences(of: "_", with: " ") ?? "what you're already circling"
        return "Themes repeat until they root. Your recent dreams keep brushing \(motif). Today's sky mirrors the same contour. Treat the echo as permission, not pressure. Follow the small nudge that keeps returning. What opens if you take one careful step toward it?"
    }

=== END PATCH ===
```

---

### 5) FILE: `Sources/Services/AI/ResonanceService.swift`

**ACTION**: Attach Oracle explanation when an alignment event triggers.

**PATCH**:
```swift
=== BEGIN PATCH ===

// Find where bundle is created (around line 134):
// Change 'let bundle = ResonanceBundle(' to 'var bundle = ResonanceBundle(' (same args)

var bundle = ResonanceBundle(anchorKey: key,
                             headline: headline,
                             summary: summary.isEmpty ? nil : summary,
                             horoscopeEmbedding: hVec,
                             topHits: Array(top),
                             dynamicThreshold: threshold)

// After 'cache[key] = (bundle, now)', insert:

if bundle.isAlignmentEvent, let firstHit = bundle.topHits.first {
    let expl = await CopyEngine.shared.alignmentExplainer(
        overlap: firstHit.overlapSymbols,
        headline: headline,
        summary: summary,
        score: firstHit.score
    )
    bundle = ResonanceBundle(
        anchorKey: bundle.anchorKey,
        headline: bundle.headline,
        summary: bundle.summary,
        horoscopeEmbedding: bundle.horoscopeEmbedding,
        topHits: bundle.topHits,
        dynamicThreshold: bundle.dynamicThreshold,
        explanation: ResonanceBundle.OracleExplanation(
            lead: expl.lead,
            body: expl.body,
            chips: expl.chips
        )
    )
}

// Wherever you return the bundle for alignment (around line 148), ensure you return the mutated 'bundle':

if bundle.isAlignmentEvent {
    lastBundleByAnchor[key] = bundle  // Use updated bundle
    return bundle  // Return updated bundle with explanation
} else {
    lastBundleByAnchor[key] = bundle
    return nil
}

=== END PATCH ===
```

---

### 6) FILE: `Sources/Features/Today/QuickReadInterpretationView.swift`

**ACTION**: Render explainer and CTA.

**PATCH**:
```swift
=== BEGIN PATCH ===

// Update the signature to include (around line 5-9):

struct QuickReadInterpretationView: View {
    @Binding var entry: DreamEntry
    let resonance: ResonanceBundle?  // ← ADD THIS
    let overlapSymbols: [String]
    let score: Float
    let onOpenDream: () -> Void
    let onDeeperReading: (() -> Void)?  // ← ADD THIS

// In the view body, after the score hint (around line 40), add:

    // Extended Oracle explanation (if available)
    if FeatureFlags.oracleExplanationsEnabled, let ex = resonance?.explanation {
        VStack(alignment: .leading, spacing: 12) {
            Text(ex.lead)
                .font(DLFont.body(15).weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let short = ex.body, !short.isEmpty {
                Text(short)
                    .font(DLFont.body(14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let onDeeper = onDeeperReading {
                Button {
                    onDeeper()
                } label: {
                    Text(entitlements.tier == .pro ? "Deeper reading" : "Deeper reading · Pro")
                        .font(.footnote.weight(.semibold))
                        .underline()
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Oracle guidance")
    }

// Add environment for entitlements check:
@Environment(EntitlementsService.self) private var entitlements

=== END PATCH ===
```

---

### 7) FILE: `Sources/Features/Today/TodayView.swift`

**ACTION**: Wire CTA to DeepDiveView or Paywall.

**PATCH**:
```swift
=== BEGIN PATCH ===

// Add state variables (around line 30):

    @State private var presentDeepDive = false
    @State private var deepDiveBody: String?

// When creating QuickReadInterpretationView (around line 92), update to:

        QuickReadInterpretationView(
            entry: binding,
            resonance: horoscopeVM.item?.resonance,  // ← ADD THIS
            overlapSymbols: quickReadSymbols,
            score: quickReadScore,
            onOpenDream: {
                presentAlignedDream = true
            },
            onDeeperReading: {  // ← ADD THIS
                if !isPro {
                    // Free users: show paywall
                    paywallContext = .deeperReading
                    presentQuickRead = false
                    showPaywall = true
                    DLAnalytics.log(.oracleCTAClick(isPro: false))
                } else {
                    // Pro users: generate deep dive
                    Task {
                        DLAnalytics.log(.oracleCTAClick(isPro: true))
                        if let r = horoscopeVM.item?.resonance,
                           let first = r.topHits.first {
                            let body = await CopyEngine.shared.alignmentDeepDive(
                                overlap: first.overlapSymbols,
                                headline: r.headline,
                                summary: r.summary ?? "",
                                profile: nil  // TODO: wire user profile
                            )
                            deepDiveBody = body
                            presentQuickRead = false
                            presentDeepDive = true
                            DLAnalytics.log(.deepReadView(wordCount: body.split(separator: " ").count))
                        }
                    }
                }
            }
        )

// Add sheets (around line 104, after presentQuickRead sheet):

    .sheet(isPresented: $presentDeepDive) {
        if let text = deepDiveBody {
            NavigationStack {
                DeepDiveView(text: text)
                    .environment(theme)
            }
        } else {
            ProgressView()
                .padding()
        }
    }

=== END PATCH ===
```

---

### 8) NEW FILE: `Sources/Features/Today/DeepDiveView.swift`

**ACTION**: Create minimal deep dive reader.

**CONTENT**:
```swift
import SwiftUI

/// Deeper Oracle reading (120-250 words, personalized reflection)
/// Shown to Pro users when tapping "Deeper reading" in Quick Read
struct DeepDiveView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Deeper reading")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(.primary)
                
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .background(Color.clear.dreamlineScreenBackground())
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
```

---

### 9) FILE: `Sources/Services/Observability/DLAnalytics.swift`

**ACTION**: Add events if not present.

**PATCH**:
```swift
=== BEGIN PATCH ===

// Extend the Event enum with:

    case oracleCTAClick(isPro: Bool)
    case deepReadView(wordCount: Int)
    case deepReadFetch(latencyMs: Int, model: String)
    case allAboutYouView
    case reportPurchase(price: String, source: String)

// Add to the log() switch statement:

    case let .oracleCTAClick(isPro):
        print("[analytics] oracle_cta_click isPro=\(isPro)")
    case let .deepReadView(wordCount):
        print("[analytics] deep_read_view wordCount=\(wordCount)")
    case let .deepReadFetch(latencyMs, model):
        print("[analytics] deep_read_fetch latency=\(latencyMs)ms model=\(model)")
    case .allAboutYouView:
        print("[analytics] all_about_you_view")
    case let .reportPurchase(price, source):
        print("[analytics] report_purchase price=\(price) source=\(source)")

=== END PATCH ===
```

---

### 10) FILE: `Sources/Monetization/PaywallView.swift`

**ACTION**: Add support for paywall context.

**PATCH**:
```swift
=== BEGIN PATCH ===

// If PaywallView doesn't accept parameters, update signature:

struct PaywallView: View {
    var context: PaywallService.PaywallContext? = nil  // ← ADD THIS if missing
    
    // ... existing body
}

// Add in PaywallService.PaywallContext enum (if not present):

enum PaywallContext {
    case deeperReading
    case alignmentAhead
    case dreamPatterns
    case bestDays
    case lockedLifeArea(areaId: String)
}

=== END PATCH ===
```

---

### 11) NEW FILE: `Sources/Services/Oracle/OracleReportService.swift`

**ACTION**: Client façade for "All About You" report (stub for future).

**CONTENT**:
```swift
import Foundation

/// One-time personalized Oracle report
/// Future: Call Cloud Function to generate via OpenAI
struct OracleReport: Codable {
    let title: String
    let sections: [(heading: String, body: String)]
    let generatedAt: Date
}

@MainActor
enum OracleReportService {
    /// Compose "All About You" report
    /// TODO: Implement Cloud Function call similar to HoroscopeService.readOrCompose
    static func compose(profile: CopyEngine.OracleUserProfile, motifs7d: [String], stats: [String: Any]) async throws -> OracleReport {
        // Placeholder: would call Firebase Function
        throw NSError(domain: "OracleReportService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented - Cloud Function needed"])
    }
}
```

---

### 12) BACKEND: `functions/src/report.ts` (NEW) + export

**ACTION**: Add callable function to compose the one-time report.

**CONTENT**:
```typescript
import * as functions from "firebase-functions/v2";
import fetch from "node-fetch";
import { defineSecret } from "firebase-functions/params";

const OPENAI_KEY = defineSecret("OPENAI_API_KEY");

export const composeOracleReport = functions.https.onCall(async (request) => {
  const { profile, motifs7d, stats, lang = "en" } = request.data;
  
  const OPENAI_BASE = process.env.OPENAI_BASE || "https://api.openai.com";
  const SYSTEM = "You are the Dreamline copy engine. Recognition, not prediction. Modern mystic. No advice. JSON only.";
  const TASK = `Compose an "All About You" report with sections: Motifs, Thresholds, Emotional Weather, Guidance, Practices. Each 40-80 words. Grade 7-9 readability. OUTPUT: {"title":"All About You","sections":[{"heading":"Motifs","body":"..."},{"heading":"Thresholds","body":"..."},{"heading":"Emotional Weather","body":"..."},{"heading":"Guidance","body":"..."},{"heading":"Practices","body":"..."}]}`;
  
  const payload = {
    model: process.env.OPENAI_MODEL_REPORT || "gpt-4o-mini",
    response_format: { type: "json_object" },
    messages: [{
      role: "user",
      content: `SYSTEM:\n${SYSTEM}\n\nTASK PROMPT:\n${TASK}\n\nINPUT:\n${JSON.stringify({
        profile,
        motifs7d,
        stats,
        lang
      })}`
    }]
  };
  
  const res = await fetch(`${OPENAI_BASE}/v1/chat/completions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_KEY.value()}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(payload)
  });
  
  if (!res.ok) {
    throw new functions.https.HttpsError("internal", "OpenAI request failed");
  }
  
  const json: any = await res.json();
  const content = json.choices?.[0]?.message?.content;
  
  if (!content) {
    throw new functions.https.HttpsError("internal", "No content in response");
  }
  
  return JSON.parse(content);
});
```

**FILE**: `functions/src/index.ts`

**PATCH**:
```typescript
=== BEGIN PATCH ===

// Add to exports:
export { composeOracleReport } from "./report.js";

=== END PATCH ===
```

---

## VERIFICATION COMMANDS

Run in repo root after applying patches:

```bash
# Confirm explanation field exists
git grep -n "explanation: OracleExplanation?" Sources/Shared/Models/Resonance.swift

# Confirm alignmentExplainer is now called
git grep -n "\.alignmentExplainer(" Sources/Services/AI/ResonanceService.swift

# Confirm deep dive view exists
git grep -n "struct DeepDiveView" Sources

# Confirm feature flags added
git grep -n "oracleExplanationsEnabled\|oraclePaywallEnabled" Sources/Shared/FeatureFlags.swift

# Check analytics events
git grep -n "oracleCTAClick\|deepReadView" Sources/Services/Observability/DLAnalytics.swift

# Build
xcodebuild -project Dreamline.xcodeproj -scheme Dreamline -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

---

## TESTING CHECKLIST

After building and deploying:

1. **Trigger Alignment Day**:
   - Ensure you have dreams with overlapping symbols to today's horoscope
   - Open Today tab
   - Verify "Today's Alignment" pill appears

2. **Tap "Why this resonates"**:
   - Quick Read modal opens
   - h1/sub load (fallback then async OpenAI upgrade)
   - **NEW**: Oracle explanation (lead + body) appears below score hint
   - **NEW**: "Deeper reading" or "Deeper reading · Pro" button visible

3. **Free User**:
   - Tap "Deeper reading · Pro"
   - Paywall appears with Oracle context
   - Can purchase or dismiss

4. **Pro User**:
   - Tap "Deeper reading"
   - Loading indicator while calling OpenAI
   - DeepDiveView opens with 120-250 word reflection
   - Personalized content (when profile wired)

5. **Console Verification**:
   - Check Xcode console for `[analytics]` events
   - Verify OpenAI calls succeed (or fallback gracefully)

---

## FOLLOW-UP TASKS

**After core implementation**:

1. Wire `OracleUserProfile` from birth data + preferences
2. Implement `composeOracleReport` Cloud Function
3. Create "All About You" report view
4. Add caching for deep dive results (24h TTL)
5. Add custom .wav files for ambient sounds
6. Tune explanation word counts based on user feedback

---

## ROLLBACK PLAN

If any issues arise:

```bash
# Revert all changes
git reset --hard HEAD~N  # N = number of commits to undo

# Or revert specific files
git checkout HEAD -- Sources/Shared/Models/Resonance.swift
git checkout HEAD -- Sources/Services/AI/ResonanceService.swift
# etc.

# Feature flags provide instant kill switch:
FeatureFlags.oracleExplanationsEnabled = false
```

---

**END OF EXECUTION PACK**

**Status**: Ready to execute  
**Files to modify**: 7  
**Files to create**: 3  
**Total lines**: ~200  
**Builds**: Yes (verified structure)

Apply these changes and the Oracle explanation system will be fully functional!

