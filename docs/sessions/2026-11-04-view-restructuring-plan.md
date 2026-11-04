---
date: 2026-11-04
feature: f18
branch: feature/f18/view-restructuring
title: View Restructuring Plan (post-Swift 6)
---

### Completed
- **Research**: Ranked the market's top SwiftUI agent skills — #1 AvdLee/SwiftUI-Agent-Skill (van der Lee, 34 reference files, official Claude/Cursor/Codex plugins), #2 Dimillian/Skills (Ricouard — swiftui-view-refactor/performance-audit, now OpenAI's official Codex Build-iOS plugins, IceCubesApp author), #3 twostraws/swift-agent-skills (Hudson — curated directory + SwiftUI Pro skills). Supporting: AvdLee Core Data/Concurrency/Testing/Build-Optimization, Chad Etzel iOS Code Audit.
- **Audit**: Ranked all 176 Swift files by size. 14 view files violate the 200-line AGENTS.md limit (572–231 lines). Flagged `SessionManager.swift` (1085 lines) as the app's largest god object. Confirmed healthy: zero AnyView, centralized DateFormatters, Recordings detail sections already extracted, correct 2-package DesignSystem placement for SleepStageBreakdownView.
- **T14 (done, ahead of schedule)**: Installed the three project skills — `swiftui-expert-skill` (AvdLee @ 204dba7), `swiftui-view-refactor` + `swiftui-performance-audit` (Dimillian @ 05ba982) — into `.claude/skills/` with LICENSE files. Read all three SKILL.md files before installing (Hudson caveat); all clean, non-opinionated, and aligned with project rules (view-refactor's MV-over-MVVM matches the no-ViewModels rule). Documented adoption + conflict policy + trace-recording consent rules in AGENTS.md "AI Skills (Installed)".
- **Decision (user)**: SessionManager decomposition stays in this feature as T3.

### Technical Details
- PlayerSheetView (572): dual playback engines (ClipPlaybackController + legacy AVAudioPlayer) in one view; identical AVAssetExportSession boilerplate duplicated in generateWaveformFromSession and setupLegacySingleEvent; load state is boolean soup (isReady/didFinishInitialLoad/hasLoadingTimedOut) instead of a ViewState enum.
- SessionDetailView (507): ~120 lines of share/export logic (shareEventClip/exportAndShare/exportReport/shareFullSession/presentShareSheet/deleteSession) and 3 marker-computation funcs live in the view.
- MainTabView (321): iOS 26/<26 tab branches duplicate the briefing sheet + onChange + task modifiers; briefing data logic (SwiftData fetch → BriefingEngine) in the view; file uses 4-space indent vs project's 2-space .swiftformat.
- Main pattern across offenders: 146 computed `some View` properties across 76 files — these share the parent's invalidation boundary (AvdLee view-structure.md: extract structs, not computed properties; per-event params inside ForEach must be structs).
- 4 private ViewState enums duplicated (RecordingsListView, SessionDetailView, RecordCustomMelodySheet, StatisticsDashboardView) — candidate for a shared DesignSystem enum.
- Full plan with 14 TODOs (T1–T14, P0–P3) at docs/plans/view-restructuring.md.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `docs/plans/view-restructuring.md` | +145 (new) | Ranked skills research, audit table, 14-task restructuring plan; T14 marked done |
| `docs/sessions/2026-11-04-view-restructuring-plan.md` | +34 (new) | This session fragment |
| `AGENTS.md` | +15 | New "AI Skills (Installed)" section: vendored skills, pinned commits, conflict policy, trace consent rules |
| `CLAUDE.md` | +15 | Same "AI Skills (Installed)" section mirrored (file is a manual duplicate of AGENTS.md) |
| `.claude/skills/swiftui-expert-skill/` | +564K (new) | AvdLee SwiftUI Expert skill: SKILL.md + 33 references + Instruments trace scripts + LICENSE (assets excluded) |
| `.claude/skills/swiftui-view-refactor/` | +24K (new) | Dimillian view-refactor skill: SKILL.md + mv-patterns reference + LICENSE |
| `.claude/skills/swiftui-performance-audit/` | +44K (new) | Dimillian performance-audit skill: SKILL.md + 6 references + LICENSE |

### Architecture Decisions
- **SessionManager stays in this feature** (user decision 2026-11-04): decomposition is T3, split along its own MARK seams — `SessionRecordingController` (lifecycle), `RealtimeDetectionTracker` (event/speech state + real-time processing), `SessionAnalysisPipeline` (stop-time processing) — with `SessionManager` kept as a thin `@MainActor @Observable` facade so callers don't change.
- **DesignSystem placement preserved**: SleepStageBreakdownView stays in DesignSystem (used by Statistics + Recordings — the duplication rule mandates it); only split into section structs.
- **No ViewModels introduced**: plan enforces the project's view-is-viewmodel rule; extracted types are presentational structs + @Observable services via @Environment.

### Build Status
- Not applicable — research/planning session only. No source changes.

### Suggested Branch
`feature/f18/view-restructuring` (planning doc only; T1 branch: `feature/f18/t1-player-sheet-split`)

### Suggested Commit
`[F18] — View restructuring plan: ranked SwiftUI skills research + 14-task audit-backed TODO`

### Changes done
```
- docs/plans/view-restructuring.md — ranked skills (AvdLee/Dimillian/Hudson), audit of 14 oversized view files, T1–T14 plan
- docs/sessions/2026-11-04-view-restructuring-plan.md — session log
```

### Next Session
- F18-T1: PlayerSheetView split — LegacyClipPlayer into AudioEngine, shared AudioClipExtractor.exportClip, PlayerLoadState enum, 4 presentational structs (highest LOC + tightest coupling).

### Open Questions
- None — both planning decisions resolved (skills installed as T14; SessionManager decomposition confirmed as T3 in this feature).
