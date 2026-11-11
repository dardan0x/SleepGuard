---
date: 2026-11-11
feature: F23
branch: feature/f23/t3-ci-app-build
title: F23-T3 CI builds the app target
---

### Completed
- F23-T3: a new `app` job in `tests.yml` builds the SleepGuard scheme (app + widget extension) on every PR.

### Technical Details
- Generic iOS Simulator destination, `CODE_SIGNING_ALLOWED=NO`, its own derived data; the job fails unless `** BUILD SUCCEEDED **` is in the log, which is uploaded on failure.
- Verified locally from a cold derived-data folder.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `.github/workflows/tests.yml` | +30 | `app` job |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | T3 Done |

### Architecture Decisions
- Same workflow as the package tests (PRs + manual), as a parallel job.

### Build Status
- Local cold build: BUILD SUCCEEDED, 3 asset warnings (pre-existing).

### Suggested Branch
`feature/f23/t3-ci-app-build`

### Suggested Commit
`F23-T3 — CI builds the app target`

### Changes done
- See Files Changed.

### Next Session
- F23-T4 os.Logger.

### Open Questions
- Fix the iPad icon / AccentColor warnings, or make the app iPhone-only?
- Commit `Package.resolved` so CI and local builds use the same dependency versions?
