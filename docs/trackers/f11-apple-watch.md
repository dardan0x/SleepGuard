# F11 — Apple Watch

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P2 |
| **Version** | V2.0 |
| **Blocked By** | — |
| **Started** | 2026-05-07 |
| **Completed** | 2026-05-07 |
| **Feature Doc** | [features/f11-apple-watch.md](features/f11-apple-watch.md) |

## Summary

Record snoring from the Apple Watch microphone, enabling phone-free sleep tracking. Watch session data syncs to the paired iPhone via WatchConnectivity.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F11-T1 | WatchOS app target + basic UI | Setup | Done | — | Watch App | 2026-05-07 | 2026-05-07 |
| F11-T2 | WatchConnectivity session management | Backend | Done | F11-T1 | Env / Watch App | 2026-05-07 | 2026-05-07 |
| F11-T3 | Watch audio recording + detection | Backend | Done | F11-T2 | Watch App | 2026-05-07 | 2026-05-07 |
| F11-T4 | Sync watch data to iPhone | Backend | Done | F11-T3 | Env / Watch App | 2026-05-07 | 2026-05-07 |

## Task Details

### F11-T1 — WatchOS app target + basic UI

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/modules.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] WatchOS app source files created (`SleepGuardWatchApp.swift`, `ContentView.swift`)
- [x] Basic start/stop recording UI on watch
- [x] Manual setup guide for Xcode target integration
- [x] iPhone app detects paired watch availability

**Prompt Used:**
Create Watch app source files with SwiftUI entry point, start/stop UI, and manual Xcode target setup README.

**Notes:**
- Watch app source code lives in `WatchApp/Sources/`
- Xcode target must be added manually per `WatchApp/README.md` (File → New → Target → watchOS App)
- iOS app already shows Watch connection status in SettingsView
- `Models` and `AudioEngine` packages updated with `watchOS(.v10)` platform support

---

### F11-T2 — WatchConnectivity session management

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/dependencies.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] WCSession activated on both iPhone and Watch
- [x] Reachability status observed
- [x] Message passing verified (session data transfer)
- [x] Builds with zero errors

**Prompt Used:**
Create WatchConnectivityManager on iOS and WatchSessionManager on Watch with WCSession activation, reachability, and message handling.

**Notes:**
- `WatchConnectivityManager` in Env package: iOS-side singleton with `isWatchReachable` observable
- `WatchSessionManager` on Watch: implements `WCSessionDelegate`, sends session data via `sendMessage` when reachable, falls back to `updateApplicationContext`
- `WatchConnectivity` framework linked in Env package

---

### F11-T3 — Watch audio recording + detection

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] AVAudioEngine tap on watch captures microphone input
- [x] Snore detection via dB threshold on watch
- [x] Session metadata accumulated locally on watch
- [x] Builds with zero errors

**Prompt Used:**
Create WatchAudioRecorder with AVAudioEngine tap and dB calculation; integrate into WatchSessionManager for event counting.

**Notes:**
- `WatchAudioRecorder` uses `AVAudioEngine.inputNode.installTap` with 1024 buffer size
- dB calculation same formula as iOS `AudioRecorder`
- Event count increments when `currentDB > -30`
- `AVAudioSession` configured with `.playAndRecord` + `.defaultToSpeaker`

---

### F11-T4 — Sync watch data to iPhone

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/networking.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] Session data transferred via WCSession `sendMessage`
- [x] iPhone receives watch session data
- [x] Fallback to `updateApplicationContext` when not reachable
- [x] Builds with zero errors

**Prompt Used:**
Implement data sync from Watch to iPhone: Watch sends session payload on stop, iOS WatchConnectivityManager receives and stores last sync timestamp.

**Notes:**
- Session payload includes: `type: "session"`, `startDate`, `duration`, `eventsCount`
- Primary transport: `WCSession.sendMessage` (immediate, when reachable)
- Fallback: `WCSession.updateApplicationContext` (queued, delivered when app launches)
- iOS app shows connection status in Settings → WATCH section

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
