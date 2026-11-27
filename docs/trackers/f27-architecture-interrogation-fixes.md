# F27 — Architecture Interrogation Fixes

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P0 (T1) / P1 |
| **Version** | V5 |
| **Blocked By** | — |
| **Started** | 2026-11-25 |
| **Completed** | 2026-11-26 |
| **Feature Doc** | [f27](../features/f27-architecture-interrogation-fixes.md) |
| **Branch** | `refactor/f27-architecture-interrogation-fixes` (one branch, one commit per task; the user merges it into `main`) |

## Summary

Fixes the verdicts of the principal-level architecture review (`ARCHITECTURE_INTERROGATION.md`, 2026-11-19), each checked against the code first. Order: data safety, flow correctness, detection parity, then structure and docs. SleepGuard + SleepGuardShared (the user commits and tags Shared); UIKitWay items go to a follow-up list.

### Decisions (user, 2026-11-25)
- Scope: SleepGuard + Shared. UIKitWay as a follow-up.
- Cadence (Q14): a shared `SampleDecimator` with the same (latest-value) output as today.
- Big refactors: all four (one theme system, Env split, Logging leaf, access-level imports).
- Protocols (Q24): keep them all; add contract tests for stateful fakes.
- Git: one refactor branch, a commit per task named after it, no sub-branches.
- Strings live in Shared, so new strings ship first as a small Shared release (0.29.1).

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F27-T1 | Never delete the user's store (Q55) | Bug / Data safety | Done | Shared 0.29.1 (strings) | Models / App | 2026-11-25 | 2026-11-25 |
| F27-T2 | Root owns the night flow and presentation (Q22, Q27, Q28, Q26) | Refactor / Bug | Done | — | Routing / Env / App | 2026-11-25 | 2026-11-25 |
| F27-T3 | Flags frozen per recording (Q50) | Bug | Done | — | Env | 2026-11-25 | 2026-11-25 |
| F27-T4 | Detail and lists tell the truth: CQS load, delete order + alert, no dead `.error` (Q34, Q56, Q20) | Bug / Refactor | Done | Shared 0.29.1 | Recordings / Statistics / Env / Models | 2026-11-25 | 2026-11-25 |
| F27-T5 | Launch work off main; owned tasks (Q9, Q54) | Perf | Done | T2 | Models / Statistics / App | 2026-11-25 | 2026-11-25 |
| F27-T6 | Checkpoint writes off the detection path (Q13/Q39) | Perf | Done | — | Env | 2026-11-25 | 2026-11-25 |
| F27-T7 | Shared 0.30.0: decimator, interruption gaps, SaveRules, stored-type fixtures, score golden, CI (Q14, Q17, Q3, Q11, Q9, Q6, Q2) | Shared | Done (user tags 0.30.0) | — | SleepGuardShared (+ UIKitWay compat patch) | 2026-11-25 | 2026-11-25 |
| F27-T8 | Bump to 0.30.0 and adopt: decimator driver, interruption gaps, FFT gate, thermal log, SaveRules | Detection | Done | T7 | Env / AudioEngine / Models | 2026-11-25 | 2026-11-25 |
| F27-T9 | Module hygiene: declared deps, import checker, guardrail fixes (Q30, Q63) | Infra | Done | — | all / scripts | 2026-11-25 | 2026-11-25 |
| F27-T10 | `Logging` leaf; AudioEngine off Models (Q32) | Refactor | Done | T9 | Logging / AudioEngine / Models / Recordings | 2026-11-25 | 2026-11-25 |
| F27-T11 | Split Env by reason to change (Q31) | Refactor | Done | T10 | Env → Config / Health / Platform / Routing | 2026-11-25 | 2026-11-25 |
| F27-T12 | Access-level imports (Q30) | Refactor | Done | T11 | all | 2026-11-26 | 2026-11-26 |
| F27-T13 | One theme system (Q21) | Refactor | Done | T12 | DesignSystem / views / widgets | 2026-11-26 | 2026-11-26 |
| F27-T14 | Two dependency-resolution styles (Q23) | Refactor | Done | T11 | Env / Recordings / AudioEngine | 2026-11-26 | 2026-11-26 |
| F27-T15 | Contract tests for stateful fakes (Q24/Q59) | Tests | Done | T11 | Env | 2026-11-26 | 2026-11-26 |
| F27-T16 | Dead code and docs (Q67, Q53) | Cleanup | Done | — | Recordings / docs | 2026-11-26 | 2026-11-26 |
| F27-T17 | Close out: feature doc, ADRs, UIKitWay follow-up list | Docs | Done | all | docs | 2026-11-26 | 2026-11-26 |
| F27-T18 | Shared HealthKit and raw-log behaviour (shared 0.32.0) | Refactor | Done | T17 | Health, Services | 2026-11-26 | 2026-11-26 |
| F27-T19 | Remove DesignSystem duplicates of the shared kit | Refactor | Done | T17 | DesignSystem, widgets | 2026-11-26 | 2026-11-26 |
| F27-T20 | Rename `Env` to `Services` | Refactor | Done | T19 | all packages | 2026-11-26 | 2026-11-26 |
| F27-T21 | Shared settings (shared 0.33.0) | Refactor | Done | T20 | Config | 2026-11-26 | 2026-11-26 |
| F27-T22 | Uniform the apps, release A (shared 0.34.0) | Refactor | Done | T21 | Models, Services, AudioEngine, Personalization, app | 2026-11-26 | 2026-11-26 |
| F27-T23 | Uniform the apps, release B: shared audio (shared 0.35.0) | Refactor | Done | T22 | AudioEngine, Services, Recordings, SleepSession | 2026-11-26 | 2026-11-26 |
| F27-T24 | Uniform the apps, release C: one SwiftData schema (shared 0.36.0) | Refactor | Done | T23 | Models, Services, Recordings, Statistics, DesignSystem, Health, app | 2026-11-26 | 2026-11-26 |
| F27-T25 | Uniform the apps, close-out (ADR 0010, docs) | Docs | Done | T24 | docs | 2026-11-26 | 2026-11-26 |
| F27-T26 | Explicit imports: no `@_exported` | Refactor | Done | T25 | every package, app, scripts | 2026-11-26 | 2026-11-26 |
| F27-T27 | No re-exports in the shared repo (shared 0.37.0) | Refactor | Done | T26 | manifests | 2026-11-26 | 2026-11-26 |
| F27-T28 | App folders, unused sounds removed, SleepGuardShared declared by the project | Refactor | Done | T27 | app target, project, scripts | 2026-11-27 | 2026-11-27 |
| F27-T29 | Local packages as a Packages folder in the project | Refactor | Done | T28 | project | 2026-11-27 | 2026-11-27 |
| F27-T30 | The workspace builds the pinned release (no local override) | Refactor | Done | T29 | workspace, docs | 2026-11-27 | 2026-11-27 |
| F27-T31 | Features as one package, a target per feature (ADR 0011) | Refactor | Done | T30 | Features, project, scripts, docs | 2026-11-28 | 2026-11-28 |

