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
| P5-T1 | Bandpass filter bugfix — sleep talking never detected | ✅ Done | EQ (100–500 Hz) removed from `AudioRecorder`; tap now runs on raw `inputNode`; SoundAnalysis receives full-spectrum audio; FFT analyzer already distinguishes snoring from speech on full audio |
| P5-T2 | Sleep score excludes non-snoring events | ✅ Done | `SleepSession.snoringDuration` and `sleepScore` now filter by `.snoring` category only; sleep talking no longer incorrectly penalizes score |
| P5-T3 | Category-specific events title | ✅ Done | `SessionDetailEventsView` accepts dynamic title; `SessionDetailView` passes format string based on selected filter (All/Snoring/Sleep Talking/Noise); 4 new localized strings |
| P5-T4 | Baby sound detection | ✅ Done | Added `babyIdentifiers` (`baby_crying`, `baby_laughter`, `babble`) to `SoundAnalysisDetector`; baby confidence feeds into `speechConfidence` pipeline; creates `.sleepTalking` events |
| P5-T5 | Expanded speech/vocalization identifiers | ✅ Done | `speechIdentifiers` expanded from 5 → 22 entries: `whisper`, `mumble`, `mutter`, `stutter`, `groan`, `moan`, `sigh`, `grunt`, `grumble`, `exclaim`, `gasp`, `yell`, `scream`, `shout`, `laugh`, `giggle`, `whimper` |
| P5-T6 | Speech detection threshold tuning | ✅ Done | `SpeechDetector.dbFloor` lowered from -40.0 → -55.0 to catch quiet sleep talking at nightstand distance; speech event minimum duration lowered from 2.0s → 0.5s to capture brief utterances; debug logging added |

## Prompt Used

User requested a detailed plan for rebranding SnoreGuard to SleepGuard and expanding from snore-only to multi-sound sleep tracking. User selected Approach B (Full Sleep Tracker) from the plan.

## Notes

- Phase 1 completed in Session 58
- P2-T2 completed in Session 59
- **Bugfix (Session 61)**: Bandpass filter (100–500 Hz) applied before SoundAnalysis tap was destroying speech spectral content above ~700 Hz, causing sleep talking to never be detected. Removed EQ entirely — tap now runs on raw input node. FFT analyzer already distinguishes snoring from speech via `lowFreqRatio` and `spectralCentroid` on full-spectrum audio, so snoring detection remains accurate. Also fixed `snoringDuration` and `sleepScore` to only count `.snoring` events, preventing sleep talking from incorrectly penalizing the score.
- P2-T3 completed in Session 59
- Phase 2 complete (P2-T1 through P2-T5)
- F14 is now complete (27/27 tasks)
- When user says "continue" or "work on what's next", start with the 🟡 Next task in this tracker
- F13 (CloudKit Sync) is intentionally skipped — do NOT work on it unless explicitly asked
- Feature doc: `docs/features/f14-sleepguard-rebrand.md`
- See `/Users/user/.kimi/plans/maxima-blue-marvel-moon-knight.md` for full strategic plan
