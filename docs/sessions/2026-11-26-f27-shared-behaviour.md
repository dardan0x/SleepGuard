---
date: 2026-11-26
feature: F27
branch: refactor/f27-architecture-interrogation-fixes
title: Shared behaviour (HealthKit, raw log), DesignSystem duplicates, Env renamed Services
---

### Completed
- Answered the owner's questions on sharing, DesignSystem, public imports, naming and the shared checkout's place in Xcode.
- F27-T18: shared 0.32.0 (`SleepHealthKit`, `SleepFiles`), wrapped by `HealthKitSync` and `SessionRawLogWriter`.
- F27-T19: DesignSystem duplicates of the kit removed.
- F27-T20: `Env` renamed `Services`.
- F27-T21: shared settings (0.33.0): `UserPreferences` delegates its 16 common settings to `PreferencesDefaults`.
- F27-T22: uniform the apps, release A (0.34.0): logging, classifier, sample nights, files and layout, storage sweep, start notification.
- F27-T24: release C (0.36.0): one SwiftData schema, SleepStore's NightRecord / NightEventRecord, stored summary, shared store opening.
- F27-T23: release B (0.35.0): SleepAudioKit for capture, compression, playback, waveform, spectrum, extraction and melodies; four audio bugs fixed.

### Technical Details
- Principle: share behaviour (implementations over shared values), keep protocols per app. A protocol encodes an app's DI, state and isolation; a shared implementation is what fixes a bug once.
- `HealthKitSync` keeps its observable `isAuthorized`; reads stages regardless of write permission (HealthKit never reports read permission); logs failures.
- `SessionRawLogWriter` keeps its 200-sample buffer; the file, time order and empty-log removal are `RawLogFile`'s.
- The public `HealthKitSync.init(health:)` exposes `HealthKitSleep`, so that file needs `public import SleepHealthKit` (InternalImportsByDefault).

### Files Changed
- Shared (owner tagged 0.32.0): `Sources/SleepHealthKit/HealthKitSleep.swift`, `Sources/SleepFiles/RawLogFile.swift`, tests, `Package.swift`, `README.md`, `scripts/run-tests.sh`
- `Packages/Health/Sources/HealthKitSync.swift`, `Packages/Health/Package.swift`
- `Packages/Services/**` (was `Packages/Env`), `SessionRawLogWriter.swift`, `SessionRawLogWriting.swift`, `Package.swift`
- Every manifest and Swift import naming Env; `SleepGuard.xcodeproj/project.pbxproj`; `scripts/check-layering.py`, `scripts/check-imports.py`
- DesignSystem: `Theme+Intensity.swift`, `DurationFormatter.swift`, `DurationFormatterTests.swift`, `SessionRow.swift` removed; `ThemeEnvironmentTests.swift`; `SessionDetailAdvancedPlayerView.swift`; widgets
- Docs: CLAUDE.md, AGENTS.md, README.md, TECHNICAL_OVERVIEW.md, ADR 0008 (note), ADR 0009, trackers

### Architecture Decisions
- Shared behaviour, per-app protocols (README of the shared repo and AGENTS.md).

### Build Status
- Pinned 0.32.0: app builds, all package tests pass, layering and import checks pass.

### Suggested Branch
`refactor/f27-architecture-interrogation-fixes` (into main by the owner)

### Suggested Commit
```
F27-T18/T20 — Shared HealthKit and raw-log behaviour; Env renamed Services
```

### Next Session
- Owner: merge the F27 branch; one real night on a device.

### Open Questions
- None.
