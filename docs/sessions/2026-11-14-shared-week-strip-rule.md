
### Completed
- F4-T3 (tracked in SleepGuardUIKitWay): the dashboard's week strip takes its days and dot levels from `SleepCore` (`NightDashboard.week(now:)`, `NightSummary.snoringLevel`: over 15% loud, over 5% light). The view keeps its labels and layout.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Statistics/Sources/State/DashboardState.swift` | Holds `week`, made with the dashboard |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | `weekDays` maps the shared week to labels and colours |
| `Packages/Statistics/Tests/DashboardStateTests.swift` | Week strip test |

### Build Status
- Statistics 19 (1 new), Models 80 pass against the local shared checkout; app builds through the workspace; format and layering pass.
- Bumped to shared `0.8.0`: all 8 suites pass and the project (release) builds.
