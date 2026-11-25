# ADR 0007: The app root owns the end of a night and app-level modals

- **Status:** Accepted
- **Date:** 2026-11-25
- **Task:** F27-T2 (principal review Q22, Q26, Q27, Q28)

## Context

When a recording stopped, `StatisticsTab` watched `sessionManager.completedSession`. It presented the summary, auto-saved a night stopped for low battery, and was the only place a crash-recovered night surfaced. Tabs are remotely configurable, and `MainTabView` builds only the visible ones. With Statistics hidden, nobody watched:

- A recovered night was never offered. Its checkpoint stayed, so it was "offered" again on every launch.
- A low-battery night was never saved.

Three owners presented modals independently: the tab's `RouterPath` (summary), the tab's own `@State` (notification soft-ask) and `MainTabView` (morning briefing). Two sheets at launch could collide. `SheetDestination.sessionSummary` carried no ID and read the singleton when presenting. A widget deep link that arrived while recording or while the summary was up was cleared before the guard, so it was lost.

## Decision

- **`SessionFlowHost`** (app target, a view modifier on `MainTabView`) owns the end of a night, whichever tabs are visible: launch recovery (recovery first, then cleanup), the summary, and the low-battery auto-save (on failure, the summary is offered instead).
- **One root presentation slot.** `RootPresentation` (`Routing`): `.sessionSummary(id:)`, `.notificationSoftAsk`, `.briefing(id:)`. The pure `RootPresentationPolicy.next(requests:current:isRecording:isInLiveSession:)` picks what shows. Priority: summary > soft-ask > briefing. It never replaces a sheet that is up (or still closing), never presents while recording, and holds the prompts back while the live session screen is up. Unit-tested in `RoutingTests`.
- **Routes carry identity.** The summary is presented by night ID and shown only while that night is still pending. `SheetDestination` keeps only tab-level sheets (`.profileEditor`).
- **Deep links wait instead of being dropped.** `TabCoordinator.takePendingDeepLink(blocked:)` hands the link over only when nothing blocks it (recording, a night waiting to be saved, a tab sheet). "Start tracking" while already recording is dropped, because there is nothing to start.
- `StatisticsTab` is the dashboard only.

## Consequences

**Better:** the end of a night no longer depends on a tab being visible. Presentation conflicts are decided by one tested rule instead of by whichever `.sheet` SwiftUI honours. A deep link is never silently lost.

**Limits, honestly:**
- `SessionFlowHost` itself is a view and isn't unit-tested; the policy and the deep-link hand-over are. The host was verified on the simulator: recovery with Statistics hidden, summary → briefing chaining, and a deferred deep link.
- Screen-local sheets (player, events grid, melody picker) still belong to their screens. The root can't see them, and doesn't need to: none of them competes with app-level modals.
- Starting a recording is still only reachable from Statistics. Hiding that tab hides recording; that's a product decision, not covered here.
- Found while verifying: a summary that closes itself by clearing its night empties its own content, so `dismiss()` reaches nothing. The host closes the summary as soon as its night is resolved, and uses the sheet that is still closing as "current", so the next modal waits for it.

## Alternatives

- **A root `fullScreenCover` for the summary only:** smallest change, but the briefing and soft-ask would still collide with it.
- **An `@Observable` flow model in Env:** testable, but it would hold SwiftUI presentation state in the service layer (Env doesn't import SwiftUI).
- **Forbid hiding Statistics remotely:** a policy that the code wouldn't enforce.
