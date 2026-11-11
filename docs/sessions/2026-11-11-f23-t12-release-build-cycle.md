---
date: 2026-11-11
feature: F23
branch: feature/f23/t12-release-build-cycle
title: F23-T12 Fix the Release build cycle
---

### Completed
- F23-T12: the app builds in Release again, so Archive works. CI now builds Release.

### Technical Details
- "Cycle inside SleepGuard": the Crashlytics script (which needs the dSYM) ran before the widget was embedded. Release-only, because Debug produces no dSYM. Moved Crashlytics to the last phase, as Firebase requires.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard.xcodeproj/project.pbxproj` | ±1 | Crashlytics phase last |
| `.github/workflows/tests.yml` | +4 | App job builds Release |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | T12 Done |

### Architecture Decisions
- CI builds Release rather than Debug: that's what ships.

### Build Status
- Release: BUILD SUCCEEDED (widget embedded, dSYM present). Debug: 0 warnings.

### Suggested Branch
`feature/f23/t12-release-build-cycle`

### Suggested Commit
`F23-T12 — Fix the Release build cycle (Crashlytics phase last); CI builds Release`

### Changes done
- See Files Changed.

### Next Session
- F23-T9 raw-log streaming.

### Open Questions
- None.
