# Snore Detection Algorithm & Architecture

> Last updated: 2026-11-11 (F22: rules extracted into `DetectionStateMachine` on the `DetectionEngine` actor; duration thresholds; raw log format 2). Earlier: 2026-06-10 (Sessions 70–71: post-melody breathing delay, melody re-trigger, gap counting model)

This document is the canonical reference for how SleepGuard detects, records, measures, and scores snoring. It covers the real-time detection pipeline, the event-tracking state machine, audio file architecture, duration calculation philosophy, and how Sessions 67–69 changed the recording model.

---

## 1. Overview

SleepGuard runs a **20 Hz detection loop** (every 50 ms) while a session is active. On each tick it analyzes the microphone audio through three parallel paths:

1. **Apple SoundAnalysis** (`SNAudioStreamAnalyzer` with 300-class pre-trained model)
2. **FFT spectral analysis** (custom low-frequency dominance detector)
3. **dB level monitoring** (RMS → dBFS)

These feed into a **cascading classifier** that returns one of five states: `.none`, `.quiet`, `.light`, `.loud`, `.epic`.

A **state machine** in `SessionManager` then tracks sustained detection, groups nearby snoring into **epochs**, writes per-event audio files, triggers the soothing melody, and accumulates real-time statistics.

---

## 2. Detection Pipeline

### 2.1 Audio Capture (`AudioRecorder`)

```
AVAudioEngine.inputNode → tap (1024 samples)
    ├─→ calculateDB()           → currentDB (dBFS)
    ├─→ FFTAnalyzer.analyze()   → spectralScore, lowFreqRatio, spectralCentroid, dominantFrequency
    ├─→ SoundAnalysisDetector   → snoreConfidence, speechConfidence
    └─→ write to file(s)        → full-session .caf (optional debug) + per-event .caf
```

**Settings:**
- Category: `.playAndRecord`, mode: `.measurement`
- Options: `[.defaultToSpeaker, .allowBluetooth, .mixWithOthers]`
- Buffer: **1024 samples** per tap callback
- Rate: ~20 callbacks/second at 44.1 kHz

The tap writes to **two optional files simultaneously**:
- `audioFile` — full session `.caf` (only when `preserveRawAudio == true`, debug mode)
- `currentEventFile` — per-event `.caf` (started when snoring begins, finalized when it ends)

### 2.2 Three-Layer Cascading Classifier (`SnoreDetector`)

`classify(db:spectralScore:snoreConfidence:)` never uses raw dB alone — that would create massive false positives from breathing, bed creaks, and traffic.

**Priority order:**

```
if snoreConfidence > 0     → classifyWithSoundAnalysis(db, snoreConfidence)
else if spectralScore > 0  → classifyWithSpectral(db, spectralScore)
else                       → .none
```

#### Layer 1: SoundAnalysis (Apple ML)

Uses `SNClassifySoundRequest(classifierIdentifier: .version1)` — Apple's 300-class pre-trained model shipped with iOS.

**Snore identifiers:** `["snore", "snoring"]`  
**Speech identifiers:** 23 classes including `speech`, `talking`, `whisper`, `groan`, `moan`, `laugh`, `giggle`, `whimper`  
**Baby identifiers:** `["baby_crying", "baby_laughter", "babble"]` (mapped to speech)

**Classification logic:**

| Step | Condition | Result |
|------|-----------|--------|
| 1 | `snoreConfidence < confidenceGate` | `.none` |
| 2 | `db >= epicThreshold` && `snoreConfidence >= highConfidenceGate` | `.epic` |
| 3 | `db >= loudThreshold` | `.loud` |
| 4 | `db >= lightThreshold` | `.light` |
| 5 | `db >= quietThreshold` | `.quiet` |
| 6 | `snoreConfidence >= quietFallbackGate` | `.quiet` |
| 7 | Otherwise | `.none` |

**Why only epic uses `highConfidenceGate`:** ML confidence already gated entry in step 1, so the audio is confirmed snore-like. Within that, intensity should be driven primarily by amplitude (dB). Requiring the same high confidence for `loud` was collapsing the intensity distribution — loud snores with moderate confidence (0.35–0.54) were falling through to the oversized light bucket.

#### Layer 2: FFT Spectral Fallback

