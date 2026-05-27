# Feature: F14 — SleepGuard Rebrand & Multi-Sound Detection

## Status: In Progress
## Phase 1 Completed: 2026-05-25
## Phase 2 Completed: 2026-05-26
## Phase 3 Completed: 2026-05-26
## Phase 4 In Progress: 2026-05-26

## Summary

Rebrand the app from SnoreGuard to SleepGuard and expand audio detection from snore-only to multi-sound tracking (snoring, sleep talking, coughing, noise). The rebrand updates all user-facing strings, bundle identifiers, and app display names while keeping the internal data model names intact. The multi-sound architecture adds parallel classifiers to the existing detection pipeline, with snoring retaining priority. An optional Apple Watch sleep stage overlay can correlate HealthKit sleep analysis data with audio events.

## Files

| File | Package | Purpose |
|------|---------|---------|
| `Packages/Models/Sources/Data/SleepSession.swift` | Models | Added `SleepStageSegment` + `SleepStage` enum for optional Watch sleep stage data |
| `Packages/Models/Sources/Data/SnoreEvent.swift` | Models | Expanded `SoundCategory` with `.coughing`; `.sleepTalking` and `.noise` already existed |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | AudioEngine | `SnoringState` → `DetectionState` rename (code-level, no migration) |
| `Packages/AudioEngine/Sources/Engine/SnoreSample.swift` | AudioEngine | Updated `state` property type to `DetectionState` |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | AudioEngine | Existing tap infrastructure reused for parallel classifiers |
| `Packages/Env/Sources/Services/SessionManager.swift` | Env | `currentSnoringState` → `currentDetectionState`; future home for parallel speech tracking |
| `Packages/Env/Sources/Services/SessionRawLogWriter.swift` | Env | `DetectionState` param type updated |
| `Packages/Env/Sources/Services/RecordingDelayManager.swift` | Env | Notification title "SnoreGuard" → "SleepGuard" |
| `Packages/Env/Sources/Services/UserPreferences.swift` | Env | Future home for `detectSleepTalking` toggle |
| `Packages/Env/Sources/Services/HealthKitSync.swift` | Env | Future source for HealthKit sleep stage queries |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | SleepSession | `currentSnoringState` → `currentDetectionState` references |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | Recordings | Future home for category filter and sleep stage timeline overlay |
| `Packages/Recordings/Sources/Views/SessionDetailEventsView.swift` | Recordings | Future home for segmented category picker |
| `Packages/DesignSystem/Sources/Components/SleepStageBreakdownView.swift` | DesignSystem | Compact stage bar + 2×2 stat grid for Statistics dashboard and session detail timeline |
| `Packages/DesignSystem/Sources/Components/SleepStageBreakdownView.swift` | DesignSystem | Compact stage bar + 2×2 stat grid for Statistics dashboard |
| `Packages/Recordings/Sources/Views/SessionDetailTimelineView.swift` | Recordings | Future home for multi-category color rendering |
| `Packages/Recordings/Sources/Views/EventRow.swift` | Recordings | Future home for category-based icons |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | Recordings | Future title updates based on event category |
| `Packages/Recordings/Sources/Views/SleepReportPDFGenerator.swift` | Recordings | "SnoreGuard" → "SleepGuard" in PDF header/footer |
| `Packages/DesignSystem/Sources/Components/SessionStatsGrid.swift` | DesignSystem | Future home for optional disturbance summary row |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | DesignSystem | Rebrand strings updated (onboarding, alerts, privacy copy) |
| `Packages/Settings/Sources/Views/SettingsView.swift` | Settings | Future home for "Detect Sleep Talking" and "Enhanced Sleep Tracking" toggles |
| `SnoreGuard/SleepGuardApp.swift` | App | App entry point renamed from `SnoreGuardApp` |
| `SnoreGuard/Info.plist` | App | Added `CFBundleDisplayName` = "SleepGuard" |
| `SnoreGuard.xcodeproj/project.pbxproj` | App | Bundle ID updated to `com.daki.exampleProject.SleepGuard` |
| `WatchApp/Sources/SnoreGuardWatchApp.swift` | WatchApp | Watch app struct renamed to `SleepGuardWatchApp` |

## Routes

| Type | Destination | View | Trigger |
|------|-------------|------|---------|
| — | — | — | No new routes in Phase 1 |

_Planned for Phase 3–4: Potential sleep stage detail or correlation views (deferred until Watch integration is wired)._

## State

