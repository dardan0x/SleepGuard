### Completed
- F21-T10: `AudioClipExtractor` and `EventClipCompressor` tests against real audio files generated in temp folders (11 new). The suite is now 134 tests, all passing. This finishes the AudioEngine phase (T8–T10).

### Technical Details
- **Fixtures** (in `TestAudio.swift`):
  - `writeTone(to:seconds:hz:)` writes a mono float CAF sine in 4096-frame chunks
  - `duration(of:)` uses `AVURLAsset.load(.duration)`
  - `TempFolder` is a unique temp dir, removed in `deinit`
- **`AudioClipExtractorTests` (8)**, on a 10 s, 215 Hz session file:
  - event at 2 s, 3 s long, 0.5 s padding → 4 s clip named `event_<uuid>.m4a`
  - bursts 0.5–1 / 3–3.5 → 3 s clip (event duration 99 is ignored)
  - padding clamped to 0…10 s
  - event at 12 s → nil
  - clip features: dominant ≈ 215 Hz, low ratio > 0.8, centroid < 400
  - a stale existing clip is replaced
  - `extractClips` with 6 events + 1 out of range → exactly the 6 IDs (2 batches)
  - missing file → zero features
- **`EventClipCompressorTests` (3)**:
  - 5 s CAF → mono AAC (HE or LC), ≥ 16 kHz, 5 s ± 0.15, and > 20× smaller
  - an existing destination is replaced
  - a missing source returns false
- Gotcha: a lone `@MainActor` test in a nonisolated suite broke the `@Test` macro expansion for every test in the suite (`@const` / `@section` errors). Removing it fixed both that and the `[SnoreEvent]` sending error.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Tests/TestAudio.swift` | +38 | `writeTone`, `duration(of:)`, `TempFolder` |
| `Packages/AudioEngine/Tests/AudioClipExtractorTests.swift` | +101 (new) | Clip extraction |
| `Packages/AudioEngine/Tests/EventClipCompressorTests.swift` | +44 (new) | AAC compression |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T10 Done |

### Architecture Decisions
- **Real files, not mocks**: both types are thin wrappers over AVFoundation export/encode. The only meaningful test is that the produced file has the right span and format.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 134/134 pass. SwiftFormat lint clean.

### Changes done
```
- Add TestAudio.writeTone / duration(of:) and TempFolder fixtures
- Add AudioClipExtractorTests (8): spans, bursts, clamping, naming, replace, batching, features
- Add EventClipCompressorTests (3): mono AAC output, replace, missing source
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T11: `RealtimeDetectionTracker` (Env), the live event state machine and the sensitivity presets. It probably needs a small testability change (inject a clock/detector); ask first.

### Open Questions
- None new.
