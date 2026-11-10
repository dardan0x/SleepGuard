---
date: 2026-11-11
feature: F22
branch: feature/f22/t13-view-size-check
title: F22-T13 CI view-size check
---

### Completed
- F22-T13: CI fails when a view file goes over 200 lines, with a ratcheting allowlist for today's two offenders.

### Technical Details
- `scripts/check-view-size.py` covers `Sources/Views/` and `Sources/Components/` in every package.
- Allowlist entries carry a line ceiling and a reason. A stale entry also fails, so the list only shrinks.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `scripts/check-view-size.py` | +70 | New check |
| `.github/workflows/layering.yml` | +2 | Runs it |
| `AGENTS.md`, `CLAUDE.md` | +1 | Rule points at the check |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T13 Done, 10/14 |

### Architecture Decisions
- Ceilings instead of plain exemptions: an allowlisted file can't quietly grow to 800 lines.
- The 100-line container rule isn't enforced. Detecting a "container view" by pattern would be noisy.

### Build Status
- Lint clean, layering passed, view-size check passed and probed (new oversized file → exit 1; allowlisted file growing → exit 1). No Swift changed.

### Suggested Branch
`feature/f22/t13-view-size-check`

### Suggested Commit
`F22-T13 — CI view-size check with ratcheting allowlist`

### Changes done
- See Files Changed.

### Next Session
- F22-T8: extract `DetectionStateMachine`.

### Open Questions
- `SleepReportPDFGenerator` belongs in `Helpers/`, not `Views/`. Moving it would drop it from the scan. Do it as a cleanup when it's split?
