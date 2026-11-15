
### Completed
- F24-T3a: the night detail's components come from the shared kit: stats grid, timeline (detail and session summary), the two banners, event rows, event cards.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/DesignSystem/Sources/Components/SleepGuardKitAdapters.swift` | New: kit initializers from `SleepSession` / `SnoreEvent` with the old signatures |
| `Packages/DesignSystem/Sources/Components/{SessionStatsGrid,SnoringTimelineView}.swift` | Deleted |
| `Packages/DesignSystem/Sources/Components/{MelodyGapsBannerView,LowBatteryBannerView}.swift` | Thin wrappers over the kit's banners |
| `Packages/Recordings/Sources/Views/EventRow.swift` | Deleted |
| `Packages/Recordings/Sources/Views/EventsSheetView.swift` | Kit `EventCard`; private card removed |
| `Packages/Recordings/Sources/Views/SessionDetailTimelineView.swift` | Kit `NightTimeline` |
| `Packages/SleepSession/Sources/Views/SessionSummaryTimeline.swift` | Kit `NightTimeline` without the title |

### Technical Details
- SleepGuard's own types shadow the kit's same-named ones inside its modules, so the kit's take over only once SleepGuard's are deleted.
- The adapters keep the call sites unchanged; only the drawing moved.
- Visible change: event rows use the device's short time.

### Build Status
- All 8 suites pass; app builds (against the local shared checkout); format, layering, view size pass.
- Bumped to shared `0.12.0` (from `0.10.0`): all 8 suites pass and the project (release) builds.
- Not seen on screen yet.
