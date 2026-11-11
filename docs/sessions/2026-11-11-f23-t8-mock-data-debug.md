---
date: 2026-11-11
feature: F23
branch: feature/f23/t8-mock-data-debug
title: F23-T8 MockDataGenerator Debug-only
---

### Completed
- F23-T8: `MockDataGenerator` is compiled only in Debug builds.

### Technical Details
- The file is wrapped in `#if DEBUG`; its three callers already were.
- While verifying in Release, found that the app target's Release build has a dependency cycle (the Crashlytics script runs before the widget is embedded). Logged as T12.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/MockDataGenerator.swift` | +3 | `#if DEBUG` |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | T8 Done; T12 added |

### Architecture Decisions
- None.

### Build Status
- Env and Settings: Release BUILD SUCCEEDED. App: Debug build 0 warnings. App Release: fails on the pre-existing cycle (T12).

### Suggested Branch
`feature/f23/t8-mock-data-debug`

### Suggested Commit
`F23-T8 — MockDataGenerator Debug-only`

### Changes done
- See Files Changed.

### Next Session
- F23-T12 Release build cycle.

### Open Questions
- None.
