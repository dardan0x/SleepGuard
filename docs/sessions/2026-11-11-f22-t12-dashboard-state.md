---
date: 2026-11-11
feature: F22
branch: feature/f22/t12-dashboard-state
title: F22-T12 DashboardState pure mapping
---

### Completed
- F22-T12: the Statistics dashboard's session-to-state mapping is a pure function, `DashboardState.make(from:now:calendar:)`, with 10 tests.

### Technical Details
- No SwiftUI, SwiftData query or clock inside the function. The view passes `@Query` results and `Date()`.
- `isLastNight` moved out of `StatisticsLoadedView`, so the "LAST NIGHT / LAST TIME" label is testable.
- `StatisticsLoadedView` takes one `state: DashboardState` instead of four values.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Statistics/Sources/State/DashboardState.swift` | +36 | New pure mapping |
| `Packages/Statistics/Sources/Views/StatisticsDashboardView.swift` | −15 | `loadState()` is one line; `ViewState.loaded(DashboardState)` |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | ±10 | Reads from `state` |
| `Packages/Statistics/Tests/DashboardStateTests.swift` | +110 | 10 tests |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T12 Done, 9/14 |

### Architecture Decisions
- Kept behavior identical, including the start-date rule for "last night". Changing what counts as a night is a product decision.

### Build Status
- Lint clean, layering passed, all 8 package suites pass (Statistics 18), app build 0 warnings, dashboard unchanged on the simulator.

### Suggested Branch
`feature/f22/t12-dashboard-state`

### Suggested Commit
`F22-T12 — DashboardState pure mapping + tests`

### Changes done
- See Files Changed.

### Next Session
- F22-T13 CI 200-line view check, then T8.

### Open Questions
- Should "last night" mean a sleep window (e.g. started between 18:00 yesterday and 06:00 today) instead of the start date? Today a 00:30 bedtime shows "LAST TIME".
