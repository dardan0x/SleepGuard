# F20 — Home Screen & Lock Screen Widgets

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Version** | V5 |
| **Blocked By** | — |
| **Started** | 2026-11-08 |
| **Completed** | — |
| **Feature Doc** | — |
| **Branch** | `feature/f20-home-screen-widgets` (each task merges here; merges to `main` after T9) |

## Summary

Users can add SleepGuard widgets to the Home Screen and Lock Screen: last night's sleep score and snoring time, a 7-night score trend, and a one-tap Start Tracking tile. The app writes a small JSON snapshot to an App Group when it goes to the background, and the widgets read it. The SwiftData store doesn't move. Tapping a widget deep-links into the matching screen.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F20-T1 | Widget extension target + App Group | Infra | Done | — | App / SleepGuardWidgets | 2026-11-08 | 2026-11-08 |
| F20-T2 | Snapshot model, store, builder, deep-link enum | Model | Done | F20-T1 | Models | 2026-11-08 | 2026-11-08 |
| F20-T3 | App writes snapshot + reloads timelines | Service | Done | F20-T2 | App | 2026-11-08 | 2026-11-08 |
| F20-T4 | `sleepguard://` deep links | Navigation | Done | F20-T2 | App / Env | 2026-11-08 | 2026-11-08 |
| F20-T5 | Last Night widget (small + medium) | UI | Done | F20-T3, F20-T4 | SleepGuardWidgets | 2026-11-08 | 2026-11-08 |
| F20-T6 | 7-Night Trend widget (medium) | UI | Done | F20-T5 | SleepGuardWidgets | 2026-11-08 | 2026-11-08 |
| F20-T7 | Start Tracking widget (small) | UI | Done | F20-T4 | SleepGuardWidgets | 2026-11-08 | 2026-11-08 |
| F20-T8 | Lock Screen accessories | UI | In Progress | F20-T5 | SleepGuardWidgets | 2026-11-08 | — |
| F20-T9 | Verification, docs, merge to main | Docs | In Progress | F20-T1…T8 | — | 2026-11-08 | — |

## Task Details

### F20-T1 — Widget extension target + App Group

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/modules.md` |
| Status | Done |
| Started | 2026-11-08 |
| Completed | 2026-11-08 |

**Acceptance Criteria:**
- [x] `SleepGuardWidgetsExtension` target is created and embedded in SleepGuard
- [x] App Group `group.com.dardan.SleepGuard` is on both the app and extension entitlements
- [x] Extension: iOS 17.6, Swift 6.0, `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (same as the app)
- [x] Extension links `Models` + `DesignSystem`; the placeholder uses `Strings` + `Theme`
- [x] Extension is registered with WidgetKit on the simulator (`pluginkit`)
- [x] Builds with zero errors and zero warnings

**Notes:**
- The user created the target and App Groups in the Xcode GUI. The AI then patched `project.pbxproj` (settings + package product deps) with a scripted, count-asserted replace and checked it with `plutil -lint`.
- Kept Xcode's bundle ID `com.dardan.SleepGuard.SleepGuardWidgets` (the plan said `.Widgets`) to avoid registering a second App ID.
- The extension's `MARKETING_VERSION` was aligned to `1.0.0` to fix the "extension version must match parent app" warning.
- Xcode put `SleepGuardWidgetsExtension.entitlements` at the repo root. It stays there; moving it would also require changing `CODE_SIGN_ENTITLEMENTS`.
- The placeholder widget (kind `LastNightWidget`) is replaced in T5. Added strings `widget.lastNight.name` / `widget.lastNight.description` (kept for T5).

---

