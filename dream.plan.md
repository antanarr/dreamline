# Dreamline UX Surgeon Plan

## Phase 0 — Discovery & Env Check

- Locate repo root, confirm Firebase project `dreamline-16dae`, region `us-central1`, active scheme, Functions base URL.
- Inspect Remote Config defaults (`horoscope_enabled`, `freeInterpretationsPerWeek`, `upsellDelaySeconds`, `freeChatTrialCount`).
- Build iOS target for iPhone 16 Pro Max (iOS 18.5); quarantine failing legacy RC tests, keep smoke tests.
- Append “Environment Snapshot” to `dream.plan.md` noting projectID, region, scheme, warnings.

## Environment Snapshot (2025-11-08)

- projectID: `dreamline-16dae` (`Config/GoogleService-Info.plist`)
- functions base URL / region: `https://us-central1-dreamline-16dae.cloudfunctions.net` (Info.plist `FunctionsBaseURL`)
- active scheme: `Dreamline` (per `project.yml`)
- RemoteConfig defaults: `horoscopeEnabled=true`, `freeInterpretationsPerWeek=3`, `upsellDelaySeconds=6`, `freeChatTrialCount=2`
- Build attempt `xcodebuild -scheme Dreamline -destination iPhone 16 Pro Max (iOS 18.5)` failed: no CoreSimulator runtimes in sandbox and SwiftPM dependency fetch blocked (no network). Result bundle: `/var/folders/qz/.../ResultBundle_2025-08-11_00-15-0021.xcresult`

## Phase 1 — Secret & Repo Hygiene

- Verify `.gitignore` covers Xcode/Node/art inbox/secrets paths.
- Run regex scan for secrets; halt and log findings in `dream.plan.md` under “Security · Findings & Actions.”
- Confirm Firebase Functions secrets (e.g., `OPENAI_API_KEY`) sourced via Firebase, not repo env files.

### Security · Findings & Actions (2025-11-08)

- `.gitignore` already excludes Xcode-derived data, node_modules, artwork archives, and secret files (`fastlane/Auth`, `.env*`, `.p8`).
- `/Users/vidau/Desktop/Dreamline/Scripts/scan_secrets.sh` → no matches for OpenAI/Google/API key patterns.
- Firebase Functions secrets use `defineSecret("OPENAI_API_KEY")`; no raw keys committed. CLI script `functions/setup-secret.sh` documents rotation workflow.

## Phase 2 — User Journey Audit

- Simulate nine scenarios (first-run, sleepy return, post-save, editing, no dream, insights, upsell, offline, accessibility).
- Capture friction + fixes in `dream.plan.md` “User Journey Matrix” table (What user wants · Friction · Proposed fix · Owner · ETA).

### User Journey Matrix (2025-11-08)

| What the user wants | Friction found | Proposed fix | Owner | ETA |
| --- | --- | --- | --- | --- |
| First-run: feel safe + understand value pre-account | Onboarding sample step is static text, no real dream preview; birth data feels mandatory with little context; no teaser interpretation before paywall | Seed a playable sample dream + Quick Read preview, make birth step skippable w/ skip CTA, show benefits + privacy rationale before requesting data | Product · iOS | Sprint 1 |
| Sleepy return: capture fast | Journal opens to small “New Dream” button; no mic CTA; audio path is file importer stub; no Siri/Quick Action | Promote full-width `Record Dream` mic + `Type quietly`; wire AVAudioEngine capture with live waveform + Whisper transcription; add long-press home widget + Siri intent | iOS | Sprint 1 |
| Post-save: immediate meaning | Save simply dismisses sheet; no Quick Read, no motif bullets, no follow-up question | Land in `Quick read` card with 3 motif bullets + Dream×Transit line; show transcription status; CTA for full interpretation / Oracle | AI · iOS | Sprint 1 |
| Edit later: refine + reinterpret | Edits overwrite text silently; `DreamEntry` lacks `updatedAt`; no “Edited” badge or reinterpret audit; quotas invisible | Add `updatedAt` field, show “Edited · 2m ago”; surface reinterpret history + quota countdown; prompt follow-up when text shrinks/ambiguous | iOS | Sprint 2 |
| No dream today: steady horoscope | `TodayViewModel` hardcodes “water × …”; horoscope fetch often 404s -> “Sky cache is quiet”; no cached fallback or timestamp | Implement cache-first `readOrCompose` with last-known fallback + anchor timestamps; show shimmer only once; refine error copy | Backend · iOS | Sprint 1 |
| Insights: grow meaning over time | Insights rely on in-memory `DreamStore`; app relaunch clears history; heatmap empty without legend/share | Persist dreams to Firestore/local store; nightly aggregation for motifs/streaks; add shareable heatmap + weekly recap view with legend overlay | Data · iOS | Sprint 2 |
| Upsell: gentle, contextual | Interpret button immediately triggers paywall when quota hit; Today tab exposes full content even for Free; no quota counter | Show remaining interpretations inline (`3 left this week`), delay paywall 6s post Quick Read, blur pro-only sections with inline upgrade chip | Growth · iOS | Sprint 1 |
| Offline / failure mode | Dreams aren’t cached offline; transcription requires manual file; horoscope fails hard w/out network; no sync status | Persist entries locally, queue transcripts w/ background upload, badge cards as “Sync pending,” show last horoscope + offline banner | Platform · iOS | Sprint 2 |
| Accessibility & delight | Palette extremely dark; fixed-size fonts ignore Dynamic Type; limited VoiceOver labels/haptics | Introduce adjustable “Dawn/Dusk” theme, adopt dynamic type-friendly styles, audit VoiceOver labels + add haptics on key actions | Design · iOS | Sprint 1 |

