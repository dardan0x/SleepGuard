### Completed
- F21-T6: 25 tests for session and episode calculations in Models (`SnoringEpisodeTests` 16, `SessionStatsTests` 9). The suite is now 93 tests, all passing.

### Technical Details
- **Grouping** (`snoringEpisodes`):
  - end-to-start gap of 300 s merges; 301 s splits
  - input is sorted by time first
  - an event inside a longer one keeps the longer end (`max`)
  - the episode's intensity is the highest rank; its id is the first event's id
  - sleep talking never joins a snoring episode
- **Display and counts**:
  - 2.9 s episodes are hidden; 3 s episodes are shown
  - `eventsCount` = displayable episodes + non-snoring events (2 → 0.25/h over 8 h)
  - `eventsPerHour` is 0 when there's no end date
- **Playback**: the representative (longest) event plays the whole episode in time order. Other events in the episode, and sleep-talking events, play alone.
- **Aggregates**:
  - `detectedDuration` uses bursts when present (20 + 30 + 40 = 90 vs. span 640)
  - `detectedSegments` follows bursts sorted by start, or whole events when there are no bursts
  - `peakDB` is the max; `averageDB` is duration-weighted (−25)
  - `SnoreEvent.snoreDuration` falls back to the burst sum when `duration` is 0
- **Session stats**:
  - unfinished session: all durations, percentages and rates are 0
  - `gapsDuration`; `monitoredDuration` is floored at 0
  - snoring % = 10
  - cached snoring duration wins when cached
  - sleep-talking count, duration, % and per-hour, plus `duration(for:)`
  - `stageStats` is nil for no segments, an empty array or a zero total; otherwise percentages (40/40/10/10)
  - Debug `minimumSaveDuration` = 120

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Tests/ModelsTests/SnoringEpisodeTests.swift` | +189 (new) | Episode grouping, filter, playback, aggregates |
| `Packages/Models/Tests/ModelsTests/SessionStatsTests.swift` | +120 (new) | Session durations and stats |
| `docs/trackers/f21-test-coverage.md`, `docs/FeatureTracker.md` | — | T6 Done |

### Architecture Decisions
- **Two suites instead of one file**: episodes and session stats change for different reasons. This also keeps each file under ~200 lines.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5). `run-tests.sh`: 93/93 pass. SwiftFormat lint clean.

### Changes done
```
- Add SnoringEpisodeTests (16): merge boundary, ordering, overlap, display filter, counts, playback, aggregates
- Add SessionStatsTests (9): durations, gaps, percentages, sleep talking, stage stats, cache, save threshold
- Update F21 tracker + FeatureTracker; add session fragment
```

### Next Session
- F21-T7: `SessionRecoverySnapshot`, `WidgetDeepLink` round-trips (partly covered in F20), `DateFormatters`, `AudioFileURLResolver`.

### Open Questions
- `detectedSegments` drops events without bursts when any event in the episode has bursts. It's unreachable today; should it fall back per event anyway?
