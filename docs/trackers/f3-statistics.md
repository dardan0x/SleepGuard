# F3 — Statistics Dashboard

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P1 |
| **Version** | V1.0 |
| **Blocked By** | — |
| **Started** | 2026-05-06 |
| **Completed** | 2026-05-06 |
| **Feature Doc** | [features/f3-statistics.md](features/f3-statistics.md) |

## Summary

Last night's summary card with sleep score (0-100), duration, snoring percentage, average/peak dB, events count, and events per hour. Also shows a last-7-nights mini chart and a prominent "Start Recording" CTA.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F3-T1 | StatisticsDashboardView (empty + loaded) | UI | Done | F2-T2 | Statistics | 2026-05-06 | 2026-05-06 |
| F3-T2 | Score gauge + stat cards components | UI | Done | F3-T1 | Statistics | 2026-05-06 | 2026-05-06 |
| F3-T3 | "Start Recording" CTA + routing | UI | Done | F3-T1 | Statistics | 2026-05-06 | 2026-05-06 |

## Task Details

### F3-T1 — StatisticsDashboardView (empty + loaded)

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/feature-template.md, docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] `StatisticsDashboardView` with `ViewState` enum: `.empty`, `.loaded(session:)`, `.error`
- [x] Empty state shows friendly illustration + "Start Recording" CTA
- [x] Loaded state fetches most recent `SleepSession` from SwiftData via `@Query`
- [x] Container view loads data; child views are presentational
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly.

**Notes:**
- Container view (`StatisticsDashboardView`) uses `@Query(sort: \.startDate, order: .reverse)` to fetch latest session
- Child views are purely presentational: `StatisticsEmptyView`, `StatisticsLoadedView`, `StatisticsErrorView`
- `ViewState` includes `.loading` for initial transition before `@Query` populates
- `.onChange(of: sessions)` triggers state reload when SwiftData updates (e.g., after saving a new session)
- Loaded state shows basic last-night card with score, date, duration, snoring %, events, avg dB. Detailed gauge/sparkline deferred to F3-T2

---

### F3-T2 — Score gauge + stat cards components

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] Circular score gauge (0-100) with color coding
- [x] Stat cards: duration, snoring %, avg dB, peak dB, events count, events/hour
- [x] Last 7 nights mini sparkline chart
- [x] All components are presentational (receive data via init)
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly.

**Notes:**
- `SleepScoreGauge`: Circular ring with `trim(from:to:)`, animated score fill, color-coded (green/orange/red), receives `score`, `theme`, `size` via init
- `StatCard`: Icon + value + label card with `theme.surfaceColor` background, receives `icon`, `title`, `value`, `theme`, `iconColor` via init
- `SleepSparkline`: Swift Charts `LineMark` + `AreaMark` with gradient fill, 0-100 Y scale, weekday labels on X axis, receives `[DataPoint]` and `theme` via init
- `StatisticsLoadedView` rewritten with score gauge card, 6 stat cards in 2-column grid, and conditional sparkline card
- `ViewState.loaded` now carries `recentSessions: [SleepSession]` so sparkline has data without additional queries

---

### F3-T3 — "Start Recording" CTA + routing

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/navigation.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] Prominent "Start Recording" button in both empty and loaded states
- [x] Tapping navigates to Live Session pre-start screen via `routerPath.navigate(to:)`
- [x] Button styled in DesignSystem theme
- [x] Builds with zero errors

**Prompt Used:**
Resume SleepGuard. Read AGENTS.md, docs/FeatureTracker.md, docs/SESSION_SUMMARY.md, docs/ProjectArchitecture.md, and the active feature tracker from docs/trackers/. Report state including which architecture doc the feature tracker references, then proceed with the next unblocked task following the workflow exactly.

