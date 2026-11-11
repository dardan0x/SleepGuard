# ADR 0003: Run detection on a `DetectionEngine` actor fed by one `AsyncStream`

- **Status:** Accepted
- **Date:** 2026-11-11
- **Task:** F22-T10 (builds on T8, the pure `DetectionStateMachine`, and T9, the replay tests)

## Context

Before F22, live detection was one 775-line `@MainActor` class. A 50 ms loop on the main actor read the latest mic level and SoundAnalysis confidence, classified the sample, ran the event rules and performed the side effects, all in one call. Melody stops arrived through a notification handler that mutated the same state.

That worked, but it had three weaknesses the mock staff-engineer interview pointed at:

1. **Ordering was implicit.** It held only because everything ran on one actor in one synchronous call. Any `await` added later (a Task per sample, a delegate hop) could reorder a melody stop and a sample with nothing to catch it.
2. **The rules were coupled to the main actor and to the clock.** You could not run them anywhere else, or replay them without the whole app around them.
3. **The thresholds were sample counts** ("3 consecutive samples"), so they silently meant something else if the sampling rate changed.

T8 made the rules a pure value type and T9 pinned their output on a real recording. This ADR decides where that machine runs.

## Decision

```
main actor                                     DetectionEngine (actor)
──────────                                     ───────────────────────
50 ms sampler ── classify ──► .sample(input, at: t)  ┐
melody-stop notification ───► .melodyDidStop(at: t)  ├─► AsyncStream ─► DetectionStateMachine
settings changed ───────────► .settings(…)           │   (ordered)            │
session stop ───────────────► .finalize(at: t)       ┘                        │
                                                                              ▼
perform(batch) ◄──────────── Batch(outputs, time) ◄───────────────── one batch per message
   └─ melody actually started ─► returns [.melodyDidStart(at: t)] ─► applied before the next queued message
```

- **One stream for everything that changes detection state.** Every message carries the time it was observed at its source, and the engine handles them strictly in arrival order. A melody stop that happened between two samples is applied between them, whichever task sent it.
- **The engine awaits each batch** before the next message. Side effects (event clips, SwiftData writes, the Snore Interrupter) stay on the main actor where those APIs live, and run in order. Backpressure slows the engine down; it never reorders anything.
- **Feedback is returned, not re-queued.** The melody is a feedback loop: only the player knows whether it actually started (it may be muted, set to "never", or missing a file). `perform` returns `.melodyDidStart`, and the engine applies it *before* the next queued sample, exactly as the synchronous tracker did. Re-queuing it would let samples that were already waiting slip in between.
- **Thresholds are durations.** Runs are "sustained for 75 ms, first sample to latest", which sits between two and three 50 ms intervals and equals the old "3 consecutive samples" at 20 Hz. Events now start at the run's actual first sample instead of a fixed 0.1 s backdate.
- **The UI is published at 5 Hz.** `currentDB`, `currentDetectionState` and `currentSpeechDetected` update at most every 200 ms instead of on every sample.
- **The sampler stays the 50 ms loop** (user decision, 2026-11-11). Classification (`SnoreDetector`, `SpeechDetector`) stays on the main actor, and the stream starts at the sampler, not at each mic buffer.

## Consequences

**Better:**
- Ordering is a property of the design, not of everything happening to be synchronous. `DetectionEngineTests` replays the real recording delivered three ways (all queued at once, paced, and in jittered chunks with sleeps) and gets identical output every time. A dedicated test checks that melody feedback lands before queued samples.
- The rules run off the main actor, and the engine has no clock, no singletons and no SwiftData. It can be driven from a test, a replay tool or a future Watch build.
- Thresholds survive a change of sampling rate.
- The T8 characterization tests (13) pass unchanged through the actor.
- `.snoreInterrupterDidStop` is now posted with the player as its sender, and the tracker listens only to its own player. Once the tests started awaiting, they interleaved on the main actor, and one test's melody stop ended another test's gap. In the app there is one player, so behavior is unchanged.

**Honest limits:**
- **No measurable performance gain.** The state machine takes microseconds per sample. The main actor still classifies each sample and performs every side effect. The win is correctness (explicit ordering) and testability, not CPU.
- **The goldens moved, by design.** Event start times in the T9 goldens moved 15–26 ms earlier, because the first-sample backdate replaced the fixed 0.1 s on a recording whose ticks are about 54 ms apart. When events were detected, finalized or discarded, and their count, intensity, volume, confidence and bursts, are all identical. The goldens were re-recorded on purpose, and the diff is in the T10 commit.
- **Asynchronous by one hop.** A sample's side effects now happen a hop after the sample instead of inside the same call. Stopping a session awaits `finishDetection()`, which flushes the stream, so every event is saved before the audio engine stops (the old "finalize before stopRecording" rule still holds).
- **`waitUntilProcessed()` exists mainly for tests.** It is a barrier message, cheap and harmless in production, but it is test-facing API on a production type.
- **The stream is unbounded.** The plan said `.bufferingNewest(n)`, but under backpressure that drops the *oldest* messages, and losing a `.melodyDidStop` or `.finalize` corrupts a session, not just one sample. At 20 Hz with a consumer that takes microseconds per message, the queue is empty in practice. If the main actor ever stalls for minutes, the app has bigger problems than a few KB of queued samples.

## Alternatives considered

- **Feed every mic buffer and every SoundAnalysis result straight into the stream** (about 47 Hz, with classification and speech tracking moved into the actor). This is the purer pipeline, and the time-based thresholds make it possible. But it changes live detection: peak dB is checked twice as often, which biases intensity upward, and the raw log grows to about 150 MB a night. Nothing but a real night can validate that. Deferred to a follow-up that has one.
- **Keep the machine on the main actor (T8 only):** the simplest option, but ordering stays implicit, and the interview's concern stands.
- **Output `AsyncStream` instead of an awaited `perform` closure:** decouples further, but loses backpressure and needs a second mechanism to apply melody feedback before queued samples.
- **A serial `DispatchQueue`:** the project rule is no GCD, and an actor gives the same serialization with compiler-checked isolation.
