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
| F20-T2 | Snapshot model, store, builder, deep-link enum | Model | Backlog | F20-T1 | Models | — | — |
| F20-T3 | App writes snapshot + reloads timelines | Service | Backlog | F20-T2 | App | — | — |
| F20-T4 | `sleepguard://` deep links | Navigation | Backlog | F20-T2 | App / Env | — | — |
| F20-T5 | Last Night widget (small + medium) | UI | Backlog | F20-T3, F20-T4 | SleepGuardWidgets | — | — |
| F20-T6 | 7-Night Trend widget (medium) | UI | Backlog | F20-T5 | SleepGuardWidgets | — | — |
| F20-T7 | Start Tracking widget (small) | UI | Backlog | F20-T4 | SleepGuardWidgets | — | — |
| F20-T8 | Lock Screen accessories | UI | Backlog | F20-T5 | SleepGuardWidgets | — | — |
| F20-T9 | Verification, docs, merge to main | Docs | Backlog | F20-T1…T8 | — | — | — |

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

**Acceptance Criteria:**
- [ ] `WidgetSnapshot`, `WidgetSnapshotStore`, `WidgetSnapshotBuilder`, `WidgetDeepLink` in `Packages/Models/Sources/Widget/`
- [ ] Builder reads only cached fields (never `events`) and skips uncached sessions
- [ ] Unit tests: builder edge cases, deep-link round-trip, store encode/decode
- [ ] Builds with zero errors

### F20-T3 — App writes snapshot

**Acceptance Criteria:**
- [ ] Snapshot is written on `.background` and at launch; `WidgetCenter.reloadAllTimelines()` is called
- [ ] JSON in the App Group container matches the latest sessions after save/delete
- [ ] Builds with zero errors

### F20-T4 — Deep links

**Acceptance Criteria:**
- [ ] `sleepguard://` scheme is registered; `.onOpenURL` → `TabCoordinator.pendingDeepLink`
- [ ] Start → `.liveSession`, session → `.sessionDetail(id:)`, trend → `.last7Nights`
- [ ] Ignored during onboarding; deleted session and hidden Statistics tab are handled
- [ ] Builds with zero errors

### F20-T5 — Last Night widget

**Acceptance Criteria:**
- [ ] Small + medium layouts reuse `SleepScoreGauge`, `DurationFormatter`, `Theme`
- [ ] Empty state → start-tracking link; otherwise → session link
- [ ] Extension memory fits the widget budget with `DesignSystem` linked
- [ ] Builds with zero errors

### F20-T6 — 7-Night Trend widget

**Acceptance Criteria:**
- [ ] Medium layout with `MiniBarChart` + average; empty state; tap → `.last7Nights`
- [ ] Builds with zero errors

### F20-T7 — Start Tracking widget

**Acceptance Criteria:**
- [ ] Small tile styled like `StartRecordingButton`; tap → `.liveSession`
- [ ] Builds with zero errors

### F20-T8 — Lock Screen accessories

**Acceptance Criteria:**
- [ ] `accessoryCircular`, `accessoryRectangular`, `accessoryInline` render correctly in vibrant mode
- [ ] Builds with zero errors

### F20-T9 — Verification, docs, merge

**Acceptance Criteria:**
- [ ] Tests, layering check, hardcoded-string grep, computed-view grep all pass
- [ ] Manual simulator pass of every widget + tap target
- [ ] Feature doc, session fragment, architecture notes
- [ ] Feature branch merged to `main`
