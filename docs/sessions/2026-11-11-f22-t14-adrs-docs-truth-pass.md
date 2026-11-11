---
date: 2026-11-11
feature: F22
branch: feature/f22/t14-adrs-docs-truth-pass
title: F22-T14 ADR 0002, docs truth pass, F22 feature doc
---

### Completed
- F22-T14: ADR 0002 records the protocol-per-service decision. The docs now match the code after F22. The F22 feature doc is written, and F22 is complete except for T10's real-night check.

### Technical Details
- Checked the tap-thread claim against Apple's `installTap` docs. They say only that the block "may be invoked on a thread other than the main thread", so three code comments and the overview no longer call it the real-time render thread.
- Test counts come from counting `@Test` in the sources: 268 in 8 packages, matching the last run.
- The tracker's detail sections for T8, T11, T12 and T13 had never moved past Backlog. They're filled in from their session fragments.
- Superseded feature docs (F15, F19, F20, F21) get a "historical record" note instead of a rewrite.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `docs/adr/0002-protocol-services.md` | +60 | New: context, decision, honest limits, alternatives |
| `docs/features/f22-architecture-hardening.md` | +130 | New feature doc: concerns → tasks, files, tests, state, edge cases, open items |
| `README.md` | ±40 | Package graph with Routing; Env/AudioEngine/DesignSystem/Routing rows; protocols; detection actor; schema plan; 268 tests table; CI checks; 12 packages |
| `docs/snore-detection-algorithm.md` | ±40 | Where the rules live (machine + actor); duration thresholds; first-sample onset; raw log format 2; data-flow box |
| `AGENTS.md`, `CLAUDE.md` | +3 | Detection-stream rule; ADR convention; ADR 0002 link (still identical apart from the agent name) |
| `Packages/AudioEngine/Sources/Engine/TapProcessor.swift`, `AudioRecorder.swift` | ±4 | Tap-thread comments match Apple's docs |
| `Packages/Env/Sources/Services/Container.swift` | ±1 | Stale "private init" in a comment |
| `docs/features/f15…`, `f19…`, `f20…`, `f21…` | +2 each | Historical-record notes |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T8/T11–T13 details filled; T14 Done; F22 Done (real night pending) |
| Local only: `docs/TECHNICAL_OVERVIEW.md`, `docs/ProjectArchitecture.md`, `docs/architecture/overview.md`, `dependencies.md` | — | Truth pass (untracked / gitignored, not committed) |

### Architecture Decisions
- ADR numbering follows the order the decisions were made (Routing T4, protocols T5–T7, actor T10), so 0002 was written after 0003.
- Historical feature docs are annotated, not rewritten: they record what was true when each feature shipped.

### Build Status
- Comment-only Swift changes: lint clean; layering and view-size checks pass; app build 0 warnings.

### Suggested Branch
`feature/f22/t14-adrs-docs-truth-pass`

### Suggested Commit
`F22-T14 — ADR 0002, docs truth pass, F22 feature doc`

### Changes done
- See Files Changed.

### Next Session
- User: one real night on a device running `feature/f22-architecture-hardening` (T10 acceptance), then merge it into `main`.
- Possible follow-ups: option B (mic buffers into the stream), a format-2 replay excerpt with sleep talking, the minute-0 classification question from T9.

### Open Questions
- `docs/interview-presentation.md` Part 5b still shows `register { FakePreferences() }`. Update it, or leave it as is?
