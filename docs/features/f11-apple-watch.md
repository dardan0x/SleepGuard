# Feature: F11 — Apple Watch

## Status: Done
## Completed: 2026-05-07

## Summary

Record snoring from the Apple Watch microphone, enabling phone-free sleep tracking. The Watch app uses AVAudioEngine for audio capture, counts snore events via dB thresholds, and syncs session data to the paired iPhone via WatchConnectivity.

## Files

| File | Purpose |
|------|---------|
| `WatchApp/Sources/SnoreGuardWatchApp.swift` | Watch app entry point + WKApplicationDelegate |
| `WatchApp/Sources/ContentView.swift` | Watch UI with start/stop recording |
| `WatchApp/Sources/WatchSessionManager.swift` | Watch-side session management + WCSessionDelegate |
| `WatchApp/Sources/WatchAudioRecorder.swift` | AVAudioEngine tap + dB calculation |
| `WatchApp/README.md` | Manual Xcode target setup instructions |
| `Packages/Env/Sources/Env/WatchConnectivityManager.swift` | iOS-side WCSession manager |
| `Packages/Settings/Sources/Settings/SettingsView.swift` | Watch connection status in Settings |
| `Packages/Models/Package.swift` | Added `watchOS(.v10)` platform |
| `Packages/AudioEngine/Package.swift` | Added `watchOS(.v10)` platform |
| `Packages/Env/Package.swift` | Added `WatchConnectivity` framework |

## Routes

No new routes added.

## State

| Property | Location | Scope |
|----------|----------|-------|
| `isWatchReachable` | WatchConnectivityManager | Singleton, observable |
| `lastSyncedSession` | WatchConnectivityManager | Singleton |
| `isRecording` | WatchSessionManager | Watch-only |
| `eventsCount` | WatchSessionManager | Watch-only |

## Edge Cases

- Watch not paired → shows "Not Connected" in Settings; data sync attempts fallback to application context
- Watch out of range during stop → `updateApplicationContext` queues data for next launch
- Audio permission denied on Watch → recording fails silently; no permission UI in V2
- Manual Xcode target setup required — see `WatchApp/README.md`

## Tasks Completed

| Task ID | Name |
|---------|------|
| F11-T1 | WatchOS app target + basic UI |
| F11-T2 | WatchConnectivity session management |
| F11-T3 | Watch audio recording + detection |
| F11-T4 | Sync watch data to iPhone |
