# ADR 0005: Draw with the shared design kit

- **Status:** Accepted
- **Date:** 2026-11-16
- **Task:** F24 (SleepGuardUIKitWay F6)

## Context

SleepGuardUIKitWay rebuilds SleepGuard's screens and needs the same tokens and the same views. Its design kit, `SleepGuardDesignKit` in the shared repo (ADR 0004), started as ports of SleepGuard's `DesignSystem` components. With a copy in each app, every visual change had to be made twice and the two drifted (one port had the calendar's night colour wrong).

The views that could be shared were the ones that only take values and draw them. Screens can't be: SleepGuard reads `@Query`, injects services with `@Injected` and navigates with `RouterPath`; SleepGuardUIKitWay uses `Dependencies`, `Routes` and UIKit coordinators.

## Decision

Tokens and presentational components live once, in `SleepGuardDesignKit`. SleepGuard draws with them:

- **Tokens.** `AppTheme` (was `Theme`, renamed because the kit's value is `Theme`) starts every token from the kit's `Theme.sleepGuard`. It stays the `@Injected(\.theme)` service, so the 131 call sites didn't change. `designKitTheme` turns it into the kit's value; the app root puts that in the SwiftUI environment, where kit components read it.
- **Re-export.** `DesignSystem` re-exports the kit (like `SleepStrings`), so any view that imports `DesignSystem` sees the kit's components.
- **Components.** Deleted from SleepGuard and taken from the kit: the basics (stat card, score gauge, mini chart, level meter, scale button style, sheet handle and nav header, recording buttons), the night detail (stats grid, timeline, banners, event row and card), Statistics (week strip, tiles, both snoring charts, calendar header and grid, night card, day row, picker, legend) and the player (header, controls, rows, enhanced-audio toggle, no-audio card, loudness legend).
- **Adapters.** `DesignSystem/Sources/Components/SleepGuardKitAdapters.swift` builds kit components from the stored models with the old signatures (`SessionStatsGrid(session:)`, `NightTimeline(session:)`, `EventRow(event:…)`, `EventCard(event:…)`), so their call sites didn't change. The gap and low-battery banners are thin wrappers that decide whether to show.
- **The rule.** A view that only takes values and draws them goes in the kit. A view that loads data, holds state, injects services or navigates stays in the app. A SleepGuard-only piece used by 2+ packages (it reads models or services) goes in `DesignSystem`.

## Consequences

- A visual change to a shared component is made once, in the shared repo, and reaches both apps after a release and a bump.
- That change now needs a shared release (tag, `scripts/bump-shared.sh`). A one-line colour fix is no longer a SleepGuard-only commit.
- Kit components read `@Environment(\.theme)`, SleepGuard's own views `@Injected(\.theme)`. Both show `AppTheme.shared`'s values; a preview that overrides an `AppTheme()` restyles only SleepGuard's own views unless it also sets `.environment(\.theme, custom.designKitTheme)`.
- SleepGuard's types shadow the kit's same-named ones inside its modules: a kit component takes effect only once SleepGuard's copy is gone.
- Visible changes made on the way, each approved: event rows and the player header use the device's short time; "Event 1 / 3"; translated loudness in the player's rows; Trends' stat tiles match Last 7 Nights'.
- Still SleepGuard's own: the waveform, the sleep-stage views, the day-group row in Recordings, the update gate, the activity view.
- **Open:** the `bg-card` token. Code and kit use `#22232B` (what ships); the token list below said `#2C2C2E`. Not checked against `designs/SleepGuard.pen` (Pencil wasn't running).

## Alternatives

- **Keep a copy in each app.** No release step for a visual change, but two copies that drift; rejected.
- **Share whole screens.** One app's data and navigation model would be forced on the other; rejected.
- **Re-export without renaming `Theme`.** Every view would see two types named `Theme`; rejected.
