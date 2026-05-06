# SnoreGuard — Feature Tracker

> Auto-updated by the AI after every task. This is the local source of truth.

Last updated: 2026-05-06

---

## Dashboard

| Metric | Count |
|--------|-------|
| Features (V1) | 6 |
| Done | 5 |
| In Progress | 0 |
| Backlog | 1 |
| Blocked | 0 |
| — | — |
| Total Tasks | 24 |
| Tasks Done | 20 |
| Tasks In Progress | 0 |
| Tasks Blocked | 0 |
| Tasks Backlog | 3 |
| — | — |
| **Progress** | **83%** |

## Features

| ID | Feature | Priority | Status | Tasks | Progress | File |
|----|---------|----------|--------|-------|----------|------|
| F1 | Onboarding | P0 | Done | 5/5 | ██████████ 100% | [tracker](trackers/f1-onboarding.md) |
| F2 | Live Session | P0 | Done | 6/6 | ██████████ 100% | [tracker](trackers/f2-live-session.md) |
| F3 | Statistics Dashboard | P1 | Done | 3/3 | ██████████ 100% | [tracker](trackers/f3-statistics.md) |
| F4 | Recordings | P1 | Done | 5/5 | ██████████ 100% | [tracker](trackers/f4-recordings.md) |
| F5 | Trends | P1 | Done | 2/2 | ██████████ 100% | [tracker](trackers/f5-trends.md) |
| F6 | Settings | P2 | Backlog | 0/3 | ░░░░░░░░░░ 0% | [tracker](trackers/f6-settings.md) |

## Activity Log

_Most recent first. The AI appends here after every task._

| Date | Task | Action | Notes |
|------|------|--------|-------|
| 2026-05-06 | F5-T2 | Completed | Stat cards built as part of TrendsView: Avg Score, Best/Worst Night, Total Events |
| 2026-05-06 | F5-T1 | Completed | TrendsView with week/month toggle, Swift Charts bar chart, intensity-colored bars, 4 stat cards |
| 2026-05-06 | F4-T4 | Completed | Audio file saving (full session .caf), mini player with play/pause/scrub/event markers, event row playback |
| 2026-05-06 | F4-T5 | Completed | Fixed .recordingDetail(id:) route in AppRegistry → SessionDetailView; navigation now works end-to-end |
| 2026-05-06 | F4-T3 | Completed | SessionDetailView with score gauge, stats grid, SnoringTimelineView, event list; FetchDescriptor by UUID |
| 2026-05-06 | F4-T2 | Completed | RecordingRowView extracted with score badge, event count, tap navigation to .recordingDetail |
| 2026-05-06 | F4-T1 | Completed | RecordingsListView with ViewState, empty/loaded/error, month-grouped sections, pull-to-refresh |
| 2026-05-06 | F3-T3 | Completed | Converted .liveSession to RouterDestination; Start Recording CTA now uses routerPath.navigate(to:) |
| 2026-05-06 | F3-T2 | Completed | SleepScoreGauge, StatCard, SleepSparkline components; loaded view with gauge + 6 stat cards + sparkline |
| 2026-05-06 | F3-T1 | Completed | StatisticsDashboardView with ViewState, empty/loaded/error, @Query, presentational children |
| 2026-05-06 | F2-T6 | Completed | Route registration + wiring: Start Recording CTA, sheet lifecycle, onboarding routing |
| 2026-05-06 | F2-T5 | Completed | Session summary sheet with sleep score ring, stats grid, Save/Discard |
| 2026-05-06 | F2-T4 | Completed | Bedside clock active recording UI with dB bar, snoring glow, timer |
| 2026-05-06 | F2-T3 | Completed | Pre-start recording screen with mic status + tips + CTA |
| 2026-05-06 | F2-T2 | Completed | SessionManager real-time event tracking + sleep score |
| 2026-05-06 | F2-T1 | Completed | AudioRecorder + SnoreDetector verified from scaffold |
| 2026-05-06 | F1-T2 | Completed | Onboarding screens 1-3 UI with animations |
| 2026-05-06 | Phase 0 | Scaffold complete | Architecture scaffolded, 9 packages, build succeeds |
| 2026-05-06 | Phase 0 | Started | Project kickoff initiated |

## Currently Active

| Task | Feature | Started | Assignee |
|------|---------|---------|----------|
| (none) | — | — | — |

## Up Next

_Unblocked tasks in priority order. The AI updates this after every task._

| Task | Feature | Priority | Why Ready |
|------|---------|----------|-----------|
| F4-T4 | F4 | P1 | F4-T3, F4-T5 done. **Blocked by missing audio file saving infrastructure** — see tracker notes |

## Blocked

| Task | Feature | Blocker | Since |
|------|---------|---------|-------|
| (none) | — | — | — |

## Up Next

_Unblocked tasks in priority order. The AI updates this after every task._

| Task | Feature | Priority | Why Ready |
|------|---------|----------|-----------|
| F5-T1 | F5 | P1 | F2, F3, F4 done |

## Completed (last 10)

| Task | Feature | Completed | Duration |
|------|---------|-----------|----------|
| F5-T2 | F5 | 2026-05-06 | — |
| F5-T1 | F5 | 2026-05-06 | — |
| F4-T4 | F4 | 2026-05-06 | — |
| F4-T5 | F4 | 2026-05-06 | — |
| F4-T3 | F4 | 2026-05-06 | — |
| F4-T2 | F4 | 2026-05-06 | — |
| F4-T1 | F4 | 2026-05-06 | — |
| F3-T3 | F3 | 2026-05-06 | — |
| F3-T2 | F3 | 2026-05-06 | — |
| F3-T1 | F3 | 2026-05-06 | — |
| F2-T6 | F2 | 2026-05-06 | — |
| F2-T5 | F2 | 2026-05-06 | — |
| F2-T4 | F2 | 2026-05-06 | — |
| F2-T3 | F2 | 2026-05-06 | — |
| F2-T2 | F2 | 2026-05-06 | — |
| F2-T1 | F2 | 2026-05-06 | — |

---

## Update Rules (for the AI)

After **every task**, update this file:
1. Recalculate all Dashboard counts and progress percentage
2. Move completed task from "Currently Active" to "Completed (last 10)"
3. Update the Features table: status, task counts, progress bar
4. Add a row to Activity Log
5. Refresh "Up Next" — check if blocked tasks are now unblocked
6. Update `Last updated` date
7. If a feature is fully done: set status to **Done**, progress to 100%
