
### Completed
- F7-T2 (tracked in SleepGuardUIKitWay): per-sample detection rules come from `SleepCore`: `SnoreClassifier` (and its sensitivity presets), `SpeechClassifier`, `DetectionSensitivity`.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | Thresholds default to the shared Medium preset; classification through `SnoreClassifier`; `apply(_:)` takes a preset |
| `Packages/AudioEngine/Sources/Engine/SpeechDetector.swift` | `SpeechClassifier`'s verdict; logs kept |
| `Packages/Env/Sources/Services/Session/RealtimeDetectionTracker.swift` | `apply(_:)` uses `SnoreClassifier.preset`; minimum event length from `DetectionSensitivity` |
| `Packages/Env/Sources/Services/UserPreferences.swift` | `DetectionSensitivity` is an alias of the shared enum |
| `AGENTS.md`, `CLAUDE.md`, `docs/adr/0004-shared-repo.md` | Detection rules are shared |

### Build Status
- All 8 suites pass against the local shared checkout, no test changed; app builds; layering and format pass. Shared: 121 SleepCore tests (replay goldens unchanged).
- Bumped to shared `0.14.0`: all 8 suites pass and the project (release) builds.
- Detection output is unchanged by construction (same rules, same tests); a real night on device would confirm.
