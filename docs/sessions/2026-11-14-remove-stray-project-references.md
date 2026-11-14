---
date: 2026-11-14
feature: none
branch: fix/remove-stray-project-references
title: Remove 19 stray references to a nested SleepGuard.xcodeproj
---

### Completed
- Every `xcodebuild` run logged "Project …/SleepGuard/SleepGuard.xcodeproj cannot be opened because it is missing its project.pbxproj file". Two causes, both fixed:
  1. `project.pbxproj` listed `SleepGuard/SleepGuard.xcodeproj` as a sub-project 19 times (19 file references, a `projectReferences` list of 19 entries, 19 empty "Products" groups). None appeared in a visible group; likely the folder was dragged in repeatedly. All removed (−202 lines).
  2. The folder itself (only a `project.xcworkspace` with an `xcuserstate`; untracked) sat inside the app's file-system-synchronized folder, so Xcode tried to load it. Moved out of the repo (not deleted).

### Technical Details
- Removal was scripted with checks: exactly 19 references, every `projectReferences` entry pointing at one of them, and each product group empty; otherwise nothing is written.
- The widget's `PBXContainerItemProxy` is unrelated (it points at this project's own widget target) and was left alone.

### Files Changed
| File | What Changed |
|------|--------------|
| `SleepGuard.xcodeproj/project.pbxproj` | 19 stray sub-project references removed |

### Build Status
- **BUILD SUCCEEDED** through the project and through the dev workspace; the "missing its project.pbxproj" error no longer appears.
- Targets unchanged: `SleepGuard`, `SleepGuardWidgetsExtension`.

### Suggested Branch
`fix/remove-stray-project-references`

### Suggested Commit
`Fix — Remove 19 stray references to a nested SleepGuard.xcodeproj`

### Open Questions
- None.