> **Currently off in live detection (F21-T9).** `FFTAnalyzer` returned all-zero features from 2026-05-08 until F21-T9 (its DFT setup got `log2n` instead of the length), so this layer never ran in production. The analyzer is fixed, but `RealtimeDetectionTracker` passes `spectralScore: 0` to `classify` until a real night validates the fallback. Raw logs and event `averageSpectralScore` record the real score.

When SoundAnalysis is unavailable (e.g., on older devices or if the snoring class is missing from the model), the FFT path kicks in.

**Hard rejects:**
- `spectralScore < 0.6` — breathing and non-snore sounds easily score 0.4–0.7
- `db < quietThreshold - 5` — quiet ambient sounds should not trigger

**Dynamic thresholds:** As `spectralScore` drops from 1.0 → 0.6, the dB thresholds are raised:

```swift
adjustedQuiet = quietThreshold + (1.0 - spectralScore) * 10
adjustedLight = lightThreshold + (1.0 - spectralScore) * 8
adjustedLoud  = loudThreshold  + (1.0 - spectralScore) * 5
adjustedEpic  = epicThreshold  + (1.0 - spectralScore) * 3
```

A spectral score of 0.6 requires dB near the base thresholds. A score of 1.0 allows dB well below them.

#### Layer 3: Pure dB (never used in production)

`classifyWithThresholds(db:)` exists for diagnostics and fallback but is **not called** by the main `classify()` method. Raw dB has no frequency discrimination and cannot distinguish snoring from coughing, traffic, or bed movement.

### 2.3 Spectral Score Formula (`FFTAnalyzer`)

The FFT runs via `vDSP_DFT_Execute` on 1024-sample buffers.

**Extracted features:**
- `lowFreqRatio`: Energy in **100–500 Hz** ÷ total energy. Snoring lives here.
- `spectralCentroid`: Weighted average frequency. Ideal snore: < 400 Hz.
- `dominantFrequency`: Highest-magnitude bin frequency.

**Combined score:**

```swift
let ratioScore    = min(1.0, max(0, (lowFreqRatio - 0.3) / 0.4))
let centroidScore = min(1.0, max(0, (800 - spectralCentroid) / 600))
let spectralScore = ratioScore * 0.7 + centroidScore * 0.3
```

Ideal snore signature: `lowFreqRatio > 0.6`, `spectralCentroid < 400 Hz` → `spectralScore ≈ 1.0`.

---

## 3. Event Lifecycle & State Machine

### 3.1 Where the rules live (F22-T8, T10)

The rules below are `DetectionStateMachine` (`Packages/AudioEngine/Sources/Engine/DetectionStateMachine.swift`), a pure value type: classified samples and melody start/stop go in, `DetectionOutput`s (event started, finalized, discarded, melody requested, recording gap, …) come out. It has no clock, no audio and no SwiftData.

At runtime it runs on the `DetectionEngine` actor, fed by one ordered `AsyncStream` of timestamped messages. `RealtimeDetectionTracker` (Env, main actor) takes a sample every 50 ms, classifies it, sends it into the stream, and performs each batch of outputs (event files, SwiftData, the melody). See ADR 0003 (`docs/adr/0003-detection-actor.md`). Its behavior is pinned by `DetectionStateMachineTests`, the replay goldens in `Packages/AudioEngine/Tests/Fixtures/Replay/` and `DetectionCharacterizationTests` (Env).

### 3.2 Core Constants

```swift
eventGapThreshold: TimeInterval = 10.0         // silence needed to close an event
sustainedRunDuration: TimeInterval = 0.075     // a run must last this long, first sample to latest
                                               // (3 samples at 20 Hz): starts an event, stops the
                                               // melody on silence, starts a speech event
melodyMinPlayDuration: TimeInterval = 4.0      // minimum melody play time
postMelodyBreathingDelay: TimeInterval = 3.0   // verify snoring resumed after melody
```

Thresholds are durations, not sample counts (F22-T10), so they keep their meaning if the sampling rate changes. Before T10 they were `requiredConsecutiveSamples = 3` and `requiredNonSnoreSamplesToStop = 3`.

### 3.3 From Detection to Event

**Step 1 — Sustained detection**  
A snore run must last `sustainedRunDuration` (75 ms from its first sample to the latest, i.e. 3 samples at 20 Hz) before an event can start. This filters out brief transients (taps, notifications, bed creaks).

