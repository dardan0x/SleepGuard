# Feature: F13 — CloudKit Sync

## Status: Done
## Completed: 2026-05-07

## Summary

Sync sleep sessions across all user's devices via CloudKit. SwiftData's built-in CloudKit integration automatically handles push/pull, while the Settings UI shows sync status and a manual refresh trigger.

## Files

| File | Purpose |
|------|---------|
| `SnoreGuard/SnoreGuardApp.swift` | ModelContainer configured with `.cloudKitDatabase(.private(...))` |
| `SnoreGuard/SnoreGuard/SnoreGuard.entitlements` | CloudKit capability + container identifier |
| `SnoreGuard.xcodeproj/project.pbxproj` | Background modes updated to `audio remote-notification` |
| `Packages/Env/Sources/Env/CloudKitSync.swift` | Singleton observing remote changes, tracking last sync |
| `Packages/Settings/Sources/Settings/SettingsView.swift` | SYNC section with status, last sync time, Sync Now button |

## Routes

No new routes added.

## State

| Property | Location | Scope |
|----------|----------|-------|
| `lastSyncDate` | CloudKitSync | Singleton, observable |
| `isSyncing` | CloudKitSync | Singleton, observable |

## Edge Cases

- CloudKit container not created in Developer portal → sync silently fails; data remains local-only
- Device offline → SwiftData queues changes locally; sync resumes when online
- Multiple devices editing same session → last-write-wins (SwiftData default)
- Background remote notification triggers sync without app launch (handled by system)

## Tasks Completed

| Task ID | Name |
|---------|------|
| F13-T1 | CloudKit container + capability setup |
| F13-T2 | SwiftData CloudKit integration |
| F13-T3 | Sync status / conflict UI |
