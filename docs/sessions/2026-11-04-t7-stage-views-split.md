---
date: 2026-11-04
feature: f18
branch: feature/f18/t7-stage-views-split
title: F18-T7 Sleep Stages Views Split
---

### Completed
- **F18-T7**: SleepStagesInfoView (315 → 27) + SleepStageBreakdownView
  (231 → 64) split, on branch `feature/f18/t7-stage-views-split`
  (commit `dc9c3da`), pushed.

### Technical Details
- SleepStagesInfoView composes: SleepStagesInfoHeader (dismiss env moved
  with the close button), YourStagesSection (stage cards + status/label/
  color/name/description/recommendation helpers + StageStatus enum),
  ScoreImpactSection (formula + computedStagePenalty + threshold bars +
  ThresholdMode). Public init `(session:theme:)` unchanged.
- SleepStageBreakdownView composes: SleepStageLegendGrid (2-column stage
  durations) + SleepStageHypnogramChart.
- SleepStageHypnogramChart promoted to its own file — it was a second
  public view inside SleepStageBreakdownView.swift.
- Cleanup while rewriting: unused `envTheme` property and unused `Env`
  import dropped; 4-space → 2-space in the breakdown view.
- Layering check green (195 files). Both views stay in DesignSystem
  (used by Statistics + Recordings).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `DesignSystem/SleepStagesInfoView.swift` | −315/+27 | Composer |
| `DesignSystem/SleepStageBreakdownView.swift` | −231/+64 | Composer, 2-space |
| `DesignSystem/{SleepStagesInfoHeader,YourStagesSection,ScoreImpactSection,SleepStageHypnogramChart,SleepStageLegendGrid}.swift` | +482 (new) | Five section/chart files |

### Build Status
- **BUILD SUCCEEDED** first try, zero warnings.

### Suggested Branch
`feature/f18/t7-stage-views-split` (pushed)

### Suggested Commit
`dc9c3da` — `[F18-T7] — Sleep stages views split (315 + 231 → six focused files)`

### Next Session
- User merges T7, then F18-T8: RecordCustomMelodySheet (307) +
  MelodyPickerSheet (297) split.

### Open Questions
- None.