### F20-T2 — Snapshot model, store, builder, deep-link enum

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/networking.md` (data model conventions) |
| Status | Done |
| Started | 2026-11-08 |
| Completed | 2026-11-08 |

**Acceptance Criteria:**
- [x] `WidgetSnapshot`, `WidgetSnapshotStore`, `WidgetSnapshotBuilder`, `WidgetDeepLink` in `Packages/Models/Sources/Widget/`
- [x] Builder reads only cached fields (never `events`) and skips uncached sessions
- [x] Unit tests: builder edge cases, deep-link round-trip, store encode/decode (10 tests / 14 cases, all pass)
- [x] Builds with zero errors

**Prompt Used:**
"continue with next task, create new branch based from feature/f20-home-screen-widgets"

**Notes:**
- Snapshot shape differs from the plan: one `Night` type (last session) plus `Day` (calendar-day average score), instead of `NightSummary` + `NightScore`. `recentDays` mirrors `Last7NightsView.daySummaries` exactly (group by `startOfDay(startDate)`, average score, last 7 days with sessions), so widget and app always agree.
- Dropped the planned `minimumSaveDuration` filter: saved sessions already passed it, so it guarded an impossible case.
- `WidgetSnapshotStore` takes an explicit URL (`fileURL` is the App Group default and is `nil` without the entitlement), so tests use a temp file.
- Deep links: `sleepguard://start`, `sleepguard://session/<uuid>`, `sleepguard://last7nights`.
- `Models` gained its first test target (`ModelsTests`, Swift Testing). The `Models` target now declares `path: "Sources"`, because SwiftPM's single-target fallback no longer applies once a second target exists.
- Known divergence: a legacy session with `hasCachedScore == false` shows in the app (score computed by faulting `events`) but is skipped by the widget. This is intentional, to avoid the faulting crash path.

### F20-T3 — App writes snapshot

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/dependencies.md` (app target = composition root) |
| Status | Done |
| Started | 2026-11-08 |
| Completed | 2026-11-08 |

**Acceptance Criteria:**
- [x] Snapshot is written on `.background` and at launch; `WidgetCenter.reloadAllTimelines()` is called
- [x] JSON in the App Group container matches the latest sessions after save/delete. Verified in T9 with a real 2-min recording: save → snapshot + widgets updated; delete → reverted
- [x] Builds with zero errors

**Prompt Used:**
"i commited and pushed and opened merge myself, continue with next task"

**Notes:**
- `SleepGuard/WidgetSnapshotWriter.swift` (app target): `FetchDescriptor<SleepSession>` with predicate `hasCachedScore && endDate != nil`, sorted by `startDate` desc, `fetchLimit = 50` → `WidgetSnapshotBuilder` → `WidgetSnapshotStore.write` → `WidgetCenter.shared.reloadAllTimelines()`. Errors are printed and never thrown into UI.
- Uses `mainContext`: fetches include pending (not yet autosaved) changes, so a session saved just before backgrounding is captured.
- Hooked into the existing `SleepGuardApp` `.onAppear` (launch) and `.onChange(of: scenePhase)` (`.background`). No changes to the 5 insert/delete sites.
- Verified on simulator BD630AD5 with `-generateMockData`: JSON decoded to last night 2026-11-06 (score 89) + 7 day averages, with the session-less day (Nov 2) correctly absent. A temporary `scenePhase` print confirmed active → inactive → background, and the file was rewritten on each background (3/3); the print was removed. The very first background attempt didn't write, most likely because it landed before the freshly launched app reached `.active`. Not reproducible afterwards.

### F20-T4 — Deep links

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/navigation.md` |
| Status | Done |
| Started | 2026-11-08 |
| Completed | 2026-11-08 |

**Acceptance Criteria:**
- [x] `sleepguard://` scheme is registered; `.onOpenURL` → `TabCoordinator.pendingDeepLink`
- [x] Start → `.liveSession`, session → `.sessionDetail(id:)`, trend → `.last7Nights`
- [x] Ignored during onboarding; deleted session and hidden Statistics tab are handled (deleted session verified on simulator; onboarding + hidden tab are code guards, not exercised at runtime)
- [x] Builds with zero errors

**Prompt Used:**
"continue where we left on with tasks and as usual dont commit without asking me first"

**Notes:**
- Flow: `SleepGuardApp.onOpenURL` (guard `hasCompletedOnboarding`) → `TabCoordinator.open(_:)` (guard Statistics tab visible, select it, set `pendingDeepLink`) → `StatisticsTab.routePendingDeepLink()` on `onAppear` + `onChange(of: pendingDeepLink)` → `DeepLinkRouter.route` (app target).
- The link is consumed (set to `nil`) first, then dropped if recording or a sheet is presented, so an unsaved session summary is never replaced. Seen live: a crash-recovered summary sheet was up and the link was correctly ignored.
- Router pops to root before pushing, so a link always lands one level deep.
- Unknown/deleted session ID → `fetchCount` is 0 → stays on the dashboard root.
- Hidden Statistics tab → link ignored, the app just opens (Sessions tab has no start/summary flow, so no fallback tab).
- Verified on simulator BD630AD5 via `simctl openurl`: last7nights (warm + cold launch), session (real ID from snapshot), zero UUID → dashboard, start from the Sessions tab → switches to Statistics + live session screen.

