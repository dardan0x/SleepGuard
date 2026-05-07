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
