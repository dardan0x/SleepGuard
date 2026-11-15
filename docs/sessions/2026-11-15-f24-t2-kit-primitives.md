
### Completed
- F24-T2: the basic components come from the shared kit. Deleted from `DesignSystem` (approved): `StatCard`, `SleepScoreGauge`, `MiniBarChart`, `AudioLevelMeter`, `ScaleButtonStyle`, `SheetHandle` / `SheetNavHeader`, `RecordingActionButton`, `StartRecordingButton`, `StopRecordingButton`.

### Technical Details
- Same APIs, so the 48 call sites didn't change; they resolve to the kit's types through `DesignSystem`'s re-export.
- Same drawing: every hardcoded value in the old copies is the kit's token; the kit reads colours from the environment the root fills (F24-T1).

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/DesignSystem/Sources/Components/{StatCard,SleepScoreGauge,MiniBarChart,AudioLevelMeter,ScaleButtonStyle,SheetHeader,RecordingActionButton,StartRecordingButton,StopRecordingButton}.swift` | Deleted |
| `docs/TECHNICAL_OVERVIEW.md` | DesignSystem row |

### Build Status
- All 8 suites pass; app and widgets build; format, layering, view size pass.
- Not seen on screen (the daily briefing covers the app on launch). Needs a look: dashboard (stat cards, gauge, mini chart), Start/Stop Recording, sheets with the handle or back header.
