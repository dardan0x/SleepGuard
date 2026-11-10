### Completed
- F21-T4: a shared test-helper library, `ModelsTestSupport`, for the Models, Env, Recordings and Statistics test targets. 46 tests pass.

### Technical Details
- New target/product `ModelsTestSupport` in `Packages/Models` (`path: "TestSupport"`, Swift 6, depends on `Models`):
  - `TestCalendar.utc` + `TestCalendar.date(year:month:day:hour:minute:)`: fixed Gregorian/UTC.
  - `TestStore` (`@MainActor`): in-memory `ModelContainer` with the app's schema (`SleepSession`, `SnoreEvent`, `UserProfile`, `LifestyleLog`). `insert(_:events:gaps:)` inserts the session and events, *then* attaches `events`/`recordingGaps`, then saves.
  - `SleepSession.fixture(start:hours:)`, `SnoreEvent.fixture(at:duration:intensity:category:averageDB:peakDB:bursts:)`.
- `TestStoreTests`: an inserted event is readable through `session.events`, its inverse points back, and `snoringDuration` = 90 s.
- `scripts/run-tests.sh`: with two library products, Xcode moves the package tests to the `Models-Package` scheme ("Scheme Models is not currently configured for the test action"). The script now uses `<Pkg>-Package` when `Package.swift` has more than one `.library(`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Package.swift` | +10/−1 | `ModelsTestSupport` product + target; ModelsTests depends on it |
| `Packages/Models/TestSupport/TestCalendar.swift` | +15 (new) | UTC calendar + date helper |
| `Packages/Models/TestSupport/TestStore.swift` | +38 (new) | In-memory SwiftData store |
| `Packages/Models/TestSupport/Fixtures.swift` | +30 (new) | Session/event builders |
| `Packages/Models/Tests/ModelsTests/TestStoreTests.swift` | +23 (new) | Store/relationship check |
| `Packages/{Env,Recordings,Statistics}/Package.swift` | +1 each | Test target depends on `ModelsTestSupport` |
| `scripts/run-tests.sh` | +3/−1 | `<Pkg>-Package` scheme selection |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T4 Done |

### Architecture Decisions
- **Helpers live in the Models package as a separate product**, not copied into each test target and not added to `Models` itself. One copy, and the app never links it.
- **In-memory store over bare `@Model` objects**: scoring and episode code reads `events`. A real context keeps inverses and the insert-then-mutate rule the same as in production.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 46/46 pass. SwiftFormat lint is clean and the layering check passes.

### Changes done
```
- Add ModelsTestSupport (TestCalendar, TestStore, fixtures) to the Models package
- Wire it into the Models, Env, Recordings and Statistics test targets
- run-tests.sh: use <Pkg>-Package scheme for multi-product packages
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T5: sleep score tests (`sleepScore(using:)`: zero duration, intensity weighting by burst sum, recording gaps, cached vs. recomputed).

### Open Questions
- Did the T3 CI run pass on PR #108? (`gh` isn't installed locally, so I couldn't check.)
