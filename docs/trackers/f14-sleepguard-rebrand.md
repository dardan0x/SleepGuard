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
- [ ] Sleep talking detected and recorded as `.sleepTalking` events
- [ ] Category filter in SessionDetailView
- [ ] EventRow shows category icons for non-snoring events
- [ ] Timeline view renders multi-category colors
- [ ] Optional Apple Watch sleep stage timeline overlay
- [ ] Settings toggle for sleep talking detection
- [ ] Settings toggle for enhanced sleep tracking (Watch)
- [ ] Build succeeds with zero errors

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
| P4-T2 | Stage correlation | ⬜ Backlog | Map to SleepStageSegment |
| P4-T3 | Stage timeline overlay | ⬜ Backlog | New SleepStageTimelineView |
| P4-T4 | Statistics integration | ⬜ Backlog | Show stage breakdown |
| P4-T5 | Settings toggle | ⬜ Backlog | "Enhanced Sleep Tracking" |
| P4-T6 | Build & verify | ⬜ Backlog | — |

## Prompt Used

User requested a detailed plan for rebranding SnoreGuard to SleepGuard and expanding from snore-only to multi-sound sleep tracking. User selected Approach B (Full Sleep Tracker) from the plan.

## Notes

- Phase 1 completed in Session 58
- P2-T2 completed in Session 59
- P2-T3 completed in Session 59
- Phase 2 complete (P2-T1 through P2-T5)
- **Next task to pick up: P4-T2 (Stage correlation)**
- When user says "continue" or "work on what's next", start with the 🟡 Next task in this tracker
- F13 (CloudKit Sync) is intentionally skipped — do NOT work on it unless explicitly asked
- Feature doc: `docs/features/f14-sleepguard-rebrand.md`
- See `/Users/user/.kimi/plans/maxima-blue-marvel-moon-knight.md` for full strategic plan
