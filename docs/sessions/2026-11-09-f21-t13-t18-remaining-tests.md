### Completed
- F21-T13: `SessionCheckpointStore` (5) + `RecordingDelayManager` (4, side-effect-free paths) tests.
- F21-T14: `SessionGrouper` (5) + `SessionDetailModel` (9) tests. **Bug fix**: deleting a session (detail screen and list) left its event clips on disk.
- F21-T15: `WeekOverWeekTrendCalculator` tests (8). The hardcoded "vs prev wk" label is now localized.
- F21-T16: `DurationFormatter` + string catalog tests (all 438 keys resolve to their English value). Found 2 malformed catalog keys.
- F21-T17: skipped (user choice; needs a UI test target).
- F21-T18: full verification, feature doc, ProjectArchitecture Tests section, FFT note in the detection doc. **F21 done: 180 tests in 7 packages, all passing.**

### Technical Details
- **T13**:
  - Both suites are `.serialized`: one shared `Documents/session_recovery.json` file, one `RecordingDelayManager.shared`.
  - Checkpoint tests: write/load, replace, clear removes the file, no events → not offered, corrupt JSON → nil.
  - Delay tests: `remainingTimeString` mm:ss (incl. "100:00"); `checkIfComplete` false when inactive, with no target, or before the target.
  - Not tested: `startDelay` / `cancel` / completion, which call `UNUserNotificationCenter.current()` (throws without an app bundle) and the mic warm-up.
- **T13 crash**: a `MainActor.assumeIsolated` in a suite `deinit` trapped (the `deinit` ran off the main thread). xcodebuild printed "Restarting after unexpected exit, crash, or test timeout" and relaunched for every remaining test. Fix: reset shared state in `init`.
- **T14 bug**: `SessionDetailModel.delete` and `RecordingsListView`'s group delete deleted and saved the events, then called `deleteSessionFiles(session)`, which iterates `session.events` (now empty). Fix: call `deleteSessionFiles` before deleting the models, in both places. Detail model tests cover:
  - load refreshes the cache with the remote score config, sorts events, detects clip sessions
  - unknown id → `.error`
  - filters (all / snoring representatives / sleep talking / noise + coughing + other), short events, display durations, filter visibility
  - delete removes the models and all files; unknown id → false
- **T15**:
  - `Trend.diff: Int` with computed `isPositive`
  - `Last7NightsView` shows `String(format: Strings.statsLast7nightsTrendVsPrevWeek, trend.diff)`; the key `stats.last7Nights.trendVsPrevWeek` = "%+lld vs prev wk" was added via `Strings.txt` → `generate-xcstrings.py`
  - tests document that a "week" is the 7 most recent *recorded* days
- **T16**:
  - the catalog is read via `#filePath`; each key's English value is compared with `String(localized:bundle: .module)` at runtime
  - `localizations` / `stringUnit` (from `22ea853`) are malformed top-level keys, listed in `knownMalformedKeys`
- **T18**:
  - The layering check flagged `import DesignSystem` in StatisticsTests (test files count as non-view code), so the label test moved to DesignSystemTests (`TrendLabelFormatTests`).
  - Running totals in the F21 docs were 2 low from T5 on (46 + 22 recorded as 66); corrected everywhere.
  - A plain failure also hangs `xcodebuild` after results print (no restarts involved); runs were wrapped in `timeout`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Tests/SessionCheckpointStoreTests.swift` | +63/−9 | Seed replaced by 5 tests |
| `Packages/Env/Tests/RecordingDelayManagerTests.swift` | +45 (new) | Delay manager tests |
| `Packages/Recordings/Sources/Helpers/SessionDetailModel.swift` | +3/−1 | Delete files first |
| `Packages/Recordings/Sources/Views/RecordingsListView.swift` | +2/−1 | Delete files first |
| `Packages/Recordings/Tests/SessionGrouperTests.swift` | +75/−6 | Seed replaced by 5 tests |
| `Packages/Recordings/Tests/SessionDetailModelTests.swift` | +190 (new) | Detail model tests |
| `Packages/Recordings/Package.swift` | +1 | RecordingsTests → Env |
| `Packages/Statistics/Sources/Views/WeekOverWeekTrendCalculator.swift` | +6/−4 | `Trend.diff` |
| `Packages/Statistics/Sources/Views/Last7NightsView.swift` | +1/−1 | Localized label |
| `Packages/Statistics/Tests/WeekOverWeekTrendCalculatorTests.swift` | +80/−6 | Seed replaced by 8 tests |
| `Packages/DesignSystem/Sources/Resources/Strings.txt`, `Localizable.xcstrings`, `Strings.swift` | +13 | `stats.last7Nights.trendVsPrevWeek` |
| `Packages/DesignSystem/Tests/DurationFormatterTests.swift` | +20/−4 | Table of minute values |
| `Packages/DesignSystem/Tests/LocalizableCatalogTests.swift` | +55 (new) | Catalog completeness + runtime resolution |
| `Packages/DesignSystem/Tests/TrendLabelFormatTests.swift` | +11 (new) | Trend label format |
| `docs/features/f21-test-coverage.md` | new | Feature doc |
| `docs/ProjectArchitecture.md` | +7 | Tests (F21) section |
| `docs/snore-detection-algorithm.md` | +2 | FFT fallback status |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md`, earlier F21 session fragments | — | T13–T18, F21 Done, corrected totals |

### Architecture Decisions
- **No notification seam for `RecordingDelayManager`**: testing those paths would need a new abstraction around `UNUserNotificationCenter` and the warm-up, which is more change than the logic warrants. Left as a note.
- **Delete-order fix in place, not a shared helper**: both delete paths already share `deleteSessionFiles`; only the call order was wrong.
- **Label formatting moves to the view**: Statistics' logic file stays free of UI text, as the layering rules require.
- **Malformed catalog keys kept**: deleting them needs approval. The test lists them, and a sentinel test fails once they're removed.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 180/180 pass. SwiftFormat lint clean; layering check passes; hardcoded-string check passes (base `origin/main`); `Strings.swift` matches the catalog.

### Changes done
```
- T13: SessionCheckpointStore + RecordingDelayManager tests
- T14: SessionGrouper + SessionDetailModel tests; fix clip files orphaned on session delete (detail + list)
- T15: localize the week-over-week trend label (Trend.diff + stats.last7Nights.trendVsPrevWeek); calculator tests
- T16: DurationFormatter table + string catalog completeness/runtime tests
- T17: skipped
- T18: verification, feature doc, ProjectArchitecture + detection doc updates, corrected test totals
```

### Next Session
- Merge `feature/f21/t13-t18-remaining-tests` → `feature/f21-test-coverage` → `main`.
- Then pick from the F21 follow-ups (feature doc): a real-night check of the spectral fallback, the `RealtimeDetectionTracker` state-machine extraction, orphaned-clip cleanup, malformed catalog keys.

### Open Questions
- Remove the malformed catalog keys `localizations` / `stringUnit`?
- `FeatureTracker.md` still lists F20 as In Progress (T8/T9) even though F20 is merged. Mark it Done?
- Notion wasn't updated during F21 (no Notion calls this session). Sync it?
