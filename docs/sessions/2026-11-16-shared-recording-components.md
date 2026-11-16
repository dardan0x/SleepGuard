
### Completed
- F7-T5a (tracked in SleepGuardUIKitWay): the recording screens' presentational pieces now come from the shared kit, and `SleepSession.minimumSaveDuration` from `SleepCore`'s `Night.minimumSaveDuration`.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | `PrestartHeader(compact:)`, `PrestartTipsCard` from the kit |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | `BedsideEventsBadge`, `BedsideClockFace`, `BedsideRecordingStatus`, `BedsideSnoreStatus` from the kit; its formatting helpers removed |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | `SessionSummaryHeader`, `SessionSummaryActions` from the kit |
| `Packages/DesignSystem/Sources/Components/SleepGuardKitAdapters.swift` | `SessionSummaryHeader(session:scoreConfig:)` |
| `Packages/Models/Sources/Data/SleepSession.swift` | `minimumSaveDuration` forwards to SleepCore (same values) |
| Deleted (approved): `PrestartHeaderView`, `PrestartTipsSection`, `PrestartTipRow`, `BedsideClockBadgesView`, `BedsideClockClockView`, `BedsideClockWaveformView`, `BedsideClockStatusView`, `SessionSummaryStats`, `SessionSummaryActions` | Now in the kit |
| Package manifests, `Package.resolved` | Shared `0.16.0` |

### Technical Details
- Same layout and values. The kit draws from the theme's palette, so the tips glow uses `scoreRed` (same `#FF453A`). The prestart title may now wrap instead of truncating on narrow widths.
- The bedside meter ripples with the once-a-second clock instead of `Date()` at each render; it still follows the level as it changes.

### Build Status
- The app builds against the local shared checkout (workspace); layering, view size and format pass.
- Bumped to shared `0.16.0`: all 8 suites pass, the pinned app builds, layering passes.
- Not checked on screen: `sleepguard://start` opens under the morning briefing sheet, which needs a tap to close. Check the prestart, bedside clock and summary by hand once.