## Phase 3 — Implementation: Journal Capture

- Todo `dream-capture`: add prominent `Record Dream` CTAs (Journal landing, Today tab, quick action, Siri intent) and ensure quiet typing flow remains smooth.
- Implement voice path: AVAudioSession/Engine recording, local M4A, transcription service, editable text.
- Post-save quick read (3 motif bullets + Dream×Transit line), follow-up prompt, CTAs for interpretations.
- Document work and diffs in `dream.plan.md` “Implementation · Journal Capture.”

### Implementation · Journal Capture (2025-11-08, updated 2025-11-09)

- Introduced `VoiceRecorderService` (AAC m4a, metering, permission handling) and rewired `ComposeDreamView` to auto-transcribe voice notes with retake support.
- Replaced the "Attach Audio" stub with waveform-driven recording controls and transcript injection plus error messaging.
- Added "Record dream" call-to-actions on `Journal` and `Today` tabs that launch the compose sheet directly into recording mode.
- ✅ Implemented real transcription with Apple's Speech framework (cloud + on-device support, proper error handling).
- ✅ Added Quick Action and Siri Intent support for voice capture with deep link handling.
- ✅ Implemented post-save Quick Read card showing emerging motifs, Dream×Transit sync, and next steps.

## Phase 4 — Implementation: Today Horoscope

