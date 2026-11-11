# F23 — Production Readiness

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Version** | V5 |
| **Blocked By** | — |
| **Started** | 2026-11-11 |
| **Completed** | — |
| **Feature Doc** | — |
| **Branch** | `feature/f23-production-readiness` (from `feature/f22-architecture-hardening`, which isn't in `main` yet; one sub-branch per task, `feature/f23/t#-slug`) |

## Summary

The "Do" list from the principal architecture review (`docs/ARCHITECTURE_REVIEW.md`, 2026-11-11). F22 made the structure solid; F23 makes the app safer to ship: one owner for saving a night (it fixes a likely clip-loss bug), the App Store privacy manifest, real logging, an audit of silent `try?`s, an app-target build in CI, and a way to measure detection accuracy. The "Consider" items wait for a measurement; the "Don't" list stays undone.

### Decisions (user, 2026-11-11)
- "ok lets go with your suggestions": follow the review's suggested order.
- Follow-up choices: commit `Package.resolved`; do accessibility, the start-failure alert, Debug-only mock data and raw-log streaming. Not chosen: deleting the stray nested xcodeproj, keeping the `.caf` when compression fails, iPhone-only.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F23-T1 | One owner for committing a night (`SessionCommitter`) + low-battery clip-loss fix | Bug / Refactor | Done | — | Env / SleepSession / App | 2026-11-11 | 2026-11-11 |
| F23-T2 | App privacy manifest (`PrivacyInfo.xcprivacy`) | Compliance | Done | — | App / Widgets | 2026-11-11 | 2026-11-11 |
| F23-T3 | CI: build the app target (app + widgets) | Infra | Done | — | .github | 2026-11-11 | 2026-11-11 |
| F23-T4 | `os.Logger` instead of `print` (+ signposts for session and event) | Infra | Done | — | all | 2026-11-11 | 2026-11-11 |
| F23-T5 | Audit `try?` on data paths | Quality | Done | F23-T4 | Env / AudioEngine / SleepSession / App | 2026-11-11 | 2026-11-11 |
| F23-T6 | Detection accuracy evaluation on labelled real nights | Tooling | Backlog | User: real nights with raw logs | scripts / AudioEngine | — | — |
| F23-T7 | Commit the app's `Package.resolved`; CI builds from it | Infra | Done | — | repo / .github | 2026-11-11 | 2026-11-11 |
| F23-T8 | `MockDataGenerator` Debug-only | Cleanup | Done | — | Env | 2026-11-11 | 2026-11-11 |
| F23-T9 | Stream the raw log to disk while recording | Perf | Done | — | Env / AudioEngine / scripts | 2026-11-11 | 2026-11-11 |
| F23-T10 | Alert when a recording fails to start | UI | Done | — | SleepSession / DesignSystem | 2026-11-11 | 2026-11-11 |
| F23-T11 | Accessibility pass (VoiceOver, Dynamic Type) | UI | Backlog | — | DesignSystem / features | — | — |
| F23-T12 | Fix the Release build cycle (Crashlytics phase last) | Build | Done | — | App / .github | 2026-11-11 | 2026-11-11 |

## Task Details

### F23-T1 — One owner for committing a night

| Field | Value |
|-------|-------|
| Arch Ref | ADR 0002; `docs/ARCHITECTURE_REVIEW.md` Do #1 |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] `SessionCommitting` protocol + `SessionCommitter` (Env): insert events + session, cache the score, save, then clear pending + checkpoint, then follow-ups (storage limits, HealthKit when enabled)
- [x] `SessionSummaryView` and `StatisticsTab`'s force-save both commit through it; the duplicated code is gone
- [x] Regression test: a `low_battery` session clears the pending record and the checkpoint (mutation-checked)
- [x] Fake + container registration + layering rule, per ADR 0002
- [x] Builds with zero errors; tests pass

**Prompt Used:**
"ok lets go with your suggestions"

**Notes:**
- **The bug (from code reading):** the force-save path saved the night but never cleared `PendingSessionStore` or the checkpoint. The pending record lists every event clip. At the next launch, the app either offered to "recover" an already-saved night (and discarding it deleted the clips), or ran `cleanupIfNeeded()` and deleted the clips straight away. Otherwise the next recording's `setPending` did the deletion. A recovered snapshot also keeps `terminationReason`, so a stale checkpoint could even be auto-saved again.
- `commit` is synchronous and throws. Nothing is cleaned up when the save fails, so the night stays protected. It returns the follow-up `Task` (storage limits, HealthKit), which callers ignore and tests await.
- Behavior change on the force-save path, on purpose: it now also enforces storage limits, as the normal save always did.
- Views lost 6 injections (`SessionSummaryView`) and the `healthKitSync` reference (`StatisticsTab`).
- Not tested: the save-failure path. An in-memory SwiftData store can't be made to fail its save, so `FakeSessionCommitter.error` covers the caller side instead.
- Simulator: recorded 2 min 24 s, stopped, Save Session → the dashboard shows the new night (Nov 11 20:07–20:10, cached score), and `session_recovery.json` is gone from the app container. The low-battery path can't be triggered on the simulator (battery level is -1); the unit test covers it.
- Tests: `SessionCommitterTests` (3 tests, 5 cases), plus a `ServiceOverrideTests` case and the default-resolution check. Mutation: removing the two clears fails the regression test for both `nil` and `low_battery`.

---

### F23-T2 — App privacy manifest

| Field | Value |
|-------|-------|
| Arch Ref | `docs/ARCHITECTURE_REVIEW.md` Do #2 |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] `SleepGuard/PrivacyInfo.xcprivacy` declares every required-reason API the app's own code uses
- [x] The widget extension has its own manifest
- [x] Both are bundled (checked in the built `.app` / `.appex`)

**Prompt Used:**
"ok lets go with your suggestions"

**Notes:**
- Found by grepping all first-party targets:
  - **UserDefaults → CA92.1:** the app's own settings stores, plus `UpdateGateView`.
  - **File timestamp → C617.1:** `attributesOfItem` in `StorageLimitEnforcer` and `SessionShareCoordinator`; only `.size` is read, but Apple lists the API.
  - **System boot time → 35F9.1:** `systemUptime` in `ClipPlaybackController`, for elapsed playback time.
  - No disk-space or keyboard APIs are used.
- Widget: UserDefaults only (linked `DesignSystem` code).
- `NSPrivacyTracking` false; no collected data types declared by the app itself. Firebase (Crashlytics, Messaging, Remote Config, Installations) and Factory ship their own manifests, which Xcode merges into the privacy report.
- The Watch sources aren't a target in this project, so there's no manifest for them.
- **Still for the user:** generate the privacy report from an Xcode archive (Organizer → Generate Privacy Report) before submission, and keep the App Store Connect privacy label in line with it (Crashlytics crash and diagnostic data).
- Both targets use synchronized folders, so the files are picked up with no `project.pbxproj` change.

---

### F23-T3 — CI builds the app target

| Field | Value |
|-------|-------|
| Arch Ref | `docs/ARCHITECTURE_REVIEW.md` Do #5 |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] A CI job builds the `SleepGuard` scheme (app + widget extension) on PRs
- [x] The same command passes locally from a cold derived-data folder

**Prompt Used:**
"ok lets go with your suggestions"

**Notes:**
- New `app` job in `tests.yml`, in parallel with `packages`: `xcodebuild build -scheme SleepGuard -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`. It fails unless `** BUILD SUCCEEDED **` appears, and uploads the log on failure.
- Local cold run: BUILD SUCCEEDED. Not run on GitHub yet: it runs on the next PR or a manual dispatch.
- The Watch sources aren't an Xcode target, so there's nothing to build for them.
- **Found:** the generic destination shows 3 asset warnings that the single-simulator build hides: no `AccentColor` asset, and missing iPad icons (76@2x, 83.5@2x). The target builds for iPad (`TARGETED_DEVICE_FAMILY`). They predate F23; fix them, or drop iPad if it isn't intended (user decision).
- **Open:** `Package.resolved` is gitignored, so CI resolves the newest Firebase/Factory within the declared ranges, which can differ from local. Committing it is standard for apps (user decision).

---

### F23-T4 — `os.Logger` instead of `print`

| Field | Value |
|-------|-------|
| Arch Ref | `docs/ARCHITECTURE_REVIEW.md` Do #3 |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] No `print(` left in package sources or the app target (76 converted)
- [x] Categories and levels chosen per call; private by default, `privacy: .public` only for errors, numbers and enum cases
- [x] Signpost intervals for each session and each snore event
- [x] A check keeps `print` out; rule in AGENTS/CLAUDE
- [x] Builds with zero errors; tests pass; logs verified on the simulator

**Prompt Used:**
"ok lets go with your suggestions"

**Notes:**
- `Log` (in `Models/Sources/Helpers/Log.swift`, since every target imports Models): 7 categories under subsystem `com.dardan.SleepGuard`, plus `Log.signposter`.
- Levels: 38 `.debug` (traces, mostly the interrupter and per-sample detection), 31 `.error`, 11 `.info`, 4 `.notice`, 1 `.fault` (the SwiftData container failing and the store being deleted).
- Errors are logged `privacy: .public` so sysdiagnose shows them. The FCM push token, file names, paths and melody names stay private by default.
- `SoundAnalysisDetector` built a top-3 string for every result (about 2 Hz all night) in Release too. It is now built only in Debug.
- Signposts: a "Session" interval (`SessionRecordingController`, ended as "stopped" or "discarded") and a "Snore event" interval per event (`RealtimeDetectionTracker`, ended as "saved" or "discarded"), visible in Instruments' Points of Interest. Plus `.info` "Session started / stopped / discarded".
- **Two Swift gotchas, handled:** (1) Logger interpolations are autoclosures, so instance properties need `self.`; SwiftFormat's `--self remove` stripped them, so `.swiftformat` now has `--selfrequired debug,info,notice,error,fault,log`. (2) The app target has member-import visibility, so app files that log `import os` themselves.
- `check-layering.py` rule 5 fails on `print(` outside comments in package Sources and the app target (probed).
- Simulator: a log stream during start → discard showed `audio`, `detection`, `interrupter`, `session` and `storage` lines, including "Session started" and "Session discarded".

---

### F23-T5 — Audit `try?` on data paths

| Field | Value |
|-------|-------|
| Arch Ref | `docs/ARCHITECTURE_REVIEW.md` Do #4 |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] Every `try?` reviewed (95); the ones that can silently lose a night, a clip or user data now log (or change behavior where silence did damage)
- [x] Harmless ones left alone, with the reasoning recorded
- [x] Builds with zero errors; tests pass

**Prompt Used:**
"ok lets go with your suggestions"

**Notes:**
- **Changed (9 places):**
  - **Delayed start, from the countdown and from the notification tap** (`RecordingCountdownView`, `AppDelegate`): `try? startSession()` became do/catch + `.error`. Before, a mic or audio-session failure at the end of the delay recorded nothing and logged nothing.
  - **Checkpoint write and read** (`SessionCheckpointStore`): a failed write, or a file that exists but can't be decoded, now logs. Either one means the night can't be recovered after a crash. Behavior unchanged otherwise (still returns nil).
  - **Pending record decode** (`PendingSessionStore`): logs, because an unreadable record means its files are never cleaned up.
  - **Storage-limit fetches** (`StorageLimitEnforcer`, 2 places): log when cleanup is skipped.
  - **Clip compression** (`EventClipCompressor` + the tracker): logs which step failed and that the event was saved without a clip.
  - **Profile fetch** (`StatisticsTab`, `SettingsTab`): **behavior change.** A fetch error used to fall through and insert a second `UserProfile`; now it logs and returns nil (no sheet) instead of duplicating.
- **Left alone, on purpose:**
  - `Task.sleep` (only throws on cancellation).
  - `removeItem` on files that may already be gone.
  - Encoding simple `Codable` configs (can't realistically fail).
  - Decoding legacy or remote data with a deliberate fallback (`RawLog` format 1, `RecordingGap.snoringResumed`, remote config).
  - Deactivating the audio session.
  - UI-only fetches (briefing, deep link, waveform).
  - The DEBUG-only dummy-audio tool.
- **Found, not fixed (needs decisions):**
  - **No user-facing alert when a session fails to start, on any path** (normal, delayed, notification). Only a log now. Needs strings and a design.
  - **A failed compression leaves the `.caf` on disk** and the event without a clip. Keeping the `.caf` as the clip would be a behavior change.
- Tests: the logging isn't unit-tested (behavior is unchanged except for the profile path, which runs in the app target). All suites still pass.

---

### F23-T7 — Commit the app's `Package.resolved`

| Field | Value |
|-------|-------|
| Arch Ref | — |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] The app's `Package.resolved` is tracked
- [x] The CI app build uses exactly those versions

**Prompt Used:**
User choice "Commit Package.resolved".

**Notes:**
- Pinned: Firebase 12.14.0, Factory 3.5.2, and their transitive dependencies (14 pins).
- Force-added, because its parent folders are ignored (`*.xcworkspace`, `…/swiftpm/`). A tracked file is unaffected by ignore rules, so later updates show up normally. `.gitignore` explains this. Library packages still don't commit lockfiles.
- The CI `app` job passes `-disableAutomaticPackageResolution`, so a stale lockfile fails the build instead of resolving silently. Verified locally: BUILD SUCCEEDED.
- The package test job (`run-tests.sh`) resolves per package as before; those packages only declare Factory `from: 3.5.2`.

---

### F23-T8 — `MockDataGenerator` Debug-only

| Field | Value |
|-------|-------|
| Arch Ref | `docs/ARCHITECTURE_REVIEW.md` Consider |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] `MockDataGenerator` (498 lines) compiles only in Debug
- [x] Release builds of the packages that reference it succeed

