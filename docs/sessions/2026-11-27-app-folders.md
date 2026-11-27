---
date: 2026-11-27
feature: F27
branch: refactor/f27-architecture-interrogation-fixes
title: App folders, unused sounds, SleepGuardShared declared by the project
---

## Completed
- F27-T28: `SleepGuard/` sorted into `App/`, `Tabs/`, `Navigation/`, `NightFlow/`, `Widgets/`; `sounds/` removed; the project declares SleepGuardShared and links the products the app and widget import; `bump-shared.sh` and `check-imports.py` cover the project.
- Also this session: PR descriptions for both architecture-review branches; explicit imports (F27-T26/T27, shared 0.37.0; UIKitWay F13-T22).

## Build Status
App build (project and workspace), layering, imports, view size, format: pass. Package tests unaffected (no package change).

## Suggested Branch
`refactor/f27-architecture-interrogation-fixes`

## Suggested Commit
`F27-T28 — App folders; unused sounds removed; SleepGuardShared declared by the project`

## Next Session
- Device night for both apps.
- The `public` surface audit (narrow `public` to `package`/internal where nothing outside the package uses it).
- Clean the project's leftover `file://` package references and duplicate framework links (owner's call).
