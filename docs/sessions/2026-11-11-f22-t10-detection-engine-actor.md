---
date: 2026-11-11
feature: F22
branch: feature/f22/t10-detection-engine-actor
title: F22-T10 DetectionEngine actor fed by one ordered AsyncStream
---

### Completed
- F22-T10: detection rules now run on a `DetectionEngine` actor. Samples, melody stops, settings changes and the session-end flush go into one ordered `AsyncStream`, and outputs come back to the main actor in order.

### Technical Details
- The user chose option A: the 50 ms sampler stays as the stream's source, and classification stays on the main actor. Feeding mic buffers directly is deferred until a real night can validate it.
- `run(_:perform:)` awaits each batch. Melody feedback is returned from `perform` and applied before the next queued message.
- The stream is `.unbounded` on purpose: `.bufferingNewest` would drop control messages. See ADR 0003.
- Run thresholds became durations (`sustainedRunDuration` 75 ms), and onset backdates to the run's first sample. The goldens were re-recorded; only start times moved, 15–26 ms earlier.
- The UI is published at 5 Hz.
- `finishDetection()` flushes the stream and awaits the engine before the audio engine stops.
- `.snoreInterrupterDidStop` now carries the player as its sender, and the tracker observes only its own player. This fixed crosstalk between interleaving tests.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/DetectionEngine.swift` | +110 | New actor + `Message` / `Batch` |
| `Packages/AudioEngine/Sources/Engine/DetectionStateMachine.swift` | ±40 | Counters → run start dates; first-sample backdate |
| `Packages/Env/Sources/Services/Session/RealtimeDetectionTracker.swift` | ±90 | Engine lifecycle, stream sends, batch performer, 5 Hz display, `finishDetection` / `waitUntilProcessed` |
| `Packages/Env/Sources/Services/Session/SessionRecordingController.swift` | ±8 | Awaits `finishDetection()`; `runsProcessingLoop` test switch |
| `Packages/Env/Sources/Services/SnoreInterrupterPlayer.swift` | ±4 | Posts the stop notification with `object: self` |
| `Packages/AudioEngine/Tests/DetectionEngineTests.swift` | +230 | Engine vs goldens and vs the machine under 3 delivery patterns; feedback ordering; control order; settings; barrier |
| `Packages/AudioEngine/Tests/DetectionReplayTests.swift` | ±60 | Transcript split into run + render; shared by the engine tests |
| `Packages/AudioEngine/Tests/Fixtures/Replay/*.golden.txt`, `README.md` | — | Re-recorded (start times only) + history |
| `Packages/Env/Tests/DetectionCharacterizationTests.swift` | ±30 | Async harness that waits for the engine per sample; expectations unchanged |
| `docs/adr/0003-detection-actor.md` | +80 | Decision, consequences, honest limits, alternatives |
| `docs/architecture/concurrency.md` | +1 | Stream-into-actor pattern (local only: the folder is gitignored) |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T10 Done (real night pending), 13/14 |

### Architecture Decisions
- Feedback is returned, not re-queued, so ordering matches the old synchronous tracker exactly.
- The engine awaits `perform` rather than using an output stream: this gives backpressure and keeps one place where ordering is decided.

### Build Status
- Lint clean; layering and view-size checks pass.
- All 8 package suites pass (268 tests: AudioEngine 62, Env 53, Models 79, Personalization 30, Statistics 18, Recordings 16, DesignSystem 7, Routing 3). Env ran 3 times with no flakiness.
- The app builds with 0 warnings. Simulator smoke test (start, 20 s recording, stop, discard): no crash.

### Suggested Branch
`feature/f22/t10-detection-engine-actor`

### Suggested Commit
`F22-T10 — DetectionEngine actor fed by one ordered AsyncStream`

### Changes done
- See Files Changed.

### Next Session
- T14: ADR 0002 (protocols), docs truth pass, feature doc, AGENTS/CLAUDE sync.
- User: one real night on a device running this branch, comparing events with a usual night.

### Open Questions
- Follow-up for option B (mic buffers straight into the stream): worth a task once a real night on this branch has been checked?
