# ADR 0011: One `Features` package, one target per feature

- **Status:** Accepted
- **Date:** 2026-11-28
- **Task:** F27-T31

## Context

Each feature (Learn, Onboarding, Personalization, Recordings, Settings, SleepSession, Statistics) was its own package. That meant seven manifests repeating the SleepGuardShared pin, Factory, the Swift 6 settings and `InternalImportsByDefault`, and seven folders sitting in one flat `Packages/` list next to the core and service packages. So the list didn't show which packages were screens and which were foundation.

SleepGuardUIKitWay keeps its screens in one `Packages/Features` package with one target per feature. The two apps share the kits and the screen content (ADR 0005, 0006), and the person working on one works on the other.

## Decision

- `Packages/Features` holds all seven features. Each is still a module with its own product and target (`Sources/<Feature>`, tests in `Tests/<Feature>Tests`), imported by name. Module names are unchanged, so the app target and the project's product dependencies are untouched.
- Each target keeps exactly the dependencies it had. The package declares the union.
- A feature target never depends on another feature target. Features talk through `Routing` (ADR 0001).
- `scripts/check-imports.py` enforces it two ways:
  - A sibling target counts only when it is declared, so an undeclared `import Settings` in Learn fails.
  - A feature that declares another feature fails.
- The core and service packages (Models, AudioEngine, Config, Health, Platform, Services, Routing, DesignSystem) are unchanged.

## Consequences

**Better:**
- One feature manifest, one shared-release pin for the features, and one `Features` entry in the project's `Packages` folder.
- `Packages/` now reads as foundation packages plus a Features package.
- The layout matches SleepGuardUIKitWay.

**Limits, honestly:**
- **The compiler no longer stops a feature-to-feature import by itself.** Before, `import Recordings` in Statistics failed with "no such module" because Statistics' package didn't know Recordings. Now both targets are in one package, so the module can be visible in the build products (the same transitive visibility F27-T9 found). `check-imports.py` in CI is now the guard. A feature-to-feature edge in the manifest is one string, not a new package dependency.
- Package tests run as one `Features-Package` scheme. `sh scripts/run-tests.sh Features` runs RecordingsTests and StatisticsTests together, and you can no longer run one feature's tests by package name.
- Editing the Features manifest re-resolves all seven features. That's harmless, but it's one edit for all of them.

## Alternatives

- **Keep seven packages:** the compiler enforces the boundary, but you keep seven copies of the same settings and a flat list.
- **Rename the modules to `*Feature`** (UIKitWay's names): full parity, but every `import` in the app target and the project's product dependencies would change. That can be done later as its own step.
- **Group the core packages too** (UIKitWay's Core/Adapters/Presentation): a separate decision. Those packages split by reason to change (ADR 0008), and this change leaves that alone.
