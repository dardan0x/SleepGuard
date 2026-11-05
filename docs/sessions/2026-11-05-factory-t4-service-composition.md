---
date: 2026-11-05
feature: f19
branch: feature/f19/t4-service-composition
title: Factory DI — Service composition
---

### Completed
- F19-T4: `SessionManager`'s hand-wired internals moved into container factories; cross-wiring preserved.

### Technical Details
- New internal (non-public) factories in `Packages/Env/Sources/Services/Container.swift`: `sessionRecordingController` and `realtimeDetectionTracker`, both `@MainActor` + `.singleton`, constructing the types directly (they are internal to Env, have no `.shared`, and are owned exclusively by `SessionManager`).
- `SessionManager` resolves both in its `private init()` via `Container.shared.…()` and performs the existing cross-wiring there (`recording.attach(detection:)`, `detection.recording = recording` weak). Public API unchanged.
- **Key finding: `@Observable` + `@Injected` collide.** Both macros synthesize underscore backing storage (`_recording`), producing "invalid redeclaration of synthesized property" compile errors. Resolution: resolve via `Container.shared.x()` in init inside `@Observable` classes. This rule must land in the T5 docs/AGENTS rewrite.
- **Vacuous criterion, with evidence:** the acceptance criterion "nonisolated Apple delegates use `dependency(\.…)`" has no call sites. All three delegate classes (`WatchConnectivityManager`/WCSession, `SoundAnalysisDetector`/SNResultsObserving, `SnoreInterrupterPlayer`/AVAudioPlayerDelegate) already parse payloads synchronously and hop via `Task { @MainActor in }` to touch only their own state — none access another service from nonisolated code. No `dependency(\.…)` helper added (criterion 3 conditional on 2).
- `SpeechDetector`/`SnoreDetector` (AudioEngine `.shared` singletons) intentionally not containerized — adding FactoryKit to the core AudioEngine package for two internal-only call sites is not justified.
- Layering check green (219 files). Build green twice.

### Pre-existing issue found (not a T4 regression)
- Starting a recording in the iOS simulator crashes with EXC_BREAKPOINT (SIGTRAP, codes `0x1, 0x1801c3e80`) on the AVFAudio realtime messenger thread inside `installTap` (`AudioRecorder.swift:220`). Reproduced identically on the un-modified `factory-reformat` baseline (crash reports `SleepGuard-2026-11-05-154038/154254/154433.ips`); persisted after `simctl privacy grant microphone`. Recording-start has likely never been exercised in this simulator. Needs on-device verification or a separate investigation — flagged to the user, not fixed here.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/Container.swift` | +11 | Internal `extension Container` with `sessionRecordingController` + `realtimeDetectionTracker` singleton factories |
| `Packages/Env/Sources/Services/Session/SessionManager.swift` | +12/-4 | Hand-wired `private let` construction → container resolution in `init`; cross-wiring unchanged |

### Architecture Decisions
- **Init-time resolution over `@Injected` in `@Observable` classes**: forced by the macro collision; also matches the "no property wrappers in observable classes" pattern the tracker criterion anticipated for nonisolated code.
- **Internal factories, not public**: the types are internal to Env; a public factory property would not compile. Keeps the composition surface minimal.

### Build Status
- **BUILD SUCCEEDED** — zero errors, layering check green.

### Suggested Branch
`feature/f19/t4-service-composition`

### Suggested Commit
`[F19-T4] — Service composition via container`

### Changes done
```
- SessionRecordingController + RealtimeDetectionTracker registered as internal container factories (singleton)
- SessionManager resolves both from Container.shared in init; attach/weak-recording wiring preserved
```

### Next Session
- F19-T5: Watch app evaluation, AGENTS.md DI rules rewrite (must include the `@Observable`/`@Injected` collision rule), dependencies.md rewrite, feature doc.

### Open Questions
- Simulator recording crash (pre-existing): investigate separately or verify on device?
