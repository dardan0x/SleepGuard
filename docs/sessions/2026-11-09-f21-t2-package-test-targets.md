### Completed
- F21-T2: `AudioEngineTests`, `EnvTests`, `RecordingsTests`, `StatisticsTests` and `DesignSystemTests` targets, each with one seed test. `scripts/run-tests.sh` now runs 7 packages and 45 tests, all passing.

### Technical Details
- Each target uses `path: "Tests"` (same as Personalization), `.swiftLanguageMode(.v6)`, and `.defaultIsolation(MainActor.self)` only where the library has it (Recordings, Statistics, DesignSystem). AudioEngine and Env have none; their seed suites are `@MainActor` because `SnoreDetector` and `SessionCheckpointStore` are.
- Env, Recordings and Statistics tests also depend on `Models` directly, ready for the session fixtures in T4.
- Seed tests:
  - `SnoreDetector.classify(db: -5)` with no confidence or spectral score → `.none`
  - `SessionCheckpointStore` clear → `loadIfPresent() == nil`
  - `SessionGrouper` on empty input → no sections
  - `WeekOverWeekTrendCalculator` on empty input → nil
  - `DurationFormatter.hoursAndMinutes(45)`
- `run-tests.sh` needed no change: it discovers packages by `testTarget` in `Package.swift`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/{AudioEngine,Env,Recordings,Statistics,DesignSystem}/Package.swift` | +10–12 each | `<Pkg>Tests` test target |
| `Packages/AudioEngine/Tests/SnoreDetectorTests.swift` | +10 (new) | No-signal → `.none` |
| `Packages/Env/Tests/SessionCheckpointStoreTests.swift` | +11 (new) | Clear → nil |
| `Packages/Recordings/Tests/SessionGrouperTests.swift` | +8 (new) | Empty input |
| `Packages/Statistics/Tests/WeekOverWeekTrendCalculatorTests.swift` | +8 (new) | Empty input |
| `Packages/DesignSystem/Tests/DurationFormatterTests.swift` | +8 (new) | Under an hour |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T2 Done |

### Architecture Decisions
- **No test targets for Learn, Onboarding, Settings or SleepSession**: they're almost all views. Their only helpers are audio I/O wrappers that a unit test can't meaningfully cover.
- **Real seed tests, not placeholders**: each one is an edge case a later task needs anyway.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 45/45 pass. SwiftFormat lint is clean and the layering check passes.

### Changes done
```
- Add <Pkg>Tests targets (path: Tests) to 5 package manifests
- Seed tests: SnoreDetector no-signal, checkpoint clear, grouper empty, trend empty, duration formatter
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T3: CI tests job. It needs the trigger decision (push vs. pull requests only).
- F21-T4: shared fixtures (in-memory SwiftData container, session/event builders).

### Open Questions
- CI trigger for T3.
- `WeekOverWeekTrendCalculator` hardcodes `"vs prev wk"` (not localized). Fix in T15?
