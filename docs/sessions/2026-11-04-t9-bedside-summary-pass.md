---
date: 2026-11-04
feature: f18
branch: feature/f18/t9-bedside-summary-pass
title: F18-T9 BedsideClock + SessionSummary Pass
---

### Completed
- **F18-T9**: BedsideClockView (251 → 156) + SessionSummaryView (241 → 105)
  split, on branch `feature/f18/t9-bedside-summary-pass` (commit `92b5e13`),
  pushed. With this task, every P0–P2 oversized view is under the 200-line
  limit.

### Technical Details
- `BedsideMelodyDisclaimer` / `BedsideMelodyOverlay` (new): Snore
  Interrupter banner + playing overlay extracted from the bedside clock;
  `melodyName` injected (the nil-fallback `"Melody"` literal stays at the
  call site, flagged as a localization gap for a future sweep).
- BedsideClockView: unused `soundAnalysisDetector` environment dropped
  (never referenced in the file); 4-space → 2-space.
- `SessionSummaryStats` (header + gauge + stat cards),
  `SessionSummaryActions` (glowing save capsule + discard),
  `SessionSummaryTimeline` extracted from the summary screen.
- Save/discard orchestration stays in SessionSummaryView: the
  cache-after-insert SwiftData flow is project-documented (AGENTS.md) and
  tied to screen flow (alerts, dismiss, HealthKit task dispatch).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | −251/+156 | Melody UI extracted, 2-space |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | −241/+105 | Sections extracted |
| `Packages/SleepSession/Sources/Views/BedsideMelody{Disclaimer,Overlay}.swift` | +110 (new) | Melody banner + overlay |
| `Packages/SleepSession/Sources/Views/SessionSummary{Stats,Actions,Timeline}.swift` | +160 (new) | Three summary sections |

### Build Status
- **BUILD SUCCEEDED** first try, zero warnings; layering check green (204 files).

### Suggested Branch
`feature/f18/t9-bedside-summary-pass` (pushed)

### Suggested Commit
`92b5e13` — `[F18-T9] — BedsideClockView + SessionSummaryView pass (251 + 241 → 159 + 118)`

### Next Session
- User merges T8 + T9, then P3 tasks: T10 computed-`some View` sweep,
  T11 enum-sheet sweep, T12 shared ViewState, T13 performance pass.

### Open Questions
- `"Melody"` fallback literal in BedsideClockView (pre-existing, unlocalized)
  — fix in the T11 localization-adjacent sweep?
