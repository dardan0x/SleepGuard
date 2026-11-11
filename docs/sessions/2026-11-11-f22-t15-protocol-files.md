---
date: 2026-11-11
feature: F22
branch: feature/f22/t15-protocol-files
title: F22-T15 Each service protocol in its own file
---

### Completed
- F22-T15: the 18 service protocols moved out of their concrete types' files into their own `<Protocol>.swift` files, next to the concrete types (user request).

### Technical Details
- Pure move by script: each protocol block and its doc comment and attributes, verbatim. Imports trimmed to what each declaration uses; FactoryKit dropped.
- Placement: sibling files, not a `Protocols/` folder. Role names share a prefix with their type, so the pairs sort together in Xcode and contract and implementation stay in one place.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/Env/Sources/Services/*ing.swift` (14), `Session/SessionManaging.swift` | new | Protocols moved out of their concrete files |
| `Packages/AudioEngine/Sources/Engine/AudioRecording.swift`, `SoundAnalysisDetecting.swift` | new | Same |
| `Packages/DesignSystem/Sources/Components/ThemeProviding.swift` | new | Same |
| 18 concrete service files | −296 | Protocol blocks removed |
| `AGENTS.md`, `CLAUDE.md`, `docs/adr/0002-protocol-services.md` | ±1 each | Rule: protocol in its own file beside the concrete type |
| `docs/features/f22-architecture-hardening.md`, `docs/trackers/f22-architecture-hardening.md`, `docs/FeatureTracker.md` | — | T15 added; F22 15/15 |

### Architecture Decisions
- Sibling file over a `Protocols/` folder (see Technical Details).

### Build Status
- Lint clean; layering and view-size checks pass; app build 0 warnings; all 8 package suites pass (268).

### Suggested Branch
`feature/f22/t15-protocol-files`

### Suggested Commit
`F22-T15 — Each service protocol in its own file`

### Changes done
- See Files Changed.

### Next Session
- User: real night on a device with `feature/f22-architecture-hardening` (T10), then merge into `main`.

### Open Questions
- None.
