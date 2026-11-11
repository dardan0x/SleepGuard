---
date: 2026-11-11
feature: F22
branch: feature/f22/t16-unused-routerpath
title: F22-T16 Remove unused RouterPath environment reads
---

### Completed
- F22-T16: removed `@Environment(RouterPath.self) private var routerPath` from the two views that never used it, `RecordingsListView` and `CalendarView`.

### Technical Details
- Audited all 15 `routerPath` declarations. The other 13 are used.
- Both leftovers date from `d4477ae`, when navigation moved into `NightGroupRowView` / `CalendarSelectedNightView`, which read the environment themselves.
- An unused environment read still traps when no `RouterPath` is provided (previews, bare sheets), so removing it also drops a needless requirement.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/RecordingsListView.swift` | −2 | Unused `routerPath` + `import Routing` |
| `Packages/Statistics/Sources/Views/CalendarView.swift` | −2 | Same |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md`, `docs/features/f22-architecture-hardening.md` | — | T16 added; F22 16/16 |

### Architecture Decisions
- None. `RouterPath` stays SwiftUI environment state (ADR 0001).

### Build Status
- Lint clean; layering and view-size checks pass; app build 0 warnings; Recordings 16 and Statistics 18 tests pass.

### Suggested Branch
`feature/f22/t16-unused-routerpath`

### Suggested Commit
`F22-T16 — Remove unused RouterPath environment reads`

### Changes done
- See Files Changed.

### Next Session
- User: real night on a device with `feature/f22-architecture-hardening` (T10), then merge into `main`.

### Open Questions
- None.
