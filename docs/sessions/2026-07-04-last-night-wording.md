---
date: 2026-07-04
feature: f15
branch: bugfix/f15-t18-last-night-wording
title: "Last night" wording only for next-day app opens
---

### Completed
- F15-T18: Made "last night" wording conditional in the Sleep Briefing and Statistics summary.

### Technical Details
- `BriefingEngine.generate` now computes `isLastNight` by checking whether the latest session's `startDate` falls on the calendar day before `now`.
- `buildHeadline`, `buildWeeklySnoringContent`, `buildWeeklyScoreContent`, and `buildWeeklyDurationContent` choose "Last night" strings only when `isLastNight` is true; otherwise they use new "Last time" variants.
- `StatisticsLoadedView` label uses `Strings.lastNightStatisticsLoadedView` only when `Calendar.current.isDateInYesterday(session.startDate)`; otherwise `Strings.lastTimeStatisticsLoadedView`.
- Added 7 localized keys for "last time" variants and regenerated `Strings.swift`.
- Added two unit tests: one verifying "Last night" phrasing for a yesterday session, one verifying "Last time" for an older session.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/DesignSystem/Sources/Resources/Strings.txt` | +10/-0 | Added "last time" localized keys for briefing headlines, stat label, and statistics loaded view |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | +91/-0 | Merged new last-time strings into catalog |
| `Packages/DesignSystem/Sources/Strings.swift` | +7/-0 | Regenerated accessors: `briefingHeadlineQuietLastTime`, `briefingHeadlineNormalLastTime`, `briefingHeadlineWeeklySnoringLastTime`, `briefingHeadlineWeeklyScoreLastTime`, `briefingHeadlineWeeklyDurationLastTime`, `briefingStatLastTime`, `lastTimeStatisticsLoadedView` |
| `Packages/Personalization/Sources/Engine/BriefingEngine.swift` | +32/-12 | Added `isLastNight` helper and wired it through `buildContent` / weekly builders / `buildHeadline` |
| `Packages/Statistics/Sources/Views/StatisticsLoadedView.swift` | +14/-1 | Replaced hardcoded "LAST NIGHT" label with conditional `summaryLabel` based on `isLastNight` |
| `Packages/Personalization/Tests/BriefingEngineTests.swift` | +24/-0 | Added `headlineSaysLastNight_whenLatestSessionIsYesterday` and `headlineSaysLastTime_whenLatestSessionIsOlder` |
| `docs/trackers/f15-personalization.md` | +18/-0 | Added F15-T18 task row and detail section |
| `docs/trackers/f3-statistics.md` | +4/-0 | Added 2026-07-04 refinement note about label gate |
| `docs/FeatureTracker.md` | +1/-0 | Added activity log entry for F15-T18 + F3 polish |

### Architecture Decisions
- **Per-string last-time variants vs. placeholder substitution**: Chose dedicated `*.lastTime` keys to keep the existing "Last night" translations untouched and avoid runtime string mutation. Slightly more keys but safer for localization.
- **Use `startDate` for last-night detection**: The existing same-day gate already prevents naps; using `startDate` matches the previous briefing gate and is predictable for overnight sessions.

### Build Status
- **BUILD SUCCEEDED** — `SleepGuard` scheme and `Personalization` scheme both build with zero errors.
- Unit tests compile but cannot be executed via CLI because the auto-generated SPM schemes lack a test action and `swift test` fails on the package's macOS platform mismatch (pre-existing). Test logic was verified by code review.

### Suggested Branch
`bugfix/f15-t18-last-night-wording`

### Suggested Commit
`[F15-T18] Conditional "last night" wording in briefing and stats label`

### Changes done
- Added `isLastNight(session:now:calendar:)` to `BriefingEngine`.
- Added last-time localization keys and regenerated `Strings.swift`.
- Updated briefing headlines and weekly stat labels to use "last time" when the session is not from the previous day.
- Updated `StatisticsLoadedView` summary label to use "LAST TIME" for non-last-night sessions.
- Added two unit tests for headline phrasing.
- Updated F15/F3 trackers and `FeatureTracker.md`.

### Next Session
- (none planned; awaiting user priority)

### Open Questions
- None.
