---
date: 2026-11-11
feature: F23
branch: feature/f23/t7-package-resolved
title: F23-T7 Commit the app's Package.resolved
---

### Completed
- F23-T7: the app's `Package.resolved` is tracked, and CI builds the app from exactly those versions.
- F23 extended with T7–T11 (user choices after the review).

### Technical Details
- Force-added (its parent folders are ignored); `.gitignore` explains why. CI `app` job: `-disableAutomaticPackageResolution`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | +130 | Tracked |
| `.gitignore` | +3 | Comment |
| `.github/workflows/tests.yml` | +2 | Pinned resolution |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | T7 Done; T8–T11 added |

### Architecture Decisions
- Lockfile only for the app; library packages keep version ranges.

### Build Status
- Local build with `-disableAutomaticPackageResolution`: BUILD SUCCEEDED.

### Suggested Branch
`feature/f23/t7-package-resolved`

### Suggested Commit
`F23-T7 — Commit the app's Package.resolved; CI builds from it`

### Changes done
- See Files Changed.

### Next Session
- F23-T8 MockDataGenerator Debug-only.

### Open Questions
- None.
