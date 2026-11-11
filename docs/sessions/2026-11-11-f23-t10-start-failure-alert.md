---
date: 2026-11-11
feature: F23
branch: feature/f23/t10-start-failure-alert
title: F23-T10 Alert when a recording fails to start
---

### Completed
- F23-T10: a failed start now shows "Couldn't Start Recording" instead of silently doing nothing.

### Technical Details
- `startFailed` cases in `PrestartPresentation` and `CountdownAlert`, set in every start `catch`. OK-only system alert, in the same form as the existing alerts.
- 2 strings via `Strings.txt` → `generate-xcstrings.py`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/SleepSession/Sources/Views/RecordingPrestartView.swift` | +7 | Alert + case |
| `Packages/SleepSession/Sources/Views/RecordingCountdownView.swift` | +8 | Alert + case (charging and delay paths) |
| `Packages/DesignSystem/Sources/Resources/{Strings.txt, Localizable.xcstrings}`, `Strings.swift` | +2 keys | New strings |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | T10 Done |

### Architecture Decisions
- View-local alert state (the existing enums), no service state.

### Build Status
- Lint, hardcoded-strings, strings-in-sync and view-size checks pass; DesignSystem 7 tests pass; app build 0 warnings.
- Simulator: alert shown with a temporary throw (reverted).

### Suggested Branch
`feature/f23/t10-start-failure-alert`

### Suggested Commit
`F23-T10 — Alert when a recording fails to start`

### Changes done
- See Files Changed.

### Next Session
- F23-T11 accessibility pass.

### Open Questions
- Also surface failures when starting from the notification tap (needs app-level presentation state)?
