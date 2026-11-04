---
date: 2026-11-04
feature: f18
branch: feature/f18/t4-maintabview-split
title: F18-T4 MainTabView Split
---

### Completed
- **F18-T4**: MainTabView split 321 → 155 lines + 4-space → 2-space indent,
  on branch `feature/f18/t4-maintabview-split` (commit `1a76c77`), pushed.
  Branched off the integration branch at the T2 merge point — files are
  disjoint from the open T3 branch (app target vs Env/AudioEngine).

### Technical Details
- `AppBriefingController` (app target): briefing generation + lifestyle log
  + `markBriefingShown`/`dismissBriefing`. App target chosen because the
  controller needs Personalization (BriefingEngine) AND Env
  (AppConfig/UserPreferences) — no package may import both. Two-phase
  @State creation in `.task` (env-dependent init, same pattern as
  SessionDetailModel).
- `CustomTabBarView`: iOS < 26 capsule bar chrome + items, verbatim. The
  Strings title switch stays in MainTabView and is injected as
  `titleFor:` — avoids duplicating the mapping (duplication rule).
- `SessionProcessingOverlay`: extracted dimming + spinner.
- Shared modifiers hoisted to the body root: `.environment(tabCoordinator)`,
  `.onChange(visibleTabsInOrder)`, briefing `.task` + `.sheet`, processing
  overlay. The iOS 26 / <26 branches previously each carried a copy of
  sheet+task+onChange — now single instances. System-only modifiers
  (`.tint`, `.animation(nil:value:)`) stay on the system branch.
- Briefing sheet binding: `Binding(get: controller.currentBriefing, set:
  dismiss when nil)` + `onDismiss: markBriefingShown()` — parity with the
  original `item:onDismiss:` sheet.
- Pre-existing zero-warning fix: the unused-`latestSession` warning is gone
  (logic moved into the controller, which uses a plain nil-check).
- iOS 26 system tab bar boot-smoke-tested (simulator is 26.2). The < 26
  custom bar path compiles; visuals were moved verbatim.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/MainTabView.swift` | −321/+155 | Slim container, hoisted modifiers, 2-space |
| `SleepGuard/AppBriefingController.swift` | +112 (new) | Briefing generation + log persistence |
| `SleepGuard/CustomTabBarView.swift` | +95 (new) | Floating capsule tab bar |
| `SleepGuard/SessionProcessingOverlay.swift` | +33 (new) | Processing overlay |

### Architecture Decisions
- **Controller in the app target** rather than Personalization/Env: only the
  app target may import both sides. Documented in the type's doc comment.
- **Closure injection for tab titles** over duplicating the Strings switch.

### Build Status
- **BUILD SUCCEEDED**, zero warnings, boot smoke passed.

### Suggested Branch
`feature/f18/t4-maintabview-split` (pushed)

### Suggested Commit
`1a76c77` — `[F18-T4] — MainTabView split (321 → 155 lines, 4-space → 2-space)`

### Next Session
- User merges T3 + T4 (order independent — disjoint files), then F18-T5:
  RecordingPrestartView split (enum sheets; TipRow/SnoreInterrupterRow/
  DelayPickerSection structs).

### Open Questions
- None.
