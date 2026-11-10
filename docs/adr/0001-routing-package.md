# ADR 0001: Move navigation into a `Routing` package

- **Status:** Accepted
- **Date:** 2026-11-10
- **Task:** F22-T4

## Context

`RouterDestination`, `SheetDestination` and `RouterPath` lived in `Env/Sources/Services/Router.swift`, next to the DI container, HealthKit sync, the session services and the 750-line detection tracker.

That put two different kinds of code in one module:

- **The navigation contract.** It is how feature packages talk to each other ("open session detail for this id"). It changes whenever a screen is added. It needs SwiftUI (`NavigationPath`) and nothing else: routes carry only `UUID`s.
- **The service layer.** It holds state and side effects (audio, HealthKit, storage). It changes for completely different reasons.

Consequences of keeping them together:

1. **Rebuild scope.** Adding a route case edited `Env`, so `Env` and everything that depends on it recompiled, including `DesignSystem`, which never navigates.
2. **Layering.** `Router.swift` was the only reason `Env` imported SwiftUI, and the layering rules carried a special exception for it.
3. **Wrong dependency direction.** Anything that wanted to name a route had to depend on the whole service layer.

## Decision

Create `Packages/Routing`, a leaf package with no package dependencies:

```
Routing  (SwiftUI only)
  ├─ RouterDestination   push routes
  ├─ SheetDestination    modal routes
  └─ RouterPath          per-tab NavigationPath + presented sheet
```

- Feature packages that navigate (Learn, Recordings, Settings, SleepSession, Statistics) and the app target depend on `Routing` directly.
- `Env` keeps `TabCoordinator`, `AppTab` handling and `TabResetSignal`. These are app-wide tab state that read `AppConfig`, not navigation-stack state. `Router.swift` became `TabCoordinator.swift`, and `Env` no longer imports SwiftUI.
- `scripts/check-layering.py` now fails if `Env/Sources` imports SwiftUI again, and the SwiftUI exception for `Router.swift` is gone.
- The unused `Container.routerPath` Factory registration was deleted. `RouterPath` is deliberately SwiftUI-environment state, one per tab (see F19); nothing resolved it through the container, and keeping it would have forced `Env` to depend on `Routing`.

## Consequences

**Better:**
- Adding a screen edits a 50-line leaf package. `Env`, `AudioEngine`, `Models` and `DesignSystem` don't recompile.
- `Env` is UI-free, as `modules.md` always said it should be. The checker keeps it that way.
- The navigation contract can be read in one file, and it has its own tests (`RoutingTests`).
- Future consumers (App Intents, widget deep links, a Watch companion) can depend on routes without pulling in services.

**Honest limits:**
- **Feature packages still rebuild when a route is added**, because they import `Routing`. The saving is the shared layers below them, not the features. A per-feature route enum would avoid that, but it would split the contract and the app-level `AppRegistry` switch, which isn't worth it at 6 push routes and 2 sheets.
- One more package to maintain (12 instead of 11). The cost is a 20-line manifest; the boundary is enforced by the compiler rather than by review.

## Alternatives considered

- **Keep routes in `Env`:** simplest, but keeps the SwiftUI exception and the rebuild scope.
- **Routes per feature package + type-erased routing:** maximal decoupling, but over-engineered for this app's size, and it loses exhaustive `switch` checking in `AppRegistry`.
- **Put routes in `Models`:** zero new packages, but `Models` must stay free of SwiftUI (`RouterPath` holds a `NavigationPath`).
