
### Completed
- F26-T2: The sleep stages card and the info sheet host the shared content; the stage rules come from SleepCore.

### Technical Details
- `SleepStagesSection` (DesignSystem) maps a `SleepSession`'s stages to SleepCore's `SleepStageBreakdown`, shows the shared `SleepStagesCard` and owns the info sheet (`SleepStagesInfoContent`). Used on the session detail and the statistics dashboard, where `SleepStageBreakdownView` was.
- Stage statuses (good / low / high) and the score impact now come from `SleepStageBreakdown`, with `appConfig.sleepScoreConfig`: the old score impact hard-coded the stage constants, so remote config didn't reach it. Same values today, nothing visible changes.
- Fetching stages is unchanged (`SessionDetailModel`, `HealthKitSync`).
- Mirrors SleepGuardUIKitWay's F8-T3, which shows the same content.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/DesignSystem/Sources/Components/SleepStagesSection.swift` | New: maps the session, hosts the shared card and sheet |
| `Packages/Recordings/Sources/Views/SessionDetailLoadedView.swift` | Uses `SleepStagesSection` |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | Uses `SleepStagesSection`; reads `appConfig` |
| `Packages/DesignSystem/Sources/Components/{ThemeProviding,AppTheme}.swift` | `stageColor(_:)` removed (orphaned) |
| 7 deleted files (approved) | Moved to the shared repo |
| `docs/trackers/f26-shared-settings-content.md`, `docs/FeatureTracker.md` | F26-T2 |

### Build Status
- App builds on the local shared checkout; layering and view-size checks pass; every package suite passes on the local checkout. Re-run on the 0.23.0 release: every package suite passes and the app builds.

### Open Questions
- The light recommendation text says 45–55% while the status band is 40–60%. The recommendation texts are fixed, so they'd drift if remote config moved the targets.
