# F3 — Statistics Dashboard

## Overview

Last night's summary card with sleep score (0-100), duration, snoring percentage, average/peak dB, events count, and events per hour. Also shows a last-7-nights mini chart and a prominent "Start Recording" CTA.

## Status

**Done** — all tasks completed on 2026-05-06.

## Files

| File | Package | Purpose |
|------|---------|---------|
| `StatisticsDashboardView.swift` | Statistics | Container view with ViewState, @Query, empty/loaded/error states |
| `Components/SleepScoreGauge.swift` | Statistics | Presentational circular score gauge with animated fill |
| `Components/StatCard.swift` | Statistics | Presentational stat card (icon + value + label) |
| `Components/SleepSparkline.swift` | Statistics | Presentational mini sparkline using Swift Charts |
| `Router.swift` | Env | `RouterDestination.liveSession` added |
| `AppRegistry.swift` | App | `.liveSession` mapped to `SleepSessionView()` in `withAppRouter()` |
| `MainTabView.swift` | App | Sheet handling, onboarding routing, completedSession observation |

## Routes

| Type | Destination | Trigger |
|------|-------------|---------|
| Push | `.liveSession` | "Start Recording" CTA in empty/loaded states |
| Sheet | `.sessionSummary` | Stop recording (managed by `SessionManager`) |

## State

| State | Type | Scope | Description |
|-------|------|-------|-------------|
| `viewState` | `ViewState` enum | `StatisticsDashboardView` | `.loading`, `.empty`, `.loaded(session, recentSessions)`, `.error` |
| `sessions` | `@Query` | `StatisticsDashboardView` | SwiftData query for all `SleepSession` sorted descending |

## Edge Cases

- **No sessions yet**: Empty state with moon icon, descriptive copy, and full-width CTA
- **Single session**: Sparkline renders a `PointMark` instead of `LineMark` when only one data point exists
- **SwiftData update**: `.onChange(of: sessions)` reloads view state automatically when new sessions are saved
- **Recording completion**: `MainTabView` observes `sessionManager.completedSession`, pops navigation stack, then presents summary sheet

## Tasks Completed

- F3-T1: StatisticsDashboardView (empty + loaded)
- F3-T2: Score gauge + stat cards components
- F3-T3: "Start Recording" CTA + routing
