# F14: SleepGuard Rebrand & Multi-Sound Detection

> Tracker for the SleepGuard rebrand and multi-sound detection expansion.

## Overview

Rebrand SnoreGuard to SleepGuard and expand detection from snore-only to multi-sound (snoring, sleep talking, coughing, noise). Add optional Apple Watch sleep stage overlay.

## Acceptance Criteria

- [x] App displays as "SleepGuard" on home screen
- [x] Bundle ID updated to `com.daki.exampleProject.SleepGuard`
- [x] All user-facing "SnoreGuard" references removed
- [x] Data model supports future sleep stage segments without migration
- [x] `SoundCategory` supports `.sleepTalking`, `.coughing`, `.noise`
- [x] Sleep talking detected and recorded as `.sleepTalking` events
- [x] Category filter in SessionDetailView
- [x] EventRow shows category icons for non-snoring events
- [x] Timeline view renders multi-category colors
- [x] Optional Apple Watch sleep stage breakdown view
- [x] Settings toggle for sleep talking detection
- [x] Settings toggle for enhanced sleep tracking (Watch)
- [x] Build succeeds with zero errors
- [x] Statistics integration with dummy data

## Tasks

| ID | Task | Status | Notes |
|----|------|--------|-------|
| P1-T1 | App-wide rebrand (bundle ID, display name, app struct) | ✅ Done | `SleepGuardApp.swift`, `CFBundleDisplayName`, bundle ID |
| P1-T2 | String migration | ✅ Done | 6 keys updated in Localizable.xcstrings |
| P1-T3 | Model expansion (SleepStageSegment, SoundCategory.coughing) | ✅ Done | Zero-migration, backward-compatible |
| P1-T4 | DetectionState rename | ✅ Done | `SnoringState` → `DetectionState`, 5 files |
| P1-T5 | Build & verify | ✅ Done | BUILD SUCCEEDED |
| P2-T1 | SpeechDetector | ✅ Done | New classifier in AudioEngine — SpeechDetector singleton + SoundAnalysisDetector speech confidence extraction |
| P2-T2 | Parallel detection wiring | ✅ Done | SessionManager integration |
| P2-T3 | Event creation for sleep talking | ✅ Done | `finalizeEvent()` category logic |
| P2-T4 | Settings toggle | ✅ Done | "Detect Sleep Talking" on/off |
| P2-T5 | Build & verify | ✅ Done | Clean build (zero errors); code review confirms snoring behavior unchanged when toggle off; priority finalization correct; no regressions |
| P3-T1 | Category filter | ✅ Done | Segmented picker in SessionDetailView |
| P3-T2 | EventRow icons | ✅ Done | Category-based icons |
| P3-T3 | Timeline multi-color | ✅ Done | Sleep talking = purple, noise = orange |
| P3-T4 | Stats grid supplement | ✅ Done | Optional disturbance row |
| P3-T5 | Player labels | ✅ Done | Title based on event category |
| P3-T6 | Build & verify | ✅ Done | Clean build (zero errors); pre-existing asset warnings only; Phase 3 UI verified |
| P4-T1 | HealthKit read sleep stages | ✅ Done | `fetchSleepStages(for:)` queries HK sleep analysis samples, maps to `SleepStageSegment`; `mapSleepStage` maps core/deep/REM/awake; skips legacy/in-bed/unspecified |
| P4-T2 | Stage correlation | ✅ Done | `SessionDetailView.loadSession()` fetches stages when `sleepStageSegments == nil`, stores empty array for no-data to prevent re-query, saves to SwiftData |
| P4-T3 | Stage timeline overlay | ✅ Done | `SleepStageBreakdownView` compact stage bar + 2×2 stat grid; shown in `SessionDetailTimelineView` and `StatisticsLoadedView`; 5 localized strings; build succeeds |
| P4-T4 | Statistics integration | ✅ Done | `SleepStageBreakdownView` compact stage bar + 2×2 stat grid in `StatisticsLoadedView`; `MockDataGenerator` generates realistic sleep cycles; build succeeds |
| P4-T5 | Settings toggle | ✅ Done | "Enhanced Sleep Tracking" toggle in SettingsWatchSection; requests HealthKit auth on enable; gates `fetchSleepStages` in SessionDetailView |
| P4-T6 | Build & verify | ✅ Done | Clean build (zero errors); all F14 changes verified |

## Prompt Used

User requested a detailed plan for rebranding SnoreGuard to SleepGuard and expanding from snore-only to multi-sound sleep tracking. User selected Approach B (Full Sleep Tracker) from the plan.

## Notes

- Phase 1 completed in Session 58
- P2-T2 completed in Session 59
- P2-T3 completed in Session 59
- Phase 2 complete (P2-T1 through P2-T5)
- F14 is now complete (21/21 tasks)
- When user says "continue" or "work on what's next", start with the 🟡 Next task in this tracker
- F13 (CloudKit Sync) is intentionally skipped — do NOT work on it unless explicitly asked
- Feature doc: `docs/features/f14-sleepguard-rebrand.md`
- See `/Users/user/.kimi/plans/maxima-blue-marvel-moon-knight.md` for full strategic plan
