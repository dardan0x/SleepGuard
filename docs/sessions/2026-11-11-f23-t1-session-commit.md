---
date: 2026-11-11
feature: F23
branch: feature/f23/t1-session-commit
title: F23-T1 One owner for committing a night; low-battery clip-loss fix
---

### Completed
- F23 started from the principal architecture review (`docs/ARCHITECTURE_REVIEW.md`): 6 tasks.
- F23-T1: saving a finished night has one owner, `SessionCommitter` (Env). The summary sheet and the low-battery force-save both use it. This fixes a likely data-loss bug in the force-save path.

### Technical Details
- **Bug:** `StatisticsTab.autoSaveForceSavedSession` saved without `pendingSessionStore.clearPending()` / `sessionCheckpointStore.clear()`. The stale pending record (which lists every event clip) made the next launch or recording delete the saved night's clips. A stale checkpoint offered to "recover" the saved night again.
- `commit(_:in:) throws -> Task<Void, Never>`: insert events + session → cache the score → save → clear pending + checkpoint → follow-ups (storage limits; HealthKit if enabled). Nothing is cleaned up if the save throws.
- The F22 conventions apply: protocol in its own file, `Factory<any SessionCommitting>`, `FakeSessionCommitter`, `.shared` blocked in features by `check-layering.py`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/Session/SessionCommitting.swift` | +20 | New protocol |
| `Packages/Env/Sources/Services/Session/SessionCommitter.swift` | +60 | New service |
| `Packages/Env/Sources/Services/Container.swift` | +1 | `sessionCommitter` factory |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | −35 | Commits through the service; 6 injections removed |
| `SleepGuard/StatisticsTab.swift` | −20 | Force-save commits through the service |
| `Packages/Env/TestSupport/FakeSessionServices.swift`, `FakeStores.swift` | +20 | `FakeSessionCommitter`; `FakeStorageLimitEnforcer.enforceCount` |
| `Packages/Env/Tests/SessionCommitterTests.swift` | +90 | Regression + score cache + follow-ups |
| `Packages/Env/Tests/ServiceOverrideTests.swift` | +14 | Override + default resolution |
| `scripts/check-layering.py` | ±1 | `SessionCommitter` in the singleton rule |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | F23 created; T1 Done |
| `docs/ARCHITECTURE_REVIEW.md` | +170 | The review that F23 implements |

### Architecture Decisions
- `commit` is synchronous (the critical part) and returns the follow-up task, so views stay synchronous and tests can await the follow-ups.
- A separate service rather than a method on `SessionManager`: it needs SwiftData and six collaborators that the recording facade doesn't otherwise touch.

### Build Status
- Lint clean; layering and view-size checks pass; app build 0 warnings; Env 57 tests pass (mutation-checked).
- Simulator: recorded 2 min 24 s, stopped, Save Session → the dashboard shows the new night (Nov 11 20:07–20:10, cached score); `session_recovery.json` is gone from the app container.

### Suggested Branch
`feature/f23/t1-session-commit`

### Suggested Commit
`F23-T1 — SessionCommitter owns saving a night; fix low-battery clip loss`

### Changes done
- See Files Changed.

### Next Session
- F23-T2 privacy manifest, F23-T3 CI app build.

### Open Questions
- None.
