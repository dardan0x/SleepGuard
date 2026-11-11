---
date: 2026-11-11
feature: F22
branch: feature/f22/t8-detection-state-machine
title: F22-T8 pure DetectionStateMachine extracted from the tracker
---

### Completed
- F22-T8: the snore / sleep-talking / melody-gap rules are a pure `DetectionStateMachine` struct in AudioEngine. `RealtimeDetectionTracker` is now an adapter that performs its outputs.

### Technical Details
- Characterization first: an injectable clock on the old tracker, then 13 end-to-end scripted-sample tests recorded against it. They passed unchanged after the extraction.
- The machine API is `ingest(_:at:)`, plus the melody feedback calls `melodyDidStart(at:)` / `melodyDidStop(at:)` and `finalizeActiveEvents(at:)`. Outputs come back in the order to perform them.
- The tracker re-reads settings every tick (live preferences + the detector's gate), as before.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/DetectionStateMachine.swift` | +390 | New pure state machine + input/output types |
| `Packages/Env/Sources/Services/Session/RealtimeDetectionTracker.swift` | 775 → 447 | Adapter; injectable clock |
| `Packages/Models/Sources/Data/SnoreBurst.swift` | ±1 | `Equatable` |
| `Packages/Env/Tests/DetectionCharacterizationTests.swift` | +300 | 13 end-to-end behavior pins + harness |
| `Packages/AudioEngine/Tests/DetectionStateMachineTests.swift` | +260 | 18 machine unit tests |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T8 Done, 11/14 |

### Architecture Decisions
- The melody is modeled as a feedback loop (`melodyRequested` → `melodyDidStart`), because only the player knows whether it actually started (muted, mode "never", file missing).
- Classification stays outside the machine: it takes verdicts, not raw confidences, so T10 can move it independently.

### Build Status
- Lint clean; layering and view-size checks pass; all 8 package suites pass (261 tests: AudioEngine 55, Env 53); app build 0 warnings and launches on the simulator.

### Suggested Branch
`feature/f22/t8-detection-state-machine`

### Suggested Commit
`F22-T8 — Extract pure DetectionStateMachine; tracker becomes an adapter`

### Changes done
- See Files Changed.

### Next Session
- T9 replay tests: blocked on a real night recorded with "preserve raw audio" on (interrupter set to "never" if possible).
- T14 can be prepared, but ADR 0003 belongs to T10.

### Open Questions
- With the interrupter on, an event that doesn't resume after the melody is always discarded (0.10 s span). Intended? It's the "melody-pause bias" on the product list.
- Should bursts end at the last snoring sample, to match the event span?
