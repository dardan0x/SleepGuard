---
date: 2026-11-05
feature: f19
branch: factory-reformat
title: Factory DI Migration — Plan & Branch Scaffolding
---

### Completed
- F19-T0: Factory DI migration planned. Researched [hmlongco/Factory](https://github.com/hmlongco/Factory) (v3.5.2): SwiftUI-first (`@Injected`/`@InjectedObservable`, preview mocking), Swift 6 strict-concurrency-ready (Xcode 26/27, `@MainActor` factories, nonisolated `dependency()` function), fits modular package layout (container registrations centralized in Env). Verdict: adopt via phased migration.
- F19-T0: Branch scaffolding. Base branch `factory-reformat` created from `main` (holds plan + docs). Five task branches created: `feature/f19/t1-factory-foundation`, `t2-statistics-pilot`, `t3-ui-packages-migration`, `t4-service-composition`, `t5-watch-docs-rules`. PRs target `factory-reformat`; final merge of `factory-reformat` → `main` after all 5 PRs.

### Technical Details
- Migration surface measured: 20 `@MainActor @Observable` `.shared` singletons in `Packages/Env/Sources/Services/`; 163 `@Environment(X.self)` occurrences across 109 view files; wiring via `withAppDependencyGraph(11 params)` + `withEnvironments()` (6 sheet call sites).
- Scope mapping: `.singleton` ≡ `.shared`; `RouterPath` stays per-instance (Factory default `.unique` scope).
- ModelContext intentionally untouched — stays on SwiftUI `.modelContext` environment, passed as parameter to helpers.
- T4 will move hand-wired internals (e.g. `SessionManager`'s `SessionRecordingController` + `RealtimeDetectionTracker`) into container factories; nonisolated Apple delegates use Factory's global `dependency(\.…)` function per `docs/architecture/concurrency.md`.
- Known approved deviation: `AGENTS.md` DI rules ("All dependencies flow through `@Environment`") get rewritten in T5 — flagged to and approved by user.

### Incident: feature-number collision
- Initially registered as F18; discovered `feature/f18/*` branches + `docs/plans/view-restructuring.md` already occupy F18 (view-restructuring, not yet in tracker table — pre-existing gap).
- Renumbered everything to F19 before any code landed: `git mv` tracker file, sed F18→F19 across tracker, amended the single base commit (`0e64be7`), force-pushed `factory-reformat` (safe: branch minutes old, single commit), deleted + recreated the 4 task branches that had been pushed under the wrong number. The pre-existing view-restructuring branches were untouched.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `docs/trackers/f19-factory-di.md` | +222 | New feature tracker: research summary, migration strategy, 5 tasks with acceptance criteria, branch/PR links |
| `docs/FeatureTracker.md` | +5/-5 | Registered F19 row, dashboard counts (Total 110, Backlog 21, 81%), activity log entry, Currently Active = F19-T1 |

### Architecture Decisions
- **Factory over status quo**: eliminates 11-param wiring + sheet environment re-injection; adds compile-time-safe registrations, preview mocking, per-test overrides. Cost: 109 files mechanical migration — accepted, phased per package.
- **Base-branch PR flow**: `factory-reformat` accumulates 5 reviewed PRs before one merge to `main` — requested by user for steady, reviewable rollout.
- **Registrations centralized in Env** (not per-feature-package container extensions): all 20 services live in Env today; per-module splitting remains possible later (Factory supports it).

### Build Status
- Not applicable — docs + git scaffolding only, no code changes.

### Suggested Branch
`factory-reformat` (docs commit already pushed)

### Suggested Commit
`[F19-T0] — Factory DI migration plan` (already committed as `0e64be7`)

### Changes done
```
- docs/trackers/f19-factory-di.md (new)
- docs/FeatureTracker.md (F19 registered)
```

### Next Session
- F19-T1 (`feature/f19/t1-factory-foundation`): add Factory package to Env, create Container extension registering all 20 services, zero view changes, build green.
- Then F19-T2 (`feature/f19/t2-statistics-pilot`): Statistics package `@Environment` → `@Injected` pilot; user reviews pilot PR before T3 fans out.

### Open Questions
- T5: migrate the Watch app target (4 files, self-contained) or document a skip? Decide when T5 starts.
- Pre-existing gap (noted, not fixed): view-restructuring feature occupies F18 branches/plan but is missing from `docs/FeatureTracker.md` — renumber or register it when that work resumes to avoid future collisions.