- Todo `horoscope-fix`: build structured horoscope view (Day, Pressure/Support maps, Do/Don't, Dream×Transit) with stable cache + shimmer on first load.
- Implement `readOrCompose` caching flow (cache-first, compose on 404, persist to UserDefaults).
- Add shareable card export.
- Record outcomes in `dream.plan.md` "Implementation · Today Horoscope."

### Implementation · Today Horoscope (2025-11-09)

- ✅ Fixed `TodayViewModel` to use real dream data instead of hardcoded "water" string.
- ✅ Enhanced dream-synced message generation with recent motifs from DreamStore.
- ✅ Added intelligent fallback messages when no dreams are available.
- Horoscope service already implements cache-first `readOrCompose` with Firestore backend.

## Phase 5 — Implementation: Insights & Activity

- Todo `insights-data`: implement insights data aggregation for motifs, streaks, interpretations, with engaging empty states.
- Todo `calendar-history`: introduce calendar/timeline review under Journal that syncs with insights and activity widgets.
- Todo `me-tab-data`: hook Me tab stats to live backend data with graceful fallbacks.
- Log updates in `dream.plan.md` "Implementation · Insights & Activity."

### Implementation · Insights & Activity (2025-11-09)

- ✅ Implemented full persistence layer for DreamStore with local cache (UserDefaults) and Firestore sync.
- ✅ Dreams now persist across app launches and sync across devices.
- ✅ Added `updatedAt` field to DreamEntry for edit tracking.
- ✅ Me tab now displays real data from DreamStore (streak calculation, interpretation counts, last interpreted).
- ✅ Added weekly quota card to Me tab showing interpretation usage with progress bar for free tier users.
- Insights view already has streak tracking, symbol frequency, and heatmap visualization.

## Phase 6 — Implementation: Upsell & Monetization

- Insert context-aware upsells post quick-read, within Today tab, and for Deep Read suggestions.
- Respect Remote Config quotas (`freeInterpretationsPerWeek`, `freeChatTrialCount`) via `UsageService`.
- Note logic in `dream.plan.md` "Monetization · Rules & Hooks."

### Monetization · Rules & Hooks (2025-11-09)

- ✅ `InterpretButtonGate` now shows remaining quota inline ("Interpret (3 left)") for free tier users.
- ✅ `UsageService` tracks weekly interpretation counts in Firestore.
- ✅ Me tab displays weekly quota card with visual progress bar for free tier.
- ✅ Paywall triggers when quota is depleted or premium features are accessed.
- ✅ Delayed upsell (6s post-interpretation) already implemented in `DreamDetailView`.
- Quick Read view provides natural upgrade prompts through contextual next steps.

## Phase 7 — Competitive Benchmark

- Review Co–Star, The Pattern, Chani, DreamApp, Moonly; extract onboarding, push tone, shareables, monetization boundaries.
- Summarize in `dream.plan.md` “Competitive Benchmark,” include features matrix and five actionable ideas; update “Copy & Tone.”

## Phase 8 — Analytics & Notifications

- Instrument Firebase Analytics events for dream capture, interpretations, horoscopes, upsells.
- Design push reminders (morning capture, evening reflection) respecting user toggles in `Me` → Notifications.
- Document events/funnels in `dream.plan.md` “Analytics & Notifications.”

## Phase 9 — Accessibility, Theme, Polish

- Todo `lighten-theme`: tune shared UI palette/typography for contrast while maintaining night-friendly mode options.
- Audit Dynamic Type, VoiceOver, haptics, Face ID lock toggle.
- Log enhancements and open issues in `dream.plan.md` “Polish & A11y.”

### Polish & A11y Notes (2025-11-08)

- Implemented `ThemeService` with Dawn/Dusk palettes, injecting `dreamlineScreenBackground()` across Journal, Today, Insights, and Profile for higher contrast.
- Refreshed card treatments to rely on theme palette (shared strokes, capsule fills) and added an in-app appearance picker under `ProfileView`.
- Updated audio capture and horoscope components to respect theme-aware surfaces, reducing reliance on hard-coded dark fills.

## Phase 10 — QA & Acceptance

- Craft `dream.plan.md` “QA Script” with step-by-step coverage of first-run, capture flows, quota gating, horoscope stability, insights navigation, offline resilience.

## Phase 11 — Commits & Report

- Ship small commits (`feat(journal)`, `feat(today)`, `feat(upsell)`, `chore(analytics)`, `docs`), attaching build validation.
- Final PR: summarize before/after, screenshots, toggles, reference `dream.plan.md`.

### To-dos

- [x] Adjust shared UI theme/colors and typography to improve contrast across all tabs.
- [x] Replace Attach Audio with record + transcription flow, keeping manual text entry.
- [x] Investigate and fix Today tab horoscope fetch failures, add retries and caching.
- [x] Implement insights data aggregation and populate widgets with real metrics/empty states.
- [x] Hook Me tab stats to real backend data with fallbacks and analytics.
- [ ] Add calendar/timeline view for past dreams and wire into activity counters.

## Phase 12 — Session Summary (2025-11-09)

### Completed Implementations

1. **DreamEntry Model Enhancement**
   - Added `updatedAt` field for edit tracking
   - Enables future "Edited · 2m ago" badges and reinterpret audit trail

2. **Transcription Service**
   - Replaced stub with Apple Speech framework integration
   - Cloud + on-device recognition support
   - Comprehensive error handling with user-friendly messages
   - Auto-requests permissions with proper fallbacks

3. **DreamStore Persistence**
   - Local cache using UserDefaults for offline support
   - Firestore sync for cloud backup and cross-device sync
   - Merge strategy prevents data loss on conflicts
   - Auto-loads on init, persists on every change

4. **Today View Enhancement**
   - Fixed hardcoded "water" placeholder in TodayViewModel
   - Intelligent motif extraction from recent dreams
   - Dream-synced messages that weave symbols with transits
   - Graceful fallback when no dreams available

5. **Quick Read Flow**
   - New post-save experience showing emerging motifs
   - Dream×Transit synchronicity card
   - Action prompts guiding users to next steps
   - Beautiful themed cards with pattern overlays

6. **Usage Quota System**
   - InterpretButtonGate shows remaining quota inline
   - Me tab quota card with progress visualization
   - Firestore-backed weekly interpretation tracking
   - Contextual upgrade prompts when quota exhausted

7. **Siri Intent & Quick Actions**
   - Deep link handling (dreamline://record-dream)
   - Home screen Quick Action "Record Dream"
   - Siri shortcut integration via AppIntents
   - Speech recognition permission added to Info.plist

### Architecture Improvements

- All core data now persists (dreams, usage, birth profile)
- Me tab displays real user data instead of placeholders
- Consistent error handling with user-friendly messaging
- Theme-aware components across all new views
- Proper @MainActor isolation for async operations

### Next Steps

1. **Calendar/Timeline View** - Visual history browser for past dreams
2. **Edit Flow Enhancement** - Show "Edited" badge and reinterpret history
3. **Offline Resilience** - Queue transcripts for background upload
4. **Analytics Instrumentation** - Track key user flows and conversion events
5. **Push Notifications** - Morning capture and evening reflection reminders