| Property | Type | Scope | Description |
|----------|------|-------|-------------|
| `sleepStageSegments` | `[SleepStageSegment]?` | `SleepSession` | Optional Watch sleep stage data; `nil` for all legacy sessions |
| `SoundCategory` | enum | `SnoreEvent` | `.snoring`, `.sleepTalking`, `.coughing`, `.noise`, `.other` |
| `currentDetectionState` | `DetectionState` | `SessionManager` | Real-time snoring state (renamed from `currentSnoringState`) |
| `detectSleepTalking` | `Bool` | `UserPreferences` | **Planned Phase 2** — toggle to enable speech detection |
| `enhancedSleepTracking` | `Bool` | `UserPreferences` | **Planned Phase 4** — toggle to enable Watch sleep stage overlay |

## Edge Cases

- **Legacy sessions have no sleep stage data** → `sleepStageSegments` is `nil`; UI hides the stage timeline overlay entirely. No migration required.
- **Single-category nights (only snoring)** → Category filter in `SessionDetailView` is hidden. The UI stays identical to the pre-rebrand experience.
- **Snoring vs. sleep talking overlap** → Snoring always takes priority in the classifier pipeline. If audio is classified as snoring, it is never also classified as speech. No duplicate events.
- **HealthKit sleep data missing or delayed** → Watch sleep stage overlay gracefully falls back to hidden. The session still shows all audio events normally.
- **SwiftData model lightness** → `SleepStageSegment` is a `Codable` struct array, not a `@Model` relationship. This avoids complex migrations and keeps `SleepSession` lightweight.
- **Rebrand without breaking existing data** → Internal model names (`SnoreEvent`, `snoringDuration`) remain unchanged. Only user-facing strings and app metadata changed.
- **App Store review medical claims** → Copy avoids diagnosing sleep disorders. Framed as "track audio during sleep."

## Tasks Completed

| Task ID | Name | Phase |
|---------|------|-------|
| P1-T1 | App-wide rebrand (bundle ID, display name, app struct) | 1 |
| P1-T2 | String migration (6 keys in Localizable.xcstrings) | 1 |
| P1-T3 | Model expansion (`SleepStageSegment`, `SoundCategory.coughing`) | 1 |
| P1-T4 | `DetectionState` rename (`SnoringState` → `DetectionState`) | 1 |
| P1-T5 | Build & verify | 1 |
| P2-T1 | `SpeechDetector`: New classifier in `AudioEngine` | 2 |
| P2-T2 | Parallel detection wiring in `SessionManager` | 2 |
| P2-T3 | Event creation for `.sleepTalking` | 2 |
| P2-T4 | Settings toggle "Detect Sleep Talking" | 2 |
| P2-T5 | Build & verify — zero errors, no regressions | 2 |
| P3-T1 | Category filter: Segmented picker in `SessionDetailView` | 3 |
| P3-T2 | EventRow icons: Category-based icons | 3 |
| P3-T3 | Timeline multi-color: Sleep talking = purple, noise = orange | 3 |
| P3-T4 | Stats grid supplement: Optional disturbance row | 3 |
| P3-T5 | Player labels: Title based on event category | 3 |
| P3-T6 | Build & verify — zero errors, Phase 3 UI verified | 3 |
| P4-T1 | HealthKit read sleep stages | 4 |
| P4-T2 | Stage correlation: Attach segments to `SleepSession` | 4 |
| P4-T3 | Stage timeline overlay: `SleepStageBreakdownView` | 4 |
| P4-T4 | Statistics integration: `SleepStageBreakdownView` + mock data | 4 |

## Remaining Work

### Phase 3: UI Adaptation
- **P3-T1** — Category filter: Segmented picker (`All | Snoring | Sleep Talking | Noise`) in `SessionDetailView`
- **P3-T2** — EventRow icons: Category-based icons replacing intensity dot for non-snoring events
- **P3-T3** — Timeline multi-color: Sleep talking = purple, noise = orange, snoring = existing intensity colors
- **P3-T4** — Stats grid supplement: Optional disturbance row below the 2×2 grid
- **P3-T5** — Player labels: `PlayerSheetView` title based on event category
- **P3-T6** — Build & verify: Screenshot comparison with design tokens

### Phase 4: Apple Watch Sleep Stages
- **P4-T1** — HealthKit read: Extend `HealthKitSync` to query `HKCategoryValueSleepAnalysis` ✅
- **P4-T2** — Stage correlation: Map HealthKit segments to `SleepStageSegment`, attach to `SleepSession` ✅
- **P4-T3** — Stage timeline overlay: `SleepStageBreakdownView` in `SessionDetailTimelineView` and `StatisticsLoadedView` ✅
- **P4-T4** — Statistics integration: Stage breakdown in `StatisticsDashboardView` for Watch users ✅
- **P4-T5** — Settings toggle: "Enhanced Sleep Tracking" requiring Watch + HealthKit permission
- **P4-T6** — Build & verify
