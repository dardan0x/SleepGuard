
### Completed
- F25-T4a: the session detail and the events sheet host the shared content; the filter and event rows come from SleepCore.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Recordings/Sources/Views/SessionDetailLoadedView.swift` | Hosts `NightDetailContent` (stages and short-events button in slots); toolbar, sheets, overlay unchanged |
| `Packages/Recordings/Sources/Views/ShortEventsButton.swift` | New: the short-events button, now a slot view |
| `Packages/Recordings/Sources/Views/EventsSheetView.swift` | Hosts `EventsGridContent` over rows |
| `Packages/Recordings/Sources/Helpers/SessionDetailModel.swift` | `night`, `filters`, `rows`, `event(for:)`; own filter enum, `filteredEvents`, `displayDurations` removed |
| `Packages/Recordings/Tests/SessionDetailModelTests.swift` | Same cases on the new API; membership test moved to SleepCore |
| `Packages/Models/Sources/Data/SleepSession+Night.swift` | `night` public (the extension is now `public`, same members visible as before plus `night`) |
| `scripts/check-view-size.py` | `SessionDetailLoadedView` left the allow-list: 141 lines now (was 201) |
| Package manifests, `Package.resolved` | Shared `0.19.0` |
| Deleted (approved): `SessionDetailHeaderView`, `SessionDetailEventsView`, `SessionDetailTimelineView` | Drawing is shared |

### Architecture Decisions
- With the owner: snoring rows show the episode's start (a visible change for multi-event episodes); the filter keeps SleepGuard's rule (all four once there are two kinds).

### Build Status
- Against the local shared checkout, then on shared `0.19.0`: all 8 suites pass, the pinned app builds, layering and view size pass.
- Not checked on screen (morning briefing sheet at launch).
