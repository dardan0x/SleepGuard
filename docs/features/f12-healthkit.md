# Feature: F12 — HealthKit

## Status: Done
## Completed: 2026-05-07

## Summary

Sync sleep session data to Apple Health so users can view sleep trends alongside other health metrics. After each session is saved, a sleep analysis sample is written to HealthKit with snoring metadata.

## Files

| File | Purpose |
|------|---------|
| `Packages/Env/Sources/Env/HealthKitSync.swift` | Singleton for HealthKit authorization and sleep data writing |
| `Packages/Env/Sources/Env/UserPreferences.swift` | Added `syncToHealthKit` toggle |
| `Packages/Settings/Sources/Settings/SettingsView.swift` | Added HealthKit sync toggle in Data section |
| `Packages/SleepSession/Sources/SleepSession/SessionSummaryView.swift` | Triggers HealthKit sync after session save |
| `SleepGuard/SleepGuard/SleepGuard.entitlements` | HealthKit capability entitlement |
| `SleepGuard.xcodeproj/project.pbxproj` | Build settings for entitlements and Info.plist usage descriptions |

## Routes

No new routes added.

## State

| Property | Location | Scope |
|----------|----------|-------|
| `syncToHealthKit` | UserPreferences | App-wide, UserDefaults-backed |
| `isAuthorized` | HealthKitSync | Singleton, reflects HK authorization status |

## Edge Cases

- HealthKit unavailable on device → `HealthKitSync` silently does nothing
- User denies HealthKit permission → toggle snaps back OFF; they must re-enable in Settings to retry
- Simulator: HealthKit framework loads but sleep data writing may be limited; code is device-ready
- Session save and HealthKit write are independent — SwiftData save succeeds even if HealthKit write fails
- App restart: `checkAuthorizationStatus()` is called on launch, so prior granted permission is respected without re-prompting

## Tasks Completed

| Task ID | Name |
|---------|------|
| F12-T1 | HealthKit capability + permissions |
| F12-T2 | Write sleep data to HealthKit |
| F12-T3 | Settings toggle + trigger on session save |