**Prompt Used:**
User choice "MockDataGenerator Debug-only".

**Notes:**
- Whole file wrapped in `#if DEBUG`. All three callers (`SleepGuardApp` launch argument, `SettingsDataSection`, `SettingsStorageSection` test cleanup) were already `#if DEBUG`.
- Verified: Env and Settings build in Release; the app builds in Debug with 0 warnings.
- **Found:** the app target's Release build fails with a dependency cycle (Crashlytics script phase before "Embed Foundation Extensions"). It predates F23; fixed in T12.

---

### F23-T12 — Fix the Release build cycle

| Field | Value |
|-------|-------|
| Arch Ref | — |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] The app builds in Release (what Archive uses)
- [x] CI builds Release, so this can't come back unnoticed

**Prompt Used:**
Found while verifying T8 ("other points from review").

**Notes:**
- **The error:** "Cycle inside SleepGuard". The "Firebase Crashlytics" run-script phase sat before "Embed Foundation Extensions". In Release it depends on the dSYM, which depends on the embedded widget `.appex`, which waited for the script. Debug builds never produce a dSYM, which is why it went unnoticed. **It would also fail Archive.**
- **Fix:** move the Crashlytics phase to the end of the app target's build phases, as Firebase's setup guide requires. One line of `project.pbxproj`.
- Verified: a Release build succeeds, the widget is embedded and the dSYM is produced; Debug builds with 0 warnings.
- The CI `app` job now builds `-configuration Release`.
- Not changed: the script's second input path is `$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)`, which points nowhere (Firebase documents `$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)`). It only affects dependency tracking, and the phase is `alwaysOutOfDate`.