**Step 2 — Event start (backdated)**  
When sustained detection is confirmed, the event starts at the run's first sample, so the first snore's leading edge isn't lost. (Before F22-T10 it was a fixed 0.10 s backdate.)

**Step 3 — Per-event audio file**  
`audioRecorder.startEventFile(eventID:url:)` creates a new `.caf` file for writing. The tap callback writes to this file in real time alongside the optional full-session file.

**Step 4 — Burst tracking**  
Within an event, continuous snoring segments are tracked as **bursts**:
- `activeBurstStart = now` when snoring resumes
- `completedBursts.append((start, end))` when silence begins

This preserves the internal structure of the epoch — you can see which parts were continuous snoring vs. breathing gaps.

**Step 5 — Event finalization**  
An event is finalized when:
- `now - lastSnoringSampleTime >= 10.0 seconds`, **and**
- the soothing melody is **not** playing

The 10-second gap is the **debounce threshold**. If snoring resumes within 10 seconds, the same event continues. This merges natural breathing pauses into a single snoring epoch.

**Melody interaction:** When the melody starts, the mic pauses. The current burst and audio file are closed, but the **event stays open** — snoring is assumed to continue during the gap. When the melody stops:

1. A `RecordingGap` is logged (`snoringResumed: false` initially).
2. The system waits `postMelodyBreathingDelay` (3 s).
3. **If sustained snoring resumes** within 3 s → `snoringResumed` is marked `true`, `lastSnoringSampleTime` is extended, and the gap counts as snoring time.
4. **If 3 s of silence pass** → the event is finalized with its pre-melody span; the gap does **not** count.

**Melody re-triggering:** The soothing melody plays every time sustained snoring is confirmed, not just once per event. During continuous snoring the melody may fire multiple times within the same open event.

### 3.4 `finalizeActiveEvent()`

```swift
let eventSpan = (lastSnoringSampleTime ?? Date()).timeIntervalSince(startTime)
```

- `eventSpan` = time from first detected snore to last detected snore **within the episode**
- Includes breathing pauses < 10 seconds
- **Excludes** the trailing 10-second silence gap

**Minimum duration filter:**

| Sensitivity | Minimum event duration |
|-------------|----------------------|
| Low | 2.0 s |
| Medium | 1.0 s |
| High | 0.5 s |

Events shorter than this are discarded (file deleted). When melody-triggered, the minimum is always 0.5 s.

**Burst model conversion:**

```swift
let bursts = completedBursts.map { SnoreBurst(
    startOffset: $0.start.timeIntervalSince(startTime),
    endOffset: $0.end.timeIntervalSince(startTime)
) }
```

Burst offsets are **relative to the event start**, not the session start. This makes them portable and independent of session timeline.

---

## 4. Snoring Epochs vs. Net Snore Time

### 4.1 What We Measure

SleepGuard uses **epoch time**, not net snore time.

| Concept | Definition | SleepGuard Equivalent |
|---------|-----------|----------------------|
| **Net snore time** | Sum of only continuous snoring bursts (no gaps at all) | `bursts.reduce(0) { $0 + $1.duration }` |
| **Epoch time** | First snore to last snore, including natural breathing pauses < 10 s | `SnoreEvent.duration` |

`SnoreEvent.snoreDuration` returns:
- **New data:** `duration` (epoch time, includes intra-event breathing gaps and counted melody gaps)
- **Legacy data (pre-May 22):** burst sum (net time) as fallback

**Melody gaps and the epoch model:** When snoring resumes quickly after a melody gap, the gap is treated as a normal breathing pause within the epoch — the event span covers it. Only gaps where snoring did **not** resume within the breathing delay are excluded from the event span.

### 4.2 Why Epochs Are Clinically Correct

Normal breathing pauses between snores are **2–8 seconds**. The airway is still partially compromised during these pauses — the person has not resumed normal breathing. Counting only the bursts (net time) underreports snoring by 20–40% and makes the metric less useful for clinical comparison.

**Validated competitor apps use the same definition:**

> *"The snoring epoch is composed of several snoring signals interrupted by pauses (<10 s). Therefore, the duration of snoring was represented by the sum of total snoring epochs."* — SnoreClock validation study (Chiang et al., 2021)

