---
date: 2026-11-05
feature: f19
branch: feature/f19/t5-watch-docs-rules
title: Factory DI — Watch eval, docs & rules rewrite
---

### Completed
- F19-T5: Watch app evaluated (documented skip), DI rules rewritten across AGENTS.md/CLAUDE.md/templates/architecture docs, feature doc created. Final task of F19.

### Technical Details
- **Watch app skip rationale**: `WatchApp/` has no package structure, a single self-contained singleton (`WatchSessionManager.shared`) accessed twice; FactoryKit would require editing the watch target's pbxproj for zero gain. Documented in `dependencies.md` and the feature doc.
- **Rules rewritten** (`@Environment` flow → Factory container): `AGENTS.md`, `CLAUDE.md`, `docs/AGENTS_TEMPLATE.md`, `docs/CLAUDE_TEMPLATE.md` — Dependencies section now mandates `@Injected(\.service)` in views, `Container.shared.service()` in `@Observable` classes (macro collision), `dependency(\.service)` for nonisolated code, app target as composition root, RouterPath as the deliberate `.environment` exception.
- **Architecture docs synced**: `dependencies.md` fully rewritten (registrations, per-context resolution, mocking, watch skip, rules); `rules.md` (Do 4/15, Don't 4, limitation bullet), `INDEX.md`, `overview.md`, `state.md`, `views.md`, `feature-template.md`, `navigation.md`, `PROMPTS.md` — all DI references now describe the container; `.withEnvironments()` only for RouterPath.
- **T3 orphan cleanup**: dead `.environment(tabCoordinator)` removed from `MainTabView.swift:35` — zero `@Environment(TabCoordinator` consumers existed after T3.
- Not migrated (documented in feature doc follow-up): remaining direct `.shared` in view closures (StatisticsTab `UserPreferences.shared`, `HapticManager.shared`); DEBUG `Button("Debug Config")` hardcoded string (pre-existing).
- Build green. Layering check green (219 files).

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/MainTabView.swift` | −1 | Dead `.environment(tabCoordinator)` removed |
| `AGENTS.md`, `CLAUDE.md`, `docs/AGENTS_TEMPLATE.md`, `docs/CLAUDE_TEMPLATE.md` | ~+12/−5 each | Dependencies + State rules rewritten for Factory DI |
| `docs/architecture/dependencies.md` | rewritten | Full Factory-based DI reference (was IceCubes env-based) |
| `docs/architecture/{rules,INDEX,overview,state,views,feature-template,navigation,PROMPTS}.md` | ~+20/−20 | Stale `@Environment`/withEnvironments references synced |
| `docs/features/f19-factory-di.md` | new | Feature doc: files, state table, edge cases, follow-ups |

### Architecture Decisions
- **Docs breadth**: tracker criterion named AGENTS.md + dependencies.md, but `rules.md` (the audit checklist AGENTS.md points to) and prompt templates would actively contradict the new rules — syncing them prevents future AI sessions from re-deriving the old pattern.
- **Watch skip** over migration: pbxproj risk vs zero architectural gain; consistent with f17's "modernize at integration time" note.

### Build Status
- **BUILD SUCCEEDED** — zero errors.

### Suggested Branch
`feature/f19/t5-watch-docs-rules`

### Suggested Commit
`[F19-T5] — Watch eval, DI rules rewrite, feature doc`

### Changes done
```
- Watch app: documented skip (no packages, one singleton, pbxproj risk)
- AGENTS.md/CLAUDE.md/templates: Dependencies rules -> Factory container
- docs/architecture/*: all DI references synced to container pattern
- MainTabView: dead .environment(tabCoordinator) removed (T3 orphan)
- docs/features/f19-factory-di.md created
```

### Next Session
- Merge T5 (PR into factory-reformat), then merge `factory-reformat` → `main` (link: https://github.com/dardan0x/SleepGuard/compare/main...factory-reformat?expand=1).
- Final tracker bookkeeping: F19 5/5 Done, FeatureTracker counts (Total 110, Done 94, Backlog 16, 85%).

### Open Questions
- Pre-existing simulator recording crash (`installTap` EXC_BREAKPOINT) — investigate separately or verify on device.
