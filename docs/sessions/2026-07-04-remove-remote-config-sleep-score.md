---
date: 2026-07-04
feature: none
branch: fix/remove-remote-config-sleep-score
title: Remove Remote Config from Sleep Score
---

### Completed
- Removed `sleep_score_config` from `RemoteConfigLoader`.
- Simplified `AppConfig.sleepScoreConfig` to resolve from `SleepScoreConfig.default` (DEBUG local override still supported).
- Removed remote/cache persistence for sleep score config.
- Updated documentation: `docs/remote-config-schema.md` and `docs/sleep-score-calculation.md`.

### Technical Details
- `RemoteConfigLoader.apply()` no longer decodes `sleep_score_config` and calls `AppConfig.apply` without that parameter.
- `AppConfig.apply(flags:tabs:learnTab:updateGate:)` signature restored to pre-remote-config-sleep-score form.
- `AppConfig.sleepScoreConfig` now returns `.default` in release builds, preserving the DEBUG-only `setSleepScoreConfigOverride(_:)` hook for local testing.
- All UI call sites (`SessionSummaryView`, `SessionDetailView`, `StatisticsTab`) continue using `appConfig.sleepScoreConfig`; no view changes required.
- Historical `UserDefaults` key `appconfig.sleepScoreConfig` is now orphaned and will not be read or written.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/RemoteConfig/RemoteConfigLoader.swift` | -23 | Removed `sleep_score_config` key, decoding, defaults JSON, and parameter from `apply()` call |
| `Packages/Env/Sources/Services/AppConfig.swift` | -8 / +3 | Removed remote/cache sleep score config; `sleepScoreConfig` now returns `.default` with DEBUG override |
| `docs/remote-config-schema.md` | -48 | Removed `sleep_score_config` parameter table row, section, and day-to-day bullet |
| `docs/sleep-score-calculation.md` | -5 / +5 | Rewrote "Remote Config" section as "Configuration" describing local defaults and DEBUG override |

### Architecture Decisions
- **Keep `AppConfig.sleepScoreConfig` property**: Avoids touching four call sites and keeps the DEBUG override path intact for testing scoring changes locally.
- **Keep `SleepScoreConfig` unchanged**: The struct, its defaults, and the calculation in `SleepSession` remain exactly as in the previous commit; only the source of the config changes.
- **Keep `RemoteConfigLoader` for other keys**: Feature flags, tabs, Learn tab, and update gating still flow through Firebase Remote Config.

### Build Status
- **BUILD SUCCEEDED** — one pre-existing warning (`latestSession` unused in `MainTabView.swift:207`).

### Suggested Branch
`fix/remove-remote-config-sleep-score`

### Suggested Commit
`Remove Remote Config from sleep score calculation`

### Changes done
- Removed `sleep_score_config` key from `RemoteConfigLoader.Key`.
- Removed `decodeSleepScoreConfig(_:)` and `defaultSleepScoreConfigJSON()`.
- Removed `sleepScoreConfig` from `RemoteConfigLoader.apply()` and `AppConfig.apply(...)`.
- Removed `remoteSleepScoreConfig`, its cache key, and persist/load logic from `AppConfig`.
- Made `AppConfig.sleepScoreConfig` return `SleepScoreConfig.default` (DEBUG override preserved).
- Updated `docs/remote-config-schema.md` to remove sleep score config references.
- Updated `docs/sleep-score-calculation.md` to describe local-only configuration.

### Next Session
- No follow-up required unless the user wants to also remove the DEBUG override hook or add a UI for tuning `SleepScoreConfig.default` in Settings.

### Open Questions
- Should the orphaned `UserDefaults` key `appconfig.sleepScoreConfig` be explicitly cleared for existing installs, or is it acceptable to leave it unused?
