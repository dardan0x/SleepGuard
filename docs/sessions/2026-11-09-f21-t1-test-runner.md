
### Completed
- Planned F21 Test Coverage (18 tasks, `docs/trackers/f21-test-coverage.md`). Created `feature/f21-test-coverage` from `main` and the task branch `feature/f21/t1-test-plan`.
- F21-T1: `scripts/run-tests.sh` runs every package's tests on the pinned simulator. The existing 40 tests (Models 10, Personalization 30) all pass. Before this, the Personalization tests didn't compile and nothing ran from the command line in one step.

### Technical Details
- **Why not a test plan on the app scheme**: the packages are linked as `XCLocalSwiftPackageReference` only (no folder references in the project), so Xcode doesn't expose their test targets. A shared `.xctestplan` and classic scheme `Testables` both failed with "There are no test bundles available to test". Both attempts were reverted.
- **Script**: finds packages whose `Package.swift` has a `testTarget`. For each, it runs `xcodebuild test -scheme <Pkg>` from the package folder, sharing `-derivedDataPath .build/test-derived-data` (gitignored), with logs in `.build/test-derived-data/logs/<Pkg>.log`. It prints the Swift Testing summary line, or the errors and `✘` lines on failure, and exits 1 if any package fails. Overrides: `DESTINATION`, `DERIVED_DATA`, or package names as arguments.
- **Cold run**: the first Personalization run builds Env, AudioEngine, DesignSystem and Factory and took more than 10 minutes. Warm runs take seconds.
- **Compile fix**: `ScoreTrend` is now `Equatable`, which the tests' `==` needs.
- **4 stale failures** (the tests had never run):
  - `greetingNight`: the night copy is "Still up?" (since F15-T5). The assertion now looks for "Still up".
  - Survey gate: `30778b0` changed `sessions.count >= 2` + `abs(swing) >= 15` to `>= 1` with no swing gate. With one session, `avg = 0 / max(0,1) = 0`, so `latest >= avg` was always true. The first night always got "Nice jump tonight. What did you do differently?". **Fix (user approved)**: the gate is `>= 2` again; the any-swing rule stays. `noSurvey_whenScoreSwingIsSmall` is renamed `survey_whenScoreSwingIsSmall` and expects a positive survey.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `scripts/run-tests.sh` | +46 (new) | Per-package simulator test runner |
| `Packages/Personalization/Sources/Engine/Briefing.swift` | +1/−1 | `ScoreTrend: Equatable` |
| `Packages/Personalization/Sources/Engine/BriefingEngine.swift` | +3/−1 | Survey needs ≥2 sessions (first-night bug) |
| `Packages/Personalization/Tests/BriefingEngineTests.swift` | +3/−3 | Greeting assertion; swing test matches the current rule |
| `docs/trackers/f21-test-coverage.md` | new | F21 tracker, T1 Done |
| `docs/FeatureTracker.md` | — | F21 row, dashboard counts, activity log |
| `docs/sessions/2026-11-09-f21-t1-test-runner.md` | new | This fragment |

### Architecture Decisions
- **Per-package script over a workspace or pbxproj folder refs** (user's choice): no project-file surgery, and the way you open the project doesn't change. CI can call the same script. Cost: XcodeBuildMCP `test_sim` on the app scheme still runs nothing.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `sh scripts/run-tests.sh`: Models 10/10, Personalization 30/30. Layering check passed.

### Changes done
```
- Add scripts/run-tests.sh (xcodebuild test per package, shared derived data)
- Make ScoreTrend Equatable so BriefingEngineTests compile
- Fix first-night survey: require ≥2 sessions before comparing scores
- Update stale greeting and survey-swing tests
- Add F21 tracker, FeatureTracker row, session fragment
```

### Next Session
- F21-T2: add `testTarget`s to AudioEngine, Env, Recordings, Statistics and DesignSystem.
- F21-T3: CI tests job. It needs a decision on push vs. pull requests only.

### Open Questions
- CI trigger for the tests job (every push vs. pull requests only).
- May T8/T11 make small changes for testability (an internal initializer for `SnoreDetector`, an injected clock for `RealtimeDetectionTracker`)?
- Phase 5 UI smoke tests: in or out?
- `FeatureTracker.md` on `main` still lists F20 as In Progress (7/9) even though F20 is merged. Should I mark it Done?
