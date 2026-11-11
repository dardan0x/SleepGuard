# F22 — Architecture Hardening

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done (real-night check pending, T10) |
| **Priority** | P1 |
| **Version** | V5 |
| **Blocked By** | — |
| **Started** | 2026-11-10 |
| **Completed** | 2026-11-11 |
| **Feature Doc** | [`docs/features/f22-architecture-hardening.md`](../features/f22-architecture-hardening.md) |
| **Branch** | `feature/f22-architecture-hardening` (one sub-branch per task, `feature/f22/t#-slug`, merged back here; then `main`) |

## Summary

Fixes the architecture concerns raised in the mock staff-engineer interview (`SleepGuard-Architecture-Debate.md`, 2026-11-10), after checking each claim against the code. Users see no change. The codebase gets: a pure, versioned sleep score; a `Routing` leaf package; protocol-based services, each with a fake that tests or previews use; a detection state machine that runs on its own actor, fed by an ordered `AsyncStream` and covered by replay tests built from real nights; `VersionedSchema`; CI guardrails; and ADRs that explain each decision.

### Decisions (user, 2026-11-10)
- **Protocols for every service**, with no exceptions. Rule: every protocol ships with a fake in `EnvTestSupport` (or the owning package's test support), and at least one test or preview uses it.
- **`Routing` package** for the route enums + `RouterPath`, with an ADR explaining why.
- **Detection off the main actor**: `DetectionEngine` actor fed by `AsyncStream`.
- **No `Detection` package.** The pure state machine lives in `AudioEngine`, next to `SnoreDetector` and `SnoreSample`.
- **`VersionedSchema` is included** (T11). It is not deferred to F13.
- **Local trackers only.** No Notion sync for F22.

### Interview claims found outdated (no task needed)
- CI already runs tests (`.github/workflows/tests.yml`); about 179 `@Test`s, not 40; `SleepScoreTests` exists.
- `AVAudioSession` already uses `.measurement` mode (`AudioRecorder.swift:188`).
- No `nonisolated(unsafe)`, `@preconcurrency`, `assumeIsolated` or `@unchecked Sendable` anywhere.
- No analytics `logEvent` calls, so no HealthKit-derived data goes to Firebase.
- Audio-hop ordering: the tracker polls the latest values every 50 ms, so `Task`-per-buffer ordering can't corrupt the state machine. The real weaknesses are poll-time `Date()` timestamps and dB and confidence values sampled at different moments (fixed by T1 + T10).

### Non-code follow-ups (user)
- Crashlytics: find the root cause of the relationship-faulting crash that `cachedSleepScore` worked around.
- Measure battery drain over one full night on a device.
- Re-test on iOS 17 whether sheets lose the environment.
- Product wording: melody-pause bias, partner snoring in a shared bed, no apnea hints.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F22-T1 | Raw log: add `peakDB`, `speechConfidence`, sample timestamp | Model | Done | — | AudioEngine / Env | 2026-11-10 | 2026-11-10 |
| F22-T2 | `SleepInputs` value type + pure score function + parameterized tests | Model | Done | — | Models | 2026-11-10 | 2026-11-10 |
| F22-T3 | Versioned score cache with one owner + launch recompute | Model | Done | F22-T2 | Models / App | 2026-11-10 | 2026-11-10 |
| F22-T4 | `Routing` package (+ ADR 0001) | Infra | Done | — | Routing / all features | 2026-11-10 | 2026-11-10 |
| F22-T5 | Protocol DI pilot: `HealthKitSync` + `EnvTestSupport` fake | Infra | Done | — | Env / Recordings | 2026-11-10 | 2026-11-10 |
| F22-T6 | Protocol DI rollout: every remaining service + `Theme` | Infra | Done | F22-T5 | Env / AudioEngine / DesignSystem | 2026-11-10 | 2026-11-10 |
| F22-T7 | Remove `.shared` from feature packages; `DesignSystem` drops `Env` | Infra | Done | F22-T6 | Features / DesignSystem | 2026-11-10 | 2026-11-10 |
| F22-T8 | Extract pure `DetectionStateMachine` into `AudioEngine` | Refactor | Done | F22-T1 | AudioEngine / Env | 2026-11-11 | 2026-11-11 |
| F22-T9 | Detection replay tests (golden outputs from real-recording excerpts) | Test | Done | F22-T1, F22-T8 | AudioEngine | 2026-11-11 | 2026-11-11 |
| F22-T10 | `DetectionEngine` actor + `AsyncStream` input (+ ADR) | Refactor | Done | F22-T9 | AudioEngine / Env | 2026-11-11 | 2026-11-11 |
| F22-T11 | `VersionedSchema` V1 + empty migration plan | Model | Done | F22-T3 | Models / App | 2026-11-10 | 2026-11-10 |
| F22-T12 | `DashboardState.make(from:now:)` pure mapping + tests | Refactor | Done | F22-T3 | Statistics | 2026-11-11 | 2026-11-11 |
| F22-T13 | CI check: 200-line view limit with allowlist | Infra | Done | — | scripts / .github | 2026-11-11 | 2026-11-11 |
| F22-T14 | ADRs (protocols, detection actor) + docs truth pass + feature doc | Docs | Done | F22-T1…T13 | docs | 2026-11-11 | 2026-11-11 |

## Task Details

### F22-T1 — Raw log: add `peakDB`, `speechConfidence`, sample timestamp

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/concurrency.md` |
| Status | Done |
| Started | 2026-11-10 |
| Completed | 2026-11-10 |

**Acceptance Criteria:**
- [x] `SnoreSample` records every input `processAudioLevel` receives: `db`, `peakDB`, `spectralScore`, `snoreConfidence`, `speechConfidence`, plus `elapsed`
- [x] New fields are optional on decode, so old `rawlog_*.json` files still load
- [x] Round-trip test: encode → decode equals; decoding an old-format sample works
- [x] Builds with zero errors; package tests pass

**Prompt Used:**
"1,2 point you're right. For 3 point or notion dont do it, just update local feature trackers as we do now." (start T1 after the plan was approved)

**Notes:**
- Format 2: `rawlog_<id>.json` is now a `RawLog { metadata, samples }` object. `RawLog.decode(from:)` falls back to format 1 (a bare sample array). The metadata (sensitivity, sleep talking, interrupter mode, session start) is inside the file rather than in a separate file, so the 4 places that delete `rawLogFileURL` don't change.
- **Bug fixed:** `elapsed` was measured inside the writer actor, when the unstructured `Task` arrived, and from the actor's own start time. Now the tracker passes its `now`, `elapsed` is measured from `session.startDate`, and `stop()` sorts the samples. This was the interview's "Task per sample, no ordering" concern, applied to the log rather than the detector.
- `SessionRawLogWriter.init(directory:)` is internal, for tests.
- Logs grow from about 48 MB to about 65–70 MB a night. They are still only written when `preserveRawAudio` is on.
- Tests: AudioEngine 37/37, Env 23/23 (3 new `RawLogTests`, 3 new `SessionRawLogWriterTests`).

---

### F22-T2 — `SleepInputs` value type + pure score function

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/networking.md` |
| Status | Done |
| Started | 2026-11-10 |
| Completed | 2026-11-10 |

**Acceptance Criteria:**
- [x] `SleepInputs` (Sendable struct): durations, gaps, snoring bursts by intensity, episodes, sleep stages
- [x] `SleepScore.compute(_ inputs:, config:) -> Int` is pure. `SleepSession.sleepScore(using:)` builds the inputs and calls it, with identical results
- [x] Parameterized tests on plain values: 2 h nap, zero events, 100% epic, caps, clamp
- [x] Existing `SleepScoreTests` still pass unchanged
- [x] Builds with zero errors

**Prompt Used:**
"when i say continue you checkout to feature/f22-architecture-hardening, pull latest and continue with next task"

**Notes:**
- New `Models/Sources/Data/SleepScore.swift`: `SleepInputs` holds exactly what the formula reads: total duration, snoring duration (events + resumed gaps), displayable episode count, measured snoring per intensity (burst sums), sleep-talking count and duration, and `StageStats?`. `enum SleepScore` holds the formula, split into one private function per penalty. The arithmetic is unchanged, down to the expression order, so `Int` truncation matches exactly.
- `SleepSession.sleepInputs` builds the inputs (it still reads `events`, and `snoringDuration` still prefers the cached value). `sleepScore(using:)` is one line.
- `StageStats` is now `Equatable`, so `SleepInputs` can be.
- `SleepScoreFormulaTests`: 14 parameterized cases with the arithmetic in comments, a bounds check over every case, and a custom minimum score. No `ModelContainer` is needed.
- The doc comment on `SleepScore` says the coefficients are hand-tuned heuristics, not a clinical measure. That's the interview's honesty point, written into the code.

---

### F22-T3 — Versioned score cache with one owner

| Field | Value |
|-------|-------|
| Arch Ref | CLAUDE.md "SwiftData Schema Rules" |
| Status | Done |
| Started | 2026-11-10 |
| Completed | 2026-11-10 |

**Acceptance Criteria:**
- [x] ~~`SleepScoreConfig.version`~~ `SleepScore.cacheVersion(for:)` + additive `SleepSession.cachedScoreVersion: String = ""` (see Notes)
- [x] One owner function refreshes score + version; `SessionSummaryView`, `SessionDetailModel`, `StatisticsTab`, `MockDataGenerator` call it (no other `cachedSleepScore =` writers)
- [x] Launch pass recomputes sessions whose version is stale
- [x] Tests: stale version recomputed, current version untouched
- [x] Builds with zero errors

**Prompt Used:**
"continue"

**Notes:**
- **Deviation from the plan: a fingerprint, not a hand-bumped `Int`.** The version is `"<SleepScore.formulaVersion>-<FNV-1a of the config's sorted-key JSON>"`. A coefficient change, like the 0.7 → 0.85 change the interview raised, now makes the cache stale with no manual bump. `formulaVersion` only needs bumping when the formula's *code* changes. `hashValue` can't be used, because it is seeded per launch.
- Owner: `SleepSession.refreshCachedScore(using:)` in `Models/Sources/Data/SleepScoreCache.swift`. It clears `hasCachedScore` first, so `snoringDuration` recomputes from events instead of returning the old cached value.
- Launch pass: `SleepSession.refreshStaleCachedScores(in:config:)` fetches finished sessions with `!hasCachedScore || cachedScoreVersion != current`, refreshes them and saves. `SleepGuardApp.onAppear` runs it before `WidgetSnapshotWriter.update`, so widgets get fresh scores too.
- **First launch after this update recomputes every session once**, because every session's `cachedScoreVersion` is `""`. That's intended: some sessions may have been cached with older coefficients. It runs on the main context. That's fine for a few hundred sessions; a background `ModelContext` would be the fix if it ever shows up as launch time.
- The `SessionDetailModel` recompute on open stays (new HealthKit stages change the inputs), now through the owner.
- Tests: `SleepScoreCacheTests` (6): version stable and sensitive to coefficients, owner writes every field, the stale pass touches only stale/uncached finished sessions, a second pass does nothing, and a config change invalidates everything.

---

### F22-T4 — `Routing` package

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/navigation.md`, `docs/architecture/modules.md` |
| Status | Done |
| Started | 2026-11-10 |
| Completed | 2026-11-10 |

**Acceptance Criteria:**
- [x] `Packages/Routing` holds `RouterDestination`, `SheetDestination`, `RouterPath`; depends only on Foundation + SwiftUI
- [x] `Env` no longer defines routes; features import `Routing` for navigation
- [x] `docs/adr/0001-routing-package.md`: context, decision, consequences. It states honestly that features still rebuild when a route is added; `Env` and `DesignSystem` don't
- [x] `check-layering.py` and `modules.md` updated
- [x] Builds with zero errors; tests pass

**Prompt Used:**
"from now and onwards, can you commit with suggested commit messages. Work on each task by creating branches for each and merge them locally into feature/f22-architecture-hardening … continue with next tasks"

**Notes:**
- `Routing` is a leaf package (no package dependencies, SwiftUI only, Swift 6) with a `RoutingTests` target: navigate/back/root, back on an empty path, unique sheet ids. 3 tests.
- `Env/Router.swift` became `TabCoordinator.swift` (`TabCoordinator`, `TabResetSignal`), importing `Observation` instead of SwiftUI. **`Env` no longer imports SwiftUI anywhere.** `check-layering.py` now fails on `import SwiftUI` in `Env/Sources`, and the old SwiftUI exception for `Router.swift` was removed from CLAUDE.md and AGENTS.md.
- **Deleted the unused `Container.routerPath` factory.** It had zero callers (`RouterPath` is environment-only since F19), and keeping it would have forced an `Env → Routing` edge.
- Wiring: `Routing` added to the Learn, Recordings, Settings, SleepSession and Statistics manifests, and to the app target in `project.pbxproj` (local package ref + product dependency + Frameworks phase). `import Routing` added to 10 package files and 5 app files.
- The doc updates in `docs/architecture/*` and `docs/ProjectArchitecture.md` are local only, because both paths are gitignored.
- Tests: Routing 3, Env 23, Recordings 14, Statistics 8, all passing. App build: 0 warnings, 0 errors.

---

### F22-T5 — Protocol DI pilot: `HealthKitSync`

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/dependencies.md` |
| Status | Done |
| Started | 2026-11-10 |
| Completed | 2026-11-10 |

**Acceptance Criteria:**
- [x] `HealthKitSyncing` protocol (`@MainActor`, `AnyObject`); `HealthKitSync` conforms, init no longer private
- [x] Container registers `Factory<any HealthKitSyncing>`; `SessionDetailModel` resolves it via the container instead of `HealthKitSync.shared`
- [x] New `EnvTestSupport` library with `FakeHealthKitSync`
- [x] `SessionDetailModelTests` uses the fake through `Container.shared.healthKitSync.register { … }`
- [x] Builds with zero errors; tests pass

**Prompt Used:**
"continue with next tasks" (same message as T4; commit + merge locally from T4 on)

**Notes:**
- **Conventions validated for T6:**
  - The protocol is named for its role (`HealthKitSyncing`) and declared at the top of the concrete type's file. The concrete class keeps its name and `.shared`.
  - The protocol is `@MainActor` and refines `AnyObject, Observable`.
  - `init()` is public.
  - The container returns `Factory<any P>` and still aliases `.shared`.
  - `@Observable` owners resolve `Container.shared.service()` in init.
- **Observation through `any P` works:** `OnboardingPageHealthWatchView` reads `healthKitSync.isAuthorized` through the existential, and the app builds with no changes to any view.
- **Test isolation: Factory's `FactoryTesting` `.container` trait** (Factory 3.5.2) gives each test its own container scope through a `TaskLocal`, so `register { fake }` can't leak into parallel tests. The Recordings test target now depends on `FactoryKit` + `FactoryTesting` + `EnvTestSupport`.
- `EnvTestSupport` (`Packages/Env/TestSupport/`) mirrors `ModelsTestSupport`. Env now has 2 library products, so its test scheme is `Env-Package`; `run-tests.sh` already handles that.
- Tests (+2): with enhanced tracking on, the fake's stages are fetched once and stored, and the cached score includes the stage penalty (85). With it off, the fake is never called.
- **Known gap, closed in T6:** `enhancedSleepTracking` is still read from concrete `UserPreferences.shared`, so the suite is `.serialized` and the test restores the flag.
- The app target (`SleepGuardApp`, `StatisticsTab`) still uses `HealthKitSync.shared` directly. That's allowed, since it is the composition root.

---

### F22-T6 — Protocol DI rollout

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/dependencies.md` |
| Status | Done |
| Started | 2026-11-10 |
| Completed | 2026-11-10 |

**Acceptance Criteria:**
- [x] Every container-registered service (Env, AudioEngine, `Theme`) has a protocol + fake; no `private init()` left on services
- [x] `UserPreferences` takes `UserDefaults` (tests use an isolated suite)
- [x] Each fake is used by at least one test or preview
- [x] Builds with zero errors; tests pass

**Prompt Used:**
"continue with next tasks"

**Notes:**
- **17 new protocols**, plus `HealthKitSyncing` from T5:
  - `AppConfigProviding` (DEBUG override API inside `#if DEBUG`)
  - `AudioRecording`, `CustomMelodyStoring`, `HapticFeedbackProviding`, `NotificationPermissionManaging`
  - `PendingSessionStoring`, `RecordingDelayManaging`, `SessionCheckpointStoring`, `SessionManaging`
  - `SnoreInterrupterPlaying`, `SoundAnalysisDetecting`, `UserPreferencesStoring`, `WatchConnectivityManaging`, `TabCoordinating`
  - `SessionRawLogWriting` (an `Actor` protocol)
  - `StorageLimitEnforcing` (`Sendable`, with `@MainActor` requirements matching the implementation)
  - `ThemeProviding` (41 token/helper requirements, generated from `Theme`)
- Every `Container` factory is now `Factory<any P>`, still aliasing `.shared`. Every service init is public.
- **Ripple:** about 30 `theme: Theme` component params and properties became `any ThemeProviding`, and `SessionDetailModel`/`AppBriefingController` take `any AppConfigProviding` / `any UserPreferencesStoring`. **No `@Injected` site changed**, because the type is inferred from the key path. App, widgets and every package build with 0 warnings.
- **Test doubles in `EnvTestSupport`:** `FakeSessionManager`, `FakeAudioRecorder`, `FakeSoundAnalysisDetector`, `FakeSnoreInterrupterPlayer`, `FakeRecordingDelayManager`, `FakeTabCoordinator`, `FakeHapticManager`, `FakePendingSessionStore`, `FakeSessionCheckpointStore`, `FakeCustomMelodyStorage`, `FakeNotificationPermissionManager`, `FakeWatchConnectivityManager`, `FakeStorageLimitEnforcer`, `FakeSessionRawLogWriter`, plus `FakeHealthKitSync` from T5.
- **Deliberate doubles that aren't hand-written fakes:** `UserPreferences.isolated()` / `AppConfig.isolated()` are the real types on a throwaway `UserDefaults` suite (`UserDefaults.isolated()`). Re-implementing 26 `UserDefaults`-backed properties would only create drift. For `Theme`, the double is a separate `Theme()` with tokens changed.
- **Tests:**
  - `ServiceOverrideTests` (10, `@Suite(.container)`): the live default resolution, and each fake replacing its service through the container.
  - `IsolatedStoreTests` (2): preferences don't leak between instances; `AppConfig` persists applied values to its own store.
  - `ThemeOverrideTests` (2).
- `SessionDetailModelTests` dropped the T5 workaround (`.serialized` + flipping `UserPreferences.shared`). It now uses isolated stores and runs in parallel.
- CLAUDE.md / AGENTS.md Dependencies rules now describe the protocol + double conventions.
- Not in scope (T7): `.shared` calls inside `Env` internals and feature views are still there. The protocols make them replaceable, and T7 routes them through the container.

---

### F22-T7 — Remove `.shared` from feature packages

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/dependencies.md`, `docs/architecture/rules.md` |
| Status | Done |
| Started | 2026-11-10 |
| Completed | 2026-11-10 |

**Acceptance Criteria:**
- [x] Zero app-service `.shared` references in feature package sources (system singletons like `UIApplication.shared` excluded)
- [x] `Env` internals resolve collaborators via the container, not `.shared`
- [x] `DesignSystem` no longer depends on `Env` (`RecordingActionButton` takes the haptic as an action; `SnoringTimelineView` import removed)
- [x] `check-layering.py` fails on new feature-package `.shared` service access
- [x] Builds with zero errors; tests pass

**Prompt Used:**
"continue with next tasks"

**Notes:**
- **Feature views (13 files):** `X.shared.` became an `@Injected` property, reusing the view's existing injection where it had one. `RecordingPrestartView` and `RecordingCountdownView` also call `sessionManager.startSession()` through their injected manager now.
- **Feature helpers:** `CustomMelodyRecorder` and `MelodyPreviewPlayer` take `melodyStorage: any CustomMelodyStoring = Container.shared.customMelodyStorage()`.
- **Env internals use constructor injection with container defaults:**
  - `SessionRecordingController`: recorder, interrupter, sound analysis, prefs, pending, checkpoint, raw log
  - `RealtimeDetectionTracker`: same set, minus sound analysis
  - `SnoreInterrupterPlayer`: prefs, melodies, haptics
  - `RecordingDelayManager`: recorder
  - `TabCoordinator`: app config, which now picks its initial tab in `init`
  - `StorageLimitEnforcer` (`Sendable`) and `MockDataGenerator` (static) resolve `Container.shared.userPreferences()` at the call site
- `AudioRecorder` (AudioEngine has no container) takes `soundAnalyzer: any SoundAnalysisDetecting = SoundAnalysisDetector.shared`. That's the one remaining default `.shared`, and it's intentional.
- **Deviation:** `RecordingActionButton` didn't take a haptic action. It uses SwiftUI's `.sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger:)`, the same feedback as `HapticManager.tap()`, so no caller changed and DesignSystem needs no service. **DesignSystem's `Env` dependency is removed** from its manifest.
- `DaySummary.intensityColor` (a model reading `Theme.shared`) was deleted. It duplicated `Theme.intensityColor(_:)`, which the two views now call.
- Swift 6 caught the nudge timer: the haptics existential can't be captured into a nonisolated `Timer` block, so it uses the same `[weak self]` + `Task { @MainActor in }` hop as the stop timer below it.
- `check-layering.py` rule 4 is a regex over the 18 service types, applied to package `Sources` above Env/Routing and excluding `Container.swift`. Checked with a probe file.
- **Tests:**
  - `ConstructorInjectionTests` (5): `TabCoordinator` with hidden tabs and deep links on isolated `AppConfig`; `SnoreInterrupterPlayer` set to "never" or muted doesn't play or buzz, with a fake haptic.
  - `RecordingDelayManagerTests` uses a fresh instance with `FakeAudioRecorder` and is no longer `.serialized`.
  - The fake's `remainingTimeString` now matches the real `MM:SS` format.
- Still `.shared`: `SpeechDetector` / `SnoreDetector` defaults in the tracker. They are AudioEngine helpers, not registered services, and T8 reshapes them.

---

### F22-T8 — Extract pure `DetectionStateMachine`

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/concurrency.md` |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] `DetectionStateMachine` (struct, `AudioEngine`): `mutating func ingest(_ input:, at:) -> [DetectionOutput]`; no clock, no singletons, no SwiftData
- [x] `RealtimeDetectionTracker` becomes an adapter: feeds samples, performs side effects (insert event, clip, melody, checkpoint)
- [x] Behavior unchanged: still driven by the 50 ms loop; existing `DetectionSensitivityTests` pass
- [x] Unit tests for the main transitions (onset, min duration, orphan filter, melody gap, speech)
- [x] Builds with zero errors

**Prompt Used:**
"continue with next tasks" (after T11–T13, which ran first while the user recorded the T9 night)

**Notes:**
- Characterization first: an injectable clock on the old tracker, then 13 end-to-end scripted-sample tests (`DetectionCharacterizationTests`, Env) recorded against it. They passed unchanged after the extraction, and again through the T10 actor.
- API: `ingest(_:at:)`, the melody feedback calls `melodyDidStart(at:)` / `melodyDidStop(at:)`, and `finalizeActiveEvents(at:)`. Outputs come back in the order to perform them.
- The melody is a feedback loop (`melodyRequested` → `melodyDidStart`), because only the player knows whether it actually started (muted, mode "never", file missing).
- Classification stays outside the machine: it takes verdicts, not raw confidences, so T10 could move it independently.
- `DetectionStateMachineTests` (18) cover onset, min duration, the orphan filter, the melody gap and speech.

---

### F22-T9 — Detection replay tests

| Field | Value |
|-------|-------|
| Arch Ref | — |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] 2–4 trimmed excerpts (5–10 min) from a real recording, committed as fixtures (small, compressed if needed). *Changed by the user: a 37-min scripted recording instead of a real night, and the log is format 1, not T1 format (see Notes).*
- [x] Golden expected outputs (events: start, end, intensity) stored alongside
- [x] Replay test feeds each excerpt through `DetectionStateMachine` and diffs against the golden
- [x] A script regenerates goldens on purpose (never silently)
- [x] Tests pass in CI (they run in `run-tests.sh AudioEngine`, which `tests.yml` calls)

**Prompt Used:**
"can i record a 30 min snoring samples for t9, is it enough?" → "i recorded and here is the rawlog file i extracted: …/rawlog_AF51658B-….json"

**Notes:**
- Source: one 37-minute recording on the user's iPhone (2026-11-11), imitated snoring, Snore Interrupter off. 41,594 samples, ordered, no gaps over 0.5 s.
- **The log is format 1.** The phone ran a build from before T1, so there is no `peakDB`, `speechConfidence` or settings metadata. The replay runs at Medium (`minEventDuration` 1.0 s, gate 0.55) with sleep talking off, so **speech detection has no replay coverage**. The T8 characterization tests still cover it. `spectralScore` is 0 throughout.
- 4 fixtures in `Packages/AudioEngine/Tests/Fixtures/Replay/`: `sustained-snoring` (0–7.5 min), `sparse-snores` (7–15), `loud-onset` (15–21), `short-bursts-and-quiet` (23–32). Total 1.1 MB of CSV (rounded levels, no audio).
- Goldens list every decision with its time: event start, finalize (span, intensity, avg/peak dB, confidence, burst count), and discard with reason. Per-sample `melodyRequested` outputs are counted, not listed.
- `scripts/make-replay-fixture.py` cuts excerpts. `scripts/record-replay-goldens.sh` re-records via `TEST_RUNNER_RECORD_REPLAY_GOLDENS=1` and prints the golden diff. Normal runs only compare.
- Mutation check: changing the 10 s silence gap to 9 s failed all 4 replays, each with a first-difference message. Reverted.
- Follow-up: add a T1-format excerpt with sleep talking from a real night.

---

### F22-T10 — `DetectionEngine` actor + `AsyncStream`

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/concurrency.md` |
| Status | Done (real-night check pending) |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] Samples, melody start/stop, settings changes and the session-end flush go into one ordered `AsyncStream`, each timestamped at its source. *Changed by the user (option A): the source is the 50 ms sampler, not each mic buffer and SoundAnalysis result. The stream is `.unbounded`, not `.bufferingNewest(n)` (see ADR 0003).*
- [x] `DetectionEngine` actor runs the state machine; outputs go to a MainActor adapter for side effects
- [x] UI snapshot published at about 5 Hz
- [x] Sample-count thresholds converted to durations (rate-independent)
- [x] Replay tests (T9) still match the goldens, or each difference is explained and approved. *Re-recorded: only event start times moved, 15–26 ms earlier; explained in ADR 0003 and the fixtures README.*
- [x] `docs/adr/0003-detection-actor.md`
- [ ] Builds with zero errors; one real-night check on device. *The build has 0 warnings, and the simulator smoke test (start, record, stop, discard) passed. **The real night is still to do (user).***

**Prompt Used:**
"ok continue with t10", then option A chosen: "keep the 50 ms sampler".

**Notes:**
- `DetectionEngine` (AudioEngine): `Message` = `.sample` / `.melodyDidStart` / `.melodyDidStop` / `.settings` / `.finalize` / `.barrier`. `run(_:perform:)` awaits each `Batch`, and feedback returned from `perform` is applied before the next queued message.
- Tracker: `startEngine()` per session (a generation counter ignores stale batches), `sendSettingsIfChanged()`, `finishDetection()` (flush + await, replaces `finalizeActiveEventsIfNeeded()`), `waitUntilProcessed()` (barrier), 5 Hz display throttle.
- Machine: run start dates replace three counters (`sustainedRunDuration` 75 ms); onset backdates to the run's first sample.
- `.snoreInterrupterDidStop` is posted with the player as sender, and the tracker observes only its own player. This fixes crosstalk between the now-interleaving characterization tests.
- `SessionRecordingController(runsProcessingLoop:)`: test switch so only scripted samples arrive.
- Tests: `DetectionEngineTests` (4 fixtures × 3 delivery patterns vs goldens and vs the bare machine; feedback ordering × 3; control-message order; settings; barrier). The 13 characterization tests pass unchanged. 268 tests total.
- Follow-up: feeding mic buffers directly (option B) once a real night can validate it.

---

### F22-T11 — `VersionedSchema` V1

| Field | Value |
|-------|-------|
| Arch Ref | CLAUDE.md "SwiftData Schema Rules" |
| Status | Done |
| Started | 2026-11-10 |
| Completed | 2026-11-10 |

**Acceptance Criteria:**
- [x] `SleepGuardSchemaV1: VersionedSchema` listing the current models unchanged; `SleepGuardMigrationPlan` with no stages
- [x] `ModelContainer` in app + test support uses the plan
- [x] Verified on a simulator holding existing (pre-T11) data: launches, sessions intact
- [x] CLAUDE.md schema rules updated (how to add V2)
- [x] Builds with zero errors

**Prompt Used:**
"continue with next tasks" (run before T8: T9 needed a recorded night first)

**Notes:**
_Prerequisite for F13 (removing `@Attribute(.unique)` on 4 models needs a real migration)._
- `SleepGuardSchema.container(_:)` calls `ModelContainer(for:migrationPlan:configurations:)`; the app and `TestStore` both use it. `SleepGuardSchema.Current` names the latest version.
- V1 references the live `@Model` classes. It is not frozen as nested copies yet: that would duplicate four models for no behavior. Freezing becomes step 1 of adding V2 (procedure in CLAUDE.md / AGENTS.md).
- Simulator with pre-T11 data: 30 sessions / 614 events / 1 profile / 7 logs / score sum 1744 before and after launch.
- `SleepGuardSchemaTests` (2).

---

### F22-T12 — `DashboardState.make(from:now:)`

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/state.md` |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] The session → `ViewState` mapping in `StatisticsDashboardView` moves to a pure function
- [x] Tests: which night is "last night", a session crossing midnight, force-saved session with a stale cache, no sessions
- [x] Builds with zero errors

**Prompt Used:**
"continue with next tasks"

**Notes:**
- `DashboardState.make(from:now:calendar:)` has no SwiftUI, SwiftData query or clock. The view passes `@Query` results and `Date()`. `StatisticsLoadedView` takes one `state` instead of four values.
- `isLastNight` moved out of the view, so the "LAST NIGHT / LAST TIME" label is testable.
- Behavior kept identical, including the start-date rule for "last night". Changing what counts as a night is a product decision (open).
- `DashboardStateTests` (10).

---

### F22-T13 — CI view-size check

| Field | Value |
|-------|-------|
| Arch Ref | CLAUDE.md "View Componentization" |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] Script fails when a file in `Sources/Views/` or `Sources/Components/` exceeds 200 lines, unless allowlisted
- [x] Allowlist seeded with current offenders (each with a reason)
- [x] Runs in `.github/workflows/layering.yml`

**Prompt Used:**
"continue with next tasks"

**Notes:**
- `scripts/check-view-size.py` covers `Sources/Views/` and `Sources/Components/` in every package; runs in `layering.yml`.
- The allowlist holds the two current offenders (`SleepReportPDFGenerator.swift`, `SessionDetailLoadedView.swift`), each with a line ceiling and a reason. A file that grows past its ceiling fails, and so does a stale entry, so the list only shrinks.
- The 100-line container rule isn't enforced: detecting a "container view" by pattern would be noisy.

---

### F22-T14 — ADRs + docs truth pass + feature doc

| Field | Value |
|-------|-------|
| Arch Ref | — |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] `docs/adr/0002-protocol-services.md` (ADR 0003 was written in T10)
- [x] `TECHNICAL_OVERVIEW.md` claims match the code (tests in CI, test count, measurement mode, tap-thread wording verified against Apple docs). *Edited locally only: the file is untracked by the user's choice.*
- [x] Stale docs deleted or marked historical
- [x] `docs/features/f22-architecture-hardening.md`; `ProjectArchitecture.md` updated (local only: gitignored)
- [x] AGENTS.md / CLAUDE.md rules synced (protocols, Routing, detection actor)

**Prompt Used:**
"continue" (after the T10 handoff)

**Notes:**
- **Tap thread:** Apple's `installTap(onBus:bufferSize:format:block:)` docs say only that the framework "may invoke the `tapBlock` on a thread other than the main thread". They don't call it the real-time render thread. The three code comments in `TapProcessor` / `AudioRecorder` and the overview now say "off the main thread".
- **Measurement mode:** confirmed. `AudioRecorder` sets `.playAndRecord` + `.measurement` in all three session-configuration paths.
- **Tests and CI:** 268 `@Test` functions in 8 packages (AudioEngine 62, Env 53, Models 79, Personalization 30, Statistics 18, Recordings 16, DesignSystem 7, Routing 3), counted from the sources; `tests.yml` runs them on PRs. README, overview and ProjectArchitecture updated from 179/7.
- **Committed docs:** README (package graph with Routing, Env/DesignSystem rows, protocols, detection actor, tests table, CI table, package count), `snore-detection-algorithm.md` (state machine + actor, duration thresholds, first-sample onset, raw log format 2), ADR 0002, feature doc, AGENTS/CLAUDE (detection-stream rule, ADR convention, ADR 0002 link), `Container.swift` comment ("private init" was stale).
- **Historical markers** on F15, F19, F20, F21 feature docs instead of rewriting them: they record what was true then.
- **Tracker truth:** the detail sections of T8, T11, T12 and T13 still said Backlog with unchecked criteria (only the task table had been updated). Filled from their session fragments.
- **Local-only edits** (gitignored or untracked, so not in the commit): `docs/TECHNICAL_OVERVIEW.md` (29 edits; original copy in the session scratchpad), `docs/ProjectArchitecture.md`, `docs/architecture/overview.md`, `dependencies.md`, and `concurrency.md` (from T10).
- `docs/interview-presentation.md` Part 5b still shows `register { FakePreferences() }`. Left as is (user's file); the overview's gotchas section now says what to say instead.
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
