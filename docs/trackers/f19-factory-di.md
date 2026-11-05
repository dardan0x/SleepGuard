# F19 — Factory DI Migration

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Version** | V3 |
| **Blocked By** | — |
| **Started** | 2026-11-05 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

Migrate SleepGuard from SwiftUI-environment-based dependency injection (`.shared` singletons wired through `withAppDependencyGraph()` / `withEnvironments()`) to container-based DI using [Factory](https://github.com/hmlongco/Factory). Eliminates the 11-parameter wiring function, the mandatory `.withEnvironments()` sheet re-injection, and unlocks compile-time-safe registrations, preview mocking, and per-test overrides.

## Research Summary

- **SwiftUI**: first-class. `@Injected` / `@InjectedObservable` property wrappers; `@Observable` services keep working (views observe injected references directly). Preview mocks via `Container.shared.x.register { Mock() }` or `.withContainer(\.x) { Mock() }`.
- **Swift Concurrency**: Factory 3.x supports Xcode 26/27 strict concurrency + Swift Testing. `@MainActor` factories match our isolation split. Nonisolated classes (Apple delegates per `concurrency.md`) use the global `dependency(\.…)` function.
- **Architecture fit**: all 20 services live in `Packages/Env` → one `Container` extension in Env, only Env imports FactoryKit initially. `.singleton` scope ≡ `.shared`. Feature packages add FactoryKit for view-level `@Injected` only (passes `check-layering.py`). ModelContext stays on SwiftUI's `.modelContext` environment, unchanged.
- **Known rule conflict**: `AGENTS.md` mandates "All dependencies flow through `@Environment`" — rewritten in F19-T5. Flagged and approved by user.

## Migration Strategy

Base branch: **`factory-reformat`** (created from `main`, holds this plan + docs). Each task gets a branch + PR into `factory-reformat`. After all 5 PRs merge, `factory-reformat` merges to `main`.

| Task Branch | PR into `factory-reformat` |
|-------------|---------------------------|
| `feature/f19/t1-factory-foundation` | https://github.com/dardan0x/SleepGuard/compare/factory-reformat...feature/f19/t1-factory-foundation?expand=1 |
| `feature/f19/t2-statistics-pilot` | https://github.com/dardan0x/SleepGuard/compare/factory-reformat...feature/f19/t2-statistics-pilot?expand=1 |
| `feature/f19/t3-ui-packages-migration` | https://github.com/dardan0x/SleepGuard/compare/factory-reformat...feature/f19/t3-ui-packages-migration?expand=1 |
| `feature/f19/t4-service-composition` | https://github.com/dardan0x/SleepGuard/compare/factory-reformat...feature/f19/t4-service-composition?expand=1 |
| `feature/f19/t5-watch-docs-rules` | https://github.com/dardan0x/SleepGuard/compare/factory-reformat...feature/f19/t5-watch-docs-rules?expand=1 |

Final merge to `main`: https://github.com/dardan0x/SleepGuard/compare/main...factory-reformat?expand=1 (only after all 5 PRs merge)

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F19-T1 | Factory foundation in Env | Infra | Done | — | Env | 2026-11-05 | 2026-11-05 |
| F19-T2 | Statistics package pilot | UI | Backlog | F19-T1 | Statistics | — | — |
| F19-T3 | Remaining UI packages migration | UI | Backlog | F19-T2 | SleepSession, Recordings, Settings, Personalization, Onboarding, Learn | — | — |
| F19-T4 | Service composition cleanup | Infra | Backlog | F19-T1 | Env | — | — |
| F19-T5 | Watch app, docs & rules rewrite | Docs | Backlog | F19-T3, F19-T4 | WatchApp + docs | — | — |

## Task Details

### F19-T1 — Factory foundation in Env

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/dependencies.md |
| Status | Done |
| Started | 2026-11-05 |
| Completed | 2026-11-05 |

**Acceptance Criteria:**
- [x] `Factory` package added to `Packages/Env/Package.swift` (import library `FactoryKit`)
- [x] `Container` extension in Env registers all services in the current DI graph (16 singletons + `RouterPath` unique) with correct scopes
- [x] `@MainActor` annotated on factories for MainActor-isolated services (non-isolated `SessionRawLogWriter`/`StorageLimitEnforcer` correctly bare)
- [x] All existing `.shared` singletons preserved — zero view/wiring changes
- [x] Builds with zero errors (verified twice; layering check green)

**Prompt Used:**
User: "go on with T1" — implement Factory foundation per F19 plan.

**Notes:**
- `Theme` registered in DesignSystem's own `Container` extension (not Env) — layering: Theme sits above Env. Multi-module pattern per Factory docs.
- Internal composition types (`SessionRecordingController`, `RealtimeDetectionTracker`, `SpeechDetector`, `SnoreDetector`) and non-service utilities (`MockDataGenerator`, `SessionFileCleanup`, `TabCoordinator`) intentionally not registered — nothing speculative; T4 adds composition when it has real call sites.
- PR #88 merged into `factory-reformat` (merge commit `8c837d4`).

---

### F19-T2 — Statistics package pilot

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/dependencies.md, docs/architecture/concurrency.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] FactoryKit added to `Packages/Statistics/Package.swift`
- [ ] All `@Environment(X.self)` swapped to `@Injected(\.x)` in Statistics views
- [ ] Statistics previews use `Container.shared.x.register { Mock() }` style where services are involved
- [ ] Verified on simulator: Statistics tab renders and reacts to service state
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
Pilot gates the fan-out: user reviews the pilot PR before T3 proceeds.