The 10-second threshold is not arbitrary:
- Pauses **< 10 s** = normal breathing between snores → same epoch
- Pauses **≥ 10 s** = potential apnea/hypopnea event → separate epoch or flagged separately

This matches clinical polygraphy standards.

---

## 5. The 10-Second Threshold (Event Gap)

```swift
private let eventGapThreshold: TimeInterval = 10.0
```

### What it does

An active snore event stays open until **10 seconds of continuous silence** pass. If snoring resumes within 10 seconds, the same event continues with a new burst.

### What this means for the audio file

The per-event audio file is written from event start until `finalizeActiveEvent()` is called. Because finalization happens **10 seconds after the last snoring sample**, the audio file contains:

```
[actual snoring + breathing gaps] + [~10 seconds of trailing silence]
```

The metric `duration` = `lastSnoreTime - eventStart` excludes the trailing silence. The file does not.

**Session 69 fix:** `ClipPlaybackController` and `WaveformGenerator` now cap playback/visualization to `snoreDuration`, so the UI no longer exposes the trailing silence to the user. The file is preserved on disk unchanged.

### History

| Date | Change |
|------|--------|
| Original | `eventGapThreshold = 3.0` s |
| May 19 | Increased to `10.0` s — brief breathing pauses under 10 s now merge into a single `SnoreEvent` |

---

## 6. Audio Recording Architecture

### 6.1 Two Recording Modes

| Mode | Full-session file | Per-event files | Use case |
|------|------------------|-----------------|----------|
| **Production** (default) | ❌ No | ✅ Yes | Normal use. Small files, fast save. |
| **Debug** (`preserveRawAudio`) | ✅ `.caf` | ✅ Yes | Algorithm testing, re-processing, ground-truthing. |

### 6.2 File Lifecycle (Production Mode)

```
Snoring starts
    ├─→ AudioRecorder.startEventFile(eventID, url) → creates event_xxx_session_yyy.caf
    ├─→ Tap callback writes buffers to currentEventFile in real time
    │
    └─→ 10 s silence passes
        ├─→ SessionManager.finalizeActiveEvent()
        ├─→ AudioRecorder.finalizeEventFile() → closes .caf, returns URL
        ├─→ Async Task: AVAssetExportSession compress .caf → .m4a
        ├─→ Async Task: FFTAnalyzer.analyzeSpectralFeatures(of: .m4a)
        ├─→ Populate SnoreEvent.audioFileURL, dominantFrequency, spectralCentroid, lowFreqRatio
        └─→ Delete raw .caf (keep .m4a)
```

### 6.3 File Lifecycle (Debug Mode)

Same as production, but additionally:
- A full-session `session_xxx.caf` is created at `startSession()`
- The tap writes to **both** `audioFile` (session) and `currentEventFile` (event)
- On stop, if per-event clips exist, the full-session file is moved to `rawAudioFileURL` for archival

### 6.4 File Naming & Resolution

```swift
// Per-event raw file (temporary)
event_<eventID>_<sessionID>.caf

// Per-event compressed file (permanent)
event_<eventID>_<sessionID>.m4a

// Full session raw file (debug only)
session_<sessionID>.caf
```

`AudioFileURLResolver` resolves filenames to actual `URL`s in the app's Documents directory. This indirection allows files to be moved or renamed without breaking stored references in SwiftData.

---

## 7. Session 67: Incremental Background Clip Extraction

> **When:** Before direct per-event recording (legacy architecture)  
> **Problem:** Clip extraction was batched at `stopSession()` time, causing a long spinner  
> **Solution:** Extract clips incrementally during the session

### 7.1 Architecture (Session 67)

In the **legacy full-session recording model**, a single large `.caf` file held the entire night. When snoring ended, the event metadata was saved but **no audio clip existed yet**.

Session 67 added an **incremental extraction queue**:

```
Event finalizes
    ├─→ SnoreEvent saved to session.events
    └─→ clipExtractionQueue adds Task:
        ├─→ AudioClipExtractor.extractSingleClip(from: session.caf, event: event)
        ├─→ AVAssetExportSession exports event span to .m4a
        ├─→ FFTAnalyzer runs on extracted clip
        └─→ Populate event.audioFileURL + spectral data
```

