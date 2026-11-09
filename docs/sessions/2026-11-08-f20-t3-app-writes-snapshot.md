
### Completed
- F20-T3: the app writes the widget snapshot to the App Group and reloads widget timelines at launch and whenever it goes to the background.

### Technical Details
- **`SleepGuard/WidgetSnapshotWriter.swift`** (app target, MainActor by default): `update(modelContext:)` fetches `SleepSession` with `#Predicate { $0.hasCachedScore && $0.endDate != nil }`, sorted by `startDate` desc, `fetchLimit = 50` (covers the 7 most recent days with sessions), then calls `WidgetSnapshotBuilder.make(from:)`, `WidgetSnapshotStore.write(_:to: fileURL)`, `WidgetCenter.shared.reloadAllTimelines()`. Returns early if the App Group container is unavailable. Errors are `print`ed (matches the existing `[SleepGuardApp]` logging style).
- **Hooks in `SleepGuardApp.swift`**: the end of the existing `.onAppear` (launch) and a `.background` branch in the existing `.onChange(of: scenePhase)`. Both use `sharedModelContainer.mainContext`, whose fetches include pending (not yet autosaved) inserts and deletes.
- **Verification on simulator BD630AD5** (launched with `-generateMockData`): the snapshot decoded to last night 2026-11-06 23:00 → 11-07 06:46 UTC, score 89, 53 min snoring, plus 7 day averages (79, 83, 78, 54, 75, 83, 89). Nov 2, which has no session, is absent, matching Last 7 Nights.
- **Background path debugging**: the first `simctl launch com.apple.Preferences` did not trigger a write. A temporary `print` in the `scenePhase` handler showed active → inactive → background on the next run, and the file was rewritten on 3/3 background transitions. The first miss most likely happened because the freshly launched (mock-data-generating) app was backgrounded before it reached `.active`. The debug print was removed before staging.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/WidgetSnapshotWriter.swift` | +28 (new) | Fetch → build → write → reload timelines |
| `SleepGuard/SleepGuardApp.swift` | +5 | Call the writer at launch and on `.background` |
| `docs/trackers/f20-home-screen-widgets.md` | +20/−4 | T3 done, notes, save/delete check deferred to T9 |
| `docs/FeatureTracker.md` | +6/−5 | 3/9, dashboard (97 done), activity log, currently active → T4 |

### Architecture Decisions
- **Single write point on `.background`** instead of hooking the 5 session insert/delete sites across 4 packages: widgets can't be seen while the app is foregrounded, so this covers save, delete, storage cleanup and mock data with a 5-line app change, and no feature package gains WidgetKit.
- **Writer lives in the app target** (the composition root): it's the only place that holds the `ModelContainer` and may import WidgetKit; `Models` stays Foundation-only.
- **`fetchLimit = 50` instead of fetching all sessions**: bounds the work during the background transition; only misses data if a user records more than 7 sessions per day.

### Build Status
- **BUILD SUCCEEDED**: zero errors, zero warnings. Layering check passed (224 files).

### Not included in this commit
- `SleepGuard.xcodeproj/project.pbxproj` has an unstaged change made by Xcode, not by this task: it re-sorted the T1 entries (no-op) and added another self-referencing `SleepGuard.xcodeproj` project reference (`CE0984E3…`), like the existing junk ones (`CE1472B6…`, `CE1563D5…`, `CE15643C…`). Left for the user to discard or commit.

### Changes done
```
- Add WidgetSnapshotWriter (fetch cached sessions → snapshot → App Group → reload timelines)
- Call it from SleepGuardApp at launch and on scenePhase .background
- Update F20 tracker, FeatureTracker; add session fragment
```

### Next Session
- F20-T4: register the `sleepguard://` URL scheme, add `TabCoordinator.pendingDeepLink`, handle `.onOpenURL` in `SleepGuardApp`, and route in `StatisticsTab` (start → `.liveSession`, session → `.sessionDetail`, last7nights → `.last7Nights`).

### Open Questions
- Discard or commit the Xcode-generated pbxproj self-reference? (Several pre-existing ones could be cleaned up in a separate chore.)
- Notion: sync F20 tasks, or local trackers only?
