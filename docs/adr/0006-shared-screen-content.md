# ADR 0006: Share screen content, keep screens

- **Status:** Accepted
- **Date:** 2026-11-16
- **Task:** F25 (SleepGuardUIKitWay F10)

## Context

ADR 0005 moved tokens and components to the shared `SleepGuardDesignKit`. Each app still arranged those components into screens on its own, so the layouts existed twice: `StatisticsLoadedView` here and SleepGuardUIKitWay's dashboard content are the same layout, down to the "LAST NIGHT" label logic. The same is true of Trends, Calendar, Last 7 Nights, the Recordings list, the session detail, the player card and the recording screens. A layout fix had to be made in both apps. The month-and-day grouping (`SessionGrouper`) was duplicated too.

The question was whether to move every remaining view to the shared repo.

## Decision

No. View code has three layers, and only the middle one moves.

| Layer | What it is | Where it lives |
|---|---|---|
| Components | Gauge, stat card, timeline, rows, buttons | `SleepGuardDesignKit` (shared, ADR 0005) |
| Screen content | One screen's loaded layout: values and action closures in, drawing out | `SleepGuardContentKit` (shared, new) |
| Screens | Loading and `ViewState`, `@Query`, `@Injected` services, `RouterPath`, alerts and sheets, the header and toolbar | This app's feature packages |

- **The test:** a view that can be rendered in a test from plain values alone is shared. One that needs a service, a model context, the router, an alert or a sheet is a screen and stays here.
- **Feature packages stay.** `Recordings`, `Statistics`, `SleepSession` and the rest keep their screens, state owners and SleepGuard-only views (debug sections, hidden events, the PDF report, the melody sheets). Only the pure layouts leave.
- **Containers map models to values.** A container loads as it does today, then hands the content `SleepCore` values (`summaryWithoutEvents` for lists, `nightSummary` and `night` for the nights a screen shows) and closures for what the user can do. The faulting rule is unchanged: lists never read `events`.
- **SleepGuard-only extras** (sleep-stage breakdown, melody rows, share) go into a content view through an optional value or a `@ViewBuilder` slot. A screen the two apps want laid out differently is not shared.
- **A separate product, not the design kit**, so the kit stays free of product decisions.
- **`DesignSystem` stays**, as this app's bridge to the shared code: `AppTheme` and its Factory registration, the model adapters (`SleepGuardKitAdapters.swift`), the re-exports, and SleepGuard-only views. It can't move: it depends on `Models` and Factory, which the shared repo never imports. Its sleep-stage views move to the kit when SleepGuardUIKitWay gets sleep stages.
- **Rules follow the same line.** The grouping moves to `SleepCore`.

## Consequences

- A layout fix to a shared screen is made once, in the shared repo, and reaches both apps after a release and a bump.
- A fix to loading, navigation or an alert is still made per app: that is where the two architectures differ, on purpose.
- Feature packages get smaller and what's left in them is this app's architecture: MV containers, `ViewState`, DI, routing.
- Content views read `@Environment(\.theme)` like kit components; the root already injects `AppTheme.shared.designKitTheme`.
- Every layout change to a shared screen needs a shared release.
- Adoption touches working screens one at a time; each needs an on-screen check.

## Alternatives

- **Move every view to the shared repo.** Screens can't be shared without one common data and navigation model for both apps, which would remove what makes this app all-SwiftUI MV and the other a UIKit shell on ports. Rejected.
- **Move the layouts into `DesignSystem` or the design kit.** `DesignSystem` isn't visible to the other app; the kit would mix a design system with product decisions. Rejected.
- **Leave it.** Two copies of every layout, drifting. Rejected.
