# F10 — Smart Alarm

> Auto-updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P1 |
| **Version** | V2.0 |
| **Blocked By** | — |
| **Started** | 2026-05-07 |
| **Completed** | 2026-05-07 |
| **Feature Doc** | [features/f10-smart-alarm.md](features/f10-smart-alarm.md) |

## Summary

Wake the user during a light-snoring phase within a configurable time window before their set alarm time. Reduces grogginess by avoiding deep-sleep interruptions.

## Tasks

| ID | Task | Type | Status | Depends On | Package | Started | Completed |
|----|------|------|--------|------------|---------|---------|-----------|
| F10-T1 | Alarm scheduling engine | Backend | Done | — | Env | 2026-05-07 | 2026-05-07 |
| F10-T2 | Smart wake window detection | Logic | Done | F10-T1 | SleepSession | 2026-05-07 | 2026-05-07 |
| F10-T3 | Alarm UI in Settings + Pre-start | UI | Done | F10-T1 | Settings / SleepSession | 2026-05-07 | 2026-05-07 |

## Task Details

### F10-T1 — Alarm scheduling engine

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/concurrency.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] Local notification scheduled for alarm time
- [x] Background processing enabled to evaluate wake window
- [x] Alarm sound plays via local notification when triggered
- [x] Builds with zero errors

**Prompt Used:**
Create AlarmManager singleton in Env package with UNUserNotificationCenter scheduling, smart wake evaluation, and snooze support.

**Notes:**
- `AlarmManager` is `@MainActor @Observable` singleton
- `setAlarm(hour:minute:windowMinutes:)` stores alarm config and schedules a `UNTimeIntervalNotificationTrigger` notification
- `evaluate(currentTime:snoringState:)` checks if current time is within the smart window and if snoring state is `.light` or `.quiet`
- If exact alarm time passes without smart trigger, it fires as fallback
- `snooze(minutes:)` reschedules the alarm forward by N minutes
- Notification permission requested on `AlarmManager` init

---

### F10-T2 — Smart wake window detection

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/state.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] Evaluates snoring state continuously in the alarm window before alarm
- [x] Triggers alarm early if light/quiet snoring detected (optimal wake phase)
- [x] Falls back to exact alarm time if no light phase found
- [x] Builds with zero errors

**Prompt Used:**
Integrate AlarmManager into BedsideClockView: show alarm badge when set, evaluate alarm trigger in the 50ms task loop, show full-screen alarm overlay with "I'm Awake" and "Snooze" buttons.

**Notes:**
- `BedsideClockView` calls `AlarmManager.shared.evaluate(currentTime:snoringState:)` every 50ms tick
- When triggered, `showAlarmOverlay` state shows a full-screen overlay with:
  - Alarm icon + "Time to Wake Up" title
  - Current time in large font
  - "I'm Awake" button → clears alarm, stops recording, shows summary
  - "Snooze 10 min" button → snoozes alarm, dismisses overlay, recording continues
- Alarm badge in top-left shows set alarm time (e.g., "7:00 AM")
- `stopButton` now also clears the alarm to prevent post-session stray notifications

---

### F10-T3 — Alarm UI in Settings + Pre-start

| Field | Value |
|-------|-------|
| Arch Ref | docs/architecture/views.md |
| Status | Done |
| Started | 2026-05-07 |
| Completed | 2026-05-07 |

**Acceptance Criteria:**
- [x] Time picker for alarm time
- [x] Enable/disable toggle
- [x] Smart window duration picker (15/30/45 min)
- [x] Builds with zero errors

**Prompt Used:**
Add Smart Alarm section to SettingsView with toggle, compact time picker, and window duration picker. Add alarm configuration to RecordingPrestartView with toggle and time picker; wire alarm set on session start.

**Notes:**
- **SettingsView**: New "ALARM" section above Recording with:
  - Smart Alarm toggle
  - Compact `DatePicker` for hour/minute (visible when enabled)
  - Smart window duration picker (15/30/45 min) via confirmationDialog
- **RecordingPrestartView**: New alarm card above Start Recording button with:
  - Smart Alarm toggle
  - Compact time picker + window duration label
  - On Start Recording, if alarm enabled, calls `AlarmManager.shared.setAlarm(...)` with UserPreferences values
- **UserPreferences** extended with `alarmEnabled`, `alarmHour` (default 7), `alarmMinute` (default 0), `alarmWindowMinutes` (default 30)

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
