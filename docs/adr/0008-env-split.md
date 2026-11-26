# ADR 0008: Split `Env` by reason to change

> **Note (2026-11-26, F27-T20):** `Env` is now named `Services` (module, products `Services` / `ServicesTestSupport`, folder `Packages/Services`). The text below keeps the old name.

- **Status:** Accepted
- **Date:** 2026-11-25
- **Task:** F27-T11 (principal review Q31; also Q29, Q30)

## Context

`Env` held 37 files and 3.7k lines: the recording night (session manager, controller, detection tracker, committer, checkpoint/pending/raw-log stores, storage limits, interrupter, delay, melody storage), remote config and preferences, HealthKit, haptics, notification permission, Watch connectivity and tab coordination. It imported UIKit, HealthKit, WatchConnectivity, UserNotifications and SwiftData.

That is a layer ("things with state that aren't views"), not a responsibility. In practice:
- A feature that only reads a feature flag (Statistics, Learn) depended on the whole session stack, and so did its rebuilds.
- `TabCoordinator`, presentation state, lived among the services.
- New code had one place to go, so `Env` kept growing.

## Decision

Split by reason to change:

| Package | Holds | Depends on |
|---|---|---|
| `Config` | `AppConfig`, `UserPreferences` (+ protocols, `ConfigTestSupport` with the isolated stores) | Models, SleepCore, Factory |
| `Health` | `HealthKitSync` (+ protocol, fake) | Models, SleepCore, Factory; links HealthKit |
| `Platform` | haptics, notification permission, Watch (+ protocols, fakes); the only UIKit services | Factory; links WatchConnectivity |
| `Env` | the recording night (see above) | Models, AudioEngine, Config, Health, Platform, Factory |
| `Routing` | + `TabCoordinator` / `TabCoordinating` / `TabResetSignal` (+ fake) | Models, Config, Factory |

- Each package registers its own factories in a `Container` extension and ships its own TestSupport.
- Features declare only what they use: Statistics, Learn and Personalization no longer depend on `Env`. `scripts/check-imports.py` keeps manifests and imports in step.
- `Env` must not import `Routing` (nor SwiftUI): services sit below navigation. Enforced by `check-layering.py`.
- The app target links Config, Health and Platform directly (`project.pbxproj`).

## Consequences

**Better:** a flag or preference change rebuilds Config and its readers, not the session stack. HealthKit and WatchConnectivity are linked by the packages that use them. Each package's purpose fits in one sentence, so a new service has an obvious home.

**Limits, honestly:**
- `Routing` is no longer a pure SwiftUI leaf: it now depends on Models, Config and Factory because `TabCoordinator` reads `AppConfig`. A route change still doesn't rebuild the services, but a Config change rebuilds Routing and every feature.
- Five packages instead of one is more manifests to keep right; `check-imports.py` is what makes that cheap.
- `Env` is still the biggest package (the recording night is genuinely one reason to change).

## Alternatives

- **Targets inside one `Env` package:** same boundaries, fewer manifests, but features would still name one package and drift back to depending on all of it.
- **`TabCoordinator` in the app target:** keeps Routing a pure leaf, but Learn reads it, so it would need a closure seam.
