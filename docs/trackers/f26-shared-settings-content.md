# F26 — Shared Settings content

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P2 |
| **Version** | — |
| **Blocked By** | F25 |
| **Started** | 2026-11-17 |
| **Completed** | 2026-11-17 |
| **Feature Doc** | — |

## Summary

Settings, the profile editor, the prestart's start delay and the countdown host their layouts from the shared `SleepGuardContentKit` (ADR 0006), and three rules move to `SleepCore`: which nights the storage limits empty (`StoragePlan`), the delay's options and countdown text (`RecordingDelay`), and the raw log format (`RawLog`, `SnoreSample`, `RawLogMetadata`). The profile maps to the shared `SleepProfile` value. No schema change, no visible change. Mirrors SleepGuardUIKitWay's F8-T1, which builds its Settings on the same content.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F26-T1 | Settings, profile editor, delay row and countdown host the shared content; storage, delay and raw log rules from SleepCore; `UserProfile` ↔ `SleepProfile` | Refactor | Done | F25 | Settings, Personalization, SleepSession, Env, Models, AudioEngine | 2026-11-17 | 2026-11-17 |
| F26-T2 | Sleep stages: the breakdown card and the info sheet host the shared content; stage statuses and the score impact from SleepCore's `SleepStageBreakdown` | Refactor | Done | F26-T1 | DesignSystem, Recordings, Statistics | 2026-11-17 | 2026-11-17 |
| F26-T3 | Snore Interrupter: prestart row, settings sheet, melody picker, recorder and bedside pieces host the shared content; mode, catalog, recording rules and gap helpers from SleepCore; sounds from the shared `SleepMelodies` | Refactor | Done | F26-T2 | SleepSession, Env, Models, DesignSystem, app bundle | 2026-11-17 | 2026-11-17 |
| F26-T4 | Onboarding hosts the shared content; page order and moves from SleepCore's `OnboardingPages`; the Health page follows the `healthSync` flag | Refactor | Done | F26-T3 | Onboarding | 2026-11-17 | 2026-11-17 |

## Notes

- 18 files deleted with the owner's approval (the Settings sections and their helpers, the four profile pages and the chip selector, `PrestartDelaySection`, `SnoreSample.swift` and its tests, now in the shared repo).
- `SettingsView` is split in three files (`+Values`, `+Actions`) for the 200-line limit.
- The shared day rule chooses every night past the limit, as `StorageLimitEnforcer` did, so stale references are still cleared.
- F26-T2: 7 files deleted with the owner's approval (`SleepStageBreakdownView`, `SleepStageHypnogramChart`, `SleepStageLegendGrid`, `SleepStagesInfoView`, `SleepStagesInfoHeader`, `YourStagesSection`, `ScoreImpactSection`), now in the shared repo. `SleepStagesSection` (DesignSystem) maps the session and owns the sheet. `stageColor(_:)` left the theme (orphaned); the `stage*Color` members stay.
- Fix, don't port (F26-T2): the score impact hard-coded the stage constants; the shared content reads `appConfig.sleepScoreConfig`. Same values today, so nothing visible changes.
- Open: the light recommendation text says 45–55% while the status band is 40–60%.
- F26-T3: 23 files deleted with the owner's approval: 10 interrupter views, `Models/Melody.swift`, the unused `MelodyGapsBannerView`, and the 11 catalog sounds in `sounds/` (now in `SleepMelodies`). The two sounds not in the catalog stay. `SnoreInterrupterSheet`, `MelodyPickerSheet` and `RecordCustomMelodySheet` are now thin hosts.
- Fix, don't port (F26-T3): the 11 melody names, the mode labels (`displayLabel`) and "My Sound N" were English-only. They are strings now. A recording someone already saved keeps its stored name.
- F26-T4: 6 page views deleted with the owner's approval; `OnboardingView` is the host. `docs/features/f1-onboarding.md` brought up to date (it described @AppStorage, a sheet route and an Open Settings button that are long gone).
- Fix, don't port (F26-T4): the Health page showed even with the `healthSync` flag off; it now follows the flag.
- Open: the onboarding string keys are named for other pages (page 1's body is `onboarding.page4.body`); the values are right, so they were left.
- Open: `RecordingDelayManager`'s notification text is English-only. The shared key `session.countdown.notificationBody` exists; using it from `Env` needs a layering decision (non-view code and `Strings`).
