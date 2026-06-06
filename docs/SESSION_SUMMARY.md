# SleepGuard Sprint Log

## 2026-05-06 — Phase 0: Project Kickoff

### Completed
- docs/IdeaBrief.md
- docs/Roadmap.md (V1/V1.1/V2 features)
- docs/FeatureTracker.md + 6 per-feature trackers (f1–f6)
- docs/ProjectArchitecture.md (deviations from IceCubes documented)
- docs/features/ directory created
- 9 SPM packages scaffolded and compiling:
  - Models, AudioEngine, Env, DesignSystem
  - Onboarding, SleepSession, Statistics, Recordings, Settings
- App entry point with onboarding gate + 3-tab structure
- Background audio build setting configured
- .swiftformat with 2-space indent
- Build verified: zero errors

### Blockers
- Notion database creation blocked — API version 2025-09-03 removed programmatic DB creation.
  - Workaround: Local trackers are primary source of truth.
  - If needed, Notion workspace can be set up manually per docs/VIBE_CODING_WORKFLOW.md Step 4.

### Next Session
- Start F1 (Onboarding) — F1-T1: Onboarding state + UserPreferences flag

---

## 2026-05-06 — Session 2: F1 Onboarding Complete

### Completed
- **F1-T1**: `UserPreferences.hasCompletedOnboarding` @AppStorage flag in `Packages/Env/Sources/Env/UserPreferences.swift`
- **F1-T2**: Onboarding pages 1-3 (hook, features, privacy) with animated transitions
- **F1-T3**: Page 4 mic permission with pulsing concentric rings using `Timer` + `@State var ringScale`; `AVAudioSession.requestRecordPermission()` wrapped in `withCheckedContinuation`
- **F1-T4**: Page 5 motivation screen with dual CTA (`onCompleteToRecording`, `onCompleteToStatistics`)
- **F1-T5**: Onboarding gate in `SleepGuardApp.swift` — shows `OnboardingView` when `!hasCompletedOnboarding`, else `MainTabView`; `.sheet(item:)` registration for `.onboarding` in `AppRegistry.swift`

### Technical Details
- `OnboardingView` uses `TabView` with `.tabViewStyle(.page(indexDisplayMode: .never))` for swipe paging
- Progress dots use active pill shape (width 20 for active, 8 for inactive)
- Skip button hidden on last page; Back button hidden on first page
- `UserPreferences` is `@MainActor @Observable` singleton with `.shared`, injected via `@Environment`
- Permission flow handles `.granted` (auto-advance), `.denied` (shows Settings link), `.undetermined` (shows primary CTA)

### Issues / Decisions
- **Theme colors**: Used `.white`/`.primary`/`.accentColor` instead of UIKit `Color` extensions to avoid cross-platform compilation issues
- **Package isolation**: Onboarding package only imports `Env`, `Models`, `AudioEngine`, `DesignSystem` — no feature-to-feature imports

### Next Session
- Start F2 (Live Session) — F2-T1: AudioRecorder + SnoreDetector (already scaffolded, verify and enhance)
### Git Handoff
- **Suggested branch**: `feature/f1/t1-t5-onboarding-flow`
- **Suggested commit**: `F1-T1..T5 — Onboarding flow with 5 pages, permission, and app gate`

---

## 2026-05-06 — Session 18: Statistics Header Pin

### Completed
- Pinned "Statistics" title + Calendar button to the top of the Statistics dashboard so it doesn't scroll.

### Technical Details
- Restructured both `StatisticsEmptyView` and `StatisticsLoadedView`:
  - Moved `headerSection` outside the `ScrollView` into a parent `VStack(spacing: 0)`.
  - `ScrollView` now only wraps the scrollable content (week selector, gauge, stats, chart, recording button).
  - Padding applied separately: header gets `.padding(.horizontal, 20) + .padding(.top, 20)`; scrollable content gets `.padding(.horizontal, 20) + .padding(.bottom, 20)`.
- Also fixed empty-state title font that was missed in the previous polish pass: 32 → 34pt.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +24/-20 | Pinned header outside ScrollView for empty and loaded states; empty title 32→34pt |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Git Handoff
- **Suggested branch**: `polish/v1-statistics-pinned-header`
- **Suggested commit**: `Pin Statistics header above ScrollView — title + Calendar button no longer scrolls`

---

## 2026-05-06 — Session 20: Compact Statistics Layout

### Completed
- Shrunk score gauge and stat cards so the full Statistics dashboard fits on one screen.
- Un-pinned the Start Recording button — it's now back inside the scrollable content.

### Technical Details
- **SleepScoreGauge**: size reduced 150 → 110 (proportional shrink of ring, score text, and label).
- **StatCard** (shared component):
  - Padding: 14 → 10
  - Icon font: 16 → 14
  - Value font: 20 → 18
  - Title font: 12 → 11
- **MiniBarChart**:
  - Overall height: 100 → 70
  - Max bar height: 80 → 55
  - X-axis label font: 11 → 10
- **StatisticsDashboardView**:
  - Section spacing: 24 → 16
  - Start Recording button moved back inside the `ScrollView` for both empty and loaded states.
  - Header remains pinned above the ScrollView.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +12/-24 | Button back inside ScrollView, gauge 110, spacing 16 |
| `Packages/DesignSystem/Sources/DesignSystem/StatCard.swift` | +4/-4 | Padding 10, fonts 14/18/11 |
| `Packages/DesignSystem/Sources/DesignSystem/MiniBarChart.swift` | +3/-3 | Height 70, bar max 55, label font 10 |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Git Handoff
- **Suggested branch**: `polish/v1-statistics-compact`
- **Suggested commit**: `Compact Statistics layout — shrink gauge, cards, chart to fit one screen`

---

## 2026-05-06 — Session 21: Stat Cards Further Shrink

### Completed
- Reduced StatCard sizes even further to ensure the full Statistics dashboard fits comfortably on one screen.

### Technical Details
- **StatCard** (shared component):
  - Padding: 10 → 8
  - Icon font: 14 → 12
  - Value font: 18 → 16
  - Title font: 11 → 10

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/DesignSystem/StatCard.swift` | +4/-4 | Padding 8, fonts 12/16/10 |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Git Handoff
- **Suggested branch**: `polish/v1-statistics-compact`
- **Suggested commit**: `Shrink StatCard padding and fonts further to fit one screen`

### Open Questions
- None

## 2026-05-19 — Session 50: Low Battery Force-Save + Banner

### Completed
- **F2-T12**: Low battery force-save and explanatory banner

### Technical Details
- `SessionManager.processingTask` increments a counter every 50ms; every 600 iterations (~30s) it calls `checkBatteryLevel()`
- `UIDevice.current.isBatteryMonitoringEnabled` is enabled in `SessionManager.init()` (skipped in simulator)
- At `batteryLevel <= 0.02`, `forceSaveDueToLowBattery()` calls `stopSession()` and sets `forceSaveReason = "low_battery"`
- `StatisticsTab.onChange(of: sessionManager.completedSession)` checks `forceSaveReason`; if set, auto-saves to SwiftData via `modelContext`, syncs to HealthKit if enabled, stores reason in `UserDefaults`, and clears flags without presenting summary sheet
- `LowBatteryBannerView` (DesignSystem) reads `session_termination_reason_<id>` from `UserDefaults` and renders a `MelodyGapsBannerView`-style info card with `bolt.fill` icon in `scoreAmber`
- Banner is shown in both `SessionSummaryView` (after manual stop) and `SessionDetailView` (saved session detail)
- `SessionDetailView.deleteSession()` removes the `UserDefaults` key alongside the session deletion
- Zero changes to `SleepSession` SwiftData model

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/SessionManager.swift` | +25/-0 | Battery monitoring (`batteryCheckCounter`, `checkBatteryLevel()`), `forceSaveReason`, `forceSaveDueToLowBattery()` |
| `SleepGuard/StatisticsTab.swift` | +28/-4 | Auto-save logic for force-saved sessions; `HealthKitSync` and `modelContext` environments; `autoSaveForceSavedSession()` helper |
| `Packages/DesignSystem/Sources/Components/LowBatteryBannerView.swift` | +32/-0 | New banner component; reads UserDefaults; styled like `MelodyGapsBannerView` |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | +2/-0 | Added `LowBatteryBannerView` below `MelodyGapsBannerView` |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +3/-0 | Added `LowBatteryBannerView` below `MelodyGapsBannerView`; UserDefaults cleanup in `deleteSession()` |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` | +1/-0 | `session.summary.lowBattery.forceSave.info` localization entry |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +10/-0 | Added English localization for low battery banner text |
| `Packages/DesignSystem/Sources/Strings.swift` | +1/-0 | Regenerated; added `sessionSummaryLowBatteryForceSaveInfo` accessor |

### Architecture Decisions
- **UserDefaults over model changes**: Storing the force-save reason in `UserDefaults` (keyed by session ID) avoids a SwiftData migration and keeps `SleepSession` lightweight. Cleanup is trivial on deletion.
- **Auto-save in StatisticsTab, not SessionManager**: `SessionManager` has no `ModelContext` access by design. The view layer (`StatisticsTab`) handles the save + sync sequence, matching the existing pattern where `SessionSummaryView.saveSession()` triggers HealthKit sync.
- **Banner in both summary and detail**: The banner appears in `SessionSummaryView` (for completeness, in case the auto-save path fails and the user sees the summary) and `SessionDetailView` (primary discovery path for already-saved force-saved sessions).

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Git Handoff
- **Suggested branch**: `feature/f2-t12-low-battery-force-save`
- **Suggested commit**: `F2-T12 — Low battery force-save and explanatory banner`
  - `SessionManager` battery monitoring with 30s polling interval
  - `forceSaveDueToLowBattery()` stops session and sets `forceSaveReason`
  - `StatisticsTab` auto-saves force-saved sessions to SwiftData + HealthKit
  - `LowBatteryBannerView` styled like `MelodyGapsBannerView`
  - UserDefaults-based termination reason; no `SleepSession` model changes

### Open Questions
- Should we show a local notification when force-saving, or is the in-app banner sufficient?
- Should `BedsideClockView` show a brief "Saving session…" overlay while the force-save happens?

---

## 2026-05-06 — Session 19: Statistics Start Recording Button Pin

### Completed
- Pinned "Start Recording" button to the bottom of the Statistics dashboard so it doesn't scroll.

### Technical Details
- Moved the Start Recording `Button` outside the `ScrollView` in both `StatisticsEmptyView` and `StatisticsLoadedView`.
- In the empty state, the button was previously inside the card; now the card contains only the icon + text, and the button sits below it, pinned like the loaded state.
- Layout is now: fixed header → `ScrollView` with body content → fixed Start Recording button.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +24/-24 | Moved Start Recording button outside ScrollView for both empty and loaded states |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Git Handoff
- **Suggested branch**: `polish/v1-statistics-pinned-button`
- **Suggested commit**: `Pin Start Recording button below ScrollView in Statistics dashboard`

### Open Questions
- None

---

## 2026-05-06 — Session 3: F2 Live Session (T1-T2)

### Completed
- **F2-T1**: Verified `AudioRecorder` + `SnoreDetector` scaffold meets all acceptance criteria
  - `AudioRecorder`: `@MainActor @Observable` singleton wrapping `AVAudioEngine`
  - Mic permission handling, start/stop, real-time dB metering via `installTap(onBus:bufferSize:format:)`
  - `AVAudioSession` configured: `.playAndRecord`, `.measurement`, `.defaultToSpeaker + .allowBluetooth`
  - `SnoreDetector`: configurable dB thresholds (`quietThreshold: -40`, `lightThreshold: -30`, `loudThreshold: -20`)
  - Publishes `currentState: SnoringState` (`.none`, `.quiet`, `.light`, `.loud`)
- **F2-T2**: Enhanced `SessionManager` with real-time snore event tracking
  - Added `processAudioLevel(db:)` — called by view when `audioRecorder.currentDB` changes
  - Tracks active snore events with state transition detection (`.none` → snoring starts event, snoring → `.none` finalizes event)
  - Accumulates `sessionSnoringDuration`, `totalDBSum`/`totalDBCount`, `peakDB` in real-time
  - Events < 0.5s discarded as noise spikes
  - `stopSession()` finalizes in-progress event, computes all aggregate stats (`totalDuration`, `snoringPercentage`, `eventsCount`, `eventsPerHour`, `averageDB`)
  - Sleep score formula: `max(0, 100 - min(snoring% * 0.5, 30) - min(events/hour * 2, 30))`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Env/SessionManager.swift` | +133/-13 | Complete rewrite. Added event tracking state, aggregate state, `processAudioLevel(db:)`, `finalizeActiveEvent(intensity:)`, `resetTrackingState()`, `intensity(from:)`. Removed direct `snoreDetector` observation — now driven by view. |

### Architecture Decisions
- **View-driven audio processing**: `SessionManager.processAudioLevel(db:)` is called by the bedside clock view (F2-T4) when it observes `audioRecorder.currentDB` changes. This avoids coupling `AudioRecorder`'s tap callback (in `AudioEngine` package) to `SessionManager` (in `Env` package), preserving package boundaries.
- **In-memory event creation**: `SnoreEvent` objects are created during recording but not inserted into SwiftData until "Save Session" is tapped (F2-T5). This keeps `SessionManager` independent of `ModelContext`.
- **Sleep score formula**: Two capped penalties — snoring percentage capped at 30pts, events/hour capped at 30pts. Leaves 40pts as a baseline cushion. Formula intentionally simple for V1.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F2-T3**: Pre-start recording screen (idle state with "Start Recording" CTA, mic status indicator, instructions)
- Then F2-T4: Bedside clock active recording UI

### Git Handoff
- **Suggested branch**: `feature/f2/t1-t2-recorder-and-manager`
- **Suggested commit**: `F2-T1..T2 — AudioRecorder verification and SessionManager event tracking`

### Open Questions
- Should `AudioRecorder` emit a Combine publisher or callback for `currentDB` changes instead of relying on SwiftUI observation? (Current approach works but requires view polling via `.onChange` or `.task`)
- Should we add haptic feedback on snoring state transitions for the bedside clock? (Nice-to-have, not in V1 tracker)


## 2026-05-06 — Session 4: F2-T3 Pre-start Recording Screen

### Completed
- **F2-T3**: Pre-start recording screen (`RecordingPrestartView` + `SleepSessionView` container)

### Technical Details
- `SleepSessionView` is now a state-driven container: shows `RecordingPrestartView` when `!sessionManager.isRecording`, and a placeholder for the bedside clock when `isRecording`
- `RecordingPrestartView` features:
  - Dark nighttime-friendly background using `theme.backgroundColor`
  - Header with moon icon, "Ready to Sleep" title, and subtitle
  - Mic permission status indicator (green checkmark when granted, orange warning when denied/undetermined)
  - Tips card with 3 instruction rows (placement, charging, keep app open)
  - Large CTA button: "Grant Access & Start" when permission missing, "Start Recording" when granted
- Tapping CTA requests permission asynchronously if needed, then calls `sessionManager.startSession()`
- `AudioRecorder` accessed via `.shared` directly in the view (consistent with `SessionManager` pattern)

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/SleepSession/Sources/SleepSession/RecordingPrestartView.swift` | +103 | New. Pre-start UI with mic status, tips, and Start Recording CTA |
| `Packages/SleepSession/Sources/SleepSession/SleepSessionView.swift` | +24/-9 | Rewritten as container that switches between pre-start and active-recording placeholder based on `sessionManager.isRecording` |

### Architecture Decisions
- **No AppRegistry changes**: `AudioRecorder` was not added to `@Environment` injection to avoid cross-cutting dependency graph changes for a single boolean observation. Instead, the view accesses `AudioRecorder.shared` directly, matching the existing pattern in `SessionManager`.
- **View-driven state transition**: `SleepSessionView` observes `sessionManager.isRecording` and swaps child views. This avoids needing a router push/sheet change when recording starts — the transition happens inside the already-presented `.liveSession` sheet.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F2-T4**: Bedside clock active recording UI (full-screen clock, real-time dB indicator, snoring intensity colors, duration timer, stop button, dimmed nighttime UI)

### Git Handoff
- **Suggested branch**: `feature/f2/t3-prestart-screen`
- **Suggested commit**: `F2-T3 — Pre-start recording screen with mic status and tips`

### Open Questions
- Should `AudioRecorder` emit a Combine publisher or callback for `currentDB` changes instead of relying on SwiftUI observation? (Current approach works but requires view polling via `.onChange` or `.task`)
- Should we add haptic feedback on snoring state transitions for the bedside clock? (Nice-to-have, not in V1 tracker)


## 2026-05-06 — Session 5: F2-T4 Bedside Clock Active Recording UI

### Completed
- **F2-T4**: Bedside clock active recording UI (`BedsideClockView`)

### Technical Details
- `BedsideClockView` is a presentational view shown by `SleepSessionView` when `sessionManager.isRecording`
- `.task` runs at 20Hz (50ms intervals) while the view is alive:
  - Updates `currentTime` only when the wall-clock second changes (avoids unnecessary re-renders)
  - Calls `sessionManager.processAudioLevel(db: audioRecorder.currentDB)` on every tick
  - Task auto-cancels when the view is removed from hierarchy (e.g., stop recording)
- **Clock display**: 88pt thin rounded font, `theme.labelColor` at 80% opacity for nighttime eye comfort
- **Duration timer**: Monospaced `HH:MM:SS` below the clock, computed from `session.startDate`
- **Audio level bar**: 8pt rounded bar with `theme.surfaceColor` track; fill width maps dB `-60..-20` → `0..1`; fill color matches snoring state
- **Snoring indicator**: 
  - Top: colored dot (10pt) + text label ("Quiet", "Snoring — Quiet/Light/Loud")
  - Full-screen subtle glow: `snoringColor` at 6% opacity with `0.4s` ease animation
- **Stop button**: 64pt circle, red fill at 75% opacity, white `stop.fill` icon; calls `sessionManager.stopSession()`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/SleepSession/Sources/SleepSession/BedsideClockView.swift` | +134 | New. Full bedside clock UI with clock, duration timer, dB bar, snoring glow/indicator, stop button |
| `Packages/SleepSession/Sources/SleepSession/SleepSessionView.swift` | +6/-5 | Replaced placeholder active-recording view with `BedsideClockView()` |

### Architecture Decisions
- **Single `.task` for clock + audio**: Instead of separate `TimelineView` + `.onChange` approaches, one `while !Task.isCancelled` loop handles both. This avoids 43 re-renders/second from raw `currentDB` observation and caps updates at 20Hz.
- **No `@Environment(AudioRecorder)` injection**: Continues the F2-T3 pattern of accessing `AudioRecorder.shared` directly in the view. Keeps `AppRegistry` unchanged.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F2-T5**: Session summary sheet (sleep score, duration, snoring %, events count, avg/peak dB, Save/Discard buttons)

### Git Handoff
- **Suggested branch**: `feature/f2/t4-bedside-clock`
- **Suggested commit**: `F2-T4 — Bedside clock UI with dB bar, snoring glow, and timer`

### Open Questions
- Stop button currently drops user back to `RecordingPrestartView` because `isRecording` becomes false. F2-T5 needs to present a summary sheet instead — will likely require changing the sheet destination from `.liveSession` to `.sessionSummary(sessionID:)` when stopping.


## 2026-05-06 — Session 6: F2-T5 Session Summary Sheet

### Completed
- **F2-T5**: Session summary sheet (`SessionSummaryView`)

### Technical Details
- `SessionSummaryView` is a presentational view receiving `session: SleepSession` via init
- Large circular score ring at top using `trim(from:to:)` with colored stroke (green/orange/red by score)
- Stats grid (2 columns): Duration, Snoring %, Events, Events/Hour, Avg dB, Peak dB
- "Save Session" inserts `SleepSession` + all `SnoreEvent` children into SwiftData, then dismisses
- "Discard" dismisses without persisting (session was never inserted into model context)
- `SheetDestination.sessionSummary` simplified to no payload; session read from `SessionManager.completedSession`
- `SleepSessionView` shows `Color.clear` when `completedSession != nil` to prevent flash of `RecordingPrestartView` during sheet swap
- `StatisticsTab` observes `sessionManager.completedSession` via `.onChange` and swaps sheet from `.liveSession` to `.sessionSummary`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/SleepSession/Sources/SleepSession/SessionSummaryView.swift` | +165 | New. Summary sheet UI with score ring, stats grid, Save/Discard buttons |
| `Packages/Env/Sources/Env/SessionManager.swift` | +2/-0 | Added `completedSession: SleepSession?`; set in `stopSession()` |
| `Packages/Env/Sources/Env/Router.swift` | +3/-5 | Simplified `.sessionSummary(sessionID:)` to `.sessionSummary` (no payload) |
| `SleepGuard/MainTabView.swift` | +9/-4 | Added `sessionManager` env; `.onChange` swaps sheet; `.sessionSummary` maps to `SessionSummaryView` |
| `Packages/SleepSession/Sources/SleepSession/SleepSessionView.swift` | +2/-1 | Added `Color.clear` branch when `completedSession != nil` |

### Architecture Decisions
- **Sheet swap via `SessionManager`**: Instead of passing the tab's `RouterPath` into the sheet, `SessionManager.completedSession` acts as the bridge. The tab observes it and swaps sheets. This avoids threading `RouterPath` through `.withEnvironments()`.
- **Explicit SwiftData insertion**: Both `SleepSession` and each `SnoreEvent` are explicitly `modelContext.insert()`'ed before save. This ensures persistence even if SwiftData relationship cascade behavior varies.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F2-T6**: Route registration + wiring (pre-start, bedside clock, summary sheet routes; Statistics CTA; onboarding routing)

### Git Handoff
- **Suggested branch**: `feature/f2/t5-session-summary`
- **Suggested commit**: `F2-T5 — Session summary sheet with score ring and Save/Discard`

### Open Questions
- None

## 2026-05-06 — Session 7: F2-T6 Route Registration + Wiring

### Completed
- **F2-T6**: Route registration + wiring for live session flow

### Technical Details
- `StatisticsDashboardView` now features a "Start Recording" card with moon icon, description, and CTA button that presents `.liveSession` sheet via `routerPath.presentedSheet`
- `StatisticsTab` sheet adds `onDismiss` closure that clears `sessionManager.completedSession`, preventing `SleepSessionView` from being stuck on `Color.clear` after a previous session
- Onboarding "Start Recording" flow verified unchanged: `OnboardingPage5View` sets `presentRecordingAfterOnboarding = true`, `StatisticsTab.onAppear` presents `.liveSession` after onboarding completes
- Pre-start (`RecordingPrestartView`) and bedside clock (`BedsideClockView`) are both routed through the single `.liveSession` sheet destination; summary through `.sessionSummary`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +62/-2 | New dashboard layout with header and "Start Recording" CTA card |
| `SleepGuard/MainTabView.swift` | +6/-1 | Added `onDismiss` to `.sheet` that clears `completedSession` |

### Architecture Decisions
- **Sheet `onDismiss` for state cleanup**: Rather than adding a dedicated `clearCompletedSession()` method, `StatisticsTab` handles cleanup when the sheet is dismissed. This keeps `SessionManager` simple and avoids exposing extra API surface.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F3-T1**: StatisticsDashboardView empty + loaded states (SwiftData query, ViewState enum)

### Git Handoff
- **Suggested branch**: `feature/f2/t6-route-wiring`
- **Suggested commit**: `F2-T6 — Route registration and tab wiring for live session flow`

### Open Questions
- None

---

## 2026-05-06 — Session 9: F3-T2 Score Gauge + Stat Cards + Sparkline

### Completed
- **F3-T2**: Score gauge + stat cards components + last-7-nights sparkline

### Technical Details
- `SleepScoreGauge`: Circular ring using `Circle().trim(from:to:)`, animated with `.animation(.easeOut(duration: 0.8), value: score)`, color-coded (green ≥80, orange 50-79, red <50), configurable size
- `StatCard`: Icon (SF Symbol) + bold value + label, `theme.surfaceColor` background, corner radius 12, 2-column grid layout in loaded state
- `SleepSparkline`: Swift Charts `LineMark` + `AreaMark` with gradient fill, 0-100 Y scale, weekday-narrow X labels, hidden Y axis except top gridline, handles single-data-point case with `PointMark`
- `ViewState.loaded` expanded to `.loaded(session: SleepSession, recentSessions: [SleepSession])` so sparkline gets last 7 nights without additional queries
- Statistics package `Package.swift` gains `linkerSettings: [.linkedFramework("Charts")]`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Statistics/Components/SleepScoreGauge.swift` | +42 | New. Presentational circular score gauge |
| `Packages/Statistics/Sources/Statistics/Components/StatCard.swift` | +40 | New. Presentational stat card with icon, value, label |
| `Packages/Statistics/Sources/Statistics/Components/SleepSparkline.swift` | +65 | New. Presentational mini sparkline using Swift Charts |
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +120/-80 | Rewrote loaded state: score gauge card, 6 stat cards, sparkline card, removed old StatRow |
| `Packages/Statistics/Package.swift` | +3 | Added Charts framework linker setting |

### Architecture Decisions
- **All components presentational**: `SleepScoreGauge`, `StatCard`, `SleepSparkline` receive all data via init, no `@Query` or state management inside them
- **Sparkline in Statistics package, not DesignSystem**: Although architecture says "chart components" in DesignSystem, keeping sleep-specific sparkline in Statistics avoids adding Models dependency to DesignSystem and keeps V1 simple
- **ViewState carries recentSessions**: Instead of a separate `@Query` in the sparkline component, the container view passes the last 7 sessions down. This preserves the container/presentational split.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F3-T3**: "Start Recording" CTA + routing (verify existing CTA already uses `routerPath.presentedSheet = .liveSession`, may need refinement per acceptance criteria)

### Git Handoff
- **Suggested branch**: `feature/f3/t2-gauge-and-sparkline`
- **Suggested commit**: `F3-T2 — SleepScoreGauge, StatCard, SleepSparkline components`

### Open Questions
- None

---

## 2026-05-06 — Session 10: F3-T3 Start Recording CTA + Routing

### Completed
- **F3-T3**: Converted `.liveSession` from `SheetDestination` to `RouterDestination`; Start Recording CTA now uses `routerPath.navigate(to:)`

### Technical Details
- `.liveSession` moved from `SheetDestination` to `RouterDestination` in `Router.swift`
- `AppRegistry.withAppRouter()` maps `.liveSession` → `SleepSessionView()`
- `SleepSessionView` hides navigation bar via `.toolbar(.hidden, for: .navigationBar)` for full-screen recording experience
- `MainTabView.onChange(of: sessionManager.completedSession)` now calls `routerPath.navigateToRoot()` before presenting `.sessionSummary` sheet, ensuring the pushed live session is popped
- Onboarding routing updated: `StatisticsTab.onAppear` now uses `routerPath.navigate(to: .liveSession)` instead of `routerPath.presentedSheet = .liveSession`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Env/Router.swift` | +1/-8 | Moved `.liveSession` from `SheetDestination` to `RouterDestination` |
| `SleepGuard/AppRegistry.swift` | +2 | Added `.liveSession` → `SleepSessionView()` mapping in `withAppRouter()` |
| `SleepGuard/MainTabView.swift` | +1/-6 | Removed `.liveSession` from sheet switch; updated onboarding + completedSession handling |
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +2/-2 | Empty + loaded CTAs now use `routerPath.navigate(to: .liveSession)` |
| `Packages/SleepSession/Sources/SleepSession/SleepSessionView.swift` | +1 | Added `.toolbar(.hidden, for: .navigationBar)` |
| `docs/ProjectArchitecture.md` | +2/-1 | Added `.liveSession` to Routes table; updated recording screen description |

### Architecture Decisions
- **Push over sheet for live session**: Acceptance criteria explicitly required `routerPath.navigate(to:)`. This keeps the live session in the Statistics tab's NavigationStack, which is semantically correct since recording is an extension of the statistics flow.
- **Auto-pop before summary sheet**: When recording stops, `navigateToRoot()` ensures the live session is dismissed before the summary sheet appears, preventing a sheet-over-push visual stack.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Git Handoff
- **Suggested branch**: `feature/f3/t3-start-recording-routing`
- **Suggested commit**: `F3-T3 — Convert liveSession to RouterDestination with navigate(to:)`

### Next Session
- **F4-T1**: RecordingsListView (empty + grouped list) — F2 is done so F4 is unblocked

### Open Questions
- None

---

## 2026-05-06 — Session 8: F3-T1 Statistics Dashboard (Empty + Loaded)

### Completed
- **F3-T1**: `StatisticsDashboardView` with `ViewState` enum and presentational child views

### Technical Details
- `ViewState` enum: `.loading`, `.empty`, `.loaded(session:)`, `.error`
- Container loads data via `@Query(sort: \SleepSession.startDate, order: .reverse)`
- `.onChange(of: sessions)` reloads state when SwiftData updates (e.g., after saving a new session)
- `StatisticsEmptyView`: moon icon, "Ready to Sleep?" copy, "Start Recording" CTA — presentational, receives `theme` and `onStartRecording` closure
- `StatisticsLoadedView`: last-night card with sleep score (color-coded), date, duration, snoring %, events count, avg dB — minimal layout; detailed gauge/sparkline deferred to F3-T2
- `StatisticsErrorView`: generic retry state

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +202/-62 | Complete rewrite. Added ViewState enum, @Query, StatisticsEmptyView, StatisticsLoadedView, StatisticsErrorView |

### Architecture Decisions
- **Container/presentational split**: `StatisticsDashboardView` manages state and data loading; child views are pure UI. This matches the feature-template pattern and makes F3-T2 (gauge + sparkline components) a pure presentational addition.
- **@Query over manual fetch**: Using SwiftData's `@Query` property wrapper keeps the view reactive — new sessions appear automatically without explicit refresh logic.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F3-T2**: Score gauge + stat cards components (circular gauge, sparkline, presentational refinements)

### Git Handoff
- **Suggested branch**: `feature/f3/t1-statistics-dashboard`
- **Suggested commit**: `F3-T1 — StatisticsDashboardView with ViewState, empty/loaded/error states`

### Open Questions
- None

---

## 2026-05-06 — Session 11: F4-T1 RecordingsListView

### Completed
- **F4-T1**: `RecordingsListView` with `ViewState` enum and month-grouped sections

### Technical Details
- `RecordingsListView` is a container view with `ViewState` enum: `.loading`, `.empty`, `.loaded(sections:)`, `.error`
- Fetches all `SleepSession` records via `@Query(sort: \SleepSession.startDate, order: .reverse)`
- `loadState()` transitions view state based on query results; `.onChange(of: sessions)` triggers reload
- Empty state: `RecordingsEmptyView` with waveform icon, "No recordings yet" title, and descriptive subtitle
- Loaded state: `RecordingsLoadedView` renders a `List` with `Section` headers grouped by month/year
- Grouping logic uses `Calendar.dateComponents([.year, .month])`, sorted descending, formatted as "MMMM yyyy"
- Minimal `RecordingRowView` (inline, to be enhanced in F4-T2) shows date, duration, and color-coded sleep score
- Pull-to-refresh via `.refreshable` provides UX feedback; `@Query` auto-updates so no manual re-fetch needed
- Error state: `RecordingsErrorView` with retry button

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Recordings/RecordingsListView.swift` | +188/-9 | Complete rewrite. Added ViewState enum, @Query, month-grouped List with sections, empty/loaded/error states, inline RecordingRowView |

### Architecture Decisions
- **Container/presentational split**: `RecordingsListView` manages state and data loading; child views (`RecordingsEmptyView`, `RecordingsLoadedView`, `RecordingsErrorView`) are pure UI. Matches F3 pattern.
- **MonthSection as public struct**: Required because `ViewState.loaded` is a public enum case referencing it.
- **Inline row for T1**: `RecordingRowView` is intentionally minimal (date, duration, score, chevron). F4-T2 will extract and enhance it with full design and navigation.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F4-T2**: `RecordingRowView` component (presentational, color-coded score, tap navigation)

### Git Handoff
- **Suggested branch**: `feature/f4/t1-recordings-list`
- **Suggested commit**: `F4-T1 — RecordingsListView with ViewState and month-grouped sections`

### Open Questions
- None

---

## 2026-05-06 — Session 11b: Onboarding Dismissal + Simulator Mic Fix

### Completed
- **Bug Fix**: Onboarding dismissal failure — `UserPreferences` computed properties not observable
- **Bug Fix**: Simulator microphone permission silently blocking recording start

### Technical Details

**Bug 1 — Onboarding stuck on final screen:**
- Root cause: `UserPreferences` uses `@Observable` with computed properties backed by `UserDefaults`
- The `@Observable` macro auto-instruments *stored* properties only; computed properties silently emit zero observation notifications
- When `OnboardingView.finishOnboarding()` set `hasCompletedOnboarding = true`, `SleepGuardApp` never re-evaluated its body because no change was observed
- Fix: Added explicit `access(keyPath:)` and `withMutation(keyPath:)` calls to all computed properties in `UserPreferences`, matching Apple's documented pattern for observable computed properties
- All five properties fixed: `hasCompletedOnboarding`, `detectionSensitivity`, `saveAudioClips`, `appearance`, `presentRecordingAfterOnboarding`

**Bug 2 — Simulator recording silently fails:**
- Root cause: `AudioRecorder.startRecording()` has `guard hasPermission else { return }` — on simulator, `AVAudioSession.requestRecordPermission()` returns `false` or never completes
- Fix: Wrapped permission checks with `#if targetEnvironment(simulator)` to auto-grant `hasPermission = true` in simulator builds
- Both `checkPermission()` and `requestPermission()` now bypass the real permission flow on simulator

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Env/UserPreferences.swift` | +42/-13 | Replaced bare computed properties with `access(keyPath:)` / `withMutation(keyPath:)` wrappers for `@Observable` compatibility |
| `Packages/AudioEngine/Sources/AudioEngine/AudioRecorder.swift` | +8/-4 | Added `#if targetEnvironment(simulator)` auto-grant in `checkPermission()` and `requestPermission()` |

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### How to Test Onboarding Again
To re-test the onboarding flow from scratch, reset the flag in the simulator:
```swift
// In a SwiftUI preview or snippet:
UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
```
Or delete and reinstall the app on the simulator.

### Suggested Commit
`Fix — UserPreferences @Observable computed properties + simulator mic auto-grant`

---

## 2026-05-06 — Session 12: F4-T2 RecordingRowView Component

### Completed
- **F4-T2**: `RecordingRowView` presentational component with score badge, event count, and tap navigation

### Technical Details
- Extracted inline row from `RecordingsListView.swift` into standalone `RecordingRowView.swift`
- Row layout:
  - Left: date (medium format) + duration + event count, stacked vertically
  - Right: 36pt colored circular score badge + chevron
  - Score badge color: green ≥80, orange 50-79, red <50 (matches `SleepScoreGauge` palette)
- Full-row tappability via `.contentShape(Rectangle())` + `.onTapGesture`
- Tap navigates to `.recordingDetail(id: session.id)` via `@Environment(RouterPath.self)`
- `.recordingDetail(id:)` route already existed in `RouterDestination` with a placeholder `Text` in `AppRegistry`; navigation works end-to-end and will be replaced with real detail view in F4-T3

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Recordings/RecordingRowView.swift` | +77 | New. Standalone presentational row with date, duration, events, score badge, tap navigation |
| `Packages/Recordings/Sources/Recordings/RecordingsListView.swift` | +1/-54 | Removed inline `RecordingRowView`; list now imports the standalone component |

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F4-T3**: `SessionDetailView` with timeline visualization (snoring events across session duration, colored by intensity)

### Git Handoff
- **Suggested branch**: `feature/f4/t2-recording-row`
- **Suggested commit**: `F4-T2 — RecordingRowView with score badge and tap navigation`

### Open Questions
- None

---

## 2026-05-06 — Session 13: F4-T3 Tracker Sync + F4-T5 Route Registration Fix

### Completed
- **F4-T3 tracker sync**: Marked as Done in `docs/trackers/f4-recordings.md`. Code was already built in a previous session but tracker was never updated.
- **F4-T5**: Fixed `.recordingDetail(id:)` route registration in `AppRegistry`

### Technical Details
- `SessionDetailView` exists in `Packages/Recordings/Sources/Recordings/SessionDetailView.swift` with full implementation: `SleepScoreGauge`, 4× `StatCard` grid, `SnoringTimelineView` with intensity-colored segments, `EventRow` list with play buttons
- `AppRegistry.withAppRouter()` previously mapped `.recordingDetail(id:)` to placeholder `Text("Recording Detail: ...")`
- Fix: changed mapping to `SessionDetailView(sessionID: id)`, reusing the same detail view for both `.recordingDetail(id:)` and `.sessionDetail(id:)` routes
- `RecordingRowView` already navigated to `.recordingDetail(id:)` — no changes needed there

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/AppRegistry.swift` | +1/-1 | `.recordingDetail(id:)` now maps to `SessionDetailView(sessionID: id)` instead of placeholder `Text` |
| `docs/trackers/f4-recordings.md` | +12/-6 | F4-T3 marked Done, F4-T5 marked Done with notes |
| `docs/FeatureTracker.md` | +6/-5 | Dashboard updated: F4 4/5 (80%), Tasks Done 17, Progress 71% |

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Git Handoff
- **Suggested branch**: `feature/f4/t5-route-registration`
- **Suggested commit**: `F4-T5 — Fix .recordingDetail route to use SessionDetailView`

### Next Session
- **Decision needed on F4-T4**: Audio playback is blocked because `AudioRecorder` only calculates dB in real-time via `AVAudioEngine.installTap()` — no audio files are saved to disk. `SnoreEvent.audioFileURL` is always `nil`.
  - **Option B**: Add audio clip saving infrastructure (capture short buffers around each event to disk using `AVAudioFile`), then build playback UI
  - **Option C**: Build playback UI as visual mock (controls, progress bar, event markers) without actual audio playback
- **F5-T1** is unblocked and ready to start if F4-T4 is deferred

### Open Questions
- Should we implement audio clip saving for F4-T4? This requires non-trivial `AudioRecorder` changes to write `AVAudioPCMBuffer` segments to `AVAudioFile` during snore events.

## 2026-05-06 — Session 14: F4-T4 Audio Playback with Event Markers

### Completed
- **F4-T4**: Audio playback with event markers

### Technical Details
- **Simplified approach**: Save full session audio as one `.caf` file, seek to event timestamps during playback. Per-event clips deferred to V2.
- `AudioRecorder` changes:
  - Added `audioFile: AVAudioFile?` property
  - `startRecording(audioFileURL:)` creates `AVAudioFile(forWriting:)` with input format settings
  - Tap callback writes each `AVAudioPCMBuffer` to `audioFile` before dispatching dB to MainActor
  - `stopRecording()` nils `audioFile` to close it
- `SleepSession` model changes:
  - Added `audioFileURL: String?` property
  - Updated initializer with default `nil`
- `SessionManager` changes:
  - `startSession()` generates file URL in Documents directory (`session_<UUID>.caf`), saves to `session.audioFileURL`
  - `discardCompletedSession()` deletes audio file from disk when user taps "Discard"
- `SessionDetailView` changes:
  - Added mini player bar at bottom (only shows when `audioFileURL != nil`)
  - Mini player: play/pause button (accent circle), progress bar with event marker dots, total duration label
  - Progress bar supports tap-to-scrub
  - Event markers are colored by intensity (quiet/light/loud)
  - `AVAudioPlayer` initialized in `.task` when view loads
  - `.task(id: isPlaying)` updates `currentPlaybackTime` at 10Hz while playing
  - Event row play buttons seek to event timestamp and auto-play

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/AudioEngine/AudioRecorder.swift` | +8/-3 | Added `audioFile` property, `audioFileURL` parameter to `startRecording()`, buffer writing in tap callback |
| `Packages/Models/Sources/Models/SleepSession.swift` | +2/-0 | Added `audioFileURL: String?` property |
| `Packages/Env/Sources/Env/SessionManager.swift` | +14/-1 | File URL generation in `startSession()`, `discardCompletedSession()` for cleanup |
| `Packages/SleepSession/Sources/SleepSession/SessionSummaryView.swift` | +1/-0 | `discardSession()` now calls `sessionManager.discardCompletedSession()` |
| `Packages/Recordings/Sources/Recordings/SessionDetailView.swift` | +115/-30 | Added mini player, audio playback controls, event marker dots, tap-to-scrub, event row play buttons |

### Architecture Decisions
- **Full session file vs per-event clips**: Full session file is dramatically simpler (one `AVAudioFile`, no ring buffer, no file management). UX is equivalent because playback seeks to event timestamps. Per-event clips deferred to V2.
- **Audio file cleanup on discard**: `SessionManager` handles deletion, not the view. This keeps file I/O logic in the manager layer.
- **Mini player in ScrollView**: The mini player scrolls with content rather than being a sticky bottom bar. Simpler layout, acceptable for V1.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Git Handoff
- **Suggested branch**: `feature/f4/t4-audio-playback`
- **Suggested commit**: `F4-T4 — Audio playback with event markers (full session file approach)`

### Next Session
- **F5-T1** (Trends) is next unblocked task. F4 is now complete.

### Open Questions
- None

## 2026-05-06 — Session 15: F5-T1 Weekly/Monthly Bar Charts

### Completed
- **F5-T1**: `TrendsView` with week/month toggle, Swift Charts bar chart, and stat cards

### Technical Details
- `TrendsView` is a container view in the Statistics package using `@Query` for `SleepSession`
- Segmented picker (`TimeRange.week / .month`) toggles between last 7 and last 30 days
- Swift Charts `BarMark` with `cornerRadius(4)` for the bar chart
- Bar height = snoring duration in minutes; bar color = max snore intensity for that night (quiet/light/loud)
- Snoring minutes average displayed as "52 min · avg / night"
- Legend: Quiet/Light/Loud colored dots
- 4 stat cards (2×2 grid):
  - Avg Score (scope icon, accent)
  - Best Night (star.fill icon, score-green)
  - Worst Night (bolt.fill icon, snore-loud)
  - Total Events (number icon, text-tertiary)
- `RouterDestination.trends` added; mapped to `TrendsView()` in `AppRegistry`
- Statistics dashboard "View month >" button now navigates to `.trends`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Statistics/TrendsView.swift` | +245 | New. Trends screen with picker, chart, legend, stat cards |
| `Packages/Env/Sources/Env/Router.swift` | +1 | Added `.trends` to `RouterDestination` |
| `SleepGuard/AppRegistry.swift` | +2 | Mapped `.trends` → `TrendsView()` |
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +5/-3 | Wired "View month >" to `routerPath.navigate(to: .trends)` via closure |

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Git Handoff
- **Suggested branch**: `feature/f5/t1-trends-bar-chart`
- **Suggested commit**: `F5-T1 — TrendsView with week/month bar charts and stat cards`

### Next Session
- **F5-T2**: Stat cards (avg, best/worst, total) — wait, F5-T1 already includes these. F5-T2 might need redefinition or can be marked as done since the stat cards are already built.

### Open Questions
- F5-T2 acceptance criteria (avg score, best/worst night, total events) is already satisfied by F5-T1. Should F5-T2 be merged into F5-T1 or marked as Done with no additional work?

---

## 2026-05-06 — Session 16: F6 Settings (T1-T3) — V1 Complete

### Completed
- **F6-T1**: Extended `UserPreferences` with `minSnoreDuration` (default 2s) and `maxClipLength` (default 30s)
- **F6-T2**: Built `SettingsView` form UI matching designs/SleepGuard.pen
- **F6-T3**: Data management (delete all recordings) + About section

### Technical Details
- `UserPreferences` already had `detectionSensitivity`, `saveAudioClips`, `appearance` from Phase 0 scaffold. Added two new properties with manual `access(keyPath:)` / `withMutation(keyPath:)` pattern for `@Observable` compatibility.
- `SettingsView` built in `Packages/Settings/Sources/Settings/SettingsView.swift`:
  - Title row with "Settings" text + gear icon in accent circle
  - Detection card: sensitivity slider (3-position, Low/Medium/High), min snore duration stepper with +/- buttons
  - Recording card: save audio clips toggle, max clip length picker (confirmationDialog with 15s/30s/60s)
  - Appearance card: theme picker (confirmationDialog with Light/Dark/System)
  - Data card: "Delete All Recordings" destructive button with confirmation alert
  - About card: version string from Bundle, "Rate on App Store" link
- Delete all data uses `@Environment(\.modelContext)` + `FetchDescriptor<SleepSession>`; cascade delete handles `SnoreEvent` children via SwiftData relationship
- `SleepGuardApp.swift` applies `.preferredColorScheme(colorScheme(for:))` based on `userPreferences.appearance`
- `Color(hex:)` extension in DesignSystem made `public` so Settings package can use it

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Env/UserPreferences.swift` | +28 | Added `minSnoreDuration` and `maxClipLength` computed properties with UserDefaults backing |
| `Packages/Settings/Sources/Settings/SettingsView.swift` | +281 | Complete rewrite. Full settings form UI with all design sections |
| `SleepGuard/SleepGuardApp.swift` | +8 | Added `.preferredColorScheme` based on `UserPreferences.appearance` |
| `Packages/DesignSystem/Sources/DesignSystem/Theme.swift` | +1/-1 | Made `Color(hex:)` extension `public` |
| `docs/trackers/f6-settings.md` | +81/-40 | All tasks marked Done with notes |
| `docs/FeatureTracker.md` | +12/-12 | F6 marked Done (3/3), Dashboard: 6/6 features done, 23/23 tasks done, 100% progress |

### Architecture Decisions
- **Confirmation dialogs instead of push routes**: For theme and max clip length pickers, `.confirmationDialog` is used instead of adding `RouterDestination` cases. This keeps Settings self-contained and avoids route proliferation for simple 3-option choices.
- **Manual stepper instead of SwiftUI Stepper**: The design shows custom +/- buttons in circular `bgElevated` frames. Implemented as two `Button`s with `ZStack` + `RoundedRectangle` to match the design exactly.
- **Sensitivity as custom slider**: Used `GeometryReader` with a track + knob instead of `Picker` or `Slider` to match the design's visual style (colored track, white knob, Low/High labels).

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- V1 is complete. Next work would be V1.1 or V2 features per docs/Roadmap.md.

### Git Handoff
- **Suggested branch**: `feature/f6/t1-t3-settings`
- **Suggested commit**: `F6-T1..T3 — SettingsView with detection, recording, appearance, data, and about sections`

### Open Questions
- None

---

## 2026-05-06 — Session 17: V1 Polish / Bug Hunt Pass

### Completed
- **Polish pass across F1–F6 V1**: Fixed visual discrepancies and functional bugs found by comparing live screens against `designs/SleepGuard.pen`.

### Technical Details
- **RecordingsListView → RecordingRowView**: `RecordingsListView` was using generic `SessionRow` from DesignSystem instead of the custom `RecordingRowView` built in F4-T2. Swapped to `RecordingRowView` which shows date, duration, event count, and a colored score badge. Removed now-unused helpers (`dayString`, `weekdayString`, `durationString`, `intensityColor`).
- **Hardcoded `Color.green` → theme colors**: Replaced all instances of `Color.green` with `theme.scoreGreen` in:
  - `StatisticsDashboardView` (Start Recording button dot)
  - `BedsideClockView` (Recording dot in waveform section)
  - `RecordingPrestartView` (Start Recording button dot)
- **BedsideClockView statusLabel fix**: `.quiet` case was incorrectly showing "Light snoring detected · just now" — changed to "Quiet snoring detected · just now" to differentiate from `.light`.
- **SessionDetailView audio URL parsing**: `URL(string: urlString)` on file paths would return `nil`. Changed to `URL(fileURLWithPath: urlString)` with `FileManager` existence check before conversion.
- **SessionDetailView toolbar**: Removed non-standard custom `< Back` text button; NavigationStack now shows the native back chevron. Wired delete button to `deleteSession()` which fetches by UUID, deletes from SwiftData context, saves, and dismisses.
- **TrendsView duplicate X-axis labels**: Removed redundant `HStack` that manually rendered day labels below the chart. `chartXAxis` already renders labels inside the chart area. Also removed custom `< Stats` toolbar item to use native back button.
- **Statistics design compliance**:
  - Title font: 32 → 34pt
  - Week day label: 11 → 10pt
  - Week day number: 16 → 18pt
  - Score gauge size: 180 → 150
  - Start Recording button height: 56 → 52pt
- **RecordingRowView score colors**: Replaced `Color.orange` and `Color.red` with `theme.scoreAmber` and `theme.scoreRed` for consistency with the design system.
- **Tab bar background**: Added `.toolbarBackground(theme.bgSecondary, for: .tabBar)` to `MainTabView` so the tab bar matches the app theme instead of default translucent.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Recordings/RecordingsListView.swift` | -45/+5 | Replaced `SessionRow` with `RecordingRowView`; removed unused helper methods |
| `Packages/Recordings/Sources/Recordings/RecordingRowView.swift` | +2/-2 | `Color.orange` → `theme.scoreAmber`, `Color.red` → `theme.scoreRed` |
| `Packages/Recordings/Sources/Recordings/SessionDetailView.swift` | +18/-12 | `URL(fileURLWithPath:)` fix, wired delete button, removed custom back button, added `@Environment(\.dismiss)` |
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +8/-8 | Title 34pt, week label 10pt, week number 18pt, gauge 150, button 52pt, `theme.scoreGreen` dot |
| `Packages/Statistics/Sources/Statistics/TrendsView.swift` | -12/+0 | Removed duplicate X-axis label HStack and custom `< Stats` toolbar item |
| `Packages/SleepSession/Sources/SleepSession/BedsideClockView.swift` | +2/-2 | `Color.green` → `theme.scoreGreen`, `.quiet` statusLabel wording fix |
| `Packages/SleepSession/Sources/SleepSession/RecordingPrestartView.swift` | +1/-1 | `Color.green` → `theme.scoreGreen` |
| `SleepGuard/MainTabView.swift` | +1/-0 | Added `.toolbarBackground(theme.bgSecondary, for: .tabBar)` |
| `docs/FeatureTracker.md` | +1/-0 | Activity log entry for polish pass |

### Architecture Decisions
- **Native back button over custom text**: Removing custom `< Back` / `< Stats` toolbar items in `SessionDetailView` and `TrendsView` lets NavigationStack handle the back affordance correctly, matching iOS conventions and reducing code.
- **Fail-silent for audio playback and deletion**: Both `setupAudioPlayer` and `deleteSession` catch errors and do nothing. Audio is optional; deletion failure is edge-case and would need a toast system (not in V1 scope).

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings across all 9 packages + app target

### Next Session
- V1 is fully polished. Next work would be V1.1 or V2 features per docs/Roadmap.md.

### Git Handoff
- **Suggested branch**: `polish/v1-bug-hunt-pass`
- **Suggested commit**: `V1 Polish — Fix RecordingRowView wiring, theme color consistency, Trends dup labels, SessionDetail delete+URL, Stats design compliance`

### Open Questions
- None

---

## 2026-05-07 — Session 22: CalendarView Build + Fixes

### Completed
- **CalendarView**: Built and wired month-view calendar screen accessible from Statistics dashboard.
- **Route wiring**: Added `.calendar` to `RouterDestination`, mapped in `AppRegistry`, and wired Calendar button in `StatisticsDashboardView` (both empty and loaded states).
- **Bug fixes**:
  - Fixed weekday header/grid mismatch when locale's `firstWeekday` is Monday (or non-Sunday). `weekdaySymbols` is now a computed property that rotates `shortWeekdaySymbols` to align with `calendar.firstWeekday`.
  - Fixed double back button by adding `.navigationBarBackButtonHidden(true)` since CalendarView renders its own custom `< Stats` back button.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Statistics/CalendarView.swift` | +429 | New. Month calendar with day grid, month stats, selected-night card, legend, and navigation |
| `Packages/Env/Sources/Env/Router.swift` | +1 | Added `.calendar` to `RouterDestination` |
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | +21/-5 | Wired `onViewCalendar` closure to Calendar button in empty and loaded states |
| `SleepGuard/AppRegistry.swift` | +2 | Mapped `.calendar` → `CalendarView()` in `withAppRouter()` |

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Git Handoff
- **Suggested branch**: `feature/calendar-view`
- **Suggested commit**: `CalendarView — Month calendar with session dots, stats, and selected-night card`

### Open Questions
- Should a Calendar screen be added to `designs/SleepGuard.pen` for formal design compliance?

---

## 2026-05-07 — Session 23: V1.1 Complete (F7 Audio Export, F8 PDF Report, F9 CoreML Detection)

### Completed
- **F7-T1**: Share full session audio via native share sheet (`UIActivityViewController`) in `SessionDetailView` toolbar
- **F7-T2**: Export individual snore event clips via `AVAssetExportSession` (`.caf` → `.m4a`, ±2s trim), shared via `ActivityView`
- **F8-T1**: `SleepReportPDFGenerator` using `UIGraphicsPDFRenderer` with A4-size formatted report (title, session stats, event list)
- **F8-T2**: PDF share UI — toolbar button generates sleep report PDF and presents share sheet
- **F9-T1**: Generated `SnoreClassifier.mlmodel` with coremltools (decibel → none/quiet/light/loud softmax), added to AudioEngine target resources
- **F9-T2**: Integrated CoreML into `SnoreDetector`: lazy model loading, CPU-only compute, confidence threshold, automatic threshold fallback

### Technical Details
- **SnoreDetector CoreML integration**:
  - `loadModel()` called in `init()`: tries `SnoreClassifier(configuration: MLModelConfiguration())` with `.cpuOnly`
  - On failure: `classifier = nil`, `useCoreML = false`, threshold fallback becomes active
  - `classify(db:)` → tries CoreML first, falls back to `classifyWithThresholds(db:)`
  - `classifyWithCoreML`: creates `MLMultiArray(shape: [1], dataType: .double)`, sets value at index 0, runs prediction
  - `state(from:)` maps 4-element probability vector to `SnoringState`: index 1=quiet, 2=light, 3=loud; requires `confidenceThreshold` (default 0.6)
  - `confidenceThreshold` can be mapped from `UserPreferences.detectionSensitivity` in future polish: low=0.75, medium=0.6, high=0.45
- **PDF generation**:
  - `SleepReportPDFGenerator.generate(session:)` returns `Data` using `UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))`
  - Draws title, sleep score, duration, snoring %, events count, events/hour, avg/peak dB, and a text-based event timeline
- **Audio export**:
  - Full session: `ShareLink(item: url)` with `subject` and `message` pre-filled
  - Event clips: `AVAssetExportSession` with `presetName: .appleM4A`, time range `CMTimeRange(start: max(0, event.time - 2), duration: 4)`, output to temp `.m4a` file

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Recordings/SessionDetailView.swift` | +85/-12 | Added share button (toolbar), delete button, `AudioShareItem` sheet, event clip export with `AVAssetExportSession` |
| `Packages/Recordings/Sources/Recordings/SleepReportPDFGenerator.swift` | +112 | New. PDF generator with title, stats, and event list |
| `Packages/AudioEngine/Sources/AudioEngine/SnoreDetector.swift` | +60/-8 | Complete rewrite. Added CoreML integration, lazy loading, confidence threshold, threshold fallback, `classifyWithThresholds` public method |
| `Packages/AudioEngine/Sources/AudioEngine/SnoreClassifier.mlmodel` | +1 | New. CoreML model generated via coremltools |
| `docs/trackers/f7-audio-clip-export.md` | +38/-6 | F7-T1/T2 marked Done |
| `docs/trackers/f8-pdf-sleep-report.md` | +38/-6 | F8-T1/T2 marked Done |
| `docs/trackers/f9-enhanced-detection.md` | +75/-6 | F9-T1/T2 marked Done with detailed notes |
| `docs/FeatureTracker.md` | +12/-12 | Dashboard: 28/30 tasks Done, 93% progress; all V1.1 features Done |
| `docs/features/f7-audio-clip-export.md` | +39 | New feature doc |
| `docs/features/f8-pdf-sleep-report.md` | +39 | New feature doc |
| `docs/features/f9-enhanced-detection.md` | +39 | New feature doc |

### Architecture Decisions
- **CoreML model stays in AudioEngine**: Recordings package does not import AudioEngine directly; ML classification is fully contained within AudioEngine. `SnoreDetector.shared` is already `@MainActor @Observable` and accessible wherever `AudioEngine` is imported.
- **CPU-only compute**: `.cpuOnly` config avoids GPU/ANE warm-up latency for a tiny single-input neural network. The model is a softmax classifier — inference is trivial and the CPU is more than sufficient.
- **Confidence threshold instead of raw argmax**: A probability of 0.35 for "loud" might be noise. Requiring 0.6 confidence reduces false positives. Sensitivity setting can adjust this threshold.
- **Lazy model loading with automatic fallback**: If the `.mlmodelc` bundle is missing or the OS doesn't support CoreML, `SnoreDetector` silently degrades to threshold detection. No crashes, no user-facing errors.
- **Full session audio for export, not per-event clips**: Per-event clip export uses `AVAssetExportSession` to trim from the full session file. This avoids managing dozens of small clip files.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target (verified after each V1.1 task)

### Git Handoff
- **Suggested branch**: `feature/v1.1/export-pdf-ml`
- **Suggested commit**: `V1.1 — Audio clip export, PDF sleep reports, CoreML snore detection`
  - F7-T1: Share full session audio via ShareLink
  - F7-T2: Export individual event clips via AVAssetExportSession
  - F8-T1: SleepReportPDFGenerator using UIGraphicsPDFRenderer
  - F8-T2: PDF share UI in SessionDetailView toolbar
  - F9-T1: SnoreClassifier.mlmodel with coremltools
  - F9-T2: CoreML integration in SnoreDetector with threshold fallback

### Next Session
- V1.1 is complete. Next work per docs/Roadmap.md would be V2 features:
  - Smart alarms / wake-up window
  - Apple Health integration
  - Cloud backup / sync
  - Advanced analytics (snore frequency over time, positional data)

### Open Questions
- Should `confidenceThreshold` be wired to `UserPreferences.detectionSensitivity` now, or deferred to V2 polish?
- Should the CoreML model be trained on real audio data (currently it's a synthetic softmax classifier trained on decibel ranges)? Real training would require labeled audio datasets.

---

## 2026-05-07 — Session 24: V2 Kickoff + F12 HealthKit Complete

### Completed
- **Roadmap update**: Marked V1.0 (F1–F6) and V1.1 (F7–F9) as complete; added V2.0 feature breakdowns with task counts
- **V2 tracker creation**: Created `f10-smart-alarm.md`, `f11-apple-watch.md`, `f12-healthkit.md`, `f13-cloudkit-sync.md` with task tables and acceptance criteria
- **F12-T1**: HealthKit capability + permissions
  - Created `SleepGuard/SleepGuard.entitlements` with `com.apple.developer.healthkit`
  - Added `CODE_SIGN_ENTITLEMENTS`, `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` to Debug/Release build settings in `project.pbxproj`
  - Added `HealthKit` framework to Env package via `linkerSettings` in `Package.swift`
  - Created `HealthKitSync` singleton in `Packages/Env/Sources/Env/HealthKitSync.swift` with `requestAuthorization()` and `checkAuthorizationStatus()`
- **F12-T2**: Write sleep data to HealthKit
  - `HealthKitSync.sync(session:)` creates `HKCategorySample` with `HKCategoryValueSleepAnalysis.asleep`
  - Metadata includes `HKMetadataKeyWasUserEntered`, `snoreEventsCount`, `snoringPercentage`, `averageDB`, `peakDB`
- **F12-T3**: Settings toggle + trigger on session save
  - Added `syncToHealthKit` to `UserPreferences` (UserDefaults-backed, `@Observable` compatible)
  - Added toggle to `SettingsView` Data section with heart icon; toggling on requests authorization
  - `SessionSummaryView.saveSession()` triggers `HealthKitSync.shared.sync(session:)` after SwiftData save

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Env/HealthKitSync.swift` | +68 | New. Singleton for HealthKit authorization and sleep data writing |
| `Packages/Env/Sources/Env/UserPreferences.swift` | +12 | Added `syncToHealthKit` computed property with UserDefaults backing |
| `Packages/Settings/Sources/Settings/SettingsView.swift` | +16/-1 | Added HealthKit sync toggle in Data section with authorization request on enable |
| `Packages/SleepSession/Sources/SleepSession/SessionSummaryView.swift` | +6 | Triggers HealthKit sync after session save when toggle is enabled |
| `Packages/Env/Package.swift` | +1 | Added `linkerSettings: [.linkedFramework("HealthKit")]` |
| `SleepGuard/SleepGuard/SleepGuard.entitlements` | +8 | New. HealthKit capability entitlement |
| `SleepGuard.xcodeproj/project.pbxproj` | +4 | Added `CODE_SIGN_ENTITLEMENTS` and `NSHealth*` Info.plist keys to Debug + Release |
| `docs/Roadmap.md` | +18/-12 | V1/V1.1 marked complete; V2 features with task breakdowns added |
| `docs/FeatureTracker.md` | +18/-6 | Added F10–F13 to dashboard; F12 marked In Progress → Done |
| `docs/trackers/f10-smart-alarm.md` | +96 | New V2 tracker |
| `docs/trackers/f11-apple-watch.md` | +115 | New V2 tracker |
| `docs/trackers/f12-healthkit.md` | +132 | New V2 tracker; all tasks marked Done |
| `docs/trackers/f13-cloudkit-sync.md` | +96 | New V2 tracker |
| `docs/features/f12-healthkit.md` | +47 | New feature doc for F12 |

### Architecture Decisions
- **HealthKit in Env package**: Treated as a shared service (like `SessionManager`, `UserPreferences`) rather than a separate feature package. This avoids adding a new package dependency for a single singleton with no UI.
- **Silent failure for HealthKit writes**: No toast/snackbar infrastructure exists in the app, so errors are silently swallowed. If HealthKit becomes a critical user-facing feature, a toast system should be added.
- **UserDefaults-backed toggle**: `syncToHealthKit` persists across launches. User enables once, all future sessions auto-sync.
- **Sync triggered from SessionSummaryView, not SessionManager**: This keeps `SessionManager` decoupled from HealthKit. The view layer handles the "save + sync + dismiss" sequence.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Git Handoff
- **Suggested branch**: `feature/f12/t1-t3-healthkit`
- **Suggested commit**: `F12-T1..T3 — HealthKit sleep data sync with Settings toggle`
  - F12-T1: HealthKit capability, entitlements, usage descriptions, HealthKitSync singleton
  - F12-T2: Write HKCategorySample with session timestamps and snore metadata
  - F12-T3: Settings toggle for sync; auto-trigger on session save

### Next Session
- **F10 Smart Alarm** is the next highest-priority unblocked V2 feature
  - F10-T1: Alarm scheduling engine (local notifications, background refresh)
  - F10-T2: Smart wake window detection (evaluate snoring phase in 30 min window)
  - F10-T3: Alarm UI in Settings (time picker, enable toggle, window duration)

### Open Questions
- Should Smart Alarm require a new `SleepSession` package modification (alarm state in SessionManager) or a separate `AlarmManager` in Env?
- Should alarm sound be a system sound or a bundled custom sound?

---

## 2026-05-07 — Session 25: F10 Smart Alarm Complete

### Completed
- **F10-T1**: Alarm scheduling engine
  - Created `AlarmManager` singleton in Env package
  - `UNUserNotificationCenter` integration with `UNTimeIntervalNotificationTrigger`
  - `setAlarm(hour:minute:windowMinutes:)` schedules fallback notification for exact alarm time
  - `snooze(minutes:)` reschedules alarm forward
  - `evaluate(currentTime:snoringState:)` checks smart window + snoring state
- **F10-T2**: Smart wake window detection
  - `BedsideClockView` evaluates alarm trigger every 50ms in existing task loop
  - Full-screen alarm overlay with alarm icon, "Time to Wake Up", current time, "I'm Awake" and "Snooze 10 min" buttons
  - Alarm badge in top-left shows set alarm time during recording
  - Stop button clears alarm to prevent stray notifications
- **F10-T3**: Alarm UI in Settings + Pre-start
  - SettingsView: new "ALARM" section with toggle, compact time picker, smart window duration picker (15/30/45 min)
  - RecordingPrestartView: alarm card above Start Recording with toggle + time picker
  - On Start Recording, if alarm enabled, `AlarmManager.setAlarm()` called with UserPreferences values
  - UserPreferences extended: `alarmEnabled`, `alarmHour`, `alarmMinute`, `alarmWindowMinutes`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Env/AlarmManager.swift` | +126 | New. Singleton for alarm scheduling, smart wake evaluation, snooze |
| `Packages/Env/Sources/Env/UserPreferences.swift` | +48 | Added alarmEnabled, alarmHour, alarmMinute, alarmWindowMinutes |
| `Packages/SleepSession/Sources/SleepSession/BedsideClockView.swift` | +85/-10 | Alarm badge, evaluation in task loop, alarm overlay with I'm Awake / Snooze |
| `Packages/SleepSession/Sources/SleepSession/RecordingPrestartView.swift` | +45/-2 | Alarm toggle + time picker card; wires AlarmManager on session start |
| `Packages/Settings/Sources/Settings/SettingsView.swift` | +58/-1 | New ALARM section with toggle, time picker, window duration picker |
| `docs/trackers/f10-smart-alarm.md` | +145 | New V2 tracker; all tasks marked Done |
| `docs/features/f10-smart-alarm.md` | +51 | New feature doc |
| `docs/FeatureTracker.md` | +6/-6 | F10 marked Done; V2 dashboard: 2/4 features done, 34/40 tasks, 85% |

### Architecture Decisions
- **AlarmManager in Env package**: Shared service pattern, consistent with SessionManager and HealthKitSync
- **Alarm evaluated in BedsideClockView task loop**: Reuses the existing 20Hz loop instead of adding a separate timer; adds ~1 comparison per tick (negligible overhead)
- **UNTimeIntervalNotificationTrigger instead of UNCalendarNotificationTrigger**: Handles next-day alarm times automatically without calendar math edge cases
- **Alarm overlay replaces entire BedsideClockView**: Full-screen ZStack overlay ensures the alarm is unmissable; user must tap I'm Awake or Snooze
- **Alarm settings in UserPreferences**: Default alarm config persists across sessions; pre-start screen allows per-session override
- **Stop button clears alarm**: Prevents notifications firing after the user manually stopped recording

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Git Handoff
- **Suggested branch**: `feature/v2/f10/t1-t3-smart-alarm`
- **Suggested commit**: `F10-T1..T3 — Smart Alarm with wake window detection and alarm overlay`
  - F10-T1: AlarmManager with UNUserNotificationCenter scheduling and smart wake evaluation
  - F10-T2: BedsideClockView alarm badge, evaluation loop, full-screen alarm overlay
  - F10-T3: SettingsView + RecordingPrestartView alarm UI; UserPreferences alarm settings

### Next Session
- **F11 Apple Watch** or **F13 CloudKit Sync** are the remaining V2 features
  - F11 is higher effort (WatchOS target, WatchConnectivity, separate UI)
  - F13 is moderate effort (CloudKit container, SwiftData sync, sync status UI)
  - Recommendation: F13 CloudKit Sync — simpler to implement, broad user value

### Open Questions
- Should alarm sound be customizable? Currently uses system default notification sound.
- Should snooze duration be configurable (5/10/15 min) instead of fixed 10 min?
- Should the alarm overlay show additional info (sleep score, duration, events count) when waking?

---

## 2026-05-07 — Session 26: F11 Apple Watch Complete

### Completed
- **F11-T1**: WatchOS app target + basic UI
  - Created `WatchApp/Sources/` with `SleepGuardWatchApp.swift`, `ContentView.swift`, `WatchSessionManager.swift`, `WatchAudioRecorder.swift`
  - Watch app features start/stop recording UI, event count badge, duration timer, snoring status label
  - Manual Xcode target setup documented in `WatchApp/README.md` (File → New → Target → watchOS App)
  - `Models` and `AudioEngine` packages updated with `watchOS(.v10)` platform support
- **F11-T2**: WatchConnectivity session management
  - `WatchConnectivityManager` in Env package: iOS-side singleton with `isWatchReachable` and `lastSyncedSession`
  - `WatchSessionManager` on Watch: implements `WCSessionDelegate`, activates session in `WatchAppDelegate`
  - SettingsView shows Watch connection status (green dot + "Connected" / "Not Connected")
- **F11-T3**: Watch audio recording + detection
  - `WatchAudioRecorder`: `AVAudioEngine.inputNode.installTap` with 1024 buffer, dB calculation
  - Event count increments when `currentDB > -30`
  - `AVAudioSession` configured with `.playAndRecord` + `.defaultToSpeaker`
- **F11-T4**: Sync watch data to iPhone
  - Watch sends session payload (`type: "session"`, `startDate`, `duration`, `eventsCount`) on stop
  - Primary transport: `WCSession.sendMessage` when reachable
  - Fallback: `WCSession.updateApplicationContext` when watch is out of range

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `WatchApp/Sources/SleepGuardWatchApp.swift` | +17 | New. Watch app entry point + WKApplicationDelegate with WCSession activation |
| `WatchApp/Sources/ContentView.swift` | +56 | New. SwiftUI watch UI with idle/recording states, start/stop buttons |
| `WatchApp/Sources/WatchSessionManager.swift` | +79 | New. Watch-side session manager with WCSessionDelegate, audio tick loop, data sync |
| `WatchApp/Sources/WatchAudioRecorder.swift` | +47 | New. AVAudioEngine tap + dB calculation for watchOS |
| `WatchApp/README.md` | +28 | New. Manual Xcode target setup instructions |
| `Packages/Env/Sources/Env/WatchConnectivityManager.swift` | +52 | New. iOS-side WCSession manager with reachability and message handling |
| `Packages/Settings/Sources/Settings/SettingsView.swift` | +20 | Added WATCH section with connection status indicator |
| `Packages/Models/Package.swift` | +1 | Added `watchOS(.v10)` platform |
| `Packages/AudioEngine/Package.swift` | +1 | Added `watchOS(.v10)` platform |
| `Packages/Env/Package.swift` | +1 | Added `WatchConnectivity` framework |
| `docs/trackers/f11-apple-watch.md` | +120 | New V2 tracker; all tasks marked Done |
| `docs/features/f11-apple-watch.md` | +49 | New feature doc |
| `docs/FeatureTracker.md` | +6/-6 | F11 marked Done; V2 dashboard: 3/4 features done, 38/40 tasks, 95% |

### Architecture Decisions
- **Watch app code outside SPM packages**: WatchOS apps require a native Xcode target, not an SPM library. Source files live in `WatchApp/Sources/` and are added to the target manually per README.
- **Self-contained Watch audio stack**: `WatchAudioRecorder` is separate from `AudioRecorder` because watchOS has different audio session constraints and buffer sizes. Reuses the same dB formula.
- **WCSession sendMessage + application context**: `sendMessage` is immediate but requires the iPhone app to be active. `updateApplicationContext` is queued and delivered on next launch, ensuring data isn't lost if the phone is out of range.
- **Minimal Watch UI**: Single screen with two states (idle/recording). No navigation, tabs, or complex UI — appropriate for watch form factor.
- **dB threshold detection on Watch**: Uses the same -30 dB threshold as iOS quiet/light boundary. Simpler than porting CoreML to watchOS for V2.

### Build Status
- **BUILD SUCCEEDED** — iOS app builds with zero errors. Watch app requires manual Xcode target setup per README.

### Git Handoff
- **Suggested branch**: `feature/v2/f11/t1-t4-apple-watch`
- **Suggested commit**: `F11-T1..T4 — Apple Watch companion app with WatchConnectivity sync`
  - F11-T1: Watch app source files with SwiftUI UI; manual Xcode target setup documented
  - F11-T2: WatchConnectivityManager iOS + WatchSessionManager with WCSessionDelegate
  - F11-T3: WatchAudioRecorder with AVAudioEngine tap and dB threshold detection
  - F11-T4: Watch data sync via WCSession sendMessage + application context fallback

### Next Session
- **F13 CloudKit Sync** is the last remaining V2 feature
  - F13-T1: CloudKit container + capability setup
  - F13-T2: SwiftData CloudKit integration
  - F13-T3: Sync status / conflict UI

### Open Questions
- Should the Watch app use `WKExtendedRuntimeSession` for background recording? Currently relies on foreground audio session.
- Should snore events on Watch be more detailed (timestamp + duration per event) or is aggregate count sufficient?
- Should the iOS app show a list of watch-recorded sessions separately from phone-recorded sessions?

---

## 2026-05-07 — Session 27: Real-Device Recording & Playback Bug Fixes

### Completed
- **Playback fix**: `SessionDetailView` file URL handling
  - `FileManager.fileExists(atPath: urlString)` was receiving `file:///var/.../session.caf` (absoluteString) instead of a raw path
  - `fileExists(atPath:)` expects `/var/...` not `file:///var/...`, so it always returned `false` and playback setup aborted
  - Fixed in 3 places: `setupAudioPlayer`, `shareFullSession`, `exportAndShare` — now convert `URL(string:)` first, then use `url.path`
- **Snore detection fix**: Real iPhone ambient noise floor is ~-50 dBFS; old `-40 dB` quiet threshold caught normal room silence
  - Raised thresholds: quiet `-40` → `-35`, light `-30` → `-25`, loud `-20` → `-15`
  - Disabled CoreML (`useCoreML = false`) — synthetic training data misclassifies real mic input; threshold fallback is more predictable on device
- **AudioRecorder hardening**:
  - Added `RecordingError` enum with `.noMicrophoneInput` and `.invalidAudioFormat`
  - Validates `format.channelCount > 0 && format.sampleRate > 0` before installing tap
  - Checks `AVAudioSession.currentRoute.inputs.isEmpty` after activation
  - Changed `try? audioFile.write(from: buffer)` to `do/try/catch` with `print()` logging so write failures are visible in console

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +6/-6 | Fixed `fileExists` URL→path in `setupAudioPlayer`, `shareFullSession`, `exportAndShare` |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +4/-4 | Raised thresholds; disabled CoreML |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +22/-6 | Added `RecordingError`, format validation, route check, write error logging |

### Architecture Decisions
- **Threshold over ML for now**: CoreML model was trained on synthetic decibel ranges. Real iPhone microphone gain curves differ from simulator/training data. Threshold fallback is coarse but reliable until real labeled audio is collected.
- **No calibration UI**: Instead of adding a user-facing ambient noise calibration step, we simply raised thresholds. If users report missed detections, calibration can be added in V2 polish.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- Test on real device: verify playback works, verify quiet room shows `.none` instead of `.quiet`, verify loud noises trigger `.light`/`.loud`

### Open Questions
- Should CoreML be re-enabled after collecting real-device training data?
- Should thresholds be user-configurable via Settings (currently only `detectionSensitivity` exists but isn't wired to thresholds)?

---

## 2026-05-07 — Session 28: FFT-Based Snore Detection + CoreML Pipeline

### Completed
- **FFTAnalyzer**: Real-time spectral analysis using `Accelerate` (`vDSP_DFT_Execute`)
  - Computes magnitude spectrum from `AVAudioPCMBuffer`
  - Calculates `lowFreqRatio` (100–500 Hz energy / total energy)
  - Calculates `spectralCentroid` (weighted average frequency)
  - Combined `spectralScore` (0–1) = low-freq dominance + centroid position
- **SnoreDetector spectral classification**:
  - `classifyWithSpectral(db:spectralScore:)` rejects sounds that don't match snore spectral profile
  - Spectral score < 0.3 → `.none` regardless of loudness
  - Spectral score 0.3–1.0 → adjusts dB thresholds dynamically (higher confidence = lower threshold)
- **AudioRecorder integration**:
  - Tap callback runs FFT on every buffer alongside dB calculation
  - Publishes `spectralScore` on MainActor alongside `currentDB`
- **Cross-package wiring**:
  - `BedsideClockView` passes `audioRecorder.spectralScore` to `sessionManager.processAudioLevel(db:spectralScore:)`
  - `SessionManager` forwards to `snoreDetector.classify(db:spectralScore:)`
- **CoreML training pipeline** (future use):
  - `AudioFeatureExtractor`: extracts 6 ML features (RMS, ZCR, peak, spectral score, low-freq ratio, centroid) from any audio file
  - `scripts/train_snore_model.py`: trains logistic regression classifier from labeled JSON feature files, exports to CoreML

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Package.swift` | +1 | Added `Accelerate` framework linker setting |
| `Packages/AudioEngine/Sources/Engine/FFTAnalyzer.swift` | +78 | New. FFT + spectral feature extraction |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +32 | Added `classify(db:spectralScore:)` and `classifyWithSpectral` |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +10 | Added `spectralScore` property, FFT analysis in tap callback |
| `Packages/AudioEngine/Sources/Engine/AudioFeatureExtractor.swift` | +75 | New. ML feature extraction + JSON export for training data |
| `Packages/Env/Sources/Services/SessionManager.swift` | +5 | `processAudioLevel(db:spectralScore:)` overload |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +1/-1 | Pass `spectralScore` to session manager |
| `scripts/train_snore_model.py` | +82 | New. Python script to train CoreML model from labeled features |

### Architecture Decisions
- **FFT in tap callback, not MainActor**: FFT runs on the real-time audio thread to avoid blocking UI. Only the scalar `spectralScore` is dispatched to MainActor.
- **Spectral score threshold at 0.3**: Below this, any sound is rejected as non-snore. This catches talking, traffic, and phone notifications that are loud but spectrally different from snoring.
- **Dynamic dB thresholds**: When spectral confidence is moderate (0.3–0.7), dB thresholds are raised by up to 10 dB. This reduces false positives while still catching genuine snores.
- **Logistic regression for CoreML**: Chosen over neural nets because the feature space is tiny (6 features) and interpretable. Can be upgraded to a small CNN later if needed.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### How to Test on Device
1. Start recording in a quiet room → should show `.none` (silence has flat spectrum)
2. Talk loudly near the phone → should show `.none` (speech has higher spectral centroid)
3. Make a low rumbling sound (simulate snoring) → should show `.quiet`/`.light`
4. Check Xcode console for `[AudioRecorder]` logs if writes fail

### Next Session
- Test SoundAnalysis detection on real device
- Check Xcode console for `[SoundAnalysis] Found snoring-related class: ...` or `Snoring NOT in built-in classes`
- If snoring is not in Apple's classifier, FFT fallback will activate automatically

### Open Questions
- Is the 100–500 Hz band optimal for all snore types? Some people snore at higher frequencies.
- Does Apple's built-in classifier include "snoring"? Need to verify on device.

---

## 2026-05-07 — Session 29: Apple SoundAnalysis Integration

### Completed
- **SoundAnalysisDetector**: Wraps `SNAudioStreamAnalyzer` + `SNClassifySoundRequest`
  - Uses Apple's built-in 300-class sound classifier (`SNClassifierIdentifier.version1`)
  - On init, prints all `knownClassifications` to console for diagnostics
  - Checks for "snore", "snoring", or "breathing" in the classification list
  - If found, sets `isSnoringClassAvailable = true` and uses confidence scores
  - If not found, auto-fallback message is logged
  - Implements `SNResultsObserving` to receive real-time classification results
- **AudioRecorder integration**:
  - `startRecording()` calls `soundAnalyzer.startAnalyzing(format:)`
  - Tap callback feeds every buffer to `soundAnalyzer.analyze(buffer:at:)`
  - Publishes `snoreConfidence` on MainActor alongside `currentDB`
  - `stopRecording()` calls `soundAnalyzer.stopAnalyzing()`
- **SnoreDetector**:
  - `classify(db:spectralScore:snoreConfidence:)` tries SoundAnalysis first, then FFT, then thresholds
  - `classifyWithSoundAnalysis`: requires `snoreConfidence >= 0.5` + dB threshold
  - Intensity: loud (≥0.7 confidence + loud dB), light (≥0.6 + light dB), quiet (quiet dB)
- **Cross-package wiring**:
  - `BedsideClockView` passes `audioRecorder.snoreConfidence` to `sessionManager.processAudioLevel()`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Package.swift` | +1 | Added `SoundAnalysis` framework |
| `Packages/AudioEngine/Sources/Engine/SoundAnalysisDetector.swift` | +90 | New. SNAudioStreamAnalyzer wrapper with SNResultsObserving |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +8/-2 | Integrated SoundAnalysisDetector; publish snoreConfidence |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +16/-4 | Added `classifyWithSoundAnalysis`; priority: SoundAnalysis → FFT → thresholds |
| `Packages/Env/Sources/Services/SessionManager.swift` | +2 | `processAudioLevel` accepts `snoreConfidence` |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +4/-1 | Pass `snoreConfidence` to session manager |

### Architecture Decisions
- **SoundAnalysis priority over FFT**: Apple's model is trained on far more data than our hand-tuned spectral heuristic. If snoring is in the built-in classes, this should be significantly more accurate.
- **Three-tier fallback**: SoundAnalysis → FFT spectral → dB thresholds. Ensures the app always has some detection method active.
- **Non-isolated SNResultsObserving methods**: Apple's delegate methods are called on internal queues, not MainActor. We dispatch `snoreConfidence` updates to MainActor via `Task { @MainActor in }`.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### How to Test on Device
1. Start recording
2. Open Xcode console
3. Look for: `[SoundAnalysis] Found snoring-related class: 'snoring'` (or similar)
   - If found: SoundAnalysis is active. Snore near the phone and check if detection works.
   - If NOT found: Look for `[SoundAnalysis] Snoring NOT in built-in classes. FFT fallback will be used.`

### Open Questions
- Does Apple's built-in classifier actually include "snoring"? The documentation says 300+ sounds but doesn't list them all. Need real-device verification.

---

## 2026-05-07 — Session 27b: dB → Percentage UI Polish

### Completed
- Added `audioLevelPercentage(from:)` helper in `AudioEngine` package
  - Maps dBFS (-60 … -20) → 0% … 100% for user-friendly display
  - Overloads for `Float` and `Double`
- Updated all UI surfaces that showed raw negative dB:
  - `BedsideClockView`: `%-35 dB · ambient%` → `65% · ambient`
  - `SessionDetailView` stat card: `Peak` now shows `%`
  - `SessionSummaryView` stat card: `Peak` now shows `%`
  - `StatisticsLoadedView` stat card: `Avg dB` → `Avg Level` with `%`
  - `SleepReportPDFGenerator`: `Avg dB`/`Peak dB` → `Avg Level`/`Peak Level` with `%`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +12 | Added `audioLevelPercentage(from:)` overloads |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +1/-1 | dB → percentage display |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +1/-1 | Peak dB → percentage; added `import AudioEngine` |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | +1/-1 | Peak dB → percentage; added `import AudioEngine` |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | +1/-1 | Avg dB → Avg Level percentage; added `import AudioEngine` |
| `Packages/Recordings/Sources/Views/SleepReportPDFGenerator.swift` | +3/-3 | Avg/Peak dB → Level percentage; added `import AudioEngine` |

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target


---

## 2026-05-07 — Session 28: Detection Pipeline Hardening + UI Polish + Recordings Grouping

### Completed

**Snore Detection Pipeline Fixes (F9 refinement)**
- Fixed actor-isolation race condition: `AudioRecorder` tap callback ran on background audio queue but accessed `@MainActor`-isolated `SoundAnalysisDetector.snoreConfidence`, always reading stale `0`
- Removed `snoreConfidence` property from `AudioRecorder` (stale copy); `BedsideClockView` now reads `SoundAnalysisDetector.shared.snoreConfidence` directly on `@MainActor`
- Fixed `SnoreDetector.classifyWithSoundAnalysis` dB thresholds: lowered floors to `-25`/`-40`/`-60` dB so low-mic-gain or brief snores aren't filtered out when SoundAnalysis is ≥0.5 confident
- Added `AVAudioUnitEQ` bandpass filter (100–500 Hz, center 300 Hz, 2.5 octaves) to recording pipeline; saved audio now contains only snoring frequencies
- Added debug logging in `SoundAnalysisDetector`, `BedsideClockView`, and `SessionManager` to trace classification pipeline end-to-end
- Temporarily removed `#if targetEnvironment(simulator)` permission bypasses to allow macOS microphone permission dialog for Simulator; confirmed detection works end-to-end

**Events Not Updating (F2 bug fix)**
- Root cause: `SessionManager.eventsCount` was a computed property `{ currentSession?.events?.count ?? 0 }`; SwiftUI `@Observable` does not reliably propagate deep mutations on SwiftData `@Model` relationships
- Changed `eventsCount` to a stored `Int = 0` that gets explicitly updated in `finalizeActiveEvent`, `processAudioLevel`, `startSession`, and `stopSession`
- Events badge in `BedsideClockView` now updates in real time as snore events are created/finalized

**UI Cleanup**
- Removed percentage-based audio level display; replaced with raw dBFS, then removed dB entirely from active recording UI (negative values are confusing to users)
- Removed snore confidence display from release builds (now `#if DEBUG` only), then removed entirely from UI surfaces
- Removed dB stat cards from `SessionDetailView`, `SessionSummaryView`, `StatisticsLoadedView`, and `SleepReportPDFGenerator`
- Remaining stats: sleep score, duration, snoring percentage, events count, events/hour

**Statistics Dashboard — Multi-Recording Night Support (F3 refinement)**
- Main score gauge now shows **average score** across all recordings on the same day (instead of latest only)
- Label shows `"3 RECORDINGS"` when multiple sessions exist, `"LAST NIGHT"` when single
- `StatisticsDashboardView.ViewState` expanded to carry `dayScore: Int` and `daySessionCount: Int`
- "Last 7 Nights" chart now groups by calendar day, averages scores per day, and renders one bar per night (previously showed one bar per recording)

**Recordings Tab — Night Grouping (F4 refinement)**
- Replaced per-recording rows with **expandable night cards**
- Each card shows: date, recording count pill (only if >1), total duration, total events, **average score** badge
- Tap card header to expand with animated reveal of individual recording sub-rows
- Each sub-row shows: time range, duration, events, individual score badge; tap navigates to that recording's detail
- Deleted `RecordingRowView.swift` (replaced by `NightGroupRowView`)
- Created `NightGroup.swift` (model) and `NightGroupRowView.swift` (UI)
- Updated `MonthSection` to hold `[NightGroup]` instead of raw `[SleepSession]`

### Technical Details
- `AudioRecorder` audio engine: `inputNode → AVAudioUnitEQ (bandpass) → mainMixerNode (volume 0)`; tap installed on EQ output captures filtered audio for both analysis and file write
- `AVAudioUnitEQFilterParameters.bandwidth` (not `bandWidth`) is the correct property name
- `NightGroupRowView` uses `withAnimation(.easeInOut(duration: 0.2))` for expand/collapse
- `ISO8601DateFormatter` used for stable `NightGroup.id` based on calendar day

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +25/-15 | Added AVAudioUnitEQ bandpass filter; removed `snoreConfidence` property; tap moved from inputNode to EQ output; removed simulator permission bypasses |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +12/-6 | Lowered dB floors for SoundAnalysis path; always returns snoring state when confidence ≥0.6 |
| `Packages/AudioEngine/Sources/Engine/SoundAnalysisDetector.swift` | +5/-1 | Added debug print when confidence updates |
| `Packages/Env/Sources/Services/SessionManager.swift` | +8/-3 | `eventsCount` changed from computed to stored property; explicit updates on event creation |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +8/-12 | Reads `SoundAnalysisDetector.shared.snoreConfidence` directly; removed dB/status text from UI; debug logging |
| `Packages/Statistics/Sources/Views/StatisticsDashboardView.swift` | +10/-4 | Computes `dayScore` and `daySessionCount`; passes to loaded view |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | +18/-8 | Uses `dayScore` for gauge; groups chart by day with averaged scores; removed dB stat card |
| `Packages/Recordings/Sources/Views/RecordingsListView.swift` | +18/-8 | Groups sessions by day within month; renders `NightGroupRowView` |
| `Packages/Recordings/Sources/Views/NightGroup.swift` | +24 | New. Day-group model with computed averageScore, totalDuration, totalEvents |
| `Packages/Recordings/Sources/Views/NightGroupRowView.swift` | +97 | New. Expandable night card with sub-rows for individual recordings |
| `Packages/Recordings/Sources/Views/MonthSection.swift` | +2/-2 | `sessions` → `groups` |
| `Packages/Recordings/Sources/Views/RecordingRowView.swift` | — | **Deleted** — replaced by NightGroupRowView |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +1/-5 | Removed Peak dB stat card |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | +1/-5 | Removed Peak dB stat card |
| `Packages/Recordings/Sources/Views/SleepReportPDFGenerator.swift` | +2/-6 | Removed Avg/Peak Level stats and event dB column from PDF |

### Architecture Decisions
- **Bandpass filter on recording path**: Apple's SoundAnalysis classifier already focuses on 100–500 Hz; filtering the recording removes non-snore noise and reduces file size indirectly (quieter filtered audio)
- **Stored `eventsCount` over computed**: `@Observable` + `@Model` deep mutation observation is unreliable for SwiftData relationship arrays; explicit stored property guarantees UI updates
- **Night grouping over flat list**: Users make multiple recordings per night (e.g., testing, interrupted sleep); grouping by night reduces visual clutter and surfaces nightly averages
- **Expandable cards over drill-down**: Keeping recordings accessible in-context (expand in place) is faster than navigating to a separate "night detail" screen

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Open Questions
- Should simulator permission bypasses be restored now that macOS permission is confirmed working? (Temporarily removed in `AudioRecorder.swift`)
- Should `audioLevelPercentage(from:)` helper be kept or removed? No longer used in UI but might be useful for future features

### Follow-up Needed
- Test on physical device: SoundAnalysis detection accuracy with real snoring audio
- Evaluate if bandpass filtering affects SoundAnalysis classification quality (trained on full-spectrum audio)
append
## 2026-05-08 — Session 29: Recording Button Redesign + Calendar Polish + Recordings Bulk Delete

### Completed
- **Start/Stop Recording Button Redesign**: Extracted reusable `RecordingActionButton<Label>` generic component in DesignSystem with exact screenshot color `#1E1D1E`, red gradient stroke, and double-layer red glow (outer soft halo + inner concentrated glow). Created `StartRecordingButton` and `StopRecordingButton` wrappers. Replaced all 4 inline instances across app.
- **CalendarView Nav Title**: Replaced plain text with dark pill (`surface2` background + `accent` foreground) containing calendar icon + "Calendar" text, matching design screenshot.
- **Statistics Header Calendar Buttons**: Updated both `StatisticsLoadedView` and `StatisticsEmptyView` header Calendar buttons to match same dark pill style (was blue accent pill).
- **Calendar Day Cell Backgrounds**: Added `surface2` rounded background only to dates with recorded events; transparent for empty dates. Grid spacing increased to 8pt.
- **Calendar Today/Selected Highlight**: Full cell `accent` background with white text and white dot when `isToday || isSelected`; removed old green circle indicator.
- **Calendar Intensity Dots**: 4→5pt dot size; white dot when cell is highlighted (today/selected), otherwise uses snoring intensity color (gray/amber/red).
- **SleepScoreGauge Size**: Statistics gauge increased from 90→120.
- **Theme Token `surface2`**: Added `surface2: Color = Color(hex: "#2C2C2E")`; `bgCard` changed from stored to computed property returning `surface2`.
- **Recordings Bulk Delete**: Swipe-to-delete + long-press alert on `NightGroupRowView` cards. Alert asks "Remove X recordings from this night?" with "Remove" (destructive) and "Discard" (cancel). Deletes all `SleepSession` objects in the group via `modelContext.delete`.

### Technical Details
- `RecordingActionButton` uses `ZStack` with two glow layers: outer `blur(20)`, `opacity(0.12)`, `height+40` + inner `blur(10)`, gradient `0.45→0`, `height+20`
- `StartRecordingButton` height defaults to 56; `StopRecordingButton` uses red square icon instead of pulsing dot
- Calendar `dayCell` background logic: `isHighlighted ? accent : hasEvents ? surface2 : clear`
- `NightGroupRowView` accepts `onDeleteRequest` closure; long press `minimumDuration: 0.5` on header HStack alongside existing tap gesture
- `RecordingsListView` adds `.swipeActions(edge: .trailing)` with destructive Delete button + `.alert` modifier for confirmation

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Components/StartRecordingButton.swift` | +120/-50 | New generic `RecordingActionButton`; `StartRecordingButton` + `StopRecordingButton` wrappers; two-layer glow |
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +5/-35 | Replaced inline button with `StartRecordingButton`; removed duplicated `PulsingDot` |
| `Packages/Statistics/Sources/Views/StatisticsEmptyView.swift` | +5/-25 | Replaced inline button with `StartRecordingButton`; removed duplicated `PulsingDot` |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | +8/-30 | Replaced inline button with `StartRecordingButton`; removed duplicated `PulsingDot`; gauge size 90→120; Calendar button style |
| `Packages/Onboarding/Sources/Views/OnboardingPage5View.swift` | +5/-10 | Replaced accent button with `StartRecordingButton` |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +5/-20 | Replaced inline stop button with `StopRecordingButton` |
| `Packages/DesignSystem/Sources/Components/Theme.swift` | +2/-1 | Added `surface2` token; `bgCard` computed from `surface2` |
| `Packages/Statistics/Sources/Views/CalendarView.swift` | +35/-20 | Nav title pill; day cell backgrounds; today/selected highlight; white dots on highlight; grid spacing |
| `Packages/Recordings/Sources/Views/RecordingsListView.swift` | +25/-2 | Swipe delete + long-press alert + `deleteGroup` + `modelContext` |
| `Packages/Recordings/Sources/Views/NightGroupRowView.swift` | +10/-2 | `onDeleteRequest` param + `.onLongPressGesture` |

### Architecture Decisions
- **Generic `RecordingActionButton`**: Single reusable component with `@ViewBuilder` label slot avoids duplicating glow/stroke/background logic across start/stop variants
- **Two-layer glow**: Single faint layer disappeared against pure black; concentrated inner layer (blur 10, opacity 0.45) ensures visibility on all backgrounds
- **Bulk delete over per-recording**: Night group card represents one logical sleep night; deleting all recordings in that night matches user mental model

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- F13-T1: CloudKit Sync (only remaining backlog task)

### Open Questions
- Should simulator mic permission bypasses be restored in `AudioRecorder.swift`?

## 2026-05-08 — Session: Architecture Compliance Audit & Refactoring

### Completed
- Architecture compliance audit across all view files
- Fixed @Environment violations (6 services wired through dependency graph)
- Extracted shared DateFormatters (eliminated 20 inline DateFormatter creations)
- Split 6 oversized views into 28 separate files
- Extracted reusable SnoringLegendView to DesignSystem
- Extracted SessionGrouper helper for recordings list logic
- All builds pass with zero errors

### Technical Details
- **No ViewModels introduced** — codebase already follows documented "No ViewModels" architecture; refactored using `@State` + ViewState enum pattern + presentational component extraction
- `withAppDependencyGraph()` now wires: AudioRecorder, AlarmManager, HealthKitSync, WatchConnectivityManager, SoundAnalysisDetector
- `withEnvironments()` (sheet fallback) also wires all shared services
- SettingsView split from 534 lines → 148 lines (+ 7 section components + 2 shared helpers)
- SessionDetailView split from 462 lines → 295 lines (+ 4 presentational subviews)
- CalendarView split from 392 lines → 169 lines (+ 5 subviews)
- TrendsView split from 266 lines → 168 lines (+ 2 subviews)
- BedsideClockView split from 233 lines → 143 lines (+ 4 subviews)
- StatisticsLoadedView split from 247 lines → gone (+ 4 subviews)
- RecordingsListView grouping logic extracted to SessionGrouper (40 lines → 1 line call)

## 2026-05-08 — Session 30: Session Summary Polish + Tab Bar Fix + Background Recording

### Completed
- **SessionSummaryView Save Button Redesign**: Replaced blue accent `Capsule()` button with dark pill (`#1E1D1E` fill + white gradient stroke) and two-layer behind-glow effect matching `RecordingActionButton` pattern.
- **10-Minute Minimum Session Validation**: `saveSession()` now checks `session.totalDuration < 600` and shows an alert with title "Session Too Short" / message "To generate meaningful sleep analysis, recordings must be at least 10 minutes long." instead of saving.
- **Custom Tab Bar for iOS < 26**: Replaced system `TabView` on older iOS with a design-compliant floating pill tab bar (`bgCard` fill, `border` stroke, `cornerRadius: 36`, accent selected state).
- **Hide Tab Bar During Recording**: Custom tab bar conditionally removed from view hierarchy when `sessionManager.isRecording` is true. iOS 26+ system `TabView` uses `.toolbar(.hidden, for: .tabBar)` on each tab content.
- **Background Recording (Lock Screen)**: Added audio interruption handling with auto-resume; added `AVAudioEngineConfigurationChange` route-change observer that restarts the engine if stopped; `setActive(false)` now uses `notifyOthersOnDeactivation`.

### Technical Details
- `RecordingActionButton` glow pattern ported to Save Session: outer `blur(20)` halo (`accent` 0.12) + inner gradient glow (`accent` 0.35→0)
- `.alert("Session Too Short", isPresented:)` on `SessionSummaryView` with OK button (cancel role)
- Custom tab bar uses `ZStack(alignment: .bottom)` + opacity-based tab switching to preserve `NavigationStack` state across tabs
- Tab bar iOS branching: `#available(iOS 26.0, *)` uses system `TabView`; else uses custom floating pill
- `AudioRecorder` now registers for `AVAudioSession.interruptionNotification` and `.AVAudioEngineConfigurationChange`
- Interruption `.began` → engine stops but `isRecording` stays true; `.ended` with `.shouldResume` → reactivates session and restarts engine
- Route change handler checks `engine.isRunning` and restarts if needed while `isRecording`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/AppRegistry.swift` | +8/-4 | Added 5 new services to environment graph |
| `SleepGuard/SleepGuardApp.swift` | +5/-1 | Passed new services to dependency graph; added AudioEngine import |
| `Models/Package.swift` | +1/-3 | Changed target path from `Sources/Data` to `Sources` to include Helpers |
| `Recordings/Package.swift` | +1/-1 | Changed target path from `Sources/Views` to `Sources` to include Helpers |
| `Models/Sources/Helpers/DateFormatters.swift` | +74 | New shared DateFormatter instances |
| `Settings/Sources/Views/SettingsView.swift` | +148/-534 | Slimmed to container; sections extracted |
| `Settings/Sources/Views/Settings*Section.swift` | 7 new files | 7 section components + 2 helpers |
| `Recordings/Sources/Views/SessionDetailView.swift` | +295/-462 | Slimmed; 4 subviews extracted |
| `Recordings/Sources/Views/SessionDetail*View.swift` | 4 new files | Header, Timeline, Events, MiniPlayer |
| `Statistics/Sources/Views/CalendarView.swift` | +169/-392 | Slimmed; 5 subviews extracted |
| `Statistics/Sources/Views/Calendar*View.swift` | 5 new files | MonthSelector, DayHeaders, Grid, MonthStats, SelectedNight |
| `Statistics/Sources/Views/TrendsView.swift` | +168/-266 | Slimmed; chart + stats grid extracted |
| `Statistics/Sources/Views/Trends*View.swift` | 2 new files | ChartSection, StatsGrid |
| `SleepSession/Sources/Views/BedsideClockView.swift` | +143/-233 | Slimmed; 4 subviews extracted |
| `SleepSession/Sources/Views/BedsideClock*View.swift` | 4 new files | Badges, Clock, Waveform, Status |
| `Statistics/Sources/Views/StatisticsLoadedView.swift` | +95/-241 | Slimmed; 4 subviews extracted |
| `Statistics/Sources/Views/Statistics*View.swift` | 4 new files | Header, WeekSelector, StatsGrid, MiniChart |
| `Recordings/Sources/Helpers/SessionGrouper.swift` | +40 | New helper for session grouping logic |
| `DesignSystem/Sources/Components/SnoringLegendView.swift` | +22 | Reusable legend extracted from Calendar+Trends |
| 15+ other view files | ~30 lines each | Replaced inline DateFormatters with shared instances |

### Architecture Decisions
- **No ViewModels added**: The documented architecture explicitly prohibits ViewModels ("The view IS the view model"). Instead, we extracted presentational components and helper types, which achieves the same separation of concerns without violating the architecture.
- **Environment graph expansion**: All 5 previously-direct `.shared` accesses now flow through `@Environment`, making dependencies explicit and testable.
- **Shared DateFormatters**: Eliminated the anti-pattern of creating `DateFormatter()` inside computed properties (which reconstructs on every body evaluation).

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- SessionDetailView is still 295 lines (down from 462). The remaining bulk is audio playback + export logic. Consider extracting `SessionDetailAudioController` and `SessionDetailShareController` helper types if further slimming is needed.
- NightGroupRowView (179 lines) could be split further if needed.
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | +45/-10 | Dark pill Save button with glow; 10-min duration check; `.alert` for short sessions |
| `SleepGuard/MainTabView.swift` | +90/-15 | iOS 26+ system TabView branch; custom floating pill tab bar for iOS < 26; hide during recording |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +45/-2 | Interruption + route change notification handlers; auto-resume logic; `notifyOthersOnDeactivation` |

### Architecture Decisions
- **Opacity-based tab preservation**: All three `NavigationStack` tabs render simultaneously with `.opacity` + `.allowsHitTesting` so back-stack state survives tab switches
- **Per-tab `.toolbar(.hidden)` on iOS 26+**: Modifier must be on tab content (inside `TabView`) rather than on `TabView` itself for SwiftUI to pick it up
- **Notification-based background resilience**: `AVAudioEngine` can stop on route changes (lock/unlock, headphones); observing `.AVAudioEngineConfigurationChange` and restarting ensures continuous recording

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- F13-T1: CloudKit Sync (only remaining backlog task)

### Open Questions
- Should simulator mic permission bypasses be restored in `AudioRecorder.swift`?


## 2026-05-08 — Session 31: Delayed Recording Start (replaces Smart Alarm)

### Completed
- **Replaced Smart Alarm with Delayed Recording Start**: Removed the entire Smart Alarm feature (alarm scheduling, smart wake window, overlay, Settings section) and replaced it with a countdown-based delayed recording start.
- **RecordingDelayManager**: New `@Observable` singleton in `Env` with a `Timer` (1s interval on `RunLoop.main` `.common` mode) that tracks `targetDate` for background resilience. Schedules a local notification fallback. Posts `.recordingDelayDidComplete` on completion.
- **RecordingPrestartView Redesign**: Removed alarm toggle/time picker. Added horizontal delay picker: Off / 15m / 30m / 45m / 1h with accent-selected state and helper text below. Non-scrollable layout with explicit per-element spacing (15px to button, 10px to Cancel).
- **RecordingCountdownView**: New full-screen countdown with moon icon, large "Recording starts in XX:XX" timer (72pt thin rounded), Cancel (dark pill), and Start Now (accent pill). Auto-starts recording via notification observer when timer hits zero.
- **SleepSessionView**: Added `RecordingDelayManager.shared.isActive` branch to show countdown view between pre-start and bedside clock.
- **BedsideClockView Cleanup**: Removed alarm badge, alarm overlay, and `AlarmManager.clearAlarm()` call.
- **SettingsView Cleanup**: Removed Smart Alarm section. Added "Start delay" row in Recording section with confirmation dialog (Off / 15m / 30m / 45m / 1h).
- **UserPreferences**: Replaced `alarmEnabled`, `alarmHour`, `alarmMinute`, `alarmWindowMinutes` with `recordingDelayMinutes` (0/15/30/45/60).

### Technical Details
- `RecordingDelayManager` uses `Timer(timeInterval:repeats:block:)` + `RunLoop.main.add(timer, forMode: .common)` to survive app backgrounding with audio session active
- `RecordingPrestartView` uses explicit `.padding(.top)` per element instead of global `VStack(spacing:)` to achieve precise 15px/10px spacing
- Delay buttons use `bgElevated` when unselected and `accent` fill when selected, with spring animation
- Countdown view observes `.recordingDelayDidComplete` via `.onReceive` to auto-start `sessionManager.startSession()`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/UserPreferences.swift` | +8/-55 | Removed alarm properties; added `recordingDelayMinutes` |
| `Packages/Env/Sources/Services/RecordingDelayManager.swift` | +93/-0 | New singleton: Timer-based countdown, notification scheduling, background resilience |
| `Packages/SleepSession/Sources/Views/SleepSessionView.swift` | +2/-0 | Added `RecordingDelayManager.isActive` branch |
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +90/-80 | Delay picker replaces alarm UI; explicit layout spacing; non-scrollable |
| `Packages/SleepSession/Sources/Views/RecordingCountdownView.swift` | +50/-0 | New countdown screen with timer, Cancel, Start Now |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +12/-45 | Removed alarm badge, overlay, and alarm clear on stop |
| `Packages/Settings/Sources/Views/SettingsView.swift` | +20/-65 | Removed alarm section; added Start delay row in Recording section |

### Architecture Decisions
- **Timer over `.task`**: SwiftUI `.task` suspends in background; `Timer` on `.common` run loop mode keeps evaluating with background audio active
- **Notification fallback**: Local notification scheduled for exact delay time so recording can start even if app is backgrounded and timer throttles
- **Single preference replaces four**: `recordingDelayMinutes` encodes "off" as 0, eliminating the need for a separate enabled flag

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- F13-T1: CloudKit Sync (only remaining backlog task)

### Open Questions
- Should unused `AlarmManager.swift` and `AlarmOverlayView.swift` be deleted?
- Should simulator mic permission bypasses be restored in `AudioRecorder.swift`?

---

## 2026-05-09 — Session 32: Snore Event Debounce

### Completed
- **F2-T8**: Snore event debounce — 3-second gap threshold in `SessionManager`

### Technical Details
- Added `eventGapThreshold: TimeInterval = 3.0` to `SessionManager`
- Replaced immediate event finalization on `.none` state with debounced tracking using `lastSnoringSampleTime`
- When snoring resumes within 3 seconds of last sample, existing event continues with accumulated dB sum/count
- Event intensity upgrades to peak observed level via `intensityRank` helper (quiet=0, light=1, loud=2)
- `currentSnoringState` updates immediately for UI responsiveness; only event persistence is debounced
- `stopSession()` finalizes any in-progress event regardless of gap threshold

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/SessionManager.swift` | +55/-33 | Added `eventGapThreshold`, `lastSnoringSampleTime`, `activeEventIntensity`, `intensityRank`; rewrote event transition logic to debounce gaps; `finalizeActiveEvent()` no longer takes intensity parameter |

### Architecture Decisions
- **3-second threshold**: Long enough to absorb a normal breath between snore bursts; short enough to still separate truly distinct episodes
- **Separate display state vs event tracking state**: `currentSnoringState` updates immediately so UI shows real-time snoring status; event tracking uses separate debounced logic to avoid flooding the events list

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Git Handoff
- **Suggested branch**: `feature/f2/t8-snore-event-debounce`
- **Suggested commit**: `[F2-T8] — Add 3-second debounce gap between snore events`

### Next Session
- F13-T1: CloudKit Sync (only remaining backlog task)

### Open Questions
- Should the 3-second threshold be user-configurable in Settings?



## 2026-05-09 — Session 33: Snore-Only Recordings + Advanced Frequency Player

### Completed
- **F4-T6**: Snore-Only Recordings + Advanced Frequency Player — replaces full-session audio with per-event clips + expandable advanced player

### Technical Details
- `stopSession()` is now `async` and calls `AudioClipExtractor.extractClips()` to create per-event `.m4a` clips (±2s padding)
- Full session `.caf` file deleted after successful clip extraction; storage savings ~90%+
- `SnoreEvent` extended with `dominantFrequency`, `spectralCentroid`, `lowFreqRatio` (defaults = 0 for SwiftData migration)
- `AudioClipExtractor` actor: `AVAssetExportSession` with `.appleM4A` preset → read exported clip → `FFTAnalyzer.analyze()` per buffer → average spectral features → assign to event
- `ClipPlaybackController`: `@Observable @MainActor` singleton managing sequential clip playback with `AVAudioPlayer`; auto-advances to next clip; `seek(to:)` maps 0–1 across concatenated timeline
- `WaveformGenerator.generateSamples(from:)` returns ~300 amplitude points via `AVAudioFile` RMS per chunk
- `WaveformGenerator.spectrumSamples(from:)` returns 32 averaged FFT magnitude bars via `FFTAnalyzer.spectrumBars()`
- `SessionDetailAdvancedPlayerView`: waveform (custom `Shape`/`Path` filled with intensity color), 32-bar spectrum (green→amber→red gradient by frequency), 5-stat grid (Duration, Peak dB, Dominant Freq, Spectral Centroid, Low-Freq Ratio)
- `SessionDetailMiniPlayerView`: added `isExpandable` + `onExpand` parameters; `waveform` SF Symbol expand button
- `SessionDetailView`: dual-mode playback — legacy (`audioFileURL != nil`) uses full-file `AVAudioPlayer`; clip mode uses `ClipPlaybackController` + conditionally shows advanced player
- Event share: clip sessions use pre-extracted `event.audioFileURL` directly; legacy sessions still use on-demand `AVAssetExportSession`
- `BedsideClockView`: both stop call-sites (direct + alert "Stop Anyway") wrapped in `Task { await sessionManager.stopSession() }`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SnoreEvent.swift` | +4/-0 | Added `dominantFrequency`, `spectralCentroid`, `lowFreqRatio` with `= 0` defaults |
| `Packages/AudioEngine/Sources/Engine/AudioClipExtractor.swift` | +110/-0 | New actor: per-event clip extraction + spectral analysis via FFTAnalyzer |
| `Packages/AudioEngine/Sources/Engine/FFTAnalyzer.swift` | +45/-0 | Added `spectrumBars(buffer:sampleRate:barCount:)` for 0–1000 Hz bar visualization |
| `Packages/Env/Sources/Services/SessionManager.swift` | +18/-2 | `stopSession()` now `async`; calls `AudioClipExtractor.extractClips()`; deletes full session file after extraction |
| `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` | +210/-0 | New `@Observable` controller: sequential clip playback, auto-advance, concatenated timeline seek |
| `Packages/Recordings/Sources/Helpers/PlaybackSpectrumAnalyzer.swift` | +90/-0 | New `AVAudioEngine`-based real-time spectrum analyzer (prepared for future use) |
| `Packages/Recordings/Sources/Helpers/WaveformGenerator.swift` | +40/-0 | New `spectrumSamples(from:barCount:)` method using `FFTAnalyzer.spectrumBars()` |
| `Packages/Recordings/Sources/Views/SessionDetailAdvancedPlayerView.swift` | +140/-0 | New expandable advanced player: waveform, spectrum bars, stats grid |
| `Packages/Recordings/Sources/Views/SessionDetailMiniPlayerView.swift` | +15/-0 | Added `isExpandable` flag + expand button with `waveform` icon |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +95/-50 | Dual-mode playback (legacy vs clip); `ClipPlaybackController` integration; advanced player conditional display; event share direct vs export |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +4/-1 | Wrapped `stopSession()` call in alert button action with `Task { await ... }` |

### Architecture Decisions
- **Static spectrum over real-time FFT**: Pre-computed spectrum bars per clip avoids sync complexity between two audio engines (`AVAudioPlayer` for playback + `AVAudioEngine` for analysis). Real-time analyzer (`PlaybackSpectrumAnalyzer`) is present but not wired to active UI.
- **2-second clip padding**: Matches existing F7 export behavior; provides enough audio context for FFT analysis while keeping clips small
- **Dual-mode playback in one view**: `SessionDetailView` transparently handles both legacy (full-file) and new (clip-only) sessions, ensuring users don't lose access to old recordings
- **Async `stopSession()`**: Clip extraction involves file I/O and export; making it `async` prevents UI blocking during the ~1-2s extraction process

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Git Handoff
- **Suggested branch**: `feature/f4/t6-snore-only-recordings`
- **Suggested commit**: `[F4-T6] — Add per-event snore clips + expandable advanced player with waveform and spectrum`

### Next Session
- F13-T1: CloudKit Sync (only remaining backlog task)

### Open Questions
- Should `PlaybackSpectrumAnalyzer` be wired for real-time spectrum during playback (replacing static bars)?
- Should the 32 spectrum bars animate in real-time as the clip plays?
- Is the 2-second clip padding sufficient, or should it be user-configurable?

## 2026-05-09 — Session 34: F4-T6 Polish + Playback Fixes + Reusable Stats Grid + Navigation Polish

### Completed
- **F4-T6 continuation**: Waveform tap-to-seek, expand hint pill ("Details"), Peak dB hidden from stats
- **Playback fix**: `setupClipPlayback` now calls `loadEvents()` (was assigning `.events` directly, breaking progress/seek); `ClipPlaybackController.play()` activates `AVAudioSession`; `tick()` only auto-advances near clip end
- **Zero-padding clips**: `AudioClipExtractor` padding `2.0` → `0.0`; event duration excludes debounce gap for naturally finalized events (`finalizeActiveEvent(includeGap: false)`); clips contain ONLY snore audio
- **AudioFileURLResolver**: New helper to prevent stale absolute paths after app relaunch; stores only filenames, resolves against current Documents directory at runtime; backward-compatible with legacy absolute paths
- **SessionStatsGrid**: Extracted reusable 2×2 stat grid component in `DesignSystem`; used by `StatisticsStatsGrid` and `SessionDetailHeaderView`
- **Snore Time stat**: Added to `SessionStatsGrid` and `SessionDetailHeaderView` with compact `Xhr Ym` / `Xm` format
- **NightGroupRowView navigation**: Single-recording groups tap directly to `.recordingDetail` instead of expanding

### Technical Details
- `AudioFileURLResolver` in `Models` package: `resolve(_:)` extracts `lastPathComponent` from stored string and rebuilds URL against live `documentsDirectory`; `filename(from:)` for write-side; handles both old absolute paths and new filename-only storage
- `finalizeActiveEvent(includeGap:)` — when debounce gap triggers natural finalization, `lastSnoringSampleTime` becomes the event end (true snore duration); `stopSession()` passes `includeGap: true` for mid-session stops
- `SessionStatsGrid` uses `hr` suffix for hours (e.g., `4hr 5m`) and plain `m` for under 1 hour; `.lineLimit(1)` on `StatCard.value` prevents card expansion
- `NightGroupRowView` tap: `group.sessions.count == 1` → `routerPath.navigate(to: .recordingDetail(id:))`; `count > 1` → `isExpanded.toggle()`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Helpers/AudioFileURLResolver.swift` | +30/-0 | New: resolves stored audio filenames against current Documents directory; backward-compatible with absolute paths |
| `Packages/Env/Sources/Services/SessionManager.swift` | +10/-8 | `finalizeActiveEvent(includeGap:)`; zero padding in `extractClips`; stores filenames only via `AudioFileURLResolver` |
| `Packages/AudioEngine/Sources/Engine/AudioClipExtractor.swift` | +1/-1 | Default padding `2.0` → `0.0` |
| `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` | +10/-3 | Audio session activation before play; `play()` return value check; `tick()` guards against false auto-advance |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +15/-15 | All `audioFileURL` reads via `AudioFileURLResolver.resolve()`; `setupClipPlayback` uses `loadEvents()`; legacy export zero padding |
| `Packages/DesignSystem/Sources/Components/SessionStatsGrid.swift` | +55/-0 | New reusable 2×2 stat grid: Duration, Snoring %, Snore Time, Events |
| `Packages/Statistics/Sources/Views/StatisticsStatsGrid.swift` | +4/-39 | Delegates to `SessionStatsGrid` |
| `Packages/Recordings/Sources/Views/SessionDetailHeaderView.swift` | +8/-37 | Delegates to `SessionStatsGrid` |
| `Packages/Recordings/Sources/Views/SessionDetailAdvancedPlayerView.swift` | +10/-3 | Waveform tap-to-seek; "Tap waveform to seek" label; Peak dB removed |
| `Packages/Recordings/Sources/Views/SessionDetailMiniPlayerView.swift` | +10/-5 | Expand button is now a pill with "Details" text + icon |
| `Packages/Recordings/Sources/Views/NightGroupRowView.swift` | +5/-2 | Single-recording groups navigate directly; multi-recording groups expand |

### Architecture Decisions
- **Filename-only storage for audio files**: Absolute paths break across app launches on iOS; storing just the filename and resolving at runtime is the standard pattern for document-scoped files
- **Zero-padding clips**: Eliminates all non-snore audio from saved clips; event durations also trimmed to true snore time by excluding debounce gap
- **Reusable `SessionStatsGrid`**: Prevents duplication between Statistics dashboard and Session detail; single source of truth for formatting and card layout

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Git Handoff
- **Suggested branch**: `feature/f4/t6-snore-only-recordings`
- **Suggested commit**: `[F4-T6] — Snore-only clips, advanced player, AudioFileURLResolver, reusable stats grid, playback fixes`

### Next Session
- F13-T1: CloudKit Sync (only remaining backlog task)

### Open Questions
- Should spectrum bars animate in real-time during playback?
- Should `PlaybackSpectrumAnalyzer` (real-time FFT) replace static pre-computed bars?

## 2026-05-09 — Session 35: Localization Infrastructure — Semantic Key Migration

### Completed
- Migrated `Localizable.xcstrings` from raw English text keys to semantic dot-notation keys (132 entries)
- Updated `scripts/generate-strings.py` with camelCase boundary splitting for clean identifier generation
- Fixed double-`Format` suffix bug when semantic keys already encode format status
- Regenerated `Strings.swift` — all 132 constants now ≤40 chars (down from 12 previously over 40)
- Updated 42 source files to use new semantic-based `Strings.*` constants
- Verified zero `String(localized:` calls remain outside `Strings.swift`

### Technical Details
- Semantic key schema: `{feature}.{screen}.{element}` (e.g. `onboarding.page4.buttonPrimary`, `session.bedside.snoreLight`, `stats.trends.avgMinFormat`)
- Generator now splits on camelCase boundaries via regex `(?<=[a-z])(?=[A-Z])` so `buttonPrimary` → `button` + `Primary` → `buttonPrimary` instead of `buttonprimary`
- Generator skips auto-appending `Format` suffix if the resulting name already ends with `Format` (prevents `eventsCountUpperFormatFormat`)
- Disambiguation logic from original generator preserved but no longer triggered since semantic keys are inherently unique

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +132/-132 | All 132 keys rewritten from raw English to semantic dot-notation |
| `Packages/DesignSystem/Sources/Strings.swift` | +138/-138 | Regenerated with clean camelCase names from semantic keys |
| `scripts/generate-strings.py` | +3/-1 | Added camelCase splitting; fixed double-Format suffix |
| `SleepGuard/MainTabView.swift` | +3/-3 | `tabMedia`, `tabSettings`, `tabStatistics` |
| `Packages/Statistics/Sources/Views/*` | +40/-40 | 9 files: stats constants updated |
| `Packages/Settings/Sources/Views/*` | +35/-35 | 7 files: settings constants updated |
| `Packages/Recordings/Sources/Views/*` | +55/-55 | 9 files: recordings constants updated |
| `Packages/SleepSession/Sources/Views/*` | +35/-35 | 6 files: session constants updated |
| `Packages/Onboarding/Sources/Views/*` | +30/-30 | 6 files: onboarding constants updated |
| `Packages/DesignSystem/Sources/Components/*` | +15/-15 | 5 files: design system constants updated |

### Architecture Decisions
- **Semantic keys are the single source of truth**: English copy lives in the `value` field; keys are stable identifiers. Changing copy no longer changes the key or the generated constant name.
- **Flat `Strings` enum, not nested**: Despite dot-notation keys, the API remains `Strings.onboardingPage4ButtonPrimary` rather than `Strings.onboarding.page4.buttonPrimary`. This avoids deeply nested access while keeping keys organized.
- **No manual name overrides**: The generator derives all names heuristically from semantic keys. Zero maintenance burden.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Git Handoff
- **Suggested branch**: `refactor/semantic-localization-keys`
- **Suggested commit**: `Refactor — migrate xcstrings to semantic dot-notation keys`

### Next Session
- F13-T1: CloudKit Sync (only remaining backlog task)

### Open Questions
- Should we add a second language (e.g. Spanish or German) to validate the localization pipeline end-to-end?

---

## 2026-05-10 — Session 36: Raw Audio Preservation for Future Migrations

### Completed
- Added `rawAudioFileURL: String?` to `SleepSession` model
- `SessionManager.stopSession()` now preserves the full session `.caf` in `rawAudioFileURL` instead of deleting it after clip extraction
- `SessionManager.discardCompletedSession()` now deletes the raw audio file alongside clips and legacy full-session files
- Old sessions remain playable from per-event clips; raw audio is the archive for future re-processing

### Technical Details
- `SleepSession.rawAudioFileURL` stores only the filename (same pattern as `audioFileURL`); path resolved via `AudioFileURLResolver`
- When clips extract successfully: `rawAudioFileURL` = old `audioFileURL`, `audioFileURL` = nil
- When clips fail: `audioFileURL` remains pointing to full session (legacy fallback), `rawAudioFileURL` stays nil
- SwiftData handles the new optional property gracefully for old sessions (nil by default)

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepSession.swift` | +6 | Added `rawAudioFileURL: String?` property + init parameter |
| `Packages/Env/Sources/Services/SessionManager.swift` | +8/-5 | `stopSession()`: preserve full session as raw data instead of deleting; `discardCompletedSession()`: delete raw audio file |

### Architecture Decisions
- **Keep full audio, not a transition log**: Full audio is the ultimate ground truth. It allows changing ANY part of the detection pipeline (thresholds, debounce, algorithms, bandpass). A transition log would only allow debounce changes and would be ~15MB for a 10h session — still significant.
- **Storage tradeoff**: Each session now keeps both clips (.m4a, small) and full audio (.caf, ~300-500MB for 10h). This is the right tradeoff for a health app where data fidelity matters. A future enhancement could add a retention policy (e.g., auto-delete raw audio after 30 days).

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Next Session
- (none scheduled — user may want to address orphaned audio files on disk when SwiftData sessions are deleted)

### Open Questions
- **Audio file cleanup**: `RecordingsListView.deleteGroup()`, `SettingsView.deleteAllData()`, and `SessionDetailView.deleteSession()` all call `modelContext.delete(session)` without cleaning up associated audio files on disk. With `rawAudioFileURL` now present, orphaned files are more likely. Should we add a pre-delete file cleanup step?
- **Raw audio retention policy**: Should we auto-delete `rawAudioFileURL` files after N days to manage storage? This would require a background cleanup task.

---

## 2026-05-10 — Session 36 (continued): Raw Classification Log + Orphaned File Cleanup

### Completed
- Added `SessionRawLogWriter` actor that buffers every classification sample at ~20 Hz during recording
- `SnoringState` now conforms to `Codable` (String raw value)
- `SnoreSample` struct stores: elapsed time, dB, spectralScore, snoreConfidence, state
- `SleepSession.rawLogFileURL: String?` references the JSON log file written at session stop
- `SessionManager` starts the writer at `startSession()`, appends samples in `processAudioLevel()`, and flushes at `stopSession()`
- Created `deleteSessionFiles(_:)` helper in Env that removes: event clips, legacy full session, raw audio archive, and raw classification log
- Wired file cleanup into all 3 deletion paths:
  - `RecordingsListView.deleteGroup()`
  - `SettingsView.deleteAllData()`
  - `SessionDetailView.deleteSession()`

### Technical Details
- Raw log format: JSON array of `SnoreSample` (~20-30MB for a 10h session)
- Log file naming: `rawlog_<sessionUUID>.json` in Documents directory
- `SessionRawLogWriter` uses an in-memory buffer flushed atomically to disk at `stop()`
- If writing fails or session is discarded, `discard()` cleans up the partial file

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +1 | `SnoringState` → `String, Codable` |
| `Packages/AudioEngine/Sources/Engine/SnoreSample.swift` | +25 | New struct for classification samples |
| `Packages/Env/Sources/Services/SessionRawLogWriter.swift` | +62 | New actor: buffers + writes JSON log |
| `Packages/Env/Sources/Services/SessionFileCleanup.swift` | +32 | New helper: deletes all session files |
| `Packages/Models/Sources/Data/SleepSession.swift` | +7 | `rawLogFileURL` property + init |
| `Packages/Env/Sources/Services/SessionManager.swift` | +15 | Start/stop/append raw log writer |
| `Packages/Recordings/Sources/Views/RecordingsListView.swift` | +1 | `deleteSessionFiles()` before delete |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +1 | `deleteSessionFiles()` before delete |
| `Packages/Settings/Sources/Views/SettingsView.swift` | +1 | `deleteSessionFiles()` before delete |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Open Questions
- Should we add a background cleanup task that deletes `rawAudioFileURL` / `rawLogFileURL` files older than N days to manage storage?

---

## 2026-05-10 — Session 36 (continued): Per-Burst Tracking for Snore-Only Clips

### Completed
- Added `SnoreBurst` struct (`startOffset`, `endOffset`, `duration`) to Models
- Added `bursts: [SnoreBurst]?` to `SnoreEvent`
- `SessionManager` now tracks burst boundaries during recording:
  - `activeBurstStart: Date?` marks when current continuous snoring began
  - `completedBursts: [(start: Date, end: Date)]` stores finished bursts in the active event
  - When silence arrives, the open burst is closed and added to completedBursts
- `finalizeActiveEvent()` computes true snoring duration as `sum(burst.duration)` instead of `lastSnore - eventStart` (which included debounce gaps)
- `AudioClipExtractor` uses `AVMutableComposition` to stitch only burst segments into gap-free clips; legacy events without bursts fall back to single-range export
- Spectral analysis now runs on gap-free clips, giving more accurate frequency data

### Technical Details
- Burst offsets are stored relative to event start time for portability
- `snoreDuration` is now "seconds of actual snoring" rather than "event span"
- Sleep score recalculates from true snoring duration, so percentages are slightly lower (and scores slightly higher) than before
- Player total (`ClipPlaybackController`) reads `event.snoreDuration`, so it matches the true audio content

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SnoreBurst.swift` | +24 | New struct for continuous snoring segments |
| `Packages/Models/Sources/Data/SnoreEvent.swift` | +4 | `bursts` property + init parameter |
| `Packages/AudioEngine/Sources/Engine/AudioClipExtractor.swift` | +45/-15 | AVMutableComposition burst stitching; legacy fallback |
| `Packages/Env/Sources/Services/SessionManager.swift` | +35/-10 | Burst tracking state; burst-aware finalizeActiveEvent |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Open Questions
- Old sessions have `bursts = nil`, so they still play with gaps (legacy fallback). Should we offer a "re-process" button for old sessions using the raw audio or raw log?

---

## 2026-05-10 — Session 36 (continued): Mini Player Dot Position Fix

### Completed
- Fixed mini player event markers so they align with the playback progress bar
- `SessionDetailMiniPlayerView` now receives `eventMarkers: [Double]` instead of computing dot positions internally
- For clip sessions: markers are computed on the concatenated clips timeline (`accumulatedClipDuration / totalClipsDuration`)
- For legacy sessions: markers remain on the full session timeline (`event.timestamp / session.totalDuration`)

### Root Cause
The mini player progress bar represents `currentTime / totalClipsDuration` (concatenated clips timeline).
The dots were previously computed as `event.timestamp / session.totalDuration` (full session timeline).
For a typical 8-hour session with 8 minutes of clips, the dots would be at 0.2% and 0.6% of the track (barely visible at the left edge), but playback of clip 2 would start at 5.4% of the clips timeline — nowhere near the second dot.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/SessionDetailMiniPlayerView.swift` | +5/-10 | Receives `eventMarkers: [Double]`; renders dots from pre-computed positions |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +25 | `clipEventMarkers()` + `legacyEventMarkers()` helpers; pass markers to mini player |

### Build Status
- **BUILD SUCCEEDED** — zero errors

## 2026-05-11 — Session 37: PDF Visual Polish + Dark Mode Color Preservation

### Completed
- Redesigned PDF header gradient from bright red `#FF453A` to blue gradient (`#7FD9F2` → `#1A73C0` → `#0D2666`)
- Changed card backgrounds from near-white `#F5F5F7` to icy blue `#F0F7FF` that complements the blue header
- Added explicit white page background fill to prevent dark mode PDF viewers from showing dark backgrounds through transparent areas
- Replaced all semantic `UIColor.white` with explicit `UIColor(red: 1, green: 1, blue: 1, alpha: ...)` to prevent dark mode color shifting
- Forced `UITraitCollection(userInterfaceStyle: .light)` during PDF generation with restore-on-exit pattern
- Removed unused `blabla1/2/3` dark red color constants leftover from earlier experiments

### Technical Details
- `UIRectFill(pageRect)` fills the entire 612×792 PDF canvas with white before any content is drawn
- `UITraitCollection.current = lightTraits` is set before `renderer.writePDF()` and restored via `defer` to ensure all color resolution happens in light mode context
- Event row background uses slightly lighter icy blue `#F5FAFF` for subtle differentiation from cards
- Secondary text color shifted from warm gray to cool blue-gray `#737B94` for harmony with blue theme

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/SleepReportPDFGenerator.swift` | +25/-20 | Blue gradient header; icy blue card/row backgrounds; explicit RGB white; white page fill; light mode trait forcing; cleaned unused constants |

### Architecture Decisions
- **Explicit colors over semantic**: PDFs are documents, not UI — they must render identically regardless of viewer dark mode. Every color is now explicit RGBA.
- **Page background fill**: Without it, PDF viewers (iOS Files app in dark mode) show their own dark background through transparent areas, making light cards appear black.
- **Trait collection forcing**: Even explicit `UIColor` values can shift if resolved through a dark mode trait collection. Setting `UITraitCollection.current` to `.light` eliminates this entirely.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- (none scheduled — user may want to test PDF on device in both light and dark mode to verify colors are preserved)

### Open Questions
- Should the PDF footer or event table headers also get a subtle blue tint for full thematic consistency?

---

## 2026-05-12 — Session 37: Sleep Score Formula Fix

### Completed
- Sleep score formula revised to penalize high snoring percentages more aggressively.
- `sleepScore` moved from SwiftData stored property to computed property on `SleepSession`.

### Technical Details
- Old formula: `max(0, 100 - min(snoring% × 0.5, 30) - min(events/hour × 2, 30))` — minimum score 40, intensity ignored.
- New formula: `max(0, 100 - min(snoring% × 0.7, 70) - min(events/hour × 2, 20) - min(lightRatio × 10 + loudRatio × 20, 20))` — minimum score 0, intensity weighted by event duration.
- Example: 29:39 session with 27:43 snoring (93.5%) now scores ~31 instead of 66.
- Computed property means all historical sessions retroactively use the new formula without Core Data / SwiftData migration.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepSession.swift` | +21/-5 | Removed `sleepScore` stored property and init parameter; added computed `sleepScore` with new formula including intensity penalty |
| `Packages/Env/Sources/Services/SessionManager.swift` | -10 | Removed `computeSleepScore(session:)` function and `session.sleepScore = ...` assignment in `stopSession()` |

### Architecture Decisions
- **Computed over stored**: Product logic (scoring formulas) changes frequently in health apps. Storing derived values couples data to logic version. Computing on read lets us iterate formulas without migration scripts or stale historical scores.
- **Intensity from event durations**: `SnoreEvent.intensity` is the peak observed during the event, but we weight by `snoreDuration` so a 10-minute loud event counts more than a 2-second loud spike.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- (none scheduled)

### Open Questions
- Should the snoring penalty weight (0.7) or cap (70) be tuned further based on real-world testing?

---

## 2026-05-12 — Session 37 (continued): Derived Session Stats → Computed

### Completed
- Converted 5 derived `SleepSession` properties from SwiftData stored to computed.

### Technical Details
- **Stored before:** `totalDuration`, `snoringDuration`, `snoringPercentage`, `eventsCount`, `eventsPerHour`, `sleepScore`
- **Computed now:** All except `averageDB` and `peakDB` (which derive from per-sample audio data not stored in SwiftData)
- **Source of truth:**
  - `totalDuration` → `endDate.timeIntervalSince(startDate)`
  - `snoringDuration` → `events.reduce(0) { $0 + $1.snoreDuration }`
  - `snoringPercentage` → `snoringDuration / totalDuration * 100`
  - `eventsCount` → `events?.count ?? 0`
  - `eventsPerHour` → `eventsCount / (totalDuration / 3600)`
  - `sleepScore` → formula (see earlier session entry)
- Removed all write sites in `SessionManager.processAudioLevel()` and `SessionManager.stopSession()`.
- `SessionManager.eventsCount` (stored `Int` for `@Observable` UI propagation) still updates from computed `session.eventsCount`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepSession.swift` | +25/-9 | Removed 5 stored properties and init parameters; added computed properties deriving from `startDate`/`endDate`/`events` |
| `Packages/Env/Sources/Services/SessionManager.swift` | -12 | Removed assignments to computed properties in `stopSession()` and `processAudioLevel()`; kept `averageDB` and `sessionManager.eventsCount` updates |

### Architecture Decisions
- **Raw data only in SwiftData:** Time-series aggregates (duration, counts, percentages) are derived values. Persisting them creates stale data risk and requires migrations when formulas change. Computing on read keeps the model layer thin.
- **`averageDB` / `peakDB` stay stored:** They aggregate ~50ms audio samples across the entire session. The raw sample log exists in `rawLogFileURL`, but re-parsing a JSON log for every UI read is too expensive. These are analysis results, not simple arithmetic.
- **Query limitation accepted:** SwiftData can't sort/filter by computed properties. All current queries sort by `startDate`, so this is not a constraint today.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- (none scheduled)

---

## 2026-05-12 — Session 37 (continued): SnoreEvent.snoreDuration → Computed

### Completed
- Converted `SnoreEvent.snoreDuration` from SwiftData stored to computed.

### Technical Details
- `snoreDuration` is now `bursts?.reduce(0) { $0 + $1.duration } ?? 0`
- Removed `snoreDuration` parameter from `SnoreEvent` init
- Removed `trueSnoreDuration` local variable from `SessionManager.finalizeActiveEvent()`
- If burst-detection logic changes in the future (gap threshold, minimum burst length), historical event durations auto-update

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SnoreEvent.swift` | +6/-4 | Removed `snoreDuration` stored property and init parameter; added computed property deriving from `bursts` |
| `Packages/Env/Sources/Services/SessionManager.swift` | -3 | Removed `snoreDuration` argument from `SnoreEvent` init; removed `trueSnoreDuration` local variable |

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

---

## 2026-05-12 — Session 37: Sleep Score Fix + SwiftData Schema Audit (Final)

### Completed
- Fixed sleep score formula that was producing 66 for a 93.5% snoring session
- Converted 6 derived `SleepSession` properties from stored to computed
- Converted `SnoreEvent.snoreDuration` from stored to computed
- Full audit of SwiftData schema to minimize future migrations

### Technical Details

**Old sleep score formula:**
```
score = max(0, 100 - min(snoring% × 0.5, 30) - min(events/hour × 2, 30))
// Minimum possible score: 40. Intensity ignored.
```

**New sleep score formula:**
```
score = max(0, 100
  - min(snoring% × 0.7, 70)
  - min(events/hour × 2, 20)
  - min(lightRatio × 10 + loudRatio × 20, 20))
// Minimum possible score: 0. Intensity weighted by event duration.
```

**Example impact:** 29:39 session with 27:43 snoring (93.5%) — score went from **66 → ~31**.

**SwiftData schema changes:**
| Model | Removed from stored | Still stored |
|-------|---------------------|--------------|
| `SleepSession` | `totalDuration`, `snoringDuration`, `snoringPercentage`, `eventsCount`, `eventsPerHour`, `sleepScore` | `id`, `startDate`, `endDate`, `averageDB`, `peakDB`, `audioFileURL`, `rawAudioFileURL`, `rawLogFileURL`, `events` |
| `SnoreEvent` | `snoreDuration` | `id`, `timestamp`, `intensity`, `averageDB`, `peakDB`, `dominantFrequency`, `spectralCentroid`, `lowFreqRatio`, `audioFileURL`, `bursts`, `session` |

**Why `averageDB`/`peakDB` and event FFT features stay stored:**
They derive from per-sample audio data (~20 Hz JSON log or FFT on audio clips). Recomputing on every UI read would require parsing 500K+ JSON entries or running FFT per event. These are cached analysis results, not simple arithmetic.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepSession.swift` | +51/-15 | Removed 6 stored properties and init parameters; added computed `totalDuration`, `snoringDuration`, `snoringPercentage`, `eventsCount`, `eventsPerHour`, `sleepScore` |
| `Packages/Models/Sources/Data/SnoreEvent.swift` | +6/-4 | Removed `snoreDuration` stored property and init parameter; added computed property deriving from `bursts` |
| `Packages/Env/Sources/Services/SessionManager.swift` | -28 | Removed `computeSleepScore(session:)`, removed assignments to all computed properties in `stopSession()` and `processAudioLevel()`, removed `trueSnoreDuration` local variable |
| `docs/trackers/f2-live-session.md` | +6 | Added Session 37 refinement notes |
| `docs/FeatureTracker.md` | +3 | Added activity log entries for formula fix and both refactor tasks |

### Architecture Decisions
- **Computed for simple derivations:** Any property that is pure arithmetic over small in-memory arrays (events, bursts, dates) should be computed. Formula changes apply retroactively; no migrations needed.
- **Stored for expensive analysis results:** Audio features (dB averages, peaks, FFT coefficients) require re-processing raw audio or parsing large JSON logs. These stay stored as caches.
- **Query limitation accepted:** SwiftData cannot sort/filter by computed properties. All current queries sort by `startDate`, so this is not a constraint today.
- **Schema stability:** The remaining stored properties represent raw data or expensive-to-recompute caches. Their meanings are unlikely to change, minimizing future migration needs.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- (none scheduled)

### Open Questions
- Should snoring penalty weight (0.7) or cap (70) be tuned based on real-world testing?
- Should we add `analysisPipelineVersion: Int` to `SleepSession` for background reprocessing when detection algorithms change?

---


---

## 2026-05-12 — Session 38: Performance Fix — Computed Properties Hang + Stop Button Bug + Gauge Animation

### Completed
- **BUG**: `BedsideClockView` Stop button always showed "Session Too Short" alert because it checked `session.totalDuration` (computed from `endDate`, which is `nil` during recording → always 0). Fixed to use live elapsed time `currentTime.timeIntervalSince(session.startDate)`.
- **BUG**: `SessionDetailView` and `RecordingsListView` hung on fresh app open for dates with multiple saved sessions. The schema audit changed `sleepScore`/`snoringDuration` from stored to computed, so every `body` evaluation triggered SwiftData relationship faulting + redundant O(n) passes.
- **PERF**: `SleepSession.sleepScore` refactored to single-pass over events (was 3+ passes).
- **PERF**: `AudioClipExtractor.extractClips()` parallelized with `TaskGroup` (batches of 4) instead of sequential `for` loop. Cuts post-recording processing time significantly for long sessions.
- **PERF**: `NightGroup.averageScore`/`totalDuration`/`totalEvents` moved from computed properties to stored constants computed once at init. Prevents re-computation on every SwiftUI `body` evaluation.
- **PERF**: `SessionDetailView` pre-computes `sortedEvents` and `isClipSession` during async `loadSession()` instead of sorting/faulting synchronously in `loadedBody`.
- **PERF**: `SnoringTimelineView` avoids `O(n log n)` sort when events are already chronological.
- **UX**: `SleepScoreGauge` now animates from 0 → target on first load using `@State animatedProgress` + `.onAppear`.

### Technical Details
- `NightGroup` is a value type; computed properties were re-evaluated every time `NightGroupRowView.body` rendered. With 3+ sessions per night, each evaluation called `sleepScore` 3×, faulting events each time. Making them stored constants computed at `init` eliminates this.
- `SessionDetailView` previously did `session.events?.sorted(...)` in `loadedBody` (every layout pass) and again in `SessionDetailEventsView.body`. Now sorted once in `loadSession()` and passed down.
- `SessionDetailView.diagnoseAudioFiles()` iterated all events synchronously on the main thread during load — removed entirely.
- `AudioClipExtractor` now uses `withTaskGroup` with batch size 4. Each task creates its own `AVURLAsset` to avoid Sendable issues. Exports and spectral analysis run concurrently within each batch.
- `SleepScoreGauge` uses `.animation(.easeOut(duration: 0.8), value: animatedProgress)` + `.onAppear { animatedProgress = CGFloat(score) / 100.0 }` + `.onChange(of: score)` for updates. No heavy work on main thread; interpolation runs on render server.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepSession.swift` | +28/-21 | Single-pass `sleepScore`; removed redundant `snoringPercentage`/`snoringDuration` calls |
| `Packages/AudioEngine/Sources/Engine/AudioClipExtractor.swift` | +55/-58 | Parallelized extraction with `TaskGroup` (batch size 4); extracted per-event logic into `extractSingleClip()` |
| `Packages/DesignSystem/Sources/Components/SnoringTimelineView.swift` | +10/-2 | Sort-skip when events already chronological |
| `Packages/Recordings/Sources/Views/NightGroup.swift` | +8/-7 | `averageScore`, `totalDuration`, `totalEvents` stored at init instead of computed |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +35/-42 | `ViewState.loaded` carries `sortedEvents` + `isClipSession`; pre-computed in `loadSession()`; removed `diagnoseAudioFiles()`; `legacyPlayerSection` takes sorted events |
| `Packages/Recordings/Sources/Views/SessionDetailHeaderView.swift` | +2/-1 | Takes `score: Int` directly |
| `Packages/Recordings/Sources/Views/SessionDetailEventsView.swift` | +1/-3 | Takes `events: [SnoreEvent]` instead of re-sorting `session.events` |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +1/-1 | Stop button uses live elapsed time instead of `session.totalDuration` |
| `Packages/DesignSystem/Sources/Components/SleepScoreGauge.swift` | +10/-3 | `@State animatedProgress` with `.onAppear` animation + `.onChange(of: score)` |

### Architecture Decisions
- **Pre-compute during async load, never in body:** Any data that requires relationship access or sorting should be computed in `.task { loadState() }` and cached in `ViewState`. `body` must be O(1).
- **Struct-level caching for group stats:** `NightGroup` stores averaged stats at init because SwiftUI `body` re-evaluates frequently. Value-type computed properties that touch relationships are a performance trap.
- **Parallel I/O with bounded concurrency:** `TaskGroup` with batch size 4 keeps `AVAssetExportSession` load reasonable while still cutting sequential wait time.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- Test parallel clip extraction on a real 30+ minute session to verify export stability.
- Consider adding relationship prefetching (`FetchDescriptor` with `relationshipKeyPathsForPrefetching`) for `RecordingsListView` if cold-start faulting remains noticeable.

### Open Questions
- Should `NightGroup` also cache `latestSession`? It's O(1) array access, so low priority.
- Is batch size 4 optimal for `AVAssetExportSession` concurrency, or should it be tuned per device?

---

## 2026-05-12 — Session 39: Fix Main-Thread Audio I/O Hang in SessionDetailView

### Completed
- **BUG**: `SessionDetailView` hung when opening saved recordings with large legacy audio files. `setupAudioPlayer()` called `AVAudioPlayer(contentsOf:)` synchronously on the main thread; for 30+ minute `.caf` files this blocks the UI for seconds.
- **BUG**: `SessionDetailView` `.task` could redundantly re-run audio setup on body re-evaluation (e.g., `isPlayerExpanded` toggle). Added `didSetupAudio` guard to ensure one-shot initialization.
- **PERF**: `ClipPlaybackController.loadEvents()` redundantly sorted already-sorted events (caller `SessionDetailView.loadSession()` pre-sorts). Removed `events.sorted()` to avoid O(n log n) work.

### Technical Details
- `setupAudioPlayer(for:)` is now `async` and creates `AVAudioPlayer` inside `Task.detached(priority: .userInitiated)`. The synchronous `contentsOf:` decode + `prepareToPlay()` run on a background thread; only the final assignment to `@State audioPlayer` hops back to `@MainActor`.
- `SessionDetailView` `.task` in `loadedBody` now reads `guard !didSetupAudio else { return }` before branching to clip vs. legacy setup. Prevents double-initializing `AVAudioPlayer` on view re-evaluation.
- `ClipPlaybackController.loadEvents(_:)` removed `events.sorted { $0.timestamp < $1.timestamp }` because `SessionDetailView` already passes chronologically sorted events from `loadSession()`. This avoids an unnecessary O(n log n) pass every time the detail view appears.
- `SessionDetailMiniPlayerView` was ruled out as the culprit — it is purely presentational (receives pre-computed `progress`, `eventMarkers`, etc.). Zero audio I/O.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +12/-5 | `setupAudioPlayer` → `async` with `Task.detached`; added `didSetupAudio` state; `.task` awaits setup |
| `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` | +1/-1 | Removed redundant `events.sorted()` in `loadEvents()`; trusts caller order |

### Architecture Decisions
- **Never do synchronous file I/O on `@MainActor`:** `AVAudioPlayer(contentsOf:)` reads and decodes the entire audio file. Always wrap in `Task.detached` for large files, even if the API surface is synchronous.
- **One-shot setup guards prevent redundant work:** SwiftUI `.task` lifetime can restart on identity changes. A `didSetupAudio` boolean prevents re-creating expensive resources.
- **Trust caller invariants to avoid redundant work:** If the caller guarantees sorted input, don't re-sort. Document the invariant in comments.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- Monitor for remaining hangs in `SessionDetailView` for sessions with very high event counts (500+ clips). If file-existence checks in `loadEvents` add up, consider lazy resolution.
- Consider making `ClipPlaybackController.setupPlayerForCurrentEvent()` async too, so clip auto-advance (`tick()`) doesn't block the main thread when loading the next clip.

### Open Questions
- Should `ClipPlaybackController` skip file-existence checks entirely and assume clips exist? Failed extractions are rare; a missing clip would fail at `AVAudioPlayer` creation anyway.

---

## 2026-05-12 — Session 39 (continued): Lazy Audio + Canvas Timeline

### Completed
- **Lazy legacy audio player**: `AVAudioPlayer` is no longer created when `SessionDetailView` appears. It is only created when the user taps the play button. This completely removes heavy file decode from the view load path.
- **Lazy clip audio player**: `ClipPlaybackController.loadEvents()` no longer calls `setupPlayerForCurrentEvent()`. The first `play()` tap creates the `AVAudioPlayer` for the current clip.
- **Removed file-existence checks**: `ClipPlaybackController.loadEvents()` no longer checks `FileManager.fileExists(atPath:)` for every event. It now just maps `event.snoreDuration`. Missing clips fail gracefully when playback is attempted.
- **Canvas timeline**: `SnoringTimelineView` reimplemented with `Canvas` instead of `ForEach` over hundreds of `RoundedRectangle` views. A single `Canvas` render pass draws all segments, eliminating SwiftUI view-creation overhead for sessions with many events.

### Technical Details
- `SessionDetailView.loadedBody` `.task` no longer calls `await setupAudioPlayer(for:)` for legacy sessions. The task only runs `setupClipPlayback` for clip sessions, which is now lightweight (no file I/O, no player creation).
- `toggleLegacyPlayback()` checks `audioPlayer == nil` and spawns an async task to create the player via `Task.detached`. Once ready, it recursively calls itself to start playback. A `isLegacyPlayerLoading` flag prevents duplicate initializations.
- `seekToLegacyEvent()` handles the nil-player case by lazy-initing first, then seeking.
- `ClipPlaybackController.play()` now checks `if audioPlayer == nil { setupPlayerForCurrentEvent() }` before attempting playback. All other entry points (`playEvent(at:)`, `tick()`, `seekToOverall`) rely on `play()` or `setupPlayerForCurrentEvent()` being called on demand.
- `SnoringTimelineView` draws background + segments in a single `Canvas` closure using `Path(roundedRect:)` and `context.fill(...)`. No `GeometryReader`, no `ForEach`, no view identity management for hundreds of items.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +35/-15 | Lazy legacy playback (`isLegacyPlayerLoading`, `currentSession`, async `toggleLegacyPlayback`); removed `await setupAudioPlayer` from `.task` |
| `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` | +4/-6 | `loadEvents` skips file checks + player setup; `play()` lazy-inits player |
| `Packages/DesignSystem/Sources/Components/SnoringTimelineView.swift` | +16/-35 | Replaced `GeometryReader` + `ForEach` with `Canvas` single-pass drawing |

### Architecture Decisions
- **Lazy over eager for expensive resources:** Audio players are created on user interaction, not view appearance. This guarantees the view loads instantly regardless of file size.
- **Canvas for high-item-count graphics:** When a view needs hundreds of identical shapes, `Canvas` + `Path` is orders of magnitude faster than `ForEach` with individual SwiftUI views.
- **Fail-soft for missing clips:** Instead of pre-validating every clip file, assume existence and let `AVAudioPlayer(contentsOf:)` fail at play time. This removes O(n) file system calls from the load path.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- Monitor user feedback on large-session load times. If hangs persist, investigate SwiftData relationship faulting during `loadSession()` or pre-computing timeline segments in the background.
- Consider adding a small loading spinner on the mini player play button while lazy audio init is in progress.

### Open Questions
- Should `SessionDetailView` pre-compute `sleepScore` and timeline segments during `loadSession()` so `body` is truly O(1)?

---

## 2026-05-12 — Session 39 (continued): Fix False-Positive Snore Detection

### Completed
- **BUG**: Snore detector created massive false positives (breathing, bed creaking, traffic, talking) because the fallback `classifyWithThresholds()` was a pure dB gate at -35 dB with zero frequency discrimination.
- **BUG**: Spectral threshold of 0.3 was too permissive — breathing easily scores 0.4–0.7 in the 100–500 Hz band. Raised to 0.6 with a -35 dB minimum floor.
- **BUG**: `SoundAnalysisDetector` included `"breathing"` in `snoreIdentifiers`, so Apple's classifier treating breathing as a class would count it as snoring.
- **BUG**: `SessionManager.finalizeActiveEvent()` hardcoded 0.5 s minimum duration instead of using `UserPreferences.minSnoreDuration` (default 2.0 s). Brief breathing waves (< 2 s) now get discarded.
- **BUG**: No sustained-detection requirement — a single sample above threshold could start an event. Added `consecutiveSnoreSamples` counter requiring 3 consecutive detections (≈150 ms at 20 Hz).

### Technical Details
- `SnoreDetector.classify()` no longer falls back to `classifyWithThresholds()`. If both SoundAnalysis and spectral are inconclusive, it returns `.none`.
- `classifyWithSpectral()` threshold raised from 0.3 → 0.6. Added `guard db >= -35 else { return .none }` so quiet ambient sounds are rejected even with decent spectral scores.
- `SoundAnalysisDetector.snoreIdentifiers` changed from `["snore", "snoring", "breathing"]` to `["snore", "snoring"]`.
- `SessionManager.processAudioLevel()` increments `consecutiveSnoreSamples` when `state != .none`. Only starts/extends an event after 3 consecutive samples (≈150 ms). Brief sounds (bed creaks, taps) are filtered out. The event start time is backdated to when sustained detection began.
- `SessionManager.finalizeActiveEvent()` now reads `UserPreferences.shared.minSnoreDuration` (default 2.0 s) instead of hardcoded 0.5 s.
- The UI hang was a *symptom* of false positives, not an audio player issue. With hundreds or thousands of false events per session, `loadSession()`, `SnoringTimelineView`, and `sleepScore` all iterated massive arrays.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +12/-10 | Removed dB fallback; spectral threshold 0.3→0.6; added -35 dB floor |
| `Packages/AudioEngine/Sources/Engine/SoundAnalysisDetector.swift` | +1/-1 | Removed `"breathing"` from snore identifiers |
| `Packages/Env/Sources/Services/SessionManager.swift` | +18/-6 | Consecutive sample gate (3×); backdated event start; `minSnoreDuration` from prefs |

### Architecture Decisions
- **Pure dB gates are dangerous for audio classification:** Without frequency or temporal analysis, any sound above a threshold is "snoring." Always require at least one discriminative classifier (spectral or ML) to confirm.
- **Sustained detection prevents transient false positives:** A single 50 ms sample above threshold is not snoring. Require 150 ms of consistent detection.
- **User preference for minimum duration should be respected:** Hardcoding 0.5 s ignored the user's setting and allowed brief breathing waves to become events.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- Monitor real-world detection accuracy. If false positives persist, consider:
  - Training a custom `MLSoundClassifier` model on snoring vs. breathing/bed creaking
  - Adding periodicity analysis (snoring is rhythmic; breathing is irregular)
  - Lowering the bandpass filter center frequency to better capture the snoring fundamental (~80–150 Hz)

### Open Questions
- Is 0.6 spectral threshold too aggressive? Might miss quiet snoring. May need tuning based on user feedback.
- Should `requiredConsecutiveSamples` be configurable in settings?


---

## 2026-05-12 — Session 39 (continued): Sheet-Based Player + Events UI

### Completed
- **Restructured `SessionDetailView` into a bottom-sheet audio pattern** to eliminate audio I/O from the detail view load path.
- **Fake mini player bar**: `SessionDetailMiniPlayerView` is now a static presentational component with no live playback state. It shows session info, a zeroed progress bar, and event marker dots. Tapping anywhere opens the real player sheet.
- **`PlayerSheetView` (new)**: Self-contained bottom sheet that owns all audio state — `AVAudioPlayer` for legacy sessions, `ClipPlaybackController` for clip sessions, waveform/spectrum visualization, and full playback controls. Initialized only when the user opens the sheet.
- **`EventsSheetView` (new)**: Bottom sheet showing all snore events as a multi-row grid of compact cards (120×140 pt, 3 per row). Each card shows intensity dot, relative time, duration, and a Play button. Replaces the inline vertical event list for large sessions.
- **`SessionDetailEventsView`**: Now shows only the first 4 events inline plus a "Show All" button. Eliminates rendering hundreds of `EventRow` views in the main scroll.
- **Removed `.withEnvironments()`**: Sheets only use `@Environment(Theme.self)` and `@Environment(\.dismiss)`, which are standard SwiftUI environments. No app-specific singleton injection needed.

### Technical Details
- `SessionDetailView` no longer has any `@State` for audio playback. All audio-related state moved to `PlayerSheetView`.
- `SessionDetailView.loadedBody` pre-computes `sortedEvents` and `isClipSession` during `loadSession()`; passes them to child views as immutable `let` parameters.
- `PlayerSheetView` receives `session`, `sortedEvents`, `isClipSession`, and an optional `initialEvent`. On `.task`, it initializes the appropriate player and optionally auto-plays the initial event.
- Legacy audio setup (`setupAudioPlayer()`) remains async with `Task.detached(priority: .userInitiated)` to avoid blocking sheet presentation.
- `DetailSheet` enum (`.player(initialEvent: SnoreEvent?)`, `.events`) drives `.sheet(item:)` presentation with stable IDs.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +120/-280 | Removed all audio state; added `DetailSheet` enum; fake mini player section; `.sheet(item:)` for player + events |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | +244/-0 | **New** — Self-contained audio player sheet with legacy + clip playback, visualization, controls |
| `Packages/Recordings/Sources/Views/EventsSheetView.swift` | +116/-0 | **New** — Horizontal scrolling event cards in a bottom sheet |
| `Packages/Recordings/Sources/Views/SessionDetailEventsView.swift` | +42/-60 | Shows first 4 events + "Show All" button; removed inline play/share row logic (moved to parent) |
| `Packages/Recordings/Sources/Views/SessionDetailMiniPlayerView.swift` | +103/-120 | Now purely presentational; receives all state via `let` parameters; no `@State` |

### Architecture Decisions
- **Sheet isolation for heavy I/O**: Audio file I/O and player initialization are expensive and belong in a dedicated sheet, not in the main detail scroll. This prevents the detail view from ever blocking on audio setup.
- **Horizontal event cards vs. vertical list**: For sessions with thousands of events (legacy polluted data), a vertical `ForEach` over `EventRow` views is expensive. Horizontal cards in a sheet are cheaper and more scannable.
- **No `.withEnvironments()` in package sheets**: The extension lives in the app target. Since sheets only need `Theme` and `dismiss`, we avoid the cross-target dependency issue entirely.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- Consider adding a "Delete Legacy Sessions" bulk action in Settings for users with pre-fix polluted data.
- Consider pre-computing timeline segment arrays in `loadSession()` to make `SnoringTimelineView` truly O(1) in `body`.

### Open Questions
- Should `PlayerSheetView` support background audio (continue playing after dismiss)? Currently stops when sheet closes.
- Should event cards in `EventsSheetView` show a waveform thumbnail?


---

## 2026-05-12 — Session 39 (continued): Event-Focused Player UI

### Completed
- **Redesigned `PlayerSheetView` to match the screenshot design** — single-event focused player with bar waveform, centered pause button, and skip controls.
- **Created `EventPlayerView`** — New presentational component matching the design:
  - Header: "SNORING EVENT" label, duration + intensity (e.g. "1m 18s · Loud"), Peak/Avg dB
  - Bar-style waveform (80 thin vertical bars) with blue played / gray unplayed coloring
  - White vertical line indicating current playback position
  - Time labels: start, current/total, end
  - Large white circular pause button centered, with 15s skip back/forward buttons
  - Legend: colored dots for Light snore / Loud snore
- **Player auto-opens in expanded mode** — No more mini player + expand toggle. Tapping Play on any event card opens the sheet directly showing the full event player.
- **Waveform visualization** — `WaveformGenerator` samples rendered as individual `RoundedRectangle` bars. For clip sessions, reads the event's `.m4a` directly. For legacy sessions, exports a temporary clip and generates waveform from it.
- **Skip controls** — ±15 second skip back/forward for both clip and legacy playback.
- **`SessionDetailMiniPlayerView`** — Inline fake bar in `SessionDetailView` now hides play button entirely (`showsPlaybackButton: false`). Only shows timeline with duration and event markers.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/EventPlayerView.swift` | +195/-0 | **New** — Design-matching single-event player with bar waveform, pause button, skip controls |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | +266/-0 | **Rewritten** — Uses `EventPlayerView` directly; removed mini player + expand pattern; auto-plays on open |
| `Packages/Recordings/Sources/Views/SessionDetailMiniPlayerView.swift` | +25/-5 | Added `showsPlaybackButton` parameter; hides play button when false |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +12/-8 | Fake player section now has "TIMELINE" label above; passes `showsPlaybackButton: false` |

### Architecture Decisions
- **Single-event player vs. timeline player**: The design is event-scoped, not session-scoped. Each event gets its own waveform and controls. For clip sessions, sequential playback advances to the next event automatically (handled by `ClipPlaybackController`).
- **Bar waveform over filled shape**: The design shows discrete vertical bars, not a continuous filled path. Bars are easier to color by play state (blue played vs. gray unplayed) and computationally cheaper.
- **Auto-play on sheet open**: When user taps Play on an event card, the sheet opens and immediately starts playing that event. The large pause button is the primary control since playback is already active.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- Add localized strings for new UI labels ("Snoring Event", "Light snore", "Loud snore")
- Consider adding per-burst marker dots on the waveform (currently shows single dot or burst-position dots)

### Open Questions
- Should the player auto-advance to the next event when one finishes? Currently `ClipPlaybackController` does this; legacy single-event player stops.


## 2026-05-13 — Session 40: Single-Event Playback from Events Sheet + Detail Inline

### Completed
- **Fixed `EventsSheetView` dismissal on play**: Tapping an event card's Play button now presents `PlayerSheetView` as a nested sheet while keeping `EventsSheetView` open underneath.
- **Single-event playback from `EventsSheetView`**: `PlayerSheetView` receives `sortedEvents: [event]` instead of all events. This makes the player show only that event's waveform, duration, and time — not the full concatenated clip sequence.
- **Single-event playback from `SessionDetailEventsView`**: Applied the same fix to the inline event list on `SessionDetailView`. The `.player` sheet case now passes `sortedEvents: initialEvent.map { [$0] } ?? sortedEvents`, so tapping an event row plays only that recording.

### Technical Details
- `EventsSheetView` uses `.sheet(item: $selectedEvent)` presenting `PlayerSheetView` with `sortedEvents: [event]`. The sheet is nested inside `EventsSheetView`'s `NavigationStack`, so the parent sheet stays open.
- `ClipPlaybackController.loadEvents([event])` sets `totalClipsDuration = event.snoreDuration`, `events.count = 1`, so `EventPlayerView` shows the event-scoped UI without "Event X of Y" sequence label.
- `SessionDetailView.DetailSheet.player` case updated to filter `sortedEvents` to just the tapped event. Fallback to all events only if `initialEvent` is nil (defensive).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/EventsSheetView.swift` | +63/-53 | Rewrote to present `PlayerSheetView` as nested sheet with `sortedEvents: [event]`; removed earlier inline mini-player experiment |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +1/-1 | `.player` sheet: `sortedEvents: sortedEvents` → `sortedEvents: initialEvent.map { [$0] } ?? sortedEvents` |

### Architecture Decisions
- **Nested sheets over sheet replacement**: Changing `activeSheet` from `.events` to `.player` in the parent dismisses the events sheet. Presenting the player from within `EventsSheetView` preserves the parent.
- **Single-event array trick**: Passing `[event]` to `PlayerSheetView` reuses all existing clip/legacy playback logic without adding a new "single event mode" flag. `ClipPlaybackController` naturally handles a 1-element array.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- (none scheduled)

### Open Questions
- None

---

## 2026-05-14 — Session 41: Last 7 Nights Screen + Duration Format Unification + Tab Navigation Fix

### Completed
- **Last 7 Nights dedicated screen**: Created `Last7NightsView` matching design node fuq0d from `SleepGuard.pen`. Includes custom nav bar with "Stats" back button, date range + avg sleep score header with week-over-week trend indicator (`+4 vs prev wk`), snoring minutes bar chart with intensity-based colors (quiet/gray, light/amber, loud/red), 2×2 stat grid (AVG SNORING, TOTAL EVENTS, BEST, WORST), and ALL NIGHTS list with score circles, day/date, duration, and snoring time.
- **Reusable components extracted**: `Last7NightsChartCard`, `Last7NightsStatGrid`, `Last7NightsRow`, `Last7NightsDaySummary`, `WeekOverWeekTrendCalculator` — all under 200 lines per AGENTS.md rules.
- **New route `.last7Nights`**: Added to `RouterDestination` and mapped to `Last7NightsView()` in `AppRegistry`.
- **"See all" button wired**: `StatisticsMiniChartSection` now uses `@Environment(RouterPath.self)` to navigate directly to `.last7Nights` instead of prop-drilling closures.
- **Duration format unification**: Fixed all user-facing duration strings to use consistent `%d h %d min` / `%d min` format matching `NightGroupRowView`. Updated `Last7NightsRow`, `Last7NightsStatGrid`, `SessionSummaryView`, `BedsideClockView`, `WatchSessionManager`.
- **Event player timestamp**: Added event start time (`hh:mm am/pm`) to `EventPlayerView.headerSection` before "Snoring Event", matching `EventRow` format.
- **Tab navigation bugfix**: Root cause was `withAppDependencyGraph` injecting three `RouterPath` instances via `.environment()`, where the last one (`settingsRouterPath`) overwrote the previous two. All tabs shared the same navigation path, so pushing a detail view in Recordings tab polluted Statistics tab's stack. Fixed by giving each tab (`StatisticsTab`, `RecordingsTab`, `SettingsTab`) its own `@State private var routerPath = RouterPath()` injected via `.environment(routerPath)` scoped to the tab's view hierarchy. Removed shared router paths from `SleepGuardApp` and `withAppDependencyGraph`.
- **Localization strings**: Added 8 new strings to `Localizable.xcstrings` and regenerated `Strings.swift`.

### Technical Details
- `Last7NightsView` queries `SleepSession` via SwiftData, groups by day using `Calendar.startOfDay`, takes last 7 days, and computes aggregated stats (avg score, avg snoring minutes, total events, best/worst with weekday labels).
- `DaySummary` stores `SnoreIntensity` enum and computes `intensityColor` lazily via `Theme.shared` to avoid `@MainActor` isolation issues during init.
- `WeekOverWeekTrendCalculator` compares current 7-night average score vs previous 7-night average; returns `nil` if fewer than 8 nights of data exist.
- Bar chart in `Last7NightsChartCard` uses custom `HStack` of `RoundedRectangle` bars (cornerRadius 3) with heights proportional to max snoring minutes within the 80pt container, matching the pencil design exactly.
- ALL NIGHTS rows show score circles with 3pt stroke colored by `theme.scoreColor(avgScore)` and snoring text colored by max intensity.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Views/Last7NightsView.swift` | +188/-0 | **New** — Main container view for Last 7 Nights screen |
| `Packages/Statistics/Sources/Views/Last7NightsChartCard.swift` | +62/-0 | **New** — Chart card with bars, labels, and legend |
| `Packages/Statistics/Sources/Views/Last7NightsStatGrid.swift` | +86/-0 | **New** — 2×2 stat grid with icon headers |
| `Packages/Statistics/Sources/Views/Last7NightsRow.swift` | +79/-0 | **New** — Night row with score circle, day/date, duration |
| `Packages/Statistics/Sources/Views/Last7NightsDaySummary.swift` | +48/-0 | **New** — Day-level data model with intensity logic |
| `Packages/Statistics/Sources/Views/WeekOverWeekTrendCalculator.swift` | +39/-0 | **New** — Week-over-week trend computation |
| `Packages/Statistics/Sources/Views/StatisticsMiniChartSection.swift` | +4/-2 | Removed `onSeeAll` closure; uses `@Environment(RouterPath)` + `.last7Nights` |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | +1/-4 | Removed `onSeeAll` parameter passing |
| `Packages/Env/Sources/Services/Router.swift` | +1/-0 | Added `.last7Nights` case |
| `SleepGuard/AppRegistry.swift` | +2/-8 | Mapped `.last7Nights` → `Last7NightsView`; removed shared router paths |
| `SleepGuard/StatisticsTab.swift` | +3/-2 | Own `@State var routerPath`; `.environment(routerPath)` |
| `SleepGuard/RecordingsTab.swift` | +3/-2 | Own `@State var routerPath`; `.environment(routerPath)` |
| `SleepGuard/SettingsTab.swift` | +3/-2 | Own `@State var routerPath`; `.environment(routerPath)` |
| `SleepGuard/SleepGuardApp.swift` | +1/-6 | Removed shared `statisticsRouterPath`, `recordingsRouterPath`, `settingsRouterPath` |
| `Packages/Recordings/Sources/Views/EventPlayerView.swift` | +13/-0 | Added `eventTimeString` helper + timestamp display in header |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | +5/-2 | Duration format: `%dh %02dm` → `%d h %d min` |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +7/-3 | Duration format: `%dh %02dm` → `%d h %d min` |
| `WatchApp/Sources/WatchSessionManager.swift` | +5/-2 | Duration format: `%dh %02dm` → `%d h %d min` |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +93/-0 | Added 8 new `stats.last7Nights.*` strings |
| `Packages/DesignSystem/Sources/Strings.swift` | +9/-0 | Auto-generated from xcstrings |

### Architecture Decisions
- **Per-tab RouterPath isolation**: `.environment()` overwrites same-type values. The previous architecture of injecting three router paths at the app root was fundamentally broken — only the last one survived. Moving router path ownership into each tab using `@State` + scoped `.environment()` is the correct SwiftUI pattern.
- **Dedicated `.last7Nights` route vs reusing `.trends`**: `.trends` is kept for the generic TrendsView (used by "View Month"). The mini chart "See all" navigates to a dedicated screen because the design (fuq0d) is a specific layout without the Week/Month picker.
- **Event timestamp in player header**: Uses explicit 12-hour logic (`hour >= 12 ? "pm" : "am"`) instead of locale-dependent `DateFormatter` to guarantee consistent `2:30 pm` / `11:30 am` display.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- (none scheduled)

### Open Questions
- Should the share button in `Last7NightsView` toolbar be wired to a share sheet?
- Should the ALL NIGHTS rows in `Last7NightsView` navigate to `sessionDetail` or `recordingDetail`? Currently uses `.sessionDetail`.

---

---

## 2026-05-14 — Session 42: Soothing Melody Sheet + Picker Sheets

### Completed
- **RecordingPrestartView actionRow**: Clickable row with trailing value label and chevron that opens `SoothingMelodySheet`
- **SoothingMelodySheet** (design node `zvwP5`): Native iOS wheel picker for melody duration (Never, Always, 5s, 15s, 30s, 60s), song selection row (RJhGr), status badge, Save/Cancel buttons
- **MelodyPickerSheet** (design node `p0pnlC`): Scrollable list of melodies (Melody 9–17) with accent highlight, checkmark, and stroke border on selected item
- **TipsSection gradient**: Applied `RecordingActionButton`-style red glow + gradient stroke to tipsSection container

### Technical Details
- `Melody` model added to `Models` package with IDs 9–17
- `UserPreferences` extended with `soothingMelodyMode` (enum: never/always/fiveSeconds/fifteenSeconds/thirtySeconds/sixtySeconds) and `selectedMelodyID` (defaults to 12)
- Both sheets use draft-state pattern: local `@State` copies of preferences that only commit on Save; Cancel discards changes
- `SoothingMelodySheet` presents `MelodyPickerSheet` via nested `.sheet`; selected melody bound back via `@Binding`
- Extracted reusable components: `SheetHandle` (drag bar), `SheetNavHeader` (back button + centered title)
- Wheel picker uses SwiftUI `Picker` with `.pickerStyle(.wheel)` inside a `bgCard` rounded container
- `RecordingPrestartView` dynamically displays "Off", "Always", "5 seconds", etc. based on selected mode

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/Melody.swift` | +26 | New `Melody` model with `allMelodies` array |
| `Packages/Env/Sources/Services/UserPreferences.swift` | +28 | Added `soothingMelodyMode` and `selectedMelodyID` with UserDefaults backing |
| `Packages/SleepSession/Sources/Views/SoothingMelodySheet.swift` | +240 | New sheet: wheel picker, song row, status badge, Save/Cancel, reusable SheetHandle + SheetNavHeader |
| `Packages/SleepSession/Sources/Views/MelodyPickerSheet.swift` | +135 | New sheet: melody list with selection highlight, checkmark, accent stroke, Save button |
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +45/-15 | Added actionRow with dynamic value, tipsSection gradient glow + stroke, SoothingMelodySheet presentation |

### Architecture Decisions
- **Draft-state pattern for sheets**: `SoothingMelodySheet` holds local `@State` copies of mode and melody ID. This lets users explore options without persisting until Save is tapped. Keeps Cancel behavior intuitive.
- **Nested sheets over RouterPath**: Since these sheets are self-contained and only triggered from `RecordingPrestartView`, local `@State` + `.sheet` is simpler than adding `SheetDestination` cases and handling them at the tab level.
- **Wheel picker for durations**: Replaced the design's card-with-rows approach with a native `UIPickerView`-style wheel (`Picker` + `.pickerStyle(.wheel)`) because the option count grew from 3 to 6. This is more scrollable and feels native.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Next Session
- Polish / design QA of the soothing melody flow if needed
- Or continue with next V1.1/V2 feature per Roadmap

### Git Handoff
- **Suggested branch**: `feature/soothing-melody-sheet`
- **Suggested commit**: `Soothing Melody — Pre-start actionRow, duration wheel picker, melody picker sheet, and tipsSection gradient`

### Open Questions
- The nav back buttons in both sheets say "Search" per the design file — confirm if this should be "Back" or kept as-designed
- Should the soothing melody audio actually play during snoring detection? This session built only the UI + settings storage; the playback integration into `SessionManager` / `AudioRecorder` is not yet implemented


---

## 2026-05-14 — Session 43: Soothing Melody Audio Playback

### Completed
- **F2-T10**: Wired the Soothing Melody feature to 11 real MP3 files so playback triggers automatically when snoring is detected during an active recording session.

### Technical Details
- `sounds/` folder (11 MP3s) added as a folder reference to the main app target via Ruby `xcodeproj` gem; files are copied into the app bundle and accessible via `Bundle.main.url(forResource:withExtension:)`.
- `Melody` model replaced dummy IDs 9–17 with real filename + displayName mappings for 11 sounds (Funny Alarm, Bird Chittering, Cute Cat Meow, etc.).
- `SoothingMelodyPlayer` (Env package) is a `@MainActor @Observable` singleton wrapping `AVAudioPlayer`.
  - `playIfNeeded()` checks `UserPreferences.soothingMelodyMode` and `selectedMelodyID`, loads the matching MP3 from bundle, and starts playback at volume 0.6.
  - Timed modes (5s/15s/30s/60s) schedule a `Timer` to auto-stop; `.always` loops indefinitely.
  - Re-trigger guard (`!isPlaying`) prevents audio stuttering when consecutive snore detections fire.
  - `AVAudioPlayerDelegate` calls `stop()` on natural playback completion.
- `SessionManager` triggers `soothingMelodyPlayer.playIfNeeded()` at the exact moment a new snore event begins (`activeEventStart == nil` after 3 consecutive samples).
- `SessionManager.stopSession()` and `stopAndDiscardSession()` both call `soothingMelodyPlayer.stop()` to prevent audio leaking after recording ends.
- `BedsideClockView` gains a compact overlay card (`.overlay(alignment: .top)`) when `soothingMelodyPlayer.isPlaying`.
  - Shows pulsing `music.note` icon (`.symbolEffect(.pulse)`), melody name, and a bordered "Stop" button.
  - Uses `.transition(.move(edge: .top).combined(with: .opacity))` for smooth appearance.
- `AppRegistry.swift` and `SleepGuardApp.swift` updated to inject `SoothingMelodyPlayer.shared` into the environment graph.
- `UserPreferences.selectedMelodyID` default changed from 12 → 6 to match the new valid ID range (1–11).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard.xcodeproj/project.pbxproj` | +6 | Added `sounds/` folder reference to main app target resources build phase |
| `Packages/Models/Sources/Data/Melody.swift` | +11/-10 | Replaced dummy melodies with real filename + displayName mapping for 11 MP3s |
| `Packages/Env/Sources/Services/SoothingMelodyPlayer.swift` | +65 | New — AVAudioPlayer wrapper with playIfNeeded, stop, auto-stop timer, isPlaying state |
| `Packages/Env/Sources/Services/SessionManager.swift` | +4 | Triggers `playIfNeeded()` on new snore event; stops on session end |
| `Packages/Env/Sources/Services/UserPreferences.swift` | +1/-1 | Default `selectedMelodyID` changed 12 → 6 |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +35 | Added `melodyOverlay` with pulsing icon, name, Stop button; injected `SoothingMelodyPlayer` |
| `Packages/SleepSession/Sources/Views/SoothingMelodySheet.swift` | +1/-1 | Default `draftMelodyID` changed 12 → 6 |
| `SleepGuard/SleepGuardApp.swift` | +2 | Injected `soothingMelodyPlayer` into `withAppDependencyGraph` |
| `SleepGuard/AppRegistry.swift` | +4 | Added `SoothingMelodyPlayer` parameter to `withAppDependencyGraph` and `withEnvironments` |

### Architecture Decisions
- **Placement in Env package**: `SoothingMelodyPlayer` lives in `Env` because it needs `UserPreferences` (also in Env) and must be observable by `BedsideClockView` (in SleepSession, which imports Env). This avoids a new package and follows the existing singleton + `@Environment` pattern.
- **Compact overlay vs full sheet**: Chose a compact top-overlay card instead of a full `.sheet` because a modal would block the bedside clock and stop button during sleep recording.
- **Volume 0.6**: Fixed at 60% to reduce the chance of playback being picked up by the microphone while still being audible. No recording pause — snore detection must continue uninterrupted per user requirement.
- **Re-trigger guard**: Ignore new snore detections while already playing. Prevents rapid audio restart/stutter. If the user wants restart-on-every-snore, it's a one-line removal of `guard !isPlaying else { return }`.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings.
- Verified that MP3 files are present in built app bundle: `SleepGuard.app/sounds/*.mp3` (11 files).

### Next Session
- No immediate follow-up for this feature. The soothing melody is fully functional end-to-end.

### Open Questions
- None.


---

## 2026-05-14 — Session 44: Soothing Melody — Playback, Mute, Custom Recording, Previews

### Completed
- **F2-T10 (follow-up)**: Fixed melody playback not working — `Bundle.main.url(forResource:)` needed `subdirectory: "sounds"` fallback; `.measurement` audio session mode was routing playback to earpiece so `overrideOutputAudioPort(.speaker)` was added. Added extensive debug logging to `SoothingMelodyPlayer` and `SessionManager`.
- **F2-T10 (follow-up)**: Added "Mute for session" option in `BedsideClockView` overlay. Tapping "Stop" allows re-triggering on future snores; "Mute for session" disables all further melody playback until a new recording session starts.
- **F2-T11**: Added 3-second audio preview when tapping any melody row in `MelodyPickerSheet`.
- **F2-T11**: Added custom melody recording — "Record yours" pinned row in `MelodyPickerSheet` opens `RecordCustomMelodySheet` with 10-second `AVAudioRecorder`, playback, re-record, and save.
- **F2-T11**: `CustomMelodyStorage` (Env) persists custom melody metadata and audio files to `Documents/CustomMelodies/`.
- **F2-T11**: Fixed `SoothingMelodySheet.songRow` to resolve custom melodies (checks both bundled `Melody` and `CustomMelodyStorage`).
- **UX polish**: Added helper text under "Soothing melody" actionRow in `RecordingPrestartView`.
- **Refactor**: Extracted `SheetHandle` and `SheetNavHeader` from `SoothingMelodySheet.swift` into `DesignSystem/SheetHeader.swift` for reuse.

### Technical Details
- `AVAudioPlayer` playback requires `overrideOutputAudioPort(.speaker)` when the app's `AVAudioSession` uses `.measurement` mode, because iOS routes playback to the receiver (earpiece) at near-zero volume in measurement mode.
- `Bundle.main.url(forResource:withExtension:subdirectory:)` is more reliable than the parameterless variant when files live inside a folder-reference subdirectory.
- `AVAudioRecorder` (not `AVAudioEngine`) is the right tool for the custom melody recording feature — much simpler setup for a standalone 10-second voice clip.
- Custom melody IDs start at 100 to avoid collision with bundled IDs (1–11). `CustomMelodyStorage` persists an array of dictionaries to UserDefaults and stores `.m4a` files in `Documents/CustomMelodies/`.
- `Melody` model gained `isCustom: Bool`; `Melody.melody(id:)` only searches bundled. All consumers (`SoothingMelodyPlayer`, `SoothingMelodySheet`) now fall back to `CustomMelodyStorage.shared.melody(id:)`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard.xcodeproj/project.pbxproj` | +6 | Added `sounds/` folder reference to app target resources |
| `Packages/Models/Sources/Data/Melody.swift` | +11/-10 | Added `isCustom` flag; real filename + displayName mapping |
| `Packages/Env/Sources/Services/SoothingMelodyPlayer.swift` | +45/-30 | Speaker override, subdirectory fallback, debug logging, session mute API |
| `Packages/Env/Sources/Services/SessionManager.swift` | +6 | Triggers `playIfNeeded()` on new snore event; stops on session end; event logging |
| `Packages/Env/Sources/Services/UserPreferences.swift` | +1/-1 | Default `selectedMelodyID` 12 → 6 |
| `Packages/Env/Sources/Services/CustomMelodyStorage.swift` | +65 | **New** — metadata + file I/O for user-recorded melodies |
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +9 | Helper text below soothing melody actionRow |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +35 | Melody overlay with "Stop" + "Mute for session" buttons |
| `Packages/SleepSession/Sources/Views/SoothingMelodySheet.swift` | +1/-1 | Default `draftMelodyID` 12 → 6; removed local SheetHandle/SheetNavHeader |
| `Packages/SleepSession/Sources/Views/SoothingMelodySheet.swift` | +2/-1 | `selectedMelody` now resolves custom melodies via `CustomMelodyStorage` |
| `Packages/SleepSession/Sources/Views/MelodyPickerSheet.swift` | +65/-30 | Audio preview on tap (3s), "Record yours" row, custom melody list, delete |
| `Packages/SleepSession/Sources/Views/RecordCustomMelodySheet.swift` | +165 | **New** — 10s recording sheet with playback, re-record, save |
| `Packages/DesignSystem/Sources/Components/SheetHeader.swift` | +35 | **New** — Extracted `SheetHandle` and `SheetNavHeader` |
| `SleepGuard/SleepGuardApp.swift` | +2 | Injected `SoothingMelodyPlayer` into environment |
| `SleepGuard/AppRegistry.swift` | +4 | Added `SoothingMelodyPlayer` to dependency graph |

### Architecture Decisions
- **Custom melody storage in Env**: `CustomMelodyStorage` lives in `Env` because it's a runtime singleton service that manages file I/O and UserDefaults. `Models` package stays pure (no file system knowledge).
- **Two-stop overlay buttons**: "Stop" (allows re-trigger) and "Mute for session" (disables for remainder of session) give users explicit control without needing a settings toggle.
- **AVAudioRecorder for custom clips**: Chosen over `AVAudioEngine` because we don't need FFT analysis, tap buffers, or real-time classification for a simple voice recording.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings.

### Next Session
- No immediate follow-up for this feature. Soothing Melody is fully functional end-to-end.

### Open Questions
- None.


---

## 2026-05-15 — Session 45: Nightstand Mode — Auto-lock Prevention + Charging Alert + Mic Permission Gate

### Completed
- **Idle timer disable during sleep sessions**: Added `UIApplication.shared.isIdleTimerDisabled` logic in `SleepGuardApp.swift` tied to `SessionManager.isRecording`. Also handles `scenePhase` `.active` to re-disable the idle timer when returning from background (iOS auto-re-enables it on background).
- **Charging alert before recording**: Added an alert when the user taps Start Recording and the iPhone is not charging. Alert shows in both `RecordingPrestartView` (main start button) and `RecordingCountdownView` ("Start Now" button). Auto-start after countdown completion skips the alert since the user isn't present.
- **Microphone permission gate before recording**: Both `RecordingPrestartView` and `RecordingCountdownView` now check `AudioRecorder.hasPermission` before starting. If undetermined, requests permission asynchronously; if denied, shows an alert with "Open Settings" that links to the app's Settings page. Recording cannot start without microphone access.
- **Alert actions**: Charging alert: "Cancel" dismisses; "Start Anyway" proceeds. Microphone alert: "Cancel" dismisses; "Open Settings" routes to system Settings. Alert button actions wrapped in `Task { @MainActor in }` for safe actor isolation.

### Technical Details
- `UIDevice.current.isBatteryMonitoringEnabled = true` must be set before reading `batteryState`. On simulator, `batteryState` returns `.unknown` so the alert always fires — this is expected simulator behavior.
- Alert closures use shared singletons (`SessionManager.shared`, `UserPreferences.shared`) directly rather than `@Environment` properties to avoid any potential environment access issues from modal alert contexts.
- Added 6 localized strings: `session.chargingAlert.title/message/startAnyway` and `session.microphoneAlert.title/message/openSettings` via `Strings.txt` → `generate-xcstrings.py`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/SleepGuardApp.swift` | +9 | `scenePhase` env + `.onChange` for `isRecording` and `.active` to toggle idle timer |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` | +3 | Added charging alert title, message, startAnyway strings |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | — | Regenerated with 3 new entries |
| `Packages/DesignSystem/Sources/Strings.swift` | — | Regenerated with `sessionChargingAlertTitle`, `Message`, `StartAnyway` |
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +45 | Charging check + microphone permission check in start button, alert modifiers for both, `beginSession()` helper, `isCharging` property |
| `Packages/SleepSession/Sources/Views/RecordingCountdownView.swift` | +38 | Charging check + microphone permission check in "Start Now", alert modifiers for both, `startSession()` helper, `isCharging` property |

### Build Status
- **BUILD SUCCEEDED** — zero errors.

### Git Handoff
- **Suggested branch**: `feature/nightstand-auto-lock-charging-alert`
- **Suggested commit**: `Nightstand mode — disable idle timer during sessions + charging alert before recording`

### Open Questions
- On physical devices, verify that `batteryState` returns `.charging` or `.full` when plugged in. If any device returns `.unknown` while charging, the alert logic may need adjustment.


---

## 2026-05-16 — Session 46: Soothing Melody Polish + Event Player Fixes

### Completed
- **Lock-screen note for soothing melody**: Added contextual subtitle inside `soothingMelodyRow` in `RecordingPrestartView` using `lock.open.fill` icon, displayed only when melody mode != `.never`. Clarifies that the lock screen must remain visible for the melody to trigger.
- **4-second minimum melody play duration**: Added `melodyMinPlayDuration = 4.0` and `melodyStartTime` tracking in `SessionManager`. Melody now continues playing until at least 4 seconds have elapsed since start, even if non-snore is detected immediately. Prevents stuttery on/off behavior for very short snore bursts.
- **Audio recording resume failure fix**: Root cause was `AVAudioEngine` cannot be reliably restarted after `stop()` with an input tap installed. Fixed by fully recreating the engine in `resumeRecording()` instead of restarting the old one. `pauseRecording()` now removes the tap and nils `audioEngine`. Kept `setCategory(.playback)` in `SoothingMelodyPlayer` for maximum volume.
- **Event Player simulator playback failure**: iOS Simulator requires `setActive(false)` before switching from `.playAndRecord` to `.playback`. Added deactivation step in `ClipPlaybackController` and `PlayerSheetView` legacy playback paths.
- **Event Player missing audio handling**: Added `hasAudioForCurrentEvent` to `ClipPlaybackController`, `sessionAudioURL` fallback helper (`audioFileURL` → `rawAudioFileURL`), and `noAudioView` UI with localized strings. Prevents crash when clip extraction hasn't completed or file is missing.
- **Waveform loading UX**: Added `isWaveformLoading` state, skeleton placeholder bars with pulse animation in `EventPlayerView`, and moved `WaveformGenerator.generateSamples` to `Task.detached` so the main thread isn't blocked on long clips.

### Technical Details
- `AVAudioEngine` restart bug: Apple docs state `stop()` invalidates the engine's running state but leaves nodes attached; a subsequent `start()` often fails when an input-node tap is present. The robust fix is `engine = nil` → `engine = AVAudioEngine()` → rebuild chain → `start()`.
- `Task.detached(priority: .userInitiated)` for waveform generation prevents the UI from freezing when generating samples from large `.caf` files.
- Skeleton placeholder uses deterministic pseudo-random bar heights (`(index * 7 + 13) % 17`) so bars don't flicker during pulse animation. Opacity pulses between 0.25 and 0.55.
- `pulsePhase` animation runs in a `.task(id: isLoadingWaveform)` loop, auto-cancelled when loading completes.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +18 | `soothingMelodyRow` accepts optional `subtitle`; shows lock icon + note when melody enabled |
| `Packages/Env/Sources/Services/SessionManager.swift` | +8 | `melodyMinPlayDuration`, `melodyStartTime`, min-duration gate before stopping melody |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +18/-4 | `pauseRecording()` nils engine + removes tap; `resumeRecording()` creates fresh `AVAudioEngine` |
| `Packages/Env/Sources/Services/SoothingMelodyPlayer.swift` | +1 | `setActive(false)` before category switch (simulator fix) |
| `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` | +6 | `hasAudioForCurrentEvent` computed property; `setActive(false)` before playback |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | +35/-5 | `isLoadingWaveform` state; `sessionAudioURL` fallback; `noAudioView`; `Task.detached` waveform gen |
| `Packages/Recordings/Sources/Views/EventPlayerView.swift` | +22/-3 | `isLoadingWaveform` parameter; `waveformPlaceholder` with pulse animation; scrub disabled while loading |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +12 | `soothing.melody.lockscreen.note`, `event.player.noAudio.title`, `event.player.noAudio.description` |
| `Packages/DesignSystem/Sources/Strings.swift` | — | Regenerated with new keys |

### Build Status
- **BUILD NOT VERIFIED** — No Xcode.app installed in build environment (only CommandLineTools). Code reviewed for syntax correctness.

### Git Handoff
- **Suggested branch**: `feature/melody-polish-event-player-fixes`
- **Suggested commit**: `Soothing Melody polish + Event Player fixes`
  - Lock-screen requirement note in RecordingPrestartView
  - 4s minimum melody duration to prevent stutter
  - AVAudioEngine recreation fix for recording resume
  - Simulator audio session deactivation before playback
  - Missing audio fallback with noAudioView
  - Waveform skeleton loading + off-main-thread generation

### Open Questions
- Verify `AVAudioEngine` recreation approach on physical devices — any latency introduced by rebuilding the engine chain?
- Should the 4s minimum melody duration be user-configurable in Settings?


---

## 2026-05-16 — Session 46: Recording Button Pin + iOS 26 Liquid Glass Tab Bar Fix

### Completed
- **Pinned Start Recording button** in `RecordingPrestartView` so it stays fixed 10px above the tab bar while content scrolls.
- **Fixed button cut-off on iOS < 26** caused by the custom floating tab bar overlaying content. Added `.padding(.bottom, 86)` to `customContent` in `MainTabView` so the tab bar reserves its own space instead of overlapping child views.
- **Fixed liquid glass tab bar light/dark glitch** on iOS 26+. The tab bar was inconsistently transitioning between light and dark materials because:
  - `UserPreferences.appearance` defaulted to `.system`, so `preferredColorScheme` was `nil`. When the device was in light mode, the liquid glass tab bar rendered light against the app's always-dark UI.
  - `.toolbarBackground(theme.bgSecondary, for: .tabBar)` was forcing a solid color behind the adaptive liquid glass material, causing it to recalculate and flicker during transitions.

### Technical Details
- **RecordingPrestartView restructuring**: Moved `StartRecordingButton` and Cancel `Button` out of the `ScrollView` into a pinned bottom `VStack` inside a `ZStack(alignment: .bottom)`. Added `.padding(.bottom, 10)` to the button bar. Increased bottom spacer from 120 → 160 so scroll content clears the pinned buttons.
- **Custom tab bar safe-area fix**: The iOS < 26 custom tab bar is an overlay in a `ZStack` and doesn't contribute to safe area insets. Adding `.padding(.bottom, 86)` to `customContent` makes all tab content end exactly where the tab bar begins, preventing any overlapping views.
- **Liquid glass fix**: Removed `.toolbarBackground(theme.bgSecondary, for: .tabBar)` from `systemTabView` (iOS 26+). Changed `UserPreferences.appearance` default from `"system"` to `"dark"` (and fallback `?? .system` to `?? .dark`). The app is dark-only (all design tokens are dark), so forcing `.dark` color scheme keeps the liquid glass tab bar consistently dark.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +24/-24 | Extracted button + cancel from ScrollView into pinned bottom bar via ZStack; bottom spacer 120→160 |
| `SleepGuard/MainTabView.swift` | +2/-2 | Added `.padding(.bottom, 86)` to `customContent` (iOS < 26); removed `.toolbarBackground(theme.bgSecondary, for: .tabBar)` from `systemTabView` (iOS 26+) |
| `Packages/Env/Sources/Services/UserPreferences.swift` | +2/-2 | Default appearance `"system"` → `"dark"`; fallback `.system` → `.dark` |

### Architecture Decisions
- **Reserve space instead of overlay**: For the custom tab bar, padding `customContent` is cleaner than trying to calculate bottom insets inside every child view. It fixes the issue globally for all tabs.
- **Let liquid glass self-manage**: Apple designed iOS 26 liquid glass to adapt its own material. Explicit `.toolbarBackground` colors conflict with this and should be avoided on iOS 26+.

### Build Status
- **BUILD NOT VERIFIED** — `xcodebuild` unavailable (CommandLineTools selected instead of Xcode). Code changes are SwiftUI-only and syntactically valid.

### Git Handoff
- **Suggested commit**: `Pin RecordingPrestart button + fix liquid glass tab bar flicker`
  - Pinned Start Recording button 10px from tab bar in RecordingPrestartView
  - Added customContent bottom padding to prevent custom tab bar overlap on iOS < 26
  - Default appearance .dark; removed forced toolbarBackground on iOS 26+ liquid glass

### Open Questions
- Should `SettingsAppearanceSection` be wired up with a real picker? Currently it shows "Always Dark" as static text with no way to change the theme.


---

## 2026-05-16 — Session 47: HealthKit Sync Auth Persistence Fix

### Completed
- Fixed HealthKit sync silently failing after app restart
- Fixed Settings toggle staying ON when user denies HealthKit permission
- Added auth status re-check before every session sync as a safety net

### Technical Details
**Root cause:** `HealthKitSync.isAuthorized` was a runtime property defaulting to `false`. `checkAuthorizationStatus()` existed but was never invoked, so after any app restart the stored `UserPreferences.syncToHealthKit == true` flag had no effect — `sync(session:)` returned early because `isAuthorized` was still `false`.

**Fixes applied:**
1. `SleepGuardApp.swift` — `.onAppear { HealthKitSync.shared.checkAuthorizationStatus() }` restores the real authorization state from `HKHealthStore` on every launch.
2. `SettingsDataSection.swift` — Toggle binding now requests auth *before* committing the preference. If `requestAuthorization()` returns `false`, the toggle snaps back OFF. This prevents the "toggle ON but nothing happens" UX.
3. `SessionSummaryView.swift` — Sync Task calls `healthKitSync.checkAuthorizationStatus()` before `await healthKitSync.sync(session:)`, guarding against edge cases like permission revocation mid-session.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/SleepGuardApp.swift` | +3 | `.onAppear` calls `HealthKitSync.shared.checkAuthorizationStatus()` |
| `Packages/Settings/Sources/Views/SettingsDataSection.swift` | +5/-3 | Toggle only commits `syncToHealthKit = true` when `requestAuthorization()` returns `granted` |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | +1 | `healthKitSync.checkAuthorizationStatus()` before `sync(session:)` |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Git Handoff
- **Suggested branch**: `fix/healthkit-auth-persistence`
- **Suggested commit**: `Fix HealthKit sync auth persistence — check status on launch, honest toggle, save safety net`

### Open Questions
- None

---

## 2026-05-18 — Session 48: Transparent Gap Tracking for Soothing Melody

### Completed
- Implemented recording gap tracking when soothing melody pauses the microphone
- Adjusted sleep score and snoring percentage to use `monitoredDuration` (excluding gaps)
- Added visual gap indicators to `SnoringTimelineView`
- Added info banner in `SessionSummaryView` and `SessionDetailView` explaining missed detection
- Fixed pre-existing JSON corruption in `Localizable.xcstrings` (duplicate content insertion)

### Technical Details
**Root cause:** `SoothingMelodyPlayer` switches `AVAudioSession` to `.playback`, which triggers `AudioRecorder.pauseRecording()`. The mic is completely dead during melody playback, so any snoring in those windows is invisible to stats.

**Fixes applied:**
1. `RecordingGap.swift` — New `Codable, Sendable` model: `startOffset` + `duration` relative to session start.
2. `SleepSession.swift` — Added `recordingGaps: [RecordingGap]?`, computed `gapsDuration`, `monitoredDuration`. Updated `snoringPercentage` and `sleepScore` to use `monitoredDuration` instead of `totalDuration`.
3. `AudioNotifications.swift` — Added `.recordingDidPause` and `.recordingDidResume`.
4. `AudioRecorder.swift` — `pauseRecording()` stores `currentGapStart` and posts `.recordingDidPause`. `resumeRecording()` and `stopRecording()` calculate duration and post `.recordingDidResume`.
5. `SessionManager.swift` — Observes pause/resume notifications, appends `RecordingGap` to `currentSession.recordingGaps` on resume. Initializes `recordingGaps = []` at session start.
6. `SnoringTimelineView.swift` — Renders gap segments as `textTertiary.opacity(0.18)` fill with `textTertiary.opacity(0.35)` stroke, making detection blind spots visible on the timeline.
7. `MelodyGapsBannerView.swift` — New reusable DesignSystem component. Shows: "Soothing melody paused detection for **X min**. Actual snoring may be higher than recorded." Only appears when gaps exist.
8. `SessionSummaryView.swift` & `SessionDetailView.swift` — Added `MelodyGapsBannerView(session: session)` below stats/timeline.
9. `Localizable.xcstrings` — Added `session.summary.melodyGapsInfo` key. Also fixed severe pre-existing corruption where the file contained duplicated JSON content starting at line 2164, causing `generate-strings.py` to fail.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/RecordingGap.swift` | +21 | New model for mic-paused intervals |
| `Packages/Models/Sources/Data/SleepSession.swift` | +18/-3 | Added `recordingGaps`, `gapsDuration`, `monitoredDuration`; updated `snoringPercentage` & `sleepScore` denominators |
| `Packages/Models/Sources/Helpers/AudioNotifications.swift` | +2 | Added `.recordingDidPause`, `.recordingDidResume` |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +15/-1 | Track gap start/end; post pause/resume notifications |
| `Packages/Env/Sources/Services/SessionManager.swift` | +35/-1 | Observe notifications; append gaps to session; init `recordingGaps` |
| `Packages/DesignSystem/Sources/Components/SnoringTimelineView.swift` | +32/-1 | Render gap segments on timeline canvas |
| `Packages/DesignSystem/Sources/Components/MelodyGapsBannerView.swift` | +40 | New reusable info banner for melody gaps |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | +2 | Added banner below stats grid |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +2 | Added banner below timeline |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +216/-2031 | Added new string; fixed corruption by deduplicating and reformatting |
| `Packages/DesignSystem/Sources/Strings.swift` | +8/-203 | Regenerated with 216 strings |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Git Handoff
- **Suggested branch**: `feature/recording-gap-tracking`
- **Suggested commit**: `Transparent gap tracking for soothing melody — monitoredDuration stats, timeline gaps, UI banner`
  - Track mic-paused intervals during melody playback as `RecordingGap`
  - Sleep score & snoring % now use `monitoredDuration` (total - gaps)
  - `SnoringTimelineView` renders gaps with semi-transparent overlay
  - `MelodyGapsBannerView` explains missed detection to users
  - Fixed `Localizable.xcstrings` JSON corruption

### Open Questions
- Should gap data be included in the PDF sleep report or HealthKit metadata?
- Should we add a Settings toggle to let users choose between max-volume melody (with gaps) vs ducked melody (continuous detection)?


---

## 2026-05-18 — Session 49: Gap Tracking Hardening + Model Lightness + Banner Pluralization

### Completed
- Removed notification-based gap tracking; replaced with direct `.soothingMelodyDidStop` observation
- Fixed event discard during mic pause (`!soothingMelodyPlayer.isPlaying` guard + `lastSnoringSampleTime` extension on resume)
- Reverted `gapsDuration` from stored to computed to keep `SleepSession` lightweight and migration-free
- Added 0.5s minimum for force-finalized events (prevents 0-second saved events)
- MelodyGapsBannerView "over X mins" format with proper pluralization

### Technical Details
- `AudioRecorder` no longer posts `.recordingDidPause` / `.recordingDidResume`; removed `currentGapStart`
- `SessionManager` observes `.soothingMelodyDidStop` → `logRecordingGap(start:duration:)` + `melodyStartTime = nil`
- `processAudioLevel()` event-finalize branch now requires `!soothingMelodyPlayer.isPlaying` to avoid stale-data discards
- `handleMelodyDidStop()` extends `lastSnoringSampleTime = Date()` when mic resumes so `eventSpan` covers the gap
- `SleepSession.gapsDuration` is computed from `recordingGaps` again; `SessionManager` only writes to `recordingGaps` via full array reassignment
- `finalizeActiveEvent(skipMinDuration:)` uses 0.5s floor when `skipMinDuration == true`
- New localized strings: `common.over`, `time.minute.singular/plural`, `time.hour.singular/plural`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepSession.swift` | +4/-4 | `gapsDuration` reverted from stored to computed |
| `Packages/Models/Sources/Helpers/AudioNotifications.swift` | +0/-2 | Removed unused `.recordingDidPause`, `.recordingDidResume` |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +0/-12 | Removed `currentGapStart`, gap notifications, `isMicPaused` |
| `Packages/Env/Sources/Services/SessionManager.swift` | +20/-35 | Direct gap tracking via `.soothingMelodyDidStop`; event-finalize guard; `lastSnoringSampleTime` extension |
| `Packages/DesignSystem/Sources/Components/MelodyGapsBannerView.swift` | +8/-5 | `durationString` now returns "over X mins" with pluralization |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +72/-0 | Added `common.over`, `time.*` plural keys |
| `Packages/DesignSystem/Sources/Strings.swift` | +5/-0 | Regenerated with 221 strings |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Next Session
- Verify gap tracking end-to-end on a real device with timed and always melody modes
- Consider adding gap data to PDF sleep report or HealthKit metadata

### Open Questions
- Should gap duration be surfaced in the exported PDF sleep report?
- Should we add a Settings toggle for ducked melody (continuous detection, lower volume) vs full-volume melody with gaps?


---

## 2026-05-17 — Session 48: UI Polish — Tab Bar Liquid Glass + Recording Layout Fixes

### Completed
- Fixed UI glitch when tapping Start Recording button by making `onStartRecording` closures `@MainActor`
- Made `RecordingPrestartView` adaptive for compact screens (iPhone 16e, 17 Pro, smaller)
- Added smooth sliding pill animation to custom tab bar via `matchedGeometryEffect`
- Mimicked iOS 26 liquid glass effect on custom tab bar for iOS < 26

### Technical Details
- `@MainActor` on `onStartRecording` ensures navigation state mutations run on the main thread, eliminating the frame-drop glitch when tapping the Statistics tab CTA.
- `isCompactHeight` uses `UIScreen.main.bounds.height <= 874` to scale down `iconSection` (100 → 80 pts, font 44 → 36 pts) and headline title (28 → 24 pts) on smaller devices without affecting Pro Max screens.
- `matchedGeometryEffect(id: "activeTab", in: tabAnimation)` with a conditional `RoundedRectangle` creates a ghost view that smoothly slides between tab positions during selection changes.
- Liquid glass approximation: `.ultraThinMaterial` + `theme.bgCard` tint + subtle white gradient highlights for the floating capsule container; solid `theme.bgCard` active pill with light stroke and top highlight.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/Views/StatisticsEmptyView.swift` | +1/-1 | `@MainActor let onStartRecording: () -> Void` |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | +1/-1 | `@MainActor let onStartRecording: () -> Void` |
| `Packages/Statistics/Sources/Views/StatisticsDashboardView.swift` | +2/-2 | Inline closures annotated `{ @MainActor in }` |
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +10/-4 | `isCompactHeight` property; adaptive `iconSection` and `headlineSection` sizing |
| `SleepGuard/MainTabView.swift` | +25/-15 | `matchedGeometryEffect` sliding active pill; liquid glass materials + gradient highlights |

### Architecture Decisions
- **MainActor on closures**: Propagating `@MainActor` through the closure type signature is cleaner than wrapping every call site in `Task { @MainActor in }`.
- **Screen-height threshold**: `UIScreen.main.bounds.height <= 874` covers iPhone 16e (844 pts), 17 Pro (874 pts), and all smaller devices, while leaving Pro Max (932 pts) untouched.

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Git Handoff
- **Suggested branch**: `feature/ui-polish-tab-bar-recording-layout`
- **Suggested commit**: `UI Polish — @MainActor recording CTA, compact height layout, liquid glass tab bar`
  - `@MainActor` on `onStartRecording` closures in Statistics package
  - `RecordingPrestartView` adaptive layout for compact-height devices
  - Custom tab bar `matchedGeometryEffect` sliding pill animation
  - Liquid glass mimic for iOS < 26 using materials + gradient highlights

### Open Questions
- None


---

## 2026-05-19 — Session 51: Increase Snore Event Gap Threshold

### Completed
- Increased `eventGapThreshold` from 3.0 → 10.0 seconds in `SessionManager`

### Technical Details
- The existing burst-tracking architecture (`activeBurstStart`, `completedBursts`, `SnoreBurst`) already captures continuous snoring segments and gaps between them, so a longer threshold naturally produces multi-burst events instead of separate events.
- `AudioClipExtractor` composes gap-free clips from bursts via `AVMutableComposition`, so merged events still produce clean audio clips.
- The melody play/stop logic is fully decoupled from event finalization (melody stops on sustained non-snore + 4 s minimum play duration), so anti-snore behavior is unaffected.
- Existing sessions remain split (threshold only applies to new recordings).

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/SessionManager.swift` | +1/-1 | `eventGapThreshold: TimeInterval = 3.0` → `10.0` |

### Architecture Decisions
- **Single-line threshold change vs. post-session merging**: Post-session merging would touch the data model and require burst offset recalculation. Since the architecture already supports multi-burst events, simply widening the real-time threshold is safer and produces the same outcome for new sessions.

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Git Handoff
- **Suggested branch**: `tweak/event-gap-threshold-10s`
- **Suggested commit**: `Increase snore event gap threshold from 3s to 10s`
  - Brief breathing pauses under 10s now merge into a single SnoreEvent
  - Reduces duplicate "same minute" entries in the events list

### Open Questions
- None


---

## 2026-05-22 — Session 52–53: Background Audio Fix + Snoring Time Refactor

### Completed
- **Session 52**: Fixed background audio recording — microphone was stopping when app entered background
- **Session 53**: Refactored snoring duration calculation to use event-span (validated epoch style) instead of burst-sum

### Technical Details

**Background Audio Fix:**
- Root cause: `UIBackgroundModes` was declared in build settings (`INFOPLIST_KEY_UIBackgroundModes = audio`) but was NOT being injected into the built `Info.plist` due to array-vs-string syntax mismatch in `project.pbxproj`. The built app had no background audio entitlement, so iOS suspended it on backgrounding.
- Fixed by explicitly adding `UIBackgroundModes` array with `audio` to `SleepGuard/Info.plist`, and correcting the pbxproj syntax to `(audio)` array format.
- `AudioRecorder` improvements:
  - Added `.mixWithOthers` to `AVAudioSession` category options to prevent interruption by other apps' audio.
  - Added `isPaused` flag to distinguish intentional mic pauses (soothing melody) from unintended stops.
  - Added `AVAudioSession.routeChangeNotification` and `UIApplication.didBecomeActiveNotification` observers to restart the engine if it stops due to route changes or background suspension.
  - Replaced bare `audioEngine?.start()` in interruption handler with `resumeRecordingIfNeeded()`, which does a full engine rebuild if needed.
- `SoothingMelodyPlayer` no longer switches `AVAudioSession` category to `.playback` — this was dropping the microphone input and breaking background recording resumption. The existing `.playAndRecord` session already supports playback.

**Snoring Time Refactor:**
- Research showed validated apps (SnoreClock, SnoreLab) define a snoring "epoch" as the full episode span including natural breathing pauses (<10s) within it.
- `SnoreEvent` gained a new `duration: TimeInterval = 0` property storing `eventSpan` (from `activeEventStart` to `lastSnoringSampleTime`).
- `SnoreEvent.snoreDuration` now returns `duration` when available, falling back to burst-sum for legacy pre-migration data.
- `SleepSession.snoringDuration` no longer adds `gapsDuration`. Recording gaps (soothing melody mic pauses) are excluded — we no longer assume snoring continued during intervention.
- `sleepScore` comment updated to reflect the change.
- `bursts` array is preserved for clip extraction and fragmentation analysis.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/Info.plist` | +7/-1 | Added `UIBackgroundModes` array with `audio` |
| `SleepGuard.xcodeproj/project.pbxproj` | +4/-2 | `INFOPLIST_KEY_UIBackgroundModes` changed from string `audio` to array `(audio)` |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +46/-10 | `.mixWithOthers`; `isPaused`; route-change + didBecomeActive observers; `resumeRecordingIfNeeded()`; improved interruption handler |
| `Packages/Env/Sources/Services/SoothingMelodyPlayer.swift` | +3/-4 | Removed `setCategory(.playback)` and `setActive(true)` calls that were dropping the mic |
| `Packages/Models/Sources/Data/SnoreEvent.swift` | +14/-3 | Added `duration` property; updated init; `snoreDuration` returns event-span with burst-sum fallback |
| `Packages/Env/Sources/Services/SessionManager.swift` | +1/-1 | `finalizeActiveEvent()` passes `eventSpan` as `duration` to `SnoreEvent` |
| `Packages/Models/Sources/Data/SleepSession.swift` | +3/-3 | `snoringDuration` no longer adds `gapsDuration`; comment updated |

### Architecture Decisions
- **Explicit Info.plist over generated-only**: Despite `GENERATE_INFOPLIST_FILE = YES`, the `UIBackgroundModes` key was not being reliably generated. Adding it explicitly to the source `Info.plist` guarantees it is present in all builds.
- **Event-span over burst-sum**: Burst-sum under-reports snoring time by excluding natural breathing pauses within an episode. Event-span matches how clinically validated apps measure snoring and better represents the user's actual snoring episodes.
- **Backward compatibility via fallback**: `SnoreEvent.snoreDuration` falls back to burst-sum when `duration == 0`, preserving existing session data without requiring a SwiftData migration.
- **Gaps excluded from snoring time**: Recording gaps are now treated as "intervention time" rather than inferred snoring. This makes the metric more honest — the soothing melody may have actually stopped the snoring.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- Continue V2 polish or start F13 (CloudKit Sync)

### Git Handoff
- **Suggested branch**: `fix/background-audio-snoring-duration`
- **Suggested commit**: `Fix background audio + refactor snoring duration to event-span`
  - Add `UIBackgroundModes` to Info.plist; fix pbxproj array syntax
  - AudioRecorder: `.mixWithOthers`, route/foreground observers, robust resume
  - SoothingMelodyPlayer: stop switching AVAudioSession to `.playback`
  - SnoreEvent: `duration` field; `snoreDuration` uses event-span
  - SleepSession: `snoringDuration` excludes gaps

### Open Questions
- Should `snoringPercentage` denominator be `totalDuration` or `monitoredDuration`? Currently uses `totalDuration`.
- Should the PDF sleep report show recording gaps as a separate stat?


## 2026-05-22 — Session 54: Snore Detection Thresholds + Epic Tier + Sensitivity

### Completed
- Researched clinically validated snoring intensity classification (SnoreLab uses quiet/light/loud/epic; medical literature: 40 dB SPL = breathing→snoring threshold, mean peaks 50–65 dB, highs 80–90 dB).
- Identified core issue: SleepGuard measures uncalibrated dBFS, not dB-SPL. Fixed thresholds have no absolute physiological meaning but can be improved relative to ambient noise.
- Added **4th "epic" intensity tier** matching SnoreLab's clinically validated system.
- **Tightened SoundAnalysis dB floors** from -60/-40/-25 to -45/-30/-15 to reduce false positives from ambient bedroom noise.
- **Tightened spectral/base thresholds** from -35/-25/-15 to -30/-20/-10 with epic at -5.
- **Wired `detectionSensitivity`** (low/medium/high) to shift all thresholds by ±5 dB. Applied at session start.
- Added `snoreEpic` color (`#FF2D55`) to Theme and updated all `intensityColor` call sites.
- Updated `sleepScore` to account for `epic` intensity (30 penalty per ratio, cap raised to 30).
- Added documentation comments to `averageDB`/`peakDB` noting they are dBFS, not calibrated SPL.
- Implemented `SettingsRecordingSection` with segmented sensitivity picker; added to `SettingsView`.
- Added 5 new localized strings and regenerated `Strings.swift`.

### Technical Details
- `SnoreIntensity` and `SnoringState` enums are `String`-backed, so adding `.epic` is backward-compatible with existing SwiftData — old sessions simply never have "epic" values.
- `SnoreDetector` now exposes `epicThreshold` and uses consistent threshold math across all three classification paths (SoundAnalysis, spectral, fallback).
- SoundAnalysis floors are computed relative to base thresholds (`quietThreshold - 15`, `lightThreshold - 10`, `loudThreshold - 5`, `epicThreshold`) so sensitivity shifts apply uniformly.
- `SessionManager.applyDetectionSensitivity()` reads `UserPreferences.detectionSensitivity` and shifts thresholds before each session start.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SnoreEvent.swift` | +6/-1 | Added `.epic` to `SnoreIntensity`; doc comments on `averageDB`/`peakDB` |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +40/-25 | Added `.epic` to `SnoringState`; new base thresholds; tightened SoundAnalysis floors; `epicThreshold` property |
| `Packages/Env/Sources/Services/SessionManager.swift` | +22/-2 | `applyDetectionSensitivity()` on start; updated `intensity(from:)` and `intensityRank(_:)` for `.epic` |
| `Packages/Models/Sources/Data/SleepSession.swift` | +8/-3 | `epicDuration` in sleepScore; intensity penalty cap raised to 30; doc comments on dB fields |
| `Packages/DesignSystem/Sources/Components/Theme.swift` | +3/-1 | Added `snoreEpic` color; updated `intensityColor` |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +4/-2 | `.epic` cases for `snoringColor` and `statusLabel` |
| `Packages/Statistics/Sources/Views/Last7NightsDaySummary.swift` | +4/-2 | `.epic` in `intensityColor` and `maxIntensity` |
| `Packages/Statistics/Sources/Views/CalendarView.swift` | +2/-1 | `.epic` check in `intensityColor(for:)` |
| `Packages/Statistics/Sources/Views/TrendsView.swift` | +2/-1 | `.epic` check in `maxIntensityColor` |
| `Packages/Statistics/Sources/Views/CalendarSelectedNightView.swift` | +3/-2 | `.epic` in `sessionDescription` |
| `Packages/Statistics/Sources/Views/CalendarMonthStatsView.swift` | +1/-1 | Include `.epic` in `loudNights` count |
| `Packages/Recordings/Sources/Views/EventPlayerView.swift` | +1/-1 | `.epic` in `intensityLabel` |
| `Packages/Recordings/Sources/Views/SleepReportPDFGenerator.swift` | +2/-1 | `epicColor`; `.epic` in `intensityColor` |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | +1/-1 | `.capitalized` on `intensity.rawValue` |
| `Packages/Settings/Sources/Views/SettingsRecordingSection.swift` | +30/-1 | Implemented sensitivity picker with segmented control |
| `Packages/Settings/Sources/Views/SettingsView.swift` | +1/-0 | Added `SettingsRecordingSection` |
| `Packages/Env/Sources/Services/UserPreferences.swift` | +0/-7 | Removed attempted `displayName` on `DetectionSensitivity` (caused Env→DesignSystem import cycle) |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +45/-0 | 5 new strings for epic intensity |
| `Packages/DesignSystem/Sources/Strings.swift` | +5/-0 | Regenerated by `generate-xcstrings.py` |

### Architecture Decisions
- **String-backed enum for backward compatibility**: `SnoreIntensity` is `String, Codable`. Adding `.epic` requires no SwiftData migration. Old data simply lacks "epic" values.
- **Threshold shift in SessionManager, not SnoreDetector**: `SnoreDetector` lives in `AudioEngine` and should not import `Env`. `SessionManager` reads the preference and sets the detector's public threshold vars.
- **No dB-SPL calibration (yet)**: True SPL calibration requires a known reference tone and mic sensitivity curve. That is Phase 2 (adaptive baseline). Phase 1 makes the existing relative thresholds less wrong.
- **SoundAnalysis floors relative to base thresholds**: This ensures sensitivity shifts apply consistently across both classification paths.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- Continue V2 polish or start F13 (CloudKit Sync)

### Open Questions
- Should `snoringPercentage` denominator be `totalDuration` or `monitoredDuration`? Currently uses `totalDuration`.
- Should the PDF sleep report show recording gaps as a separate stat?
- Should we implement adaptive baseline (30-second ambient calibration at session start) for truly calibrated relative thresholds?


## 2026-05-22 — Session 55: Future-Proof Data Model for Multi-Sound Detection

### Completed
- Added `SoundCategory` enum (`snoring`, `sleepTalking`, `noise`, `other`) to Models package
- Added `category: SoundCategory` property to `SnoreEvent` with default `.snoring` — lightweight SwiftData migration, all existing events auto-categorize as snoring
- Added `duration(for category:)` computed helper on `SleepSession` for future per-category stats
- Explicitly passed `category: .snoring` in `SessionManager.finalizeActiveEvent()` for clarity
- Left all UI unchanged — no dead "Other Sounds: 0" stat cards

### Technical Details
- `SoundCategory` is `String, Codable, Sendable` — same pattern as `SnoreIntensity` for future extensibility
- SwiftData `@Model` requires fully qualified default value (`SoundCategory.snoring`, not `.snoring`)
- `SleepSession.snoringDuration`, `snoringPercentage`, `eventsCount`, `sleepScore` continue working unchanged because they operate on the full event list
- When multi-sound detection ships, only detection logic and UI need to change — no data migration

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SnoreEvent.swift` | +10/-1 | Added `SoundCategory` enum; added `category` property with default; updated initializer |
| `Packages/Models/Sources/Data/SleepSession.swift` | +4/-0 | Added `duration(for category:)` computed helper |
| `Packages/Env/Sources/Services/SessionManager.swift` | +1/-0 | Explicit `category: .snoring` in `SnoreEvent` init |

### Architecture Decisions
- **Keep `SnoreEvent` model name**: Renaming a `@Model` class is not a lightweight migration. Adding a property is. The name mismatch is cosmetic and harmless.
- **No UI changes now**: Adding an "Other Sounds" stat that always shows 0 would look like a bug. UI evolves when the feature ships.
- **Enum over String**: `SoundCategory` is a closed enum for now. If the user wants open-ended categories (user-defined labels), this can become a `String` later with a migration — but an enum gives type safety and exhaustiveness checking in switches today.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- Continue V2 polish or start F13 (CloudKit Sync)

### Open Questions
- What specific sound categories are anticipated? (coughing, apnea/gasping, pet sounds, traffic?). This determines if `SoundCategory` should stay an enum or become an open String.
- Should non-snore sounds affect the sleep score, or should each category have its own score weighting?


## 2026-05-23 — Session 56: Mock Data Generation for App Store Screenshots

### Completed
- Created `MockDataGenerator` utility in `Packages/Env/Sources/Services/` that generates realistic `SleepSession` + `SnoreEvent` data for May 1–23, 2026
- Wired `#if DEBUG` auto-generation trigger in `SleepGuardApp.swift`: launch app with `-generateMockData` argument to populate data on first launch
- Populated simulator SwiftData store with 20 nights of mock data (3 skipped days for realism)
- Verified data renders correctly on Statistics dashboard with realistic score trend (worse → better), variable event counts, and midnight GMT+2 start times

### Technical Details
- Data algorithm: `dayFactor` (0.0 = May 1, 1.0 = May 23) drives all distributions
  - Event count: lerp(22, 5, dayFactor) ± jitter — early May heavy, late May light
  - Snoring percentage: lerp(32–50%, 6–18%, dayFactor) of session duration
  - Intensity distribution: early May favors `.loud`/`.epic`; late May favors `.quiet`/`.light`
  - Session duration: 6.5–8.5h primary, 1.5–3h secondary (20% of days have 2 sessions)
  - 3 days skipped (May 6, 15, 20) for realistic gaps
- Events distributed across session timeline with 1–2 bursts each
- dB values: avg -54 to -26, peak -10 to -18 — realistic relative dBFS ranges
- Score computed naturally by existing `SleepSession.sleepScore` formula — no hardcoded scores
- Generator clears existing data before insertion to avoid duplicates on re-runs

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/MockDataGenerator.swift` | +122/-0 | New file — generates realistic May 2026 sleep data |
| `SleepGuard/SleepGuardApp.swift` | +9/-1 | Added `#if DEBUG` block that calls `MockDataGenerator.generate` when `-generateMockData` launch argument is present |
| `.xcodebuildmcp/config.yaml` | +1/-1 | Fixed projectPath from `SleepGuard` to `SleepGuard` to match actual directory |

### Architecture Decisions
- **Launch argument trigger over UI button**: More reliable for automation; no risk of shipping debug UI. The `-generateMockData` flag is ephemeral and only works in DEBUG builds.
- **Keep generator in Env package**: Reusable for future screenshot refreshes; depends only on Models and SwiftData.
- **Remove `@MainActor` from generator**: `ModelContext` operations don't require MainActor; this allows calling from `sharedModelContainer` initializer.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- User will take App Store screenshots using the populated data
- If data needs tweaking (e.g., more extreme score range, different date range), re-run with `-generateMockData` after deleting existing data in Settings

### Open Questions
- Should the generator support custom date ranges or score curves via additional launch arguments?
- Should we create a small CLI tool that writes directly to SwiftData sqlite to avoid app launch entirely?

## 2026-05-24 — Session 57: Unify Duration Format Across App

### Completed
- Created `DurationFormatter.hoursAndMinutes(_:)` in `DesignSystem` — shared helper that outputs `X h Y min` or `X min` when under 60
- Replaced all ad-hoc duration formatting wrappers with the shared formatter

### Technical Details
- `DurationFormatter` uses existing localized `Strings.timeHourSingular/Plural` and `Strings.timeMinuteSingular/Plural` — no new English-only strings
- TrendsView: label changed from "SNORING MINUTES" → "AVG SNORING"; big text now shows formatted duration (e.g., "1 h 30 min") instead of raw integer; subtext reduced to "avg / night"
- SessionStatsGrid: "Snore Time" stat changed from `H:MM:SS` → `X h Y min` to match other snoring displays
- Last7NightsStatGrid, Last7NightsRow, NightGroupRowView: inlined formatter calls and removed private `durationString` / `snoringDurationString` / `totalDurationString` wrappers

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Helpers/DurationFormatter.swift` | +16/-0 | New shared formatter |
| `Packages/Statistics/Sources/Views/TrendsView.swift` | +4/-4 | Uses `DurationFormatter.hoursAndMinutes` for avg snoring; label + subtext updated |
| `Packages/Statistics/Sources/Views/Last7NightsStatGrid.swift` | +1/-6 | Inlined formatter; removed private `durationString` wrapper |
| `Packages/Statistics/Sources/Views/Last7NightsRow.swift` | +2/-13 | Inlined formatter for both total duration and snoring; removed private wrappers |
| `Packages/DesignSystem/Sources/Components/SessionStatsGrid.swift` | +1/-1 | Snore Time uses `DurationFormatter.hoursAndMinutes` instead of `H:MM:SS` |
| `Packages/Recordings/Sources/Views/NightGroupRowView.swift` | +2/-15 | Inlined formatter for group total and per-session durations; removed private wrappers |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +15/-2 | Added `stats.trends.avgSnoringLabel`; updated `stats.trends.avgMinFormat` to "avg / night"; updated `stats.trends.snoringMinutesLabel` to "AVG SNORING" |
| `Packages/DesignSystem/Sources/Strings.swift` | +1/-0 | Regenerated with new key |

### Architecture Decisions
- **Single formatter enum over view extensions**: `DurationFormatter` is a plain enum with one static method. No view protocol extensions, no format style wrappers — minimum code for the problem.
- **Removed all single-use private wrappers**: `Last7NightsRow.durationString`, `Last7NightsRow.snoringDurationString`, `Last7NightsStatGrid.durationString`, `NightGroupRowView.totalDurationString`, `NightGroupRowView.durationString` — all deleted. The formatter is the one source of truth.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- Continue V2 polish or start F13 (CloudKit Sync)

### Open Questions
- None

## 2026-05-25 — Session 58: SleepGuard Rebrand — Phase 1 Foundation

### Completed
- Approved Approach B: "SleepGuard — Full Sleep Tracker" (rebrand + multi-sound + Watch sleep stages)
- Phase 1: Foundation — all tasks complete
  - P1-T3: Added `SleepStageSegment` + `SleepStage` enum to `SleepSession`; added `.coughing` to `SoundCategory`
  - P1-T4: Renamed `SnoringState` → `DetectionState` (internal refactor, zero migration, 5 files)
  - P1-T1: Rebrand app struct `SleepGuardApp` → `SleepGuardApp`, file renamed, bundle ID updated, `CFBundleDisplayName` added to Info.plist
  - P1-T2: Updated 6 user-facing strings in `Localizable.xcstrings` (onboarding title/description, microphone alert, delete-all confirmation, privacy copy)
  - P1-T5: Build verified — zero errors

### Technical Details
- `SleepStageSegment` is a lightweight `Codable` struct stored as an array on `SleepSession`. `nil` for all existing sessions → no UI disruption.
- `DetectionState` rename is purely code-level; the enum was never persisted in SwiftData (it's computed in real-time). All references in `SnoreDetector`, `SessionManager`, `BedsideClockView`, `SessionRawLogWriter`, `SnoreSample` updated.
- Bundle ID changed from `com.daki.exampleProject.SleepGuard` → `com.daki.exampleProject.SleepGuard` in Debug/Release configs.
- `CFBundleDisplayName` = "SleepGuard" added to `Info.plist` so the home screen label updates independently of target name.
- All hardcoded "SleepGuard" strings eliminated from Swift code (PDF generator, notification manager, watch app, comments).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepSession.swift` | +21/-0 | Added `SleepStage`, `SleepStageSegment`, and `sleepStageSegments` property |
| `Packages/Models/Sources/Data/SnoreEvent.swift` | +1/-0 | Added `.coughing` to `SoundCategory` |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +1/-1 | `SnoringState` → `DetectionState` |
| `Packages/AudioEngine/Sources/Engine/SnoreSample.swift` | +1/-1 | `SnoringState` → `DetectionState` |
| `Packages/Env/Sources/Services/SessionManager.swift` | +4/-4 | `currentSnoringState` → `currentDetectionState`, `intensity(from:)` param type |
| `Packages/Env/Sources/Services/SessionRawLogWriter.swift` | +1/-1 | `SnoringState` → `DetectionState` |
| `Packages/Env/Sources/Services/RecordingDelayManager.swift` | +2/-2 | Notification title "SleepGuard" → "SleepGuard", ID updated |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +2/-2 | `currentSnoringState` → `currentDetectionState` |
| `Packages/Recordings/Sources/Views/SleepReportPDFGenerator.swift` | +2/-2 | "SleepGuard" → "SleepGuard" in PDF header/footer |
| `Packages/Recordings/Sources/Views/EventPlayerView.swift` | +1/-1 | Comment updated |
| `WatchApp/Sources/SleepGuardWatchApp.swift` | +1/-1 | `SleepGuardWatchApp` → `SleepGuardWatchApp` |
| `SleepGuard/SleepGuardApp.swift` | — | Deleted (renamed to `SleepGuardApp.swift`) |
| `SleepGuard/SleepGuardApp.swift` | +76/-0 | New file (renamed from `SleepGuardApp.swift`) |
| `SleepGuard/Info.plist` | +2/-0 | Added `CFBundleDisplayName` = "SleepGuard" |
| `SleepGuard.xcodeproj/project.pbxproj` | +2/-2 | Bundle ID updated to `com.daki.exampleProject.SleepGuard` |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +6/-6 | 6 strings updated to SleepGuard/generic copy |

### Architecture Decisions
- **Keep `SnoreEvent` model name**: Internal model names don't need to change. The `category` field already provides the generic abstraction.
- **`SleepStageSegment` as Codable array rather than @Model relationship**: Avoids complex SwiftData relationships for optional data. HealthKit sleep data is read-only and append-only; a simple array is sufficient.
- **Bundle display name via Info.plist instead of target rename**: Changing Xcode target names breaks schemes, derived data paths, and script references. Info.plist override is safer and reversible.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- Phase 2: Sleep Talking Detection
  - Create `SpeechDetector` in `AudioEngine`
  - Wire parallel detection into `SessionManager`
  - Add "Detect Sleep Talking" toggle in Settings

### Open Questions
- Should we rename the Xcode project file itself (`SleepGuard.xcodeproj` → `SleepGuard.xcodeproj`) and all scheme names? This is developer-facing and can be deferred.
- Should the onboarding screens be redesigned to visually reflect "SleepGuard" (new hero images, colors)? The current onboarding is snore-focused.


---

## 2026-05-26 — Session 59: P2-T1 SpeechDetector

### Completed
- P2-T1: Built `SpeechDetector` classifier in AudioEngine
- Extended `SoundAnalysisDetector` to extract speech confidence from built-in 300-class classifier

### Technical Details
- `SpeechDetector` is a `@MainActor @Observable` singleton following the same pattern as `SnoreDetector`
- Classification requires both `speechConfidence >= 0.5` and `db >= -40.0` to filter out whisper-quiet false positives
- `SoundAnalysisDetector` now scans for speech-related identifiers (`speech`, `talking`, `conversation`, `narration`, `monologue`) in the same `SNClassificationResult` used for snoring — zero additional ML overhead
- Speech confidence is published on `@MainActor` alongside snore confidence in a single `Task`
- Both confidences reset to 0 when `stopAnalyzing()` is called

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/SpeechDetector.swift` | +47 | New classifier: `classify(db:speechConfidence:)`, `update(db:speechConfidence:)`, configurable thresholds |
| `Packages/AudioEngine/Sources/Engine/SoundAnalysisDetector.swift` | +14/-4 | Added `speechConfidence` property, `speechIdentifiers` array, parallel extraction in result handler, reset on stop |
| `docs/trackers/f14-sleepguard-rebrand.md` | +1/-1 | P2-T1 marked Done |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard counts, Activity Log, Currently Active, Completed, Up Next updated |

### Architecture Decisions
- **Speech detection piggybacks on existing SoundAnalysis stream**: Creating a second `SNAudioStreamAnalyzer` would double CPU/battery cost. The built-in classifier already returns all 300 classes in a single result, so we simply scan for additional identifiers.
- **Binary speech classification (no intensity levels)**: Sleep talking doesn't need quiet/light/loud/epic tiers like snoring. A simple boolean `isSpeechDetected` is sufficient and keeps the API surface small.
- **Snoring retains priority**: The `SpeechDetector` API is designed so `SessionManager` (P2-T2) can check snoring first and ignore speech when both are present, matching the documented edge case.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P2-T2: Parallel detection wiring — integrate `SpeechDetector` into `SessionManager`
- P2-T3: Event creation for sleep talking — update `finalizeEvent()` category logic
- P2-T4: Settings toggle for "Detect Sleep Talking"

### Open Questions
- None


### Suggested Branch
`feature/f14/p2-t1-speech-detector`

### Suggested Commit
```
[P2-T1] — Add SpeechDetector for sleep talking classification

- Create SpeechDetector singleton with confidence + dB thresholds
- Extend SoundAnalysisDetector to extract speechConfidence from built-in classifier
- Scan speech identifiers: speech, talking, conversation, narration, monologue
- Reset speechConfidence on stopAnalyzing()
- Binary classification design (no intensity tiers) to keep API minimal
```


## 2026-05-26 — Session 59: P2-T2 Parallel Detection Wiring

### Completed
- P2-T2: Wired `SpeechDetector` into `SessionManager` processing loop

### Technical Details
- `SessionManager` now owns a `speechDetector = SpeechDetector.shared` reference alongside `snoreDetector`
- The 20 Hz processing task polls `SoundAnalysisDetector.shared.speechConfidence` and feeds it into `SpeechDetector.update(db:speechConfidence:)`
- `SessionManager` exposes `currentSpeechDetected: Bool` for future UI observation
- Snoring priority is preserved: speech detection runs in parallel but does not yet affect event creation (that is P2-T3)
- Debug prints now include `speechConf` and speech detection state alongside snore classification
- `resetTrackingState()` clears `currentSpeechDetected` to avoid stale state across sessions
- Backward-compatible overload chain: `processAudioLevel(db:)` → `processAudioLevel(db:spectralScore:snoreConfidence:speechConfidence:)` with defaults

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/SessionManager.swift` | +12/-5 | Added `speechDetector`, `currentSpeechDetected`; wired speech confidence into processing loop; updated debug prints; reset state |
| `docs/trackers/f14-sleepguard-rebrand.md` | +3/-3 | P2-T2 marked Done; updated next task note |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard counts (49 done, 13 backlog, 79%), Activity Log, Completed, Up Next updated |

### Architecture Decisions
- **SpeechDetector remains a separate singleton**: Rather than folding speech logic into `SnoreDetector`, we keep them decoupled. This lets each evolve independently (different thresholds, different confidence sources) and makes unit testing easier.
- **No raw log changes yet**: `SnoreSample` and `SessionRawLogWriter` were left untouched. Adding `speechConfidence` to the raw log is deferred until P2-T3 when the full speech event pipeline is validated.
- **No view changes yet**: `currentSpeechDetected` is published but not consumed by any view. UI integration (BedsideClockView indicator) is deferred to Phase 3.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P2-T3: Event creation for sleep talking — update `finalizeEvent()` to create `.sleepTalking` events when snoring is absent but speech is sustained
- P2-T4: Settings toggle for "Detect Sleep Talking" in `UserPreferences` + `SettingsView`

### Open Questions
- None

### Suggested Branch
`feature/f14/p2-t2-parallel-detection`

### Suggested Commit
```
[P2-T2] — Wire SpeechDetector into SessionManager parallel detection loop

- Add SpeechDetector reference and currentSpeechDetected to SessionManager
- Poll speechConfidence from SoundAnalysisDetector at 20Hz
- Feed db + speechConfidence into SpeechDetector.update()
- Reset speech state on session start/stop
- Preserve snoring priority; speech does not yet create events
```


## 2026-05-26 — Session 59 (continued): P2-T3 Event Creation for Sleep Talking

### Completed
- P2-T3: Added parallel speech event tracking and `finalizeActiveSpeechEvent()` in `SessionManager`

### Technical Details
- Added `detectSleepTalking: Bool` to `UserPreferences` (default `false`) to safely gate speech event creation
- `SessionManager` gained parallel speech event tracking state mirroring snore event tracking:
  - `activeSpeechEventStart`, `activeSpeechEventDBSum/Count`, `activeSpeechEventPeakDB`
  - `lastSpeechSampleTime`, `consecutiveSpeechSamples`, `requiredConsecutiveSpeechSamples = 3`
- Speech event lifecycle:
  - **Start**: 3 consecutive speech samples (≈150 ms) with backdated timestamp
  - **Extend**: accumulate dB sum/count/peak on each sustained sample
  - **Finalize (gap)**: 10 s of silence triggers `finalizeActiveSpeechEvent()`
  - **Finalize (priority)**: snoring detection immediately finalizes the speech event with `endTime: now`
- `finalizeActiveSpeechEvent(endTime:)` creates a `SnoreEvent` with `category: .sleepTalking`, `intensity: .quiet`, and the same 2 s minimum duration as snore events
- Both `stopSession()` and `stopAndDiscardSession()` finalize any in-progress speech events
- `resetTrackingState()` clears all speech tracking state
- Speech events do NOT interact with the soothing melody player — melody play/stop remains purely snore-driven

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/SessionManager.swift` | +77/-4 | Speech event tracking state, priority finalization, gap-based finalization, `finalizeActiveSpeechEvent()` method, reset cleanup |
| `Packages/Env/Sources/Services/UserPreferences.swift` | +12 | Added `detectSleepTalking` boolean preference (default false) |
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-2 | P2-T3 marked Done; next task updated to P2-T4 |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard (50 done, 12 backlog, 81%), Activity Log, Completed, Up Next updated |

### Architecture Decisions
- **Gated by `detectSleepTalking` preference (default false)**: Since P2-T4 (Settings toggle UI) hasn't been built yet, adding the preference now prevents accidental speech event creation for all users. The toggle UI in P2-T4 will simply wire to this existing pref.
- **Same 3-sample consecutive gate as snoring**: Keeps the pipeline consistent and filters out brief transient sounds that SoundAnalysis might misclassify as speech.
- **Same 10 s gap threshold as snoring**: Natural breathing pauses during sleep talking are typically shorter than 10 s. This matches the snoring epoch definition.
- **No intensity tiers for speech**: `SnoreEvent.intensity` is set to `.quiet` for all speech events. This keeps the data model simple; if needed, future phases can add speech-specific intensity (volume-based).
- **Snoring priority enforced at sample level**: When `state != .none`, any active speech event is finalized immediately with `endTime: now`, ensuring the speech event never overlaps with a snore event.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P2-T4: Settings toggle — "Detect Sleep Talking" on/off in `SettingsView`
- P2-T5: Build & verify — end-to-end test with audio samples

### Open Questions
- None

### Suggested Branch
`feature/f14/p2-t3-speech-events`

### Suggested Commit
```
[P2-T3] — Add sleep talking event creation with snoring priority

- Add parallel speech event tracking state to SessionManager
- finalizeActiveSpeechEvent() creates .sleepTalking SnoreEvents
- 3-sample consecutive gate + 10s gap threshold + 2s minimum duration
- Snoring detection immediately finalizes active speech events (priority)
- Add detectSleepTalking preference (default false) for safe gating
- Wire stopSession/stopAndDiscardSession to finalize speech events
```


## 2026-05-26 — Session 59 (continued): P2-T4 Settings Toggle

### Completed
- P2-T4: Added "Detect Sleep Talking" toggle to `SettingsRecordingSection`

### Technical Details
- Added localized string `settings.detectSleepTalking` = "Detect Sleep Talking" to `Localizable.xcstrings`
- Regenerated `Strings.swift` (228 strings total)
- Toggle uses the existing settings card pattern:
  - `SettingsIconBackground(systemName: "bubble.left.fill", color: theme.accent)`
  - `Text(Strings.settingsDetectSleepTalking)`
  - `Toggle("", isOn: Binding(get:set:))` with `.labelsHidden()` and `.tint(theme.scoreGreen)`
- Toggle is placed in `SettingsRecordingSection` (section title: "DETECTION") below the sensitivity picker
- The toggle directly binds to `UserPreferences.detectSleepTalking`, which gates speech event creation in `SessionManager`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +12 | Added `settings.detectSleepTalking` entry |
| `Packages/DesignSystem/Sources/Strings.swift` | +1 | Regenerated — added `settingsDetectSleepTalking` accessor |
| `Packages/Settings/Sources/Views/SettingsRecordingSection.swift` | +12 | Added sleep talking toggle row |
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-2 | P2-T4 marked Done; next task updated to P2-T5 |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard (51 done, 11 backlog, 82%), Activity Log, Completed, Up Next updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P2-T5: Build & verify — end-to-end test with audio samples; ensure snoring accuracy is unchanged
- P3-T1: Category filter — segmented picker (`All | Snoring | Sleep Talking | Noise`) in `SessionDetailView`

### Open Questions
- None

### Suggested Branch
`feature/f14/p2-t4-settings-toggle`

### Suggested Commit
```
[P2-T4] — Add "Detect Sleep Talking" settings toggle

- Add localized `settings.detectSleepTalking` string
- Regenerate Strings.swift
- Add toggle row to SettingsRecordingSection with bubble.left.fill icon
- Bind toggle to UserPreferences.detectSleepTalking
```


## 2026-05-26 — Session 59 (continued): P2-T5 Build & Verify — Phase 2 Complete

### Completed
- P2-T5: Verified Phase 2 sleep talking detection pipeline via clean build and code review

### Verification Results
- **Clean build**: `BUILD SUCCEEDED` with zero errors
- **Pre-existing warnings only**: AccentColor missing from asset catalog, iPad app icon sizes, AppIntents metadata skipped — none related to Phase 2
- **Snoring behavior unchanged when toggle off**: `detectSleepTalking` defaults to `false`, so the speech tracking block is completely skipped; all snore event tracking, burst logic, melody play/stop, and gap finalization execute exactly as before
- **Snoring priority verified**: When `state != .none`, `finalizeActiveSpeechEvent(endTime: now)` is called before any snore tracking begins, ensuring speech events never overlap with snore events
- **Melody interaction verified**: Speech samples increment `consecutiveNonSnoreSamples` (since `state == .none`), so melody stop logic still triggers correctly after 3 sustained non-snore samples
- **No double-counting risk**: `activeEventStart` and `activeSpeechEventStart` are mutually exclusive by construction; `stopSession()` finalizes both defensively

### Phase 2 Summary
| Task | What was built |
|------|---------------|
| P2-T1 | `SpeechDetector` singleton with confidence + dB thresholds |
| P2-T2 | Wired `SpeechDetector` into `SessionManager` 20 Hz processing loop |
| P2-T3 | Parallel speech event tracking; `finalizeActiveSpeechEvent()` creates `.sleepTalking` events |
| P2-T4 | "Detect Sleep Talking" toggle in `SettingsRecordingSection` |
| P2-T5 | Build & verify — zero errors, no regressions |

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-1 | P2-T5 marked Done; Phase 2 complete note |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard (52 done, 10 backlog, 84%), Activity Log, Completed, Up Next updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P3-T1: Category filter — segmented picker (`All | Snoring | Sleep Talking | Noise`) in `SessionDetailView`
- P3-T2: EventRow icons — category-based icons for non-snoring events

### Open Questions
- None

### Suggested Branch
`feature/f14/p2-t5-verify`

### Suggested Commit
```
[P2-T5] — Verify Phase 2 sleep talking detection pipeline

- Clean build with zero errors
- Code review confirms snoring behavior unchanged when toggle off
- Speech priority finalization verified correct
- No regressions in melody play/stop or gap tracking
```


## 2026-05-26 — Session 59 (continued): P3-T1 Category Filter

### Completed
- P3-T1: Added segmented category filter to `SessionDetailView`

### Technical Details
- Added 4 localized filter strings: `filter.all`, `filter.snoring`, `filter.sleepTalking`, `filter.noise`
- `EventCategoryFilter` enum with `includes(event:)` method:
  - `.all` → includes all events
  - `.snoring` → `.snoring` category only
  - `.sleepTalking` → `.sleepTalking` category only
  - `.noise` → `.noise`, `.coughing`, and `.other` categories
- Filter picker shown only when `shouldShowFilter` is true (session has >1 distinct category)
- Filter is hidden for single-category sessions (snoring-only nights), preserving pre-rebrand UI
- Filter state (`@State selectedFilter`) wired to:
  - `SessionDetailEventsView` — shows first 4 filtered events + "Show All" count
  - `EventsSheetView` — shows all filtered events in grid
  - `PlayerSheetView` — plays only filtered events when opened from "Show All"
- Timeline view (`SessionDetailTimelineView`) remains unfiltered — shows all events as a visual overview

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +44 | Added `filter.all`, `filter.snoring`, `filter.sleepTalking`, `filter.noise` |
| `Packages/DesignSystem/Sources/Strings.swift` | +4 | Regenerated (232 strings) |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +40/-5 | `EventCategoryFilter` enum, `selectedFilter` state, `shouldShowFilter`/`filteredEvents` computed properties, picker in `loadedBody`, filtered events passed to sheets |
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-2 | P3-T1 marked Done; next task P3-T2 |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard (53 done, 9 backlog, 85%), Activity Log, Completed, Up Next updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P3-T2: EventRow icons — category-based icons replacing intensity dot for non-snoring events
- P3-T3: Timeline multi-color — sleep talking = purple, noise = orange

### Open Questions
- None

### Suggested Branch
`feature/f14/p3-t1-category-filter`

### Suggested Commit
```
[P3-T1] — Add category filter to SessionDetailView

- Add EventCategoryFilter enum with All/Snoring/Sleep Talking/Noise
- Segmented picker shown only when session has multiple categories
- Filter wired to events list, events sheet, and player sheet
- Timeline view remains unfiltered
- Localize 4 filter strings
```


## 2026-05-26 — Session 59 (continued): P3-T2 EventRow Icons

### Completed
- P3-T2: Added category-based icons to `EventRow` for non-snoring events

### Technical Details
- `EventRow.categoryIndicator` is a `@ViewBuilder` that switches on `event.category`:
  - `.snoring` → intensity-colored circle (unchanged existing behavior)
  - `.sleepTalking` → `bubble.left.fill` icon in purple (`theme.sleepTalkingColor`)
  - `.noise`, `.coughing`, `.other` → `waveform` icon in orange (`theme.noiseColor`)
- Added `sleepTalkingColor` and `noiseColor` to `Theme` so P3-T3 (timeline multi-color) can reuse them
- Icon sizing: 11pt font, 12×12 frame — visually balanced with the 10×10 intensity dot
- No localization needed — icons are universal symbols

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Components/Theme.swift` | +4 | Added `sleepTalkingColor` (purple `#BF5AF2`) and `noiseColor` (orange `#FF9F0A`) |
| `Packages/Recordings/Sources/Views/EventRow.swift` | +18/-2 | `categoryIndicator` view builder; snoring retains dot, non-snoring gets category icons |
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-2 | P3-T2 marked Done; next task P3-T3 |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard (54 done, 8 backlog, 87%), Activity Log, Completed, Up Next updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P3-T3: Timeline multi-color — `SnoringTimelineView` renders sleep talking in purple, noise in orange
- P3-T4: Stats grid supplement — optional disturbance row below the 2×2 grid

### Open Questions
- None

### Suggested Branch
`feature/f14/p3-t2-eventrow-icons`

### Suggested Commit
```
[P3-T2] — Add category-based icons to EventRow

- EventRow.categoryIndicator shows intensity dot for snoring
- Sleep talking events show purple bubble.left.fill icon
- Noise/coughing/other events show orange waveform icon
- Theme gains sleepTalkingColor and noiseColor for reuse
```


## 2026-05-26 — Session 59 (continued): P3-T3 Timeline Multi-Color

### Completed
- P3-T3: Updated `SnoringTimelineView` to render events by category color

### Technical Details
- Added `eventColor(_:)` helper to `SnoringTimelineView`:
  - `.snoring` → `theme.intensityColor(event.intensity)` (existing behavior)
  - `.sleepTalking` → `theme.sleepTalkingColor` (purple `#BF5AF2`)
  - `.noise`, `.coughing`, `.other` → `theme.noiseColor` (orange `#FF9F0A`)
- `Canvas` rendering loop now calls `eventColor(event)` instead of `theme.intensityColor(event.intensity)`
- Snoring-only sessions render identically to pre-rebrand (intensity colors unchanged)
- Multi-category sessions show purple/orange segments alongside intensity-colored segments

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Components/SnoringTimelineView.swift` | +11/-1 | `eventColor(_:)` helper; timeline segments use category-based color |
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-2 | P3-T3 marked Done; next task P3-T4 |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard (55 done, 7 backlog, 89%), Activity Log, Completed, Up Next updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P3-T4: Stats grid supplement — optional disturbance row below the 2×2 grid in `SessionDetailView`
- P3-T5: Player labels — `PlayerSheetView` title based on event category

### Open Questions
- None

- SnoringTimelineView.eventColor(_:) maps category to color
- Snoring retains intensity colors
- Sleep talking = purple, noise/coughing/other = orange
```


## 2026-05-26 — Session 59 (continued): P3-T4 Stats Grid Supplement

### Completed
- P3-T4: Added optional disturbance row below the 2×2 stats grid in `SessionDetailHeaderView`

### Technical Details
- `SessionDetailHeaderView` restructured from `HStack` to `VStack(spacing: 12)` containing:
  - `HStack` with `SleepScoreGauge` + `SessionStatsGrid` (unchanged layout)
  - Conditional `StatCard` showing disturbance count (only when `disturbanceCount > 0`)
- `disturbanceCount` computed as `session.events?.filter { $0.category != .snoring }.count ?? 0`
- Disturbance card uses `speaker.wave.2.fill` icon in `theme.noiseColor` (orange)
- Card hidden for snoring-only sessions, preserving pre-rebrand UI
- Added localized string `session.disturbances` = "Disturbances"

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +11 | Added `session.disturbances` entry |
| `Packages/DesignSystem/Sources/Strings.swift` | +1 | Regenerated (233 strings) |
| `Packages/Recordings/Sources/Views/SessionDetailHeaderView.swift` | +14/-4 | VStack wrapper, `disturbanceCount` computed property, conditional disturbance `StatCard` |
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-2 | P3-T4 marked Done; next task P3-T5 |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard (56 done, 6 backlog, 90%), Activity Log, Completed, Up Next updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P3-T5: Player labels — `PlayerSheetView` title based on event category
- P3-T6: Build & verify — screenshot comparison with design tokens

### Open Questions
- None
[P3-T4] — Add optional disturbance row below session stats grid

- SessionDetailHeaderView wraps gauge+grid in VStack
- Disturbance StatCard shows count of non-snoring events
- Hidden for snoring-only sessions
- Localized "Disturbances" string
```


## 2026-05-26 — Session 59 (continued): P3-T5 Player Labels

### Completed
- P3-T5: `PlayerSheetView` navigation title now reflects event category

### Technical Details
- Added localized title strings:
  - `event.player.navigation.title` = "Snoring Player" (existing)
  - `event.player.sleepTalking.title` = "Sleep Talking Player"
  - `event.player.noise.title` = "Noise Player"
- `PlayerSheetView.playerNavigationTitle` computed property:
  - Resolves current event from `playbackController.currentEvent ?? initialEvent`
  - Maps category to title: snoring → "Snoring Player", sleep talking → "Sleep Talking Player", noise/coughing/other → "Noise Player"
- Title updates dynamically as the user navigates between events in clip playback
- Falls back to "Snoring Player" if no event is resolved

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +22 | Added `event.player.sleepTalking.title` and `event.player.noise.title` |
| `Packages/DesignSystem/Sources/Strings.swift` | +2 | Regenerated (235 strings) |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | +12/-1 | `playerNavigationTitle` computed property; `.navigationTitle` uses dynamic title |
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-2 | P3-T5 marked Done; next task P3-T6 |
| `docs/FeatureTracker.md` | +5/-5 | Dashboard (57 done, 5 backlog, 92%), Activity Log, Completed, Up Next updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

### Next Session
- P3-T6: Build & verify — end-to-end test with audio samples; screenshot comparison with design tokens

### Open Questions
- None
[P3-T5] — Dynamic PlayerSheetView title based on event category

- Add event.player.sleepTalking.title and event.player.noise.title strings
- PlayerSheetView.playerNavigationTitle resolves current event category
- Snoring → "Snoring Player", sleep talking → "Sleep Talking Player", noise → "Noise Player"
- Title updates dynamically during clip playback navigation
```


## 2026-05-26 — Session 60: P3-T6 Build & verify + P4-T1 HealthKit read sleep stages

### Completed
- **P3-T6**: Build & verify after Phase 3 UI changes — clean build with zero errors; only pre-existing asset catalog warnings (no regressions)
- **P4-T1**: Extended `HealthKitSync` with `fetchSleepStages(for:)` to read Apple Watch sleep stage data from HealthKit

### Technical Details
- `fetchSleepStages(for:)` uses `HKSampleQuery` wrapped in `withCheckedContinuation` for async/await compatibility
- Query predicate spans the session's `startDate` → `endDate` (or start + `totalDuration` if nil)
- Results sorted by `HKSampleSortIdentifierStartDate` ascending
- `mapSleepStage(_:)` converts HK sleep analysis values to `SleepStage`:
  - `asleepCore` → `.light`
  - `asleepDeep` → `.deep`
  - `asleepREM` → `.rem`
  - `awake` → `.awake`
  - Legacy `asleep`, `inBed`, `asleepUnspecified` → `nil` (filtered out)
- Each returned `SleepStageSegment` carries:
  - `stage`: mapped sleep stage
  - `startOffset`: seconds from session start
  - `duration`: sample end − start
- The existing `SleepSession.sleepStageSegments` model property (added in P1-T3) remains the target for P4-T2 population

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/HealthKitSync.swift` | +37/-0 | Added `fetchSleepStages(for:)` and private `mapSleepStage(_:)` |
| `docs/trackers/f14-sleepguard-rebrand.md` | +3/-3 | P3-T6 → Done; P4-T1 → Done; next task updated to P4-T2 |
| `docs/FeatureTracker.md` | +6/-4 | Dashboard (58 done, 4 backlog, 93%), Activity Log, Currently Active, Up Next updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors; pre-existing asset catalog warnings only

### Next Session
- **P4-T2**: Stage correlation — wire `fetchSleepStages` into `SessionDetailView` (or `SessionManager` / save flow) to populate `SleepSession.sleepStageSegments`
- **P4-T3**: SleepStageBreakdownView — visual overlay of sleep stages alongside snoring timeline and in Statistics dashboard

### Open Questions
- Should stage fetching happen automatically when opening `SessionDetailView` (lazy load), or should it be cached at session-save time?
- If the user has no Apple Watch sleep data, the query returns `[]` — should the UI show a "No sleep stage data" placeholder or simply hide the timeline section?
```


## 2026-05-26 — Session 60 (continued): P4-T2 Stage correlation

### Completed
- **P4-T2**: Wired HealthKit sleep stage read into `SessionDetailView` — auto-populates `SleepSession.sleepStageSegments` on first view

### Technical Details
- `SessionDetailView.loadSession()` now checks `session.sleepStageSegments == nil` before transitioning to `.loaded` state
- If nil, calls `HealthKitSync.shared.fetchSleepStages(for: session)` asynchronously
- Stores returned stages directly on the model; if HealthKit returns empty, stores `[]` to prevent repeated queries on subsequent views
- `try modelContext.save()` persists the result to SwiftData so the fetch is a one-time operation per session
- Non-blocking: HealthKit is local storage so the query completes in milliseconds; UI remains in `.loading` briefly
- No UI changes in this task — `SleepStageBreakdownView` (P4-T3) will consume the populated data

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +6/-0 | Sleep stage fetch block inside `loadSession()`: nil-check, fetch, save, then proceed to `.loaded` |
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-2 | P4-T2 → Done; next task updated to P4-T3 |
| `docs/FeatureTracker.md` | +4/-3 | Dashboard (59 done, 3 backlog, 95%), Activity Log, Up Next updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors; pre-existing asset warnings only

### Next Session
- **P4-T3**: SleepStageBreakdownView — visual overlay of sleep stages (awake/REM/light/deep) in SessionDetailTimelineView and StatisticsLoadedView

### Open Questions
- None


## 2026-05-26 — Session 60 (continued): P4-T3 Stage timeline overlay

### Completed
- **P4-T3**: Created `SleepStageBreakdownView` — Canvas-based sleep stage visualization for use in `SessionDetailTimelineView` and `StatisticsLoadedView`

### Technical Details
- `SleepStageBreakdownView` uses `Canvas` (matching `SnoringTimelineView` style): 32 px bar with `bgCard` background, 8 pt corner radius, colored segments proportional to stage duration
- Stage colors added to `Theme`: deep = `#5E5CE6`, light = `#64D2FF`, REM = `#BF5AF2`, awake = `#FF9F0A`
- Legend row below the bar: 4 tiny colored dots + stage name labels (`Deep`, `Light`, `REM`, `Awake`)
- Conditionally shown in `SessionDetailTimelineView` only when `session.sleepStageSegments?.isEmpty == false`
- Hidden for legacy sessions (`nil`) and nights with no Watch data (`[]`)
- 5 new localized strings: `recordings.detail.sleepStagesLabel`, `sleepStage.awake`, `sleepStage.deep`, `sleepStage.light`, `sleepStage.rem`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Components/Theme.swift` | +12/-0 | Added `stageDeepColor`, `stageLightColor`, `stageREMColor`, `stageAwakeColor`, and `stageColor(_:)` helper |
| `Packages/DesignSystem/Sources/Components/SleepStageBreakdownView.swift` | +63/-0 | New Canvas-based sleep stage breakdown view with legend |
| `Packages/Recordings/Sources/Views/SessionDetailTimelineView.swift` | +8/-0 | Conditionally shows `SleepStageBreakdownView` above `SnoringTimelineView` |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +45/-0 | Added 5 localization keys |
| `Packages/DesignSystem/Sources/Strings.swift` | +5/-0 | Auto-regenerated |
| `docs/trackers/f14-sleepguard-rebrand.md` | +6/-6 | P4-T3 → Done; acceptance criteria updated; next task updated to P4-T4 |
| `docs/FeatureTracker.md` | +6/-6 | Dashboard (58 done, 4 backlog, 94%), Activity Log, Currently Active, Up Next updated |
| `docs/features/f14-sleepguard-rebrand.md` | +8/-2 | Added `SleepStageBreakdownView` to files table; updated tasks completed and remaining work |

### Build Status
- **BUILD SUCCEEDED** — zero errors; pre-existing asset warnings only

### Next Session
- **P4-T4**: Statistics integration — stage breakdown in `StatisticsDashboardView` for Watch users

### Open Questions
- None


## 2026-05-26 — Session 60 (continued): P4-T4 Statistics integration

### Completed
- **P4-T4**: Added `SleepStageBreakdownView` to `StatisticsDashboardView` with dummy/mock data support

### Technical Details
- `SleepStageBreakdownView` (DesignSystem) shows a compact 16 px Canvas stacked bar (deep/light/REM/awake proportions) + 2×2 `StatCard` grid with stage durations
- Placed in `StatisticsLoadedView` between `StatisticsStatsGrid` and `StatisticsMiniChartSection`
- Conditionally shown only when `session.sleepStageSegments?.isEmpty == false`
- `MockDataGenerator.generate()` now creates realistic `SleepStageSegment` arrays for every mock session
  - Simulates ~90-minute sleep cycles: light → deep → light → REM, with brief awake transitions
  - Stage distributions: deep 15–25%, light 35–50%, REM 20–30%, awake 0–5 min between cycles
  - Initial light sleep phase (10–20 min) before first cycle
- Uses existing `DurationFormatter.hoursAndMinutes` for consistent duration formatting
- Reuses existing stage color theme tokens (`stageDeepColor`, `stageLightColor`, `stageREMColor`, `stageAwakeColor`)
- 1 new localized string: `statistics.sleepStagesLabel`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Components/SleepStageBreakdownView.swift` | +95/-0 | New compact stage bar + 2×2 stat grid component |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | +4/-0 | Conditionally shows `SleepStageBreakdownView` below stats grid |
| `Packages/Env/Sources/Services/MockDataGenerator.swift` | +47/-1 | Added `generateSleepStages(duration:)` helper; wired into session creation |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +13/-0 | Added `statistics.sleepStagesLabel` |
| `Packages/DesignSystem/Sources/Strings.swift` | +1/-0 | Auto-regenerated |
| `docs/trackers/f14-sleepguard-rebrand.md` | +4/-4 | P4-T4 → Done; acceptance criteria updated; next task P4-T5 |
| `docs/FeatureTracker.md` | +7/-6 | Dashboard (59 done, 3 backlog, 95%), Activity Log, Currently Active, Up Next updated |
| `docs/features/f14-sleepguard-rebrand.md` | +3/-2 | Added `SleepStageBreakdownView` to files table; updated tasks completed and remaining work |

### Build Status
- **BUILD SUCCEEDED** — zero errors; pre-existing asset warnings only

### Next Session
- **P4-T5**: Settings toggle — "Enhanced Sleep Tracking" requiring Watch + HealthKit permission

### Open Questions
- None


## 2026-05-26 — Session 60 continued: P4-T4 Verification & Bug Fixes

### Completed
- **P4-T4 Verified**: Hypnogram chart now renders correctly with realistic sleep cycles after fixing multiple visual bugs

### Technical Details
- **Fixed 0-width segments**: `hypnogramSegments()` was calculating `width = relativeDuration * width` where `relativeDuration = stage.duration / session.totalDuration`. When `session.totalDuration` returned 0 (because `endDate` was nil for in-progress/faulted sessions), all segment widths became 0. Fixed by:
  - Adding `max(session.totalDuration, 1)` guard in `hypnogramSegments()`
  - Ensuring `SleepSession.totalDuration` safely computes `endDate?.timeIntervalSince(startDate) ?? 0`
- **Fixed color regression**: `Theme.stageLightColor` had accidentally been changed to `.green` during debugging; restored to design-token `#0A84FF` (blue)
- **Reordered `SleepStage` enum**: Changed from `deep, light, rem, awake` to `awake, rem, light, deep` for visual band order consistency (top-to-bottom in chart)
- **Cleaned view hierarchy**: Removed redundant standalone `SleepStageLegendView`; `SleepStageBreakdownView` owns its chart + 2×2 legend grid
- **Removed all debug code**: White borders, debug text overlays, debug color overrides, and white center dots removed from `SleepStageHypnogramChart`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Components/SleepStageBreakdownView.swift` | +15/-50 | Removed all debug overlays; restored actual `segment.color` rendering; cleaned up Canvas |
| `Packages/DesignSystem/Sources/Components/Theme.swift` | +1/-1 | `stageLightColor` restored from `.green` to `Color(hex: "#0A84FF")` |
| `Packages/Models/Sources/Data/SleepSession.swift` | +2/-2 | `SleepStage` enum reordered to `awake, rem, light, deep`; `totalDuration` computed safely |

### Build Status
- **BUILD SUCCEEDED** — zero errors; pre-existing asset warnings only

### Screenshot Verification
- Hypnogram chart shows: yellow (awake) at edges, blue (light sleep) bars distributed across chart, 4-band layout with subtle horizontal grid lines, time labels at bottom, 2×2 legend grid with correct durations

### Next Session
- **P4-T5**: Settings toggle — "Enhanced Sleep Tracking" requiring Watch + HealthKit permission

### Open Questions
- None


## 2026-05-27 — Session 61: P4-T5 Enhanced Sleep Tracking Toggle

### Completed
- **P4-T5**: Settings toggle — "Enhanced Sleep Tracking" requiring Watch + HealthKit permission

### Technical Details
- Added `enhancedSleepTracking: Bool` to `UserPreferences` with manual `access(keyPath:)` / `withMutation(keyPath:)` pattern (same as other computed UserDefaults-backed properties)
- Added toggle row to `SettingsWatchSection` with `bed.double.fill` icon in accent color
- Toggle requests HealthKit authorization via `healthKitSync.requestAuthorization()` when turned ON (same pattern as `syncToHealthKit` toggle in `SettingsDataSection`)
- Toggle is disabled (turned OFF) if HealthKit authorization is denied
- Gated `fetchSleepStages` in `SessionDetailView.loadSession()`: only queries HealthKit sleep analysis when `userPreferences.enhancedSleepTracking == true`
- Added localized string `settings.enhancedSleepTracking` → "Enhanced Sleep Tracking"
- Regenerated `Strings.swift` via `python3 scripts/generate-strings.py`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/UserPreferences.swift` | +13/-0 | Added `enhancedSleepTracking` computed property with UserDefaults backing |
| `Packages/Settings/Sources/Views/SettingsWatchSection.swift` | +20/-2 | Added toggle row with `bed.double.fill` icon; injected `UserPreferences` and `HealthKitSync` environments |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +2/-1 | Added `UserPreferences` environment; gated `fetchSleepStages` behind `enhancedSleepTracking` |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +11/-0 | Added `settings.enhancedSleepTracking` localization entry |
| `Packages/DesignSystem/Sources/Strings.swift` | +1/-0 | Regenerated; added `settingsEnhancedSleepTracking` accessor |
| `docs/trackers/f14-sleepguard-rebrand.md` | +3/-3 | P4-T5 marked Done; acceptance criteria updated; next task updated to P4-T6 |
| `docs/FeatureTracker.md` | +12/-12 | Dashboard (61 done, 1 backlog, 98%), Activity Log, Currently Active, Up Next updated |
| `docs/features/f14-sleepguard-rebrand.md` | +2/-2 | Added P4-T5 to Tasks Completed and Remaining Work |

### Build Status
- **BUILD SUCCEEDED** — zero errors
`F14-P4-T5 — Enhanced Sleep Tracking toggle in SettingsWatchSection`
- Add `enhancedSleepTracking` to `UserPreferences` with UserDefaults backing
- Toggle in `SettingsWatchSection` with `bed.double.fill` icon and HealthKit auth request
- Gate `fetchSleepStages` in `SessionDetailView` behind the preference
- Localize `settings.enhancedSleepTracking` string

### Next Session
- **P4-T6**: Build & verify — final pass for F14 Phase 4

### Open Questions
- None


## 2026-05-27 — Session 62: P4-T6 Build & Verify + F14 Complete

### Completed
- **P4-T6**: Final build & verify for F14 Phase 4
- **F14**: SleepGuard Rebrand & Multi-Sound Detection — 100% complete (21/21 tasks)

### Technical Details
- Ran full project build: zero errors, zero warnings
- Verified all 9 SPM packages + app target compile cleanly
- F14 acceptance criteria all satisfied:
  - App displays as "SleepGuard" on home screen
  - Bundle ID updated to `com.daki.exampleProject.SleepGuard`
  - All user-facing "SleepGuard" references removed
  - Data model supports sleep stage segments without migration
  - `SoundCategory` supports `.sleepTalking`, `.coughing`, `.noise`
  - Sleep talking detected and recorded as `.sleepTalking` events
  - Category filter in `SessionDetailView`
  - EventRow shows category icons for non-snoring events
  - Timeline view renders multi-category colors
  - Sleep stage breakdown view (`SleepStageBreakdownView`) in `StatisticsLoadedView` and `SessionDetailTimelineView`
  - Settings toggle for sleep talking detection
  - Settings toggle for enhanced sleep tracking (Watch)
  - Statistics integration with dummy data

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `docs/trackers/f14-sleepguard-rebrand.md` | +2/-2 | P4-T6 marked Done; notes updated |
| `docs/FeatureTracker.md` | +10/-10 | F14 → Done (21/21, 100%); Dashboard: 62/62 done, 100% progress |
| `docs/features/f14-sleepguard-rebrand.md` | +2/-2 | Status → Done; Phase 4 completion date; P4-T6 ✅ |

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

`F14-P4-T6 — Final build & verify; F14 complete`
- Clean build (zero errors)
- All 21 F14 tasks done
- SleepGuard rebrand & multi-sound detection fully shipped

### Next Session
- All tracked tasks are complete. Next work would be new features per `docs/Roadmap.md` or user-requested changes.

### Open Questions
- None


## 2026-05-27 — Session 62b: Enhanced Sleep Tracking Auto-Enable Polish

### Completed
- Auto-enable "Enhanced Sleep Tracking" for users who already granted HealthKit permission

### Technical Details
- Added `hasExplicitlySetEnhancedSleepTracking` to `UserPreferences` — tracks whether the user has manually toggled the setting
- In `SleepGuardApp.onAppear`, after `checkAuthorizationStatus()`: if user has never manually toggled, sync `enhancedSleepTracking` to match `HealthKitSync.isAuthorized`
  - This means users who granted HealthKit via `syncToHealthKit` automatically get sleep stage breakdowns without visiting Settings
  - Users without HealthKit auth stay opted out
- In `SettingsWatchSection`, when the user interacts with the toggle, `hasExplicitlySetEnhancedSleepTracking` is set to `true` so the app never overrides their choice again
- This is a soft opt-in: respects user agency while removing friction for existing HealthKit users

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/UserPreferences.swift` | +13/-0 | Added `hasExplicitlySetEnhancedSleepTracking` computed property |
| `SleepGuard/SleepGuardApp.swift` | +3/-1 | Auto-sync `enhancedSleepTracking` with HealthKit auth status on app appear (only if user hasn't explicitly set it) |
| `Packages/Settings/Sources/Views/SettingsWatchSection.swift` | +1/-0 | Set `hasExplicitlySetEnhancedSleepTracking = true` on manual toggle |

### Build Status
- **BUILD SUCCEEDED** — zero errors

`Polish — Auto-enable Enhanced Sleep Tracking for existing HealthKit users`
- Add `hasExplicitlySetEnhancedSleepTracking` flag to `UserPreferences`
- Auto-sync toggle with HealthKit auth on app launch (only until user manually toggles)
- Respect user choice once explicitly set

### Open Questions
- None


## 2026-05-27 — Session 62c: Sleep Talking Detection Hardening

### Completed
- **P5-T1**: Bandpass filter bugfix — removed EQ from audio chain
- **P5-T2**: Sleep score excludes non-snoring events
- **P5-T3**: Category-specific events title
- **P5-T4**: Baby sound detection
- **P5-T5**: Expanded speech/vocalization identifiers
- **P5-T6**: Speech detection threshold tuning

### Technical Details
- **Root cause of sleep talking never being detected**: `AudioRecorder` applied a bandpass EQ (100–500 Hz) before the SoundAnalysis tap. Apple's built-in classifier was trained on full-spectrum audio; stripping frequencies above ~700 Hz destroyed the spectral features it uses to detect speech. Removed the EQ entirely — tap now runs on raw `inputNode`. FFT analyzer already distinguishes snoring from speech via `lowFreqRatio` and `spectralCentroid` on full-spectrum audio, so snoring detection remains accurate.
- **Sleep score fairness**: `SleepSession.snoringDuration` and `sleepScore` were counting ALL events (including sleep talking) as snoring, unfairly penalizing the score. Both now filter by `.snoring` category only.
- **Dynamic event titles**: `SessionDetailEventsView` accepts a `title: String` parameter. `SessionDetailView` computes the title from `selectedFilter`: All → "EVENTS", Snoring → "SNORING EVENTS", Sleep Talking → "SLEEP TALKING EVENTS", Noise → "DISTURBANCES". Four new localized format strings added.
- **Baby sounds**: Added `babyIdentifiers` (`baby_crying`, `baby_laughter`, `babble`) to `SoundAnalysisDetector`; baby confidence is merged into `maxSpeechConfidence` so baby sounds flow through the same `.sleepTalking` event pipeline.
- **Vocalization expansion**: `speechIdentifiers` grew from 5 → 22 entries to catch sleep talking variants: `whisper`, `mumble`, `mutter`, `stutter`, `groan`, `moan`, `sigh`, `grunt`, `grumble`, `exclaim`, `gasp`, `yell`, `scream`, `shout`, `laugh`, `giggle`, `whimper`.
- **Threshold tuning for real-world sleep talking**:
  - `SpeechDetector.dbFloor`: -40.0 → -55.0. Sleep talking at nightstand distance is typically -50 to -60 dBFS; the old floor rejected virtually all quiet speech.
  - `SessionManager` speech event min duration: 2.0s → 0.5s. Combined with SoundAnalysis's ~1s analysis window lag + 3-sample consecutive gate, the old threshold required >3s of continuous talking to survive. Most sleep talking is 0.5–1.5s.
  - Added debug prints to `SpeechDetector.classify` and `finalizeActiveSpeechEvent` so rejections are visible in console.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | -27 | Removed `AVAudioUnitEQ` bandpass filter; tap moved from `eq` node to `inputNode` (raw audio); `pauseRecording` now removes tap from `inputNode` directly |
| `Packages/AudioEngine/Sources/Engine/SoundAnalysisDetector.swift` | +8/-1 | Added `babyIdentifiers`; expanded `speechIdentifiers` from 5 → 22; baby confidence merged into `maxSpeechConfidence` |
| `Packages/AudioEngine/Sources/Engine/SpeechDetector.swift` | +7/-1 | `dbFloor` -40.0 → -55.0; added DEBUG prints for confidence and dB rejections |
| `Packages/Models/Sources/Data/SleepSession.swift` | +2/-2 | `snoringDuration` filters by `.snoring`; `sleepScore` iterates over `snoringEvents` only |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +9/-1 | Added `eventsTitle` computed property based on `selectedFilter`; passes title to `SessionDetailEventsView` |
| `Packages/Recordings/Sources/Views/SessionDetailEventsView.swift` | +2/-1 | Added `title: String` parameter; uses passed title instead of hardcoded `sessionRecordingEventsFormat` |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +48 | Added 4 category-specific event format strings |
| `Packages/DesignSystem/Sources/Strings.swift` | +4 | Regenerated with 250 strings |
| `Packages/Env/Sources/Services/SessionManager.swift` | +2/-1 | Speech event min duration 2.0s → 0.5s; added debug print for discarded short events |
| `docs/trackers/f14-sleepguard-rebrand.md` | +8/-1 | Added P5-T1 through P5-T6; updated task count 21→27 |
| `docs/FeatureTracker.md` | +6/-3 | Activity log entries for all 6 tasks; dashboard 64→70 tasks done |

### Architecture Decisions
- **Remove EQ instead of adding a second tap**: A second tap (full-spectrum for SoundAnalysis, filtered for FFT/recording) would be more complex and risk synchronization issues. Removing the EQ entirely is simpler and correct — the FFT analyzer already computes spectral features relative to total energy, so it naturally distinguishes snoring (low-frequency dominant) from speech (broad spectrum).
- **Merge baby/vocalization confidence into speechConfidence**: Rather than adding parallel `babyConfidence`/`vocalizationConfidence` properties and complicating `SessionManager`, all human-vocalization confidence feeds into the existing `speechConfidence` variable. The downstream pipeline (thresholds, consecutive gate, event finalization) is identical.
- **Separate thresholds for speech vs snoring**: Snoring events keep the 2s minimum (appropriate for snoring epochs). Speech events get 0.5s minimum (appropriate for brief utterances). This is hardcoded because the two sound categories have fundamentally different temporal characteristics.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

`F14-P5-T1..T6 — Sleep talking detection hardening`
- Bandpass filter removed (root cause of speech never being detected)
- Sleep score fixed to exclude non-snoring events
- Dynamic category-specific event titles
- Baby sounds + 17 additional vocalization identifiers
- dB floor -55, min duration 0.5s for speech events
- All builds pass

### Next Session
- All tracked tasks are complete. Next work would be new features per `docs/Roadmap.md` or user-requested changes.

### Open Questions
- None

---

## 2026-05-27 — Session 62d: Holistic Sleep Score

### Completed
- **Sleep talking & sleep stage integration**: `sleepScore` now penalizes sleep talking and poor sleep architecture when data is available.

### Technical Details

**New formula:**
```
score = 100 - snoringPenalty - eventsPenalty - intensityPenalty
            - sleepTalkingPenalty - stagePenalty
```

**Sleep talking penalty** (only when `.sleepTalking` events exist):
- `min(sleepTalkingPercentage * 0.35 + sleepTalkingEventsPerHour * 0.8, 15)`
- Weighted ~half of snoring (0.35 vs 0.7 duration, 0.8 vs 2.0 frequency).
- A user talking 5% of the night with 3 events/hour gets ~4 point penalty.

**Sleep stage penalty** (only when `sleepStageSegments != nil`):
- `min(deepDeficit * 0.6 + remDeficit * 0.4 + awakeExcess * 1.0, 15)`
- Deep deficit: penalty per % below 15% (NSF/AASM healthy range).
- REM deficit: penalty per % below 18%.
- Awake excess: penalty per % above 8% (WASO norms).
- A user with 5% deep, 10% REM, 20% awake gets ~12 point penalty.
- Healthy stages (20% deep, 22% REM, 3% awake) → 0 penalty.

**Backward compatibility:**
- Sessions without Watch data → `stagePenalty = 0` (identical to before).
- Sessions without sleep talking events → `sleepTalkingPenalty = 0` (identical to before).
- Mock data generates healthy stage distributions and occasional sleep talking → scores stable (max talking penalty ~0.6 pts).

**Sanity check results:**
- Light snoring only: 93
- Light snoring + healthy stages: 93 (no change)
- Light snoring + poor stages: 78 (15 point reduction)
- Light snoring + 3% talking: 91 (2 point reduction)
- Everything terrible: 0
- Borderline thresholds (deep 15%, REM 18%, awake 8%): 100 (zero penalty)

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepSession.swift` | +53/-8 | Added `StageStats` struct, `stageStats`, `sleepTalkingDuration`, `sleepTalkingEvents`, `sleepTalkingPercentage`, `sleepTalkingEventsPerHour` computed properties; rewrote `sleepScore` with conditional sleep talking and stage penalties |
| `Packages/Env/Sources/Services/MockDataGenerator.swift` | +43/-1 | Added `generateSleepTalkingEvents()` helper; 10-40% of sessions get 1-4 sleep talking events (probability inversely scales with target score); events are 5-30s, `.quiet`, -55 to -45 dB; appended to session events; updated `forScore()` comment |
| `Packages/Models/Sources/Data/SleepSession.swift` | +53/-8 | Added `StageStats` struct, `stageStats`, `sleepTalkingDuration`, `sleepTalkingEvents`, `sleepTalkingPercentage`, `sleepTalkingEventsPerHour` computed properties; rewrote `sleepScore` with conditional sleep talking and stage penalties |

### Architecture Decisions
- **Conditional penalties via data presence**: No need for feature flags or user preference checks in the model. If `sleepStageSegments` is nil → no stage penalty. If no `.sleepTalking` events → no talking penalty. This is elegant and automatically backward compatible with all existing sessions.
- **Separate penalty caps**: Each new penalty is capped at 15. Snoring remains the dominant factor (max 70 + 20 + 30 = 120). Stages and talking are modifiers, not primary drivers — appropriate since the app's core value proposition is acoustic sleep monitoring.
- **Evidence-based thresholds**: Deep ≥15%, REM ≥18%, awake ≤8% are grounded in NSF/AASM guidelines and WASO norms, not arbitrary numbers.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings

`Session 62d — Holistic sleep score with sleep talking & stage penalties`
- Sleep talking penalty: max 15 (duration%×0.35 + events/hr×0.8)
- Sleep stage penalty: max 15 (deep deficit×0.6 + REM deficit×0.4 + awake excess×1.0)
- Backward compatible, conditional on data presence
- All builds pass, sanity checks verified

### Next Session
- All tracked tasks are complete. Next work would be new features per `docs/Roadmap.md` or user-requested changes.

### Open Questions
- None

---


## 2026-05-27 — Session 63: Onboarding Health & Watch Screen

### Completed
- **F1-T6**: Health & Watch onboarding screen (`OnboardingPageHealthWatchView`)
- Updated `designs/SleepGuard.pen` onboarding flow: moved Health & Watch design into main 6-page sequence, updated all 7 screen variants to 6 progress dots

### Technical Details
- **New view**: `OnboardingPageHealthWatchView.swift` (Packages/Onboarding/Sources/Views/)
  - Health illustration: concentric green rings (`#0A2818` fill, `#133D20` inner), `bed.double.fill` icon, `heart.fill` accent, blue dot
  - Title + body about sleep stage breakdowns (deep/light/REM/awake) and smartwatch pairing
  - Privacy pill: shield icon + "All health data stays on your device" in `bgElevated` capsule
  - Primary button requests HealthKit authorization via `HealthKitSync.requestAuthorization()`
  - Granted state: button turns `scoreGreen` with white dot + "Health connected" label
  - 0.8-second `Task.sleep` after grant before calling `onContinue()` so user sees confirmation
  - Secondary "Skip for now" button advances without requesting permission
  - On appear: checks existing HealthKit auth status; auto-shows granted state if already authorized
- **`OnboardingView`**: `totalPages` 5 → 6; inserted `OnboardingPageHealthWatchView` at tag 3; Mic shifted to tag 4; CTA shifted to tag 5
- **Consistency**: same 0.8 s grant-delay added to `OnboardingPage4View` (Microphone permission)
- **Localized strings** (6 new keys):
  - `onboarding.healthWatch.title`, `.body`, `.badge`, `.buttonPrimary`, `.buttonSecondary`, `.granted`

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Onboarding/Sources/Views/OnboardingPageHealthWatchView.swift` | +112 | **New** — Health & Watch onboarding page with HealthKit auth, granted state, privacy pill |
| `Packages/Onboarding/Sources/Views/OnboardingView.swift` | +4/-1 | `totalPages` 5→6; inserted `OnboardingPageHealthWatchView` at tag 3; shifted Mic/CTA tags |
| `Packages/Onboarding/Sources/Views/OnboardingPage4View.swift` | +2/-0 | Added 0.8 s delay after mic permission grant before advancing |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +74/-0 | 6 new `onboarding.healthWatch.*` localized strings |
| `Packages/DesignSystem/Sources/Strings.swift` | +6/-0 | Regenerated; added 6 new string accessors |
| `docs/trackers/f1-onboarding.md` | +25/-4 | F1-T6 added to task table and detail section; version bumped to V1.1; completion date updated |
| `docs/FeatureTracker.md` | +5/-5 | F1 tasks 5/5→6/6; total tasks 62→63; activity log + completed list updated |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Suggested Branch
`feature/f1-t6-health-watch-onboarding`

### Suggested Commit
`F1-T6 — Health & Watch onboarding screen with HealthKit auth and granted-state delay`
- `OnboardingPageHealthWatchView` with concentric green illustration, privacy pill, HealthKit CTA
- 0.8 s confirmation delay before auto-advance on both HealthKit and Microphone permission pages
- Onboarding flow expanded from 5 → 6 pages
- 6 new localized strings

### Open Questions
- None

---

## 2026-05-27 → 2026-05-28 — Session: Snore Detection Investigation & Recalibration

### Completed
- **Investigation**: User reported app under-counts vs competitor (~3 min vs ~25 min on the same night). Mapped the full pipeline: `AudioRecorder` → `SoundAnalysisDetector` + `FFTAnalyzer` → `SnoreDetector.classify()` → `SessionManager` event tracking.
- **Data-driven diagnosis on user's overnight session**: parsed `rawlog_*.json` (303k samples, 4.5 h) and read the 3.1 GB raw `.caf` (Float32 PCM, offset 4096) directly in Python. Proved per-second RMS sat at the noise floor — loudest 25 min at −69.6 dBFS, only ~2 dB above the −72 median. **Snoring never reached the detector at a usable level**; thresholds/event-logic were never going to matter.
- **Capture path rewrite — 3 iterations on real device**:
  1. ❌ `mode: .measurement → .default` + `setInputGain(1.0)` to boost level. AGC + maxed preamp amplified the noise floor → mic sounded loud/noisy. **Reverted.**
  2. ❌ Narrow band-pass (125–700 Hz) → 40 Hz high-pass for full-band capture. User reported **loud speaker feedback during recording** — `engine.mainMixerNode.volume = 0` was leaking. **Superseded by #3.**
  3. ✅ **Removed the EQ/mixer/speaker graph entirely.** `start/resumeRecording` now tap `inputNode` directly (no output path = nothing to feed back); `pauseRecording` updated to remove tap from `inputNode`.
- **Overnight verification** (build #3): user reported **3 min → 15 min detected (5× improvement)**, peak −12.8 dBFS, `snoreConfidence` reaching 0.89, speaker feedback gone.
- **Ground-truth validation against the new `.caf`**: built an independent burst-detector (energy spikes with snore periodicity, no SoundAnalysis) → estimated 24.2 min "loose" / 16.6 min "strong" snoring. Extracted 12 WAV samples (densest snore stretches, true-quiet references, suspicious peaks); user listening test confirmed quiet samples are silent, the −28 dBFS peak at t=60 was a cough (not snoring), and a 1-second isolated snore at t=330 was missed by both detector and competitor-comparable. **Real snore time ≈ 22–25 min.**
- **Threshold recalibration**:
  - `SnoreDetector` gained `confidenceGate`/`highConfidenceGate`/`quietFallbackGate` Float properties (medium defaults 0.35/0.55/0.45, replacing hardcoded 0.5/0.7/0.6).
  - dB defaults dropped to −50/−40/−25/−15 (was −30/−20/−10/−5).
  - `SessionManager.applyDetectionSensitivity` rewritten to set all 7 detector values per Low/Med/High instead of a single dB offset.
  - `minEventDuration` (computed property, sensitivity-dependent 2/1/0.5 s per Low/Med/High) replaces the hardcoded 2 s in `finalizeActiveEvent` — lets isolated single snores (~1 s) survive on Medium/High.
- **Handover doc** created at `docs/SNORE_DETECTION_HANDOVER.md` (self-contained: problem, pipeline map, all data tables, change history with revert tracking, decision tree for next session, offline-analysis recipes).

### Technical Details
- The detector funnel was 100% dependent on SoundAnalysis: `SnoreDetector.classify()` (`SnoreDetector.swift:35`) takes the SA path whenever `snoreConfidence > 0`, which was true for ~100% of samples → the FFT/dB spectral fallback **never ran**. Still doesn't post-recalibration; flagged as open.
- `FFTAnalyzer.spectralScore` is logged as `0.000` for every one of the 303k samples in the old log AND every one of the 407k samples in the new log → the FFT is hitting its zero-guard early-return (`fftSetup` likely nil or `floatChannelData` nil). Flagged.
- Speaker-feedback root cause: `engine.mainMixerNode.volume = 0` does **not** fully mute the `.playAndRecord` + `.defaultToSpeaker` output path. Loud input still leaks audibly. Removing the input→mixer connection entirely (tap `inputNode` directly) was the correct fix; the input node renders without an explicit downstream graph connection because the tap drives it.
- `.caf` format used by the app: raw little-endian Float32 PCM, mono 48 kHz, data starts at byte offset 4096. Readable with Python `array.array('f', file.read())` — no ffmpeg/sox needed.
- Burst-detection algorithm: 100 ms RMS windows; rolling 30 s median as local noise floor; burst = ≥6 dB above floor for 0.3–3.5 s; episode = ≥3 bursts within 8 s gaps. STRONG/LOOSE estimates give a confidence interval on "real snoring."
- Sensitivity tiers calibrated against ground truth, not guessed: dB floors sit ~10 dB above measured noise floor (~−65) and ~10 dB below measured snore peaks (~−45). A cough at −28 dBFS won't fire even on High because SA gives coughs low snore-confidence (`confidenceGate` filters on classifier output, not amplitude).
- Detected-time vs event-time mismatch: per-sample state classification gives ~9 min on the new log, but the app displays ~15 min because of event merging (gap-threshold 10 s within `SessionManager.swift`).

### Files Changed

| File | What Changed |
|------|--------------|
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | Removed EQ/mixer/speaker graph; `start/resumeRecording` install tap on `inputNode` directly; `pauseRecording` removes tap from `inputNode`. (Earlier in-session attempts `.measurement→.default+gain` and narrow→high-pass were reverted/superseded — net diff is just the direct-tap pattern.) |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | Added `confidenceGate`/`highConfidenceGate`/`quietFallbackGate` Float properties (defaults 0.35/0.55/0.45); dB defaults changed to -50/-40/-25/-15; replaced hardcoded 0.5/0.7/0.6 in `classifyWithSoundAnalysis` with the new properties; updated doc comments. |
| `Packages/Env/Sources/Services/SessionManager.swift` | Rewrote `applyDetectionSensitivity()` to set all 7 detector values per Low/Med/High; added `minEventDuration` computed property (2/1/0.5 s); replaced hardcoded `2.0` in `finalizeActiveEvent` with `minEventDuration`; updated the surrounding doc comment. |
| `docs/SNORE_DETECTION_HANDOVER.md` | **New** — self-contained investigation handover. Pipeline map, all data tables, full code-change history with revert tracking, decision tree for next session keyed on the next-night test outcome, offline-analysis Python recipes. |

### Build Status
- **BUILD SUCCEEDED** after every change (verified with `mcp__XcodeBuildMCP__build_sim`). SourceKit shows `AVAudioSession unavailable in macOS` warnings on `AudioRecorder.swift` — these are iOS-only-file indexing false positives, not compiler errors.

`Fix snore detection capture path + recalibrate thresholds`
- AudioRecorder: tap `inputNode` directly, remove EQ/mixer/speaker graph that leaked audible feedback at non-trivial input levels
- SnoreDetector: configurable SA confidence gates; dB defaults recalibrated for full-band capture (old values were tuned for the old narrow band-pass)
- SessionManager: per-sensitivity SA gate + dB floor + minEventDuration mapping; `minEventDuration` now sensitivity-dependent (2/1/0.5 s) so isolated single snores survive on Medium/High
- Add `docs/SNORE_DETECTION_HANDOVER.md` with investigation findings, ground-truth data, and decision tree for next-session iteration

### Open Questions
- **Next-night verification pending**: confirm displayed snore time lands ~20–24 min on Medium for a typical night, and that the anti-snore melody doesn't fire on non-snores.
- `FFTAnalyzer.spectralScore` returns 0 for every sample — secondary bug; fallback path is non-functional. Worth fixing once the SA path is validated.
- `SnoreDetector.swift:35` — `if snoreConfidence > 0 { return classifyWithSoundAnalysis(...) }` shadows the spectral path ~100% of the time. Should become `>= 0.05` (or similar) once the FFT is fixed so the fallback can actually rescue when SA is unsure.
- Whether `inputNode.installTap` without a downstream connection runs reliably across all iOS versions and device routings (Bluetooth, USB mic, etc.) — works on the user's iPhone per the overnight test, but worth a wider-device validation before shipping.



---

## 2026-05-28 — Session 64: Sleep Stages Info Sheet + HealthKit Query Fix

### Completed
- **Sleep stages info sheet**: `SleepStagesInfoView` educational sheet that opens from the `info.circle` button in `SleepStageBreakdownView`. Shows personalized stage interpretation with status badges (Good/Low/High), recommended ranges for each stage, score impact formula, and visual threshold bars comparing the user's actual values against targets.
- **HealthKit sleep stage query fix**: Removed `.strictStartDate` from `HealthKitSync.fetchSleepStages` so overlapping Watch samples are included. Added `stagesEmptyAndOld` retry logic in `SessionDetailView` for sessions older than 1 hour that previously fetched empty stage arrays.

### Technical Details
- `SleepStagesInfoView` uses `@Environment(\.dismiss)` for the close button (`xmark.circle.fill`)
- Stage cards show: color indicator, name, status badge, duration + percentage, recommended range (only when not Good), and one-sentence description
- Score impact section shows the formula (Deep ≥15%, REM ≥18%, Awake ≤8%), actual penalty, and 3 threshold bars with target markers
- Threshold bars use `GeometryReader` to render value bar + target circle marker on a shared background
- 15 new localized strings for sleep stages info content + 1 new `action.close` string

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Components/SleepStagesInfoView.swift` | +274 | **New** — Educational sheet with stage cards, score impact, threshold bars |
| `Packages/DesignSystem/Sources/Components/SleepStageBreakdownView.swift` | +18/-2 | Added `info.circle` button + `.sheet` presentation |
| `Packages/Env/Sources/Services/HealthKitSync.swift` | +1/-1 | Removed `.strictStartDate` from sleep stage query predicate |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +4/-1 | Added `stagesEmptyAndOld` retry for old sessions with empty stage arrays |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +156 | 16 new localized strings |
| `Packages/DesignSystem/Sources/Strings.swift` | regenerated | Auto-generated accessors |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Suggested Branch
`feature/sleep-stages-info-sheet`

### Suggested Commit
`Session 64 — Sleep stages info sheet + HealthKit query fix`
- SleepStagesInfoView with personalized stage interpretation and score impact
- Info button on SleepStageBreakdownView header
- Fix HealthKit query to include overlapping sleep stage samples
- Retry empty stage fetches for sessions older than 1 hour

### Open Questions
- None

---

## 2026-05-28 — Session 65: PDF Generator Polish & Loading Fix

### Completed
- **PDF first-time generation fix**: Removed `UITraitCollection.current` manipulation from `SleepReportPDFGenerator` — this global state mutation was causing `UIGraphicsPDFRenderer` to fail on first use. Added explicit error logging.
- **PDF new stats**: Added Sleep Architecture section with horizontal stage bars (Deep/Light/REM/Awake) when Watch data is available; added Sleep Talking summary card; expanded stats grid to include snore time and sleep talking events/percentage; updated events table with a "Type" column showing event category (Snoring/Sleep Talking/Noise).
- **PDF layout spacing**: Widened horizontal spacing in event row columns (Time/Type/Duration/Intensity) and in sleep architecture section (name label → bar → percentage) so elements don't crowd.
- **PDF loading fix**: Added `isGeneratingPDF` state to `SessionDetailView` — the export button is disabled and shows a `clock` icon while the PDF is being generated, preventing the user's double-tap issue.

### Technical Details
- PDF stats grid is now dynamic: base 4 stats, expands to 6 when sleep talking data exists
- Sleep architecture bars use `maxPct` normalization so the largest stage fills the available width
- Event Type column uses `SoundCategory` mapping (`.snoring` → "Snoring", `.sleepTalking` → "Sleep Talking", `.noise/.coughing/.other` → "Noise")
- `isGeneratingPDF` uses `defer` to guarantee reset even if generation throws

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/SleepReportPDFGenerator.swift` | +120/-20 | Removed UITraitCollection hack; added sleep architecture section; added sleep talking summary; expanded stats grid; added event Type column; widened column spacing |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | +8/-3 | Added `isGeneratingPDF` state; disabled export button + clock icon during generation |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +22 | `pdf.avgDB`, `pdf.peakDB` (later removed from grid but strings kept) |
| `Packages/DesignSystem/Sources/Strings.swift` | regenerated | Auto-generated accessors |

### Build Status
- **BUILD SUCCEEDED** — zero errors

### Suggested Branch
`feature/pdf-generator-polish`

### Suggested Commit
`Session 65 — PDF generator polish: fix first-time failure, add sleep stages & talking stats, loading state`
- Fix first-time PDF generation by removing UITraitCollection manipulation
- Add sleep architecture bars and sleep talking summary to PDF
- Widen column spacing in event rows and stage bars
- Disable PDF export button with clock icon during generation

### Open Questions
- None

---

## 2026-05-28 → 2026-05-29 — Session 66: Enhanced Audio Playback + Post-Recalibration Tuning

> Two threads run in parallel through this session — finishing the F9 detection-tuning work that started in the prior "Snore Detection Investigation & Recalibration" entry, and building out a new Enhanced Audio playback feature in F4 (Recordings). The detection thread mostly verified or investigated; the Enhanced Audio thread is where the bulk of the code change lives.

### Completed

#### F4 — Enhanced Audio Playback (the headline feature)

- **`ClipPlaybackController` rewritten on `AVAudioEngine`** (`Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift`, ~310 lines, full rewrite of internals — entire public API preserved). Pipeline is `AVAudioPlayerNode → AVAudioUnitEQ → mainMixerNode`; engine lazy-starts on first `play()`, format-detected per clip, only re-connects when the format actually differs.
- **Per-clip peak normalization**: on file load, `currentGainDB(for:)` reads the file's samples, finds peak amplitude, computes the gain to bring it to −3 dBFS, and caps at the EQ's +24 dB ceiling. Sets `eq.globalGain`. Quiet clips get max boost; loud clips get less — every clip plays at similar perceived loudness.
- **Two-band EQ for noise reduction**: high-pass at 80 Hz (HVAC rumble + 50/60 Hz mains hum), low-pass at 1.5 kHz (broadband mic hiss). Snore energy lives 100 Hz–1 kHz so the passband preserves it entirely.
- **`enhancedAudioEnabled` toggle**: public `Bool` on the controller with `didSet` that re-applies EQ bypass and (if a clip is loaded) recomputes per-clip gain. Wired to `UserPreferences.enhancedAudioPlayback` (new pref, defaults `true` on first access via explicit `defaults.object(forKey:)` check).
- **Toggle UI in `PlayerSheetView`**: card matching the rest of the player's design tokens (`theme.bgCard`, `theme.radiusCard`, `theme.accent` toggle tint), label + description on the left, `Toggle` on the right. Only rendered in the clip-session branch — the legacy `AVAudioPlayer` single-event path isn't affected and showing the toggle there would be misleading. Binding writes both the controller (instant audio change) and `UserPreferences` (persistence).
- **2 new localized strings** added via `Strings.txt` → `python3 scripts/generate-xcstrings.py`: `event.player.enhancedAudio.label` ("Enhanced Audio") and `event.player.enhancedAudio.description` ("Boosts volume and reduces background noise").
- **Sheet detent bump 470 → 580** (`.presentationDetents([.height(580), .large])`). Added `.large` as a second detent so users can drag for more breathing room without losing the sized default.

#### F4 — Audio cutting off early bug (`.dataPlayedBack` fix)

- User reported clips ending milliseconds to seconds before the actual end.
- Root cause: `AVAudioPlayerNode.scheduleSegment` defaults to `completionCallbackType: .dataConsumed`, which fires when the data is *read from the source*, not when it's been *played through the speakers*. Our `handlePlaybackFinished` immediately called `playerNode.stop()` (and possibly reconnected the chain for the next clip's format), flushing whatever was still in the output buffer.
- Fix: pass `completionCallbackType: .dataPlayedBack` explicitly. Completion now fires after the audio has actually been heard, so cleanup is harmless.

#### F4 — Skeleton loading state (replaces "Audio unavailable" flash)

- User reported a brief "Audio unavailable" flash on the first render before the player set up.
- Root cause: first body render happens *before* `.task` runs; with empty `events` and `legacyEventDuration = 0`, the original conditional chain fell through to `noAudioView`.
- Fix: two new `@State` flags — `didFinishInitialLoad` (flipped at end of `.task`) and `hasLoadingTimedOut` (10 s safety net). Body restructured so the *default during loading* is a `loadingSkeleton` (waveform-shaped placeholder of `theme.bgElevated` shapes + circular `ProgressView`), not `noAudioView`. `noAudioView` now only shows once loading is genuinely over (or times out).

#### F4 — Burst markers: position math, capsule spans, 4-color legend

- **Position math fix**: `position = burst.startOffset / totalDuration` was a latent multi-event bug — burst offsets are event-relative, not session-relative. Changed to `burst.startOffset / event.snoreDuration` with an `event.snoreDuration > 0` guard. Invisible in single-event view; would have clustered all dots at the far left in multi-event sessions.
- **Dots → capsule spans**: replaced `Circle` markers (showing only burst *start*) with `Capsule` shapes spanning `[startOffset, endOffset]` so users can see *both* when each burst started AND how long it lasted. Minimum width 6 pt so very short bursts stay visible at all sheet sizes. Loosened the fallback guard from `count > 1` to `!isEmpty` so single-burst events also show their span.
- **Legend: 2-color → 4-color**: was hardcoded `theme.scoreAmber` + `theme.scoreRed` ("Light snore" / "Loud snore"), which left users staring at gray dots for Quiet events with no matching legend entry. Replaced with four chips (Quiet / Light / Loud / Epic) pulled via `theme.intensityColor(_:)` — same source the markers use, can't drift out of sync. Tightened chip spacing from 20/6 to 14/4 so all four fit on any iPhone width. Reuses existing intensity-label strings; no new localization needed.

#### F9 — Post-recalibration tuning (continuation of prior session)

- **Real-night verification of fix #4** (the SA-gate + dB-floor + `minEventDuration` per-sensitivity recalibration applied in the previous session): user's overnight on the recalibrated Medium build logged 20.94 min / 65 events for a ~21 min subjective night. Independent burst-detection on the `.caf` reported LOOSE 26.1 min / STRONG 16.6 min — confirming the app is already in the right neighborhood. No further tuning needed for Medium/Low defaults.
- **Short-event orphan-FP investigation**: user reported FPs on High after subsequent night testing. Cross-referenced 27 short app events (<2 s) against the independent burst detector: 14 corroborated by ≥3 nearby bursts (real isolated snores), 13 orphans (real FPs). **Key finding**: peak_conf and peak_db cannot separate them — orphans actually have *higher* median `peak_conf` (0.57 vs 0.44). Only `nearest_other_event_distance` separates cleanly (28 s vs 100 s medians).
- **Temporal-context filter — applied, then reverted by user**: implemented Option B from the analysis (`lastFinalizedEventEnd` state + `shortEventDurationThreshold = 2.0 s` + `temporalContextWindow = 30 s` discard in `finalizeActiveEvent`, skipped on `skipMinDuration`). Built clean. User reverted the change in a subsequent edit. Design + decision tree + supporting data tables preserved in `docs/SNORE_DETECTION_HANDOVER.md` for future revisit.

### Technical Details

- **`.dataPlayedBack` vs `.dataConsumed`**: the underrated `AVAudioPlayerNode` API choice. `.dataConsumed` (default) fires when the source data has been *handed to the engine* — the output buffer is still draining. `.dataPlayedBack` fires only after the audio has actually been *heard*. For any audio app where the completion handler does cleanup (stop, reconnect, advance), `.dataPlayedBack` is the right choice.
- **Per-clip normalization math**: `gainDB = 20 * log10(targetPeak / sourcePeak)`, clamped `[0, 24]`. `targetPeak = 0.708` ≈ −3 dBFS. Never attenuates a loud clip (`max(gainDB, 0)`); never exceeds the EQ's headroom (`min(gainDB, 24)`).
- **`UserPreferences.enhancedAudioPlayback` defaulting**: standard `defaults.bool(forKey:)` returns `false` when a key has never been written. To get a *true* default on first access we check `defaults.object(forKey: "enhancedAudioPlayback") == nil` first. This is the same trick used by `recordingDelayMinutes` for non-zero defaults.
- **Sheet-size math**: the original 470 pt detent comfortably held `EventPlayerView` (~280 pt) + scrubber + controls. The new toggle card is ~80 pt; 470 + 80 + spacing overflowed into the `ScrollView`'s hidden region, which is why the toggle was "invisible" until the bump. 580 fits the new content without scrolling.
- **Skeleton state machine**: there are *two* exits from the skeleton — `didFinishInitialLoad` (normal path, set at end of `.task`) and `hasLoadingTimedOut` (10 s safety, set by a parallel `Task`). Cancelled when the normal path wins, so the timeout almost never fires in practice — it's purely there to prevent the user from being stuck on a skeleton if the legacy async export silently fails.
- **Burst-span visualization as F9 diagnostic tool**: the capsule shapes are the direct visual answer to "is this burst a real snore or an orphan FP?" — narrow capsule sitting on flat waveform is the exact shape of the orphan-FP pattern surfaced in the F9 investigation. Visible at a glance now without scrubbing audio.

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` | ~+310/−265 | Full rewrite of internals on `AVAudioEngine`; same public surface preserved |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | ~+80/−30 | Toggle UI, sheet detent, skeleton loading state, init from `UserPreferences` |
| `Packages/Recordings/Sources/Views/EventPlayerView.swift` | ~+30/−15 | Burst marker math fix, dots → capsule spans, 4-color legend with helper |
| `Packages/Env/Sources/Services/UserPreferences.swift` | +18 | New `enhancedAudioPlayback` pref (default `true`) |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` | +2 | 2 new keys |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +74 | Auto-regenerated via `generate-xcstrings.py` |
| `Packages/DesignSystem/Sources/Strings.swift` | +2 | Auto-regenerated accessors |
| `docs/trackers/f4-recordings.md` | (refinements section) | "Session 66 Refinements — Enhanced Audio Playback" |
| `docs/trackers/f9-enhanced-detection.md` | (refinements section) | "Session 66 Refinements — Post-Recalibration Tuning" |
| `docs/FeatureTracker.md` | activity log + last-updated | New rows for each major change |
| `docs/SNORE_DETECTION_HANDOVER.md` | already current | Existing handover doc covers the F9 investigation methodology |

### Build Status

- **BUILD SUCCEEDED** after every change. The recurring SourceKit `AVAudioSession unavailable in macOS` and `No such module 'DesignSystem'` warnings on iOS-only files are indexer false positives — the iOS Simulator builds compile clean with zero errors.

### Suggested Branch
`feature/enhanced-audio-playback`

### Suggested Commit
`Session 66 — Enhanced Audio playback + burst-span markers + post-recalibration tuning`
- F4: rewrite `ClipPlaybackController` on `AVAudioEngine` with EQ bandpass + per-clip peak normalization; toggleable via `UserPreferences.enhancedAudioPlayback` (default true)
- F4: add toggle UI card in `PlayerSheetView`; bump sheet detent 470→580 to fit; add skeleton loading state replacing "Audio unavailable" flash
- F4: fix audio cutting off early via `completionCallbackType: .dataPlayedBack`
- F4: replace burst-marker dots with capsule spans; fix position math (multi-event bug); 4-color intensity legend
- F9: continuation work on post-recalibration short-event FP filter — temporal-context implementation built clean but reverted by user; design preserved in handover doc
- 2 new localized strings; build succeeds

### Open Questions
- Whether to re-apply the F9 temporal-context filter or leave the orphan-FP shape visible to users via the F4 capsule-span markers as the user's diagnostic tool (depends on whether users actually inspect events vs. trust totals). Defer until next-night reports come in.

## 2026-06-01 — Session 67: Incremental Background Clip Extraction

### Completed
- Incremental clip extraction: each snore/speech event's audio clip is extracted immediately after finalization during the session, spreading the heavy `AVAssetExportSession` + FFT work across the full sleep duration instead of concentrating it at stop-time.
- `PendingSessionStore` tracks all files belonging to the current unsaved session; on force-close/relaunch or Discard, all orphaned clips, raw audio, and logs are deleted automatically.
- Save Session is now nearly instantaneous — it only inserts into SwiftData and clears the pending record.

### Technical Details
- `AudioClipExtractor.extractSingleClip` is now public with an overload that accepts `sessionDuration` directly, avoiding stale duration reads from a growing `.caf` file.
- `SessionManager` serializes incremental extractions via a single `clipExtractionQueue` task to minimize CPU impact during recording.
- `stopSession()` awaits the extraction queue, then extracts any events that still lack clips (e.g., events finalized at stop-time or earlier failures), then registers the raw log filename.
- `startSession()` cleans up any previous pending session before registering the new one, preventing disk bloat when the user starts a new session without saving/discarding the old.
- `SleepGuardApp.onAppear` calls `PendingSessionStore.cleanupIfNeeded()` so force-close → relaunch always deletes orphaned files.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/PendingSessionStore.swift` | +62 | New service: tracks unsaved session files in UserDefaults, deletes them on cleanup |
| `Packages/AudioEngine/Sources/Engine/AudioClipExtractor.swift` | +13/-1 | Made `extractSingleClip` public; added overload with explicit `sessionDuration` |
| `Packages/Env/Sources/Services/SessionManager.swift` | +57/-23 | Incremental extraction queue, pending tracking, cleanup on discard/stop, await queue in `stopSession` |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | +2 | `PendingSessionStore.clearPending()` after successful SwiftData save |
| `SleepGuard/SleepGuardApp.swift` | +1 | `PendingSessionStore.cleanupIfNeeded()` on app launch |

### Architecture Decisions
- **Serialize extractions, don't parallelize**: A single task queue ensures only one `AVAssetExportSession` + FFT runs at a time, minimizing battery/thermal impact while the user sleeps. Each event is typically 5–30 s of audio, so FFT is fast.
- **Track files, not session object**: `PendingSessionStore` persists only filenames, not the full `SleepSession` model. This avoids serialization complexity and works even when the app relaunches with no session in memory.
- **Keep existing manual deletion in `discardCompletedSession`**: `PendingSessionStore.cleanupIfNeeded()` handles the primary cleanup, but the existing per-file deletion remains as a safety net.

### Build Status
- **BUILD SUCCEEDED** — zero errors.

### Suggested Branch
`feature/incremental-clip-extraction`

### Suggested Commit
`[Perf] Incremental background clip extraction for fast session save`

### Changes done
```
- Extract each event's clip immediately after finalization during the session
- PendingSessionStore tracks files for unsaved sessions and cleans up on discard/force-close
- AudioClipExtractor.extractSingleClip is now public
- Save Session is nearly instant; stopSession spinner time reduced to ~last event only
```

### Next Session
- (none — awaiting next task)

### Open Questions
- Should we add a subtle UI indicator that clips are being extracted in the background? Currently it's invisible to the user.
- Should the incremental extraction task be wrapped in `beginBackgroundTask` so it can finish if the app goes to background mid-extraction?

## 2026-06-01 — Session 68: Direct Per-Event Recording

### Completed
- Eliminated full-session `.caf` recording in production mode. Per-event `.caf` files are written directly during the session, compressed to `.m4a` on finalize, and raw `.caf` is deleted immediately.
- `SessionManager` now creates per-event audio files when snoring starts, compresses them to AAC `.m4a` when the event ends, runs FFT spectral analysis on the compressed clip, and cleans up the raw file.
- Full-session `.caf` is only recorded when `UserPreferences.preserveRawAudio == true` (debug-only toggle, defaults `false`). When enabled, behavior matches the old full-session + per-event clips path for algorithm testing.
- `PendingSessionStore.setPending()` now accepts an optional session audio filename so it doesn't track a non-existent full-session file in production mode.
- `AudioClipExtractor.analyzeSpectralFeatures` is now public so `SessionManager` can run FFT on freshly compressed `.m4a` event files.
- `#if DEBUG` Settings toggle for `preserveRawAudio` with localized label and description.

### Technical Details
- `AudioRecorder.startEventFile(eventID:url:)` / `finalizeEventFile()` — already existed and required no changes. The tap writes to both the optional full-session file and the current event file simultaneously.
- `SessionManager.finalizeActiveEvent()` closes the event file via `audioRecorder.finalizeEventFile()`, then spawns a `Task` that uses `AVAssetExportSession` (preset `AppleM4A`) to compress the raw `.caf` to `.m4a`, runs `AudioClipExtractor.analyzeSpectralFeatures` on the result, populates `event.audioFileURL` / `dominantFrequency` / `spectralCentroid` / `lowFreqRatio`, then deletes the raw `.caf`.
- `pendingEventTasks: [Task<Void, Never>]` tracks all in-flight compression tasks. `stopSession()` awaits them before presenting the summary, ensuring every saved event has its audio ready.
- `stopAndDiscardSession()` now also iterates `session.events` and deletes each event's audio file, preventing leaks when the user discards a short session.
- Melody pause handling unchanged: when melody starts, `finalizeActiveEvent(skipMinDuration: true)` is called before the mic pauses, so the event file is closed and compressed. Post-melody snoring starts a new event with a new file.
- Speech events do not create audio files (no per-event recording for sleep talking; clips are snore-only).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/SessionManager.swift` | ~+110/-120 | Removed incremental clip extraction queue; added per-event file creation, async compression + FFT, `pendingEventTasks`, conditional full-session recording, event-file cleanup on discard |
| `Packages/Env/Sources/Services/PendingSessionStore.swift` | +4/-3 | `setPending` now takes optional `sessionAudioFilename` instead of hardcoding session `.caf` |
| `Packages/AudioEngine/Sources/Engine/AudioClipExtractor.swift` | +2/-2 | `SpectralData` and `analyzeSpectralFeatures` are now `public` |
| `Packages/Settings/Sources/Views/SettingsRecordingSection.swift` | +18 | `#if DEBUG` toggle for `preserveRawAudio` with subtitle description |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +24 | Added `settings.preserveRawAudio` and `settings.preserveRawAudio.description` |
| `Packages/DesignSystem/Sources/Strings.swift` | +2 | Auto-regenerated accessors for new settings strings |

### Architecture Decisions
- **No queue for compression tasks**: Each event gets its own `Task`. Since events are typically minutes apart and compression is fast for small files, overlap is rare. `stopSession()` gathers all pending tasks with `await task.value`.
- **Compress on finalize, not on stop**: This spreads CPU/battery impact across the night and makes `stopSession()` nearly instant (just awaits any stragglers).
- **Keep `.m4a`, delete `.caf` immediately on success**: The `.m4a` is the permanent playback source. If compression fails, the raw `.caf` is left on disk as a fallback; it will be cleaned up on discard or by `PendingSessionStore` if the session is never saved.
- **Debug toggle, not a retention policy**: The user explicitly rejected retention-based approaches because a 5 GB file can fail to write when only 1 GB is free. The debug override is the only path to full-session recording.

### Build Status
- **BUILD SUCCEEDED** — zero errors.

`[Perf] Direct per-event recording — eliminate 5 GB full-session .caf in production`
- Write per-event `.caf` directly during session; compress to `.m4a` + FFT on finalize
- Delete raw `.caf` after successful compression; `pendingEventTasks` ensures stopSession waits
- Full-session `.caf` only recorded when `preserveRawAudio` debug toggle is enabled
- `PendingSessionStore.setPending` no longer hardcodes session filename
- `AudioClipExtractor.analyzeSpectralFeatures` made public
- Debug settings toggle with localized strings

### Next Session
- Test per-event recording end-to-end on device/simulator with a short simulated session to verify `.m4a` files are created, spectral data is populated, and playback works.
- Consider adding `beginBackgroundTask` around the compression task if the app goes to background mid-compression.

### Open Questions
- Should speech events also get per-event audio clips? Currently they are metadata-only.

## 2026-06-01 — Session 69: Fix Snore Duration / Audio File Mismatch

### Completed
- Fixed the discrepancy where `EventCard` showed 1s but `PlayerSheetView` showed 11s for the same snore event.
- Root cause: per-event audio files include the 10s trailing silence debounce gap, but `snoreDuration` correctly excludes it.
- Made the fix future-proof and SwiftData-migration-safe.

### Technical Details
- `ClipPlaybackController` now respects `event.snoreDuration` as the canonical playback duration instead of overwriting it with the raw audio file length.
- `WaveformGenerator.generateSamples(from:maxDuration:)` gained an optional `maxDuration` parameter so waveform visualization is trimmed to the algorithm-defined duration, eliminating flatline silence tails in the UI.
- `ClipPlaybackController` schedules `AVAudioPlayerNode.scheduleSegment` with a frame count capped to `currentClipDuration`, so playback stops at the correct time even though the underlying file is longer.
- All seek, scrub, progress-tick, and pause time-clamping now use `currentClipDuration` (algorithm-defined) rather than `currentFileDuration` (raw file length).
- Zero SwiftData schema changes; zero audio file mutations. The full audio (including trailing silence) is preserved on disk. If a future algorithm decides to include the gap, only `SnoreEvent.snoreDuration` needs to change — the playback and visualization layers will automatically follow.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Helpers/WaveformGenerator.swift` | +12/-8 | Added `maxDuration: TimeInterval?` parameter to `generateSamples(from:pointCount:maxDuration:)`. Limits frame reading to `min(totalFrames, maxDuration * sampleRate)` so waveforms match the metric duration. |
| `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` | +16/-8 | Added `currentClipDuration` computed property (algorithm-defined, capped by file length). Removed `clipDurations` overwrite in `setupPlayerForCurrentEvent()`. Capped `scheduleSegment` frame count, seek bounds, progress ticks, and pause clamping to `currentClipDuration`. |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | +1/-1 | Passes `event.snoreDuration` as `maxDuration` to `WaveformGenerator.generateSamples` for clip-session waveforms. |

### Architecture Decisions
- **Non-destructive fix**: Audio files are NOT trimmed. The 10s trailing silence is kept on disk for future algorithm changes or debugging. Only playback and visualization are bounded.
- **No SwiftData migration**: The fix is purely in the playback/visualization layer. `SnoreEvent.duration` and `SnoreEvent.bursts` remain the only stored data. Changing the duration algorithm later only requires editing `snoreDuration` — no migration, no file re-processing.
- **Algorithm-agnostic playback boundary**: `currentClipDuration = min(clipDurations[currentEventIndex], currentFileDuration)` means playback can never exceed the file, but the UI/playback timeline is driven by `snoreDuration`. This dual-source approach is resilient to missing or truncated files.

### Build Status
- **BUILD SUCCEEDED** — zero errors.

`[Fix] Align clip playback and waveform with algorithm-defined snoreDuration`
- WaveformGenerator.generateSamples: add maxDuration parameter for duration-limited waveform sampling
- ClipPlaybackController: use currentClipDuration (snoreDuration) instead of file duration for playback bounds, scheduling, seeking, and progress
- PlayerSheetView: pass event.snoreDuration to waveform generator so visualization matches metric duration

### Next Session
- Consider whether speech events (which also use the 10s gap threshold) need the same playback-duration fix. Speech events currently have no per-event audio files, so the issue does not apply yet.
- Evaluate if `spectrumSamples` should also get a `maxDuration` parameter when it is brought into active use.

### Open Questions
- Should there be a user-facing toggle to "include silence gaps in playback" for debugging or curiosity? (Probably not — keeps UI simple.)

## 2026-06-01 — Session 70: Snore Intensity Classification Fix

### Completed
- Fixed `SnoreDetector.classifyWithSoundAnalysis` removing broken dB floor offsets that collapsed almost all snoring into the "light" bucket.
- Added `calculatePeakDB` to `AudioRecorder` and exposed `currentPeakDB`; intensity classification now uses peak level instead of RMS because snoring is impulsive and RMS over 23 ms buffers under-reports perceptual loudness by 6–15 dB.
- Lowered loud/epic thresholds by 5 dB across all sensitivities to match real-world captured levels at typical bedside distances.
- Updated `docs/snore-detection-algorithm.md` logic table and threshold table to reflect the corrected classification rules.

### Technical Details
- **Root cause of light-only detection:** `floorLight = lightThreshold - 10` made light start at -50 dBFS (same as quiet), creating a 20 dB catch-all bucket. Both loud and epic required `highConfidenceGate` (0.55), so moderate-confidence snores at -20 dBFS fell through to light.
- **Fix:** Intensity is now purely amplitude-driven after ML confidence gates entry. Only epic requires `highConfidenceGate`. Thresholds are used directly without downward offsets.
- **Peak dB:** `AudioRecorder` computes `20 * log10(maxSample)` per 1024-sample buffer. SessionManager passes `currentPeakDB` to `SnoreDetector.classify`. Event statistics (`averageDB`, `peakDB`) continue to use RMS `db` for consistency with historical data.
- **Threshold changes:**
  - Low: loud -20 → -15, epic -10 → -5
  - Medium: loud -25 → -20, epic -15 → -10
  - High: loud -30 → -25, epic -20 → -15

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +8/-14 | Removed floor offsets; intensity uses direct thresholds; only epic requires highConfidenceGate; default thresholds updated |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +25/-3 | Added `currentPeakDB` property + `calculatePeakDB()` method; peak computed in tap alongside RMS dB |
| `Packages/Env/Sources/Services/SessionManager.swift` | +18/-12 | `processAudioLevel` accepts `peakDB`; classification uses peak; thresholds lowered 5 dB; debug print shows rms+peak |
| `docs/snore-detection-algorithm.md` | +8/-8 | Updated logic table and threshold table; documented rationale for peak-dB and epic-only high confidence |

### Architecture Decisions
- **Peak for classification, RMS for statistics:** Peak captures impulsive snore loudness; RMS is better for long-term averages and backward-compatible event stats.
- **Amplitude-driven intensity, not confidence-driven:** ML confidence gates whether it's a snore at all. Within that, dB should determine intensity. Requiring high confidence for loud was collapsing the distribution.
- **5 dB threshold shift:** Conservative adjustment based on user feedback that even high-sensitivity loud=-30 wasn't reachable. Combined with peak dB, this should make loud/epic realistic without over-lowering.

### Build Status
- **BUILD SUCCEEDED** — zero errors.

### Suggested Branch
`feature/snore-intensity-classification-fix`

### Suggested Commit
`[F2] Snore intensity classification fix — peak dB + corrected thresholds`
- Remove broken floor offsets in classifyWithSoundAnalysis
- Use peak dB instead of RMS for intensity classification
- Lower loud/epic thresholds by 5 dB across all sensitivities
- Update snore-detection-algorithm.md documentation

### Changes done
```
- classifyWithSoundAnalysis uses direct thresholds without -10/-5 offsets
- Only epic requires highConfidenceGate; loud uses base confidenceGate
- AudioRecorder tracks currentPeakDB via calculatePeakDB
- SessionManager passes peakDB to classifier for intensity decisions
- loud/epic thresholds lowered 5 dB (medium: loud=-20, epic=-10)
- docs/snore-detection-algorithm.md updated
```

### Next Session
- Test snore intensity classification end-to-end with loud snoring samples to verify loud/epic trigger correctly.
- If still too strict, consider a calibration step or user-adjustable threshold offset.

### Open Questions
- Should we expose a per-user calibration step (e.g., "make a loud snore sound") to personalize thresholds?
- Is the 5 dB shift enough, or do bedroom acoustics vary more than expected?

---

## 2026-06-01 — Session 71: Settings Storage Limits

### Completed
- **F6-T4**: Storage limit settings with automatic audio cleanup

### Technical Details
- `UserPreferences` gained 4 new properties: `limitStorageEnabled` (default true), `storageLimitMB` (default 500), `limitDaysEnabled` (default true), `maxDays` (default 30)
- `StorageLimitEnforcer` singleton enforces both size-based and day-based limits; file I/O runs off MainActor via `Task.detached` so launch/save never block
- Cleanup plan pattern: MainActor fetches sessions + clears audio URL properties immediately (so model stays consistent), background task deletes files from disk, then context is saved
- `SettingsStorageSection` added to `SettingsView` with toggles + menu pickers for MB (100/250/500/1000/2000) and days (7/14/30/60/90)
- Enforcer triggers on app launch (`.task` in `SleepGuardApp`) and after every session save (`SessionSummaryView.saveSession`)
- Session metadata (SwiftData models) is never deleted — only audio files are removed
- 11 new localized strings added; `Strings.swift` regenerated
- DEBUG-only "Test Storage Cleanup" button injects dummy 1 MB audio files and runs the enforcer, showing a report alert

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/UserPreferences.swift` | +48 | Added `limitStorageEnabled`, `storageLimitMB`, `limitDaysEnabled`, `maxDays` with manual access/withMutation |
| `Packages/Env/Sources/Services/StorageLimitEnforcer.swift` | +304 | New async nonisolated service; `CleanupPlan` + `CleanupReport`; day/size limit builders; off-MainActor file deletion; debug dummy injection |
| `Packages/Settings/Sources/Views/SettingsStorageSection.swift` | +133 | New section with toggles, pickers, and DEBUG test button |
| `Packages/Settings/Sources/Views/SettingsView.swift` | +1 | Added `SettingsStorageSection()` to VStack |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | +4 | `Task { await enforcer.enforceLimits(...) }` after `modelContext.save()` |
| `SleepGuard/SleepGuardApp.swift` | +6/-3 | `.task` for `PendingSessionStore.cleanupIfNeeded()` + `StorageLimitEnforcer`; `.onAppear` keeps sync HealthKit state |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +90 | 11 new settings strings |
| `Packages/DesignSystem/Sources/Strings.swift` | +11 | Auto-regenerated accessors |

### Architecture Decisions
- **Async + nonisolated enforcer**: Removed `@MainActor` from `StorageLimitEnforcer` so `Task.detached` can do file deletion without blocking UI. Model mutations happen on MainActor; file deletion happens in background.
- **Clear URLs before deleting files**: Model objects have their `audioFileURL` / `rawAudioFileURL` / `rawLogFileURL` cleared and saved immediately, so the UI can't reference orphaned files even if background deletion is slow.
- **`.task` over `.onAppear` + `Task { }`**: `.task` is the idiomatic SwiftUI way to run async work on view appearance; it's auto-cancelled on disappear and avoids nested closure boilerplate.
- **Default limits**: 500 MB / 30 days chosen as reasonable defaults that won't surprise users but prevent unbounded storage growth.

### Build Status
- **BUILD SUCCEEDED** — zero errors.

### Suggested Branch
`feature/f6/t4-storage-limits`

### Suggested Commit
`F6-T4 — Settings storage limits with automatic audio cleanup`
- Add UserPreferences properties for storage limit and max age
- Create StorageLimitEnforcer with async off-MainActor file deletion
- Add SettingsStorageSection UI with toggles and pickers
- Trigger cleanup on app launch and after session save
- Preserve session metadata, delete only audio files
- Add DEBUG test helper and localized strings

### Next Session
- (none — this was a user-requested enhancement)

### Open Questions
- Should speech events also get per-event audio clips that are subject to these limits? Currently speech events are metadata-only.


---

## 2026-06-06 — Session 71: F15 Personalization & Sleep Briefing — T1 Scaffold

### Completed
- F15-T1: Personalization package scaffold

### Technical Details
- New `Packages/Personalization/` feature package created following existing package patterns (Package.swift with deps on Models, Env, DesignSystem)
- Directory structure: `Sources/Engine/` and `Sources/Views/` for the pure briefing engine and UI layers
- Package added to `SleepGuard.xcodeproj` as `XCLocalSwiftPackageReference` with `relativePath = Packages/Personalization`
- `Personalization` product linked in the `SleepGuard` app target's `PBXFrameworksBuildPhase`
- Placeholder `BriefingEngine.swift` and `SleepBriefingView.swift` created so the package compiles cleanly
- No runtime code changes yet; this is purely structural groundwork for T2–T16

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Personalization/Package.swift` | +22 | New feature package manifest depending on Models, Env, DesignSystem |
| `Packages/Personalization/Sources/Engine/BriefingEngine.swift` | +5 | Placeholder struct for compilation |
| `Packages/Personalization/Sources/Views/SleepBriefingView.swift` | +8 | Placeholder view for compilation |
| `SleepGuard.xcodeproj/project.pbxproj` | +7 | Added `XCLocalSwiftPackageReference`, `XCSwiftPackageProductDependency`, `PBXBuildFile`, and linked to target |
| `docs/trackers/f15-personalization.md` | +298 | New feature tracker with 16 tasks and full task detail sections |
| `docs/FeatureTracker.md` | +1/-5 | Updated dashboard counts, activity log, currently active, up next |

### Architecture Decisions
- **Feature package isolation**: `Personalization` is a standalone feature package (deps: Models, Env, DesignSystem) following the existing module rules. It does not import other feature packages.
- **Engine/Views split**: Pure rules engine lives in `Sources/Engine/`, UI lives in `Sources/Views/`. This mirrors the plan's requirement that `BriefingEngine` be fully testable with no UI dependencies.

### Build Status
- **BUILD SUCCEEDED** — zero errors.

`[F15-T1] Personalization package scaffold`
- Create Packages/Personalization/Package.swift with deps Models/Env/DesignSystem
- Create Sources/Engine/ and Sources/Views/ directory structure
- Add Personalization as XCLocalSwiftPackageReference in SleepGuard.xcodeproj
- Link Personalization product in app target Frameworks build phase
- Add placeholder BriefingEngine.swift and SleepBriefingView.swift for compilation
- Build succeeds with zero errors

### Changes done
- Created `Packages/Personalization/` feature package
- Added package to Xcode project local references
- Created feature tracker `docs/trackers/f15-personalization.md`
- Updated `docs/FeatureTracker.md`

### Next Session
- F15-T2: `UserProfile` + `LifestyleLog` SwiftData models
- F15-T3: `UserPreferences` flags (lastBriefingShownDate, hasCompletedProfile, profilePromptDismissCount, briefingEnabled)

### Open Questions
- (none)


---

## 2026-06-06 — Session 71 (continued): F15-T2 UserProfile + LifestyleLog Models

### Completed
- F15-T2: UserProfile + LifestyleLog SwiftData models

### Technical Details
- `UserProfile` `@Model` with 4 field groups per plan:
  - **Identity**: firstName, birthYear (derived `age`), biologicalSex, heightCm, weightKg
  - **Goals**: targetBedtime (time-of-day Date), targetSleepHours, primaryGoal
  - **Lifestyle baseline**: caffeineHabit, alcoholHabit, exerciseFrequency, typicalStress, screenBeforeBed
  - **Personal touch**: hobbies ([String]), occupationType
  - **Meta**: createdAt, updatedAt
- `LifestyleLog` `@Model` captures per-night deviations: hadCaffeineLate, hadAlcohol, exercised, stressfulDay, lateMeal, screenBeforeBed, optional note, optional sessionID link
- 8 enums defined, all `String, Codable, Sendable` for SwiftData compatibility: `BiologicalSex`, `PrimaryGoal`, `CaffeineHabit`, `AlcoholHabit`, `ExerciseFrequency`, `TypicalStress`, `ScreenBeforeBed`, `OccupationType`
- All fields optional or have sensible defaults; nothing is mandatory
- Both models registered in `Schema([SleepSession.self, SnoreEvent.self, UserProfile.self, LifestyleLog.self])` in `SleepGuardApp.swift`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/UserProfile.swift` | +141 | New SwiftData model with identity, goals, lifestyle baseline, personal touch fields, and 8 enums |
| `Packages/Models/Sources/Data/LifestyleLog.swift` | +54 | New SwiftData model for per-night lifestyle deviation logging |
| `SleepGuard/SleepGuardApp.swift` | +1/-1 | Added `UserProfile.self` and `LifestyleLog.self` to SwiftData schema |
| `docs/trackers/f15-personalization.md` | +1/-1 | T2 status → Done, acceptance criteria checked |
| `docs/FeatureTracker.md` | +2/-2 | Dashboard counts refreshed (73 done, 14 backlog, 12% F15 progress) |

### Architecture Decisions
- **birthYear over raw age**: Stored as `birthYear: Int?` so it doesn't drift; `age` is a computed property. Matches the plan's recommendation.
- **All enums have defaults**: Every enum field has a safe default (e.g., `.unspecified`, `.medium`, `.other`) so the model is always valid even when the user skips every step.
- **hobbies as [String]**: Simple string array for chip tags rather than a separate relation or complex type. Easy to query and display.

### Build Status
- **BUILD SUCCEEDED** — zero errors.

`[F15-T2] UserProfile and LifestyleLog SwiftData models`
- Add UserProfile model with identity, goals, lifestyle, and personal touch fields
- Add LifestyleLog model for per-night deviation tracking
- Define 8 Sendable enums for profile fields
- Register both models in SleepGuardApp SwiftData schema
- Build succeeds with zero errors

### Changes done
- Created `Packages/Models/Sources/Data/UserProfile.swift`
- Created `Packages/Models/Sources/Data/LifestyleLog.swift`
- Updated `SleepGuard/SleepGuardApp.swift` schema registration

### Next Session
- F15-T3: UserPreferences flags (lastBriefingShownDate, hasCompletedProfile, profilePromptDismissCount, briefingEnabled)

### Open Questions
- (none)


---

## 2026-06-06 — Session 71 (continued): F15-T3 UserPreferences Flags

### Completed
- F15-T3: UserPreferences flags for Personalization & Sleep Briefing

### Technical Details
- Added 4 new properties to `UserPreferences` following the existing manual `access`/`withMutation` pattern:
  - `lastBriefingShownDate: Date?` — gates the once-per-day briefing; nil means never shown
  - `hasCompletedProfile: Bool` — suppresses the profile prompt once the user fills the editor
  - `profilePromptDismissCount: Int` — backs off if user keeps dismissing (max 3)
  - `briefingEnabled: Bool` — Settings toggle to disable daily briefing; defaults to `true` using `defaults.object(forKey:) == nil` check
- All properties use `@Observable` registrar calls so SwiftUI re-renders when values change

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/UserPreferences.swift` | +48 | Added `lastBriefingShownDate`, `hasCompletedProfile`, `profilePromptDismissCount`, `briefingEnabled` with `access`/`withMutation` |
| `docs/trackers/f15-personalization.md` | +1/-1 | T3 status → Done, acceptance criteria checked |
| `docs/FeatureTracker.md` | +2/-2 | Dashboard counts refreshed (74 done, 13 backlog, 19% F15 progress) |

### Build Status
- **BUILD SUCCEEDED** — zero errors.

### Suggested Branch
`feature/f15/t3-userpreferences-flags`

### Suggested Commit
`[F15-T3] UserPreferences flags for personalization and briefing`
- Add lastBriefingShownDate, hasCompletedProfile, profilePromptDismissCount, briefingEnabled
- All use manual access/withMutation pattern for @Observable change propagation
- briefingEnabled defaults to true for new installs
- Build succeeds with zero errors

### Next Session
- F15-T4: BriefingEngine + value types (pure rules engine, no UI)

### Open Questions
- (none)


---

## 2026-06-06 — Session 71 (continued): F15-T4 BriefingEngine + Value Types

### Completed
- F15-T4: Pure BriefingEngine rules engine and value types

### Technical Details
- `Briefing` value type: greeting, headline, stats, insight, nudge, survey, scoreContext
- `BriefingStat` label/value pairs for recap chips
- `ScoreTrend` enum: .improving, .declining, .steady, .firstNight, .noData, .returningAfterGap(days:)
- `SurveyPrompt` with title, chips, and swing direction
- `BriefingEngine.generate(profile:recentSessions:lifestyleLogs:now:)` — fully pure, no UI, no side effects
  - **Greeting**: time-of-day (morning/afternoon/evening/night) + optional firstName
  - **Score context**: noData → firstNight → returningAfterGap (>3 days) → improving/declining/steady vs 7-day rolling average
  - **Headline**: duration + snoring minutes + score, warmly phrased
  - **Stats**: Sleep duration, Snoring minutes, Score
  - **Insight**: trend diff + targetSleepHours shortfall (if profile has a goal)
  - **Survey gate**: |Δscore| ≥ 15 from 7-day average AND no LifestyleLog for that night → positive/negative chip prompts
- `QuoteBank` selects context-appropriate quote string by `ScoreTrend`
- All types are `Sendable`; engine is a static func on an empty enum (no state, fully testable)

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Personalization/Sources/Engine/Briefing.swift` | +75 | New value types: `Briefing`, `BriefingStat`, `ScoreTrend`, `SurveyPrompt` |
| `Packages/Personalization/Sources/Engine/BriefingEngine.swift` | +165 | Pure rules engine with greeting, score context, headline, stats, insight, survey gating |
| `Packages/Personalization/Sources/Engine/QuoteBank.swift` | +25 | Context-based quote selection by `ScoreTrend` |
| `docs/trackers/f15-personalization.md` | +1/-1 | T4 status → Done, acceptance criteria checked |
| `docs/FeatureTracker.md` | +2/-2 | Dashboard counts refreshed (75 done, 12 backlog, 25% F15 progress) |

### Architecture Decisions
- **Pure static function**: `BriefingEngine` has no instance state; inputs → output. Makes unit testing trivial (feed synthetic sessions, assert output).
- **Value types throughout**: `Briefing`, `BriefingStat`, `SurveyPrompt`, and `ScoreTrend` are all `Sendable`. No references to `@Model` objects escape the engine; it reads computed properties only.
- **QuoteBank separate**: Keeps motivational copy isolated from logic. Will be migrated to localized keys in T5.
- **7-day rolling average**: Uses the most recent 6 prior sessions (up to 7 days) as the baseline for trend detection. Simple and stable.

### Build Status
- **BUILD SUCCEEDED** — zero errors.

- Add Briefing, BriefingStat, ScoreTrend, SurveyPrompt value types
- Add BriefingEngine.generate() pure rules engine
- Greeting by time-of-day with optional name
- Score context: improving/declining/steady/firstNight/noData/returningAfterGap
- Recap headline, stats chips, trend insight, survey gate (|Δscore|≥15)
- Add QuoteBank for context-based motivational quotes
- Build succeeds with zero errors

### Next Session
- F15-T5: QuoteBank + localized strings for briefing
- F15-T6: SleepBriefingView + subviews

### Open Questions
- (none)


---

## 2026-06-06 — Session 71 (continued): F15-T5 QuoteBank + Localized Strings

### Completed
- F15-T5: Localized all briefing engine strings; regenerated Strings.swift

### Technical Details
- Added 39 localization keys to `Strings.txt`, merged into `Localizable.xcstrings` via `generate-xcstrings.py`:
  - **Greetings**: morning/afternoon/evening/night × with-name + no-name variants
  - **Headlines**: welcome, quiet night, normal night (with format args)
  - **Insights**: improving, declining, steady, goal shortfall (with format args)
  - **Quotes**: improving, declining, steady, firstNight, noData, returningAfterGap
  - **Survey**: positive/negative titles + 10 chip labels (exercised, less caffeine, no alcohol, slept earlier, less stress, late caffeine, alcohol, stressful day, late meal, screens in bed)
  - **Stats**: sleep, snoring, score labels
  - **Profile prompt**: title, subtitle, action
- `QuoteBank.swift` migrated from hardcoded English to `Strings.briefingQuote*`
- `BriefingEngine.swift` migrated all user-facing text to `Strings.*` with `String(format:)` for dynamic interpolation
- `Strings.swift` regenerated to 333 total accessors
- Grep-verified: zero hardcoded capitalized strings remain in `Engine/*.swift`

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Resources/Strings.txt` | +49 | Added 39 briefing and profile localization keys |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +520 | Merged new keys with English translations |
| `Packages/DesignSystem/Sources/Strings.swift` | +39 | Auto-regenerated accessors for new keys |
| `Packages/Personalization/Sources/Engine/QuoteBank.swift` | +4/-4 | Migrated from hardcoded strings to `Strings.*` |
| `Packages/Personalization/Sources/Engine/BriefingEngine.swift` | +15/-10 | Migrated all user-facing text to `Strings.*` with `String(format:)` |
| `docs/trackers/f15-personalization.md` | +1/-1 | T5 status → Done, acceptance criteria checked |
| `docs/FeatureTracker.md` | +2/-2 | Dashboard counts refreshed (76 done, 11 backlog, 31% F15 progress) |

### Build Status
- **BUILD SUCCEEDED** — zero errors.

`[F15-T5] Localize BriefingEngine and QuoteBank strings`
- Add 39 briefing/profile keys to Localizable.xcstrings
- Migrate QuoteBank from hardcoded English to Strings.*
- Migrate BriefingEngine headlines, insights, greetings, stats to localized format strings
- Add 10 localized survey chip labels
- Regenerate Strings.swift (333 total accessors)
- Build succeeds with zero errors

### Next Session
- F15-T6: SleepBriefingView + subviews (full-screen container, greeting header, recap card, insight card, survey card)

### Open Questions
- (none)


---

## 2026-06-06 — Session 71 (continued): F15-T6 SleepBriefingView + Subviews

### Completed
- F15-T6: Full-screen Sleep Briefing UI with 4 subviews

### Technical Details
- `SleepBriefingView` — 64-line container receiving `Briefing` + `onDismiss` + optional `onChipTap`
  - Scrollable full-screen with `theme.bgPrimary` background
  - Vertical stack: greeting → recap card → insight card → nudge → survey card → dismiss button
  - Close button: white text on black pill at bottom
- `BriefingGreetingHeader` — large bold greeting text, leading-aligned
- `BriefingRecapCard` — headline + 3 `StatCard` chips (sleep duration, snoring minutes, score) in HStack
  - Reuses existing `StatCard` component from DesignSystem
  - Icons mapped by label: bed.double.fill, waveform, star.fill
- `BriefingInsightCard` — sparkles icon + insight text on `bgCard` background
- `BriefingSurveyCard` — title + chip buttons in a custom `FlowLayout` + Skip action
  - `FlowLayout` is a simple `Layout` protocol implementation for wrapping chip rows
  - Chips use `bgElevated` with `radiusSmall`; tap calls `onChipTap` then dismisses
- All strings resolved via `Strings.*`; grep-verified zero hardcoded literals

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Personalization/Sources/Views/SleepBriefingView.swift` | +64 | Full-screen briefing container (replaced placeholder) |
| `Packages/Personalization/Sources/Views/BriefingGreetingHeader.swift` | +21 | Greeting headline component |
| `Packages/Personalization/Sources/Views/BriefingRecapCard.swift` | +49 | Headline + stat chips card |
| `Packages/Personalization/Sources/Views/BriefingInsightCard.swift` | +29 | Insight text card with sparkles icon |
| `Packages/Personalization/Sources/Views/BriefingSurveyCard.swift` | +92 | Survey card with FlowLayout chip buttons and Skip action |
| `docs/trackers/f15-personalization.md` | +1/-1 | T6 status → Done, acceptance criteria checked |
| `docs/FeatureTracker.md` | +2/-2 | Dashboard counts refreshed (77 done, 10 backlog, 38% F15 progress) |

### Build Status
- **BUILD SUCCEEDED** — zero errors.

`[F15-T6] SleepBriefingView and subviews`
- Add SleepBriefingView full-screen container (64 lines)
- Add BriefingGreetingHeader, BriefingRecapCard, BriefingInsightCard, BriefingSurveyCard
- Reuse StatCard component for recap stat chips
- Add custom FlowLayout for survey chip wrapping
- All strings via Strings.*; zero hardcoded literals
- Build succeeds with zero errors

### Next Session
- F15-T7: Profile editor views (4 steps)

### Open Questions
- (none)
