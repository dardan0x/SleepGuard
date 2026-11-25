---
date: 2026-11-25
feature: F27
branch: refactor/f27-architecture-interrogation-fixes
title: F27 planning (principal review verified) and T1 store safety
---

### Completed
- **F27 planned.** Checked every SleepGuard and Shared concern in the principal review (`ARCHITECTURE_INTERROGATION.md`) against the code. Nearly all hold, and four are worse than stated: deep links are cleared before the guard, the melody ignores the remote flag, detail load saves on every open, and delete removes clips before the save. The review's §8 point (`Night` decode precondition) is already handled. 17 tasks; tracker `docs/trackers/f27-architecture-interrogation-fixes.md`.
- **F27-T1 — Never delete the user's store.** A Release build that can't open the store keeps the file, runs on an in-memory store and shows `StoreUnavailableView`. The store is backed up once per app version before opening.

### Technical Details
- `SleepGuardStore.open(_:allowDestructiveReset:)` (Models) returns the container plus the failure. Only `#if DEBUG` passes `true`.
- The live store is in the App Group container (SwiftData's `.automatic` group container uses the widget's group). The `default.store` in the app's own Application Support is a stale leftover.
- Strings live in Shared, so T1/T4 strings shipped first as Shared **0.29.1** (user tagged). SleepGuard bumped 0.27.0 → 0.29.1 (0.28/0.29 only added public UI pieces).

### Files Changed
- `Packages/Models/Sources/Data/SleepGuardStore.swift` (new): open-or-fallback, per-version backup.
- `Packages/Models/Tests/ModelsTests/SleepGuardStoreTests.swift` (new): 5 tests.
- `SleepGuard/StoreUnavailableView.swift` (new): blocking screen, same layout as the hard update gate.
- `SleepGuard/SleepGuardApp.swift`: opens through `SleepGuardStore`; launch work, widget snapshot and deep links skip the fallback.
- 9 `Package.swift` + `SleepGuard.xcodeproj/.../Package.resolved`: shared 0.29.1.
- `docs/trackers/f27-architecture-interrogation-fixes.md` (new), `docs/FeatureTracker.md`.

### Architecture Decisions
- Data safety over availability: a store that can't be opened is never touched in Release. The user sees why and is pointed at an update; nothing is recorded into memory.
- One backup copy (the previous version's), taken before the container opens so store, WAL and SHM match.

### Build Status
- All package tests pass on the pin (AudioEngine 34, DesignSystem 7, Env 63, Models 88, Recordings 10, Routing 3, Statistics 11).
- CI-equivalent Release build (project, pinned lockfile): succeeded.
- Simulator, Release: normal launch wrote the `.bak` files; a corrupt store showed the blocking screen with the file's md5 unchanged; the real store was restored afterwards.

### Suggested Branch
`refactor/f27-architecture-interrogation-fixes`

### Suggested Commit
`F27-T1 — Never delete the user's store`

### Changes done
- Store opening moved to `SleepGuardStore`; Release fallback is in-memory plus a blocking screen.
- Per-version store backup.
- Shared bumped to 0.29.1.

### Next Session
- F27-T2: the root owns the night flow and presentation.

### Open Questions
- Recording can only be started from the Statistics tab, so hiding that tab remotely removes recording altogether. This is a product decision, recorded here and not fixed in F27.
- `check-layering.py` reports false violations from ignored `.build/index-build` checkouts locally (fixed in T9).