## Task Details

### F27-T1 — Never delete the user's store

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q55, Q68; CLAUDE.md "Versioned schema" |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] Release builds never delete the store: on open failure the file stays, the app runs on an in-memory store and shows `StoreUnavailableView`
- [x] Debug keeps the delete-and-retry reset (dev schema changes)
- [x] The store (+ `-wal`/`-shm`) is copied to `.bak` once per app version before opening
- [x] Nothing (recovery, cleanup, re-score, widget snapshot, deep links) touches the in-memory fallback
- [x] Tests: corrupt store kept and in-memory fallback; Debug reset; healthy open; backup once per version; no store → no backup
- [x] Builds with zero errors; Models tests pass

**Prompt Used:**
"can you make a plan with a refactor feature to fix all issues mentioned on …ARCHITECTURE_INTERROGATION.md"

**Notes:**
- `SleepGuardStore` (Models) owns opening: `open(_:allowDestructiveReset:)` returns the container and the failure, if any. The app passes `true` only under `#if DEBUG`. The in-memory fallback `fatalError`s only when even an in-memory store can't be created (nothing could work then).
- The live store is in the **App Group container** (`group.com.dardan.SleepGuard/Library/Application Support/default.store`): SwiftData's `.automatic` group container picks the widget's app group. The `default.store` in the app's own Application Support is a stale leftover from before the group existed; nothing reads it.
- Backup: the store and its `-wal`/`-shm` are copied as a set *before* the container opens, so the copy is consistent. Marker file `default.store.bak-version`. One copy only (the previous version's), so disk use is one extra store.
- `StoreUnavailableView` (app target) copies the hard update gate's layout; the design file has no screen for this. Strings ship in Shared 0.29.1.
- Gated on the failure: launch work in `onAppear`, widget snapshot on background, deep links. The update gate overlay still shows on top if remote config asks for it.
- Simulator (Release build, workspace): normal launch wrote `.bak` files plus marker 1.0.0. A corrupt `default.store` showed the blocking screen, and the file's md5 was unchanged after launch. The real store was restored afterwards and the app opened with its data.
- Found: `check-layering.py` scans ignored `.build/index-build` checkouts → false violations locally (fix in T9).
- Tests: `SleepGuardStoreTests` (5). Models: 88 tests pass.

---

### F27-T2 — Root owns the night flow and presentation

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q22, Q26, Q27, Q28; ADR 0001; new ADR 0007 |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] Recovery, the summary and the low-battery auto-save work with the Statistics tab hidden (`SessionFlowHost` at the root)
- [x] One root presentation slot: summary > soft-ask > briefing, never over a sheet that is up or closing, never while recording (`RootPresentationPolicy`, 7 tests)
- [x] The summary is presented by night ID; `SheetDestination.sessionSummary` removed
- [x] A deep link that arrives while recording or while a night waits to be saved is routed afterwards, not dropped (`takePendingDeepLink(blocked:)`, tested)
- [x] `StatisticsTab` is the dashboard only
- [x] ADR 0007; navigation rule updated in CLAUDE.md and AGENTS.md
- [x] Builds with zero errors; Routing (9) and Env (64) tests pass

**Prompt Used:**
"continue"

**Notes:**
- Recovery moved from `SleepGuardApp.onAppear` into the host's `.task`, ahead of the briefing, so a recovered night outranks the prompts. The host only exists after onboarding and when the store opened (T1).
- **Bug found on the simulator and fixed:** Discard clears `completedSession` before the summary calls `dismiss()`. That empties the sheet's content, so the dismiss reaches nothing and an empty sheet stays up. The host now closes the summary as soon as its night is resolved.
- **Second bug, found by reading the code and fixed:** `presentNext()` ran while the summary was still closing and presented the briefing into the closing sheet. The briefing was then marked shown without being seen. The policy now treats the sheet that is still closing (`shown`) as current.
- "Start tracking" from the widget while already recording is dropped (nothing to start). Every other link waits.
- Removed `RouterPathTests.sheetIDsAreUnique`: `SheetDestination` has one case now; ID uniqueness is covered for `RootPresentation`.
- Simulator (Debug, workspace), with Statistics hidden through the debug tab override and a planted checkpoint: the summary is offered at launch, and Discard returns to Sessions/Settings/Learn. Statistics visible: summary, then Discard, then the briefing, then Close, then the dashboard (briefing marked shown, checkpoint cleared). `sleepguard://last7nights` opened while the summary was up was routed to Last 7 Nights after Discard.
- Not verified on the simulator: the low-battery auto-save (the simulator reports battery -1); it uses the same `SessionCommitter` path as before.

---

### F27-T3 — Flags frozen per recording

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q50 |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] Remote values that arrive while a night records wait and apply at the stop (`AppConfig.holdRemoteUpdates` / `releaseRemoteUpdates`; the latest values win)
- [x] `SessionRecordingController` holds from a successful start to the stop
- [x] The melody honours the remote `snoreInterrupter` flag (before, it ignored it); frozen, so the melody and its Mute/Stop controls agree all night
- [x] Tests: hold/release, latest-wins, immediate when not held, controller start→stop, melody off remotely (5)
- [x] Builds with zero errors; Env tests pass (69)

