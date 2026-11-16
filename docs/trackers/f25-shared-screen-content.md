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
| F25-T2 | Statistics screens (dashboard, Trends, Calendar, Last 7 Nights) host the shared content | Refactor | Backlog | F25-T1 | Statistics, DesignSystem | — | — |
| F25-T3 | Recordings list hosts the shared content; `SessionGrouper` replaced by `SleepCore`'s rule | Refactor | Backlog | F25-T2 | Recordings | — | — |
| F25-T4 | Session detail, events sheet and player host the shared content | Refactor | Backlog | F25-T2 | Recordings | — | — |
| F25-T5 | Prestart, bedside clock and summary host the shared content (melody rows and overlay through slots) | Refactor | Backlog | F25-T2 | SleepSession | — | — |
| F25-T6 | Review: no screen-content view left here for the shared screens; docs final | Docs | Backlog | F25-T3, T4, T5 | docs | — | — |

## Notes

- Containers map models to `SleepCore` values before handing them to content. Lists use `summaryWithoutEvents` (no event faulting).
- Every file deletion is listed and confirmed first.
- Each adopted screen is checked on the simulator, before and after.
- `DesignSystem` stays as the bridge (ADR 0006). Its sleep-stage views move to the shared kit with SleepGuardUIKitWay's F8-T3.
