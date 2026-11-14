# F24 — Shared design kit adoption

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P2 |
| **Version** | — |
| **Blocked By** | — (do when there's time; best after SleepGuardUIKitWay F3-T5, which puts the detail components into the kit) |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

SleepGuard draws its tokens and presentational components from `SleepGuardDesignKit` in the shared repo (`../SleepGuardShared`) instead of its own copies in `DesignSystem`, so a visual change to a shared component is made once and shows in both SleepGuard and SleepGuardUIKitWay. No visual change for the user.

**Rule:** a view that only takes values and draws them belongs in the shared kit. A view that loads data, holds state, injects services or navigates stays in this app (screens, `@Query`, `@Injected`, `RouterPath`).

Mirrors SleepGuardUIKitWay's F6 ("Design kit adoption in SleepGuard").

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F24-T1 | `Theme` built from the kit's default palette; kit theme injected into the SwiftUI environment at the root | Refactor | Backlog | — | DesignSystem, app | — | — |
| F24-T2 | Replace `DesignSystem` primitives with the kit's (`StatCard`, `SleepScoreGauge`, `MiniBarChart`, `AudioLevelMeter`, sheet header/handle, `ScaleButtonStyle`, recording buttons) | Refactor | Backlog | F24-T1 | DesignSystem + call sites | — | — |
| F24-T3 | Replace the detail components with the kit's view-data versions (`SessionStatsGrid`, `EventRow`, score badge, `SnoringLegendView`, `EventIntensityLegendView`, `SleepStageLegendGrid`, timeline); map `@Model` values to view data at the call site | Refactor | Backlog | F24-T2, UIKitWay F3-T5 | DesignSystem, Recordings, Statistics | — | — |
| F24-T4 | ADR (`docs/adr/`), `AGENTS.md`/`CLAUDE.md` design section and duplication rule point at the shared kit | Docs | Backlog | F24-T3 | docs | — | — |

## Task Details

### F24-T1 — Theme from the kit

| Field | Value |
|-------|-------|
| Arch Ref | `docs/adr/0004-shared-repo.md`, `docs/architecture/views.md` |
| Status | Backlog |
| Started | — |
| Completed | — |

**Acceptance Criteria:**
- [ ] `DesignSystem` depends on `SleepGuardDesignKit` (pinned shared release; local override via `SleepGuard.xcworkspace`)
- [ ] The 131 `@Injected(\.theme)` call sites are untouched
- [ ] Token values match `designs/SleepGuard.pen` (resolve the open `bg-card` mismatch: `#2C2C2E` in AGENTS.md vs `#22232B` in code)
- [ ] Builds with zero errors; all tests pass

### F24-T2 — Primitive components

**Acceptance Criteria:**
- [ ] Each replaced component is deleted from `DesignSystem`; call sites use the kit's
- [ ] Checked against `designs/SleepGuard.pen` (simulator screenshots before/after)
- [ ] `check-layering.py` and `check-view-size.py` pass; builds with zero errors; all tests pass

### F24-T3 — Detail components

**Acceptance Criteria:**
- [ ] Kit components take plain values / `SleepCore` types, never SwiftData models
- [ ] Mapping from `SleepSession`/`SnoreEvent` to view data lives in this app, next to the call site
- [ ] Checked against `designs/SleepGuard.pen`; builds with zero errors; all tests pass

### F24-T4 — Docs

**Acceptance Criteria:**
- [ ] ADR: context, decision, consequences (one change reaches both apps; a kit change needs a shared release), alternatives (keep copies)
- [ ] `AGENTS.md` and `CLAUDE.md` kept in sync

## Notes

- If the kit starts fighting SleepGuard's design rules, stop and record why before forking a component.
- A kit change goes through a shared release (tag, then `scripts/bump-shared.sh`).
