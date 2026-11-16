# F25 — Shared screen content

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P2 |
| **Version** | — |
| **Blocked By** | — |
| **Started** | 2026-11-16 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

SleepGuard's screens host their loaded layouts from `SleepGuardContentKit` in the shared repo (`../SleepGuardShared`) instead of their own copies, so a layout fix is made once and shows in both SleepGuard and SleepGuardUIKitWay. Screens stay here: loading, `ViewState`, `@Query`, `@Injected`, `RouterPath`, alerts, headers. No visual change for the user. See ADR 0006.

**The test:** a view that can be rendered from plain values alone is shared; one that needs a service, a model context, the router, an alert or a sheet stays in this app.

Mirrors SleepGuardUIKitWay's F10, which carries the detailed task notes.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F25-T1 | Decision recorded: ADR 0006, the three-layer rule in `AGENTS.md` / `CLAUDE.md` | Docs | Done | — | docs | 2026-11-16 | 2026-11-16 |
| F25-T2 | Statistics screens (dashboard, Trends, Calendar, Last 7 Nights) host the shared content | Refactor | Done | F25-T1 | Statistics, DesignSystem | 2026-11-16 | 2026-11-16 |
| F25-T3 | Recordings list hosts the shared content; `SessionGrouper` replaced by `SleepCore`'s rule | Refactor | Done | F25-T2 | Recordings | 2026-11-16 | 2026-11-16 |
| F25-T4a | Session detail and events sheet host the shared content; `SessionDetailModel` on SleepCore's filter and rows | Refactor | Done | F25-T2 | Recordings | 2026-11-16 | 2026-11-16 |
| F25-T4b | Player hosts the shared player content (waveform in it) | Refactor | Done | F25-T4a | Recordings | 2026-11-16 | 2026-11-16 |
| F25-T5 | Prestart, bedside clock and summary host the shared content (melody rows and overlay through slots) | Refactor | Backlog | F25-T2 | SleepSession | — | — |
| F25-T6 | Review: no screen-content view left here for the shared screens; docs final | Docs | Backlog | F25-T3, T4, T5 | docs | — | — |

## Notes

- Containers map models to `SleepCore` values before handing them to content. Lists use `summaryWithoutEvents` (no event faulting).
- Every file deletion is listed and confirmed first.
- Each adopted screen is checked on the simulator, before and after.
- **T2 (2026-11-16):** `DesignSystem` re-exports `SleepGuardContentKit`. The four screens keep their `@Query`, `RouterPath`, header and toolbar, and host `StatisticsDashboardContent` (sleep stages in its slot), `TrendsContent`, `CalendarContent`, `LastSevenNightsContent`, `StatisticsEmptyContent`. Containers still choose nights without reading events, then build full summaries for the shown ones. `DashboardState` carries SleepCore's `NightDashboard`. Deleted (approved): 8 views, `WeekOverWeekTrendCalculator` and its tests (`ScoreTrend` directly). Approved visible change: the calendar's selected night reads "Loud snoring · 62 out of 100" (was "· score 62", hard-coded English). Not checked on screen (the morning briefing sheet covers launch).
- **T3 (2026-11-16):** the Recordings list groups with SleepCore's `NightMonth` and draws with `NightsListContent` (day cards, swipe and long-press delete) and `NightsListEmptyContent`; the container keeps `@Query`, `RouterPath`, the delete confirmation and the SwiftData delete, `refreshable`, and the error state. Deleted (approved): `SessionGrouper`, `NightGroup`, `MonthSection`, `NightGroupRowView`, `RecordingsEmptyView`, `SessionGrouperTests` (cases ported to `NightMonthTests`). No visible change intended.
- **T4a (2026-11-16):** `SessionDetailLoadedView` keeps its toolbar (title, PDF, share, delete), sheets and export overlay and hosts `NightDetailContent` with the sleep stages and `ShortEventsButton` in its slots; `EventsSheetView` hosts `EventsGridContent`. `SessionDetailModel` exposes `night`, `filters`, `rows`, `event(for:)` (SleepCore's `EventFilter` / `EventListRow`); its tests follow, the membership test moved to SleepCore. `SleepSession.night` is public. Deleted (approved): `SessionDetailHeaderView`, `SessionDetailEventsView`, `SessionDetailTimelineView`. Visible change, approved: a snoring row shows the episode's start time.
- **T4b (2026-11-16):** `ClipPlayerContent` hosts `PlayerContent`, `LegacyPlayerContent` hosts `PlayerCard`; the sheet container (controller, waveform loader, legacy player, loading and no-audio states, toolbar) stays. `WaveformGenerator.generateSamples` feeds SleepCore's `WaveformAccumulator` (same numbers). `PlayerClip(event:)` adapter. Deleted (approved): `EventPlayerView`, `EventWaveformView` (with its unused burst-marker code), `PlayerEventListSection`. No visible change intended; the waveform gains VoiceOver adjust (±15 s).
- `DesignSystem` stays as the bridge (ADR 0006). Its sleep-stage views move to the shared kit with SleepGuardUIKitWay's F8-T3.
