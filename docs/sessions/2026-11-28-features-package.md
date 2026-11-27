---
date: 2026-11-28
feature: F27
branch: refactor/f27-features-package
title: Features as one package, a target per feature
---

### Completed
- F27-T31: the seven feature packages (Learn, Onboarding, Personalization, Recordings, Settings, SleepSession, Statistics) are now targets of one `Packages/Features` package, as in SleepGuardUIKitWay. Each is still its own module, imported by name.

### Technical Details
- Sources moved with `git mv` to `Packages/Features/Sources/<Feature>/`; tests to `Tests/RecordingsTests` and `Tests/StatisticsTests`. Each target keeps its previous dependency list exactly; the package declares the union and shares one `swiftSettings` list.
- Project: the `Packages` group has one `Features` folder reference instead of seven; no dangling IDs. The product dependencies (by name) are unchanged.
- `check-imports.py`: siblings are no longer implicitly allowed; a feature declaring another feature fails. Both were probed and failed as expected.
- `check-view-size.py` scans the features' `Views`/`Components` (61 view files, same as before).
- `run-tests.sh` prints every "Test run" line, since Features runs two bundles under `Features-Package`.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Features/Package.swift` | New: 7 products and targets, 2 test targets |
| `Packages/Features/Sources/*`, `Packages/Features/Tests/*` | Moved from the seven feature packages (content unchanged) |
| `Packages/{Learn,…,Statistics}/Package.swift`, `Packages/Statistics/.swiftpm/…/Statistics.xcscheme` | Removed |
| `SleepGuard.xcodeproj/project.pbxproj` | Seven package folder references → one `Features` |
| `scripts/check-imports.py` | Declared siblings only; no feature → feature dependency |
| `scripts/check-view-size.py` | Scans `Packages/Features/Sources/*/{Views,Components}` |
| `scripts/run-tests.sh` | Prints each test run of a package |
| `docs/adr/0011-features-package.md` | New ADR |
| `CLAUDE.md`, `AGENTS.md` | Features rule (kept in sync) |
| `README.md`, `docs/TECHNICAL_OVERVIEW.md` | Package diagram, isolation section, tables |
| `docs/trackers/f27-architecture-interrogation-fixes.md`, `docs/FeatureTracker.md` | F27-T31 |

### Architecture Decisions
- **Module names kept** (`Settings`, not `SettingsFeature`): the app target and project stay untouched; renaming for parity can be its own step.
- **CI, not the compiler, now guards feature isolation** (one package): ADR 0011 records the trade-off.
- **Core packages untouched**: they split by reason to change (ADR 0008).

### Build Status
- **BUILD SUCCEEDED** (SleepGuard scheme, zero errors; existing warnings only). Checks pass: imports, layering, view size, hardcoded strings. Package tests: all pass (Features 23, 180 in total). App launches to onboarding.

### Suggested Branch
`refactor/f27-features-package`

### Suggested Commit
`F27-T31 — Features as one package, a target per feature`
- Move the seven feature packages into `Packages/Features` (one target each, module names unchanged)
- Project: one `Features` folder reference
- check-imports: declared siblings only; no feature depends on another
- check-view-size scans the features; run-tests prints every test run
- ADR 0011; CLAUDE/AGENTS, README, TECHNICAL_OVERVIEW, trackers

### Next Session
- Device night for both apps (still pending from F27).
- Optional: rename the modules to `*Feature` for full UIKitWay parity.

### Open Questions
- TECHNICAL_OVERVIEW's "237 tests in 8 packages" doesn't match the runner (180 in 6); refresh the number?
- Delete the untracked `Packages/Logging/.swiftpm` leftover?