**Prompt Used:**
"continue"

**Notes:**
- One mechanism instead of a snapshot per flag: everything that reads `AppConfig` during the night (bedside overlay, player, visible tabs) sees the same values, and tabs can't disappear mid-recording.
- Debug overrides still apply immediately (deliberate: a developer flipping a switch expects it).
- The hold lives in memory: if the app is killed mid-night, the next launch fetches again.
- `RemoteConfigLoader` is unchanged; it keeps refreshing on foreground, and `AppConfig` decides when values apply.
- Not verified on the simulator: a mid-night remote flip can't be forced there, and debug overrides bypass the hold. Covered by the unit tests.

---

### F27-T4 — Detail and lists tell the truth

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q34, Q56, Q20 |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] `SessionDetailModel.load` is read-only; `enrichIfNeeded` is the separate command (late HealthKit stages, stale cached score) and saves only when something changed
- [x] A failed enrichment save is logged and leaves the loaded night on screen (it used to turn the screen into `.error`)
- [x] Delete order: rows first, then files once saved (a failure leaves orphan files, never a night without clips); rollback on failure
- [x] Failed deletes show an alert on the detail screen and the nights list (they used to do nothing)
- [x] Unreachable `.error` removed from `StatisticsDashboardView` and `RecordingsListView`
- [x] Builds with zero errors; Recordings (12), Models (88), Statistics (11), Env (69) pass

**Prompt Used:**
"continue"

**Notes:**
- `SleepSession.hasStaleCachedScore(for:)` (Models) reads only the cached fields. `sessionFileURLs(_:)` / `removeFiles(_:)` (Env) let callers collect a night's files before deleting the rows; `deleteSessionFiles` is now a wrapper over them (Settings' delete-all still uses it, unchanged).
- Deleting a night that's already gone now counts as done (the screen dismisses) instead of failing.
- **User decision:** keep `StatisticsErrorView.swift` and `RecordingsErrorView.swift`, now unused. Listed for T16.
- Not forced: a failing save (an in-memory SwiftData store can't be made to fail), so the alert path is checked by build and reading only.
- Simulator (Debug): detail of 11 Nov loads through the read-only path; trash deletes it, the screen dismisses, the list updates. The simulator store was restored from the T1 backup afterwards.

---

### F27-T5 — Launch work off the first frames; owned tasks

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q9 (follow-up), Q54, Q20 |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] The stale-score refresh no longer runs synchronously before first render: batches of 50, a save and `Task.yield()` after each
- [x] Launch housekeeping runs from the root's `.task`, in order: storage limits, re-score, widget snapshot (the pointless `Task.detached` is gone)
- [x] Screens update when nights are re-scored in place (dashboard change detection on cached score + version)
- [x] Concurrency rule in CLAUDE.md / AGENTS.md
- [x] Builds with zero errors; all package tests pass

**Prompt Used:**
"continue"

**Notes:**
- **Deviation from the plan, on evidence:** the plan said "background `ModelContext`". Built that way (`@ModelActor`), the simulator showed the dashboard keeping the old scores until the next launch: saves from another context don't refresh objects the main context already holds. Switched to batched main-context passes that yield. The first frames still render first, and screens update as batches land.
- **The principal's Q20 subtlety, confirmed live:** `.onChange(of: sessions)` compares identities, so a night re-scored in place never redrew the dashboard. It now watches `ScoreStamp`s (id, cached score, version), which are cached fields only, so there is no faulting. Before T5 this was hidden because the re-score ran synchronously before the dashboard first computed.
- Storage limits stay on the main context (the enforcer is `@MainActor`); it only removes files of saved nights over a limit, never "unreferenced" files, so a recovered night's clips are safe.
- Not done from the plan: storing `SessionCommitter.commit`'s follow-up `Task` in the callers. The follow-up must outlive the summary sheet that starts it, so a view-held handle adds nothing. The rule now names the service as its owner; tests already await the returned task.
- Simulator (Debug): a debug score-config override re-scored 31 nights at launch (log); the dashboard showed the stricter scores (a red W bar). Removing the override re-scored 31 back, and the dashboard returned to the real colours **in the same launch**.
- Tests: `stalePassWorksThroughLongHistoriesInBatches` (120 nights, batch 50); the existing refresh tests now `await`. Models 89.

---

### F27-T6 — Checkpoint writes off the detection path

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q13, Q39; ADR 0003 |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] `write` hands the snapshot to `CheckpointWriter` (actor) and returns; encoding and the atomic write happen off the main actor, so detection's awaited `perform` no longer waits on disk
- [x] Bursts collapse to the latest snapshot; an older one arriving late is ignored
- [x] `clear()` stays synchronous, and a write still in flight can't bring back a cleared file (sequence gate under a lock)
- [x] Tests: in-flight write after clear (mutation-checked), write after clear kept, burst collapses (<10 disk writes, latest lands), existing tests now flush
- [x] Builds with zero errors; Env 72 tests pass

**Prompt Used:**
"continue"