The queue was **serialized** (one extraction at a time) to minimize CPU/battery impact while sleeping.

### 7.2 `PendingSessionStore`

Introduced in Session 67 to solve the orphan-file problem:

```swift
@MainActor
public final class PendingSessionStore {
    func setPending(sessionID: UUID, sessionAudioFilename: String?)
    func addFile(_ filename: String)        // track per-event files
    func clearPending()                      // stop tracking (session saved)
    func cleanupIfNeeded()                   // delete all tracked files
}
```

- Persists filenames in `UserDefaults` (not the full session object)
- On app launch: `cleanupIfNeeded()` deletes any orphaned files from force-closed sessions
- On discard: `cleanupIfNeeded()` deletes all pending files
- On save: `clearPending()` removes the record

---

## 8. Session 68: Direct Per-Event Recording

> **When:** Replaced incremental extraction  
> **Problem:** Full-session `.caf` files grew to ~5 GB, could fail to write when disk was low, and made the app a storage hog  
> **Solution:** Write per-event `.caf` directly during the session; compress to `.m4a` on finalize

### 8.1 What Changed

| Before (Session 67) | After (Session 68) |
|--------------------|--------------------|
| One full-session `.caf` (~5 GB) | No full-session file in production |
| Incremental extraction from large `.caf` | Direct per-event `.caf` writing |
| Extraction queue serializes exports | Each event gets its own async `Task` |
| Clip exists only after extraction | Clip exists as `.caf` immediately; compressed later |

### 8.2 How It Works

The tap callback already supported dual-file writing (`audioFile` + `currentEventFile`). Session 68 simply stopped creating `audioFile` in production mode.

```swift
// startSession()
let sessionAudioFilename: String? = UserPreferences.shared.preserveRawAudio
    ? "session_\(session.id.uuidString).caf"
    : nil
```

When snoring starts:
```swift
let fileURL = eventFileURL(eventID: eventID, sessionID: session.id)
try audioRecorder.startEventFile(eventID: eventID, url: fileURL)
```

When snoring ends:
```swift
let rawFileURL = audioRecorder.finalizeEventFile()
if let rawFileURL = rawFileURL {
    let task = Task { @MainActor in
        let m4aURL = rawFileURL.deletingPathExtension().appendingPathExtension("m4a")
        if await compressEventFile(from: rawFileURL, to: m4aURL) {
            let spectral = await AudioClipExtractor.analyzeSpectralFeatures(of: m4aURL)
            event.audioFileURL = AudioFileURLResolver.filename(from: m4aURL)
            event.dominantFrequency = spectral.dominantFrequency
            event.spectralCentroid = spectral.spectralCentroid
            event.lowFreqRatio = spectral.lowFreqRatio
            try? FileManager.default.removeItem(at: rawFileURL)
        }
    }
    pendingEventTasks.append(task)
}
```

### 8.3 Why No Queue?

Events are typically **minutes apart**. Compression of a 5–30 second `.caf` to `.m4a` is fast. Overlap is rare, so a simple `Task` per event is sufficient. `stopSession()` awaits all `pendingEventTasks` with `await task.value` before presenting the summary.

### 8.4 Compression Settings

```swift
let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
exportSession.outputFileType = .m4a
```

Apple's `AppleM4A` preset uses AAC compression. For 5–30 second clips, this completes in well under a second on modern hardware.

---

## 9. Duration Calculation & Sleep Score

### 9.1 Real-Time Duration Accumulation

During the session:

```swift
if state != .none {
    sessionSnoringDuration += timeDelta
}
```

`timeDelta` is capped at `0.5` s to avoid spikes after background/resume. This gives a **live counter** of how much snoring has occurred so far.

### 9.2 Post-Session Duration

```swift
// SleepSession.snoringDuration
public var snoringDuration: TimeInterval {
    let snoringEvents = events?.filter { $0.category == .snoring } ?? []
    let eventDuration = snoringEvents.reduce(0) { $0 + $1.snoreDuration }

    // Only count gaps where snoring actually resumed.
    let countableGaps = (recordingGaps ?? []).filter(\.snoringResumed)
    let countableGapDuration = countableGaps.reduce(0) { $0 + $1.duration }
    guard countableGapDuration > 0 else { return eventDuration }

    // Old sessions (events don't span gaps): add countable gap duration.
    // New sessions (events span gaps): eventDuration already includes them.
    let hasUncoveredGap = countableGaps.contains { /* ... */ }
    return eventDuration + (hasUncoveredGap ? countableGapDuration : 0)
}
```

