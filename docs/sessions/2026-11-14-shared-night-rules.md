### Completed
- F0-T6 (tracked in SleepGuardUIKitWay): `SleepSession`'s night metrics (`snoringDuration`, sleep talking, `snoringEpisodes`, `displayableSnoringEpisodes`, `episodePlaybackEvents`, `eventsCount`, `stageStats`, `sleepInputs`) call `SleepCore`'s rules through a mapping to the shared `Night`. `SnoringEpisode` wraps the shared `NightEpisode` with the same public API.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Models/Sources/Data/SleepSession+Night.swift` | New: models → `Night` / `NightEvent` |
| `Packages/Models/Sources/Data/SleepSession.swift` | Rule bodies replaced by calls to the shared rules (324 → 197 lines) |
| `Packages/Models/Sources/Data/SnoreEpisode.swift` | `SnoringEpisode` wraps `NightEpisode` |
| `AGENTS.md`, `CLAUDE.md`, `docs/adr/0004-shared-repo.md` | Night rules are shared |

### Build Status
- All 8 package suites pass with no test changed (Models 77), against the local shared checkout. App builds through the dev workspace. Layering, view size, format: pass.
- Needs shared `0.4.0`: then `sh scripts/bump-shared.sh 0.4.0` (this repo still pinned `0.1.0`).