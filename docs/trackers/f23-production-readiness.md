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

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F23-T1 | One owner for committing a night (`SessionCommitter`) + low-battery clip-loss fix | Bug / Refactor | Done | — | Env / SleepSession / App | 2026-11-11 | 2026-11-11 |
| F23-T2 | App privacy manifest (`PrivacyInfo.xcprivacy`) | Compliance | Done | — | App / Widgets | 2026-11-11 | 2026-11-11 |
| F23-T3 | CI: build the app target (app + widgets) | Infra | Done | — | .github | 2026-11-11 | 2026-11-11 |
| F23-T4 | `os.Logger` instead of `print` (+ signposts for session and event) | Infra | Done | — | all | 2026-11-11 | 2026-11-11 |
| F23-T5 | Audit `try?` on data paths | Quality | Backlog | F23-T4 | Env / AudioEngine / Recordings / App | — | — |
| F23-T6 | Detection accuracy evaluation on labelled real nights | Tooling | Backlog | User: real nights with raw logs | scripts / AudioEngine | — | — |

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

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)
