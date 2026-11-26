# F27 — Architecture Interrogation Fixes

**Status:** Done (2026-11-26) · **Branch:** `refactor/f27-architecture-interrogation-fixes` · **Tracker:** [f27](../trackers/f27-architecture-interrogation-fixes.md)

A principal-level review of SleepGuard, SleepGuardUIKitWay and SleepGuardShared (`ARCHITECTURE_INTERROGATION.md`, 68 questions and a 20-item verdict list) named the places where the honest answer was "we'd change this". Every SleepGuard and Shared concern was checked against the code first. Nearly all held, and four were worse than stated: deep links were cleared before their guard, the melody ignored the remote flag, the detail screen saved on every open, and delete removed clips before the save. F27 fixes them in order of harm: data safety, flow correctness, detection parity, then structure and docs. Shared changes shipped as 0.29.1 (strings) and 0.30.0, committed and tagged by the user.

## What changed, by concern

| Concern (review Q) | Before | After |
|---|---|---|
| Store fails to open (Q55) | Release deleted the store: silent, total loss | Release keeps the file, runs in memory, shows a blocking screen; per-version backup before opening (T1) |
| End of night (Q22, Q27, Q28) | Owned by the Statistics tab; hidden tab = no recovery, no low-battery save; three independent sheet owners; deep links dropped | `SessionFlowHost` at the root; one presentation slot ordered by `RootPresentationPolicy`; summary by night ID; deep links wait (T2, ADR 0007) |
| Remote flags (Q50) | Could flip mid-night; melody ignored the flag | Held from start to stop, applied at the stop; melody honours the flag (T3) |
| Detail and lists (Q34, Q56, Q20) | Load saved every time; failed delete did nothing; delete removed clips first; unreachable `.error` | Read-only load + enrichment command; rows before files with an alert; dead states gone (T4) |
| Launch work (Q9, Q54) | Re-score synchronous before first render; a pointless `Task.detached` | Batched, yielding main-context re-score from an ordered root task; dashboard redraws on in-place re-scores (T5) |
| Detection I/O (Q13, Q39) | Checkpoint encode + write inside the awaited `perform` | Coalescing off-main writer; `clear()` synchronous with a sequence gate (T6) |
| Detection parity (Q14) | 50 ms sleep loop (~54 ms real); UIKitWay per buffer | Shared `SampleDecimator`: exact 20 Hz on a time grid (T7, T8) |
| Interruptions (Q17) | A call counted as "not snoring" | Interruption gaps, left out of the score's percentages (formula v2, **user decision**) (T7, T8) |
| Battery/thermal (Q17) | FFT always on; no thermal signal | FFT only with the raw log; thermal state logged (T8) |
| Shared release safety (Q2, Q3, Q6, Q9, Q11, Q36) | `#if DEBUG` in a shared rule; stored types unprotected; no score golden; UIKitWay not built; no skew policy | `SaveRules`; `StoredValue` fixtures; score golden; UIKitWay CI job; skew warning; release and deprecation policy (T7) |
| Module hygiene (Q30, Q63) | Undeclared imports compiled; stale guardrails | `check-imports.py` in CI; guardrails fixed; access-level imports everywhere (T9, T12) |
| Layering (Q31, Q32) | `Env` god module; AudioEngine depended on SwiftData | Config / Health / Platform split, TabCoordinator to Routing (ADR 0008); `Logging` leaf, AudioEngine off Models (T10, T11) |
| Theme (Q21, Q24) | Two theme systems; 40-member `ThemeProviding` | One: the kit's `Theme` in the environment (ADR 0009) (T13) |
| DI (Q23) | Three resolution styles | One outside views: init parameters defaulting to the container (T14) |
| Fakes (Q24, Q59) | Nothing checked fakes against reality | Contract tests for stateful stores; one drifted fake fixed (T15) |
| Dead code, docs (Q67, Q53) | Dead mini player; stale ProjectArchitecture.md; isolation rule unwritten | Removed; rule written; technical overview truthful (T16) |

## Files

