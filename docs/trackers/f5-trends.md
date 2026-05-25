# F5 — Trends

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P1 |
| **Version** | V1.0 |
| **Blocked By** | F2 (needs recording data), F3 (shares dashboard space) |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

Weekly and monthly bar charts (Swift Charts) showing snoring duration per night, colored by intensity. Stat cards show average sleep score, best/worst night, and total events. Lives within the Statistics tab.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F5-T1 | Weekly/monthly bar charts | UI | Done | F2-T2, F3-T1 | Statistics | 2026-05-06 | 2026-05-06 |
| F5-T2 | Stat cards (avg, best/worst, total) | UI | Done | F5-T1 | Statistics | 2026-05-06 | 2026-05-06 |

## Task Details

### F5-T1 — Weekly/monthly bar charts

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] Uses Swift Charts (`Charts` framework)
- [ ] Weekly view: last 7 nights as bar chart
- [ ] Monthly view: last 30 nights as bar chart
- [ ] Bars colored by snoring intensity (quiet/light/loud)
- [ ] Toggle between weekly and monthly
- [ ] Builds with zero errors

**Prompt Used:**
_(filled after task completion)_

**Notes:**
_(decisions, issues, deviations)_

---

### F5-T2 — Stat cards (avg, best/worst, total)

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-06 |
| Completed | 2026-05-06 |

**Acceptance Criteria:**
- [x] Average sleep score across all sessions
- [x] Best night (highest score)
- [x] Worst night (lowest score)
- [x] Total snoring events across all sessions
- [x] Cards are presentational components (`TrendStatCard`)
- [x] Builds with zero errors

**Notes:**
- Built as part of F5-T1 (`TrendsView`). `TrendStatCard` is a private presentational component.
- Best/Worst night show score values only (no date) per design.

---

### Session 57 Refinements (2026-05-24)

- **Duration format unification**: `TrendsView` average snoring display now uses `DurationFormatter.hoursAndMinutes` — shows `X h Y min` instead of raw minutes. Label updated from "SNORING MINUTES" to "AVG SNORING". Subtext simplified to "avg / night". `SessionStatsGrid` snore time stat changed from `H:MM:SS` to the same `X h Y min` format.

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)
