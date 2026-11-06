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
| F19-T2 | Statistics package pilot | UI | Done | F19-T1 | Statistics | 2026-11-05 | 2026-11-05 |
| F19-T3 | Remaining UI packages migration | UI | Done | F19-T2 | SleepSession, Recordings, Settings, Personalization, Onboarding, Learn | 2026-11-05 | 2026-11-05 |
| F19-T4 | Service composition cleanup | Infra | Done | F19-T1 | Env | 2026-11-05 | 2026-11-05 |
| F19-T5 | Watch app, docs & rules rewrite | Docs | Done | F19-T3, F19-T4 | WatchApp + docs | 2026-11-05 | 2026-11-05 |

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
| Status | Done |
| Started | 2026-11-05 |
| Completed | 2026-11-05 |

**Acceptance Criteria:**
- [x] FactoryKit added to `Packages/Statistics/Package.swift`
- [x] All `@Environment(X.self)` swapped to `@Injected(\.x)` in Statistics views (17 Theme sites)
- [x] Statistics previews use `Container.shared.x.register { Mock() }` style where services are involved — **vacuous: no `#Preview` blocks exist in Statistics**
- [x] Verified on simulator: Statistics tab renders (empty + loaded states) and Calendar push via environment RouterPath works
- [x] Builds with zero errors

**Prompt Used:**
User: "go with next task T2" — convert Statistics per F19 plan; pilot gates T3 fan-out.

**Notes:**
- **Pilot finding (applies app-wide): `RouterPath` stays `@Environment`.** Factory `.unique` scope would orphan navigation paths; `.shared`'s weak cache dies with the first requesting view. Tab-owned navigation stacks need environment propagation. T3 consequence: `withAppDependencyGraph`/`withEnvironments` shrink to RouterPath-only — they don't disappear.
- "Reacts to service state" demonstrated via RouterPath navigation; live theme switching not demonstrable (build hardcodes Always Dark; Settings Theme row is display-only — pre-existing).
- PR #89 merged into `factory-reformat`.

---

### F19-T3 — Remaining UI packages migration

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/dependencies.md |
| Status | Done |
| Started | 2026-11-05 |
| Completed | 2026-11-05 |

**Acceptance Criteria:**
- [x] `@Environment(X.self)` → `@Injected(\.x)` in SleepSession, Recordings, Settings, Personalization, Onboarding, Learn (package-by-package order)
- [x] FactoryKit added to each migrated package's Package.swift (6 packages)
- [x] `withAppDependencyGraph()` call site in `SleepGuardApp.swift` removed; `@State` service holdings replaced
- [x] `withAppDependencyGraph`/`withEnvironments` deleted from `AppRegistry.swift`; `withEnvironments()` shrank to RouterPath-only injection at the two remaining call sites
- [x] Sheets present correctly without environment re-injection (verified on simulator — briefing sheet, melody picker, snore interrupter)
- [x] Builds with zero errors (verified twice; layering check green)

**Prompt Used:**
User: "continue with T3" — fan out the T2 pilot pattern to the remaining UI packages.

**Notes:**
- 91 views converted across 7 packages (Statistics pilot + 6 in this task). `TabCoordinator` gained `public static let shared` + `.singleton` registration — LearnTab consumed it via environment before.
- `RouterPath` stays `@Environment` throughout (pilot finding from F19-T2): Factory scopes cannot model tab-owned navigation paths. `withEnvironments()` survives as RouterPath-only injection for sheets.
- App target holds `.shared` references directly (composition-root style) — FactoryKit not added to app target pbxproj.
- Leftovers for T5 consideration: dead `.environment(tabCoordinator)` in `MainTabView.swift:32`; hardcoded DEBUG `Button("Debug Config")` in `SettingsView.swift:46`; direct `.shared` accesses in view closures (e.g. `UserPreferences.shared` in StatisticsTab, `HapticManager.shared`) that could optionally become `@Injected`.
- PR #90 merged into `factory-reformat` (merge commit `dbac3ab`).

---

### F19-T4 — Service composition cleanup

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Done |
| Started | 2026-11-05 |
| Completed | 2026-11-05 |

**Acceptance Criteria:**
- [x] Internal hand-wired sub-components moved into container factories (`SessionManager`'s `SessionRecordingController` + `RealtimeDetectionTracker`) with init injection inside Env only
- [x] Nonisolated classes (Apple delegates) use `dependency(\.…)` — **vacuous: verified all three delegate classes (WCSession, SNResultsObserving, AVAudioPlayerDelegate) access no other service from nonisolated code** — they parse payloads synchronously and hop via `Task { @MainActor in }` to own state only. No call sites exist; nothing speculative added
- [x] `dependency(\.…)` helper exposed — **not needed** (conditional on previous criterion)
- [x] Builds with zero errors (verified twice; layering check green)

**Prompt Used:**
User: "continue" — T4 after T3 merge (PR #90).

**Notes:**
- **Finding: `@Observable` + `@Injected` collide** — both macros synthesize underscore backing storage → "invalid redeclaration of synthesized property" compile error. `@Observable` classes must resolve via `Container.shared.x()` in init. Rule lands in T5's AGENTS.md rewrite.
- `SpeechDetector`/`SnoreDetector` (AudioEngine `.shared`) intentionally not containerized — FactoryKit in the core package for two internal call sites is unjustified.
- **Pre-existing issue flagged:** starting a recording in the simulator crashes (EXC_BREAKPOINT in `installTap`, AVFAudio realtime thread) — reproduced identically on the unmodified `factory-reformat` baseline, even with mic permission granted. Not a T4 regression; needs separate investigation or on-device verification.
- PR #91 merged into `factory-reformat` (merge commit `c033305`).

---

### F19-T5 — Watch app, docs & rules rewrite

| Field | Value |
|-------|-------|
| Arch Ref | AGENTS.md, docs/architecture/dependencies.md |
| Status | Done |
| Started | 2026-11-05 |
| Completed | 2026-11-05 |

**Acceptance Criteria:**
- [x] Watch app target evaluated — **documented skip**: no package structure, one self-contained singleton (`WatchSessionManager.shared`) accessed twice; FactoryKit would require watch-target pbxproj edits for zero gain (also noted in f17 follow-up)
- [x] `AGENTS.md` DI rules rewritten: `@Environment` dependency flow → `@Injected` container injection; `.shared` → container-owned singletons; sheet re-injection rule removed (RouterPath-only exception); `@MainActor` resolution rules added (incl. `@Observable`+`@Injected` macro collision from T4). `CLAUDE.md` + both templates synced
- [x] `docs/architecture/dependencies.md` rewritten to match (plus rules.md, INDEX, overview, state, views, feature-template, navigation, PROMPTS — those are gitignored local docs)
- [x] `docs/features/f19-factory-di.md` feature doc created (files/state/edge-cases tables)
- [x] Builds with zero errors; layering check green

**Prompt Used:**
User: "continue" — T5 after T4 merge (PR #91).

**Notes:**
- T3 orphan closed: dead `.environment(tabCoordinator)` removed from `MainTabView.swift`.
- T3 leftovers documented in feature-doc follow-up (not migrated): direct `.shared` in view closures (`UserPreferences.shared` in StatisticsTab, `HapticManager.shared`); hardcoded DEBUG `Button("Debug Config")` in SettingsView (pre-existing).
- PR #92 merged into `factory-reformat` (merge commit `96d3b0e`). **F19 complete — ready for `factory-reformat` → `main` merge.**

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
