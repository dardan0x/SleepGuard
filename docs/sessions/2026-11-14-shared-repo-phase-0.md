---
date: 2026-11-14
feature: none
branch: feature/shared/p0-extract-sleepcore-strings
title: Phase 0 of the SleepGuardUIKitWay plan — pure logic and strings moved to the SleepGuardShared repo
---

### Completed
- Planned `SleepGuardUIKitWay` (UIKit shell + SwiftUI screens, hexagonal core, 3 brand targets, Tuist). Plan: `~/.claude/plans/pasted-content-id-0ed0-project-glimmering-axolotl.md`.
- Phase 0: created the `SleepGuardShared` package next to this repo (`../SleepGuardShared`, local git repo, nothing committed) with two products, and moved code into it unchanged:
  - `SleepCore`: `SleepScore`, `SleepInputs`, `SleepScoreConfig`, the cache-version hash, `SnoreIntensity`, `SoundCategory`, `SleepStage`, `SleepStageSegment`, `StageStats`, `RecordingGap`, `SnoreBurst`, `DetectionState`, `DetectionStateMachine`, `DetectionEngine`, their tests and the replay fixtures/goldens.
  - `SleepStrings`: `Localizable.xcstrings`, `Strings.txt`, generated `Strings.swift`, the generator scripts, `LocalizableCatalogTests`.
- SleepGuard now consumes both by path.

### Technical Details
- Packages depend on `.package(path: "../../../SleepGuardShared")`; files that name a moved type add `import SleepCore` (39 files).
- `DesignSystem/Sources/Strings.swift` is `@_exported import SleepStrings`. A `typealias` failed in the app and widget targets because they build with member import visibility.
- `StageStats` gained a public initializer (its memberwise init was internal and is now used across a module boundary).
- A private `SnoreIntensity.rank` in `DetectionStateMachine.swift` duplicated the public one once both were in one module; the duplicate was removed (same values).
- Schema safety: a store written before the move is checked in as `Packages/Models/Tests/ModelsTests/Fixtures/premove-v1.store`; `storeWrittenBeforeTheValueTypesMovedToSleepCoreStillOpens` opens it and decodes gaps, stage segments, bursts and both enums, and recomputes the same score (78).
- `SleepReportPDFGenerator.swift` dropped an unused `import AudioEngine` so the added `import SleepCore` didn't push it past its 525-line ceiling.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Models/Sources/Data/{SleepScore,SleepScoreConfig,RecordingGap,SnoreBurst}.swift` | Moved to `SleepCore` |
| `Packages/Models/Sources/Data/{SnoreEvent,SleepSession,SleepScoreCache}.swift` | Enums / stage types / cache-version extension moved out; `import SleepCore` |
| `Packages/AudioEngine/Sources/Engine/{DetectionStateMachine,DetectionEngine}.swift` | Moved to `SleepCore` |
| `Packages/AudioEngine/Sources/Engine/SnoreDetector.swift` | `DetectionState` moved out; `import SleepCore` |
| `Packages/AudioEngine/Tests/Detection*Tests.swift`, `Tests/Fixtures/Replay/*` | Moved to `SleepGuardShared/Tests/SleepCoreTests` |
| `Packages/Models/Tests/ModelsTests/SleepScoreFormulaTests.swift` | Moved to `SleepCoreTests` |
| `Packages/Models/Tests/ModelsTests/SleepGuardSchemaTests.swift`, `Fixtures/premove-v1.store` | New pre-move store test and fixture |
| `Packages/DesignSystem/Sources/Strings.swift` | Now re-exports `SleepStrings` |
| `Packages/DesignSystem/Sources/Resources/*`, `Tests/LocalizableCatalogTests.swift` | Moved to `SleepStrings` |
| `Packages/{Models,AudioEngine,DesignSystem,Env,Recordings,Statistics}/Package.swift` | Depend on `SleepGuardShared` |
| 39 source/test files in Models, AudioEngine, DesignSystem, Env, Recordings, Statistics | `import SleepCore` |
| `scripts/generate-strings.py`, `generate-xcstrings.py`, `record-replay-goldens.sh` | Run the shared repo's scripts |
| `scripts/extract-strings.py` | Catalog paths point at the shared repo |
| `scripts/make-replay-fixture.py` | Deleted; the working copy is in the shared repo |
| `AGENTS.md`, `CLAUDE.md`, `docs/TECHNICAL_OVERVIEW.md` | Paths and a "Shared repo" rule |
| `docs/adr/0004-shared-repo.md` | New ADR |

### Architecture Decisions
- **One shared repo, several products** rather than one repo per package: a change spanning logic and strings is one commit and one version.
- **Explicit `import SleepCore`**, with one re-export for strings only (reason above). See ADR 0004.
- **Move-only.** Episode merging, snoring duration, classifier rules and sensitivity thresholds stay here; each needs a refactor to become pure first.

### Build Status
- **BUILD SUCCEEDED** — app + widgets (Debug, simulator).
- Package tests: all 8 suites pass (AudioEngine 40, DesignSystem 5, Env 59, Models 77, Personalization 30, Recordings 16, Routing 3, Statistics 18).
- Shared repo: 28 `SleepCore` tests + 2 `SleepStrings` tests pass on the simulator; `SleepCore` also passes on macOS. Replay goldens unchanged.
- `check-layering.py`, `check-view-size.py`, `check-hardcoded-strings.py`, SwiftFormat lint: pass.
- Not verified: the app on a simulator holding real pre-change data (only the fixture store test).

### Suggested Branch
`feature/shared/p0-extract-sleepcore-strings`

### Suggested Commit
`Shared P0 — Move pure score, detection and strings to SleepGuardShared`
- Move SleepScore, detection state machine/engine, stored value types and their tests to SleepCore
- Move the string catalog, generated Strings and generators to SleepStrings
- Depend on SleepGuardShared by path; import SleepCore where its types are named
- Add a test that opens a store written before the move
- ADR 0004; update AGENTS.md / CLAUDE.md / TECHNICAL_OVERVIEW paths

### Changes done
- See Files Changed.

### Next Session
- Give `SleepGuardShared` a remote, then fix CI: `tests.yml` must fetch it; move `strings-sync` to the shared repo's CI.
- Phase 1: `SleepGuardUIKitWay` foundation (Tuist project, package skeletons, 3 brands, design kit product).

### Open Questions
- Remote for `SleepGuardShared`: private GitHub repo? Then path dependency → versioned URL with the sibling checkout as local override.
- The pbxproj build phase "Generate Strings.swift" still runs and now regenerates the file in the sibling shared checkout. Keep or remove?