**Notes:**
- Why `clear()` isn't async: the committer clears right after saving. A clear that lagged behind could leave the file for a kill to find, and the saved night would be offered again (the F23-T1 bug class).
- The snapshot value is still built on the main actor (copying the night's fields and events); only encoding and I/O moved. The protocol is unchanged, so fakes and callers didn't change.
- Mutation check: with the gate disabled, `aWriteInFlightNeverBringsBackAClearedFile` fails.
- Not checked on the simulator: a mid-night checkpoint needs a recording with events (or 2 min). Covered by the store tests; the detection characterization tests (fake store) pass unchanged.

---

### F27-T7 — Shared 0.30.0

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q14, Q17, Q3, Q11, Q9, Q6, Q2, Q36 |
| Status | Done (written here; committed and tagged by the user) |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] `SampleDecimator`: per-buffer readings → 20 Hz, latest-value, time-anchored (no drift), re-anchors after a pause (4 tests)
- [x] Interruptions: `RecordingGap.Kind` (melody / interruption; missing or unknown decodes as melody), engine messages `captureDidPause` / `captureDidResume`, output `.interruptionGap`, open events end at their last sample, a night ending mid-call keeps the gap
- [x] Score formula v2 (**user decision**: record and exclude): snoring and sleep-talking percentages use measured time (`SleepInputs.unmeasuredDuration` = interruption time); melody gaps score exactly as before; `formulaVersion` 2 → every app re-scores once at launch
- [x] `SaveRules` (`.standard` = 30 min); `Night.minimumSaveDuration` deprecated for one minor (removed in 0.31.0)
- [x] `StoredValue` marker + `StoredValuesTests` decoding frozen 0.29.0 / 0.30.0 fixtures of every stored type and raw value
- [x] `ScoreGoldenTests`: a known night's score and the literal `cacheVersion`, so a formula change without a version bump fails
- [x] Interruption banner (DesignKit) + string; ContentKit shows melody and interruption banners separately
- [x] CI: `uikitway` job (every brand, Tuist local mode), content kit + melodies tests in `ui`, consumer-skew warning (>2 minors); README release policy
- [x] SleepCore 229 tests (macOS), strings 2 + melodies 2 + design kit 30 + content kit 12 (simulator)

**Notes:**
- **UIKitWay compatibility patch** (user decision; uncommitted there, the user merges): handle `.interruptionGap` in `RecordingSession.perform`, show the gap banner for melody gaps only. Built the SleepGuard brand against the candidate in Tuist local mode: succeeded. Its full adoption (decimator, capture messages, `SaveRules`, stored-score refresh) stays on the follow-up list.
- The replay goldens didn't change: no fixture contains an interruption, and the decimator isn't in the replay path.

---

### F27-T8 — Adopt Shared 0.30.0

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q14, Q17, Q3; ADR 0003 |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] Shared pinned at 0.30.0 (9 manifests + app lockfile)
- [x] Detection samples come from the tap through `SampleDecimator` (20 Hz, time-anchored); the old 50 ms sleep loop is now a 1 Hz housekeeping tick (battery every ~30 s, checkpoint every ~2 min), which also runs during interruptions
- [x] Audio interruptions reach detection through the stream (`captureDidPause` / `captureDidResume`); open events end; the span is stored as an interruption gap
- [x] FFT runs only with the raw-audio debug log on (`AudioRecording.computesSpectrum`)
- [x] Thermal state logged at start and on change (`Log.session` + signpost); no behaviour change
- [x] `SleepSession.saveRules`: Debug 2 min chosen by the app, Release `.standard`
- [x] Tests: same night at 43 Hz and 47 Hz through the tap; a call ends the event and becomes an interruption gap; the pre-move fixture store's cached score is stale under formula v2 and recomputes to the same 78
- [x] Builds with zero errors; all package tests pass on the pin

**Prompt Used:**
"continue" / "done tagging"

**Notes:**
- Detection output for the same samples is unchanged (characterization tests and shared replay goldens). What changed is *which* samples: no more 4 ms drift per tick, and no stale samples while the mic is interrupted.
- `averageSpectralScore` becomes 0 with the raw log off. Nothing displays it, and the one rule that reads it (short events with no ML confidence) can't fire live.
- Simulator (Debug, raw log on): a 20 s recording logged 400 samples over 19.95 s, every interval exactly 50 ms (it was ~54 ms). "Session Too Short" showed the 2-minute Debug rule. Discard removed the raw log and checkpoint. Thermal state `nominal` logged.
- **History:** the T8 code first landed in `b41f6d1` under the Shared commit message (the Shared commit command also ran in this repo). With the user's OK that tip commit was amended into this task's commit, together with the bump.
- Not tested on the simulator: a real audio-session interruption (no call on the simulator). Covered by the harness test through the recorder's callback.

---

### F27-T9 — Module hygiene and guardrails

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q30, Q63, Q67, Q29 |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] `Recordings` declares `AudioEngine`; `AudioEngineTests` declares `Models`; the unused `Settings → Personalization` edge is gone
- [x] `scripts/check-imports.py` in CI (`layering.yml`): every import of a project module must be declared or re-exported by a declared dependency. On the old manifests it flags exactly the 7 leaks the review sweep found
- [x] `check-view-size.py` also scans the app target (65 files)
- [x] `check-layering.py`: skips `.build/` checkouts (no more local false positives), drops the stale `BriefingEngine` / `QuoteBank` allowlist (moved to Shared in F26), the singleton pattern names `AppTheme` (it named a `Theme` type that no longer exists)
- [x] CLAUDE.md / AGENTS.md: no feature-to-feature edge today; the import check; app target in the size check; stale allowed-exception removed
- [x] Builds with zero errors; AudioEngine 35, Recordings 12 tests pass

**Prompt Used:**
"done tagging" (continued)

**Notes:**
- Not done from the plan: banning `AppTheme.shared` / `Container.shared` in the app target. The rule says the app target is the composition root and holds `.shared` references, so the ban would contradict it; T13 removes `AppTheme` as a service anyway.
- The import check is textual (manifest parsing + `import` lines). Access-level imports (T12) make the compiler enforce the same thing.

---

### F27-T10 — `Logging` leaf; AudioEngine off Models

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q32 |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] `Packages/Logging` (imports only `os`) holds `Log` and the signposter (moved with history)
- [x] `AudioEngine` depends on `Logging` + `SleepCore` only; no `Models`, so no SwiftData or schema in the audio layer
- [x] Audio notification names moved to `AudioEngine` (it observes them; Env posts them)
- [x] Clip extraction and the legacy player take a `ClipSource` value instead of `SnoreEvent`; Recordings maps with `SnoreEvent.clipSource`
- [x] Layering check treats `Logging` as core; docs point at the new path
- [x] Builds with zero errors; AudioEngine 35, Models 89, Env 74, Recordings 12 pass; import check 22 targets / 13 packages

**Prompt Used:**
"done tagging" (continued)

