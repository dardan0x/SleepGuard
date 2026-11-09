### Completed
- F20-T6: 7-Night Trend widget (medium) showing the average score and score-colored day bars from `snapshot.recentDays`. Empty state → start tracking; otherwise tap → Last 7 Nights.

### Technical Details
- **`TrendWidgetView`**: `HStack` of [caption "LAST 7 NIGHTS", average `Text` (44pt bold rounded, `theme.scoreColor`), `Strings.statsLast7nightsAvgSleepScore`] + `MiniBarChart(data:theme:)`. `chartData` maps each `Day` to `DataPoint(label: dayOfWeekShort.prefix(1).uppercased(), value: averageScore, color: scoreColor)`, which is the same construction as `StatisticsMiniChartSection`.
- **Average**: `days.map(\.averageScore).reduce(0, +) / max(days.count, 1)`. That's the same integer math as `Last7NightsView.averageSleepScore`.
- **Shared provider**: `WidgetSnapshotProvider` (`TimelineProvider`, policy `.never`) yields `SnapshotEntry(date:snapshot:)`; a missing file becomes `WidgetSnapshot.empty`. Gallery previews fall back to `WidgetSnapshot.sample` (a night plus 7 sample days) when there's no night yet. Both widgets use it.
- **Simulator verification (BD630AD5)**: the gallery shows 3 pages (Last Night small/medium, Trend). Placed the Trend widget: avg 79, 7 bars labeled S S M W T F S (Oct 31 – Nov 7, Nov 2 has no session). Tap → Last 7 Nights showing avg 79 ✔︎. Empty snapshot + reinstall → "No nights yet" ✔︎. Extension `phys_footprint_peak` 24 MB.
- **Simulator tip**: the ⌘⇧H Home keystroke didn't reach the simulator this time. Launching then terminating `com.apple.Preferences` via `simctl` reliably lands on the Home Screen.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuardWidgets/TrendWidget.swift` | +24 (new) | `TrendWidget` config (medium) + preview |
| `SleepGuardWidgets/TrendWidgetView.swift` | +53 (new) | Trend layout, average, chart data, empty state, `widgetURL` |
| `SleepGuardWidgets/WidgetSnapshotProvider.swift` | +48 (new) | Shared entry/provider, `WidgetSnapshot.empty`/`.sample` |
| `SleepGuardWidgets/SleepGuardWidgets.swift` | −40/+8 | Provider/entry/sample moved out; uses `WidgetSnapshotProvider` |
| `SleepGuardWidgets/LastNightWidgetView.swift` | ±4 | Takes `night:`; uses `WidgetEmptyView` |
| `SleepGuardWidgets/LastNightEmptyView.swift` → `WidgetEmptyView.swift` | rename | Shared empty state |
| `SleepGuardWidgets/SleepGuardWidgetsBundle.swift` | +1 | Registers `TrendWidget` |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` / `Localizable.xcstrings` / `Strings.swift` | +3 keys | `widget.trend.name/description/label` |
| `docs/trackers/f20-home-screen-widgets.md`, `docs/FeatureTracker.md` | — | T6 done, 6/9, currently active → T7 |

### Architecture Decisions
- **Extract the shared provider now**: the second widget would otherwise duplicate the provider verbatim. T7/T8 reuse it too (T8 lock-screen accessories read the same snapshot).
- **Empty trend taps go to start tracking**: Last 7 Nights would also be empty, and starting a night is the only useful action.
- **Medium only**: seven bars plus an average don't fit legibly in small. Matches the plan.

### Build Status
- **BUILD SUCCEEDED**: zero errors, zero warnings (the first attempt failed on a missing `import Models` in `TrendWidget.swift`; fixed). Layering check passed. No hardcoded strings or extra computed `some View` properties.

### Not included in this commit
- `SleepGuard.xcodeproj/project.pbxproj`: Xcode-generated self-reference junk again (verified the diff only touches `SleepGuard.xcodeproj` refs / Products groups).

### Changes done
```
- Add TrendWidget (medium): average score + MiniBarChart from snapshot.recentDays
- Empty state → start tracking; tap → Last 7 Nights
- Extract shared WidgetSnapshotProvider/SnapshotEntry; rename empty view to WidgetEmptyView
- Add 3 widget.trend strings
- Update F20 tracker, FeatureTracker; add session fragment
```

### Next Session
- F20-T7: Start Tracking widget (small), styled like `StartRecordingButton`, tap → `sleepguard://start`. It doesn't need the snapshot, so it can use a trivial static provider (or reuse the shared one).

### Open Questions
- Rename the shared empty-state string keys from `widget.lastNight.empty.*` to `widget.empty.*`? Cosmetic; not done.
- Carry-overs from T5: briefing covering deep-linked screens; widget background color choice.