### F20-T5 — Last Night widget

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-08 |
| Completed | 2026-11-08 |

**Acceptance Criteria:**
- [x] Small + medium layouts reuse `SleepScoreGauge`, `DurationFormatter`, `Theme`
- [x] Empty state → start-tracking link; otherwise → session link
- [x] Extension memory fits the widget budget with `DesignSystem` linked (24 MB peak on the simulator, Debug; limit ~30 MB. Re-check on a device in T9)
- [x] Builds with zero errors

**Prompt Used:**
"continue with next task"

**Notes:**
- No widget design exists in `designs/SleepGuard.pen` (user confirmed). Layout built from existing components + tokens; background `bg-secondary` (#1C1C1E).
- The T1 placeholder was replaced in place in `SleepGuardWidgets.swift` (kind `LastNightWidget` kept, so already-placed widgets survive). Views are split: `LastNightWidgetView` (family switch, `containerBackground`, `widgetURL`, shared `LastNightLabel`), `LastNightSmallView`, `LastNightMediumView` (+ `LastNightStatRow`), `LastNightEmptyView`.
- Provider: reads `WidgetSnapshotStore` and uses timeline policy `.never` (the app reloads timelines on write). The gallery preview falls back to sample data when there's no night yet.
- `SleepScoreGauge`'s `onAppear` animation isn't a problem: WidgetKit renders the ring filled.
- Verified on simulator BD630AD5 Home Screen: small + medium with real data (82 · 7h 23 mins · 51 mins · 12%) → tap opens the matching session detail; empty snapshot → "No nights yet" in both sizes → tap cold-launches into the live session screen.
- Seen: when the Sleep Briefing is due, it appears on top of the deep-linked screen (the push happens underneath). This is existing briefing behavior, not changed here.
- 5 new strings: `widget.lastNight.label/slept/snoring/empty.title/empty.action`.

### F20-T6 — 7-Night Trend widget

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-08 |
| Completed | 2026-11-08 |

**Acceptance Criteria:**
- [x] Medium layout with `MiniBarChart` + average; empty state; tap → `.last7Nights`
- [x] Builds with zero errors

**Prompt Used:**
"continue with other tasks now"

**Notes:**
- `TrendWidget` (kind `TrendWidget`, medium only) + `TrendWidgetView`. Left: "LAST 7 NIGHTS" caption, average (44pt rounded, `scoreColor`), "avg sleep score" (reuses `stats.last7Nights.avgSleepScore`). Right: `MiniBarChart` with weekday-initial labels + `scoreColor` bars, built exactly like `StatisticsMiniChartSection`.
- The average uses the same integer division over day averages as `Last7NightsView.averageSleepScore`. Verified: widget 79 = app 79.
- Empty (`recentDays` empty) → `WidgetEmptyView`, tap → start tracking (not Last 7 Nights, which would be empty too). Consistent with Last Night.
- Refactor (duplication rule): the provider moved from `LastNightProvider`/`LastNightEntry` to a shared `WidgetSnapshotProvider`/`SnapshotEntry` (whole snapshot + `WidgetSnapshot.sample`/`.empty`). `LastNightEmptyView` was renamed to `WidgetEmptyView`. `LastNightWidgetView` now takes `night:`. Last Night re-checked in the gallery after the refactor.
- The empty view still uses the `widget.lastNight.empty.*` string keys (not renamed, to avoid xcstrings churn).
- Extension still 24 MB peak with two widgets.

### F20-T7 — Start Tracking widget

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | Done |
| Started | 2026-11-08 |
| Completed | 2026-11-08 |

**Acceptance Criteria:**
- [x] Small tile styled like `StartRecordingButton`; tap → `.liveSession`
- [x] Builds with zero errors

**Prompt Used:**
"continue with next tasks"

**Notes:**
- `StartTrackingWidget` (kind `StartTrackingWidget`, small) + `StartTrackingWidgetView` in one file (37-line view, no state).
- Styling: the record dot (44pt halo at 25% + 22pt solid, static because widgets can't animate the pulse) + `Strings.actionStartRecording` (17pt semibold, reused) over `bg-secondary` with a `score-red` 35% → 0 top-to-center gradient, echoing the button's red glow. Uses tokens (`scoreRed` = #FF453A) instead of the button's hardcoded hex values and its non-token `#22232B` fill.
- No interactive `Button` (that would need App Intents); the whole tile is the `widgetURL`.
- Reuses `WidgetSnapshotProvider` (ignores the entry) instead of adding a dedicated static provider: zero extra code, and the snapshot read is a tiny file.
- Verified on simulator BD630AD5: gallery page 4/4, placed on the Home Screen, tap → live session pre-start screen.
- 2 new strings: `widget.start.name`, `widget.start.description`.

### F20-T8 — Lock Screen accessories

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/views.md` |
| Status | In Progress (code done; Lock Screen render unverified) |
| Started | 2026-11-08 |
| Completed | — |

**Acceptance Criteria:**
- [ ] `accessoryCircular`, `accessoryRectangular`, `accessoryInline` render correctly in vibrant mode (**not verified**: couldn't lock the simulator via automation; needs a manual check)
- [x] Builds with zero errors

**Prompt Used:**
"continue with next tasks"

**Notes:**
- Added to the existing `LastNightWidget` (no new widget kind): `.supportedFamilies` now includes the 3 accessory families. `LastNightWidgetView` switches on `widgetFamily` first; the accessory views handle `night == nil` themselves.
- `LastNightCircularView`: `Gauge(score, 0...100)` with `.accessoryCircularCapacity`, the score as the current value, `widgetAccentable()`. Empty: `AccessoryWidgetBackground` + moon.
- `LastNightRectangularView`: "Last Night" (headline, accentable) / score (title2 bold) + "SLEEP SCORE" / "Snoring 51 mins · 12%". Empty: "No nights yet" / "Tap to start tracking".
- `LastNightInlineView`: `Label` with moon + `widget.lastNight.inline` ("Score %@ · %@ snoring"). Empty: "No nights yet".
- No Theme colors in the accessory views (vibrant mode is monochrome). Tap targets come from the shared `widgetURL` (session / start).
- Verification blocker: 3 simulators are booted, and the Simulator "Device → Lock" menu item (via AppleScript, even after raising the iPhone 16e window) didn't lock BD630AD5. Stopped after 2 attempts.

### F20-T9 — Verification, docs, merge

| Field | Value |
|-------|-------|
| Status | In Progress (docs + checks done; waiting on the T8 Lock Screen check and the merge) |
| Started | 2026-11-08 |
| Completed | — |

**Acceptance Criteria:**
- [x] Tests, layering check, hardcoded-string grep, computed-view grep all pass (Models 10 tests / 14 cases; the app scheme has no tests; `BriefingEngineTests` doesn't compile on `main` and isn't F20's)
- [x] Manual simulator pass of every Home Screen widget + tap target (Lock Screen still open under T8)
- [x] Feature doc, session fragment, architecture notes
- [ ] Feature branch merged to `main`

**Prompt Used:**
"go to t9" / "i already pushed the fix for this in main. Can you rebase and use this fix?"

**Notes:**
- The first save attempt crashed on Start Recording (`_dispatch_assert_queue_fail` in the `AudioRecorder` input tap, a Swift 6 isolation trap introduced with F17-T3). Not F20; the user fixed it on `main` (PR #97, `TapProcessor`). `main` was merged into the F20 branch (merge commit on the T9 branch, no conflicts) to bring in the fix.
- Real save/delete check (deferred from T3): a 2-min recording started from `sleepguard://start` → saved → backgrounded → snapshot `lastNight` = the new session (100), today's day added, oldest dropped. Last Night small/medium showed 100 / 2 mins; Trend average 83 (= 586 / 7, integer division) with today's bar. Tap on medium → that session's detail. Deleted it → backgrounded → snapshot back to last night 82, the oldest day restored.
- A first attempt rebased T9 onto `main`, which conflicted with `feature/f20-home-screen-widgets` (duplicated commits). It was rebuilt as feature branch + merge of `main` + the T9 docs commit, so the T9 PR targets `feature/f20-home-screen-widgets` as usual.
