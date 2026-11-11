---
date: 2026-11-11
feature: F23
branch: feature/f23/t2-privacy-manifest
title: F23-T2 App and widget privacy manifests
---

### Completed
- F23-T2: `PrivacyInfo.xcprivacy` for the app and the widget extension.

### Technical Details
- App: UserDefaults (CA92.1), file timestamp (C617.1, `attributesOfItem` for file sizes), system boot time (35F9.1, `systemUptime` for playback timing). Widget: UserDefaults (CA92.1).
- Tracking false; no app-collected data types. The Firebase and Factory bundles ship their own manifests.
- Synchronized folders pick up both files; verified inside the built `.app` and `.appex`.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `SleepGuard/PrivacyInfo.xcprivacy` | +40 | New |
| `SleepGuardWidgets/PrivacyInfo.xcprivacy` | +25 | New |
| `docs/trackers/f23-production-readiness.md`, `docs/FeatureTracker.md` | — | T2 Done |

### Architecture Decisions
- None.

### Build Status
- `plutil -lint` OK; app build 0 warnings; both manifests present in the built products.

### Suggested Branch
`feature/f23/t2-privacy-manifest`

### Suggested Commit
`F23-T2 — App and widget privacy manifests`

### Changes done
- See Files Changed.

### Next Session
- F23-T3 CI app build.

### Open Questions
- User: generate the privacy report from an archive before submission, and match the App Store Connect privacy label (Crashlytics).
