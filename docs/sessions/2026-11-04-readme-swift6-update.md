---
date: 2026-11-04
feature: none
branch: docs/readme-swift6-f17-f18-update
title: README update for Swift 6 migration + view restructuring
---

### Completed
- Standalone docs task: brought `README.md` in line with the two most recent features — F17 (Swift 6 migration) and F18 (view restructuring).

### Technical Details
- Verified against git history and `docs/features/f17-swift6-migration.md` before editing: all 11 SPM packages are on `swift-tools-version: 6.2` + `swiftLanguageMode(.v6)`; app target is `SWIFT_VERSION = 6.0` + `SWIFT_STRICT_CONCURRENCY = complete` (`SWIFT_APPROACHABLE_CONCURRENCY = YES` predates F17); isolation split is explicit `@MainActor` in Models/Env/AudioEngine vs `.defaultIsolation(MainActor.self)` in the 8 UI packages.
- F18 (all 14 tasks complete) added: ≤200-line view / ≤100-line container limits, struct subviews over computed `some View`, enum-driven sheets/alerts, `SessionManager` decomposition, and the UI-layering rule enforced by `scripts/check-layering.py` + `.github/workflows/layering.yml`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `README.md` | +7/-6 | Badge Swift 5.9 → 6.2; requirements Xcode 16+/Swift 5.9 → Xcode 26+ (Swift 6.2 toolchain)/Swift 6 language mode + strict concurrency; packages table 9 → 11 (added `Personalization`, `Learn`); added three "Patterns enforced" bullets (Swift 6 strict concurrency + isolation split, small-views hard limits, UI layering); project structure comments (11 packages, layering CI check); build destination pinned `OS=26.2`; intro dependency list gained `AudioEngine` |

### Architecture Decisions
- **Badge says "Swift 6.2"** even though the app target compiles in Swift 6 language mode (`SWIFT_VERSION = 6.0`): the user-facing version of the toolchain/adoption is 6.2 (package tools-version), matching how the user described the change.
- **No build run**: Markdown-only change, nothing to compile. README re-read in full to verify consistency instead.

### Build Status
- **NOT RUN** — docs-only change (no Swift code touched).

### Suggested Branch
`docs/readme-swift6-f17-f18-update`

### Suggested Commit
`[Docs] — Update README for F17 Swift 6 migration + F18 view restructuring`

### Changes done
```
- Badge: Swift 5.9 → 6.2
- Requirements: Xcode 26+ (Swift 6.2 toolchain); Swift 6 language mode + strict concurrency
- Packages table: added Personalization + Learn (9 → 11)
- Patterns: added Swift 6 strict concurrency/isolation split, view hard limits, UI layering bullets
- Structure comments: 11 packages, scripts layering CI check
- Build command: pinned simulator OS=26.2
- Intro: package dependency list now includes AudioEngine
```

### Next Session
- Resume normal F-task workflow from `docs/FeatureTracker.md` (V3 features in progress/backlog).

### Open Questions
- WatchApp is still on `ObservableObject` and not wired into the Xcode project (known F17 follow-up) — README WatchApp line left as-is; revisit when it is integrated.
