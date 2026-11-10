# F21 — Test Coverage

Unit tests across the logic layer of every package that has logic: 179 Swift Testing tests in 7 packages, up from 40 tests in 2 packages that no command could run in one go (and 30 of those didn't compile). One script runs them all on the simulator, and CI runs it on every pull request. Writing the tests found and fixed four production bugs.

## Running

```sh
sh scripts/run-tests.sh                 # all packages with a testTarget
sh scripts/run-tests.sh Models Env      # selected packages
DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' sh scripts/run-tests.sh
```

- Runs `xcodebuild test` per package (scheme `<Pkg>`, or `<Pkg>-Package` when a package has more than one library product), sharing `.build/test-derived-data`. Logs: `.build/test-derived-data/logs/<Pkg>.log`.
- Why not the app scheme: the packages are linked as `XCLocalSwiftPackageReference` only, so Xcode doesn't expose their test targets to `SleepGuard` (a test plan and scheme testables both report "no test bundles"). XcodeBuildMCP `test_sim` therefore runs nothing.
- `swift test` doesn't work either: it builds for macOS, where iOS-only APIs fail.
- The first run is a cold build (10+ min); warm runs take seconds.

## Coverage

| Package | Tests | Suites |
|---------|-------|--------|
| Models | 68 | `SleepScoreTests` (22), `SnoringEpisodeTests` (16), `SessionStatsTests` (9), `WidgetSnapshot*` (11), `SessionRecoverySnapshotTests` (5), `AudioFileURLResolverTests` (4), `TestStoreTests` (1) |
| AudioEngine | 34 | `SnoreDetectorTests` (8), `FFTAnalyzerTests` (9), `TapProcessorLevelsTests` (6), `AudioClipExtractorTests` (8), `EventClipCompressorTests` (3) |
| Personalization | 30 | `BriefingEngineTests` |
| Env | 20 | `StorageLimitEnforcerTests` (6), `DetectionSensitivityTests` (5), `SessionCheckpointStoreTests` (5), `RecordingDelayManagerTests` (4) |
| Recordings | 14 | `SessionDetailModelTests` (9), `SessionGrouperTests` (5) |
| Statistics | 8 | `WeekOverWeekTrendCalculatorTests` |
| DesignSystem | 5 | `LocalizableCatalogTests` (2), `DurationFormatterTests` (2), `TrendLabelFormatTests` (1) |

Counts are `@Test` functions; parameterized tests run more cases. Learn, Onboarding, Settings and SleepSession have no test target (views, plus audio I/O wrappers).

## Files

| File | Change | Purpose |
|------|--------|---------|
| `scripts/run-tests.sh` | New | Per-package simulator test runner |
| `.github/workflows/tests.yml` | New | CI: run-tests on PRs + manual dispatch (`macos-26`, newest Xcode 26) |
| `Packages/*/Package.swift` (7) | Modified | `testTarget`s; `ModelsTestSupport` product; test dependencies |
| `Packages/Models/TestSupport/` | New | `TestCalendar`, `TestStore` (in-memory SwiftData), session/event fixtures |
| `Packages/AudioEngine/Tests/TestAudio.swift` | New | Synthetic buffers, tone files, `TempFolder` |
| `Packages/*/Tests/*.swift` | New | Test suites (see Coverage) |
| `Packages/Personalization/Sources/Engine/Briefing.swift` | Modified | `ScoreTrend: Equatable` |
| `Packages/Personalization/Sources/Engine/BriefingEngine.swift` | Modified | Survey needs ≥ 2 sessions (bug fix) |
| `Packages/AudioEngine/Sources/Engine/FFTAnalyzer.swift` | Modified | DFT setup length, zero-padding, safe spectrum binning (bug fixes) |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | Modified | Internal `init` for isolated test instances |
| `Packages/Env/Sources/Services/Session/RealtimeDetectionTracker.swift` | Modified | Injectable detector, `apply(_:)`; spectral input to `classify` held at 0 |
| `Packages/Env/Sources/Services/StorageLimitEnforcer.swift` | Modified | Internal explicit-limits overload |
| `Packages/Recordings/Sources/Helpers/SessionDetailModel.swift` | Modified | Delete files before events (bug fix) |
| `Packages/Recordings/Sources/Views/RecordingsListView.swift` | Modified | Same delete fix |
| `Packages/Statistics/Sources/Views/WeekOverWeekTrendCalculator.swift` | Modified | `Trend.diff` instead of a hardcoded English label |
| `Packages/Statistics/Sources/Views/Last7NightsView.swift` | Modified | Formats `stats.last7Nights.trendVsPrevWeek` |
| `Packages/DesignSystem/Sources/Resources/{Strings.txt, Localizable.xcstrings}`, `Strings.swift` | Modified | New key `stats.last7Nights.trendVsPrevWeek` |
| `docs/ProjectArchitecture.md`, `docs/snore-detection-algorithm.md` | Modified | Tests section; FFT fallback status |

## Bugs Found and Fixed

| Bug | Since | Effect | Fix |
|-----|-------|--------|-----|
| `FFTAnalyzer` setup created with `log2n` instead of the length → `nil` | 2026-05-08 (`e4f7c56`) | Spectral fallback never ran; events stored 0 for frequency/centroid/low-band ratio; spectrum bars always flat | Pass the length; zero-pad short buffers |
| `spectrumBars` out-of-range range when bins < bars | Latent (masked by the bug above) | Would crash the Advanced player once the FFT worked | Spread bins proportionally |
| Session delete removed events before deleting files | — | Every deleted session left its event clips in Documents | Delete files first (detail + list) |
| Survey gate `≥ 1` session with average 0 | `30778b0` | First night always asked "Nice jump tonight…" | Require ≥ 2 sessions |

## State

| State | Where | Scope |
|-------|-------|-------|
| Test fixtures | `ModelsTestSupport` (library product, test-only consumers) | Test targets |
| Test derived data + logs | `.build/test-derived-data` (gitignored) | Local / CI run |
| Shared singletons in tests | Suites touching one shared file/singleton are `.serialized`; state reset in `init` | Per test |

## Edge Cases

- **Shared state**: `SnoreDetector` and `RealtimeDetectionTracker` get isolated instances; `StorageLimitEnforcer` takes explicit limits; nothing writes `UserDefaults`.
- **Real files**: written to the test host's Documents or temp folders with unique names, removed afterwards (verified: no leftovers).
- **Notifications**: `RecordingDelayManager` paths that call `UNUserNotificationCenter` (throws without an app bundle) aren't exercised.
- **Time zones**: date-grouping tests build dates with the calendar the code uses, at midday; scoring fixtures use a fixed UTC calendar.
- **Float boundaries**: spectral threshold cases sit 0.1 dB on either side of each boundary.
- **xcodebuild after a failure**: a crashing test triggers "Restarting after unexpected exit…" for every remaining test, and a plain failure can also hang `xcodebuild` for 10+ minutes after results print. Check the log for `recorded an issue` / `Restarting after`.

## Tasks Completed

F21-T1 … F21-T16, F21-T18. F21-T17 (UI smoke tests) skipped. See `docs/trackers/f21-test-coverage.md`.

## Follow-up

- **Real-night check of the spectral fallback**, then pass `spectralScore` to `classify` in `RealtimeDetectionTracker`. Also confirm on device that the Advanced player's spectrum isn't flat.
- **Event state machine** in `RealtimeDetectionTracker` (start/stop debounce, bursts, intensity, short-event gate, melody) is untested. Proposed: extract it into a pure, clock-driven type in its own feature, with a device check.
- **Orphaned clips** from past deletes are still on users' disks; a one-off cleanup could remove `event_*.m4a` files with no matching event.
- **Events saved since May** have 0 frequency/centroid/low-band ratio; recompute from clips or leave.
- **Hardcoded notification text** in `RecordingDelayManager.scheduleNotification` (title + body).
- `sleepScore(using:)` reads the cached snoring duration once `hasCachedScore` is set (contradicts its doc comment).
- `DateFormatters.time` and `.timeWithPeriod` are identical.
- `macos-26` runner label availability on GitHub; first CI runs to confirm.
- UI smoke tests (T17) need a UI test target in the Xcode project.
