# F24 — Shared design kit adoption

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done (bg-card open) |
| **Priority** | P2 |
| **Version** | — |
| **Blocked By** | — (do when there's time; best after SleepGuardUIKitWay F3-T5, which puts the detail components into the kit) |
| **Started** | 2026-11-15 |
| **Completed** | 2026-11-16 |
| **Feature Doc** | — |

## Summary

SleepGuard draws its tokens and presentational components from `SleepGuardDesignKit` in the shared repo (`../SleepGuardShared`) instead of its own copies in `DesignSystem`, so a visual change to a shared component is made once and shows in both SleepGuard and SleepGuardUIKitWay. No visual change for the user.

**Rule:** a view that only takes values and draws them belongs in the shared kit. A view that loads data, holds state, injects services or navigates stays in this app (screens, `@Query`, `@Injected`, `RouterPath`).

Mirrors SleepGuardUIKitWay's F6 ("Design kit adoption in SleepGuard").

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F24-T1 | `Theme` built from the kit's default palette; kit theme injected into the SwiftUI environment at the root | Refactor | Done | — | DesignSystem, app | 2026-11-15 | 2026-11-15 |
| F24-T2 | Replace `DesignSystem` primitives with the kit's (`StatCard`, `SleepScoreGauge`, `MiniBarChart`, `AudioLevelMeter`, sheet header/handle, `ScaleButtonStyle`, recording buttons) | Refactor | Done | F24-T1 | DesignSystem + call sites | 2026-11-15 | 2026-11-15 |
| F24-T3 | Replace the detail components with the kit's view-data versions (`SessionStatsGrid`, `EventRow`, score badge, `SnoringLegendView`, `EventIntensityLegendView`, `SleepStageLegendGrid`, timeline); map `@Model` values to view data at the call site | Refactor | Done | F24-T2, UIKitWay F3-T5 | DesignSystem, Recordings, Statistics | 2026-11-15 | 2026-11-16 |
| F24-T4 | ADR (`docs/adr/`), `AGENTS.md`/`CLAUDE.md` design section and duplication rule point at the shared kit | Docs | Done | F24-T3 | docs | 2026-11-16 | 2026-11-16 |

## Task Details

### F24-T1 — Theme from the kit

| Field | Value |
|-------|-------|
| Arch Ref | `docs/adr/0004-shared-repo.md`, `docs/architecture/views.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [x] `DesignSystem` depends on `SleepGuardDesignKit` and re-exports it (like `SleepStrings`)
- [x] SleepGuard's theme class is now `AppTheme` (the kit's value is `Theme`; both visible together would clash). 14 `Theme.shared` / `Theme()` sites renamed (app, widgets, test); `DesignSystem`'s duplicate `Color(hex:)` removed (the kit's is identical)
- [x] Every token starts from the kit's `Theme.sleepGuard` (identical values: no visual change); `designKitTheme` gives the kit value, following overrides; the app root puts it in the environment
- [x] The 131 `@Injected(\.theme)` call sites are untouched
- [ ] Token values match `designs/SleepGuard.pen`: **open.** Code and kit use `#22232B` for `bg-card` (what ships today); AGENTS.md says `#2C2C2E`. Pencil wasn't running, so the design file wasn't checked.
- [x] All 8 suites pass (DesignSystem 7: 2 new theme tests); app and widgets build; format, layering, view size pass

### F24-T2 — Primitive components

**Acceptance Criteria:**
- [x] Deleted from `DesignSystem` (approved by the user): `StatCard`, `SleepScoreGauge`, `MiniBarChart`, `AudioLevelMeter`, `ScaleButtonStyle`, `SheetHandle` / `SheetNavHeader`, `RecordingActionButton`, `StartRecordingButton`, `StopRecordingButton`. The kit's take over through `DesignSystem`'s re-export; the 48 call sites are unchanged (same APIs)
- [x] Same drawing: compared line by line; every hardcoded value in SleepGuard's copies equals the kit's token (`#FF453A` = destructive, `#22232B` = bgCard, 16 = card radius, white = textPrimary, `#8E8E93` = textTertiary); fonts are the system font either way
- [ ] Checked on screen: **not done.** The simulator opens on the daily briefing, which covers these screens, and I can't tap from here. Needs a look (dashboard, recording buttons, sheets)
- [x] All 8 suites pass; app and widgets build; format, layering, view size pass

### F24-T3 — Detail components

**Acceptance Criteria:**
- [ ] Kit components take plain values / `SleepCore` types, never SwiftData models
- [ ] Mapping from `SleepSession`/`SnoreEvent` to view data lives in this app, next to the call site
- [ ] Checked against `designs/SleepGuard.pen`; builds with zero errors; all tests pass

**Split into three steps (2026-11-15):** T3a night detail, T3b Statistics, T3c player.

**T3a — night detail (done 2026-11-15; shared 0.12.0)**
- [x] Deleted (approved): `DesignSystem`'s `SessionStatsGrid`, `SnoringTimelineView`; `Recordings`' `EventRow`; the private `EventCard` in `EventsSheetView`
- [x] `MelodyGapsBannerView` / `LowBatteryBannerView` rewritten as thin wrappers over the kit's banners; both timelines (detail, session summary) use the kit's `NightTimeline` (the summary without its title: kit option `showsTitle`, shared 0.12.0)
- [x] `SleepGuardKitAdapters.swift`: kit initializers from the stored models with the old signatures (`SessionStatsGrid(session:)`, `NightTimeline(session:)`, `EventRow(event:displayDuration:onPlay:onShare:)`, `EventCard(event:displayDuration:onPlay:)`), so the 13 call sites didn't change
- [x] Visible change (approved): event rows show the device's short time ("2:46 AM", or "02:46" on 24-hour devices) instead of a fixed "02:46 AM"
- [x] All 8 suites pass against the local shared checkout; app builds; format, layering, view size pass
- [ ] Seen on screen: not yet (night detail, events sheet, session summary)

**T3b — Statistics (done 2026-11-15; shared 0.13.0)**
- [x] Deleted (approved): `DesignSystem`'s `SnoringLegendView`; Statistics' `TrendStatCard`, `TrendsChartSection`, `CalendarStatCard`, `CalendarGridView`, `CalendarDayHeaders`, `CalendarMonthSelector`, `Last7NightsChartCard`, `Last7NightsRow`
- [x] Rewritten on kit components: week strip (`WeekStrip` from the dashboard's week; header kept), Trends (`PillPicker`, `SnoringBarChart`, `SnoringLegend`, `StatTile`), calendar (`MonthHeader`, `CalendarMonthGrid`, `CenteredStatTile`, `NightCard` with the same text; "Today" stays in the toolbar), Last 7 Nights (`SnoringDayBars`, `StatTile` 22 pt, `DayRow`)
- [x] Orphans removed: `StatisticsWeekDay` and its mapping, `DaySummary.weekday` / `dateString`, the calendar's weekday symbols and colour helper
- [x] Kit fix (shared 0.13.0): calendar days with a night sit on the card colour (`#22232B`), as in SleepGuard; the kit had `#3A3A3C`
- [x] Visible change (approved): Trends' stat tiles take the Last 7 Nights style (2 pt more spacing, semibold icon)
- [x] All 8 suites pass against the local shared checkout; app builds; format, layering, view size pass
- [ ] Seen on screen: not yet (dashboard week strip, Trends, calendar, Last 7 Nights)

**T3c — player (done 2026-11-16)**
- [x] Deleted (approved): `EventPlayerHeaderView`, `EventPlayerControlsView`, `PlayerEventRow`, `EnhancedAudioToggleSection`, `NoAudioView`, `EventIntensityLegendView`
- [x] The four call sites use the kit's `PlayerHeader`, `PlayerControls`, `EventIntensityLegend`, `EnhancedAudioToggle`, `PlayerEventRow`, `NoAudioCard`; the waveform stays SleepGuard's
- [x] Visible changes (approved): header time in the device's short style ("1:49 AM"), "Event 1 / 3", player rows "1m 4s · Quiet" with translated loudness and the detail rows' kind dot, the no-audio line in the same formats
- [x] All 8 suites pass; app builds; format, layering, view size pass
- [ ] Heard and seen: not yet (the player from a row, the events sheet and the hidden events)

### F24-T4 — Docs

**Acceptance Criteria:**
- [x] ADR 0005 (`docs/adr/0005-shared-design-kit.md`): context, decision, consequences (one change reaches both apps; a kit change needs a shared release; two theme reads), alternatives
- [x] `AGENTS.md` and `CLAUDE.md` (in sync): shared kit paragraph in Design Compliance, the extraction and duplication rules point to the kit, `bg-card` marked open
- [x] Technical overview's DesignSystem row

## Notes

- If the kit starts fighting SleepGuard's design rules, stop and record why before forking a component.
- A kit change goes through a shared release (tag, then `scripts/bump-shared.sh`).
