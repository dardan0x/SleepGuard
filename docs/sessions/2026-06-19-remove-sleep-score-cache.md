---
date: 2026-06-19
feature: none
branch: feature/remove-sleep-score-cache
title: Remove Sleep Score Cache
---

### Completed
- Removed all reads and writes of `cachedSleepScore`, `cachedSnoringDuration`, and `hasCachedScore`.
- Made `SleepSession.sleepScore` and `snoringDuration` compute on demand using the active remote config.
- Kept the three cached properties in the SwiftData schema (marked `@available(*, deprecated)`) to avoid a migration crash for existing installs.
- Updated `MainTabView` daily briefing to use computed score/duration instead of cached values.
- Updated `AppConfig` to publish the resolved config into `SleepScoreConfig.current` so the model layer can use it without importing `Env`.

### Technical Details
- `SleepScoreConfig.current` is a static config snapshot set by `AppConfig` whenever remote config resolves.
- `SleepSession.sleepScore` now simply calls `sleepScore(using: SleepScoreConfig.current)`.
- `SleepSession.snoringDuration` now computes directly from events and gaps.
- Cache-write call sites were removed from:
  - `SessionSummaryView.saveSession()`
  - `SessionDetailView.loadSession()`
  - `StatisticsTab.autoSaveForceSavedSession()`
  - `MockDataGenerator`
- `MainTabView` no longer filters briefing sessions by `hasCachedScore`; all sessions are now eligible.
- `AGENTS.md` and `CLAUDE.md` updated to describe the deprecated properties and remove the old cache rules.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepScoreConfig.swift` | ~+10 | Added `static var current` for active config snapshot |
| `Packages/Models/Sources/Data/SleepSession.swift` | ~+5/-15 | Deprecated cached properties; removed cache reads |
| `Packages/Env/Sources/Services/AppConfig.swift` | ~+2 | Set `SleepScoreConfig.current` on init and apply |
| `SleepGuard/MainTabView.swift` | ~+4/-5 | Use computed score/duration; remove `hasCachedScore` guard |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | ~-4 | Remove cache writes |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | ~-6 | Remove cache refresh logic |
| `SleepGuard/StatisticsTab.swift` | ~-4 | Remove cache writes |
| `Packages/Env/Sources/Services/MockDataGenerator.swift` | ~-4 | Remove cache writes |
| `AGENTS.md` | ~+8/-10 | Update cached-property guidance |
| `CLAUDE.md` | ~+8/-10 | Update cached-property guidance |
| `docs/sleep-score-calculation.md` | ~+10/-20 | Remove cache behavior; add performance note |

### Architecture Decisions
- **Static `SleepScoreConfig.current`**: allows `SleepSession.sleepScore` to use the active remote config without `Models` importing `Env` or passing config through every view. This is global mutable state, but it is bounded to a single config value and set only by `AppConfig`.
- **Keep deprecated properties in schema**: avoids a SwiftData migration and potential launch crash for existing users. They can be removed in a future model-version migration after the no-cache path is proven stable.
- **Do not add a new in-memory cache**: keeping it simple for Phase 1. If list views stutter, an in-memory memoization layer can be added without changing the schema.

### Build Status
- **BUILD SUCCEEDED** — `SleepGuard` scheme built for iOS Simulator with no new errors. One pre-existing warning in `MainTabView.swift` (`latestSession` unused) remains.

### Suggested Branch
`feature/remove-sleep-score-cache`

### Suggested Commit
`[Sleep Score] — Compute score on demand; deprecate SwiftData cache`

### Changes done
- Deprecated `cachedSleepScore`, `cachedSnoringDuration`, `hasCachedScore`.
- Removed all cache reads/writes.
- Made `sleepScore` and `snoringDuration` compute on demand.
- Wired active remote config into `SleepScoreConfig.current`.
- Updated briefing generation to use computed values.
- Updated agent docs.

### Next Session
- Monitor list/statistics view performance and crash reports after this change.
- If stable, plan Phase 2: SwiftData model migration to drop the deprecated properties.
- If unstable, consider an in-memory memoization layer for list views.

### Open Questions
- Should list views be limited to the last N sessions (e.g., 90 days) to reduce relationship-faulting surface?