---

### F23-T9 — Stream the raw log to disk while recording

| Field | Value |
|-------|-------|
| Arch Ref | `docs/ARCHITECTURE_REVIEW.md` Consider |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] Memory stays flat during the night (no whole-night buffer)
- [x] A crash keeps the log up to the last flush
- [x] Old logs (formats 1 and 2) still decode; the fixture script reads the new format
- [x] Discarding a session deletes its log

**Prompt Used:**
User choice "Stream raw log to disk".

**Notes:**
- **Format 3 (`rawlog_<id>.jsonl`, JSON Lines):** line 1 is `RawLogMetadata`, then one `SnoreSample` per line. `RawLog.decode(from:)` tries format 2, then 1, then 3; it sorts samples, drops a partial last line (crash) and throws on a corrupt line in the middle.
- **Writer:** opens the file at `start` with the header, buffers 200 samples (~10 s), appends each chunk through a `FileHandle`, and closes at `stop`. A header-only file is deleted at `stop`. A failed create or write is logged (`Log.storage`) and new samples are dropped instead of piling up.
- **Crash cleanup:** the controller registers the log's name with the pending store at start (`SessionRawLogWriter.fileName(for:)`), since the file exists from then on. Stop no longer adds it.
- **Bug avoided:** `stopAndDiscardSession` never told the writer. Harmless while nothing reached disk before stop; now it calls `rawLogWriter.discard()` (closes and deletes).
- `make-replay-fixture.py` reads format 3, including a truncated file (probed with 1,300 lines plus a partial one).
- Tests (+5): format 3 round-trip sorted, a crash-truncated file keeps complete lines, a corrupt middle line throws (AudioEngine); samples reach disk during recording, discard deletes the file (Env). The existing format-2 test now pins `formatVersion: 2`.
- **Simulator, with the setting on:** the file had only its header at 2 s, 201 lines at 12 s and 401 at 24 s. "Stop Anyway" (discard) deleted it. The setting was switched back off afterwards.
- Size is about the same as format 2 (~65 MB a night, still Debug-setting-only).