**Notes:**
- **Deviation from the plan:** `Models` re-exports `Logging` (`@_exported import Logging`) instead of every logging file importing it. Code that already imports `Models` (including the app target, whose Xcode project would otherwise need a new package reference) keeps reaching `Log`; the leaf still lets `AudioEngine` drop `Models`. `check-imports.py` accounts for re-exports.
- The `extractClips(events:)` / `extractSingleClip(for:)` overloads now take `ClipSource`; the value-based overload most callers use is unchanged.

---

### F27-T11 — Split Env by reason to change

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q31, Q29; ADR 0008 (new) |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] `Config` (AppConfig, UserPreferences; ConfigTestSupport with isolated stores), `Health` (HealthKitSync + fake), `Platform` (haptics, notifications, Watch + fakes); files moved with history
- [x] `TabCoordinator` / `TabCoordinating` / `TabResetSignal` (+ fake, tests) moved to `Routing` (**user decision**)
- [x] Each package registers its own factories; Env keeps the recording night only
- [x] Features declare only what they use: Statistics, Learn, Personalization no longer depend on Env; `check-imports.py` passes (30 targets, 16 packages)
- [x] App target links Config, Health, Platform (`project.pbxproj`, mirrored from the Routing entries; `plutil -lint` OK)
- [x] Env must not import Routing (layering rule 3); CLAUDE.md / AGENTS.md DI and package rules; ADR 0008
- [x] Builds with zero errors (pinned Release + workspace); all package tests pass (Config 4, Env 66, Routing 14, others unchanged); app launches on the simulator

**Prompt Used:**
"Config/Health/Platform (Recommended)"

**Notes:**
- Imports were rewritten by a script that looks at the symbols each file uses (scratchpad `rewrite_imports.py`), then manifests were fixed from `check-imports.py`'s output.
- Test counts moved, nothing lost: Env 74 → 66 (LearnTabOrder 4 → Config, TabCoordinator 4 → Routing), Routing 9 → 14 (+ the TabCoordinator override test split out of `ServiceOverrideTests`).
- During the move a script stopped halfway and cut `FakeTabCoordinator` out before writing its new file; it was restored from `HEAD` before anything else changed.

---

### F27-T12 — Access-level imports

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q30 (follow-up) |
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `InternalImportsByDefault` enabled in every target of all 16 packages
- [x] `public import` only where a file's public API exposes the module's types (225 imports in 123 files), driven by the compiler's notes
- [x] `@_exported` re-exports kept (DesignSystem's kits, Models' Logging)
- [x] Rule in CLAUDE.md / AGENTS.md
- [x] All 16 packages build; all package tests pass; pinned Release app build succeeds; import and layering checks pass

**Prompt Used:**
"Full migration" (user chose it over the lighter MemberImportVisibility after seeing the 112-file scope)

**Notes:**
- Automated: a loop built each package in dependency order, read `… is imported by this file as 'internal' from 'X'` notes, and made exactly that import public (scratchpad `t12_loop.py`). Env took 18 passes; most packages 1–6.
- What it closes, precisely: a package's dependencies no longer leak their symbols to its clients. It doesn't stop a target from importing a module it never declared (module search paths); `check-imports.py` (T9) covers that.
- The app target isn't a package and already uses `MEMBER_IMPORT_VISIBILITY`; unchanged.

---

### F27-T13 — One theme system

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q21, Q24, Q67; ADR 0009 (new), ADR 0005 (bridge superseded) |
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] Every view (packages, app target, widgets) reads `@Environment(\.theme)`; the app root sets `.sleepGuard`
- [x] Members mapped to the kit: `theme.palette.*`, `theme.radii.card/small`, `scoreColor` (kit), `intensityColor` (new DesignSystem extension)
- [x] Deleted (**user approved**): `AppTheme.swift`, `ThemeProviding.swift`, DesignSystem `Container.swift`, `ThemeOverrideTests.swift`; replaced by `ThemeEnvironmentTests` (3); DesignSystem dropped Factory
- [x] Rules: `@Environment` holds `RouterPath`, `theme` and system values; layering singleton list without `AppTheme`; ADR 0009
- [x] No visual change: Settings content pixel-identical before/after (only the status-bar clock and the translucent tab bar differ); dashboard matches
- [x] Builds with zero errors (workspace + pinned Release); all package tests pass

**Prompt Used:**
"Yes, delete them"

**Notes:**
- Codemod over 37 files plus 2 hand fixes in widgets: the per-file check missed a second view struct in `LastNightMediumView.swift`, and `LastNightWidgetView.swift` was moved from a static `Theme.sleepGuard` to the environment.
- `docs/TECHNICAL_OVERVIEW.md` still mentions `AppTheme`; corrected in the T16 truth pass.

---

### F27-T14 — One dependency-resolution style outside views

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q23 |
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `SessionDetailModel`: `healthKitSync` is an init parameter defaulting to the container (was resolved in the init body)
- [x] `SessionManager`: an internal designated `init(recording:detection:)` plus a public convenience `init()` that passes the container's composition
- [x] `RealtimeDetectionTracker`: `snoreDetector` and `speechDetector` are parameters defaulting to new Env container factories (were `.shared`); the characterization harness now passes its own `SpeechDetector`, so parallel tests don't share classifier state
- [x] `SpeechDetector.init` internal like `SnoreDetector`'s (it was `private`, against the "inits are never private" rule)
- [x] Rule in CLAUDE.md / AGENTS.md, with the two honest exceptions
- [x] Builds with zero errors; Env 66, Recordings 12, AudioEngine 35 pass

**Prompt Used:**
"continue" (F27 run)

**Notes:**
- Not changed, by design: `AudioRecorder`'s `SoundAnalysisDetector.shared` default. AudioEngine has no DI, and that default is what Env's `soundAnalysisDetector` factory returns. `StorageLimitEnforcer` resolves preferences at the call because a `Sendable` type can't store the main-actor service; commented in place.
- `MockDataGenerator` (Debug-only static helper) still reads the container inline; it isn't a type with collaborators.

---

