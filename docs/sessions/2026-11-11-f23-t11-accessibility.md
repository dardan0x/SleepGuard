---
date: 2026-11-11
feature: F23
branch: feature/f23/t11-accessibility
title: F23-T11 Accessibility pass (VoiceOver)
---

### Completed
- F23-T11: VoiceOver can use the main screens. Icon buttons have names, and the score, cards, timeline, hypnogram and bars read as meaningful elements. Dynamic Type was assessed and left for a design decision.

### Technical Details
- `Label(..., systemImage:).labelStyle(.iconOnly)` for 16 icon buttons (same pixels, no added lines).
- One-element summaries (`.accessibilityElement` + label/value) for the gauge, the cards and the two `Canvas` views; per-bar spoken label/value in `MiniBarChart`; the decorative meter is hidden.
- 13 `a11y.*` strings.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| 10 view files (Recordings, Statistics, SleepSession, Personalization, DesignSystem `SheetHeader`) | ±1 per button | Labelled icon buttons |
| `SleepScoreGauge`, `StatCard`, `AudioLevelMeter`, `SnoringTimelineView`, `SleepStageHypnogramChart`, `MiniBarChart` (DesignSystem) | +3–20 | VoiceOver semantics |
| `TrendStatCard`, `CalendarStatCard`, `StatisticsMiniChartSection` (Statistics) | +3 | Same |
| `Packages/DesignSystem/Sources/Resources/{Strings.txt, Localizable.xcstrings}`, `Strings.swift` | +13 keys | `a11y.*` |
| `AGENTS.md`, `CLAUDE.md` | +1 | Accessibility rule |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | T11 Done |

### Architecture Decisions
- `Label` + `.iconOnly` over `.accessibilityLabel` on an `Image`: it's SwiftUI's own pattern, and it kept the allowlisted file at its ceiling.

### Build Status
- Lint, layering, view-size and hardcoded-strings checks pass; DesignSystem, Statistics, Recordings and Personalization tests pass; app build 0 warnings.
- Simulator accessibility tree checked (dashboard, calendar).

### Suggested Branch
`feature/f23/t11-accessibility`

### Suggested Commit
`F23-T11 — VoiceOver accessibility pass`

### Changes done
- See Files Changed.

### Next Session
- F23-T6 when labelled nights exist; then merge F22 and F23 into `main`.

### Open Questions
- Dynamic Type: adopt a scalable type scale (382 fixed font sizes)?
- Grow small tap targets (calendar arrows 12 × 16 pt, event-row icons) to 44 × 44 pt?