---

### F23-T10 — Alert when a recording fails to start

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-11 |
| Completed | 2026-11-11 |

**Acceptance Criteria:**
- [x] Starting a recording that fails shows an alert instead of doing nothing: immediate start, "Start Anyway" from the charging alert, and the end of the delay countdown
- [x] Strings localized through the catalog; views stay under 200 lines
- [x] Seen on the simulator

**Prompt Used:**
User choice "Start-failure alert".

**Notes:**
- New keys: `session.startFailedAlert.title` ("Couldn't Start Recording") and `.message` ("The microphone isn't available right now. Close any app that's recording or on a call, then try again."). Added through `Strings.txt` → `generate-xcstrings.py`; English only, like the rest of the catalog.
- `RecordingPrestartView` (`PrestartPresentation.startFailed`) and `RecordingCountdownView` (`CountdownAlert.startFailed`, both the charging path and `.recordingDelayDidComplete`): an OK-only system alert in the same form as the existing microphone and charging alerts. The screen stays, so the user can retry.
- No `.pen` design: it's a system alert. The style follows the existing alerts.
- **Not covered:** starting from the notification tap (`AppDelegate`) still only logs. There's no view in that path; showing it would need app-level presentation state (a follow-up if wanted).
- Simulator: with a temporary `throw` in `startSession()` (reverted; the controller matches HEAD), tapping Start Recording showed the alert over the prestart screen.
- Sizes: prestart 183 lines, countdown 164.

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
