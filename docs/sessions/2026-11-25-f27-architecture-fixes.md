---
date: 2026-11-25
feature: F27
branch: refactor/f27-architecture-interrogation-fixes
title: F27 planning (principal review verified), T1 store safety, T2 root night flow, T3 frozen flags, T4 detail/list truth, T5 launch work, T6 checkpoint writer, T7/T8 shared 0.30.0, T9 module hygiene, T10 Logging leaf, T11 Env split, T12 access-level imports, T13 one theme
---

### Completed
- **F27 planned.** Checked every SleepGuard and Shared concern in the principal review (`ARCHITECTURE_INTERROGATION.md`) against the code. Nearly all hold, and four are worse than stated: deep links are cleared before the guard, the melody ignores the remote flag, detail load saves on every open, and delete removes clips before the save. The review's §8 point (`Night` decode precondition) is already handled. 17 tasks; tracker `docs/trackers/f27-architecture-interrogation-fixes.md`.
- **F27-T1 — Never delete the user's store.** A Release build that can't open the store keeps the file, runs on an in-memory store and shows `StoreUnavailableView`. The store is backed up once per app version before opening.
- **F27-T2 — Root owns the night flow and presentation.** `SessionFlowHost` (app root) owns recovery, the summary and the low-battery auto-save, whichever tabs remote config shows. App-level modals share one slot ordered by `RootPresentationPolicy`. The summary is presented by night ID. Widget deep links wait instead of being dropped. ADR 0007.
- **F27-T3 — Flags frozen per recording.** `AppConfig` holds remote updates from start to stop and applies the latest at the stop. The melody honours the remote interrupter flag.
- **F27-T4 — Detail and lists tell the truth.** Read-only detail load plus a separate enrichment command; rows deleted before files, with an alert on failure; unreachable `.error` states removed.
- **F27-T5 — Launch work off the first frames.** Batched, yielding main-context re-score from an ordered root `.task`; the dashboard redraws when nights are re-scored in place.
- **F27-T6 — Checkpoint writes off the detection path.** A coalescing `CheckpointWriter` actor encodes and writes; `clear()` stays synchronous behind a sequence gate.
- **F27-T7 — Shared 0.30.0** (written here, tagged by the user): `SampleDecimator`, interruption gaps with score formula v2, `SaveRules`, stored-value fixtures, score golden, UIKitWay CI job. Plus a 3-file UIKitWay compatibility patch.
- **F27-T8 — Adopt 0.30.0.** Tap → decimator at exact 20 Hz, interruptions recorded and left out of the score, FFT only with the raw log, thermal logging, app-owned Debug save rule.
- **F27-T9 — Module hygiene.** Undeclared imports declared, unused edge removed, `check-imports.py` in CI, guardrail scripts fixed.
- **F27-T10 — `Logging` leaf.** AudioEngine no longer depends on Models (Logging + SleepCore only).
- **F27-T11 — Env split.** Config / Health / Platform packages; TabCoordinator to Routing; ADR 0008.
- **F27-T12 — Access-level imports.** Internal by default in every package; `public import` only where public API needs it.
- **F27-T13 — One theme system.** Views read the kit's `Theme` from the environment; `AppTheme` / `ThemeProviding` deleted. ADR 0009.

### Technical Details
- `SleepGuardStore.open(_:allowDestructiveReset:)` (Models) returns the container plus the failure. Only `#if DEBUG` passes `true`.
- The live store is in the App Group container (SwiftData's `.automatic` group container uses the widget's group). The `default.store` in the app's own Application Support is a stale leftover.
- Strings live in Shared, so T1/T4 strings shipped first as Shared **0.29.1** (user tagged). SleepGuard bumped 0.27.0 → 0.29.1 (0.28/0.29 only added public UI pieces).

