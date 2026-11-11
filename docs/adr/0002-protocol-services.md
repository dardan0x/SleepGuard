# ADR 0002: Every service behind a protocol, with a test double

- **Status:** Accepted
- **Date:** 2026-11-10 (written 2026-11-11, in F22-T14)
- **Tasks:** F22-T5 (pilot), F22-T6 (rollout), F22-T7 (no `.shared` in features)

## Context

F19 moved service access from `.environment` and `.shared` to a Factory container: views write `@Injected(\.sessionManager)`, `@Observable` classes call `Container.shared.x()` in `init`. But every factory still returned a **concrete type** (`Factory<SessionManager>`), and the concrete types had `private init()`.

So the container was a lookup table, not a seam:

1. **Tests couldn't replace a service.** `register { }` needs a value of the factory's type, and the only `SessionManager` that could exist was `.shared`. `SessionDetailModelTests` had to flip `UserPreferences.shared` and run `.serialized` to avoid leaking into other tests.
2. **Hidden dependencies.** 13 feature views and most `Env` internals still called `X.shared` directly, so the container didn't even see those uses.
3. **`DesignSystem` depended on `Env`** for one haptic call and one import, which put the whole service layer under the UI kit.

The staff-engineer interview (2026-11-10) asked how anything was tested without fakes. The user chose **protocols for every service, no exceptions**.

## Decision

- **One protocol per registered service, named for its role:** `SessionManaging`, `AudioRecording`, `UserPreferencesStoring`, `HealthKitSyncing`, `ThemeProviding`, … (18 in total: 15 in `Env`, 2 in `AudioEngine`, 1 in `DesignSystem`). Each protocol lives in its own file named after it, in the same folder as the concrete type (`AudioRecording.swift` beside `AudioRecorder.swift`), so the contract can be read without the implementation and the pair sorts together. (T5–T14 declared it at the top of the concrete file; F22-T15 moved them.) The concrete class keeps its name and its `.shared`.
- **Shape:** `@MainActor` protocols refining `AnyObject, Observable`, so views can read state through `any P` and Observation still tracks it. The exceptions follow the implementation: `SessionRawLogWriting` is an `Actor` protocol, and `StorageLimitEnforcing` is `Sendable`.
- **Factories are typed `Factory<any P>`** and still alias `.shared`, so the app behaves exactly as before. Inits are public. Services are passed around as `any P`, never as the concrete type.
- **Every protocol has a test double in `EnvTestSupport`** (`FakeSessionManager`, `FakeAudioRecorder`, `FakeHealthKitSync`, … 15 hand-written fakes), and each one is used by at least one test or preview. Two kinds of service get a real instance instead:
  - `UserPreferences` and `AppConfig` are wrappers over `UserDefaults`. Their double is the real type on a throwaway suite (`.isolated()`). A fake re-implementing 26 properties would only drift.
  - `Theme`'s double is a separate `Theme()` with tokens changed.
- **Tests override per test:** `Container.shared.x.register { fake }` inside `@Suite(.container)` / `@Test(.container)` from `FactoryTesting`. The container is task-local, so parallel tests can't see each other's fakes.
- **Constructor injection inside `Env`:** services take their collaborators as init parameters that default to the container (`init(preferences: any UserPreferencesStoring = Container.shared.userPreferences())`). The dependencies are visible in the signature and replaceable in tests.
- **Only the composition root touches `.shared`:** the app target (`SleepGuardApp`, `MainTabView`). Feature packages and `DesignSystem` never do, and `scripts/check-layering.py` fails the build if they start.
- **`DesignSystem` no longer depends on `Env`.** `RecordingActionButton` uses SwiftUI's `.sensoryFeedback` instead of `HapticManager`.

**Not behind protocols, on purpose:**
- `SessionRecordingController` and `RealtimeDetectionTracker` are internal to `Env` and owned by `SessionManager`, which wires them together. They are registered as concrete types. Tests build them directly with fakes for their collaborators (`DetectionCharacterizationTests`).
- `SnoreDetector` and `SpeechDetector` are AudioEngine helpers, not services. Since F22-T8 the rules they fed are a pure value type (`DetectionStateMachine`), tested with plain values.
- `RouterPath` stays SwiftUI environment state, one per tab (F19, ADR 0001).

## Consequences

**Better:**
- Any service can be replaced in a test or a preview with one `register` line, scoped to that test. `SessionDetailModelTests` dropped `.serialized` and the global-flag workaround and runs in parallel.
- `ServiceOverrideTests` (12) check the live default and each fake replacing its service. `ConstructorInjectionTests` (5) drive `TabCoordinator` and `SnoreInterrupterPlayer` with fakes and isolated stores.
- Every dependency of a feature view is visible as an `@Injected` property. The checker keeps it that way.
- `DesignSystem` sits on `Models` only, so changing a service no longer recompiles the UI kit.

**Honest limits:**
- **Protocols with one production conformer.** Each protocol exists for tests and previews, not for polymorphism. That is about 18 protocols and 15 fakes to keep in sync with their types. The compiler catches a fake that misses a requirement, but not one that behaves differently from the real thing.
- **`ThemeProviding` is wide** (41 requirements). It mirrors `Theme` one to one, and about 30 component parameters changed from `Theme` to `any ThemeProviding`. That's churn for a type that tests rarely replace.
- **Existentials everywhere.** `any P` costs a dynamic dispatch per call. Nothing measured shows it matters here, but it isn't free.
- **Singletons are still singletons.** Factories alias `.shared`, so production keeps one instance per service for the app's lifetime. The protocols make that replaceable; they don't remove it.

## Alternatives considered

- **Protocols only for the services tests actually need** (HealthKit, audio, session): less code, but every new test would start by adding a protocol, and "which services have one?" becomes a question for review. The user chose the uniform rule.
- **Subclass-and-override fakes:** no protocols, but `@Observable` final classes and `@MainActor` isolation make subclassing awkward, and it couples fakes to implementation details.
- **Keep concrete factories and register real instances on isolated storage:** works for the `UserDefaults` stores (and is what they use), but not for HealthKit, the microphone or SoundAnalysis, which can't run in a unit test.
- **Function-typed dependencies (closures instead of protocols):** lighter for one or two calls, but the services have 5–40 members each and are observed by views. A protocol keeps Observation and reads better at call sites.
