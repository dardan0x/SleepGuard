# F22 — Architecture Hardening

Fixes the architecture concerns raised in the mock staff-engineer interview (2026-11-10), after checking each claim against the code. Users see no change. In 16 tasks the codebase got:

- a pure, versioned sleep score;
- a `Routing` leaf package;
- a protocol and a test double for every service;
- detection rules as a pure state machine, run by an actor fed by one ordered `AsyncStream`, with replay tests cut from a real recording;
- a `VersionedSchema` migration plan;
- CI guardrails;
- three ADRs.

Tests went from 179 in 7 packages to **268 in 8 packages**.

Decisions: [ADR 0001 — Routing package](../adr/0001-routing-package.md), [ADR 0002 — protocol services](../adr/0002-protocol-services.md), [ADR 0003 — detection actor](../adr/0003-detection-actor.md). Task log: `docs/trackers/f22-architecture-hardening.md`.

## What changed, by concern

| Interview concern | What F22 did | Task |
|---|---|---|
| The score is a hand-tuned formula buried in a `@Model`, and its cache never notices a coefficient change | `SleepScore.compute(SleepInputs, config:)` is a pure function with parameterized tests. The cache stores a version fingerprint of the formula and config, and a launch pass recomputes stale scores | T2, T3 |
| Navigation types sit in the service layer, so `Env` imports SwiftUI | `Routing` leaf package; `Env` is SwiftUI-free, and the checker enforces it | T4 |
| Services can't be faked: concrete factories, `private init()`, `.shared` everywhere | 18 protocols, 15 fakes in `EnvTestSupport`, isolated `UserDefaults` stores, no `.shared` in feature packages, `DesignSystem` drops `Env` | T5–T7 |
| Detection is a 775-line main-actor class whose ordering only holds by accident | Pure `DetectionStateMachine` (T8), pinned by replay goldens from a real recording (T9), run on a `DetectionEngine` actor fed by one ordered stream with duration thresholds (T10) | T1, T8–T10 |
| No migration path for the schema | `SleepGuardSchemaV1` + `SleepGuardMigrationPlan`; every container opens through it | T11 |
| The dashboard's "which night" logic lives in a view | `DashboardState.make(from:now:calendar:)`, pure and tested | T12 |
| The 200-line view rule is honor-system | `check-view-size.py` in CI with a ratcheting allowlist | T13 |
| Docs drifted from the code | ADRs, this doc, truth pass on README, detection doc, overview, AGENTS/CLAUDE | T14 |

Claims found outdated, with no task needed: CI already ran tests, `.measurement` mode was already set, there was no `@unchecked Sendable`, and no HealthKit data went to analytics (see the tracker summary).

## Files

