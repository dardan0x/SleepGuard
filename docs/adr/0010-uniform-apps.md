# ADR 0010: Everything that isn't SleepGuard's own lives in SleepGuardShared

- **Status:** Accepted
- **Date:** 2026-11-26
- **Tasks:** F27-T22 (shared 0.34.0), F27-T23 (0.35.0), F27-T24 (0.36.0), F27-T25

## Context

SleepGuard and SleepGuardUIKitWay record the same night. After ADR 0004–0006 they already shared the night rules, the score, detection, strings, design and screen content. Each app still had its own copy of the rest:
- logging
- applying the classifiers to a live sample
- sample nights
- the profile, survey and checkpoint files and where they live
- storage cleanup and the start notification
- the whole AVFoundation audio stack
- two SwiftData schemas for the same `Night`

A fix in one copy didn't reach the other. A read-only sweep of the audio code found four bugs in SleepGuard's copy that SleepGuardUIKitWay's didn't have:
- a melody stop could start a second engine;
- the clip closed for a melody pause was lost;
- an interruption left the old tap installed;
- the frame position wasn't reset on resume.

The owner asked to uniform the apps as far as possible. Nothing is in production, so stored data could change without a migration.

## Decision

Behaviour both apps need moves to SleepGuardShared; each app keeps its own protocols, dependency injection, state and isolation, and wraps the shared code (the rule from F27-T18…T21, extended).

| Release | Shared | SleepGuard keeps |
|---|---|---|
| 0.34.0 | `SleepLogging` (`Log`, signposter); `LiveSampleClassifier`; `SampleNights`; `RawRecording` names, `NightFiles`, `StorageSweep`; `SleepFiles`' `StorageLocation`, `ClipFolder`, `NightCheckpoint`, `ProfileFile`, `LifestyleLogFile`; `SleepNotifications`' `StartNotification` | `ProfileStore` / `LifestyleLogStore` (observable, behind protocols); `SessionCheckpointStore`'s writer and sequence gate (only the file format is shared); `StorageLimitEnforcer`'s report |
| 0.35.0 | `SleepAudioKit`: `CaptureEngine`, `ClipCompressor`, `ClipPlayerEngine`, `ClipWaveform`, `ClipSpectrum`, `ClipExtractor`, `MelodyPlayback`, `MelodyRecording`, `MelodyFiles`, `SampleClip`; `CaptureSample` / `CaptureEvent` in SleepCore | `AudioRecording` and `AudioRecorder` (published levels, callbacks); `ClipPlaybackController`'s playlist state; the melody helpers' screen state |
| 0.36.0 | `SleepStore`: `NightRecord` / `NightEventRecord` (SleepGuardUIKitWay's shape), mapping to `Night`, `refreshSummary`, `SleepStoreSchema`, `SleepStore.open` | `@Query` on the main context; `NightRecord+SleepGuard` reads; `SessionCommitter`; `refreshStaleSummaries` at launch |

One file layout for both apps: `<app group>/<app folder>/` holds `Nights.store`, `Clips/` (event clips, raw recordings by night id), `Melodies/`, `Profile.json`, `LifestyleLogs.json`, `Recording.json`.

## Consequences

- A fix to capture, playback, files, the schema or the night's numbers is made once and reaches both apps with a release. The four audio bugs are gone in SleepGuard.
- SleepGuard lost code it maintained alone: the `Logging` package, both detectors, the audio engine internals, two `@Model` pairs, its schema and its store opening. The `Logging` package and AudioEngine's tests are gone; their tests run in the shared repo.
- Behaviour changes in SleepGuard:
  - Survey answers keep all ten chips.
  - The melody plays in the recording's session.
  - Storage cleanup also removes files no night names.
  - The stored summary (score, snoring time, event count) is stamped when a night stops, is recovered, or is saved, and at launch when the formula changed.
  - Raw recordings are found by the night's id.
  - A night without sleep stages asks Health each time it opens.
  - Debug builds no longer wipe a store that fails to open.
  - Capture no longer resumes on app activation; it resumes on interruption end, route, configuration and media-reset events.
- Honest limits:
  - The audio kit has been checked by unit tests on the simulator only. A night on a device (and one on the simulator) is still owed.
  - The bug-2 fix (a clip closed for the melody) has no regression test, because the fake recorder returns no clip.
  - A shared change now needs a release and a bump in both apps, and a breaking schema change is a shared migration both apps take.
- SleepGuard's protocols didn't change shape except `AudioRecording` (confidences in, file URLs out) and `SessionCheckpointStoring` (a `Night`).

## Alternatives

- **Share protocols too:** rejected again (ADR 0004). DI, isolation and test doubles differ by app, and a shared protocol would tie SleepGuardUIKitWay's ports to SleepGuard's container.
- **Keep SleepGuard's schema shape:** rejected by the owner. SleepGuardUIKitWay's shape stores enums as raw strings (forward compatible), has no `.unique` (CloudKit-ready) and stores a summary list screens can read without events.
- **Keep SleepGuard's audio code and port the fixes:** rejected. The audio code had the bugs; one copy is the point.
