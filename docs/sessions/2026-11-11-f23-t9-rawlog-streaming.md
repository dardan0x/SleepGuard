---
date: 2026-11-11
feature: F23
branch: feature/f23/t9-rawlog-streaming
title: F23-T9 Stream the raw log to disk while recording
---

### Completed
- F23-T9: the raw classification log is written while recording (format 3, JSON Lines), not buffered all night and encoded at stop.

### Technical Details
- Header line + one sample per line, appended every 200 samples (~10 s). The decoder reads formats 1–3, sorts, and tolerates a partial last line.
- The pending store gets the log's name at start; stop-and-discard now calls `rawLogWriter.discard()`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/SnoreSample.swift` | +40 | Format 3 encode/decode |
| `Packages/Env/Sources/Services/SessionRawLogWriter.swift` | rewritten | Streaming writer |
| `Packages/Env/Sources/Services/Session/SessionRecordingController.swift` | ±8 | Register at start; discard on stop-and-discard |
| `Packages/AudioEngine/Tests/RawLogTests.swift`, `Packages/Env/Tests/SessionRawLogWriterTests.swift` | +80 | 5 new tests |
| `scripts/make-replay-fixture.py` | +20 | Reads format 3 |
| `docs/snore-detection-algorithm.md` | ±1 | Format 3 |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | T9 Done |

### Architecture Decisions
- JSON Lines over a streamed JSON array: each line stands alone, so a crash leaves a readable file, and the reader sorts instead of the writer.

### Build Status
- Lint and layering clean; AudioEngine 65, Env 59 pass; app build 0 warnings.
- Simulator: the log grew 1 → 201 → 401 lines over 24 s; discard deleted it.

### Suggested Branch
`feature/f23/t9-rawlog-streaming`

### Suggested Commit
`F23-T9 — Stream the raw log to disk while recording (format 3, JSON Lines)`

### Changes done
- See Files Changed.

### Next Session
- F23-T10 start-failure alert.

### Open Questions
- None.
