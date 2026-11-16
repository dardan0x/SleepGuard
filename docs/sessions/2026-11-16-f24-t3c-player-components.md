
### Completed
- F24-T3c: the player draws with the shared kit's components (header, controls, loudness legend, enhanced-audio toggle, event rows, no-audio card). The waveform stays SleepGuard's. F24-T3 is done.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Recordings/Sources/Views/{EventPlayerHeaderView,EventPlayerControlsView,PlayerEventRow,EnhancedAudioToggleSection,NoAudioView,EventIntensityLegendView}.swift` | Deleted |
| `Packages/Recordings/Sources/Views/EventPlayerView.swift` | Kit header, controls, legend; unused label helper removed |
| `Packages/Recordings/Sources/Views/{ClipPlayerContent,PlayerEventListSection,PlayerSheetView}.swift` | Kit toggle, rows, no-audio card |

### Technical Details
- Visible changes (approved): device short time in the header, "Event 1 / 3", "1m 4s · Quiet" in the player's rows (translated loudness), the detail rows' kind dot.

### Build Status
- All 8 suites pass; app builds; format, layering, view size pass. Shared `0.13.0` (no release needed).
- Fixed on the way: `ClipPlayerContent` needed `import DesignSystem` for the kit's toggle (the old one was in its own module).
- Not heard or seen yet.