**Notes:**
- Converted `.liveSession` from `SheetDestination` to `RouterDestination` to satisfy `routerPath.navigate(to:)` acceptance criteria
- `SleepSessionView` hides navigation bar via `.toolbar(.hidden, for: .navigationBar)` since it's a full-screen recording experience
- `MainTabView.onChange(of: sessionManager.completedSession)` now calls `routerPath.navigateToRoot()` before presenting `.sessionSummary` sheet, ensuring the pushed live session is popped
- Onboarding routing updated: `StatisticsTab.onAppear` now uses `routerPath.navigate(to: .liveSession)` instead of `routerPath.presentedSheet = .liveSession`

---

### Session 41 Refinements (2026-05-14)

- **Last 7 Nights dedicated screen**: New `Last7NightsView` matching design node fuq0d. Custom nav bar ("Stats" back button + "Last 7 Nights" title + share icon). Date range header + large avg sleep score + week-over-week trend indicator. Snoring minutes bar chart with intensity-based colors. 2×2 stat grid (AVG SNORING, TOTAL EVENTS, BEST, WORST). ALL NIGHTS list with score circles, day/date, duration, and snoring time.
- **New route `.last7Nights`**: Added to `RouterDestination`; `AppRegistry` maps it to `Last7NightsView`. `StatisticsMiniChartSection` now navigates directly via `@Environment(RouterPath.self)` instead of closure prop-drilling.
- **Reusable components**: `Last7NightsChartCard`, `Last7NightsStatGrid`, `Last7NightsRow`, `Last7NightsDaySummary`, `WeekOverWeekTrendCalculator` — all under 200 lines.
- **Duration format fix**: `Last7NightsRow` and `Last7NightsStatGrid` now use `%d h %d min` / `%d min` format matching `NightGroupRowView`.

### Session 28 Refinements (2026-05-07)

- **Day-average score on main gauge**: `StatisticsDashboardView` now computes `dayScore` (average of all recordings on the same day) and `daySessionCount`. The gauge shows the average, and the label shows `"3 RECORDINGS"` when multiple exist.
- **"Last 7 Nights" chart grouped by day**: Chart now groups `recentSessions` by calendar day, averages scores per day, and renders one bar per night instead of one bar per recording.
- **Removed dB stat cards**: Peak dB and Avg Level cards removed from `StatisticsLoadedView` and `SleepReportPDFGenerator` because negative dBFS values are confusing to users.

### 2026-07-04 Refinements

- **"Last night" label gate**: `StatisticsLoadedView` now shows `LAST NIGHT` only when the selected session started on the previous calendar day; otherwise it shows `LAST TIME`. This prevents inaccurate wording when reopening the app after a gap.

### Session 57 Refinements (2026-05-24)

- **Duration format unification**: `Last7NightsStatGrid` and `Last7NightsRow` now use shared `DurationFormatter.hoursAndMinutes` instead of private `durationString` wrappers. Total sleep duration and snoring duration both render as `X h Y min` / `X min`.

### Session 48 Refinements (2026-05-17)

- **Start Recording CTA `@MainActor` fix**: `StatisticsEmptyView`, `StatisticsLoadedView`, and `StatisticsDashboardView` now propagate `@MainActor` through the `onStartRecording` closure type. This eliminates a UI glitch where tapping the Start Recording button caused a frame drop due to navigation state mutation off the main actor.

### Session 29 Refinements (2026-05-08)

- **CalendarView nav title**: Principal toolbar item now shows a dark `surface2` pill with calendar icon + "Calendar" text in `accent`, matching design screenshot.
- **Calendar day cell backgrounds**: Dates with recorded events get `surface2` rounded background (`radiusSmall`); empty dates stay transparent. Grid spacing increased to 8pt.
- **Calendar today/selected highlight**: Full cell `accent` background with white text and white dot. Removed old green circle indicator behind number.
- **Calendar intensity dots**: Size increased 4→5pt. White dot when cell is highlighted (today/selected), otherwise uses snoring intensity color.
- **SleepScoreGauge size**: Statistics gauge increased from 90→120.
- **Calendar button consistency**: Statistics header Calendar buttons (loaded + empty) now use same dark pill style instead of blue accent pill.

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)
