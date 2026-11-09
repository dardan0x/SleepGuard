### Completed
- F21-T7: crash-recovery snapshot, audio file path resolver, and deep-link URL contract tests in Models (10 new). The suite is now 103 tests, all passing. `DateFormatters` was skipped on purpose (see Architecture Decisions). This finishes the Models phase (T5–T7).

### Technical Details
- **`SessionRecoverySnapshotTests` (5)**: builds a detached live session (dB values, 3 file refs, a gap with `snoringResumed: false`, `terminationReason`, a snoring event with every field and a burst, a sleep-talking event). Runs it through snapshot → `JSONEncoder` → `JSONDecoder` → `makeSession()`, then checks:
  - every session and event field is kept
  - `event.session === rebuilt`
  - the score and snoring duration equal the live session's
  - an existing `endDate` wins over the checkpoint date
  - a session with no events is not recoverable
- **`AudioFileURLResolverTests` (4)**:
  - a temp file in Documents resolves from its filename, and from a stale `/var/mobile/Containers/.../OLD-UUID/Documents/<name>` path
  - nil, empty and missing files → nil
  - `filename(from:)` keeps only the filename
- **`WidgetDeepLinkTests` +1**: exact strings `sleepguard://start`, `sleepguard://last7nights`, `sleepguard://session/<uuid>`.
- A first run failed on an invented input: `resolve("/")` returns the Documents folder itself. Nothing stores "/", so the case was removed. The 5-minute `timeout` cap cut the post-failure xcodebuild stall short.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Tests/ModelsTests/SessionRecoverySnapshotTests.swift` | +103 (new) | Recovery round-trip |
| `Packages/Models/Tests/ModelsTests/AudioFileURLResolverTests.swift` | +43 (new) | Path resolution |
| `Packages/Models/Tests/ModelsTests/WidgetSnapshotTests.swift` | +7 | Deep-link URL contract |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T7 Done |

### Architecture Decisions
- **No `DateFormatters` tests**: they're Foundation configuration that depends on the device locale and time zone. Tests would be tautological or flaky.
- **Detached models in the recovery tests**: matches production, where the live session isn't inserted until the user saves.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 103/103 pass. SwiftFormat lint clean.

### Changes done
```
- Add SessionRecoverySnapshotTests (5): full round-trip, event wiring, score parity, end date, recoverability
- Add AudioFileURLResolverTests (4): filename, legacy absolute path, nil/empty/missing, filename(from:)
- Add deep-link URL contract test
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T8: `SnoreDetector` classification tests (AudioEngine). It may need a small testability change (the thresholds live on a shared singleton); ask first.

### Open Questions
- `DateFormatters.time` and `.timeWithPeriod` are identical. Merge them, or keep both?
