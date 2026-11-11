---
date: 2026-11-11
feature: F23
branch: feature/f22-architecture-hardening
title: F23-T13 Views take no services through init; refined DI rule
---

### Completed
- F23-T13: the 22 views that received `theme` through `init` now use `@Injected(\.theme)`. The DI rule now says why views use `@Injected` and that init injection is for testable non-view types.

### Technical Details
- Scripted conversion of the stored property and the explicit inits, plus the removal of the `theme:` argument at 41 call sites (balanced-paren parsing, so multi-line calls work). Fixed up by hand: `EventCard` (second struct in `EventsSheetView.swift`), `StatCard`'s default icon color (moved to `body`), and `CalendarMonthStatsView` (now-unused injection removed).
- `check-layering.py` rule 6 keeps services out of view `init`s.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| 12 DesignSystem components, 5 Recordings views, 5 Statistics views | ±1–4 each | `theme` via `@Injected`; init param removed |
| ~18 call-site files across packages and `SleepGuardWidgets/` | −1 per call | `theme:` argument removed |
| `scripts/check-layering.py` | +8 | Rule 6 |
| `AGENTS.md`, `CLAUDE.md` | ±2 | Refined DI rule with its reason |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | T13 Done |

### Architecture Decisions
- Views: `@Injected`. Non-view types with logic worth testing: init injection with container defaults. The test seam goes where the tests are.

### Build Status
- Lint, layering (rule 6 probed), view-size and hardcoded-strings checks pass; all 8 package suites pass; app + widget build 0 warnings; dashboard and Sessions unchanged on the simulator.

### Suggested Branch
`feature/f22-architecture-hardening` (direct, per user)

### Suggested Commit
`F23-T13 — Views take no services through init; refined DI rule`

### Changes done
- See Files Changed.

### Next Session
- User: force-push the rewritten branches (they now also need this commit), real night, merge into `main`.

### Open Questions
- None.
