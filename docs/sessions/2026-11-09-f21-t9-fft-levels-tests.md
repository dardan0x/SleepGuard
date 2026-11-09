### Completed
- F21-T9: tests for `FFTAnalyzer` and the `TapProcessor` RMS/peak levels with synthetic buffers (15 new). The suite is now 123 tests, all passing.
- **Bug fix**: `FFTAnalyzer` had returned all-zero features since 2026-05-08. Fixed, along with a crash in `spectrumBars` that the fix would otherwise have exposed. Live detection is deliberately unchanged (user choice: "Fix, keep detection off").

### Technical Details
- **Root cause**: `vDSP_DFT_zop_CreateSetup(nil, log2n, .FORWARD)` with `log2n = 10`. The function takes the transform length, so a length-10 setup is `nil`. Both `analyze` and `spectrumBars` hit `guard let fftSetup` and returned zeros. Introduced in `e4f7c56`.
- **Fix** (`FFTAnalyzer.swift`):
  - setup uses `vDSP_Length(bufferSize)`
  - new private `magnitudeSpectrum(of:sampleRate:)` copies up to `bufferSize` frames into zero-padded `bufferSize` arrays, runs the DFT, and returns the half-spectrum + bin width; both public functions use it
  - the old per-call code sized arrays by `frameLength`, which would read out of bounds for short buffers once the setup existed
  - the unused `log2n` is removed
- **`spectrumBars` crash**: 22 usable bins under 1 kHz (1024 frames, 44.1 kHz) for 32 bars meant `startBin = bar + 1` ran past `endBin = maxBin`, and `startBin..<endBin` traps. Now `startBin = 1 + bar·usable/barCount`, `endBin = max(startBin + 1, 1 + (bar + 1)·usable/barCount)`: always non-empty and ≤ `maxBin`.
- **Detection unchanged**: `RealtimeDetectionTracker` calls `classify(db:, spectralScore: 0, snoreConfidence:)`, with a comment explaining why. The raw sample log and event `averageSpectralScore` still use the real score.
- **Tests**:
  - `TestAudio` helper: sine, silence, LCG white noise
  - `FFTAnalyzerTests` (9): 215 Hz → dominant ±1 bin, low ratio > 0.8, centroid < 400, score > 0.9; 2 kHz → score < 0.1; noise and silence below the 0.6 gate; 512-frame buffer; 48 kHz; 32 bars in [0, 1] with max 1; 500 Hz peaks mid-range; silence → flat zeros
  - `TapProcessorLevelsTests` (6): amplitude 1 → peak 0 / RMS −3.01; 0.1 → −20 / −23.01; single spike −6.02 / −36.12; silence −200; spectral score is passed through; no files → writes never disabled

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/FFTAnalyzer.swift` | +37/−53 | Setup length, zero-padded shared spectrum, safe bar binning |
| `Packages/Env/Sources/Services/Session/RealtimeDetectionTracker.swift` | +4/−1 | Keep spectral input to `classify` at 0 |
| `Packages/AudioEngine/Tests/TestAudio.swift` | +36 (new) | Synthetic buffers |
| `Packages/AudioEngine/Tests/FFTAnalyzerTests.swift` | +80 (new) | Spectral features + bars |
| `Packages/AudioEngine/Tests/TapProcessorLevelsTests.swift` | +56 (new) | RMS / peak levels |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T9 Done |

### Architecture Decisions
- **Fix the analyzer, gate detection at the call site**: stats, saved event features and the spectrum UI get correct data now. The detection change (spectral fallback) waits for a real-night check, behind a one-line switch in the tracker.
- **Shared spectrum helper**: both public functions had the same broken setup and the same overflow risk, so one implementation fixes both.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 123/123 pass. SwiftFormat lint is clean and the layering check passes.

### Changes done
```
- Fix FFTAnalyzer: DFT setup takes the length; zero-pad short buffers via a shared helper
- Fix spectrumBars out-of-range crash when bins < bars
- RealtimeDetectionTracker: keep spectral fallback off (spectralScore: 0 into classify)
- Add TestAudio, FFTAnalyzerTests (9), TapProcessorLevelsTests (6)
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T10: `AudioClipExtractor` + `EventClipCompressor` with short synthetic files in a temp folder. `AudioClipExtractor.analyzeSpectralFeatures` now returns real values, so it's testable.

### Open Questions
- Real-night validation of the spectral fallback before passing `spectralScore` to `classify`. On-device check: open an event in the Advanced player; the spectrum should no longer be flat.
- Events saved since May have 0 for frequency, centroid and low-band ratio. Leave them, or recompute from clips?
