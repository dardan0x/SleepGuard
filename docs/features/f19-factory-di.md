# F19 — Factory DI Migration

Migration of SleepGuard's dependency injection from SwiftUI environment-based
injection (IceCubesApp pattern) to a Factory container ([Factory](https://github.com/hmlongco/Factory), pinned `3.5.2`, imported as `FactoryKit`). Services stay `@MainActor @Observable` `.shared` singletons; views now resolve them via `@Injected` from the container instead of `@Environment`. No user-facing behavior changes.

## Files

| File | Change | Purpose |
|------|--------|---------|
| `Packages/Env/Sources/Services/Container.swift` | New | Factory registrations: 17 `.shared`-aliased singletons, `routerPath` unique, 2 internal session-composition factories |
| `Packages/DesignSystem/Sources/Container.swift` | New | `theme` registration (DesignSystem sits above Env — layering) |
| `Packages/Env/Package.swift`, `Packages/DesignSystem/Package.swift` | + FactoryKit | T1 foundation dependency |
| `Packages/{Statistics,Learn,Onboarding,Personalization,Recordings,Settings,SleepSession}/Package.swift` | + FactoryKit | View-layer migration dependency (7 packages) |
| Statistics views (17 files) | `@Environment(Theme.self)` → `@Injected(\.theme)` | T2 pilot |
| Feature-package views (91 files across 6 packages) | `@Environment(X.self)` → `@Injected(\.x)` | T3 fan-out (SleepSession, Recordings, Settings, Personalization, Onboarding, Learn) |
| `SleepGuard/AppRegistry.swift` | `withAppDependencyGraph()` deleted; `withEnvironments()` shrunk to RouterPath-only | Central wiring retired — container replaces it |
| `SleepGuard/SleepGuardApp.swift`, `MainTabView.swift`, `StatisticsTab.swift`, `SettingsTab.swift`, `SessionsTab.swift`, `CustomTabBarView.swift`, `SessionProcessingOverlay.swift`, `NotificationSoftAskView.swift` | `.shared` held directly / `@Injected` | App target as composition root |
| `Packages/Env/Sources/Services/UserPreferences.swift` (TabCoordinator ext) | `public static let shared` added | LearnTab container access |
| `Packages/Env/Sources/Services/Session/SessionManager.swift` | Internals resolved from container in init | T4 service composition |
| `SleepGuard/MainTabView.swift` | Dead `.environment(tabCoordinator)` removed | T3 orphan cleanup |
| `AGENTS.md` | State + Dependencies rules rewritten | `@Injected` flow, `@Observable` collision rule, nonisolated `dependency(\.)`, composition root |
| `docs/architecture/dependencies.md` | Rewritten | Full Factory-based DI reference |

## Routes

None — no navigation changes. `RouterPath` stays `.environment`-based (see Edge Cases).

## State

| What | Before | After |
|------|--------|-------|
| Service access in feature views | `@Environment(X.self)` + `.environment()` root wiring | `@Injected(\.x)` from Factory container |
| Root wiring | `withAppDependencyGraph()` / `withEnvironments()` in `AppRegistry.swift` | Deleted / RouterPath-only |
| App target holdings | `@State` mirror objects for environment | Direct `.shared` references (composition root) |
| Session internals | Hand-wired `private let` in `SessionManager.init` | Internal container factories, resolved in init |
| Preview/test mocking | Not possible without env plumbing | `Container.shared.x.register { Mock() }` |

## Edge Cases

- **`RouterPath` cannot be containerized.** Factory `.unique` scope orphans navigation paths (a sheet pushing onto a tab stack gets a fresh, disconnected path); `.shared` caches weakly and dies with the first requesting view. Tab-owned navigation stacks must propagate via `.environment`. Sheets re-receive it through the RouterPath-only `.withEnvironments()`.
- **`@Observable` + `@Injected` collide** — both macros synthesize underscore backing storage (`_property`): "invalid redeclaration of synthesized property" compile error. `@Observable` classes resolve via `Container.shared.x()` in init. Encoded in AGENTS.md + dependencies.md.
- **Sheet environment loss is no longer a hazard for services** — `@Injected` resolves through `Container.shared`, which survives sheet presentation. Only `RouterPath` needs re-injection.
- **FactoryKit is not an app-target dependency** — the app target (pbxproj) holds `.shared` directly; feature packages use `@Injected`. Avoids pbxproj package-reference edits.
- **Non-isolated services** (`SessionRawLogWriter` actor, `StorageLimitEnforcer` Sendable class) get bare factories; `@MainActor` factories for the rest. Isolation mismatch surfaces at the resolve site.
- **Watch app skipped deliberately** — no package structure, one singleton accessed twice; pbxproj edit risk for zero gain. Documented in dependencies.md.
- **Delegate pattern unchanged** — nonisolated Apple delegates parse payloads synchronously and hop via `Task { @MainActor in }`; none resolve services, so no `dependency(\.)` call sites exist yet (rule documented for future code).

## Tasks Completed

F19-T0 (plan) … F19-T5 (see `docs/trackers/f19-factory-di.md`).

## Follow-up

- Pre-existing simulator crash on recording start (`installTap` EXC_BREAKPOINT, AVFAudio realtime thread) — reproduced on unmodified baseline; needs on-device verification or separate investigation. Not caused by this feature.
- Optional: convert remaining direct `.shared` accesses in view closures (`UserPreferences.shared` in StatisticsTab, `HapticManager.shared`) to `@Injected`.
- Optional: hardcoded DEBUG `Button("Debug Config")` in `SettingsView.swift` bypasses Strings (pre-existing).
- Watch app modernization (also noted in f17 follow-up) when the watch target gets package structure.
