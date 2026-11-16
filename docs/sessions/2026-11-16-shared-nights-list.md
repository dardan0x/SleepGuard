
### Completed
- F25-T3: the Recordings list hosts the shared nights list content; grouping comes from SleepCore's `NightMonth`.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Recordings/Sources/Views/RecordingsListView.swift` | `NightMonth.months` + `NightsListContent` / `NightsListEmptyContent`; keeps `@Query`, routing, delete confirmation and SwiftData delete, `refreshable`, error state |
| Package manifests, `Package.resolved` | Shared `0.18.0` |
| Deleted (approved): `Sources/Helpers/SessionGrouper.swift`, `Sources/Views/{NightGroup,MonthSection,NightGroupRowView,RecordingsEmptyView}.swift`, `Tests/SessionGrouperTests.swift` | Grouping is `NightMonth` (its tests carry these cases); the drawing is shared |

### Technical Details
- The list reads each session's events for its rows (`nightSummary`), as it did before through `eventsCount`.
- The day card is SleepGuard's row (date, recordings, length, events, score, long press to delete); the expanded rows are the kit's `NightRow`, which now shows the length and a chevron like SleepGuard's.

### Build Status
- Against the local shared checkout, then on shared `0.18.0`: all 8 suites pass, the app builds, layering, view size, format pass.
- Not checked on screen (the morning briefing sheet covers launch).
