# F5 — Trends

## Overview

Weekly and monthly bar charts showing snoring duration per night, colored by intensity. Stat cards show average sleep score, best/worst night, and total events. Lives within the Statistics tab as a pushed screen.

## Status

**Done** — All 2 tasks complete.

## Files

| File | Purpose |
|------|---------|
| `Packages/Statistics/Sources/Statistics/TrendsView.swift` | Container view with week/month toggle, bar chart, legend, stat cards |
| `Packages/Statistics/Sources/Statistics/StatisticsDashboardView.swift` | "View month >" button navigates to `.trends` |
| `Packages/Env/Sources/Env/Router.swift` | `.trends` added to `RouterDestination` |
| `SleepGuard/AppRegistry.swift` | `.trends` mapped to `TrendsView()` |

## Routes

| Type | Destination | View | Trigger |
|------|------------|------|---------|
| Push | `.trends` | `TrendsView` | "View month >" on Statistics dashboard |

## State

| State | Type | Scope | Description |
|-------|------|-------|-------------|
| `timeRange` | `TimeRange` enum | `TrendsView` | `.week` or `.month`; filters sessions to last 7 or 30 days |
| `sessions` | `@Query` | `TrendsView` | All `SleepSession` records sorted by date descending |

## Edge Cases

| Case | Handling |
|------|----------|
| No sessions in range | Chart shows empty; averages return 0; stat cards show 0 |
| Night with no snoring events | Bar color = `snoreQuiet`, height = 0 minutes |
| Multiple intensity levels in one night | Bar color = max intensity (loud > light > quiet) |
| Monthly view with < 30 nights | Only shows available nights; chart auto-sizes |

## Tasks Completed

- F5-T1: Weekly/monthly bar charts
- F5-T2: Stat cards (avg, best/worst, total)

## Design Notes

- Segmented picker: accent background for active, transparent for inactive
- Bar chart: 120pt height, 4pt corner radius, bottom-aligned bars
- Day labels: weekday abbreviations for week view, day numbers for month view
- Stat card icons: scope (avg), star.fill (best), bolt.fill (worst), number (total)
