---
date: 2026-11-10
feature: F22
branch: feature/f22/t11-versioned-schema
title: F22-T11 VersionedSchema V1 + empty migration plan
---

### Completed
- F22-T11: the SwiftData schema is versioned. `SleepGuardSchemaV1` lists the four current models unchanged, and `SleepGuardMigrationPlan` has no stages. The app and `TestStore` both open their container through one helper.

### Technical Details
- `SleepGuardSchema.container(_:)` calls `ModelContainer(for:migrationPlan:configurations:)`. `SleepGuardSchema.Current` names the latest version.
- V1 references the live `@Model` classes. When V2 is needed, freeze V1 as nested copies first (procedure in CLAUDE.md / AGENTS.md).
- Order change: T11–T13 run before T8, because T9's replay tests need a real recorded night.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Models/Sources/Data/SleepGuardSchema.swift` | +50 | New: V1, migration plan, container helper |
| `SleepGuard/SleepGuardApp.swift` | ±7 | Container through the plan |
| `Packages/Models/TestSupport/TestStore.swift` | ±7 | Same schema + plan as the app |
| `Packages/Models/Tests/ModelsTests/SleepGuardSchemaTests.swift` | +45 | Entity set; pre-V1 on-disk store opens intact |
| `CLAUDE.md`, `AGENTS.md` | +12 | "Versioned schema" + "Adding V2" steps |
| `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T11 Done, 8/14 |

### Architecture Decisions
- Didn't freeze V1 as nested copies yet: that duplicates four models with no behavior gained. It becomes step 1 of adding V2.

### Build Status
- swiftformat lint clean; layering check passed; all 8 package suites pass (Models 79); app build 0 warnings.
- Simulator with pre-T11 data: 30 sessions / 614 events / 1 profile / 7 logs / score sum 1744 before and after launch; dashboard renders.

### Suggested Branch
`feature/f22/t11-versioned-schema`

### Suggested Commit
`F22-T11 — VersionedSchema V1 + empty migration plan`

### Changes done
- See Files Changed.

### Next Session
- F22-T12 `DashboardState.make(from:now:)`, then T13, then T8.

### Open Questions
- The container fallback in `SleepGuardApp` deletes the store on any open failure in release builds too, although its comment says dev-only. Should it become `#if DEBUG`, with release surfacing the error instead? (Not changed.)
