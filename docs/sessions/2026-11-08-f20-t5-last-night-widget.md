

### Completed
- F20-T5: Last Night widget in small and medium sizes, with an empty state, driven by the App Group snapshot. It replaces the T1 placeholder.

### Technical Details
- **Provider** (`LastNightProvider`, `TimelineProvider`): `WidgetSnapshotStore.fileURL.flatMap(read)` → `LastNightEntry(date:night:)`. Timeline policy `.never`, because the app calls `reloadAllTimelines()` after every snapshot write (T3). `getSnapshot` returns `Night.sample` only when `context.isPreview` and no night exists, so the gallery never shows an empty widget.
- **Small**: "LAST NIGHT" caption → `SleepScoreGauge(size: 84)` → slept duration (`DurationFormatter.hoursAndMinutes`).
- **Medium**: `SleepScoreGauge(size: 116)` + caption, date (`.dateTime.weekday(.abbreviated).month(.abbreviated).day()`), "Slept" and "Snoring" rows. Snoring value = duration · rounded %.
- **Empty**: `moon.zzz.fill` (accent) + "No nights yet" + "Tap to start tracking".
- **Tap targets**: `.widgetURL` = `WidgetDeepLink.session(id)` when a night exists, otherwise `.startTracking` (routes from T4).
- **Background**: `containerBackground(theme.bgSecondary, for: .widget)`.
- **Simulator verification (BD630AD5)**: both sizes added via Home Screen → Edit → Add Widget. Real data matched the app's session detail (82, 7:23:14, 12%, 51:44). Tapping medium → session detail. I wrote an empty snapshot and reinstalled the app without launching it, which made WidgetKit reload: both sizes showed the empty state, and the tap cold-launched into the live session screen. The extension's `footprint` peak was 24 MB.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuardWidgets/SleepGuardWidgets.swift` | rewritten (68) | Placeholder → `LastNightEntry`, `LastNightProvider`, `LastNightWidget` (small + medium), `Night.sample`, previews |
| `SleepGuardWidgets/SleepGuardWidgetsBundle.swift` | ±1 | Bundle registers `LastNightWidget` |
| `SleepGuardWidgets/LastNightWidgetView.swift` | +44 (new) | Family/empty switch, background, `widgetURL`, `LastNightLabel`, `Night` text helpers |
| `SleepGuardWidgets/LastNightSmallView.swift` | +20 (new) | Small layout |
| `SleepGuardWidgets/LastNightMediumView.swift` | +44 (new) | Medium layout + `LastNightStatRow` |
| `SleepGuardWidgets/LastNightEmptyView.swift` | +24 (new) | Empty state |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` | +5 | Widget strings |
| `Packages/DesignSystem/Sources/Resources/Localizable.xcstrings` | generated | 5 new keys |
| `Packages/DesignSystem/Sources/Strings.swift` | generated | 5 new accessors |
| `docs/trackers/f20-home-screen-widgets.md`, `docs/FeatureTracker.md` | — | T5 done, 5/9, currently active → T6 |

### Architecture Decisions
- **No .pen design**: the user confirmed none exists for widgets. The layout reuses in-app components and design tokens so the widget reads as the same product. Screenshots are the review artifact.
- **Kept widget kind `LastNightWidget`** from T1, so a placeholder already on someone's Home Screen turns into the real widget instead of breaking.
- **Static `TimelineProvider`, no App Intents**: there's nothing to configure, and the app drives reloads, so a time-based refresh isn't needed.
- **Formatting helpers as a `WidgetSnapshot.Night` extension in the widget target**: `Models` stays free of DesignSystem (`DurationFormatter` and `Strings` are UI).

### Build Status
- **BUILD SUCCEEDED**: zero errors, zero warnings. Layering check passed (304 files). Hardcoded-string grep: none. No computed `some View` properties besides `body`. All widget files are ≤ 68 lines.

### Not included in this commit
- `SleepGuard.xcodeproj/project.pbxproj`: Xcode added yet another self-referencing project reference (`CE0986BE…`) and re-sorted the references. This task didn't make that change, so it stays unstaged.

### Changes done
```
- Replace T1 placeholder with LastNightWidget (small + medium), snapshot-driven provider
- Add small, medium and empty-state views; reuse SleepScoreGauge, DurationFormatter, Theme
- Widget taps deep-link to the session, or to start tracking when empty
- Add 5 widget strings (Strings.txt → xcstrings → Strings.swift)
- Update F20 tracker, FeatureTracker; add session fragment
```

### Next Session
- F20-T6: 7-Night Trend widget (medium) from `snapshot.recentDays` with `MiniBarChart` + average; empty state; tap → `sleepguard://last7nights`.

### Open Questions
- When the Sleep Briefing is due, it covers the deep-linked screen. Should widget-launched opens skip or delay the briefing?
- Widget background: `bg-secondary` (#1C1C1E) chosen. Prefer `bg-primary` (pure black) or `bg-card`?
- The pbxproj self-reference cleanup chore is still pending.
