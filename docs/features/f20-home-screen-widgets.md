# F20 — Home Screen & Lock Screen Widgets

SleepGuard widgets for the Home Screen and Lock Screen: last night's sleep score and snoring time, a 7-night score trend, and a one-tap Start Tracking tile. The app writes a small JSON snapshot to an App Group at launch and when it goes to the background. The widget extension reads only that file, never the SwiftData store. Tapping a widget opens the matching screen through a `sleepguard://` deep link.

## Widgets

| Widget (kind) | Families | Shows | Tap → |
|---------------|----------|-------|-------|
| Last Night (`LastNightWidget`) | systemSmall, systemMedium, accessoryCircular, accessoryRectangular, accessoryInline | Score gauge, date, slept, snoring (medium); score + slept (small); system gauge / score + snoring / one line (Lock Screen) | `sleepguard://session/<id>`, or `start` when there's no data |
| 7-Night Trend (`TrendWidget`) | systemMedium | Average score + mini bar chart of the last 7 days with sessions | `sleepguard://last7nights`, or `start` when there's no data |
| Start Tracking (`StartTrackingWidget`) | systemSmall | Red record dot + "Start Recording" | `sleepguard://start` |

## Files

| File | Change | Purpose |
|------|--------|---------|
| `SleepGuardWidgets/` (extension target `SleepGuardWidgetsExtension`) | New | Widget bundle, provider, all widget views, assets, Info.plist |
| `SleepGuardWidgets/SleepGuardWidgetsBundle.swift` | New | Registers the 3 widgets |
| `SleepGuardWidgets/WidgetSnapshotProvider.swift` | New | `TimelineProvider`: reads the snapshot (`.never` policy), `.empty` fallback, `.sample` for the gallery |
| `SleepGuardWidgets/SleepGuardWidgets.swift` | New | `LastNightWidget` configuration + previews |
| `SleepGuardWidgets/LastNightWidgetView.swift` | New | Family switch, container background, `widgetURL`; `LastNightLabel`; `Night` text helpers |
| `SleepGuardWidgets/LastNightSmallView.swift`, `LastNightMediumView.swift` | New | Home Screen layouts (reuse `SleepScoreGauge`) |
| `SleepGuardWidgets/LastNightAccessoryViews.swift` | New | Lock Screen circular / rectangular / inline (vibrant-safe, no Theme colors) |
| `SleepGuardWidgets/TrendWidget.swift`, `TrendWidgetView.swift` | New | Trend widget + view (average + `MiniBarChart`) |
| `SleepGuardWidgets/StartTrackingWidget.swift` | New | Start tile (widget + view) |
| `SleepGuardWidgets/WidgetEmptyView.swift` | New | Shared "No nights yet / Tap to start tracking" state |
| `SleepGuardWidgetsExtension.entitlements`, `SleepGuard/SleepGuard.entitlements` | New / + App Group | `group.com.dardan.SleepGuard` on both targets |
| `Packages/Models/Sources/Widget/WidgetSnapshot.swift` | New | Codable snapshot: `lastNight: Night?` + `recentDays: [Day]` |
| `Packages/Models/Sources/Widget/WidgetSnapshotBuilder.swift` | New | Builds the snapshot from cached session fields only |
| `Packages/Models/Sources/Widget/WidgetSnapshotStore.swift` | New | App Group file URL + read/write |
| `Packages/Models/Sources/Widget/WidgetDeepLink.swift` | New | `start` / `session/<uuid>` / `last7nights` ↔ URL |
| `Packages/Models/Tests/ModelsTests/WidgetSnapshotTests.swift`, `Packages/Models/Package.swift` | New / + test target | 10 tests (14 cases): builder, deep links, store |
| `SleepGuard/WidgetSnapshotWriter.swift` | New | Fetch → build → write → `reloadAllTimelines()` |
| `SleepGuard/SleepGuardApp.swift` | Modified | Writes the snapshot at launch and on `.background`; `.onOpenURL` → `TabCoordinator.open` |
| `SleepGuard/Info.plist` | Modified | `CFBundleURLTypes` for `sleepguard` |
| `Packages/Env/Sources/Services/Router.swift` | Modified | `TabCoordinator.pendingDeepLink` + `open(_:)` |
| `SleepGuard/StatisticsTab.swift` | Modified | Consumes `pendingDeepLink` |
| `SleepGuard/DeepLinkRouter.swift` | New | Pops to root, pushes the destination |
| `Packages/DesignSystem/Sources/Resources/Strings.txt` / `Localizable.xcstrings` / `Strings.swift` | Modified | `widget.*` strings (14 keys) |
| `SleepGuard.xcodeproj/project.pbxproj` | Modified | Extension target, embedding, package product deps |

## Routes

| Deep link | Destination | Notes |
|-----------|-------------|-------|
| `sleepguard://start` | Push `.liveSession` (Statistics tab) | Pre-start screen; the user still taps Start Recording |
| `sleepguard://session/<uuid>` | Push `.sessionDetail(id:)` | Stays on the dashboard if the session no longer exists |
| `sleepguard://last7nights` | Push `.last7Nights` | — |

No new `RouterDestination` or `SheetDestination` cases.

## State

| What | Where | Scope |
|------|-------|-------|
| Widget snapshot JSON | App Group container `widget-snapshot.json` | Shared app ↔ extension; rewritten at launch + every `.background` |
| `pendingDeepLink` | `TabCoordinator` (Env) | App-wide, cleared when Statistics tab consumes it |
| Timeline | WidgetKit, policy `.never` | Reloaded by the app after every snapshot write |

## Edge Cases

- **No sessions** → `WidgetEmptyView` / accessory empty states; tap → start tracking. The gallery shows `.sample` data instead.
- **Uncached legacy sessions** (`hasCachedScore == false`) are skipped. The builder never faults `events`, which has crashed before.
- **Deleted session** still shown by a stale widget: the deep link finds no session and stays on the dashboard root.
- **Deep link while recording or while a sheet is up** → dropped, so a live session is never interrupted.
- **Statistics tab hidden** by remote config → link ignored.
- **Before onboarding** → link ignored.
- **Day grouping** matches `Last7NightsView.daySummaries` (calendar day of `startDate`, averaged), so the widget and the app always agree.
- **Lock Screen** renders monochrome. Accessories use system styles (`accessoryCircularCapacity`, `widgetAccentable`) instead of Theme colors.
- **Memory**: extension peak footprint 24–25 MB on the simulator with 3 widgets placed (limit ~30 MB).

## Tasks Completed

F20-T1 … F20-T9 (see `docs/trackers/f20-home-screen-widgets.md`).

## Follow-up

- Lock Screen accessories haven't been checked visually (automation couldn't lock the simulator while 3 were booted).
- On-device memory check of the extension.
- Rectangular accessory joins "Snoring" + duration by concatenation. That's fine in English; a single format string would suit other languages better.
- Carry-overs: the Sleep Briefing sheet can cover the screen a widget opens; widget background color (`bg-secondary`) has no design in `SleepGuard.pen`; empty-state string key naming.
- Pre-existing, not F20: `BriefingEngineTests` doesn't compile (`ScoreTrend` isn't `Equatable`).
