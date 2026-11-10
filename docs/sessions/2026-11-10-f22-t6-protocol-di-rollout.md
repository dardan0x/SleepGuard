---
date: 2026-11-10
feature: F22
branch: feature/f22/t6-protocol-di-rollout
title: F22-T6 protocols and test doubles for every service
---

### Completed
- F22-T6: every container-registered service now has a role-named protocol, a public init, a `Factory<any P>` registration and a test double that a test exercises. The interviewer's "you can't register a fake, every class has a private init" no longer holds.

### Technical Details
- **Protocols**, each declared above its concrete type in the same file:
  - Env: `AppConfigProviding`, `CustomMelodyStoring`, `HapticFeedbackProviding`, `NotificationPermissionManaging`, `PendingSessionStoring`, `RecordingDelayManaging`, `SessionCheckpointStoring`, `SessionManaging`, `SnoreInterrupterPlaying`, `StorageLimitEnforcing`, `TabCoordinating`, `UserPreferencesStoring`, `WatchConnectivityManaging`, `SessionRawLogWriting`, and `HealthKitSyncing` (T5)
  - AudioEngine: `AudioRecording`, `SoundAnalysisDetecting`
  - DesignSystem: `ThemeProviding`
- **Isolation:** MainActor services use `@MainActor protocol …: AnyObject, Observable` (or `AnyObject` for the 3 non-observable ones). `SessionRawLogWriting: Actor`. `StorageLimitEnforcing: Sendable` with `@MainActor` requirements: the first build failed on a cross-isolation conformance, and the fix matches how the implementation is isolated.
- `UserPreferences(defaults:)` and `AppConfig(defaults:)`, with `.standard` as the default. `private init()` was replaced with a public init on 17 types.
- **Ripple:** components take `theme: any ThemeProviding`, including `SleepStagesInfoView`'s `(any ThemeProviding)?`. `SessionDetailModel` and `AppBriefingController` take protocol types. No `@Injected` declaration changed.
- **`EnvTestSupport`:**
  - `FakeSystemServices.swift`: audio recorder, sound analysis, notifications, watch
  - `FakeSessionServices.swift`: session manager, delay, interrupter, tabs
  - `FakeStores.swift`: pending, checkpoint, melodies, storage limit, raw log
  - `FakeHapticManager.swift`
  - `IsolatedDefaults.swift`: `UserDefaults.isolated()`, `UserPreferences.isolated()`, `AppConfig.isolated()`
- **Tests:** `ServiceOverrideTests` (10), `IsolatedStoreTests` (2), `ThemeOverrideTests` (2). `SessionDetailModelTests` is now parallel, on isolated stores.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| 15 `Packages/Env/Sources/Services/*.swift` + `Session/SessionManager.swift` | +10–35 each | Protocols, conformances, public inits; `defaults:` on UserPreferences/AppConfig |
| `Packages/AudioEngine/Sources/Engine/{AudioRecorder,SoundAnalysisDetector}.swift` | +25/+12 | Protocols, public inits |
| `Packages/DesignSystem/Sources/Components/Theme.swift` | +47 | `ThemeProviding`, public init |
| `Packages/Env/Sources/Services/Container.swift`, `Packages/DesignSystem/Sources/Container.swift` | ±18 | `Factory<any P>`; container doc |
| ~25 DesignSystem/Recordings/Statistics/SleepSession views, `SleepGuard/AppBriefingController.swift` | ±1–2 each | `any ThemeProviding` / protocol params |
| `Packages/Env/TestSupport/*` | new (5 files) | Fakes + isolated stores |
| `Packages/Env/Package.swift`, `Packages/DesignSystem/Package.swift` | +6 | Test deps: EnvTestSupport, FactoryKit, FactoryTesting, AudioEngine |
| `Packages/Env/Tests/ServiceOverrideTests.swift`, `Packages/DesignSystem/Tests/ThemeOverrideTests.swift` | new | 14 tests |
| `Packages/Recordings/Tests/SessionDetailModelTests.swift` | ±15 | Isolated stores, no `.serialized` |
| `CLAUDE.md`, `AGENTS.md` | +2 | Protocol + double rules |
| Trackers | — | T6 Done |

### Architecture Decisions
- **Real type on isolated storage for `UserDefaults` stores:** a hand-written fake of 26 persisted properties would drift from the real key/default logic, which is exactly what tests should exercise.
- **`any P` in signatures, not generics:** components store `theme` as a property and SwiftUI views are structs. Generics would spread type parameters through every view for no measurable gain at these call rates.
- **Protocol in the concrete type's file:** contract and implementation are reviewed together; there is no `Protocols/` folder to keep in sync.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5, 0 warnings, 0 errors), and a simulator launch renders the dashboard normally.
- `run-tests.sh` (all 8 packages with tests): AudioEngine 37, DesignSystem 7, Env 35, Models 77, Personalization 30, Recordings 16, Routing 3, Statistics 8, all passing.
- SwiftFormat: 0/293 files need formatting. Layering check passes.

### Suggested Branch
`feature/f22/t6-protocol-di-rollout` (from `feature/f22-architecture-hardening`)

### Suggested Commit
```
F22-T6 — Protocols and test doubles for every service

- 17 service protocols + ThemeProviding; Factory<any P> registrations
- Public inits; UserPreferences/AppConfig take UserDefaults
- Components/state owners take protocol types
- EnvTestSupport: 14 fakes + isolated UserDefaults stores
- ServiceOverrideTests, IsolatedStoreTests, ThemeOverrideTests
- SessionDetailModelTests parallel on isolated stores
- CLAUDE.md/AGENTS.md DI rules; trackers; session fragment
```

### Next Session
- F22-T7: route the remaining `.shared` calls (feature views + Env internals) through the container; `DesignSystem` drops `Env`.

### Open Questions
- None new.
