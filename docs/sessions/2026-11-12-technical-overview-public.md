---
date: 2026-11-12
feature: Docs
branch: docs/technical-overview
title: Technical overview verified against the code and published; README corrected
---

### Completed
- `docs/TECHNICAL_OVERVIEW.md` checked claim by claim against the code, reorganized for a public reader, and added to the repository. The README links to it.
- README, `snore-detection-algorithm.md` and `sleep-score-calculation.md` corrected where they disagreed with the code.

### Technical Details
- **Verified correct:** the sleep score formula, every coefficient and cap, and the worked example (63, recomputed); the sensitivity presets; the classifier cascade; routes; package dependencies; CI checks; Factory's task-local container and `@Injected` timing.
- **Fixed in the overview:**
  - iOS 17.6 (not 17.0); 12 packages / ~21k lines; the Watch app has no Xcode target.
  - The FFT fallback is implemented but off in live detection (`spectralScore: 0`).
  - Tap ~47 Hz vs the 50 ms sampler; speech is 25 identifier patterns and opt-in.
  - The widget snapshot is written at launch and on background, not after each save.
  - Stale line references replaced by symbol names; 19 services; scopes table (no `routerPath`).
  - An outdated DI answer; links to 9 files that aren't in git (one doesn't exist).
- **Reorganized:** table of contents; new Concurrency section; Quality section (tests, CI, logging, accessibility, privacy); decisions and open items; further reading with tracked docs only. Interview-prep phrasing became neutral (FAQ, "in one sentence"), and the "stale docs" section was removed by fixing those docs instead.
- **README fixes:**
  - Coughing and ambient-noise detection aren't implemented (categories only).
  - The smart alarm was replaced by delayed start in `a644429`.
  - The melody pauses recording (it doesn't "never drop the mic" or fade in).
  - Full-night playback is Debug-only.
  - Score weights aren't remote-tunable (Release always uses the defaults).
  - iOS 17.6; test counts 277.

### Files Changed
| File | What Changed |
|------|--------------|
| `docs/TECHNICAL_OVERVIEW.md` | Now tracked; verified and reorganized |
| `README.md` | Link to the overview; 8 claims corrected |
| `docs/snore-detection-algorithm.md` | State machine location; §9.4 points to the score doc instead of old coefficients |
| `docs/sleep-score-calculation.md` | Source of truth is `SleepScore.compute` |

### Architecture Decisions
- Reference code by type/function name, not line number, in public docs.

### Build Status
- Docs only. All relative links resolve to tracked files; all in-page anchors match GitHub heading slugs.

### Suggested Branch
`docs/technical-overview` (off `main` after PR #124)

### Suggested Commit
`Docs — Technical overview verified against the code; README corrected and linked`

### Changes done
- See Files Changed.

### Next Session
- User: push; consider updating `docs/FeatureTracker.md` F10 ("Smart Alarm", replaced by delayed start).

### Open Questions
- None.
