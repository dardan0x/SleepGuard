# Feature: F10 — Smart Alarm

## Status: Done
## Completed: 2026-05-07

## Summary

Wake the user during a light-snoring phase within a configurable time window before their set alarm time. The alarm evaluates snoring state every 50ms during the smart window and triggers early if quiet or light snoring is detected — reducing grogginess by avoiding deep-sleep interruptions.

## Files

| File | Purpose |
|------|---------|
| `Packages/Env/Sources/Env/AlarmManager.swift` | Singleton for alarm scheduling, smart wake evaluation, and snooze |
| `Packages/Env/Sources/Env/UserPreferences.swift` | Added alarm settings (enabled, hour, minute, window) |
| `Packages/SleepSession/Sources/SleepSession/BedsideClockView.swift` | Alarm badge, evaluation loop, full-screen alarm overlay |
| `Packages/SleepSession/Sources/SleepSession/RecordingPrestartView.swift` | Alarm toggle + time picker before recording starts |
| `Packages/Settings/Sources/Settings/SettingsView.swift` | Alarm section with toggle, time picker, window duration |

## Routes

No new routes added.

## State

| Property | Location | Scope |
|----------|----------|-------|
| `alarmEnabled` | UserPreferences | App-wide, UserDefaults-backed |
| `alarmHour` | UserPreferences | App-wide, default 7 |
| `alarmMinute` | UserPreferences | App-wide, default 0 |
| `alarmWindowMinutes` | UserPreferences | App-wide, default 30 |
| `isAlarmSet` | AlarmManager | Session-scoped |
| `alarmTriggered` | AlarmManager | Session-scoped |

## Edge Cases

- Alarm time in the past (relative to now) → treated as next-day alarm
- No light snoring phase found in window → falls back to exact alarm time
- User stops recording before alarm → alarm is cleared to prevent stray notifications
- Snooze shifts alarm time forward by 10 minutes and re-evaluates
- Notification permission denied → alarm still triggers in-app overlay, but no background sound

## Tasks Completed

| Task ID | Name |
|---------|------|
| F10-T1 | Alarm scheduling engine |
| F10-T2 | Smart wake window detection |
| F10-T3 | Alarm UI in Settings + Pre-start |
