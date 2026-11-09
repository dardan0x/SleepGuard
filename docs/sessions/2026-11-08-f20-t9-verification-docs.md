
### Completed
- F20-T9 (partial): ran the verification checks, did the real save/delete snapshot check deferred from T3, and wrote the feature doc + architecture section. Merged `main` into the F20 branch to pick up the recording-crash fix.

### Technical Details
- **Checks**: `check-layering.py` passed (304 files). Hardcoded-string grep: only numeric interpolations, plus one concatenation of two localized strings in the rectangular accessory. Computed-view grep: only `body`. Widget files ≤75 lines.
- **Tests**: Models 10 tests / 14 cases pass via `xcodebuild test -scheme Models` on BD630AD5 (`swift test` builds for macOS and fails on SwiftData availability). The app scheme has no test bundle. `BriefingEngineTests` (Personalization) doesn't compile on `main`: `ScoreTrend` isn't `Equatable`. Not F20.
- **Crash found**: Start Recording trapped in `AudioRecorder.startRecording`'s `installTap` closure (`_dispatch_assert_queue_fail` on `RealtimeMessenger.mServiceQueue`; backtrace via `lldb -p`). The closure inherited `@MainActor` isolation after F17-T3 moved AudioEngine to Swift 6. The user had already fixed it on `main` (PR #97, `TapProcessor`).
- **Picking up the fix**: first tried rebasing T9 onto `origin/main`; its PR then conflicted with `feature/f20-home-screen-widgets` (rebased copies of the same commits). Rebuilt T9 as `feature/f20-home-screen-widgets` + merge of `origin/main` (no conflicts) + the T9 docs commit. The resulting files are identical to the rebased version.
- **Save/delete check** (simulator, real recording): `sleepguard://start` → Start Recording (no crash) → 2:16 → Save → background. Snapshot `lastNight` = the new session (score 100), today's day added (100), oldest day dropped. Last Night small/medium showed 100 · 2 mins; Trend 83 (586/7). Tap on medium → that session's detail. Delete → background → snapshot back to last night 82 with the oldest day restored.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `docs/features/f20-home-screen-widgets.md` | new | Feature doc: widgets, files, routes, state, edge cases, follow-up |
| `docs/ProjectArchitecture.md` | +7 | Widgets (F20) section |
| `docs/trackers/f20-home-screen-widgets.md` | — | T3 save/delete criterion checked; T9 In Progress with notes |
| `docs/FeatureTracker.md` | — | Currently active T8/T9; activity log |
| `docs/sessions/2026-11-08-f20-t9-verification-docs.md` | new | This fragment |

### Architecture Decisions
- **Merge `main` instead of rebasing**: keeps the per-task PR flow into `feature/f20-home-screen-widgets` and rewrites no merged history. The feature branch then merges into `main` without conflicts.

### Build Status
- **BUILD SUCCEEDED**: zero errors, zero warnings with the `main` fix included.

### Changes done
```
- Add F20 feature doc
- Add Widgets section to ProjectArchitecture
- Check the T3 save/delete criterion (verified with a real recording)
- Update F20 tracker (T9) and FeatureTracker
- Add session fragment
```

### Next Session
- F20-T8: manual Lock Screen check (circular, rectangular, inline). Then mark T8 + T9 Done, F20 9/9, update counts.
- Merge F20 to `main`.

### Open Questions
- Pre-existing: `BriefingEngineTests` doesn't compile (`ScoreTrend` needs `Equatable`). Fix separately?
- Carry-overs: briefing covering deep-linked screens; widget background color; empty-state string key naming.
