
### Completed
- F25-T2: the dashboard, Trends, Calendar and Last 7 Nights host the shared screen content.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/DesignSystem/Package.swift`, `Sources/Strings.swift` | Depends on and re-exports `SleepGuardContentKit` |
| `Packages/Statistics/Sources/State/DashboardState.swift` | Carries `NightDashboard` and `now` |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | Header + `StatisticsDashboardContent` (sleep stages in the slot) + Start Recording |
| `Packages/Statistics/Sources/Views/StatisticsDashboardView.swift` | "See all" route as a closure |
| `Packages/Statistics/Sources/Views/StatisticsEmptyView.swift` | Header + `StatisticsEmptyContent` |
| `Packages/Statistics/Sources/Views/{TrendsView,CalendarView,Last7NightsView}.swift` | `@Query`, toolbar and night choice stay; content shared |
| Package manifests, `Package.resolved` | Shared `0.17.0` |
| Deleted (approved): `StatisticsWeekSelector`, `StatisticsStatsGrid`, `StatisticsMiniChartSection`, `TrendsStatsGrid`, `CalendarMonthStatsView`, `CalendarSelectedNightView`, `Last7NightsDaySummary`, `Last7NightsStatGrid`, `WeekOverWeekTrendCalculator`, `Tests/WeekOverWeekTrendCalculatorTests` | Now shared, or SleepCore directly |

### Build Status
- Against the local shared checkout: all 8 suites pass (Statistics 11: the trend wrapper's tests went with it), the workspace app builds (after a clean: the new product needed a fresh build graph), layering, view size, format pass.
- Bumped to shared `0.17.0`: all suites pass against the release, the pinned app builds, layering passes.
- Not checked on screen: the morning briefing sheet covers the app at launch.

### Open Questions
- Approved: calendar selected-night line is now localized ("62 out of 100").
