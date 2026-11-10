---
date: 2026-11-10
feature: F22
branch: feature/f22/t2-sleep-inputs
title: F22-T2 pure sleep score on a SleepInputs value type
---

### Completed
- F22-T2: the sleep score formula is now a pure function of a value type. `SleepSession` only gathers the inputs. The formula can be tested with plain values, with no SwiftData container.

### Technical Details
- `SleepInputs` (Sendable, Equatable) holds:
  - `totalDuration`
  - `snoringDuration`: events + gaps where snoring resumed
  - `snoringEpisodeCount`: displayable episodes
  - `quietSnoring` / `lightSnoring` / `loudSnoring` / `epicSnoring`: burst sums
  - `sleepTalkingCount` / `sleepTalkingDuration`
  - `stages: StageStats?`
  - Every field except `totalDuration` has a default of 0 or nil, so a test only lists what it varies.
- `enum SleepScore { static func compute(_:config:) -> Int }` is the old method body split into one private function per penalty: intensity, sleep talking, stages, short sleep, long sleep. The snoring and events penalties stay inline. The arithmetic is unchanged, down to the order of operations, so `Int` truncation gives the same results.
- `SleepSession.sleepInputs` builds the inputs: one pass over the snoring events by intensity, plus the existing computed properties. `sleepScore(using:)` is now `SleepScore.compute(sleepInputs, config:)`.
- `StageStats` gains `Equatable`. This is not a SwiftData schema change, since it's a plain struct.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepScore.swift` | new (~140) | `SleepInputs` + `SleepScore.compute` |
| `Packages/Models/Sources/Data/SleepSession.swift` | −95/+33 | Formula body replaced by `sleepInputs` + delegation; `StageStats: Equatable` |
| `Packages/Models/Tests/ModelsTests/SleepScoreFormulaTests.swift` | new | 14 parameterized cases (nap, 4 h, 11 h, 15 h cap, 20% light, quiet-only, 100% epic clamp, events cap, mixed intensity, sleep talking, low deep, stage cap), bounds check, custom min |
| `docs/trackers/f22-architecture-hardening.md` | — | Now committed (it was left out of T1); T2 Done |
| `docs/FeatureTracker.md` | — | T2 Done |

### Architecture Decisions
- **Intensity as four fields, not a dictionary:** fixed cases, no optional lookups, and test cases read naturally.
- **Inputs built from existing computed properties:** the episode-merging, gap and cache rules stay in one place. T2 changes where the formula lives, not what it reads.
- **`SleepScoreTests` kept unchanged:** they are the end-to-end check that results didn't change.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5, 0 warnings, 0 errors). `run-tests.sh Models`: 71/71 pass, with the 22 `SleepScoreTests` unchanged. SwiftFormat lint is clean and the layering check passes.

### Suggested Branch
`feature/f22/t2-sleep-inputs` (from `feature/f22-architecture-hardening`)

### Suggested Commit
```
F22-T2 — Pure sleep score on SleepInputs

- SleepInputs value type + SleepScore.compute (formula unchanged)
- SleepSession.sleepScore(using:) builds inputs and delegates
- StageStats: Equatable
- SleepScoreFormulaTests: 14 parameterized cases, bounds, custom min
- F22 tracker (first commit of it) + FeatureTracker; session fragment
```

### Next Session
- F22-T3: versioned score cache with a single owner, plus a recompute of stale scores at launch.

### Open Questions
- None new.