| Area | Files | Purpose |
|---|---|---|
| New packages | `Packages/Logging`, `Packages/Config`, `Packages/Health`, `Packages/Platform` | Log leaf; services split by reason to change (ADR 0008) |
| Models | `SleepGuardStore.swift`, `SleepScoreCache.swift`, `SleepSession.swift`, `LoggingExport.swift` | Safe store opening + backup; batched re-score; app-owned `SaveRules`; re-exports Logging |
| AudioEngine | `AudioRecorder.swift`, `TapProcessor.swift`, `ClipSource.swift`, `AudioNotifications.swift` | Per-buffer level callback, interruption reporting, FFT gate; no Models |
| Env | `SessionRecordingController.swift`, `RealtimeDetectionTracker.swift`, `SessionCheckpointStore.swift`, `SessionManager.swift`, `SessionFileCleanup.swift`, `CustomMelodyStorage.swift`, `SnoreInterrupterPlayer.swift`, `Container.swift` | Decimator driver, interruption gaps, off-main checkpoints, DI style, injectable locations |
| Routing | `RootPresentation.swift`, `TabCoordinator*.swift`, `Container+Routing.swift` | Root presentation policy; tab state moved in |
| Recordings / Statistics | `SessionDetailModel.swift`, `SessionDetailLoadedView.swift`, `RecordingsListView.swift`, `StatisticsDashboardView.swift` | Read-only load, enrichment, delete order + alert, score-stamp change detection |
| DesignSystem | `Theme+Intensity.swift`; deleted `AppTheme.swift`, `ThemeProviding.swift`, `Container.swift` | One theme system |
| App target | `SleepGuardApp.swift`, `SessionFlowHost.swift`, `StoreUnavailableView.swift`, `StatisticsTab.swift`, `MainTabView.swift`, `SettingsTab.swift`, `project.pbxproj` | Store safety, root night flow, ordered launch work, new package links |
| Widgets | `SleepGuardWidgets/*` | Environment theme |
| Scripts / CI | `scripts/check-imports.py` (new), `check-layering.py`, `check-view-size.py`, `.github/workflows/layering.yml` | Guardrails |
| Docs | ADRs 0007, 0008, 0009 (new), 0002 and 0005 updated; `CLAUDE.md`, `AGENTS.md`, `TECHNICAL_OVERVIEW.md` | Decisions and rules |

### Tests added

`SleepGuardStoreTests` (5), `RootPresentationPolicyTests` (7), TabCoordinator deep-link wait, `RemoteConfigFreezeTests` (5), detail load/enrich/delete, batched re-score, checkpoint coalescing / clear-wins (mutation-checked), decimator and interruption characterization, spectral gate, `ThemeEnvironmentTests` (3), `StoreContractTests` (4). In Shared: `SampleDecimatorTests`, `CaptureInterruptionTests`, `StoredValuesTests`, `ScoreGoldenTests`. Totals: 237 tests in 8 packages here, 275 in Shared.

## Routes

| Kind | Added / changed |
|---|---|
| Root presentation | `RootPresentation`: `.sessionSummary(id:)`, `.notificationSoftAsk`, `.briefing(id:)` |
| Sheet | `SheetDestination.sessionSummary` removed (now a root presentation) |

## State

| State | Where | Scope |
|---|---|---|
| Root presentation (`presented`, `shown`) | `SessionFlowHost` | App |
| Held remote values | `AppConfig.pendingRemote` | A recorded night |
| Decimator window | `SessionRecordingController` | A recording |
| Checkpoint sequence / gate | `SessionCheckpointStore` / `CheckpointWriter` | App |
| Store failure | `SleepGuardApp.storeOpening` | Launch |

## Edge Cases

- A store that fails to open in Release: the file is kept, the app runs in memory and blocks with an update prompt; nothing writes to the fallback.
- A recovered night with the Statistics tab hidden is offered at launch; a failed low-battery auto-save falls back to the summary.
- Summary and briefing due together: summary first, briefing after it closes; nothing presents into a sheet that is still closing.
- A widget link during a recording waits for the night to end ("Start tracking" while recording is dropped: nothing to start).
- A flag changed mid-night applies at the stop.
- A call mid-event ends the event at its last sample; a night ending mid-call keeps the gap.
- A checkpoint write in flight when the night is saved never brings the file back.

## Open items

- **Device night (user):** confirm the decimator cadence, interruption gaps and thermal logs on a real night.
- **Accuracy benchmark (Q15):** needs labelled nights (F23-T6).
- **Product:** recording can only be started from the Statistics tab.
- Kept by user choice: `StatisticsErrorView`, `RecordingsErrorView` (unused).

### UIKitWay follow-up (for a session in that repo)

The compatibility patch (handles `.interruptionGap`, melody-only gap banner) is with the user. Still to adopt there:
1. **Stored scores never refreshed (Q9):** store `cacheVersion` with summaries and add a launch `RefreshStaleSummaries` use case. Formula v2 makes this urgent: UIKitWay's stored scores are now stale.
2. **Detection parity (Q14):** feed `CaptureSample`s through `SampleDecimator`.
3. **Interruptions (Q17):** send `captureDidPause` / `captureDidResume` from the capture adapter.
4. **`SaveRules` (Q3):** replace `Night.minimumSaveDuration` before 0.31.0 removes it.
5. **Detail CQS and writes (Q34, Q37):** split `LoadSessionDetail` from a stage-enrichment command; a narrow `updateStages` port method instead of wholesale event replacement.
6. **Persistent-history observation (Q37)**, **navigator races (Q45)**, **typed composition instead of the `brand` key (Q47, Q48)**, **checkpoint writes off the capture path (Q13, Q39)**, **batch day delete (Q38)**, and correcting the docs' parity claim (Q14).

## Tasks Completed

F27-T1 … F27-T17 (T7 in the Shared repo: 0.29.1 and 0.30.0).
