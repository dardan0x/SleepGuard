# F27 — Architecture Interrogation Fixes

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P0 (T1) / P1 |
| **Version** | V5 |
| **Blocked By** | — |
| **Started** | 2026-11-25 |
| **Completed** | — |
| **Feature Doc** | — |
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
| F27-T11 | Split Env by reason to change (Q31) | Refactor | Backlog | T10 | Env → Config / Health / Platform | — | — |
| F27-T12 | Access-level imports (Q30) | Refactor | Backlog | T11 | all | — | — |
| F27-T13 | One theme system (Q21) | Refactor | Backlog | T12 | DesignSystem / views | — | — |
| F27-T14 | Two dependency-resolution styles (Q23) | Refactor | Backlog | T11 | Env / Recordings | — | — |
| F27-T15 | Contract tests for stateful fakes (Q24/Q59) | Tests | Backlog | T11 | Env | — | — |
| F27-T16 | Dead code and docs (Q67, Q53) | Cleanup | Backlog | — | Recordings / docs | — | — |
| F27-T17 | Close out: feature doc, ADRs, UIKitWay follow-up list | Docs | Backlog | all | docs | — | — |

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
