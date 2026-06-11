---
date: 2026-06-11
feature: none
branch: feature/firebase/push-crashlytics
title: Firebase Crashlytics + Push Notifications (FCM) with soft-ask
---

### Completed
- **Crashlytics**: added the dSYM-upload run script as the last build phase; added a DEBUG "Force Test Crash" button. SDK/`FirebaseApp.configure()` already in place.
- **Push (FCM)**: full remote-push plumbing + a soft-ask permission flow shown after the 3rd app open on the Statistics tab (not onboarding). Gated by the new `notifications` feature flag.
- **Settings permission row**: added a Notifications row to Settings → Permissions (live status, request-on-tap, opens iOS Settings when denied) as the escape hatch for users who declined the soft-ask.
- **Firebase dependency trim**: reduced linked Firebase products to exactly Analytics, Crashlytics, Messaging, RemoteConfig — removed Firestore, Storage, InAppMessaging-Beta, AppDistribution-Beta (smaller binary / faster builds).

### Technical Details
- Crashlytics run script (SPM): `"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"`, inputs `${DWARF_DSYM_FOLDER_PATH}/.../${TARGET_NAME}` + `$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)`. Release already `dwarf-with-dsym`; Debug stays `dwarf` (benign upload warning).
- `AppDelegate` (app target) via `@UIApplicationDelegateAdaptor`: `MessagingDelegate` (FCM token) + `UNUserNotificationCenterDelegate` (foreground banner), `apnsToken` forwarded to `Messaging`. Firebase Messaging stays out of all packages.
- `NotificationPermissionManager` (Env, Firebase-free `@Observable`): `authorizationStatus`, `refreshStatus()`, `requestAuthorization()` → on grant calls `registerForRemoteNotifications()` (guarded `#if canImport(UIKit)`).
- Soft-ask trigger in `StatisticsTab.evaluateNotificationSoftAsk()`: requires `AppConfig.isEnabled(.notifications)` + `appOpenCount >= 3` + status `.notDetermined` + not yet dismissed. `appOpenCount` bumped in `SleepGuardApp` `.task`.
- `NotificationSoftAskView` (app target): explainer → Enable triggers the real iOS dialog; Enable/Not-now both set `notificationSoftAskDismissed`.
- Entitlement `aps-environment = development` added; `UIBackgroundModes` already had `remote-notification`.

### Files Changed
| File | What |
|------|------|
| `SleepGuard.xcodeproj/project.pbxproj` | Crashlytics run-script build phase (last) |
| `SleepGuard/SleepGuard.entitlements` | `aps-environment = development` |
| `SleepGuard/PushNotifications/AppDelegate.swift` | new — FCM + UN delegates |
| `SleepGuard/PushNotifications/NotificationSoftAskView.swift` | new — pre-permission explainer |
| `Packages/Env/Sources/Services/NotificationPermissionManager.swift` | new — Firebase-free auth wrapper |
| `Packages/Env/Sources/Services/UserPreferences.swift` | `appOpenCount`, `notificationSoftAskDismissed` |
| `Packages/Models/Sources/Data/AppConfigModels.swift` | `FeatureFlag.notifications` |
| `SleepGuard/SleepGuardApp.swift` | delegate adaptor, inject manager, bump appOpenCount |
| `SleepGuard/AppRegistry.swift` | `NotificationPermissionManager` in both env funcs |
| `SleepGuard/StatisticsTab.swift` | soft-ask trigger + sheet |
| `Packages/Settings/Sources/Views/DebugConfigView.swift` | Force Test Crash button |
| `Packages/Settings/Sources/Views/SettingsPermissionsSection.swift` | Notifications permission row (status + request + open-settings) |
| `Strings.txt` (+generated) | 4 soft-ask strings + `settings.notificationsAccess` |
| `SleepGuard.xcodeproj/project.pbxproj` | Crashlytics run script; removed 4 unused Firebase products |
| `docs/remote-config-schema.md` | `notifications` flag |

### Firebase products (final)
Linked: **FirebaseAnalytics, FirebaseCrashlytics, FirebaseMessaging, FirebaseRemoteConfig**. The `firebase-ios-sdk` package reference stays (one repo, many products); only unused products were unlinked. Analytics kept for crash-free-users metrics, push conversion, and RC audience/A-B targeting.

### App size (asked, not built)
No ML model or custom fonts bundled; resources ≈ 2–2.5 MB (sounds 1.8 MB + icon). Estimated App Store download ~20–35 MB / install ~50–80 MB (Firebase-dominated). Exact figure only via Xcode Archive → App Thinning Size Report or App Store Connect.

### Build Status
- **BUILD SUCCEEDED** — only pre-existing/benign warnings (`latestSession`, `PendingSessionStore` async, Debug dSYM note).

### Manual prerequisites (user)
- Upload an **APNs Auth Key (.p8)** to Firebase → Project Settings → Cloud Messaging.
- Ensure the App ID has **Push Notifications** enabled (automatic signing usually adds it from the entitlement).
- **Test on a real device** — simulator doesn't get real APNs/FCM tokens; send a test from Firebase → Messaging or Cloud Messaging "Send test message" with the FCM token logged at `[Push] FCM token:`.

### Suggested Branch
`feature/firebase/push-crashlytics`

### Suggested Commit
`Firebase Crashlytics + FCM push (soft-ask + settings row) + trim unused Firebase products`

### Open Questions
- Re-engagement reminders + tips were chosen as purposes but no local-notification scheduling is built yet — wire when content/cadence is decided.
- `Force Test Crash` uses `fatalError`; fine for verification.
