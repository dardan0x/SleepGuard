---
date: 2026-11-10
feature: F22
branch: feature/f22/t1-rawlog-replay-fields
title: F22 planned; T1 raw log records every tracker input
---

### Completed
- F22 planned: the mock staff-engineer interview, with each claim checked against the code. Several were outdated: CI already runs tests, there are about 179 tests, `.measurement` mode is in use, there are no concurrency escape hatches, and there are no analytics events. 14 tasks are in `docs/trackers/f22-architecture-hardening.md`. User decisions: protocols on every service, a `Routing` package, detection on an actor fed by an `AsyncStream`, no `Detection` package, `VersionedSchema` included, local trackers only.
- F22-T1: the raw classification log now records every input `RealtimeDetectionTracker.processAudioLevel` receives, timestamped at the tracker, plus the detection settings in effect. It is the input format for the T9 replay tests.

### Technical Details
- `SnoreSample` gains `peakDB: Float?` and `speechConfidence: Float?`. Both are optional, so format-1 samples decode them as `nil`.
- New `RawLog { metadata: RawLogMetadata?, samples }`: format 2 of `rawlog_<id>.json`. `RawLog.decode(from:)` reads format 2, and falls back to format 1 (a bare `[SnoreSample]`) with `metadata == nil`.
- `RawLogMetadata` holds `formatVersion` (2), `sessionStart`, `detectionSensitivity`, `detectSleepTalking` and `snoreInterrupterMode` as raw strings. AudioEngine can't see `UserPreferences`' enums.
- **Timestamp bug fixed:** `elapsed` used to be `Date()` taken inside the writer actor, so it measured when the unstructured `Task` reached the actor, not when the tracker saw the sample. It was also relative to the actor's own start time, not the session's. Now the tracker passes `at: now`, `elapsed` is measured from `session.startDate`, and `stop()` sorts samples by `elapsed`, because appends arriving through tasks aren't guaranteed to be in order.
- The metadata goes inside the log file, not in a separate `.meta.json` file. A separate file would have needed cleanup at the 4 sites that delete `rawLogFileURL`.
- `SessionRawLogWriter.init(directory:)` is internal (it was `private init()`), so tests write to a temp folder. `.shared` is unchanged.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/SnoreSample.swift` | +~60 | `peakDB`, `speechConfidence`; `RawLog` + `RawLogMetadata` |
| `Packages/Env/Sources/Services/SessionRawLogWriter.swift` | ~rewrite of start/append/stop | Caller timestamps, metadata, sorted `RawLog` output, internal `init(directory:)` |
| `Packages/Env/Sources/Services/Session/SessionRecordingController.swift` | +8/−1 | Builds `RawLogMetadata` from preferences when starting the log |
| `Packages/Env/Sources/Services/Session/RealtimeDetectionTracker.swift` | +3 | Passes `now`, `peakDB`, `speechConfidence` to the writer |
| `Packages/AudioEngine/Tests/RawLogTests.swift` | new | Format-2 round trip, format-1 decode, garbage throws |
| `Packages/Env/Tests/SessionRawLogWriterTests.swift` | new | Sorted output with caller timestamps + metadata; empty stop; append before start |
| `docs/trackers/f22-architecture-hardening.md` | new | F22 plan, decisions, outdated interview claims, 14 tasks |
| `docs/FeatureTracker.md` | — | F22 row, dashboard counts, activity log, currently active |

### Architecture Decisions
- **Metadata inside the log, not a sidecar file:** one file per night, and none of the cleanup code changes.
- **Optional new fields over a version bump on the samples:** old logs stay readable, so the nights already recorded can still be inspected.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5, 0 warnings, 0 errors). `run-tests.sh AudioEngine Env`: 37/37 + 23/23 pass. SwiftFormat lint is clean and the layering check passes.

### Suggested Branch
`feature/f22/t1-rawlog-replay-fields` (from `feature/f22-architecture-hardening`)

### Suggested Commit
```
F22-T1 — Raw log records every tracker input

- SnoreSample: add peakDB, speechConfidence (optional; old logs decode)
- RawLog/RawLogMetadata: format 2 with detection settings; format-1 fallback
- SessionRawLogWriter: tracker timestamps, session-relative elapsed, sorted output
- Tests: RawLogTests, SessionRawLogWriterTests
- F22 tracker + FeatureTracker; session fragment
```

### Next Session
- F22-T2: `SleepInputs` value type + pure score function.
- User: record at least one night with "preserve raw audio" on (and ideally the snore interrupter set to never), to get the format-2 fixtures T9 needs.

### Open Questions
- A format-2 log is roughly 40% bigger, about 65–70 MB a night instead of about 48 MB. It's still only written with the debug flag on. Is that OK, or should samples be thinned out?
