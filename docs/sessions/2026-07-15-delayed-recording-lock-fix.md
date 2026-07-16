---
date: 2026-07-15
feature: none
branch: fix/delayed-recording-lock-background
title: Fix delayed recording not starting after phone lock
---

### Completed
- Fixed a bug where choosing a recording delay and then locking the phone caused the session to never start.

### Technical Details
- Root cause: `RecordingDelayManager` relied on a foreground `Timer` and a purely informational local notification. With no active audio session, iOS suspended the app shortly after lock, so the timer never fired and `SessionManager.startSession()` was never called.
- Fix: keep the audio subsystem in a "warmup" state during the countdown. A minimal `AVAudioEngine` input tap runs without writing files or analyzing audio, satisfying the `audio` background mode so the app continues executing after the screen is locked.
- Added a notification fallback: if the app is still suspended and the user taps the delay notification, `AppDelegate` now cancels the countdown and starts the session.

### Files Changed
| File | Lines | What Changed |
|------|-------|--------------|
| `Packages/AudioEngine/Sources/Engine/AudioRecorder.swift` | +47 | Added `isWarmedUp`, `warmupEngine`, `startWarmup()`, and `stopWarmup()` to keep audio I/O alive during a delayed-start countdown without recording or analyzing audio. |
| `Packages/Env/Sources/Services/RecordingDelayManager.swift` | +14 / -2 | Imported `AudioEngine`; calls `startWarmup()` when the delay begins and `stopWarmup()` when it is cancelled or finishes; exposed `notificationId` for the fallback handler. |
| `SleepGuard/PushNotifications/AppDelegate.swift` | +7 / -1 | Imported `Env`; `userNotificationCenter(_:didReceive:)` now starts the session when the delay notification is tapped while a countdown is active. |

### Architecture Decisions
- **Separate warmup engine**: Used a dedicated `warmupEngine` rather than reusing `audioEngine` so the existing recording lifecycle (pause/resume/stop) is untouched and the warmup path cannot interfere with an in-progress session.
- **Discard buffers during warmup**: The input tap is intentionally empty to avoid recording audio or generating events during the user-configured delay, while still keeping the mic graph alive for background eligibility.
- **Notification as fallback, not primary**: The local notification only triggers recording on user tap. The primary fix is the active audio session, which is the Apple-supported mechanism for a recording app to run after lock.

### Build Status
- **BUILD SUCCEEDED** — `build_sim` completed with no errors.
- `build_run_sim` failed on a pre-existing problem: the referenced subproject at `SleepGuard/SleepGuard.xcodeproj` is missing its `project.pbxproj` file. This is unrelated to the changes above.

### Suggested Branch
`fix/delayed-recording-lock-background`

### Suggested Commit
`[Fix] — Delayed recording fails when phone is locked`

### Changes done
- Added `AudioRecorder.startWarmup()` / `stopWarmup()`.
- Wired warmup start/stop into `RecordingDelayManager`.
- Added delay-notification tap handler in `AppDelegate` to start the session as a fallback.
