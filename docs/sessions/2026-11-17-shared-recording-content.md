
### Completed
- F25-T5: the prestart, bedside clock and summary host the shared recording content.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | Hosts `PrestartContent`; Start's checks in `startTapped()` |
| `Packages/SleepSession/Sources/Views/PrestartOptions.swift` | New: delay and Snore Interrupter rows, for the options slot |
| `Packages/SleepSession/Sources/Views/BedsideClockView.swift` | Hosts `BedsideClockContent`; melody disclaimer and overlay in slots; `stopTapped()` |
| `Packages/SleepSession/Sources/Views/SessionSummaryView.swift` | Hosts `SessionSummaryContent` |
| Package manifests, `Package.resolved` | Shared `0.21.0` |

### Open Questions
- Unused now, kept at the owner's choice: `SessionSummaryTimeline.swift` and `SessionSummaryHeader(session:scoreConfig:)` in `SleepGuardKitAdapters.swift`.

### Build Status
- Against the local shared checkout, then on shared `0.21.0`: all 8 suites pass, the app builds; layering, view size, format pass.
- Not checked on screen (morning briefing sheet at launch).
