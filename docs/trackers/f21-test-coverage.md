# F21 — Test Coverage

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Version** | V5 |
| **Blocked By** | — |
| **Started** | 2026-11-09 |
| **Completed** | — |
| **Feature Doc** | — |
| **Branch** | `feature/f21-test-coverage` (each task merges here; merges to `main` after T18) |

## Summary

Unit tests across the logic layer of every package: sleep scoring, snore detection, the live-session pipeline, storage cleanup, and the feature helpers. One script runs every package's tests on the simulator, and CI runs it too. Views stay untested on purpose (thin, "the view is the view model"); UI smoke tests are optional.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F21-T1 | Test runner script + fix Personalization tests | Infra | Done | — | scripts / Personalization | 2026-11-09 | 2026-11-09 |
| F21-T2 | Test targets for AudioEngine, Env, Recordings, Statistics, DesignSystem | Infra | Done | F21-T1 | Packages | 2026-11-09 | 2026-11-09 |
| F21-T3 | CI `tests` job | Infra | Backlog | F21-T1 | .github | — | — |
| F21-T4 | Shared fixtures (in-memory SwiftData, session/event builders) | Infra | Backlog | F21-T2 | Packages | — | — |
| F21-T5 | Sleep score tests | Test | Backlog | F21-T4 | Models | — | — |
| F21-T6 | Session + episode calculation tests | Test | Backlog | F21-T4 | Models | — | — |
| F21-T7 | Recovery snapshot, deep link, formatters, URL resolver tests | Test | Backlog | F21-T4 | Models | — | — |
| F21-T8 | `SnoreDetector` classification tests | Test | Backlog | F21-T2 | AudioEngine | — | — |
| F21-T9 | FFT + RMS/peak level tests (synthetic buffers) | Test | Backlog | F21-T2 | AudioEngine | — | — |
| F21-T10 | Clip extractor + compressor tests | Test | Backlog | F21-T2 | AudioEngine | — | — |
| F21-T11 | `RealtimeDetectionTracker` tests | Test | Backlog | F21-T4 | Env | — | — |
| F21-T12 | `StorageLimitEnforcer` tests | Test | Backlog | F21-T4 | Env | — | — |
| F21-T13 | Checkpoint store + recording delay tests | Test | Backlog | F21-T2 | Env | — | — |
| F21-T14 | Recordings helpers tests | Test | Backlog | F21-T4 | Recordings | — | — |
| F21-T15 | Week-over-week trend tests | Test | Backlog | F21-T4 | Statistics | — | — |
| F21-T16 | `DurationFormatter` + strings-key tests | Test | Backlog | F21-T2 | DesignSystem | — | — |
| F21-T17 | UI smoke tests (optional) | Test | Backlog | F21-T1 | App | — | — |
| F21-T18 | Verification, docs, merge to main | Docs | Backlog | F21-T1…T17 | — | — | — |

## Task Details

### F21-T1 — Test runner script + fix Personalization tests

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/modules.md` |
| Status | Done |
| Started | 2026-11-09 |
| Completed | 2026-11-09 |

**Acceptance Criteria:**
- [x] `sh scripts/run-tests.sh` runs every package that has a `testTarget`, on the pinned simulator, and exits non-zero if any fail
- [x] Existing Models tests (10) and Personalization tests (30) pass
- [x] Builds with zero errors

**Prompt Used:**
"ok first create as usual the main feature branch, then for each task create it based on this feature branch. … Lets start"

**Notes:**
- The plan was a shared test plan on the `SleepGuard` scheme. It can't work: the packages are linked as `XCLocalSwiftPackageReference` only (no folder references), so Xcode doesn't expose their test targets. A test plan and classic scheme testables both fail with "There are no test bundles available to test". The user chose a per-package script over a workspace or hand-editing `project.pbxproj`.
- Consequence: XcodeBuildMCP `test_sim` on the app scheme still runs nothing. Use the script.
- `BriefingEngineTests` didn't compile on `main` (`ScoreTrend` not `Equatable`, noted in F20-T9). Fixed by adding `Equatable` to `ScoreTrend`; no behavior change.
- Once compiling, 4 of 30 failed. The tests had never run, so they had drifted from the engine:
  - `greetingNight`: the night greeting is "Still up?" since F15-T5 localization; the test looked for "night". Test updated.
  - Survey gate: `30778b0` loosened it from "≥2 sessions + ≥15-point swing" to "≥1 session, any swing". With one session the average is 0, so the first night always showed "Nice jump tonight". **Bug fix (user approved):** the gate is back to ≥2 sessions; the any-swing rule stays. `noSurvey_whenScoreSwingIsSmall` → `survey_whenScoreSwingIsSmall` (expects a positive survey).

---

### F21-T2 — Test targets for AudioEngine, Env, Recordings, Statistics, DesignSystem

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/modules.md` |
| Status | Done |
| Started | 2026-11-09 |
| Completed | 2026-11-09 |

**Acceptance Criteria:**
- [x] Each of the 5 packages has a `<Pkg>Tests` target (`path: "Tests"`, Swift 6, same default isolation as the library)
- [x] One seed test per target compiles and passes; `run-tests.sh` picks all 7 packages up automatically
- [x] SwiftFormat lint clean; builds with zero errors

**Prompt Used:**
"i commited and merged, you continue with next one"

**Notes:**
- Seed tests are edge cases that the later tasks would cover anyway: `SnoreDetector` no-signal → `.none` (T8), `SessionCheckpointStore` clear → nil (T13), `SessionGrouper` empty (T14), `WeekOverWeekTrendCalculator` empty → nil (T15), `DurationFormatter` under an hour (T16).
- Learn, Onboarding, Settings and SleepSession get no test target: they're almost all views, and their two helpers (`MelodyPreviewPlayer`, `CustomMelodyRecorder`) are audio I/O wrappers.
- Found while reading: `WeekOverWeekTrendCalculator` builds its label from a hardcoded `"vs prev wk"` (not localized). Not changed here; flag for T15.

