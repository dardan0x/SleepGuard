### Completed
- F22-T3: the cached sleep score now records which formula and config produced it. One function writes it, and stale scores are recomputed at launch, so trend charts never mix two formulas.

### Technical Details
- `SleepScore.formulaVersion = 1`, and `SleepScore.cacheVersion(for:)` = `"<formulaVersion>-<hex FNV-1a of sorted-key JSON of the config>"`. It's stable across launches (unlike `hashValue`), and any coefficient change produces a new version.
- `SleepSession.cachedScoreVersion: String = ""` is an additive SwiftData property with a default, so no migration is needed. Sessions cached before this change have `""`, so they are stale.
- `SleepSession.refreshCachedScore(using:)`: sets `hasCachedScore = false` (so `snoringDuration` recomputes from events), builds `sleepInputs` once, then writes snoring duration, score and version, and sets `hasCachedScore = true`. The caller saves.
- `SleepSession.refreshStaleCachedScores(in:config:)`: `#Predicate { endDate != nil && (!hasCachedScore || cachedScoreVersion != version) }`, refreshes those sessions, saves only if any changed, and returns the count.
- `SleepGuardApp.onAppear` runs the pass on `mainContext` before `WidgetSnapshotWriter.update`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepScoreCache.swift` | new | Cache version, owner, stale pass |
| `Packages/Models/Sources/Data/SleepSession.swift` | +4 | `cachedScoreVersion` property + doc |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | −3/+1 | Uses the owner |
| `SleepGuard/StatisticsTab.swift` | −3/+1 | Uses the owner (force-saved auto-save) |
| `Packages/Recordings/Sources/Helpers/SessionDetailModel.swift` | −4/+1 | Uses the owner |
| `Packages/Env/Sources/Services/MockDataGenerator.swift` | −4/+1 | Uses the owner after insertion |
| `SleepGuard/SleepGuardApp.swift` | +8 | Launch stale pass before the widget snapshot |
| `Packages/Models/Tests/ModelsTests/SleepScoreCacheTests.swift` | new | 6 tests |
| `docs/trackers/f22-architecture-hardening.md` | — | Now committed (it was left out of T1 and T2); T3 Done |
| `docs/FeatureTracker.md` | — | T3 Done |

### Architecture Decisions
- **Fingerprint over a hand-bumped number:** forgetting to bump a number is exactly the bug the interview described. A fingerprint only misses changes to the formula's code, and `formulaVersion` covers those.
- **The owner lives in Models, not in a view or service:** the cache is domain data. Views call one function and no longer know which three fields belong together.
- **Pass on the main context at launch:** the simplest correct option, and it runs before the widget writer. It costs one full recompute after a formula change. A background context is the fix if launch time ever suffers.

### Build Status
- **BUILD SUCCEEDED** (app scheme, BD630AD5, 0 warnings, 0 errors). `run-tests.sh Models Recordings`: 77/77 + 14/14 pass. SwiftFormat lint is clean and the layering check passes.
- **Launch check:** installed over the simulator's existing store. The new column migrated without the "ModelContainer creation failed" fallback, the stale pass logged no error, and the dashboard renders scores (82 for Nov 7).

- SleepScore.cacheVersion: formula version + stable config fingerprint
- SleepSession.cachedScoreVersion (additive, default "")
- refreshCachedScore(using:) is the only writer; 4 call sites migrated
- Launch pass refreshStaleCachedScores before the widget snapshot
- SleepScoreCacheTests (6)
- F22 tracker (first commit of it) + FeatureTracker; session fragment
```

### Next Session
- F22-T4: the `Routing` package + ADR 0001.

### Open Questions
- None new.
