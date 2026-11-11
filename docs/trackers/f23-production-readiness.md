# F23 — Production Readiness

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Version** | V5 |
| **Blocked By** | — |
| **Started** | 2026-11-11 |
| **Completed** | — |
| **Feature Doc** | — |
| **Branch** | `feature/f23-production-readiness` (from `feature/f22-architecture-hardening`, which isn't in `main` yet; one sub-branch per task, `feature/f23/t#-slug`) |

## Summary

The "Do" list from the principal architecture review (`docs/ARCHITECTURE_REVIEW.md`, 2026-11-11). F22 made the structure solid; F23 makes the app safer to ship: one owner for saving a night (it fixes a likely clip-loss bug), the App Store privacy manifest, real logging, an audit of silent `try?`s, an app-target build in CI, and a way to measure detection accuracy. The "Consider" items wait for a measurement; the "Don't" list stays undone.

### Decisions (user, 2026-11-11)
- "ok lets go with your suggestions": follow the review's suggested order.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F23-T1 | One owner for committing a night (`SessionCommitter`) + low-battery clip-loss fix | Bug / Refactor | Done | — | Env / SleepSession / App | 2026-11-11 | 2026-11-11 |
| F23-T2 | App privacy manifest (`PrivacyInfo.xcprivacy`) | Compliance | Backlog | — | App | — | — |
| F23-T3 | CI: build the app target (app, widgets, Watch) | Infra | Backlog | — | .github | — | — |
| F23-T4 | `os.Logger` instead of `print` (+ signposts for session and event) | Infra | Backlog | — | all | — | — |
| F23-T5 | Audit `try?` on data paths | Quality | Backlog | F23-T4 | Env / AudioEngine / Recordings / App | — | — |
| F23-T6 | Detection accuracy evaluation on labelled real nights | Tooling | Backlog | User: real nights with raw logs | scripts / AudioEngine | — | — |

## Task Details

### F23-T1 — One owner for committing a night

| Field | Value |
|-------|-------|
| Arch Ref | ADR 0002; `docs/ARCHITECTURE_REVIEW.md` Do #1 |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] `SessionCommitting` protocol + `SessionCommitter` (Env): insert events + session, cache the score, save, then clear pending + checkpoint, then follow-ups (storage limits, HealthKit when enabled)
- [x] `SessionSummaryView` and `StatisticsTab`'s force-save both commit through it; the duplicated code is gone
- [x] Regression test: a `low_battery` session clears the pending record and the checkpoint (mutation-checked)
- [x] Fake + container registration + layering rule, per ADR 0002
- [x] Builds with zero errors; tests pass

**Prompt Used:**
"ok lets go with your suggestions"

**Notes:**
- **The bug (from code reading):** the force-save path saved the night but never cleared `PendingSessionStore` or the checkpoint. The pending record lists every event clip. At the next launch, the app either offered to "recover" an already-saved night (and discarding it deleted the clips), or ran `cleanupIfNeeded()` and deleted the clips straight away. Otherwise the next recording's `setPending` did the deletion. A recovered snapshot also keeps `terminationReason`, so a stale checkpoint could even be auto-saved again.
- `commit` is synchronous and throws. Nothing is cleaned up when the save fails, so the night stays protected. It returns the follow-up `Task` (storage limits, HealthKit), which callers ignore and tests await.
- Behavior change on the force-save path, on purpose: it now also enforces storage limits, as the normal save always did.
- Views lost 6 injections (`SessionSummaryView`) and the `healthKitSync` reference (`StatisticsTab`).
- Not tested: the save-failure path. An in-memory SwiftData store can't be made to fail its save, so `FakeSessionCommitter.error` covers the caller side instead.
- Simulator: recorded 2 min 24 s, stopped, Save Session → the dashboard shows the new night (Nov 11 20:07–20:10, cached score), and `session_recovery.json` is gone from the app container. The low-battery path can't be triggered on the simulator (battery level is -1); the unit test covers it.
- Tests: `SessionCommitterTests` (3 tests, 5 cases), plus a `ServiceOverrideTests` case and the default-resolution check. Mutation: removing the two clears fails the regression test for both `nil` and `low_battery`.

---

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)
