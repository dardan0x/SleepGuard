---
date: 2026-06-19
feature: none
branch: feature/remote-config-sleep-score
title: Remote Config Sleep Score
---

### Completed
- Made the sleep score formula tunable from Firebase Remote Config via a new `sleep_score_config` parameter.
- Tightened default penalties so severe snoring nights score lower and fragmented sleep is punished more heavily.
- Added a sleep duration penalty for very short (< 6 h) and very long (> 9 h) nights.
- Preserved SwiftData model stability — no stored property changes, no migration risk.
- Kept the score computed on demand; remote config only supplies coefficients/caps.
- Updated cache-writing call sites so new sessions and opened sessions reflect the current config.

### Technical Details
- New `SleepScoreConfig` struct in `Models` holds every coefficient, cap, stage threshold, and sleep-duration threshold with stricter defaults.
- `SleepSession.sleepScore` property remains backward-compatible (cached → `.default` fallback).
- Added `SleepSession.sleepScore(using: SleepScoreConfig)` for explicit config-driven recomputation.
- `AppConfig` resolves `sleepScoreConfig` with the same debug-override → remote/cache → default precedence as other remote values.
- `RemoteConfigLoader` fetches `sleep_score_config`, decodes it, and pushes it into `AppConfig`.
- Cache refresh points (`SessionSummaryView.saveSession`, `SessionDetailView.loadSession`, `StatisticsTab.autoSaveForceSavedSession`) now compute with `appConfig.sleepScoreConfig`.
- List/statistics views continue using `session.sleepScore` (cached) to avoid SwiftData relationship faulting across many sessions.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepScoreConfig.swift` | +130 | New tunable config struct with stricter defaults + duration penalties |
| `Packages/Models/Sources/Data/SleepSession.swift` | ~+20/-25 | Refactored `sleepScore` to use `SleepScoreConfig`; added `sleepScore(using:)` and duration penalty |
| `Packages/Env/Sources/Services/AppConfig.swift` | ~+35 | Store/resolve/cache `SleepScoreConfig` + debug override |
| `SleepGuard/RemoteConfig/RemoteConfigLoader.swift` | ~+25 | Fetch/decode `sleep_score_config`; pass to `AppConfig.apply` |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | ~+3 | Use current config for gauge and cache write |
| `Packages/Recordings/Sources/Views/SessionDetailView.swift` | ~+2 | Use current config for header and cache write |
| `SleepGuard/StatisticsTab.swift` | ~+2 | Use current config for force-saved cache write |
| `docs/remote-config-schema.md` | ~+40 | Document `sleep_score_config` parameter |
| `docs/sleep-score-calculation.md` | ~+30 | Add Remote Config section with cache behavior |

### Architecture Decisions
- **Config in `Models`, resolution in `Env`**: keeps the score formula decoupled from Firebase while still letting every feature package read the resolved config through `AppConfig`.
- **Do not migrate cached scores in bulk**: historical scores update only when a session is saved or opened in detail. Bulk recalculation risks the same SwiftData faulting crashes that `cachedSleepScore` exists to prevent.
- **Keep `sleepScore` property as cached/default fallback**: avoids breaking list/statistics views and preserves the defensive cache path.
- **Stricter defaults over cautious defaults**: severe cases (100% snoring, 12+ events/hour, 100% epic intensity) now score very low, matching user expectations and competitor severity scales.
- **Add sleep duration as a quality signal**: short and long nights both reduce score, preventing a 4-hour nap from outranking a healthy 8-hour night.

### Build Status
- **BUILD SUCCEEDED** — `SleepGuard` scheme built for iOS Simulator with no new errors. One pre-existing warning in `MainTabView.swift` (`latestSession` unused) remains.

### Suggested Branch
`feature/remote-config-sleep-score`

### Suggested Commit
`[Remote Config] — Make sleep score formula tunable from remote config`

### Changes done
- Added `SleepScoreConfig` with all formula coefficients, caps, and duration thresholds.
- Refactored `SleepSession` score computation to accept a config and added short/long sleep penalties.
- Tightened default snoring, events, and intensity penalties.
- Wired `sleep_score_config` through Remote Config → `AppConfig` → UI.
- Updated cache-writing sites to use the current remote config.
- Documented the new parameter, defaults, and cache behavior.

### Next Session
- Add the updated `sleep_score_config` JSON to the Firebase console and test live value changes.
- Optionally extend Debug Settings with a sleep-score config override panel (the `AppConfig` API already supports it).
- Consider age-adjusted sleep-stage targets using `UserProfile.birthYear` for older users.

### Open Questions
- Should the PDF report (`SleepReportPDFGenerator`) use the current remote config? It is generated from detail view where events are loaded, so it could be updated for consistency.
