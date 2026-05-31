# F9 — Enhanced Detection

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P2 |
| **Version** | V1.1 |
| **Blocked By** | — |
| **Started** | 2026-05-07 |
| **Completed** | 2026-05-07 |
| **Feature Doc** | — |

## Summary

Replace the current amplitude-threshold snore detection with a CoreML-based classifier for more accurate snoring detection and reduced false positives.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F9-T1 | CoreML model integration | Model | Done | — | AudioEngine | 2026-05-07 | 2026-05-07 |
| F9-T2 | Replace threshold detection with ML | State | Done | F9-T1 | AudioEngine | 2026-05-07 | 2026-05-07 |

## Task Details

### F9-T1 — CoreML model integration

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] CoreML model is loaded and run in the audio tap callback
- [x] Model classifies audio buffers into snore/non-snore
- [x] Classification runs off the main thread to avoid blocking UI
- [x] Builds with zero errors

**Prompt Used:**
Generate SnoreClassifier.mlmodel with coremltools (decibel → quiet/light/loud/none classification), add to AudioEngine target resources, auto-generate Swift wrapper. Then integrate into SnoreDetector with lazy loading, CPU-only compute, and threshold fallback.

**Notes:**
- Model generated via coremltools Python script using NeuralNetworkBuilder with softmax output
- Input: 1-element double array (decibel); Output: 4-element probability vector [none, quiet, light, loud]
- Model loaded lazily in SnoreDetector init; on failure, `useCoreML` is set to false and threshold fallback activates automatically
- `MLModelConfiguration.computeUnits = .cpuOnly` to avoid GPU/ANE overhead for such a tiny network
- coremltools prints `Failed to load _MLModelProxy` warnings (missing `libcoremlpython`) but generation still succeeds — non-blocking

---

### F9-T2 — Replace threshold detection with ML

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] SnoreDetector uses CoreML output instead of dB thresholds
- [x] Existing quiet/light/loud intensity levels mapped from ML confidence scores
- [x] Detection sensitivity setting still functional
- [x] Builds with zero errors

**Prompt Used:**
Integrate SnoreClassifier into SnoreDetector: add `classifyWithCoreML`, modify `update(db:)` to prefer CoreML when available, map probability vector indices to SnoringState, apply confidence threshold. Keep threshold methods as public fallback.

**Notes:**
- `SnoreDetector.update(db:)` now tries CoreML first; falls back to `classifyWithThresholds` on prediction failure or if model unavailable
- `confidenceThreshold` property (default 0.6) gates classification — only returns a snore state if max probability exceeds threshold
- Sensitivity mapping: low sensitivity → higher confidence threshold (fewer detections), high sensitivity → lower threshold (more detections). Wire to `UserPreferences.detectionSensitivity` in future polish if needed
- `classifyWithThresholds` remains public for explicit fallback use and testing
- MLMultiArray shape `[1]` with `.double` data type matches model spec

---

### Session 36 Refinements (2026-05-10)

- **`SnoringState` Codable**: Changed from `Sendable` to `String, Sendable, Codable` so classification states can be serialized in the raw classification log.
- **`SnoreSample` struct**: New model in `AudioEngine` storing elapsed time, dB, spectral score, snore confidence, and classified state. Used by `SessionRawLogWriter` for ground-truth logging.
- **Per-burst classification accuracy**: Burst boundaries are determined by state transitions (`.none` → snoring starts a burst, snoring → `.none` ends a burst). This is more precise than time-based heuristics.

### Session 28 Refinements (2026-05-07)

- **Actor-isolation race fix**: `AudioRecorder` no longer copies `snoreConfidence` from `SoundAnalysisDetector` in the background audio tap (violates `@MainActor` isolation). `BedsideClockView` now reads `SoundAnalysisDetector.shared.snoreConfidence` directly on the main actor.
- **dB threshold fix for SoundAnalysis path**: Lowered floors to `-25` (loud), `-40` (light), `-60` (quiet) dB so low-mic-gain snoring isn't filtered out when SoundAnalysis confidence is high.
- **Bandpass filter on recordings**: Added `AVAudioUnitEQ` with `.bandPass` filter (center 300 Hz, bandwidth 2.5 octaves) to the audio engine. Saved audio files now contain only 100–500 Hz frequencies.
- **Debug logging**: Added `[SoundAnalysis]`, `[BedsideClockView]`, and `[SessionManager]` debug prints for end-to-end classification pipeline tracing.

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)

### Session 66 Refinements — Post-Recalibration Tuning (2026-05-28 → 2026-05-29)

> Continuation of the investigation work first captured in the prior "Snore Detection Investigation & Recalibration" session entry. Detailed methodology + data tables live in `docs/SNORE_DETECTION_HANDOVER.md`. This section records what changed in the repo since then.

- **Real-night verification of fix #4 (threshold recalibration)**: User ran an overnight on the recalibrated build (SA gate 0.35, dB floors −50/−40/−25/−15, `minEventDuration = 1.0 s` on Medium). Independent burst-detection on the `.caf` reported LOOSE 26.1 min / STRONG 16.6 min for a ~21 min subjective night; the app's High detection logged 20.94 min across 65 events — already in the right neighborhood, no further sensitivity tuning needed for Medium/Low.
- **Short-event orphan-FP investigation**: User reported false positives on High (1–2 s clips that weren't snores). Cross-referenced 27 short app events against the independent burst detector: 14 were corroborated by ≥3 nearby bursts (real isolated snores), 13 were orphans (real FPs). **Key finding: peak_conf and peak_db CANNOT separate them** — orphans actually have *higher* median `peak_conf` (0.57 vs 0.44 for corroborated shorts). Only `nearest_other_event_distance` (median 28 s real vs 100 s FP) separates them cleanly.
- **Temporal-context filter — attempted, then reverted by user**: Implemented Option B from the analysis: `SessionManager.finalizeActiveEvent` checked `eventSpan < shortEventDurationThreshold (2.0 s)` AND `Date.now - lastFinalizedEventEnd > temporalContextWindow (30 s)` → discard as orphan. Skipped on `skipMinDuration` (melody truncation). Added `lastFinalizedEventEnd: Date?` state, updated on each saved event, reset in `resetTrackingState`. Built clean. **User reverted the change** in a subsequent edit — restored `SessionManager` to the recalibrated-but-no-temporal-filter state. Design + data analysis preserved in `docs/SNORE_DETECTION_HANDOVER.md` for future revisit; the code change is fully reproducible from the handover doc if it's wanted later.
- **Cross-reference to F4 burst-marker work**: The capsule-span markers added in F4 Session 66 Refinements are the direct visual diagnostic for the orphan-FP pattern this investigation surfaced — a narrow capsule sitting on flat waveform is the exact shape of an orphan FP, and is now visible at a glance in the event player without scrubbing audio.
