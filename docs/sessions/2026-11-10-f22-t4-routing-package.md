---
date: 2026-11-10
feature: F22
branch: feature/f22/t4-routing-package
title: F22-T4 Routing leaf package
---

### Completed
- F22-T4: navigation moved out of `Env` into a new leaf package, `Routing`, recorded in ADR 0001. `Env` no longer imports SwiftUI, and the layering check enforces that.

### Technical Details
- `Packages/Routing` (tools 6.2, Swift 6, iOS 17): `Sources/Router.swift` holds `RouterDestination`, `SheetDestination` and `RouterPath`, moved verbatim. `Tests/RouterPathTests.swift` has 3 tests.
- `Env/Sources/Services/Router.swift` → `TabCoordinator.swift`, with `import SwiftUI` replaced by `import Observation`.
- `Container.routerPath` deleted (it had no callers); the container doc comment explains why `RouterPath` isn't registered.
- Manifests: `Routing` added to Learn, Recordings, Settings, SleepSession and Statistics. App target: a new `XCLocalSwiftPackageReference "Packages/Routing"`, an `XCSwiftPackageProductDependency`, and a `PBXBuildFile` in the Frameworks phase (`plutil -lint` OK).
- `import Routing` added to 10 package files + 5 app files (`AppRegistry`, `DeepLinkRouter`, and 3 tabs).
- `check-layering.py` rule 3: no `import SwiftUI` under `Packages/Env/Sources/` (it ignores `.build`). Checked against a probe file.
- CLAUDE.md / AGENTS.md: Routing added to the allowed package list, the navigation rule added, and the `Router.swift` SwiftUI exception removed.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Routing/Package.swift`, `Sources/Router.swift`, `Tests/RouterPathTests.swift` | new | Leaf package + tests |
| `Packages/Env/Sources/Services/TabCoordinator.swift` | renamed from `Router.swift`, −45 | Route types removed; Observation instead of SwiftUI |
| `Packages/Env/Sources/Services/Container.swift` | +2/−6 | Unused `routerPath` factory removed |
| `Packages/{Learn,Recordings,Settings,SleepSession,Statistics}/Package.swift` | +2 each | `Routing` dependency |
| 10 feature view files, 5 app files | +1 each | `import Routing` |
| `SleepGuard.xcodeproj/project.pbxproj` | +13 | `Routing` package in the app target |
| `scripts/check-layering.py` | +8 | `Env` must not import SwiftUI |
| `CLAUDE.md`, `AGENTS.md` | +2/−2 | Package rules |
| `docs/adr/0001-routing-package.md` | new | The decision record |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T4 Done |
| `docs/architecture/{modules,navigation,feature-template,overview}.md`, `docs/ProjectArchitecture.md` | local | Updated, but gitignored, so not in the commit |

### Architecture Decisions
- **`TabCoordinator` stays in `Env`:** it is app-wide tab state that reads `AppConfig`, not per-tab navigation-stack state.
- **Delete the dead factory rather than add an `Env → Routing` edge:** the edge would undo the point of the split.
- **The ADR states the limit plainly:** features still recompile on a new route; the saving is in the shared layers.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5, 0 warnings, 0 errors). `run-tests.sh Routing Env Recordings Statistics`: 3 + 23 + 14 + 8 pass. SwiftFormat: 0/285 files need formatting. Layering check passes.

### Suggested Branch
`feature/f22/t4-routing-package` (from `feature/f22-architecture-hardening`)

### Suggested Commit
```
F22-T4 — Routing leaf package

- Packages/Routing: RouterDestination, SheetDestination, RouterPath + RoutingTests
- Env: Router.swift → TabCoordinator.swift, no SwiftUI; unused routerPath factory removed
- Routing wired into 5 feature packages and the app target
- check-layering: Env must not import SwiftUI
- ADR 0001; CLAUDE.md/AGENTS.md package rules; trackers; session fragment
```

### Next Session
- F22-T5: protocol DI pilot (`HealthKitSyncing` + `EnvTestSupport` fake).

### Open Questions
- None new.
