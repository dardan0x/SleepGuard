---
date: 2026-11-10
feature: F22
branch: feature/f22/t7-remove-shared
title: F22-T7 container-only service access; DesignSystem drops Env
---

### Completed
- F22-T7: no feature package or DesignSystem file touches an app service's `.shared`, and CI enforces it. `Env` services list their collaborators in `init`. DesignSystem no longer depends on `Env`.

### Technical Details
- **Views:** `@Injected(\.svc) private var svc` replaces `Svc.shared` in Onboarding, Personalization (×2), Recordings (×2), Settings, SleepSession (×7).
- **Helpers / Env:** `init(dep: any P = Container.shared.dep())` on `CustomMelodyRecorder`, `MelodyPreviewPlayer`, `SessionRecordingController`, `RealtimeDetectionTracker`, `SnoreInterrupterPlayer`, `RecordingDelayManager` and `TabCoordinator`. In `AudioEngine`, `AudioRecorder(soundAnalyzer:)` defaults to `.shared`, because there's no container there.
- **Escaping closures** capture `[rawLogWriter]` for the actor existential. The nudge `Timer` uses `[weak self]` + a `@MainActor` hop.
- **DesignSystem:** `RecordingActionButton` uses `.sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger: tapCount)`, `SleepStagesInfoView` defaults to `Container.shared.theme()`, `SnoringTimelineView` drops `import Env`, and `Package.swift` drops `Env`.
- **Statistics:** removed `DaySummary.intensityColor` (a duplicate of `Theme.intensityColor`). `DaySummary` now imports only Foundation + Models.
- `check-layering.py` rule 4: app-service `.shared` is forbidden in `Packages/*/Sources` outside Models/AudioEngine/Env/Routing and `Container.swift`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| 13 feature view files | ±2–6 each | `@Injected` instead of `.shared` |
| `Packages/SleepSession/Sources/Helpers/{CustomMelodyRecorder,MelodyPreviewPlayer}.swift` | +8 each | Injected melody storage |
| `Packages/Env/Sources/Services/Session/{SessionRecordingController,RealtimeDetectionTracker}.swift` | +30 each | Constructor injection |
| `Packages/Env/Sources/Services/{SnoreInterrupterPlayer,RecordingDelayManager,TabCoordinator,StorageLimitEnforcer,MockDataGenerator}.swift` | ±5–15 | Constructor injection / container resolution |
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +3 | `soundAnalyzer` init parameter |
| `Packages/DesignSystem/Package.swift`, `Components/{RecordingActionButton,SleepStagesInfoView,SnoringTimelineView}.swift` | ±8 | Env dependency removed |
| `Packages/Statistics/Sources/Views/{Last7NightsDaySummary,Last7NightsChartCard,Last7NightsRow}.swift` | −12/+2 | Duplicate color mapping removed |
| `scripts/check-layering.py` | +20 | Rule 4 |
| `Packages/Env/TestSupport/FakeSessionServices.swift` | ±3 | `MM:SS` format |
| `Packages/Env/Tests/{ConstructorInjectionTests,RecordingDelayManagerTests,ServiceOverrideTests}.swift` | new / ±10 | 5 new tests; fresh-instance delay tests |
| `CLAUDE.md`, `AGENTS.md` | ±1 | Rule wording |
| Trackers | — | T7 Done |

### Architecture Decisions
- **Constructor injection with container defaults for services; `@Injected` for views.** Services show their dependencies in the signature, and production call sites stay `Foo()`. Views keep the SwiftUI-friendly property wrapper.
- **`.sensoryFeedback` over threading a closure through the buttons:** DesignSystem stays a leaf with identical haptics and no API change.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5, 0 warnings, 0 errors), and the simulator launch is clean (the session graph is constructed at launch).
- `run-tests.sh`: AudioEngine 37, DesignSystem 7, Env 40, Models 77, Personalization 30, Recordings 16, Routing 3, Statistics 8, all passing.
- SwiftFormat: 0/294 files need formatting. Layering check passes.

### Suggested Branch
`feature/f22/t7-remove-shared` (from `feature/f22-architecture-hardening`)

### Suggested Commit
```
F22-T7 — Container-only service access; DesignSystem drops Env

- Feature views/helpers resolve services via @Injected / container
- Env services take collaborators in init (container defaults)
- DesignSystem: no Env dependency; RecordingActionButton uses sensoryFeedback
- DaySummary duplicate color mapping removed
- check-layering rule 4: no app-service .shared above Env
- ConstructorInjectionTests; fresh-instance RecordingDelayManagerTests
- CLAUDE.md/AGENTS.md; trackers; session fragment
```

### Next Session
- F22-T8: extract the pure `DetectionStateMachine` into AudioEngine.

### Open Questions
- None new.