`SnoreEvent.snoreDuration`:
```swift
public var snoreDuration: TimeInterval {
    duration > 0 ? duration : (bursts?.reduce(0) { $0 + $1.duration } ?? 0)
}
```

- `duration` is the epoch span (first→last snore, including breathing gaps < 10 s and counted melody gaps)
- Burst sum is the fallback for pre-May-22 legacy data
- **Gap counting:** Only `RecordingGap`s with `snoringResumed == true` are included in stats. Legacy gaps default to `true` for backward compatibility.

### 9.3 Monitored Duration

```swift
public var monitoredDuration: TimeInterval {
    max(0, totalDuration - gapsDuration)
}
```

Recording gaps occur when the soothing melody plays (mic is paused). Snoring during gaps is inferred but not directly measured. Monitored duration excludes gaps.

### 9.4 Sleep Score Formula

```swift
score = max(0, 100
    - snoringPenalty
    - eventsPenalty
    - intensityPenalty
    - sleepTalkingPenalty
    - stagePenalty)
```

| Penalty | Calculation | Cap |
|---------|------------|-----|
| **Snoring** | `min(Int(snoringPercentage * 0.7), 70)` | 70 |
| **Events/hour** | `min(Int(Double(eventCount) / (sessionDuration/3600) * 2), 20)` | 20 |
| **Intensity** | `min(Int(lightRatio*10 + loudRatio*20 + epicRatio*30), 30)` | 30 |
| **Sleep Talking** | `min(Int(talkingPct*0.35 + talkingEventsPerHr*0.8), 15)` | 15 |
| **Sleep Stage** | `min(Int(deepDeficit*0.6 + remDeficit*0.4 + awakeExcess*1.0), 15)` | 15 |

**Intensity ratios** use detected burst duration as the denominator (not total session time). This conservatively reduces the intensity penalty because spectral data is missing during recording gaps and melody pauses.

```swift
for event in snoringEvents {
    let detectedDuration = event.bursts?.reduce(0) { $0 + $1.duration } ?? event.snoreDuration
    detectedSnoringDuration += detectedDuration
    // ... intensity buckets ...
}
let lightRatio = detectedSnoringDuration > 0 ? lightDuration / detectedSnoringDuration : 0
```

**Gap-only inference:** If `eventCount == 0` but `countableGapDuration > 0`, snoring is inferred from countable gaps alone:
```swift
let inferredSnoringPercentage = (countableGapDuration / totalDuration) * 100
let snoringPenalty = min(Int(inferredSnoringPercentage * 0.7), 70)
```

### 9.5 Session 69 Fix: Player/Waveform Alignment

Before Session 69, `ClipPlaybackController` overwrote `clipDurations` with the actual audio file length. Since audio files include the 10-second trailing silence, the player showed ~11s for a 1s snore event.

After Session 69:
- `ClipPlaybackController` uses `currentClipDuration = min(clipDurations[index], currentFileDuration)`
- Playback scheduling, seeking, progress ticks, and pause clamping all respect this bound
- `WaveformGenerator.generateSamples(from:maxDuration:)` limits waveform samples to `snoreDuration`

Result: EventCard, PlayerSheetView, and waveform all show the same duration.

---

## 10. Sensitivity Settings

### 10.1 Threshold Tables

| Sensitivity | quiet | light | loud | epic | confGate | highConf | quietFallback | minEventDur |
|-------------|-------|-------|------|------|----------|----------|---------------|-------------|
| **Low** (noisy rooms) | -45 | -35 | -15 | -5 | 0.45 | 0.65 | 0.55 | 2.0 s |
| **Medium** (default) | -50 | -40 | -20 | -10 | 0.35 | 0.55 | 0.45 | 1.0 s |
| **High** (quiet rooms) | -55 | -45 | -25 | -15 | 0.25 | 0.45 | 0.35 | 0.5 s |

### 10.2 What Each Sensitivity Changes

