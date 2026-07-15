---
date: 2026-07-15
feature: none
branch: refactor/soothing-sound-rebranding
title: Snore Interrupter Rebrand
---

### Completed
- Renamed the "Soothing Melody" feature to **Snore Interrupter** across all user-facing copy, localization keys, Swift symbols, files, and notifications. The old name was misleading — the feature actively plays a sound to prompt the sleeper to change position and stop snoring, so "soothing" contradicted its intent.
- Shipped alongside (added outside the rename): reordered the built-in sound list and added new intervention sounds (Attention Chime, Baby Stop — Male/Female voice).

### Technical Details
- **Display copy** (English values in `Localizable.xcstrings`):
  - "Soothing melody" → "Snore Interrupter" (title, prestart row, lockscreen-enabled banner, session-summary stop messages)
  - "Soothing tune" → "Interrupter sound"; "Melody enabled/disabled" → "Sound enabled/disabled"; "RECORD MELODY" → "RECORD SOUND"
- **Localization keys**: 16 keys renamed `*.soothing.melody.*` → `snore.interrupter.*` (e.g. `soothing.melody.row.helper.text` → `snore.interrupter.row.helper.text`, `soothing.tune.melody.sheet` → `snore.interrupter.sound.sheet`). `Strings.swift` regenerated via `scripts/generate-strings.py`; accessors follow suit (`soothingMelodyRowHelperText` → `snoreInterrupterRowHelperText`).
- **Swift symbols**: `SoothingMelodyPlayer` → `SnoreInterrupterPlayer`, `SoothingMelodySheet` → `SnoreInterrupterSheet`, `SoothingMelodyMode` → `SnoreInterrupterMode`, `soothingMelodyMode` property → `snoreInterrupterMode`, notification symbols `soothingMelody{WillPlay,DidStop}` → `snoreInterrupter{WillPlay,DidStop}`, `FeatureFlag.soothingMelody` → `FeatureFlag.snoreInterrupter`.
- **Backward-compatibility preserved** (deliberate, not renamed):
  - UserDefaults key literal `"soothingMelodyMode"` kept as-is so existing users don't lose their saved setting.
  - `FeatureFlag.snoreInterrupter = "soothingMelody"` — raw value pinned (with comment) so the Remote Config `feature_flags` contract still matches.
- **Out of scope** (the separate custom-sound-recording sub-feature): `selectedMelodyID`, `CustomMelodyStorage`, `MelodyPickerSheet`, `RecordCustomMelodySheet`, `session.summary.melodyGaps*`, `session.bedside.melodyEnabled` still use "melody" naming.
- **Sound library** (`Melody.swift` + `sounds/`): list reordered; added `universfield-attention-chime-123107.mp3` and `Male_Voice_Saying_Stop.mp3`; `speech.mp3` → `female_voice_baby_stop.mp3`. Note: default `selectedMelodyID` is 6, which now maps to "Attention Chime" (previously "Acoustic Guitar").

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | ~48 | Display values + 16 key renames |
| `Packages/DesignSystem/Sources/Strings.swift` | ~32 | Regenerated accessors |
| `Packages/Env/Sources/Services/SoothingMelodyPlayer.swift` → `SnoreInterrupterPlayer.swift` | ~66 | Type/file rename, debug tags |
| `Packages/SleepSession/Sources/Views/SoothingMelodySheet.swift` → `SnoreInterrupterSheet.swift` | ~20 | Type/file rename |
| `Packages/Env/Sources/Services/UserPreferences.swift` | ~10 | Property + enum rename; UserDefaults literal preserved |
| `Packages/Env/Sources/Services/SessionManager.swift` | ~34 | Player references renamed |
| `Packages/Models/Sources/Data/AppConfigModels.swift` | ~3 | FeatureFlag case renamed + raw value pinned |
| `Packages/Models/Sources/Helpers/AudioNotifications.swift` | ~4 | Notification names renamed |
| `Packages/SleepSession/Sources/Views/{BedsideClockView,RecordingPrestartView}.swift` | ~58 | Symbol + accessor call-site renames |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | ~4 | Notification observers renamed |
| `Packages/Env/Sources/Services/HapticManager.swift`, `Packages/Models/Sources/Data/{RecordingGap,SleepSession}.swift` | ~8 | Comment updates |
| `SleepGuard/{AppRegistry,SleepGuardApp}.swift` | ~8 | Dependency-graph wiring renamed |
| `Packages/Models/Sources/Data/Melody.swift` | ~20 | Sound list reordered + new sounds |
| `sounds/*.mp3` | — | Added Attention Chime + Male voice; renamed speech → female_voice_baby_stop |

### Architecture Decisions
- **Rename identity, preserve persistence**: renamed everything a developer reads, but kept the two persisted contracts (UserDefaults key string, Remote Config flag raw value) frozen. Per the schema/defensive-policy mindset, changing persisted keys would silently reset users' saved settings and break remote toggling.
- **Scope boundary at "soothing" vs "melody"**: only identifiers carrying the feature identity ("soothing") were renamed. The custom-sound-recording sub-feature ("melody") was left intact to keep the diff traceable and avoid touching additional UserDefaults keys (`selectedMelodyID`).

### Build Status
- **BUILD SUCCEEDED** (`build_sim`, iPhone 16e / iOS 26.2). One pre-existing unrelated warning (`latestSession` unused in `MainTabView.swift:207`).

### Suggested Branch
`refactor/soothing-sound-rebranding` (already merged via PR #57)

### Suggested Commit
`Rebrand soothing melody to snore interrupter` (already committed as `f628fd6`)

### Changes done
```
- Renamed Soothing Melody → Snore Interrupter (copy, localization keys, Swift symbols, files, notifications)
- Preserved UserDefaults key "soothingMelodyMode" and pinned FeatureFlag raw value for backward compatibility
- Reordered built-in sound list; added Attention Chime and Male/Female "Baby Stop" voice sounds
```

### Next Session
- Optional follow-up: rename the remaining "melody" identifiers (custom-recording sub-feature) to "sound" for full internal consistency — touches `selectedMelodyID` (a UserDefaults key, needs the same preserve-literal treatment).

### Open Questions
- Should the default `selectedMelodyID` (6) intentionally point at "Attention Chime" now, or was the reorder meant to keep a different default? Worth confirming which sound new users hear first.