| File | Change | Purpose |
|------|--------|---------|
| `Packages/AudioEngine/Sources/Engine/SnoreSample.swift` | Modified | `RawLog { metadata, samples }` (format 2), `peakDB` + `speechConfidence`; reads format 1 (T1) |
| `Packages/Env/Sources/Services/SessionRawLogWriter.swift` | Modified | `elapsed` from the tracker's clock, samples sorted on stop (T1) |
| `Packages/Models/Sources/Data/SleepScore.swift` | New | `SleepInputs` + pure `SleepScore.compute` (T2) |
| `Packages/Models/Sources/Data/SleepScoreCache.swift` | New | Version fingerprint, `refreshCachedScore`, `refreshStaleCachedScores` (T3) |
| `Packages/Models/Sources/Data/SleepSession.swift` | Modified | Builds `SleepInputs`; `cachedScoreVersion` (additive) (T2, T3) |
| `SleepGuard/SleepGuardApp.swift` | Modified | Launch recompute pass; container through the schema helper (T3, T11) |
| `Packages/Routing/` | New | `RouterDestination`, `SheetDestination`, `RouterPath` + `RouterPathTests` (T4) |
| `Packages/Env/Sources/Services/Router.swift` → `TabCoordinator.swift` | Moved | Tab state stays in Env; routes moved out (T4) |
| `Packages/*/Package.swift` (navigating features) | Modified | Depend on `Routing` (T4) |
| `Packages/Env/Sources/Services/*.swift`, `AudioEngine/…/AudioRecorder.swift`, `SoundAnalysisDetector.swift`, `DesignSystem/…/Theme.swift` | Modified | A protocol per service; public inits; constructor injection with container defaults (T5–T7) |
| `AudioRecording.swift`, `SoundAnalysisDetecting.swift`, `ThemeProviding.swift`, and 15 protocol files in `Env/Sources/Services/` | New | Each protocol in its own file next to its concrete type (T15) |
| `Packages/Env/Sources/Services/Container.swift`, `DesignSystem/Sources/Container.swift` | Modified | `Factory<any P>` for every service; `routerPath` registration deleted (T4–T6) |
| `Packages/Env/TestSupport/` | New | `EnvTestSupport`: 15 fakes + `UserDefaults.isolated()` (T5, T6) |
| Feature views (13 files) and helpers | Modified | `@Injected` instead of `.shared` (T7) |
| `Packages/DesignSystem/Sources/Components/RecordingActionButton.swift` | Modified | `.sensoryFeedback` instead of `HapticManager`; DesignSystem drops `Env` (T7) |
| `Packages/AudioEngine/Sources/Engine/DetectionStateMachine.swift` | New | Pure detection rules; duration thresholds (T8, T10) |
| `Packages/AudioEngine/Sources/Engine/DetectionEngine.swift` | New | Actor + ordered `Message` stream + awaited `Batch` performer (T10) |
| `Packages/Env/Sources/Services/Session/RealtimeDetectionTracker.swift` | Rewritten | Adapter: classify, send to the engine, perform outputs, 5 Hz display (T8, T10) |
| `Packages/Env/Sources/Services/Session/SessionRecordingController.swift` | Modified | Awaits `finishDetection()` before stopping audio (T10) |
| `Packages/Env/Sources/Services/SnoreInterrupterPlayer.swift` | Modified | Stop notification carries the player as its sender (T10) |
| `Packages/AudioEngine/Tests/Fixtures/Replay/` | New | 4 CSV excerpts + goldens + README (T9, re-recorded in T10) |
| `Packages/Models/Sources/Data/SleepGuardSchema.swift` | New | `SleepGuardSchemaV1`, `SleepGuardMigrationPlan`, `container(_:)` (T11) |
| `Packages/Models/TestSupport/TestStore.swift` | Modified | Opens through the schema helper (T11) |
| `Packages/Statistics/Sources/State/DashboardState.swift` | New | Pure session → dashboard state mapping (T12) |
| `Packages/Statistics/Sources/Views/StatisticsDashboardView.swift`, `StatisticsLoadedView.swift` | Modified | Use `DashboardState` (T12) |
| `scripts/check-layering.py` | Modified | No SwiftUI in Env; no service `.shared` in feature packages (T4, T7) |
| `scripts/check-view-size.py`, `.github/workflows/layering.yml` | New / Modified | 200-line view limit with ceilings (T13) |
| `scripts/make-replay-fixture.py`, `scripts/record-replay-goldens.sh` | New | Cut fixtures from a raw log; re-record goldens on purpose (T9) |
| `Packages/AudioEngine/Sources/Engine/TapProcessor.swift`, `AudioRecorder.swift` | Modified | Tap-thread comments match Apple's docs (off the main thread, not "realtime") (T14) |
| `docs/adr/0001…0003` | New | Decision records (T4, T10, T14) |
| `AGENTS.md`, `CLAUDE.md` | Modified | Protocol + double rules, Routing, schema V2 procedure, detection-stream rule, ADR convention |
| `README.md`, `docs/snore-detection-algorithm.md` | Modified | Truth pass: packages, tests, CI, detection thresholds and actor (T14) |
| `docs/features/f15`, `f19`, `f20`, `f21` | Modified | Marked as historical records where F22 superseded them (T14) |

### Tests added

