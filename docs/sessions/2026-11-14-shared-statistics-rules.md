
### Completed
- F4-T2 (tracked in SleepGuardUIKitWay): Statistics' numbers come from the shared `SleepCore` rules (`NightDashboard`, `ScoreTrend`, `NightDay`/`NightDayStats`, `NightPeriod`, `CalendarMonth`). The views keep their types and look; their calculations are gone.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Models/Sources/Data/SleepSession+Night.swift` | `nightSummary` (reads events) and `summaryWithoutEvents` (cached fields only) |
| `Packages/Models/Tests/ModelsTests/NightSummaryMappingTests.swift` | New: both mappings |
| `Packages/Statistics/Sources/State/SleepSession+Statistics.swift` | New: choose nights without events, then build full summaries for those only |
| `Packages/Statistics/Sources/State/DashboardState.swift` | `make` calls `NightDashboard` and maps back to sessions |
| `Packages/Statistics/Sources/Views/WeekOverWeekTrendCalculator.swift` | Calls `ScoreTrend.weekOverWeek` |
| `Packages/Statistics/Sources/Views/Last7NightsDaySummary.swift`, `Last7NightsView.swift` | Day totals and best/worst from `NightDay` / `NightDayStats` |
| `Packages/Statistics/Sources/Views/TrendsView.swift` | Period stats and bar colours from `NightPeriod` |
| `Packages/Statistics/Sources/Views/CalendarView.swift`, `CalendarMonthStatsView.swift` | Grid, day lookup and month stats from `CalendarMonth` |
| `Packages/Statistics/Sources/Views/StatisticsMiniChartSection.swift` | Day averages from `NightDay` |
| `AGENTS.md`, `CLAUDE.md`, `docs/adr/0004-shared-repo.md`, `docs/TECHNICAL_OVERVIEW.md` | Statistics rules are shared; the two mappings |

### Technical Details
- Faulting `events` stays where it was: the dashboard and the trend use `summaryWithoutEvents`; Last 7 Nights, Trends and the calendar month build full summaries only for the nights they show (before, Last 7 Nights read every session's events).
- `NightSummary.loudestIntensity` (any event's loudest; `nil` without events) replaces the three in-view "max intensity" copies.

### Build Status
- All 8 package suites pass against the local shared checkout, no existing test changed (Models 80 with 3 new, Statistics 18). App builds through the dev workspace. Format, layering, view size: pass.
- Not checked on screen: Statistics with real data. The dashboard and trend are covered by the unchanged tests; Trends, the calendar and Last 7 Nights had no tests before.
- Bumped to shared `0.7.0` (`sh scripts/bump-shared.sh 0.7.0`, from `0.4.0`): all 8 suites pass and the project (release) builds.