### Files Changed
- `Packages/Models/Sources/Data/SleepGuardStore.swift` (new): open-or-fallback, per-version backup.
- `Packages/Models/Tests/ModelsTests/SleepGuardStoreTests.swift` (new): 5 tests.
- `SleepGuard/StoreUnavailableView.swift` (new): blocking screen, same layout as the hard update gate.
- `SleepGuard/SleepGuardApp.swift`: opens through `SleepGuardStore`; launch work, widget snapshot and deep links skip the fallback.
- 9 `Package.swift` + `SleepGuard.xcodeproj/.../Package.resolved`: shared 0.29.1.
- `docs/trackers/f27-architecture-interrogation-fixes.md` (new), `docs/FeatureTracker.md`.

- T2: `Packages/Routing/Sources/RootPresentation.swift` (new), `Packages/Routing/Tests/RootPresentationPolicyTests.swift` (new), `Packages/Routing/Sources/Router.swift`, `Packages/Routing/Tests/RouterPathTests.swift`, `Packages/Env/Sources/Services/{TabCoordinator,TabCoordinating}.swift`, `Packages/Env/TestSupport/FakeSessionServices.swift`, `Packages/Env/Tests/ConstructorInjectionTests.swift`, `SleepGuard/SessionFlowHost.swift` (new), `SleepGuard/{StatisticsTab,MainTabView,SettingsTab,SleepGuardApp}.swift`, `docs/adr/0007-root-session-flow.md` (new), `CLAUDE.md`, `AGENTS.md`.
- T3: `Packages/Env/Sources/Services/{AppConfig,AppConfigProviding,SnoreInterrupterPlayer}.swift`, `Packages/Env/Sources/Services/Session/SessionRecordingController.swift`, `Packages/Env/Tests/RemoteConfigFreezeTests.swift` (new), `Packages/Env/Tests/DetectionCharacterizationTests.swift` (isolated config).
- T4: `Packages/Recordings/Sources/Helpers/SessionDetailModel.swift`, `Packages/Recordings/Sources/Views/{SessionDetailView,SessionDetailLoadedView,RecordingsListView}.swift`, `Packages/Recordings/Tests/SessionDetailModelTests.swift`, `Packages/Statistics/Sources/Views/StatisticsDashboardView.swift`, `Packages/Env/Sources/Services/SessionFileCleanup.swift`, `Packages/Models/Sources/Data/SleepScoreCache.swift`.
- T5: `Packages/Models/Sources/Data/SleepScoreCache.swift`, `Packages/Models/Tests/ModelsTests/SleepScoreCacheTests.swift`, `Packages/Statistics/Sources/Views/StatisticsDashboardView.swift`, `SleepGuard/SleepGuardApp.swift`, `CLAUDE.md`, `AGENTS.md`.
- T6: `Packages/Env/Sources/Services/SessionCheckpointStore.swift`, `Packages/Env/Tests/SessionCheckpointStoreTests.swift`.
- T8: `Packages/AudioEngine/Sources/Engine/{AudioRecorder,AudioRecording,TapProcessor}.swift`, `Packages/Env/Sources/Services/Session/{SessionRecordingController,RealtimeDetectionTracker}.swift`, `Packages/Env/TestSupport/FakeSystemServices.swift`, `Packages/Env/Tests/DetectionCharacterizationTests.swift`, `Packages/Models/Sources/Data/SleepSession.swift`, `Packages/Models/Tests/ModelsTests/SleepGuardSchemaTests.swift`, 9 manifests + lockfile (0.30.0).
- T9: `Packages/{Recordings,AudioEngine,Settings}/Package.swift`, `scripts/check-imports.py` (new), `scripts/check-layering.py`, `scripts/check-view-size.py`, `.github/workflows/layering.yml`, `CLAUDE.md`, `AGENTS.md`.
- T10: `Packages/Logging/` (new: `Package.swift`, `Sources/Log.swift` moved from Models), `Packages/Models/{Package.swift,Sources/Helpers/LoggingExport.swift}`, `Packages/AudioEngine/{Package.swift,Sources/Engine/*}` (incl. `ClipSource.swift` new, `AudioNotifications.swift` moved in), `Packages/AudioEngine/Tests/AudioClipExtractorTests.swift`, `Packages/Recordings/Sources/{Helpers/SnoreEvent+ClipSource.swift,Views/PlayerSheetView.swift}`, `Packages/Env/{Sources/Services/SnoreInterrupterPlayer.swift,Tests/DetectionCharacterizationTests.swift}`, `scripts/check-layering.py`, `CLAUDE.md`, `AGENTS.md`, `docs/TECHNICAL_OVERVIEW.md`.
- T11: `Packages/{Config,Health,Platform}/` (new), `Packages/Routing/{Package.swift,Sources/TabCoordinator*.swift,Sources/Container+Routing.swift,TestSupport/,Tests/TabCoordinator*Tests.swift}`, `Packages/Env/**`, every feature manifest and the files whose imports changed (55), `SleepGuard.xcodeproj/project.pbxproj`, `scripts/check-layering.py`, `CLAUDE.md`, `AGENTS.md`, `docs/adr/0008-env-split.md`.
- T12: every `Packages/*/Package.swift` and 123 source files (import access levels only), `CLAUDE.md`, `AGENTS.md`.
- T13: 37 view files (packages, app target, widgets), `Packages/DesignSystem/{Package.swift,Sources/Components/Theme+Intensity.swift,Tests/ThemeEnvironmentTests.swift}`; deleted `AppTheme.swift`, `ThemeProviding.swift`, DesignSystem `Container.swift`, `ThemeOverrideTests.swift`; `SleepGuard/SleepGuardApp.swift`, `scripts/check-layering.py`, `CLAUDE.md`, `AGENTS.md`, `docs/adr/0009-one-theme-system.md`, `docs/adr/0005-shared-design-kit.md`.

