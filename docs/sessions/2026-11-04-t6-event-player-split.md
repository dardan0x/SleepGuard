---
date: 2026-11-04
feature: f18
branch: feature/f18/t6-event-player-split
title: F18-T6 EventPlayerView Split
---

### Completed
- **F18-T6**: EventPlayerView split 330 → 91 lines, on branch
  `feature/f18/t6-event-player-split` (commit `a6bdc93`), pushed.

### Technical Details
- Four section structs extracted (one per file): header (+ time/duration
  formatting helpers), waveform (bars, progress line, tap-to-scrub, time
  labels, deterministic placeholder), transport controls, intensity legend.
- The loading-pulse `pulsePhase` state + `.task(id: isLoadingWaveform)` moved
  INTO EventWaveformView — the pulse only animates the waveform placeholder,
  so the parent sheds both.
- Init signature unchanged; both sheet callers (Clip/LegacyPlayerContent)
  compile untouched.
- Dead code note: `waveformMarkers` (burst-span capsules) moved verbatim —
  only its call site is commented out.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Recordings/Sources/Views/EventPlayerView.swift` | −330/+91 | Thin composer + loading overlay |
| `Packages/Recordings/Sources/Views/EventPlayerHeaderView.swift` | +68 (new) | Header + formatters |
| `Packages/Recordings/Sources/Views/EventWaveformView.swift` | +161 (new) | Waveform + pulse ownership |
| `Packages/Recordings/Sources/Views/EventPlayerControlsView.swift` | +48 (new) | Transport controls |
| `Packages/Recordings/Sources/Views/EventIntensityLegendView.swift` | +30 (new) | Legend |

### Build Status
- **BUILD SUCCEEDED** first try, zero warnings.

### Suggested Branch
`feature/f18/t6-event-player-split` (pushed)

### Suggested Commit
`a6bdc93` — `[F18-T6] — EventPlayerView split (330 → 98 lines)`

### Next Session
- User merges T6, then F18-T7: SleepStagesInfoView + SleepStageBreakdownView
  section split (DesignSystem, 315 + 231).

### Open Questions
- None.
