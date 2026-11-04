---
date: 2026-11-04
feature: f18
branch: feature/f18/t10-computed-props-sweep
title: F18-T10 Computed-View Sweep
---

### Completed
- **F18-T10**: computed-`some View` sweep, on branch
  `feature/f18/t10-computed-props-sweep` (commit `ac799b4`), pushed.

### Technical Details
- Scope decision: 152 computed view properties remain across ~74 files
  after T1–T9 (the F18 splits removed many). Per the SwiftUI-expert skill,
  small static computed sections are acceptable — conversion is warranted
  for complex (> ~20 lines), state-reading, or per-ForEach-item sections.
  Converted the two worst files; the durable enforcement is the new review
  rule (wholesale conversion of 152 properties would be unreviewable and
  anti-surgical).
- SessionDetailAdvancedPlayerView 175 → 27: three section structs with
  narrow inputs — the static spectrum bars now have their own invalidation
  boundary and no longer re-evaluate when waveform samples redraw.
  WaveformShape + StatBox promoted to own files.
- SnoreInterrupterSheet 186 → 85 (4-space → 2-space): duration picker
  (binds draft state), song row, status badge, buttons — all converted;
  save/cancel logic passed as closures.
- New AGENTS.md/CLAUDE.md rule under View Componentization: computed `some
  View` shares the parent's invalidation boundary — prefer a View struct
  for complex/state-reading/per-ForEach sections; grep command included
  for review.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Recordings/SessionDetailAdvancedPlayerView.swift` | −175/+27 | Three section structs |
| `Recordings/{AdvancedWaveformSection,AdvancedSpectrumSection,AdvancedStatsSection,WaveformShape,StatBox}.swift` | +288 (new) | Sections + promoted types |
| `SleepSession/SnoreInterrupterSheet.swift` | −186/+85 | Four structs, 2-space |
| `SleepSession/SnoreInterrupter{DurationPicker,SongRow,StatusBadge,Buttons}.swift` | +158 (new) | Sheet sections |
| `AGENTS.md` / `CLAUDE.md` | +7 | Computed-view review rule |

### Build Status
- **BUILD SUCCEEDED**; layering check green (217 files); AGENTS/CLAUDE in sync.

### Suggested Branch
`feature/f18/t10-computed-props-sweep` (pushed)

### Suggested Commit
`ac799b4` — `[F18-T10] — Computed-view sweep: worst offenders + review rule`

### Next Session
- User merges T10, then F18-T11: enum-sheet sweep + localization gap fixes
  ("Melody"/"Melody 12" fallbacks flagged in T8/T9/T10).

### Open Questions
- None.
