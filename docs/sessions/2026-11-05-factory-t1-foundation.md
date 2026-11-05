---
date: 2026-11-05
feature: f19
branch: feature/f19/t1-factory-foundation
title: Factory DI Migration — T1 Foundation
---

### Completed
- F19-T1: Factory foundation. `Factory` (FactoryKit 3.5.2) added as SPM dependency; `Container` extensions register every service in today's DI graph. Zero view/wiring changes — all `.shared` singletons preserved.

### Technical Details
- Registrations alias existing `.shared` instances (`self { X.shared }.singleton`), so resolution returns the identical instances the app uses today. Single source of truth stays with the statics until T4 flips ownership.
- 17 factories in `Packages/Env/Sources/Services/Container.swift`: 14 `@MainActor` singletons (appConfig, audioRecorder, customMelodyStorage, healthKitSync, hapticManager, notificationPermissionManager, pendingSessionStore, recordingDelayManager, sessionCheckpointStore, sessionManager, snoreInterrupterPlayer, soundAnalysisDetector, userPreferences, watchConnectivityManager), 2 non-isolated singletons (sessionRawLogWriter — actor; storageLimitEnforcer — Sendable class), routerPath with default `.unique` scope (matches per-tab/per-sheet usage).
- 1 factory in `Packages/DesignSystem/Sources/Container.swift`: theme. Registered there because Theme lives above Env in the package graph (Env must not import DesignSystem per `check-layering.py`); Factory's documented multi-module `Container` extension pattern.
- All factory properties declared `public` — required for cross-module resolution by feature packages in T2/T3.
- Internal composition types (`SessionRecordingController`, `RealtimeDetectionTracker`, `SpeechDetector`, `SnoreDetector`) intentionally NOT registered — T4 moves composition into the container when it has a real consumer. Skipping avoids speculative registration.
- Not registered (not services): `MockDataGenerator`, `SessionFileCleanup`/`deleteSessionFiles(_:)` (static utilities), `TabCoordinator` (held as `@State`, not in the environment graph).
- `Package.resolved` is gitignored in this repo; CI resolves `from: "3.5.2"` fresh. Build log confirms checkout at exactly 3.5.2.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Package.swift` | +2 | Factory SPM dependency + FactoryKit product |
| `Packages/DesignSystem/Package.swift` | +2 | Factory SPM dependency + FactoryKit product |
| `Packages/Env/Sources/Services/Container.swift` | +39 | New: 17 container registrations (16 singletons + routerPath unique) |
| `Packages/DesignSystem/Sources/Container.swift` | +6 | New: theme registration |

### Architecture Decisions
- **Registrations alias `.shared` rather than own construction**: guarantees zero behavioral drift in T1; ownership flips in T4 when composition moves into the container.
- **Theme registered in DesignSystem, not Env**: layering — DesignSystem sits above Env. Multi-module `Container` extensions are Factory's blessed pattern.
- **No registration of internal Session/ AudioEngine internals yet**: AGENTS.md "nothing speculative" — T4 adds them with real composition call sites.

### Build Status
- **BUILD SUCCEEDED** — `build_sim`, 53.7s, zero errors, zero warnings
- `python3 scripts/check-layering.py` — passed (219 files scanned)

### Suggested Branch
`feature/f19/t1-factory-foundation` (work committed and pushed)

### Suggested Commit
`[F19-T1] — Factory foundation in Env` (already committed)

### Changes done
```
- Packages/Env/Package.swift (+2)
- Packages/DesignSystem/Package.swift (+2)
- Packages/Env/Sources/Services/Container.swift (new, 17 registrations)
- Packages/DesignSystem/Sources/Container.swift (new, theme)
```

### Next Session
- F19-T2 (`feature/f19/t2-statistics-pilot`): swap `@Environment(X.self)` → `@Injected(\.x)` in Statistics views, FactoryKit in its Package.swift, preview mocks via `register { ... }`. User reviews the pilot PR before T3 fans out.

### Open Questions
- None new.
