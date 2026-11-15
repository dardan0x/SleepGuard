
### Completed
- F24-T3b: Statistics draws with the shared kit's components: week strip, Trends picker, chart, legend and tiles, the calendar's header, grid, tiles and selected night, Last 7 Nights' bars, tiles and rows.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/DesignSystem/Sources/Components/SnoringLegendView.swift` | Deleted |
| `Packages/Statistics/Sources/Views/{TrendStatCard,TrendsChartSection,CalendarStatCard,CalendarGridView,CalendarDayHeaders,CalendarMonthSelector,Last7NightsChartCard,Last7NightsRow}.swift` | Deleted |
| `Packages/Statistics/Sources/Views/StatisticsWeekSelector.swift`, `StatisticsLoadedView.swift` | Kit `WeekStrip` from `DashboardState.week` |
| `Packages/Statistics/Sources/Views/TrendsView.swift`, `TrendsStatsGrid.swift` | Kit picker, chart, legend, tiles |
| `Packages/Statistics/Sources/Views/CalendarView.swift`, `CalendarMonthStatsView.swift`, `CalendarSelectedNightView.swift` | Kit header, grid, tiles, night card |
| `Packages/Statistics/Sources/Views/Last7NightsView.swift`, `Last7NightsStatGrid.swift`, `Last7NightsDaySummary.swift` | Kit bars, tiles, rows; unused fields removed |

### Technical Details
- The kit's calendar used a lighter colour for days with a night than SleepGuard; fixed in the kit (shared `0.13.0`), which also corrects SleepGuardUIKitWay.
- Visible change: Trends' tiles match Last 7 Nights' (approved).

### Build Status
- All 8 suites pass; app builds (against the local shared checkout); format, layering, view size pass.
- Bumped to shared `0.13.0`: all 8 suites pass and the project (release) builds. Not seen on screen yet.