### Architecture Decisions
- Data safety over availability: a store that can't be opened is never touched in Release. The user sees why and is pointed at an update; nothing is recorded into memory.
- One backup copy (the previous version's), taken before the container opens so store, WAL and SHM match.

- T2: app-level flows are owned at the app level (ADR 0007), not by whichever tab is on screen. A pure policy decides presentation; the view only carries it out.
- T5: long SwiftData passes stay on the main context and yield between batches; a background context's saves don't reach objects `@Query` screens hold.
- T7/T8: interruptions are recorded and the score's percentages use measured time (user decision, formula v2); sampling cadence is a shared rule.
- T11: services split by reason to change (ADR 0008); Env sits below navigation (no Routing import).
- T13: theme is a value in the environment (ADR 0009); the DI rule gains `theme` next to `RouterPath`.

### Build Status
- All package tests pass on the pin (AudioEngine 34, DesignSystem 7, Env 63, Models 88, Recordings 10, Routing 3, Statistics 11).
- CI-equivalent Release build (project, pinned lockfile): succeeded.
- Simulator, Release: normal launch wrote the `.bak` files; a corrupt store showed the blocking screen with the file's md5 unchanged; the real store was restored afterwards.

- T2: Routing 9 and Env 64 tests pass. Pinned Release build succeeded. Simulator: recovery with Statistics hidden; summary, then briefing; deferred deep link. Two presentation bugs found this way and fixed (see the tracker).

### Suggested Branch
`refactor/f27-architecture-interrogation-fixes`

### Suggested Commit
`F27-T1 — Never delete the user's store`, `F27-T2 — Root owns the night flow and presentation`, `F27-T3 — Flags frozen per recording`, `F27-T4 — Detail and lists tell the truth`, `F27-T5 — Launch work off the first frames`, `F27-T6 — Checkpoint writes off the detection path`, `F27-T8 — Adopt Shared 0.30.0` (T7 lives in the Shared repo), `F27-T9 — Module hygiene and guardrails`, `F27-T10 — Logging leaf; AudioEngine off Models`, `F27-T11 — Split Env by reason to change`, `F27-T12 — Access-level imports`, `F27-T13 — One theme system`

### Changes done
- Store opening moved to `SleepGuardStore`; Release fallback is in-memory plus a blocking screen.
- Per-version store backup.
- Shared bumped to 0.29.1.

### Next Session
- F27-T14: two dependency-resolution styles.

### Open Questions
- `StatisticsErrorView` / `RecordingsErrorView` are unused after T4 (kept by user choice); revisit in T16.
- Recording can only be started from the Statistics tab, so hiding that tab remotely removes recording altogether. This is a product decision, recorded here and not fixed in F27.
