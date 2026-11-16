
### Completed
- F7-T3a (tracked in SleepGuardUIKitWay): detection inputs from `SleepCore`: `AudioLevels`, `SpectralFeatures`, `SoundClassLabels`.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/AudioEngine/Sources/Engine/TapProcessor.swift` | RMS / peak dB from `AudioLevels` |
| `Packages/AudioEngine/Sources/Engine/FFTAnalyzer.swift` | Features and bars from `SpectralFeatures` (alias); the Accelerate transform stays |
| `Packages/AudioEngine/Sources/Engine/SoundAnalysisDetector.swift` | Class lists and confidences from `SoundClassLabels` |
| `AGENTS.md`, `CLAUDE.md`, `docs/adr/0004-shared-repo.md` | Detection inputs are shared |
| Package manifests, `Package.resolved` | Shared `0.15.0` |

### Build Status
- All 8 suites pass against the local shared checkout, no test changed; app builds; layering and format pass. Shared: 133 SleepCore tests.
- Bumped to shared `0.15.0`: all 8 suites pass against the release, the pinned app builds, layering passes.

### Open Questions
- `RealtimeDetectionTracker` closes the event file on `.eventClipClosed` (the mic pauses for a melody); the later `.snoreEventFinalized` then finds no open file, so that event's clip is never compressed and its `.caf` stays behind. Not verified on a device; worth a look when F8 ports the Snore Interrupter.
