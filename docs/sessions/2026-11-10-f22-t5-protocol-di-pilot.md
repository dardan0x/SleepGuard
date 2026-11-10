---
date: 2026-11-10
feature: F22
branch: feature/f22/t5-protocol-di-pilot
title: F22-T5 protocol DI pilot on HealthKitSync
---

### Completed
- F22-T5: the first service sits behind a protocol with a fake that a test actually uses. It validates the conventions the T6 rollout will follow.

### Technical Details
- `HealthKitSyncing` (`@MainActor protocol …: AnyObject, Observable`): `isAuthorized { get }`, `requestAuthorization()`, `checkAuthorizationStatus()`, `fetchSleepStages(for:)`, `sync(session:)`. Declared above `HealthKitSync` in the same file. `HealthKitSync` conforms, and its `init()` is now public.
- `Container.healthKitSync` is a `Factory<any HealthKitSyncing>`, still aliasing `.shared`. All 6 `@Injected(\.healthKitSync)` views compile unchanged, and Observation of `isAuthorized` works through the existential.
- `SessionDetailModel` resolves `Container.shared.healthKitSync()` in its init (`@Observable` can't use `@Injected`), replacing `HealthKitSync.shared`.
- New `EnvTestSupport` library (`Packages/Env/TestSupport/FakeHealthKitSync.swift`): configurable `isAuthorized`, `stages` and `grantsAuthorization`, and it records `fetchedSessionIDs`, `syncedSessionIDs` and `authorizationRequests`.
- `SessionDetailModelTests` is now `@Suite(.serialized, .container)`. `.container` (from `FactoryTesting`) scopes the registrations per test. Two new tests: stages fetched and scored (85), and HealthKit skipped when tracking is off.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/HealthKitSync.swift` | +20/−3 | Protocol, conformance, public init |
| `Packages/Env/Sources/Services/Container.swift` | ±1 | `Factory<any HealthKitSyncing>` |
| `Packages/Env/Package.swift` | +13 | `EnvTestSupport` library + target |
| `Packages/Env/TestSupport/FakeHealthKitSync.swift` | new | The fake |
| `Packages/Recordings/Sources/Helpers/SessionDetailModel.swift` | +5/−1 | Resolves the protocol from the container |
| `Packages/Recordings/Package.swift` | +3 | Test target: EnvTestSupport, FactoryKit, FactoryTesting |
| `Packages/Recordings/Tests/SessionDetailModelTests.swift` | +50 | Suite traits + 2 HealthKit tests |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T5 Done |

### Architecture Decisions
- **Protocol next to its implementation**, not in a `Protocols/` folder: one place to read a service's contract and its live behavior.
- **Fakes in a shipped-to-tests library**, not in each test target: previews and every package's tests can share one fake per service.
- **`FactoryTesting.container` over manual reset:** parallel-safe without teardown code.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5, 0 warnings, 0 errors). `run-tests.sh Env Recordings`: 23 + 16 pass. SwiftFormat: 0/286 files need formatting. Layering check passes.

### Suggested Branch
`feature/f22/t5-protocol-di-pilot` (from `feature/f22-architecture-hardening`)

### Suggested Commit
```
F22-T5 — Protocol DI pilot: HealthKitSyncing

- HealthKitSyncing protocol; HealthKitSync conforms, public init
- Container: Factory<any HealthKitSyncing>
- SessionDetailModel resolves it from the container
- EnvTestSupport library with FakeHealthKitSync
- SessionDetailModelTests: FactoryTesting .container, 2 HealthKit tests
- Trackers; session fragment
```

### Next Session
- F22-T6: roll the pattern out to every remaining service + `Theme`, with `UserPreferences(defaults:)`.

### Open Questions
- None new.