### F27-T15 — Contract tests for stateful fakes

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q24, Q59; ADR 0002 |
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `StoreContractTests`: one suite run against the real store and its fake, for `SessionCheckpointStoring` and `CustomMelodyStoring` (4 tests)
- [x] **Drift found and fixed:** `FakeSessionCheckpointStore` offered a snapshot with no events; the real store refuses it. The fake now matches
- [x] Real stores run in isolation: `CustomMelodyStorage(defaults:directory:)` and `SessionCheckpointStore(url:)` take their location (app defaults unchanged); `SessionCheckpointStoreTests` no longer share one file or run serialized
- [x] Removed (**user approved**) 4 `ServiceOverrideTests` cases that only called back the fake they registered
- [x] ADR 0002 counts and text updated
- [x] Builds with zero errors; Env 66 tests pass

**Prompt Used:**
"Keep, add contract tests" / "Yes, delete the 4"

**Notes:**
- Scope, honestly: only stores whose state is visible through their own protocol get a contract. `FakePendingSessionStore`, `FakeStorageLimitEnforcer` and `FakeSessionRawLogWriter` are effect-only (they count or record calls), where a spy is the right double (the review's Q60 rule); their real types have their own tests.
- Writing the contract also exposed a test-isolation bug: two suites drove `SessionCheckpointStore.shared` (one file on disk) in parallel and clobbered each other. Fixed by the injectable URL.

---

### F27-T16 — Dead code and docs

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q67, Q53, Q20 |
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] Deleted (**user approved**): `SessionDetailMiniPlayerView.swift` and the dead `fakePlayerSection` / marker helpers in `SessionDetailView.swift` (and the `Models` import that only they used)
- [x] Deleted (**user approved**): `docs/ProjectArchitecture.md` (stale; it was git-ignored, so only the local copy existed). Workflow step 10 in CLAUDE.md / AGENTS.md and `SESSION_RESUME_PROMPT.md` now point at `TECHNICAL_OVERVIEW.md`
- [x] Isolation rule (Q53) in CLAUDE.md / AGENTS.md: domain and value types never live in default-MainActor packages; cross-module types state their isolation
- [x] `TECHNICAL_OVERVIEW.md` truth pass: shared 0.30.0, 16 packages, new package graph, package table (sizes and real dependencies from the manifests), sampling (decimator), theme, test counts (237 here / 275 shared), no feature edge
- [x] Builds with zero errors; Recordings tests pass

**Prompt Used:**
"Mini player dead code, ProjectArchitecture.md"

**Notes:**
- Kept by user choice (T4): `StatisticsErrorView`, `RecordingsErrorView` (unused).
- Left as historical: `docs/KICKOFF_PROMPT.md` and the `CLAUDE_TEMPLATE.md` mention of ProjectArchitecture.md (templates for new projects); the `.gitignore` entry for it.

---

### F27-T17 — Close out

| Field | Value |
|-------|-------|
| Status | Done |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] Feature doc `docs/features/f27-architecture-interrogation-fixes.md` (changes by concern, files, tests, routes, state, edge cases, open items, UIKitWay follow-up list)
- [x] ADRs 0007–0009 written in their tasks; 0002 / 0005 updated
- [x] Tracker and FeatureTracker marked done

### F27-T18 — Shared HealthKit and raw-log behaviour (shared 0.32.0)

