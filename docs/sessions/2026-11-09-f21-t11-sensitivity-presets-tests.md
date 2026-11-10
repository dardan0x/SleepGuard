### Completed
- F21-T11 (option C): tests for the Low/Medium/High detection sensitivity presets (5 new). The suite is now 141 tests, all passing. The live event state machine is deliberately out of scope.

### Technical Details
- `RealtimeDetectionTracker`:
  - `snoreDetector` went from `= SnoreDetector.shared` to an `init(snoreDetector: SnoreDetector = .shared)` parameter; the Factory registration `RealtimeDetectionTracker()` is unchanged
  - `applyDetectionSensitivity()` now calls the new `apply(_ sensitivity: UserPreferences.DetectionSensitivity)`, which holds the existing switch unchanged
- `DetectionSensitivityTests` (5):
  - exact threshold and gate values per preset (parameterized)
  - Medium equals the `SnoreDetector` defaults
  - Low > Medium > High for every value
  - −42 dB at confidence 0.3 → none / none / light
  - High then Low → Low values
- `Packages/Env/Package.swift`: EnvTests depends on `AudioEngine` (needed to build a detector via `@testable import`).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/Session/RealtimeDetectionTracker.swift` | +9/−3 | Injectable detector; `apply(_:)` |
| `Packages/Env/Package.swift` | +1 | EnvTests → AudioEngine |
| `Packages/Env/Tests/DetectionSensitivityTests.swift` | +62 (new) | Preset tests |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T11 Done |

### Architecture Decisions
- **Option C over a refactor** (user choice): no behavior change in the most delicate audio path inside a test-coverage feature. The state-machine extraction is proposed as its own feature, with a device check.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 141/141 pass. SwiftFormat lint is clean and the layering check passes.

### Changes done
```
- RealtimeDetectionTracker: injectable SnoreDetector (default .shared), apply(_:) for presets
- EnvTests depends on AudioEngine
- Add DetectionSensitivityTests (5)
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T12: `StorageLimitEnforcer` (day-based and size-based cleanup plans, metadata kept, only audio deleted) with `TestStore` + temp files.

### Open Questions
- Create a follow-up feature for extracting the event state machine from `RealtimeDetectionTracker` (with tests + a real-night check)?
