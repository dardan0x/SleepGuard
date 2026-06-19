---
date: 2026-06-16
feature: f15
branch: bugfix/f15-briefing-same-day-empty-modal
title: Fix same-day empty briefing modal
---

### Completed
- F15-T17: Fixed the empty briefing modal that could appear when opening the app the same day a session was saved.

### Technical Details
- `Briefing` now conforms to `Identifiable` with a stable `UUID` id, enabling item-based sheet presentation.
- `MainTabView` switched from `.sheet(isPresented: $showBriefing)` to `.sheet(item: $currentBriefing)`, so a `nil` briefing can never produce an empty sheet.
- `generateBriefingIfNeeded()` now filters sessions to those with cached scores and only triggers when the latest cached session started on a previous calendar day.
- `lastBriefingShownDate` is still recorded on sheet dismiss.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Personalization/Sources/Engine/Briefing.swift` | +4/-3 | Added `Identifiable` conformance and `id: UUID` to `Briefing`. |
| `SleepGuard/MainTabView.swift` | +16/-21 | Replaced `showBriefing` state with item-based sheet; gated briefing trigger to previous-day sessions. |
| `docs/trackers/f15-personalization.md` | +16/-0 | Added F15-T17 bugfix task and notes. |
| `docs/FeatureTracker.md` | +6/-6 | Updated activity log and task counts. |

### Architecture Decisions
- **Item-based sheet**: More robust than `isPresented` + optional content because presentation and content are tied to the same optional value.
- **Previous-day gate**: The briefing is meant as a "last night" recap; sessions started today (naps or same-day re-opens) should not trigger it.

### Build Status
- **BUILD SUCCEEDED** — one pre-existing warning about an unused `latestSession` binding in `saveLifestyleLog` remains.

### Suggested Branch
`bugfix/f15-briefing-same-day-empty-modal`

### Suggested Commit
`[F15-T17] Fix same-day empty briefing modal`

### Changes done
- Made `Briefing` `Identifiable`.
- Switched `MainTabView` briefing presentation to `.sheet(item:)`.
- Added same-day session guard in `generateBriefingIfNeeded()`.
- Updated F15 tracker and FeatureTracker.

### Next Session
- (none planned; awaiting user priority)

### Open Questions
- None.