Asked by the owner: share behaviour with SleepGuardUIKitWay so one fix reaches both apps. Decided: share the behaviour (implementations over shared values), not the protocols (each app's DI, state and isolation stay its own).
- Shared 0.32.0 (written here, tagged by the owner): `SleepHealthKit` (`HealthKitSleep`) and `SleepFiles` (`RawLogFile`).
- `HealthKitSync` wraps `HealthKitSleep`; `SessionRawLogWriter` wraps `RawLogFile` (keeps its 200-sample buffer). `SessionRawLogWriting` methods are `async`.
- Bugs this removed: stages were read only when *writing* was allowed (HealthKit never reports read permission); save failures were silent; the snoring metadata now comes from the shared summary, as in UIKitWay.

### F27-T19 — Remove DesignSystem duplicates of the shared kit

`Theme.intensityColor` (= the kit's `palette.eventColor(.snoring, intensity:)`), `DurationFormatter` (= `DurationText.hoursAndMinutes`, identical text), and the unused `SessionRow` removed (deletion approved by the owner). `LowBatteryBannerView` stays: it is an adapter (decides from `SleepSession` when to show the shared banner), not a duplicate.

### F27-T20 — Rename `Env` to `Services`

Owner's choice of name. Folder, package, products (`Services`, `ServicesTestSupport`), test target, imports, Xcode project reference, `check-layering.py`, `check-imports.py`, current docs (CLAUDE/AGENTS, README, TECHNICAL_OVERVIEW); ADR 0008 has a note. Historical docs keep the old name. Committed with T18: the rename moved the files T18 edits.

### F27-T21 — Shared settings (shared 0.33.0)

The owner's follow-up: the apps aren't in production, so stored settings can move freely. Shared 0.33.0 (tagged by the owner): `SleepPreferences` (SleepCore), the 16 settings both apps have with their defaults, and `PreferencesDefaults` (new `SleepSettings` product), which stores them in UserDefaults (keys, defaults, validity). `UserPreferences` keeps its observable properties; those 16 read and write through `PreferencesDefaults`. SleepGuard-only settings (appearance, clip length, soft ask, …) stay in the app. The interrupter's keys are renamed for the feature. `UserPreferences(suiteName:)` replaces `init(defaults:)`.

### F27-T22 — Uniform the apps, release A (shared 0.34.0)

The owner's request: everything not unique to an app moves to SleepGuardShared (plan approved 2026-11-26: releases A small pieces, B audio, C one SwiftData schema; one file layout; nothing is in production).
- Logging: the `Logging` package removed; `Log` is SleepGuardShared's `SleepLogging` (re-exported by Models), signposter included.
- Classification: `SnoreDetector` / `SpeechDetector` removed; the tracker holds SleepCore's `LiveSampleClassifier` (the same as SleepGuardUIKitWay's).
- Profile and survey: the `UserProfile` and `LifestyleLog` @Models removed (schema V1 is SleepSession and SnoreEvent); `ProfileStore` and `LifestyleLogStore` (Services, observable, behind protocols, fakes) over the shared `ProfileFile` / `LifestyleLogFile`. The editor, prompt card and briefing use them; all ten survey chips are kept (the model had six).
- Checkpoint: `SessionRecoverySnapshot` removed; the checkpoint is a `Night` in the shared file format (`NightCheckpoint.encode/decode`), written by SleepGuard's own writer and sequence gate; recovery uses `SleepSession.make(from:)`.
- Files: the shared layout (`SleepGuardStorage`, the app group): clips, raw recordings (`RawRecording` names), checkpoint, profile and survey files moved off Documents.
- Storage limits: `StorageLimitEnforcer` decides with SleepCore's `StorageSweep`, so it now also removes files no night refers to (as SleepGuardUIKitWay did); its tests run serialized.
- Sample data: `MockDataGenerator` saves the shared `SampleNights` (no clips until release B).
- Start notification: the shared `StartNotification` (the text was hardcoded English).
- Deletions approved by the owner. A crash-recovered night loses its events' spectral stats until release C.

### F27-T23 — Uniform the apps, release B: shared audio (shared 0.35.0)

SleepGuardShared's SleepAudioKit (from SleepGuardUIKitWay's adapters plus SleepGuard's extras) replaces SleepGuard's audio code; the protocols stay.
- `AudioRecorder` wraps `CaptureEngine` (session, tap, clips `<id>.caf`, raw night, interruptions, route changes); it publishes the levels and the classifier's confidences, so `SoundAnalysisDetecting` is removed. `AudioRecorder.shared` is built in Services with the clips folder.
- Fixes the four audio bugs: a melody stop without a pause no longer starts a second engine; a clip closed for the melody is kept for the event's save (tracker `closedClipURL`); an interruption removes the tap; the frame position resets on every engine start.
- Compression and per-clip spectral stats: `ClipCompressor`, `ClipSpectrum`. Extraction from the raw night: `ClipExtractor` (legacy player, share, waveform fallback). `WaveformGenerator` is a thin layer over `ClipWaveform` / `ClipSpectrum`.
- `ClipPlaybackController` plays through `ClipPlayerEngine` (421 → 263 lines).
- Melodies: `SnoreInterrupterPlayer` over `MelodyPlayback` (stays in the recording's `.playAndRecord` session), `CustomMelodyStorage` over `MelodyFiles` (Melodies folder, `melodies.json`; was UserDefaults), `CustomMelodyRecorder` over `MelodyRecording`, `MelodyPreviewPlayer` over `MelodyPlayback`.
- Deleted (approved): TapProcessor, FFTAnalyzer, SoundAnalysisDetector(+ing), EventClipCompressor, AudioClipExtractor, ClipSource and their tests (now the kit's).
- No longer resumes capture on app activation (the kit resumes on interruption end, route, config and media-reset events, as SleepGuardUIKitWay).
- Not yet verified: a night on the simulator or a device; bug 2 has no regression test (the fake recorder returns no clip).
- Follow-up (owner's call): `TestAudio.swift` deleted and AudioEngine's empty test target removed (its tests are the kit's now); `WaveformGenerator` removed, `WaveformLoader` calls the kit's `ClipWaveform` directly (same 300 points and duration limit; `spectrumSamples` had no callers).

### F27-T24 — Uniform the apps, release C: one SwiftData schema (shared 0.36.0)

SleepGuardShared's SleepStore (records in SleepGuardUIKitWay's shape) replaces SleepGuard's models and schema; SleepGuard keeps `@Query` on the main context.
- `SleepSession` / `SnoreEvent` → `NightRecord` / `NightEventRecord` (66 files; Models re-exports SleepStore). SleepGuard-only reads (durations, percentages, episodes, save rules, raw-file lookup) are in `NightRecord+SleepGuard.swift`.
- The cached score fields → the stored summary (`score`, `snoringDuration`, `eventCount`, `loudestIntensity`, `scoreVersion`), written only by the shared `refreshSummary(using:)`: when a night stops, when it is recovered, at the commit, and by `refreshStaleSummaries` at launch.
- Optional end, events, gaps, stages and bursts became non-optional; the end reason is typed (`endReason`, was the `"low_battery"` string). Raw audio and log names are no longer stored: found by the night's id (`RawRecording`).
- The store is `Nights.store` in the shared layout, opened by `SleepStore.open` (backup per version, never deleted; the Debug-only reset is gone). `SleepGuardSchema`, `SleepGuardStore` and their tests removed (approved; the shared repo tests the schema and opening).
- A night without sleep stages asks Health each time its detail opens (`nil` "never fetched" no longer exists).
- CLAUDE.md / AGENTS.md schema and stored-summary rules rewritten for the shared schema.
- Verified: package lanes, app build and checks on 0.36.0; Debug sample data lands in the new store (14 nights, 106 events, summaries stamped) and the briefing reads it. Screens beyond the briefing weren't driven (simulator taps unavailable).

### F27-T25 — Uniform the apps, close-out

- ADR 0010 (everything that isn't SleepGuard's own lives in SleepGuardShared: the three releases, one layout, behaviour changes, limits).
- CLAUDE.md / AGENTS.md: classifier, logging, night rules, layering exception and the shared-behaviour rule updated (kept in sync).
- TECHNICAL_OVERVIEW: shared products, packages, the night end to end, detection, score storage, concurrency escape hatch, logging, tests (180 here, 335 shared).
- README: pin, event record, Models and AudioEngine rows (the rest of its table was already behind and is untouched).
- Owed: a recording night on a device (and a simulator night) to exercise the shared audio and store end to end.

### F27-T26 — Explicit imports: no `@_exported`

The owner's call as principal engineer: re-exports hide dependencies.
- Removed the five re-exports (Models: `SleepStore`, `SleepLogging`; DesignSystem: `SleepStrings`, `SleepGuardDesignKit`, `SleepGuardContentKit`; their three export-only files deleted, approved). Every file now imports what it uses (`public import` where a public API exposes the type), and every target declares it: manifests list their real dependencies (Settings now declares SleepGuardShared; it had none).
- `check-imports.py` now knows every shared product (it didn't check `SleepStore`, `SleepLogging`, `SleepAudioKit`, `SleepFiles`, `SleepNotifications`, `SleepSettings`, `SleepHealthKit`); `check-layering.py` rule 7 rejects `@_exported import` in packages, the app and the widgets (probed with a planted one).
- CLAUDE.md / AGENTS.md (strings example, design kit, logging, schema, package rule) and TECHNICAL_OVERVIEW updated.
- Still re-exported inside SleepGuardShared: `SleepGuardContentKit` → `SleepGuardDesignKit` → `SleepStrings`. Step 2 (a shared release, both apps) removes those.

### F27-T27 — No re-exports in the shared repo (shared 0.37.0)

Step 2 of the owner's request: SleepGuardShared's kits no longer re-export (`SleepGuardContentKit` → `SleepGuardDesignKit` → `SleepStrings`); its test script and CI fail on `@_exported`. SleepGuard already imported and declared each kit explicitly (T26), so this is the pin. Verified on 0.37.0: package lanes, app build, checks.

### F27-T28 — App folders; unused sounds; the project declares SleepGuardShared

- `SleepGuard/` sorted by concern: `App/` (app, store-unavailable screen), `Tabs/` (tab view, tab bar, one file per tab), `Navigation/` (route registry, deep links), `NightFlow/` (`SessionFlowHost`, processing overlay), `Widgets/` (snapshot writer); `RemoteConfig/` and `PushNotifications/` as before. Info.plist, entitlements and `Configuration/` stay put (build settings name them). A synchronized group: moving the files is enough.
- `sounds/` deleted (approved) with its project folder reference: two MP3s no melody uses, copied into the bundle (~205 KB). The melodies are SleepGuardShared's `SleepMelodies`.
- The project now declares SleepGuardShared (exact 0.37.0, so it shows under Package Dependencies) and links what its targets import: the app SleepCore, SleepFiles, SleepGuardDesignKit, SleepLogging, SleepStore, SleepStrings; the widget SleepGuardDesignKit, SleepStrings. Before, they came only through the packages' manifests. The workspace still overrides it with `../SleepGuardShared`.
- `bump-shared.sh` moves the project's pin too (dry-run tested); `check-imports.py` checks the app and widget targets against the products they link (probed).
- Noticed, not changed: the project has two leftover remote references to local package folders by `file://` URL (`Recordings`, `DesignSystem`) and some products linked two or three times in the app's Frameworks phase.

### F27-T29 — Local packages as a `Packages` folder in the project

The owner's call: SleepGuardShared belongs under Package Dependencies, the local packages in a `Packages` folder at the root of the project.
- The 15 local packages are folder references in a `Packages` group (Xcode's local-package form); their products are linked without a package reference. Package references are now only SleepGuardShared and Firebase.
- Cleaned while rewriting those entries: two `file://` remote references to `Packages/Recordings` and `Packages/DesignSystem`, product dependencies on references that no longer existed, and duplicate links (DesignSystem, Recordings, AudioEngine, SleepSession were linked two or three times). 67 objects removed; no dangling IDs; the app links 25 products once each (15 local, 6 shared, 4 Firebase), the widget Models, DesignSystem and its 2 shared ones.
- Verified: project and workspace builds, package resolution, import and layering checks; the per-package schemes are still generated (run-tests.sh unchanged).
- Untracked leftover noticed: `Packages/Logging/.swiftpm` (empty Xcode metadata from the deleted package), not added to the group.

### F27-T30 — The workspace builds the pinned release

The owner's call: SleepGuardShared listed under Package Dependencies in the workspace too, so the workspace no longer adds `../SleepGuardShared` (a local package overrides the pin and Xcode then shows it at the root instead).
- `SleepGuard.xcworkspace` holds only the project. To try unreleased shared code: add `../SleepGuardShared` to the workspace in Xcode for the time being (never committed), or build a throwaway workspace outside the repo that lists both (recipe in CLAUDE.md, tested: it resolves the local checkout and leaves the repo untouched).
- SleepGuardShared's CI built SleepGuard through this workspace to test candidate commits; its job now writes such a workspace itself (shared branch `ci-local-workspace`, no release needed).
- CLAUDE/AGENTS, README and TECHNICAL_OVERVIEW updated.
- The workspace lockfile gains the SleepGuardShared pin once Xcode reopens the workspace (an open Xcode rewrites it from the old override).

### F27-T31 — Features as one package, a target per feature

The owner's call (2026-11-28): organize the features like SleepGuardUIKitWay, in one `Features` package, each still a module imported by name.
- `Packages/Features` holds Learn, Onboarding, Personalization, Recordings, Settings, SleepSession and Statistics as targets (`Sources/<Feature>`, `Tests/RecordingsTests`, `Tests/StatisticsTests`). Every target keeps its previous dependency list. Module names are unchanged, so the app target and the project's product dependencies didn't change. The project's `Packages` group has one `Features` reference instead of seven. The tracked `Statistics.xcscheme` was removed; Xcode generates `Features-Package`.
- `check-imports.py`: a sibling target counts only when declared, and a feature target that declares another feature fails. Both cases were probed (undeclared `import Settings` in Learn; `"Settings"` in Learn's dependencies). `check-view-size.py` also scans `Packages/Features/Sources/*/Views|Components` (still 61 view files). `run-tests.sh` prints every test run of a package (Features has two bundles).
- ADR 0011; CLAUDE/AGENTS, README and TECHNICAL_OVERVIEW updated.
- Honest limit: the compiler alone may no longer reject a feature-to-feature import (same package); `check-imports.py` in CI is the guard.
- Verified: app build (zero errors), import/layering/view-size/strings checks, package tests (Features 23: RecordingsTests 12, StatisticsTests 11; 180 in total), app launch.
- Noticed, not changed: TECHNICAL_OVERVIEW says 237 tests in 8 packages; the runner reports 180 in 6. `Packages/Logging/.swiftpm` is still an untracked leftover.
