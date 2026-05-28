# F12 — HealthKit

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P1 |
| **Version** | V2.0 |
| **Blocked By** | — |
| **Started** | 2026-05-07 |
| **Completed** | 2026-05-07 |
| **Feature Doc** | [features/f12-healthkit.md](features/f12-healthkit.md) |

## Summary

Sync sleep session data (sleep duration, snoring events) to Apple Health so users can view sleep trends alongside other health metrics.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F12-T1 | HealthKit capability + permissions | Setup | Done | — | Env | 2026-05-07 | 2026-05-07 |
| F12-T2 | Write sleep data to HealthKit | Backend | Done | F12-T1 | Env | 2026-05-07 | 2026-05-07 |
| F12-T3 | Settings toggle + trigger on session save | UI + Logic | Done | F12-T2 | Settings | 2026-05-07 | 2026-05-07 |

## Task Details

### F12-T1 — HealthKit capability + permissions

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/dependencies.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] HealthKit capability added to app target
- [x] `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` in Info.plist
- [x] `HealthKitSync` singleton created in Env package with permission request
- [x] Builds with zero errors

**Prompt Used:**
Add HealthKit capability to SleepGuard app target, create entitlements file, add usage descriptions to build settings, create HealthKitSync singleton in Env package with authorization request method.

**Notes:**
- `CODE_SIGN_ENTITLEMENTS` and `INFOPLIST_KEY_NSHealth*` added to both Debug and Release build settings in project.pbxproj
- `HealthKit` framework linked in Env package via `linkerSettings`
- `HKHealthStore.isHealthDataAvailable()` guard ensures graceful handling on non-HealthKit devices

---

### F12-T2 — Write sleep data to HealthKit

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] `HKCategorySample` (sleep analysis) written for each session
- [x] Start/end times match session timestamps
- [x] Snoring event count stored as metadata
- [x] Builds with zero errors

**Prompt Used:**
Implement HealthKitSync.sync(session:) to write HKCategorySample for sleepAnalysis with asleep value, session timestamps, and metadata including snoreEventsCount, snoringPercentage, averageDB, peakDB.

**Notes:**
- Uses `HKCategoryValueSleepAnalysis.asleep` for the full session duration
- Metadata includes `HKMetadataKeyWasUserEntered: true` to mark user-entered data
- Additional custom metadata keys: `snoreEventsCount`, `snoringPercentage`, `averageDB`, `peakDB`
- `try await healthStore.save(sample)` with silent failure (no toast infrastructure)

---

### F12-T3 — Settings toggle + trigger on session save

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] `syncToHealthKit` toggle in Settings (below Data section)
- [x] Toggling on requests HealthKit permission if not granted
- [x] After session save, `HealthKitSync` writes sleep data automatically
- [x] Builds with zero errors

**Prompt Used:**
Add syncToHealthKit to UserPreferences, add HealthKit toggle to SettingsView Data section that requests authorization when enabled, trigger HealthKitSync.sync(session:) in SessionSummaryView.saveSession() when toggle is on.

**Notes:**
- Toggle uses `.tint(theme.scoreGreen)` to match existing toggle styling
- Authorization request is async via `Task { await HealthKitSync.shared.requestAuthorization() }`
- Sync trigger in `SessionSummaryView.saveSession()` runs after SwiftData save and before dismiss
- `UserPreferences.shared` accessed directly in SessionSummaryView (already imported via Env)

### Bugfix — Auth persistence (2026-05-16)

**Problem:** `HealthKitSync.isAuthorized` defaulted to `false` on every cold launch. `checkAuthorizationStatus()` existed but was never called, so after app restart the toggle could be ON yet sync silently skipped because `isAuthorized` was still `false`.

**Fix:**
- `SleepGuardApp.swift` calls `HealthKitSync.shared.checkAuthorizationStatus()` in `.onAppear`
- `SettingsDataSection` toggle now only stays ON if `requestAuthorization()` returns `true`; if user denies, toggle snaps back OFF
- `SessionSummaryView.saveSession()` re-checks auth status in the sync Task as a safety net

**Files touched:**
- `SleepGuard/SleepGuardApp.swift`
- `Packages/Settings/Sources/Views/SettingsDataSection.swift`
- `Packages/SleepSession/Sources/Views/SessionSummaryView.swift`

---

## Update Rules (for the AI)

After completing a task in this feature:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. If ALL tasks are Done → set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)
