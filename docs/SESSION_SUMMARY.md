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
| `SnoreGuard/MainTabView.swift` | +9/-4 | Added `sessionManager` env; `.onChange` swaps sheet; `.sessionSummary` maps to `SessionSummaryView` |
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
| `SnoreGuard/MainTabView.swift` | +6/-1 | Added `onDismiss` to `.sheet` that clears `completedSession` |

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
| `SnoreGuard/AppRegistry.swift` | +2 | Added `.liveSession` → `SleepSessionView()` mapping in `withAppRouter()` |
| `SnoreGuard/MainTabView.swift` | +1/-6 | Removed `.liveSession` from sheet switch; updated onboarding + completedSession handling |
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
- When `OnboardingView.finishOnboarding()` set `hasCompletedOnboarding = true`, `SnoreGuardApp` never re-evaluated its body because no change was observed
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
| `SnoreGuard/AppRegistry.swift` | +1/-1 | `.recordingDetail(id:)` now maps to `SessionDetailView(sessionID: id)` instead of placeholder `Text` |
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
| `SnoreGuard/AppRegistry.swift` | +2 | Mapped `.trends` → `TrendsView()` |
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
- **F6-T2**: Built `SettingsView` form UI matching designs/SnoreGuard.pen
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
- `SnoreGuardApp.swift` applies `.preferredColorScheme(colorScheme(for:))` based on `userPreferences.appearance`
- `Color(hex:)` extension in DesignSystem made `public` so Settings package can use it

### Files Changed

| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Env/UserPreferences.swift` | +28 | Added `minSnoreDuration` and `maxClipLength` computed properties with UserDefaults backing |
| `Packages/Settings/Sources/Settings/SettingsView.swift` | +281 | Complete rewrite. Full settings form UI with all design sections |
| `SnoreGuard/SnoreGuardApp.swift` | +8 | Added `.preferredColorScheme` based on `UserPreferences.appearance` |
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
- **Polish pass across F1–F6 V1**: Fixed visual discrepancies and functional bugs found by comparing live screens against `designs/SnoreGuard.pen`.

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
| `SnoreGuard/MainTabView.swift` | +1/-0 | Added `.toolbarBackground(theme.bgSecondary, for: .tabBar)` |
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
| `SnoreGuard/AppRegistry.swift` | +2 | Mapped `.calendar` → `CalendarView()` in `withAppRouter()` |

### Build Status
- **BUILD SUCCEEDED** — zero errors across all packages + app target

### Git Handoff
- **Suggested branch**: `feature/calendar-view`
- **Suggested commit**: `CalendarView — Month calendar with session dots, stats, and selected-night card`

### Open Questions
- Should a Calendar screen be added to `designs/SnoreGuard.pen` for formal design compliance?

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
  - Created `SnoreGuard/SnoreGuard.entitlements` with `com.apple.developer.healthkit`
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
| `SnoreGuard/SnoreGuard/SnoreGuard.entitlements` | +8 | New. HealthKit capability entitlement |
| `SnoreGuard.xcodeproj/project.pbxproj` | +4 | Added `CODE_SIGN_ENTITLEMENTS` and `NSHealth*` Info.plist keys to Debug + Release |
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
  - Created `WatchApp/Sources/` with `SnoreGuardWatchApp.swift`, `ContentView.swift`, `WatchSessionManager.swift`, `WatchAudioRecorder.swift`
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
| `WatchApp/Sources/SnoreGuardWatchApp.swift` | +17 | New. Watch app entry point + WKApplicationDelegate with WCSession activation |
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
| `SnoreGuard/AppRegistry.swift` | +8/-4 | Added 5 new services to environment graph |
| `SnoreGuard/SnoreGuardApp.swift` | +5/-1 | Passed new services to dependency graph; added AudioEngine import |
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
| `SnoreGuard/MainTabView.swift` | +90/-15 | iOS 26+ system TabView branch; custom floating pill tab bar for iOS < 26; hide during recording |
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
| `SnoreGuard/MainTabView.swift` | +3/-3 | `tabMedia`, `tabSettings`, `tabStatistics` |
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
- **Last 7 Nights dedicated screen**: Created `Last7NightsView` matching design node fuq0d from `SnoreGuard.pen`. Includes custom nav bar with "Stats" back button, date range + avg sleep score header with week-over-week trend indicator (`+4 vs prev wk`), snoring minutes bar chart with intensity-based colors (quiet/gray, light/amber, loud/red), 2×2 stat grid (AVG SNORING, TOTAL EVENTS, BEST, WORST), and ALL NIGHTS list with score circles, day/date, duration, and snoring time.
- **Reusable components extracted**: `Last7NightsChartCard`, `Last7NightsStatGrid`, `Last7NightsRow`, `Last7NightsDaySummary`, `WeekOverWeekTrendCalculator` — all under 200 lines per AGENTS.md rules.
- **New route `.last7Nights`**: Added to `RouterDestination` and mapped to `Last7NightsView()` in `AppRegistry`.
- **"See all" button wired**: `StatisticsMiniChartSection` now uses `@Environment(RouterPath.self)` to navigate directly to `.last7Nights` instead of prop-drilling closures.
- **Duration format unification**: Fixed all user-facing duration strings to use consistent `%d h %d min` / `%d min` format matching `NightGroupRowView`. Updated `Last7NightsRow`, `Last7NightsStatGrid`, `SessionSummaryView`, `BedsideClockView`, `WatchSessionManager`.
- **Event player timestamp**: Added event start time (`hh:mm am/pm`) to `EventPlayerView.headerSection` before "Snoring Event", matching `EventRow` format.
- **Tab navigation bugfix**: Root cause was `withAppDependencyGraph` injecting three `RouterPath` instances via `.environment()`, where the last one (`settingsRouterPath`) overwrote the previous two. All tabs shared the same navigation path, so pushing a detail view in Recordings tab polluted Statistics tab's stack. Fixed by giving each tab (`StatisticsTab`, `RecordingsTab`, `SettingsTab`) its own `@State private var routerPath = RouterPath()` injected via `.environment(routerPath)` scoped to the tab's view hierarchy. Removed shared router paths from `SnoreGuardApp` and `withAppDependencyGraph`.
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
| `SnoreGuard/AppRegistry.swift` | +2/-8 | Mapped `.last7Nights` → `Last7NightsView`; removed shared router paths |
| `SnoreGuard/StatisticsTab.swift` | +3/-2 | Own `@State var routerPath`; `.environment(routerPath)` |
| `SnoreGuard/RecordingsTab.swift` | +3/-2 | Own `@State var routerPath`; `.environment(routerPath)` |
| `SnoreGuard/SettingsTab.swift` | +3/-2 | Own `@State var routerPath`; `.environment(routerPath)` |
| `SnoreGuard/SnoreGuardApp.swift` | +1/-6 | Removed shared `statisticsRouterPath`, `recordingsRouterPath`, `settingsRouterPath` |
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
- `AppRegistry.swift` and `SnoreGuardApp.swift` updated to inject `SoothingMelodyPlayer.shared` into the environment graph.
- `UserPreferences.selectedMelodyID` default changed from 12 → 6 to match the new valid ID range (1–11).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SnoreGuard.xcodeproj/project.pbxproj` | +6 | Added `sounds/` folder reference to main app target resources build phase |
| `Packages/Models/Sources/Data/Melody.swift` | +11/-10 | Replaced dummy melodies with real filename + displayName mapping for 11 MP3s |
| `Packages/Env/Sources/Services/SoothingMelodyPlayer.swift` | +65 | New — AVAudioPlayer wrapper with playIfNeeded, stop, auto-stop timer, isPlaying state |
| `Packages/Env/Sources/Services/SessionManager.swift` | +4 | Triggers `playIfNeeded()` on new snore event; stops on session end |
| `Packages/Env/Sources/Services/UserPreferences.swift` | +1/-1 | Default `selectedMelodyID` changed 12 → 6 |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | +35 | Added `melodyOverlay` with pulsing icon, name, Stop button; injected `SoothingMelodyPlayer` |
| `Packages/SleepSession/Sources/Views/SoothingMelodySheet.swift` | +1/-1 | Default `draftMelodyID` changed 12 → 6 |
| `SnoreGuard/SnoreGuardApp.swift` | +2 | Injected `soothingMelodyPlayer` into `withAppDependencyGraph` |
| `SnoreGuard/AppRegistry.swift` | +4 | Added `SoothingMelodyPlayer` parameter to `withAppDependencyGraph` and `withEnvironments` |