| Package | Suites (tests) |
|---|---|
| AudioEngine | `DetectionStateMachineTests` (18), `DetectionEngineTests` (5, parameterized over 4 fixtures × 3 delivery patterns), `DetectionReplayTests` (2), `RawLogTests` (3) |
| Env | `DetectionCharacterizationTests` (13), `ServiceOverrideTests` (12), `ConstructorInjectionTests` (5), `SessionRawLogWriterTests` (3) |
| Models | `SleepScoreFormulaTests` (3, parameterized: 14 cases), `SleepScoreCacheTests` (6), `SleepGuardSchemaTests` (2) |
| Statistics | `DashboardStateTests` (10) |
| Recordings | `SessionDetailModelTests` (+2, with `FakeHealthKitSync`) |
| DesignSystem | `ThemeOverrideTests` (2) |
| Routing | `RouterPathTests` (3) |

## Routes

None added. All push and sheet destinations moved unchanged from `Env` to `Routing` (T4).

## State

| State | Where | Scope |
|-------|-------|-------|
| Detection state (open events, runs, melody gap) | `DetectionStateMachine`, owned by the `DetectionEngine` actor | One per tracker; rebuilt on `reset()` |
| Live display (`currentDB`, detection state, speech) | `RealtimeDetectionTracker`, published at 5 Hz | Main actor, per session |
| Score cache version | `SleepSession.cachedScoreVersion` (additive property) | Per session, persisted |
| Schema version | `SleepGuardSchema.Current` (V1) | App + tests |
| Service overrides in tests | Factory container, task-local via `.container` trait | Per test |
| Replay fixtures + goldens | `Packages/AudioEngine/Tests/Fixtures/Replay/` (bundled with `.copy`) | Test target |

## Edge Cases

- **Melody feedback ordering.** Only the player knows whether the melody started. `perform` returns `.melodyDidStart`, and the engine applies it before the next queued sample, matching the old synchronous tracker. Tested under all three delivery patterns.
- **Session stop.** `finishDetection()` flushes the stream and awaits the engine, so every event is finalized and saved before the audio engine stops.
- **Dropped control messages.** The stream is `.unbounded` on purpose: `.bufferingNewest` would drop a `.melodyDidStop` or `.finalize` under backpressure.
- **Notification crosstalk.** `.snoreInterrupterDidStop` is observed only from the tracker's own player (found when async tests started interleaving).
- **Old raw logs.** Format 1 (a bare sample array) still decodes. The replay fixtures come from a format-1 log.
- **Score cache after an update.** Every session's version starts as `""`, so the first launch after T3 recomputes every score once, on purpose.
- **Schema V2.** Not needed yet. The procedure (freeze V1 as nested copies, add a stage, write a V1-store test, verify on real data) is in CLAUDE.md / AGENTS.md. The app's container fallback deletes the store when opening fails, so V2 must be tested on a simulator holding real data.
- **Parallel tests.** Fakes are registered per test through `FactoryTesting`'s `.container` trait. Preferences use isolated `UserDefaults` suites, so no suite needs `.serialized` for shared preferences any more.

## Open items

- **Real night on a device** with this branch (T10 acceptance). The detection actor and duration thresholds are verified by replay and on the simulator, not yet overnight.
- **Replay coverage:** the excerpts come from one scripted 37-minute recording in log format 1, with no sleep-talking data and `spectralScore` 0 throughout. A format-2 excerpt from a real night would cover speech.
- **Minute-0 classification** in the T9 recording: snoring was detected where the script planned silence. Possibly noise classified as quiet snoring; not yet confirmed.
- **Option B** (feed each mic buffer into the stream, about 47 Hz) is deferred until a real night can validate it (ADR 0003).
- Non-code follow-ups (Crashlytics root cause for the faulting crash, battery over a night, iOS 17 sheet environment, product wording) are listed in the tracker.

## Tasks Completed

F22-T1, F22-T2, F22-T3, F22-T4, F22-T5, F22-T6, F22-T7, F22-T8, F22-T9, F22-T10 (real-night check pending), F22-T11, F22-T12, F22-T13, F22-T14, F22-T15, F22-T16 (unused `RouterPath` environment reads removed from `RecordingsListView` and `CalendarView`).