- **dB thresholds:** Lower (more negative) = catches quieter sounds but more false positives
- **Confidence gates:** Higher = requires stronger ML confirmation
- **Minimum event duration:** Shorter = catches isolated single snores; longer = filters out transients

Low sensitivity is for **noisy bedrooms** (street noise, partners, pets). High sensitivity is for **very quiet rooms** where even quiet snoring is audible above the noise floor.

---

## 11. Sleep Talking Detection

Runs in parallel via `SpeechDetector` and `SoundAnalysisDetector`.

**SpeechDetector thresholds:**
- `confidenceThreshold = 0.5`
- `dbFloor = -55.0`

**Priority rule:** When both snoring and speech are detected, **snoring takes priority**. `SessionManager` finalizes any active speech event immediately when snoring begins.

Sleep talking events do **not** create per-event audio files (metadata-only). This is a known gap — see Open Questions.

---

## 12. Session Raw Log (`SessionRawLogWriter`)

Actor-isolated buffer that records every sample at ~20 Hz for future re-processing:

```swift
struct SnoreSample: Codable {
    let elapsed: TimeInterval     // from session.startDate, measured by the tracker (F22-T1)
    let db: Float
    let peakDB: Float?            // F22-T1
    let spectralScore: Float
    let snoreConfidence: Float
    let speechConfidence: Float?  // F22-T1
    let state: DetectionState
}
```

On `stopSession()`, writes to `rawlog_<sessionID>.json` in Documents. Since F22-T1 the file is a `RawLog { metadata, samples }` object (format 2, with sensitivity, sleep-talking and interrupter settings); `RawLog.decode(from:)` still reads format 1, a bare sample array. Only written when `preserveRawAudio` is on.

`scripts/make-replay-fixture.py` cuts an excerpt of a raw log into a CSV fixture for the replay tests (F22-T9).

**Use case:** If you want to change thresholds or debounce values later, you can re-run the classifier on the raw log without re-recording audio. This is invaluable for algorithm tuning.

---

## 13. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AudioRecorder Tap                             │
│                    (1024 samples @ ~20 Hz)                           │
└─────────────────────────────────────────────────────────────────────┘
    │
    ├──→ calculateDB() ──────────────────────────────────────────┐
    │                                                              │
    ├──→ FFTAnalyzer.analyze() ──→ spectralScore                 │
    │                              lowFreqRatio                    │
    │                              spectralCentroid                │
    │                              dominantFrequency               │
    │                                                              │
    ├──→ SoundAnalysisDetector ──→ snoreConfidence                 │
    │                              speechConfidence                │
    │                                                              │
    └──→ Write buffer to file(s)                                   │
         ├─→ full-session .caf (optional debug)                    │
         └─→ currentEventFile .caf (if event active)               │
                                                                   │
    ┌──────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│     RealtimeDetectionTracker (main actor, every 50 ms)               │
│                                                                      │
│  SnoreDetector.classify(db, spectralScore, snoreConfidence)          │
│    → DetectionState (.none / .quiet / .light / .loud / .epic)        │
│    → .sample(input, at:) into the AsyncStream                        │
│                                                                      │
│  DetectionEngine actor → DetectionStateMachine (ADR 0003):           │
│    ├─→ run sustained ≥ 75 ms ? Start/extend event                    │
│    ├─→ activeBurstStart / completedBursts                            │
│    ├─→ 10 s silence ? finalizeActiveEvent()                          │
│    ├─→ Trigger soothing melody                                       │
│    └─→ Accumulate sessionSnoringDuration                             │
│                                                                      │
│  Parallel: SpeechDetector.update() → sleep talking events            │
│                                                                      │
│  Side effects:                                                       │
│    ├─→ startEventFile() / finalizeEventFile()                        │
│    ├─→ PendingSessionStore.addFile()                                 │
│    ├─→ SessionRawLogWriter.append()                                  │
│    └─→ pendingEventTasks (compression + FFT)                         │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    stopSession()                                     │
│                                                                      │
│  1. Await pendingEventTasks (compression/FFT)                        │
│  2. Finalize any in-flight events                                    │
│  3. Compute sleepScore from events + gaps + stage data               │
│  4. Save to SwiftData                                                │
│  5. PendingSessionStore.clearPending()                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 14. Future-Proof Design Decisions

### 14.1 Why `duration` and `bursts` Are Stored Separately