---

### F19-T3 — Remaining UI packages migration

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/dependencies.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] `@Environment(X.self)` → `@Injected(\.x)` in SleepSession, Recordings, Settings, Personalization, Onboarding, Learn (package-by-package order)
- [ ] FactoryKit added to each migrated package's Package.swift
- [ ] `withAppDependencyGraph()` call site in `SleepGuardApp.swift` removed; `@State` service holdings replaced
- [ ] `withEnvironments()` call sites removed (SettingsTab, StatisticsTab); `withAppDependencyGraph`/`withEnvironments` deleted from `AppRegistry.swift` when last consumer is gone
- [ ] Sheets present correctly without environment re-injection (verified on simulator)
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
`RouterPath` (`.unique` scope) injection in sheets keeps working — each injected site gets its own instance, same as today's `environment(RouterPath())`.

---

### F19-T4 — Service composition cleanup

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Internal hand-wired sub-components moved into container factories (e.g. `SessionManager`'s `SessionRecordingController` + `RealtimeDetectionTracker`) with init injection inside Env only
- [ ] Nonisolated classes (Apple delegates: WCSession, SNResultsObserving, AVAudioPlayerDelegate) use Factory's global `dependency(\.…)` function instead of property wrappers
- [ ] `dependency(\.…)` helper exposed from Env if needed to hide Factory from call sites
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
Depends only on T1 — can run in parallel with T2/T3.

---

### F19-T5 — Watch app, docs & rules rewrite

| Field | Value |
|-------|-------|
| Arch Ref | AGENTS.md, docs/architecture/dependencies.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Watch app target evaluated; migrated if low-risk (4 source files, self-contained) or documented skip
- [ ] `AGENTS.md` DI rules rewritten: `@Environment` dependency flow → `@Injected` container injection; `.shared` → container-owned singletons; sheet re-injection rule removed; `@MainActor` resolution rule added
- [ ] `docs/architecture/dependencies.md` rewritten to match
- [ ] `docs/features/f19-factory-di.md` feature doc created (files/routes/state tables)
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
The AGENTS.md rule rewrite is a deliberate, user-approved deviation from the original IceCubes-style rules.

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