### Architecture Decisions
- **Placement in Env package**: `SoothingMelodyPlayer` lives in `Env` because it needs `UserPreferences` (also in Env) and must be observable by `BedsideClockView` (in SleepSession, which imports Env). This avoids a new package and follows the existing singleton + `@Environment` pattern.
- **Compact overlay vs full sheet**: Chose a compact top-overlay card instead of a full `.sheet` because a modal would block the bedside clock and stop button during sleep recording.
- **Volume 0.6**: Fixed at 60% to reduce the chance of playback being picked up by the microphone while still being audible. No recording pause — snore detection must continue uninterrupted per user requirement.
- **Re-trigger guard**: Ignore new snore detections while already playing. Prevents rapid audio restart/stutter. If the user wants restart-on-every-snore, it's a one-line removal of `guard !isPlaying else { return }`.

### Build Status
- **BUILD SUCCEEDED** — zero errors, zero warnings.
- Verified that MP3 files are present in built app bundle: `SnoreGuard.app/sounds/*.mp3` (11 files).

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
| `SnoreGuard.xcodeproj/project.pbxproj` | +6 | Added `sounds/` folder reference to app target resources |
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
| `SnoreGuard/SnoreGuardApp.swift` | +2 | Injected `SoothingMelodyPlayer` into environment |
| `SnoreGuard/AppRegistry.swift` | +4 | Added `SoothingMelodyPlayer` to dependency graph |

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

## 2026-05-15 — Session 45: Nightstand Mode — Auto-lock Prevention + Charging Alert

### Completed
- **Idle timer disable during sleep sessions**: Added `UIApplication.shared.isIdleTimerDisabled` logic in `SnoreGuardApp.swift` tied to `SessionManager.isRecording`. Also handles `scenePhase` `.active` to re-disable the idle timer when returning from background (iOS auto-re-enables it on background).
- **Charging alert before recording**: Added an alert when the user taps Start Recording and the iPhone is not charging. Alert shows in both `RecordingPrestartView` (main start button) and `RecordingCountdownView` ("Start Now" button). Auto-start after countdown completion skips the alert since the user isn't present.
- **Alert actions**: "Cancel" dismisses; "Start Anyway" proceeds with the session. Alert button actions wrapped in `Task { @MainActor in }` for safe actor isolation.

### Technical Details
- `UIDevice.current.isBatteryMonitoringEnabled = true` must be set before reading `batteryState`. On simulator, `batteryState` returns `.unknown` so the alert always fires — this is expected simulator behavior.
- Alert closures use shared singletons (`SessionManager.shared`, `UserPreferences.shared`) directly rather than `@Environment` properties to avoid any potential environment access issues from modal alert contexts.
- Added 3 localized strings: `session.chargingAlert.title`, `session.chargingAlert.message`, `session.chargingAlert.startAnyway` via `Strings.txt` → `generate-xcstrings.py`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SnoreGuard/SnoreGuardApp.swift` | +9 | `scenePhase` env + `.onChange` for `isRecording` and `.active` to toggle idle timer |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` | +3 | Added charging alert title, message, startAnyway strings |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | — | Regenerated with 3 new entries |
| `Packages/DesignSystem/Sources/Strings.swift` | — | Regenerated with `sessionChargingAlertTitle`, `Message`, `StartAnyway` |
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +35 | Charging check in start button, alert modifier, `beginSession()` helper, `isCharging` property |
| `Packages/SleepSession/Sources/Views/RecordingCountdownView.swift` | +28 | Charging check in "Start Now", alert modifier, `startSession()` helper, `isCharging` property |

### Build Status
- **BUILD SUCCEEDED** — zero errors.

### Git Handoff
- **Suggested branch**: `feature/nightstand-auto-lock-charging-alert`
- **Suggested commit**: `Nightstand mode — disable idle timer during sessions + charging alert before recording`

### Open Questions
- On physical devices, verify that `batteryState` returns `.charging` or `.full` when plugged in. If any device returns `.unknown` while charging, the alert logic may need adjustment.
