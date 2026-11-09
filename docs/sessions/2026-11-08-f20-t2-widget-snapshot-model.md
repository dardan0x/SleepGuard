### Completed
- F20-T2: Foundation-only widget data layer in `Packages/Models/Sources/Widget/`: `WidgetSnapshot`, `WidgetSnapshotBuilder`, `WidgetSnapshotStore`, `WidgetDeepLink`. Covered by the package's first test target, `ModelsTests` (10 Swift Testing tests, 14 cases, all pass).

### Technical Details
- **`WidgetSnapshot`** (Codable, Sendable, Equatable, `let`s only): `generatedAt`, `lastNight: Night?`, `recentDays: [Day]`. `Night` = id, start/end, score, snoringDuration, plus computed `totalDuration` / `snoringPercentage` (same formula as `SleepSession.snoringPercentage`). `Day` = calendar day + average score.
- **`WidgetSnapshotBuilder.make(from:now:calendar:)`**: maps sessions to `Night` using only `hasCachedScore`, `cachedSleepScore`, `cachedSnoringDuration`, `startDate`, `endDate`. It never touches `events`. Skips uncached sessions and sessions without an `endDate`. `lastNight` = latest by `startDate`. `recentDays` reproduces `Last7NightsView.daySummaries`: group by `calendar.startOfDay(startDate)`, integer-average the scores, sort ascending, `suffix(7)`.
- **`WidgetSnapshotStore`**: `appGroupID = "group.com.dardan.SleepGuard"`, `fileURL` = `<group container>/widget-snapshot.json` (nil without the entitlement), `write(_:to:)` (atomic JSON), `read(from:) -> WidgetSnapshot?` (nil on a missing or corrupt file).
- **`WidgetDeepLink`**: `.startTracking` ↔ `sleepguard://start`, `.session(UUID)` ↔ `sleepguard://session/<uuid>`, `.last7Nights` ↔ `sleepguard://last7nights`. `init?(url:)` rejects other schemes, unknown hosts and malformed UUIDs.
- Tests build `SleepSession` `@Model` instances without a container and set cached fields directly. Dates round-trip through `@Model` storage with sub-millisecond drift, so the duration assertion uses a 1 ms tolerance (the first run failed on exact `==`).
- Tests run with `xcodebuild test -scheme Models -destination 'id=BD630AD5-…'` from `Packages/Models` (the app scheme has no testables). The first cold run took ~10 min (fresh derived data); warm reruns take seconds.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Widget/WidgetSnapshot.swift` | +52 (new) | Snapshot, `Night`, `Day` value types |
| `Packages/Models/Sources/Widget/WidgetSnapshotBuilder.swift` | +38 (new) | Sessions → snapshot, cached fields only, Last-7-Nights grouping |
| `Packages/Models/Sources/Widget/WidgetSnapshotStore.swift` | +22 (new) | App Group JSON read/write |
| `Packages/Models/Sources/Widget/WidgetDeepLink.swift` | +33 (new) | `sleepguard://` URL enum |
| `Packages/Models/Tests/ModelsTests/WidgetSnapshotTests.swift` | +129 (new) | Builder, store, deep-link tests |
| `Packages/Models/Package.swift` | +7 | `ModelsTests` test target; explicit `path: "Sources"` on `Models` |
| `docs/trackers/f20-home-screen-widgets.md` | +23/−5 | T2 done, criteria, notes |
| `docs/FeatureTracker.md` | +6/−5 | 2/9, dashboard (96 done), activity log, currently active → T3 |

### Architecture Decisions
- **Mirror `Last7NightsView` grouping** instead of "last 7 sessions": the trend widget and the screen it deep-links to show the same 7 bars.
- **One `Night` type instead of the planned `NightSummary` + `NightScore`**: the trend only needs a day + score, so a separate per-session score type added nothing.
- **Skip uncached sessions** instead of falling back to `sleepScore` (which faults `events`): the writer runs during the background transition, the worst time to hit the known faulting crash. Tradeoff: a legacy uncached session may appear in the app but not in the widget.
- **Explicit `path: "Sources"`**: Models kept its sources directly under `Sources/` through SwiftPM's single-target fallback, which stops applying once a test target exists.
- **Store takes an explicit URL**: testable without App Group entitlements; callers pass `WidgetSnapshotStore.fileURL`.

### Build Status
- **BUILD SUCCEEDED**: app scheme, zero errors, zero warnings.
- **TEST SUCCEEDED**: `ModelsTests` 10/10 (14 cases).
- Layering check passed (224 files). No UI imports in `Models/Sources/Widget`.

### Changes done
```
- Add WidgetSnapshot (last night + 7 calendar-day averages)
- Add WidgetSnapshotBuilder (cached fields only, mirrors Last 7 Nights grouping)
- Add WidgetSnapshotStore (App Group JSON read/write)
- Add WidgetDeepLink (sleepguard://start, /session/<id>, /last7nights)
- Add ModelsTests target with 10 tests; pin Models target path
- Update F20 tracker, FeatureTracker; add session fragment
```

### Next Session
- F20-T3: `SleepGuard/WidgetSnapshotWriter.swift` fetches recent sessions, builds and writes the snapshot, and calls `WidgetCenter.reloadAllTimelines()` on `.background` and at launch.

### Open Questions
- Notion: sync F20 tasks, or local trackers only?
- Confirm F20 is the right feature number (no F18 tracker exists locally).
