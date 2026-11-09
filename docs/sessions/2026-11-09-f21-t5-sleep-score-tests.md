### Completed
- F21-T5: `SleepScoreTests`, 22 tests covering `SleepSession.sleepScore(using:)` and the cached `sleepScore` path. The suite is now 66 tests, all passing.

### Technical Details
- Every test uses `TestStore` (in-memory SwiftData) with an 8 h night starting 2026-11-01 23:00 UTC, unless noted. Events at `.quiet` intensity isolate the non-intensity penalties.
- Covered:
  - **Baseline:** unfinished session → 100, clean night → 100, `maxScore: 50` → 50
  - **Duration:** 4 h → 96; 2 h → 100 (under the 3 h minimum); 11 h → 98; 15 h → 95 (cap)
  - **Snoring + intensity:** 10 % light → 82; epic → 62 (intensity cap 30); full-night epic → 0 (clamp); bursts (60 s of a 600 s light span + 60 s epic) → 74, where the event span would give a different result
  - **Events per hour:** 20 separate 10 s episodes → 94; 2 s episodes are hidden → 100; events 2 min apart merge → 100
  - **Gaps:** resumed + uncovered → 92; not resumed → 100; covered by an event → 92 (not double counted)
  - **Sleep talking:** 40 × 60 s → 94
  - **Stages:** light only → 85 (cap 15); healthy split → 100
  - **Cache:** cached 42 is returned by `sleepScore`, recompute gives 82; uncached `sleepScore` = default-config recompute
- **Finding**: the first cache test failed (90 ≠ 82). `sleepScore(using:)` reads `snoringDuration`, which returns `cachedSnoringDuration` (0 in the fixture) once `hasCachedScore` is true. The test now writes both cached values like production does; the scoring code is unchanged.
- **Tooling**: after a failing test, `xcodebuild test` stalled for 10+ minutes before exiting. The run was killed and rerun after the fix.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Tests/ModelsTests/SleepScoreTests.swift` | +218 (new) | 22 sleep score tests |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T5 Done |

### Architecture Decisions
- **Arithmetic in comments, exact expected scores**: no ranges or "less than" assertions. Any formula or config change fails a specific, explained test.
- **No source change for the cache finding**: it's a behavior decision, raised as an open question.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 66/66 pass. SwiftFormat lint clean.

### Changes done
```
- Add SleepScoreTests (22): penalties, caps, clamp, bursts, gaps, episode merge, cache
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T6: session and episode calculations (`snoringEpisodes`, `displayableSnoringEpisodes`, `episodePlaybackEvents`, `SnoringEpisode` dB/segments, `stageStats`, per-hour rates).

### Open Questions
- Should `sleepScore(using:)` compute an uncached snoring duration, to match its doc comment?
- Should I look into the xcodebuild stall after failed tests (it affects CI time)?
