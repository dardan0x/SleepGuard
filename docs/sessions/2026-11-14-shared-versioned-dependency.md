---
date: 2026-11-14
feature: none
branch: feature/shared/f0-t4-versioned-dependency
title: SleepGuardShared consumed by version, with a dev workspace for local edits
---

### Completed
- F0-T4 (tracked in SleepGuardUIKitWay): the six packages that use `SleepGuardShared` depend on the GitHub release `exact: "0.1.0"` instead of the sibling path.
- `SleepGuard.xcworkspace`: the project plus `../SleepGuardShared` as a local package, which overrides the release. Open it in Xcode for day-to-day work.
- `scripts/bump-shared.sh <version>`: checks the tag exists, rewrites the manifests, re-resolves the project and the workspace lockfiles.
- F0-T5 (this repo's part): `strings-sync` removed from `quality.yml`; the check now runs in the shared repo's CI.

### Technical Details
- Tag `0.1.0` = shared commit `317ea15`, pushed. The shared repo is public, so CI resolves it without a token.
- `exact:` rather than `from:` so every package graph agrees: each package's own test run resolves independently (and package lockfiles are git-ignored here).
- The workspace resolved newer Firebase (12.19.3) and Factory (3.5.3) on its own; its `Package.resolved` was seeded from the project's, so both now pin identical versions apart from the shared package.
- `.gitignore` un-ignores `SleepGuard.xcworkspace`; its `Package.resolved` is force-added (same as the project's, F23-T7).
- `.xcodebuildmcp/config.yaml` points at the workspace.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/{Models,AudioEngine,DesignSystem,Env,Recordings,Statistics}/Package.swift` | Path dependency → `url:` + `exact: "0.1.0"` |
| `SleepGuard.xcodeproj/.../Package.resolved` | Adds the `sleepguardshared` 0.1.0 pin |
| `SleepGuard.xcworkspace/` (new) | Dev workspace and its lockfile |
| `scripts/bump-shared.sh` (new) | Move to a new shared release |
| `.gitignore` | Un-ignore the dev workspace |
| `.github/workflows/quality.yml` | `strings-sync` job removed |
| `.xcodebuildmcp/config.yaml` | Workspace instead of project |
| `AGENTS.md`, `CLAUDE.md` | Shared-repo rule: two ways to build, release steps; build commands |
| `docs/adr/0004-shared-repo.md` | Versioned dependency, workspace override, revised limits |

### Architecture Decisions
- **Versioned release + workspace override** (owner's choice) over a plain path dependency: reproducible pins, at the cost that `run-tests.sh`, project and CI builds see a shared change only after it is tagged and bumped.

### Build Status
- Workspace resolves `SleepGuardShared` from `/Users/…/SleepGuardShared`; project resolves it from GitHub @ 0.1.0.
- Sharing check: a deliberate `#error` in the local shared checkout failed the workspace build; the project build **SUCCEEDED**. The probe was removed.
- Package tests against the release: all 8 suites pass (AudioEngine 40, DesignSystem 5, Env 59, Models 77, Personalization 30, Recordings 16, Routing 3, Statistics 18).
- Not verified: CI on GitHub (nothing pushed); the build MCP server reading `workspacePath` (not connected).

### Suggested Branch
`feature/shared/f0-t4-versioned-dependency`

### Suggested Commit
`Shared F0-T4 — Depend on SleepGuardShared 0.1.0 by version; dev workspace for local edits`

### Next Session
- SleepGuardUIKitWay F1-T2: Tuist project with three brand targets.

### Open Questions
- Pre-existing: the project references a stray `SleepGuard/SleepGuard.xcodeproj` with no `project.pbxproj`; every `xcodebuild` logs an error about it. Remove the reference?
