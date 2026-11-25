# F27 — Architecture Interrogation Fixes

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P0 (T1) / P1 |
| **Version** | V5 |
| **Blocked By** | — |
| **Started** | 2026-11-25 |
| **Completed** | — |
| **Feature Doc** | — |
| **Branch** | `refactor/f27-architecture-interrogation-fixes` (one branch, one commit per task; the user merges it into `main`) |

## Summary

Fixes the verdicts of the principal-level architecture review (`ARCHITECTURE_INTERROGATION.md`, 2026-11-19), each checked against the code first. Order: data safety, flow correctness, detection parity, then structure and docs. SleepGuard + SleepGuardShared (the user commits and tags Shared); UIKitWay items go to a follow-up list.

### Decisions (user, 2026-11-25)
- Scope: SleepGuard + Shared. UIKitWay as a follow-up.
- Cadence (Q14): a shared `SampleDecimator` with the same (latest-value) output as today.
- Big refactors: all four (one theme system, Env split, Logging leaf, access-level imports).
- Protocols (Q24): keep them all; add contract tests for stateful fakes.
- Git: one refactor branch, a commit per task named after it, no sub-branches.
- Strings live in Shared, so new strings ship first as a small Shared release (0.29.1).

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F27-T1 | Never delete the user's store (Q55) | Bug / Data safety | Done | Shared 0.29.1 (strings) | Models / App | 2026-11-25 | 2026-11-25 |
| F27-T2 | Root owns the night flow and presentation (Q22, Q27, Q28, Q26) | Refactor / Bug | Backlog | — | Routing / App | — | — |
| F27-T3 | Flags frozen per recording (Q50) | Bug | Backlog | — | Env / App | — | — |
| F27-T4 | Detail and lists tell the truth: CQS load, delete order + alert, no dead `.error` (Q34, Q56, Q20) | Bug / Refactor | Backlog | Shared 0.29.1 | Recordings / Statistics | — | — |
| F27-T5 | Launch work off main; owned tasks (Q9, Q54) | Perf | Backlog | T2 | Models / App | — | — |
| F27-T6 | Checkpoint writes off the detection path (Q13/Q39) | Perf | Backlog | — | Env | — | — |
| F27-T7 | Shared 0.30.0: decimator, interruption gaps, SaveRules, stored-type fixtures, score golden, CI (Q14, Q17, Q3, Q11, Q9, Q6, Q2) | Shared | Backlog | — | SleepGuardShared | — | — |
| F27-T8 | Bump to 0.30.0 and adopt: decimator driver, interruption gaps, FFT gate, thermal log, SaveRules | Detection | Backlog | T7 | Env / AudioEngine | — | — |
| F27-T9 | Module hygiene: declared deps, import checker, guardrail fixes (Q30, Q63) | Infra | Backlog | — | all / scripts | — | — |
| F27-T10 | `Logging` leaf; AudioEngine off Models (Q32) | Refactor | Backlog | T9 | Logging / AudioEngine | — | — |
| F27-T11 | Split Env by reason to change (Q31) | Refactor | Backlog | T10 | Env → Config / Health / Platform | — | — |
| F27-T12 | Access-level imports (Q30) | Refactor | Backlog | T11 | all | — | — |
| F27-T13 | One theme system (Q21) | Refactor | Backlog | T12 | DesignSystem / views | — | — |
| F27-T14 | Two dependency-resolution styles (Q23) | Refactor | Backlog | T11 | Env / Recordings | — | — |
| F27-T15 | Contract tests for stateful fakes (Q24/Q59) | Tests | Backlog | T11 | Env | — | — |
| F27-T16 | Dead code and docs (Q67, Q53) | Cleanup | Backlog | — | Recordings / docs | — | — |
| F27-T17 | Close out: feature doc, ADRs, UIKitWay follow-up list | Docs | Backlog | all | docs | — | — |

## Task Details

### F27-T1 — Never delete the user's store

| Field | Value |
|-------|-------|
| Arch Ref | Interrogation Q55, Q68; CLAUDE.md "Versioned schema" |
| Status | Done |
| Started | 2026-11-25 |
| Completed | 2026-11-25 |

**Acceptance Criteria:**
- [x] Release builds never delete the store: on open failure the file stays, the app runs on an in-memory store and shows `StoreUnavailableView`
- [x] Debug keeps the delete-and-retry reset (dev schema changes)
- [x] The store (+ `-wal`/`-shm`) is copied to `.bak` once per app version before opening
- [x] Nothing (recovery, cleanup, re-score, widget snapshot, deep links) touches the in-memory fallback
- [x] Tests: corrupt store kept and in-memory fallback; Debug reset; healthy open; backup once per version; no store → no backup
- [x] Builds with zero errors; Models tests pass

**Prompt Used:**
"can you make a plan with a refactor feature to fix all issues mentioned on …ARCHITECTURE_INTERROGATION.md"

**Notes:**
- `SleepGuardStore` (Models) owns opening: `open(_:allowDestructiveReset:)` returns the container and the failure, if any. The app passes `true` only under `#if DEBUG`. The in-memory fallback `fatalError`s only when even an in-memory store can't be created (nothing could work then).
- The live store is in the **App Group container** (`group.com.dardan.SleepGuard/Library/Application Support/default.store`): SwiftData's `.automatic` group container picks the widget's app group. The `default.store` in the app's own Application Support is a stale leftover from before the group existed; nothing reads it.
- Backup: the store and its `-wal`/`-shm` are copied as a set *before* the container opens, so the copy is consistent. Marker file `default.store.bak-version`. One copy only (the previous version's), so disk use is one extra store.
- `StoreUnavailableView` (app target) copies the hard update gate's layout; the design file has no screen for this. Strings ship in Shared 0.29.1.
- Gated on the failure: launch work in `onAppear`, widget snapshot on background, deep links. The update gate overlay still shows on top if remote config asks for it.
- Simulator (Release build, workspace): normal launch wrote `.bak` files plus marker 1.0.0. A corrupt `default.store` showed the blocking screen, and the file's md5 was unchanged after launch. The real store was restored afterwards and the app opened with its data.
- Found: `check-layering.py` scans ignored `.build/index-build` checkouts → false violations locally (fix in T9).
- Tests: `SleepGuardStoreTests` (5). Models: 88 tests pass.