`SnoreEvent` stores:
- `duration: TimeInterval` — the epoch span
- `bursts: [SnoreBurst]?` — the continuous segments

This separation allows the **calculation algorithm to change** without a data migration:
- Today: `snoreDuration = duration` (epoch time)
- Tomorrow: `snoreDuration = bursts.reduce(0) { $0 + $1.duration }` (net time)
- Future: `snoreDuration = duration + trailingGap` (include debounce)

The raw data (`duration`, `bursts`, audio file) never changes. Only the computed property changes.

### 14.2 Why Audio Files Are Not Trimmed

Session 69 intentionally does **not** trim the trailing 10-second silence from audio files. The playback and visualization layers cap themselves to `snoreDuration`. If a future algorithm decides the gap should be included, no files need re-processing — just change `snoreDuration`.

### 14.3 Why Raw Logs Exist

The `SessionRawLogWriter` records every classification decision at 20 Hz. This means:
- Thresholds can be changed retroactively
- New features (e.g., snore index, apnea detection) can be computed from old sessions
- Ground-truthing against competitor apps or clinical devices is possible

---

## 15. Session 71: Post-Melody Verification Model

> **When:** After fixing stale-data crashes during mic pause and melody single-play  
> **Problem:** Melody gaps were blindly added to snoring duration, over-reporting when snoring had actually stopped  
> **Solution:** Verify snoring resumption with a 3-second breathing delay; only confirmed gaps count

### 15.1 What Changed

| Before | After |
|--------|-------|
| Gaps always counted as snoring | Gaps counted only if snoring resumes within 3 s |
| Melody played once per event | Melody re-triggers every time sustained snoring is confirmed |
| `recordingGaps` had no metadata | `RecordingGap` now has `snoringResumed: Bool` |
| Events finalized only by 10-s silence | Events can finalize early after melody if breathing delay expires |
| `lastSnoringSampleTime` frozen during pause | Extended only after sustained post-melody snoring is confirmed |

### 15.2 Why 3 Seconds?

The breathing delay must be:
- **Long enough** to catch natural breathing pauses after a melody (1–2 s)
- **Short enough** to not merge genuinely separate snoring episodes
- **Shorter than** the 10-second event gap to avoid interfering with normal debounce

3 seconds sits comfortably between these bounds. It filters out brief post-melody silence without being aggressive.

### 15.3 Legacy Compatibility

- `RecordingGap.snoringResumed` defaults to `true` for old persisted data (custom `init(from:)` handles missing keys)
- Old sessions where events don't span gaps still get `countableGapDuration` added
- New sessions where events span gaps use the event duration directly; gaps are only excluded when `snoringResumed == false`

---

## 16. Open Questions

1. **Should speech events get per-event audio clips?** Currently metadata-only.
2. **Should the 10-second debounce be user-configurable?** Some users may want stricter splitting (3 s) or looser merging (15 s).
3. **Should we detect apnea explicitly?** The 10-second gap is already the clinical boundary. We could flag epochs where the inter-burst gap approaches 10 s.
4. **Should `beginBackgroundTask` wrap compression tasks?** If the app goes to background mid-compression, the task may be killed.
5. **Net vs. epoch reporting:** Should the user be able to toggle between "total snoring time" (epoch) and "continuous snoring time" (net)?
6. **Should `postMelodyBreathingDelay` be user-configurable?** Currently hard-coded at 3 s.

---

## 17. Glossary

| Term | Definition |
|------|-----------|
| **Burst** | A continuous segment of snoring within an event. Separated from other bursts by brief silence (< 10 s). |
| **Debounce gap** | The 10-second silence threshold required to close a snore event. |
| **dBFS** | Decibels relative to digital full scale. Not calibrated to dB-SPL. |
| **Epoch** | A snoring episode from first snore to last snore, including natural breathing pauses < 10 s. |
| **Net snore time** | Sum of burst durations only, excluding all gaps. |
| **Spectral centroid** | Weighted average frequency of the audio spectrum. |
| **Low-frequency ratio** | Energy in 100–500 Hz ÷ total energy. Snoring is concentrated here. |
| **Melody gap** | Time when the soothing melody plays and the mic is paused. Only counts as snoring if sustained snoring resumes within 3 s. |
