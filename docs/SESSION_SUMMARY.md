# SnoreGuard Sprint Log

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
- **F1-T5**: Onboarding gate in `SnoreGuardApp.swift` — shows `OnboardingView` when `!hasCompletedOnboarding`, else `MainTabView`; `.sheet(item:)` registration for `.onboarding` in `AppRegistry.swift`

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
| `SnoreGuard/MainTabView.swift` | +9/-4 | Added `sessionManager` env; `.onChange` swaps sheet; `.sessionSummary` maps to `SessionSummaryView` |
| `Packages/SleepSession/Sources/SleepSession/SleepSessionView.swift` | +2/-1 | Added `Color.clear` branch when `completedSession != nil` |

### Architecture Decisions
- **Sheet swap via `SessionManager`**: Instead of passing the tab's `RouterPath` into the sheet, `SessionManager.completedSession` acts as the bridge. The tab observes it and swaps sheets. This avoids threading `RouterPath` through `.withEnvironments()`.
- **Explicit SwiftData insertion**: Both `SleepSession` and each `SnoreEvent` are explicitly `modelContext.insert()`'ed before save. This ensures persistence even if SwiftData relationship cascade behavior varies.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F2-T6**: Route registration + wiring (pre-start, bedside clock, summary sheet routes; Statistics CTA; onboarding routing)

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
| `SnoreGuard/MainTabView.swift` | +6/-1 | Added `onDismiss` to `.sheet` that clears `completedSession` |

### Architecture Decisions
- **Sheet `onDismiss` for state cleanup**: Rather than adding a dedicated `clearCompletedSession()` method, `StatisticsTab` handles cleanup when the sheet is dismissed. This keeps `SessionManager` simple and avoids exposing extra API surface.

### Build Status
- **BUILD SUCCEEDED** — zero errors across all 9 packages + app target

### Next Session
- **F3-T1**: StatisticsDashboardView empty + loaded states (SwiftData query, ViewState enum)

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

### Open Questions
- None

---
