---
date: 2026-11-04
feature: f18
branch: feature/f18/t1-player-sheet-split
title: F18-T1 PlayerSheetView Split
---

### Completed
- **F18-T1**: PlayerSheetView split 572 → 178 lines, on branch
  `feature/f18/t1-player-sheet-split` (commit `861fbc4`), pushed for manual
  merge into `feature/f18/view-restructuring`.

### Technical Details
- `LegacyClipPlayer` (@MainActor @Observable, AudioEngine): owns legacy
  single-event export + AVAudioPlayer playback + 100 ms progress loop.
  Export reuses the pre-existing `AudioClipExtractor.extractSingleClip`
  (10-param overload); the convenience `for:` overload takes the SnoreEvent
  @Model directly and cannot be called cross-isolation under Swift 6 strict —
  callers must destructure Sendable fields (`id`, `timestamp`, `snoreDuration`,
  `bursts`) first, per AGENTS.md concurrency rules.
- `WaveformLoader` (@State-owned @Observable, Recordings/Helpers): waveform
  sampling with event-clip-first / session-export-fallback; replaces ~55 lines
  of in-view export+generation logic.
- `PlayerLoadState` enum (`loading` / `ready` / `noAudio(SnoreEvent?)`)
  replaces `isReady`+`didFinishInitialLoad`+`hasLoadingTimedOut` boolean soup.
  Timeout semantics preserved: 3 s control-readiness, 10 s skeleton safety
  that pessimistically flips to `.noAudio` and is overwritten when the export
  completes ("branch-2-wins" parity with the old if-chain). Uses
  `case .loading` pattern matching (enum not Equatable — associated
  non-Equatable class).
- Extracted structs (one per file): PlayerEventRow, PlayerEventListSection,
  EnhancedAudioToggleSection, PlayerLoadingSkeleton, NoAudioView,
  ClipPlayerContent, LegacyPlayerContent — narrow inputs, presentational.
- Two `AVAssetExportSession` implementations (~90 lines of duplication)
  deleted; both call sites now go through AudioClipExtractor.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/LegacyClipPlayer.swift` | +105 (new) | Legacy export+playback engine |
| `Packages/Recordings/Sources/Helpers/WaveformLoader.swift` | +68 (new) | Waveform loading orchestrator |
| `Packages/Recordings/Sources/Views/PlayerSheetView.swift` | −394/+178 | Rewritten: state enum, thin composer |
| `Packages/Recordings/Sources/Views/ClipPlayerContent.swift` | +61 (new) | Clip-session player content |
| `Packages/Recordings/Sources/Views/LegacyPlayerContent.swift` | +32 (new) | Legacy player content |
| `Packages/Recordings/Sources/Views/PlayerEventRow.swift` | +78 (new) | Event row |
| `Packages/Recordings/Sources/Views/PlayerEventListSection.swift` | +34 (new) | Event list section |
| `Packages/Recordings/Sources/Views/EnhancedAudioToggleSection.swift` | +31 (new) | Enhancement toggle |
| `Packages/Recordings/Sources/Views/PlayerLoadingSkeleton.swift` | +47 (new) | Loading skeleton |
| `Packages/Recordings/Sources/Views/NoAudioView.swift` | +45 (new) | No-audio state |

### Architecture Decisions
- **No new AudioEngine API**: `AudioClipExtractor.extractSingleClip(for:)`
  already existed but is uncallable from MainActor under strict v6 (non-Sendable
  @Model argument). Chose destructuring at call sites over adding a
  Sendable-descriptor overload — zero new API surface, follows project rule.
- **Content structs take the @Observable controller as a plain `let`**:
  observation propagates through stored properties, matching how EventPlayerView
  receives values.

### Build Status
- **BUILD SUCCEEDED** (XcodeBuildMCP build_sim, pinned sim BD630AD5). Two
  errors fixed en route: Sendable boundary (destructure) + Equatable enum
  (`case .loading` match).
- **TESTS NOT RUN — pre-existing gap**: the app project has a single
  `SleepGuard` target and zero unit-test bundles (pbxproj grep: 0); package
  tests aren't in the scheme, so `test_sim` reports "no test bundles
  available". Not caused by this task; recommend a separate chore to wire
  package test targets into a test plan.
- Pre-existing warning (MainTabView.swift:207 unused `latestSession`) left
  untouched — T4 territory.

### Suggested Branch
`feature/f18/t1-player-sheet-split` (pushed)

### Suggested Commit
`861fbc4` — `[F18-T1] — PlayerSheetView split (572 → 178 lines)`

### Changes done
```
- AudioEngine/LegacyClipPlayer.swift (new)
- Recordings/WaveformLoader.swift (new)
- Recordings/PlayerSheetView.swift (rewritten, 572→178)
- Recordings/{ClipPlayerContent,LegacyPlayerContent,PlayerEventRow,PlayerEventListSection,EnhancedAudioToggleSection,PlayerLoadingSkeleton,NoAudioView}.swift (new)
- docs: T1 checked off in docs/plans/view-restructuring.md
```

### Next Session
- User merges PR #? (compare link below) into `feature/f18/view-restructuring`,
  then F18-T2: SessionDetailView split (SessionShareCoordinator + marker helper)
  on `feature/f18/t2-session-detail-split`.

### Open Questions
- Pre-existing uncommitted `project.pbxproj` change (nested
  `SleepGuard/SleepGuard.xcodeproj` subproject reference missing its pbxproj)
  still present on the integration branch — decide keep/revert separately.
- Wire package unit tests into the app scheme? (test gate currently vacuous)
