### Completed
- F21-T8: `SnoreDetector` classification tests in AudioEngine, 7 new tests (28 parameterized cases). The suite is now 110 tests, all passing.

### Technical Details
- `SnoreDetector.init` changed from `private` to internal (user chose option b) so each test builds its own detector. `.shared` is unchanged; `@testable import` reaches the initializer and app code doesn't use it.
- **Routing** (`classify`):
  - confidence 0.2 with spectral 1.0 → `.none` (SoundAnalysis wins)
  - spectral alone at −5 dB → `.epic`
  - no signal → `.none`
  - `update` writes `currentState`
- **SoundAnalysis** (defaults quiet −50 / light −40 / loud −20 / epic −10; gates 0.35 / 0.55 / 0.45):
  - 0.34 → none
  - epic needs ≥ 0.55 (0.54 → loud)
  - each dB floor
  - below every floor: 0.45 → quiet, 0.44 → none
- **Spectral**:
  - score 0.59 → none; −56 dB (under quiet − 5) → none
  - score 1.0 uses the base thresholds
  - score 0.6 raises them (quiet −46, light −36.8, loud −18, epic −8.8), checked 0.1 dB on either side
- **Plain thresholds** are inclusive at −10 / −20 / −40 / −50.
- **Custom thresholds** on one instance don't affect another.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | +2/−1 | `init` internal, with a doc comment |
| `Packages/AudioEngine/Tests/SnoreDetectorTests.swift` | +100/−3 | Seed test replaced by the full suite |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T8 Done |

### Architecture Decisions
- **Internal init over mutating `.shared`**: tests stay parallel and can't leak thresholds into each other or into Env tests. The one-word visibility change has no runtime effect.
- **Sensitivity presets deferred to T11**: they're defined in `RealtimeDetectionTracker` (Env).

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 110/110 pass. SwiftFormat lint is clean and the layering check passes.

### Changes done
```
- Make SnoreDetector.init internal for isolated test instances
- SnoreDetectorTests: routing, SoundAnalysis/spectral/threshold tiers, per-instance config
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T9: `FFTAnalyzer` and the `TapProcessor` RMS/peak levels with synthetic `AVAudioPCMBuffer`s (sine, silence, noise).

### Open Questions
- None new.
